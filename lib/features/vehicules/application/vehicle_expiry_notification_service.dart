import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../maintenance/application/maintenance_service.dart';
import '../../maintenance/domain/models/maintenance_model.dart';
import '../domain/models/routine_maintenance.dart';
import '../domain/models/vehicule_model.dart';

final vehicleExpiryNotificationServiceProvider =
    Provider<VehicleExpiryNotificationService>((ref) {
  return VehicleExpiryNotificationService.instance;
});

enum _ExpiryKind { insurance, inspection, tax }

/// Notifications locales pour les échéances admin et entretiens :
/// uniquement de J−7 jusqu’au jour J (plus de rappels quotidiens après
/// échéance, ni après saisie d’une nouvelle date hors fenêtre).
class VehicleExpiryNotificationService {
  VehicleExpiryNotificationService._();
  static final VehicleExpiryNotificationService instance =
      VehicleExpiryNotificationService._();

  static const _prefsIdsKey = 'vehicle_expiry_notification_ids';
  static const _channelId = 'vehicle_expiry_reminders';
  static const _channelName = 'Échéances véhicule';
  static const _channelDescription =
      'Rappels assurance, visite technique, vignette et prochains entretiens';
  static const _notifyHour = 9;
  static const _notifyMinute = 0;
  static const _daysBefore = 7;

  final MaintenanceService _maintenanceService = MaintenanceService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _syncing = false;
  String? _lastSyncSignature;
  List<Vehicle>? _pendingVehicles;
  bool _pendingForce = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    await _configureLocalTimeZone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
      ),
    );

    _initialized = true;
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Tunis'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
  }

  Future<void> requestPermissionsIfNeeded() async {
    if (kIsWeb) return;

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Annule les anciennes planifications puis reprogramme pour la liste actuelle.
  Future<void> syncVehicles(
    List<Vehicle> vehicles, {
    bool force = false,
  }) async {
    if (kIsWeb) return;

    if (_syncing) {
      _pendingVehicles = List<Vehicle>.from(vehicles);
      _pendingForce = _pendingForce || force;
      return;
    }
    _syncing = true;

    try {
      await initialize();
      await requestPermissionsIfNeeded();

      final duesByVehicle = <String, List<Maintenance>>{};
      for (final vehicle in vehicles) {
        duesByVehicle[vehicle.id] =
            await _maintenanceService.fetchMaintenancesWithNextDue(vehicle.id);
      }

      final signature = [
        ...vehicles.map(
          (v) =>
              '${v.id}|${v.mileage}|'
              '${v.insuranceExpiry?.millisecondsSinceEpoch}|'
              '${v.technicalInspectionExpiry?.millisecondsSinceEpoch}|'
              '${v.taxExpiry?.millisecondsSinceEpoch}|'
              '${v.routine.toMap()}',
        ),
        ...duesByVehicle.entries.expand(
          (e) => e.value.map((m) {
            final itemDues = m.items
                .where((i) => i.nextDueDate != null)
                .map(
                  (i) =>
                      '${i.name}:${i.nextDueDate?.millisecondsSinceEpoch}',
                )
                .join(',');
            return '${m.id}|${m.nextDueDate?.millisecondsSinceEpoch}|'
                '${m.nextDueMileage}|$itemDues';
          }),
        ),
      ].join(';');

      if (!force && signature == _lastSyncSignature) return;

      // Toujours tout annuler avant de reprogrammer (évite les orphelins
      // après changement de date).
      await _cancelAllScheduledNotifications();

      final scheduledIds = <int>[];
      for (final vehicle in vehicles) {
        scheduledIds.addAll(
          await _scheduleKind(
            vehicle: vehicle,
            kind: _ExpiryKind.insurance,
            expiry: vehicle.insuranceExpiry,
          ),
        );
        scheduledIds.addAll(
          await _scheduleKind(
            vehicle: vehicle,
            kind: _ExpiryKind.inspection,
            expiry: vehicle.technicalInspectionExpiry,
          ),
        );
        scheduledIds.addAll(
          await _scheduleKind(
            vehicle: vehicle,
            kind: _ExpiryKind.tax,
            expiry: vehicle.taxExpiry,
          ),
        );
        scheduledIds.addAll(await _scheduleRoutine(vehicle));
        scheduledIds.addAll(
          await _scheduleMaintenanceDues(
            vehicle: vehicle,
            maintenances: duesByVehicle[vehicle.id] ?? const [],
          ),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _prefsIdsKey,
        scheduledIds.map((e) => e.toString()).toList(),
      );
      _lastSyncSignature = signature;
    } finally {
      _syncing = false;
      final pending = _pendingVehicles;
      final pendingForce = _pendingForce;
      _pendingVehicles = null;
      _pendingForce = false;
      if (pending != null) {
        await syncVehicles(pending, force: pendingForce);
      }
    }
  }

  Future<List<int>> _scheduleMaintenanceDues({
    required Vehicle vehicle,
    required List<Maintenance> maintenances,
  }) async {
    final ids = <int>[];
    final vehicleLabel = _vehicleLabel(vehicle);

    for (final m in maintenances) {
      // Rappels par élément (nouveau formulaire).
      var scheduledItemReminder = false;
      for (final item in m.items) {
        final due = item.nextDueDate;
        if (due == null) continue;
        scheduledItemReminder = true;
        ids.addAll(
          await _scheduleDateBasedReminder(
            vehicle: vehicle,
            idSeed: 'maint_${m.id}_${item.category}_${item.name}',
            title: 'Prochain entretien',
            expiry: due,
            vehicleLabel: vehicleLabel,
            kindLabel: item.name.trim().isNotEmpty ? item.name : 'Entretien',
            upcomingWording: true,
          ),
        );
      }

      // Compatibilité : anciennes interventions avec échéance globale seulement.
      if (!scheduledItemReminder && m.nextDueDate != null) {
        final kindLabel =
            m.title.trim().isNotEmpty ? m.title.trim() : 'Entretien';
        ids.addAll(
          await _scheduleDateBasedReminder(
            vehicle: vehicle,
            idSeed: 'maint_${m.id}',
            title: 'Prochain entretien',
            expiry: m.nextDueDate!,
            vehicleLabel: vehicleLabel,
            kindLabel: kindLabel,
            upcomingWording: true,
          ),
        );
      }
    }
    return ids;
  }

  Future<void> _cancelAllScheduledNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsIdsKey) ?? const <String>[];
    for (final idStr in raw) {
      final id = int.tryParse(idStr);
      if (id != null) {
        await _plugin.cancel(id: id);
      }
    }
    await prefs.remove(_prefsIdsKey);

    // Nettoie aussi les planifications orphelines (anciennes versions / IDs
    // non suivis) pour qu’un changement de date coupe vraiment les rappels.
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final request in pending) {
        await _plugin.cancel(id: request.id);
      }
    } catch (e) {
      debugPrint('Cancel pending notifications failed: $e');
    }

    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('cancelAll notifications failed: $e');
    }
  }

  Future<List<int>> _scheduleRoutine(Vehicle vehicle) async {
    final ids = <int>[];
    final statuses = vehicle.routine.allStatuses(
      currentMileage: vehicle.mileage,
    );
    final vehicleLabel = _vehicleLabel(vehicle);

    for (final status in statuses) {
      if (status.nextDueDate != null) {
        ids.addAll(
          await _scheduleDateBasedReminder(
            vehicle: vehicle,
            idSeed: 'routine_${status.kind.name}',
            title: 'Entretien ${status.kind.label}',
            expiry: status.nextDueDate!,
            vehicleLabel: vehicleLabel,
            kindLabel: status.kind.label,
          ),
        );
      }

      // Km-only (ex. chaîne) : notif immédiate 1×/jour uniquement si due bientôt
      // ou en retard côté km — pas de planification infinie.
      if (status.nextDueDate == null &&
          (status.isOverdue || status.isDueSoon)) {
        final immediateId = _notificationId(
          '${vehicle.id}_routine_${status.kind.name}',
          _ExpiryKind.insurance,
          -2,
        );
        final today = _dateOnly(DateTime.now());
        final shown = await _wasImmediateShownToday(
          '${vehicle.id}_routine_${status.kind.name}',
          _ExpiryKind.insurance,
          today,
        );
        if (!shown) {
          try {
            await _plugin.show(
              id: immediateId,
              title: 'Entretien ${status.kind.label}',
              body: '$vehicleLabel — ${status.summary}',
              notificationDetails: _details,
            );
            await _markImmediateShownToday(
              '${vehicle.id}_routine_${status.kind.name}',
              _ExpiryKind.insurance,
              today,
            );
            ids.add(immediateId);
          } catch (e) {
            debugPrint('Routine immediate notification failed: $e');
          }
        }
      }
    }
    return ids;
  }

  Future<List<int>> _scheduleDateBasedReminder({
    required Vehicle vehicle,
    required String idSeed,
    required String title,
    required DateTime expiry,
    required String vehicleLabel,
    required String kindLabel,
    bool upcomingWording = false,
  }) async {
    return _scheduleKindWithLabels(
      vehicleId: vehicle.id,
      kindIndex: idSeed.hashCode,
      expiry: expiry,
      title: title,
      vehicleLabel: vehicleLabel,
      kindLabel: kindLabel,
      upcomingWording: upcomingWording,
    );
  }

  Future<List<int>> _scheduleKind({
    required Vehicle vehicle,
    required _ExpiryKind kind,
    required DateTime? expiry,
  }) async {
    if (expiry == null) return const [];
    return _scheduleKindWithLabels(
      vehicleId: vehicle.id,
      kindIndex: kind.index,
      expiry: expiry,
      title: 'Échéance ${_kindLabel(kind)}',
      vehicleLabel: _vehicleLabel(vehicle),
      kindLabel: _kindLabel(kind),
    );
  }

  /// Planifie uniquement les jours de la fenêtre [J−7 … jour J].
  /// Si la date est déjà dépassée, aucune notification n’est programmée
  /// (l’utilisateur doit saisir la nouvelle échéance).
  Future<List<int>> _scheduleKindWithLabels({
    required String vehicleId,
    required int kindIndex,
    required DateTime expiry,
    required String title,
    required String vehicleLabel,
    required String kindLabel,
    bool upcomingWording = false,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final expiryDay = _dateOnly(expiry);
    final today = _dateOnly(now);
    final windowStart = expiryDay.subtract(const Duration(days: _daysBefore));

    // Échéance déjà passée → plus de rappels quotidiens.
    if (today.isAfter(expiryDay)) {
      return const [];
    }

    final dateStr = DateFormat('dd/MM/yyyy').format(expiryDay);
    final ids = <int>[];
    final seedId = '${vehicleId}_$kindIndex';

    // Dans la fenêtre J−7 → J : une notif immédiate (1× / jour max).
    final inWindow =
        !today.isBefore(windowStart) && !today.isAfter(expiryDay);
    if (inWindow) {
      final daysLeftNow = expiryDay.difference(today).inDays;
      final immediateId = Object.hash(seedId, -1) & 0x7fffffff;
      final shownToday = await _wasImmediateShownTodayKey(seedId, today);
      if (!shownToday) {
        try {
          await _plugin.show(
            id: immediateId,
            title: title,
            body: _body(
              kindLabel: kindLabel,
              vehicleLabel: vehicleLabel,
              dateStr: dateStr,
              daysLeft: daysLeftNow,
              upcomingWording: upcomingWording,
            ),
            notificationDetails: _details,
            payload: 'vehicle_expiry:$seedId',
          );
          await _markImmediateShownTodayKey(seedId, today);
          ids.add(immediateId);
        } catch (e) {
          debugPrint('Expiry immediate notification failed: $e');
        }
      }
    }

    // Planifie chaque jour restant de la fenêtre (demain → jour J).
    var day = windowStart;
    if (day.isBefore(today)) {
      day = today.add(const Duration(days: 1));
    }
    var index = 0;
    while (!day.isAfter(expiryDay)) {
      final scheduled = tz.TZDateTime(
        tz.local,
        day.year,
        day.month,
        day.day,
        _notifyHour,
        _notifyMinute,
      );
      if (scheduled.isAfter(now)) {
        final daysLeft = expiryDay.difference(day).inDays;
        final id = Object.hash(seedId, index) & 0x7fffffff;
        final body = _body(
          kindLabel: kindLabel,
          vehicleLabel: vehicleLabel,
          dateStr: dateStr,
          daysLeft: daysLeft,
          upcomingWording: upcomingWording,
        );

        try {
          await _plugin.zonedSchedule(
            id: id,
            title: title,
            body: body,
            scheduledDate: scheduled,
            notificationDetails: _details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            payload: 'vehicle_expiry:$seedId',
          );
          ids.add(id);
        } catch (e) {
          debugPrint('Expiry notification schedule failed ($id): $e');
        }
      }
      day = day.add(const Duration(days: 1));
      index++;
    }

    return ids;
  }

  NotificationDetails get _details => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

  String _body({
    required String kindLabel,
    required String vehicleLabel,
    required String dateStr,
    required int daysLeft,
    bool upcomingWording = false,
  }) {
    if (upcomingWording) {
      if (daysLeft > 1) {
        return '$kindLabel — $vehicleLabel : prévu le $dateStr (dans $daysLeft jours)';
      }
      if (daysLeft == 1) {
        return '$kindLabel — $vehicleLabel : prévu demain ($dateStr)';
      }
      return '$kindLabel — $vehicleLabel : prévu aujourd’hui ($dateStr)';
    }

    if (daysLeft > 1) {
      return '$kindLabel — $vehicleLabel : expire le $dateStr (dans $daysLeft jours)';
    }
    if (daysLeft == 1) {
      return '$kindLabel — $vehicleLabel : expire demain ($dateStr)';
    }
    return '$kindLabel — $vehicleLabel : expire aujourd’hui ($dateStr)';
  }

  String _kindLabel(_ExpiryKind kind) {
    switch (kind) {
      case _ExpiryKind.insurance:
        return 'Assurance';
      case _ExpiryKind.inspection:
        return 'Visite technique';
      case _ExpiryKind.tax:
        return 'Vignette / taxe';
    }
  }

  String _vehicleLabel(Vehicle vehicle) {
    final plate = vehicle.plateNumber?.trim();
    final name = '${vehicle.brand} ${vehicle.model}'.trim();
    if (plate != null && plate.isNotEmpty) return '$name ($plate)';
    return name;
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<bool> _wasImmediateShownToday(
    String vehicleId,
    _ExpiryKind kind,
    DateTime today,
  ) async {
    return _wasImmediateShownTodayKey(
      '${vehicleId}_${kind.name}',
      today,
    );
  }

  Future<void> _markImmediateShownToday(
    String vehicleId,
    _ExpiryKind kind,
    DateTime today,
  ) async {
    await _markImmediateShownTodayKey('${vehicleId}_${kind.name}', today);
  }

  Future<bool> _wasImmediateShownTodayKey(String key, DateTime today) async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getString('expiry_immediate_$key');
    return last == DateFormat('yyyy-MM-dd').format(today);
  }

  Future<void> _markImmediateShownTodayKey(String key, DateTime today) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'expiry_immediate_$key',
      DateFormat('yyyy-MM-dd').format(today),
    );
  }

  int _notificationId(String vehicleId, _ExpiryKind kind, int dayIndex) {
    final raw = Object.hash(vehicleId, kind.index, dayIndex);
    return raw & 0x7fffffff;
  }
}
