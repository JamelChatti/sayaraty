import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../maintenance/domain/models/maintenance_model.dart';

/// Types d'entretiens de routine suivis au kilométrage / au temps.
enum RoutineKind { oilChange, tires, timingBelt, battery }

extension RoutineKindX on RoutineKind {
  String get label {
    switch (this) {
      case RoutineKind.oilChange:
        return 'Vidange';
      case RoutineKind.tires:
        return 'Pneus';
      case RoutineKind.timingBelt:
        return 'Chaîne / courroie';
      case RoutineKind.battery:
        return 'Batterie';
    }
  }

  String get ruleHint {
    switch (this) {
      case RoutineKind.oilChange:
        return 'Kilométrage ou délai (le premier atteint)';
      case RoutineKind.tires:
        return 'Kilométrage ou délai (le premier atteint)';
      case RoutineKind.timingBelt:
        return 'Kilométrage uniquement';
      case RoutineKind.battery:
        return 'Durée en mois uniquement';
    }
  }

  MaintenanceType get maintenanceType {
    switch (this) {
      case RoutineKind.oilChange:
        return MaintenanceType.oilChange;
      case RoutineKind.tires:
        return MaintenanceType.tires;
      case RoutineKind.timingBelt:
        return MaintenanceType.timingBelt;
      case RoutineKind.battery:
        return MaintenanceType.battery;
    }
  }

  static RoutineKind? fromMaintenanceType(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.oilChange:
        return RoutineKind.oilChange;
      case MaintenanceType.tires:
        return RoutineKind.tires;
      case MaintenanceType.timingBelt:
        return RoutineKind.timingBelt;
      case MaintenanceType.battery:
        return RoutineKind.battery;
      default:
        return null;
    }
  }
}

class RoutineDueStatus {
  final RoutineKind kind;
  final double? nextDueMileage;
  final DateTime? nextDueDate;
  final bool isOverdue;
  final bool isDueSoon;
  final String summary;

  const RoutineDueStatus({
    required this.kind,
    required this.nextDueMileage,
    required this.nextDueDate,
    required this.isOverdue,
    required this.isDueSoon,
    required this.summary,
  });
}

/// Intervalles + dernier entretien pour chaque routine.
class RoutineMaintenanceSettings {
  // Vidange : km + jours
  final double? oilIntervalKm;
  final int? oilIntervalDays;
  final double? oilLastMileage;
  final DateTime? oilLastDate;

  // Pneus : km + jours
  final double? tiresIntervalKm;
  final int? tiresIntervalDays;
  final double? tiresLastMileage;
  final DateTime? tiresLastDate;

  // Chaîne / courroie : km seul
  final double? timingBeltIntervalKm;
  final double? timingBeltLastMileage;
  final DateTime? timingBeltLastDate;

  // Batterie : mois seul
  final int? batteryIntervalMonths;
  final DateTime? batteryLastDate;

  const RoutineMaintenanceSettings({
    this.oilIntervalKm,
    this.oilIntervalDays,
    this.oilLastMileage,
    this.oilLastDate,
    this.tiresIntervalKm,
    this.tiresIntervalDays,
    this.tiresLastMileage,
    this.tiresLastDate,
    this.timingBeltIntervalKm,
    this.timingBeltLastMileage,
    this.timingBeltLastDate,
    this.batteryIntervalMonths,
    this.batteryLastDate,
  });

  /// Valeurs proposées à la première configuration.
  factory RoutineMaintenanceSettings.defaults() =>
      const RoutineMaintenanceSettings(
        oilIntervalKm: 10000,
        oilIntervalDays: 365,
        tiresIntervalKm: 40000,
        tiresIntervalDays: 730,
        timingBeltIntervalKm: 160000,
        batteryIntervalMonths: 48,
      );

  bool get hasAnyInterval =>
      oilIntervalKm != null ||
      oilIntervalDays != null ||
      tiresIntervalKm != null ||
      tiresIntervalDays != null ||
      timingBeltIntervalKm != null ||
      batteryIntervalMonths != null;

  Map<String, dynamic> toMap() => {
        'oilIntervalKm': oilIntervalKm,
        'oilIntervalDays': oilIntervalDays,
        'oilLastMileage': oilLastMileage,
        'oilLastDate': oilLastDate,
        'tiresIntervalKm': tiresIntervalKm,
        'tiresIntervalDays': tiresIntervalDays,
        'tiresLastMileage': tiresLastMileage,
        'tiresLastDate': tiresLastDate,
        'timingBeltIntervalKm': timingBeltIntervalKm,
        'timingBeltLastMileage': timingBeltLastMileage,
        'timingBeltLastDate': timingBeltLastDate,
        'batteryIntervalMonths': batteryIntervalMonths,
        'batteryLastDate': batteryLastDate,
      };

  factory RoutineMaintenanceSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return const RoutineMaintenanceSettings();
    }
    return RoutineMaintenanceSettings(
      oilIntervalKm: (map['oilIntervalKm'] as num?)?.toDouble(),
      oilIntervalDays: (map['oilIntervalDays'] as num?)?.toInt(),
      oilLastMileage: (map['oilLastMileage'] as num?)?.toDouble(),
      oilLastDate: _toDate(map['oilLastDate']),
      tiresIntervalKm: (map['tiresIntervalKm'] as num?)?.toDouble(),
      tiresIntervalDays: (map['tiresIntervalDays'] as num?)?.toInt(),
      tiresLastMileage: (map['tiresLastMileage'] as num?)?.toDouble(),
      tiresLastDate: _toDate(map['tiresLastDate']),
      timingBeltIntervalKm: (map['timingBeltIntervalKm'] as num?)?.toDouble(),
      timingBeltLastMileage: (map['timingBeltLastMileage'] as num?)?.toDouble(),
      timingBeltLastDate: _toDate(map['timingBeltLastDate']),
      batteryIntervalMonths: (map['batteryIntervalMonths'] as num?)?.toInt(),
      batteryLastDate: _toDate(map['batteryLastDate']),
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  RoutineMaintenanceSettings copyWith({
    Object? oilIntervalKm = _unset,
    Object? oilIntervalDays = _unset,
    Object? oilLastMileage = _unset,
    Object? oilLastDate = _unset,
    Object? tiresIntervalKm = _unset,
    Object? tiresIntervalDays = _unset,
    Object? tiresLastMileage = _unset,
    Object? tiresLastDate = _unset,
    Object? timingBeltIntervalKm = _unset,
    Object? timingBeltLastMileage = _unset,
    Object? timingBeltLastDate = _unset,
    Object? batteryIntervalMonths = _unset,
    Object? batteryLastDate = _unset,
  }) {
    return RoutineMaintenanceSettings(
      oilIntervalKm: identical(oilIntervalKm, _unset)
          ? this.oilIntervalKm
          : oilIntervalKm as double?,
      oilIntervalDays: identical(oilIntervalDays, _unset)
          ? this.oilIntervalDays
          : oilIntervalDays as int?,
      oilLastMileage: identical(oilLastMileage, _unset)
          ? this.oilLastMileage
          : oilLastMileage as double?,
      oilLastDate: identical(oilLastDate, _unset)
          ? this.oilLastDate
          : oilLastDate as DateTime?,
      tiresIntervalKm: identical(tiresIntervalKm, _unset)
          ? this.tiresIntervalKm
          : tiresIntervalKm as double?,
      tiresIntervalDays: identical(tiresIntervalDays, _unset)
          ? this.tiresIntervalDays
          : tiresIntervalDays as int?,
      tiresLastMileage: identical(tiresLastMileage, _unset)
          ? this.tiresLastMileage
          : tiresLastMileage as double?,
      tiresLastDate: identical(tiresLastDate, _unset)
          ? this.tiresLastDate
          : tiresLastDate as DateTime?,
      timingBeltIntervalKm: identical(timingBeltIntervalKm, _unset)
          ? this.timingBeltIntervalKm
          : timingBeltIntervalKm as double?,
      timingBeltLastMileage: identical(timingBeltLastMileage, _unset)
          ? this.timingBeltLastMileage
          : timingBeltLastMileage as double?,
      timingBeltLastDate: identical(timingBeltLastDate, _unset)
          ? this.timingBeltLastDate
          : timingBeltLastDate as DateTime?,
      batteryIntervalMonths: identical(batteryIntervalMonths, _unset)
          ? this.batteryIntervalMonths
          : batteryIntervalMonths as int?,
      batteryLastDate: identical(batteryLastDate, _unset)
          ? this.batteryLastDate
          : batteryLastDate as DateTime?,
    );
  }

  static const _unset = Object();

  /// Prochaine échéance après un entretien effectué.
  ({double? nextKm, DateTime? nextDate}) nextDueAfter({
    required RoutineKind kind,
    required double serviceMileage,
    required DateTime serviceDate,
  }) {
    switch (kind) {
      case RoutineKind.oilChange:
        return (
          nextKm: oilIntervalKm == null
              ? null
              : serviceMileage + oilIntervalKm!,
          nextDate: oilIntervalDays == null
              ? null
              : serviceDate.add(Duration(days: oilIntervalDays!)),
        );
      case RoutineKind.tires:
        return (
          nextKm: tiresIntervalKm == null
              ? null
              : serviceMileage + tiresIntervalKm!,
          nextDate: tiresIntervalDays == null
              ? null
              : serviceDate.add(Duration(days: tiresIntervalDays!)),
        );
      case RoutineKind.timingBelt:
        return (
          nextKm: timingBeltIntervalKm == null
              ? null
              : serviceMileage + timingBeltIntervalKm!,
          nextDate: null,
        );
      case RoutineKind.battery:
        return (
          nextKm: null,
          nextDate: batteryIntervalMonths == null
              ? null
              : DateTime(
                  serviceDate.year,
                  serviceDate.month + batteryIntervalMonths!,
                  serviceDate.day,
                ),
        );
    }
  }

  RoutineMaintenanceSettings recordService({
    required RoutineKind kind,
    required double mileage,
    required DateTime date,
  }) {
    switch (kind) {
      case RoutineKind.oilChange:
        return copyWith(oilLastMileage: mileage, oilLastDate: date);
      case RoutineKind.tires:
        return copyWith(tiresLastMileage: mileage, tiresLastDate: date);
      case RoutineKind.timingBelt:
        return copyWith(
          timingBeltLastMileage: mileage,
          timingBeltLastDate: date,
        );
      case RoutineKind.battery:
        return copyWith(batteryLastDate: date);
    }
  }

  List<RoutineDueStatus> allStatuses({
    required double? currentMileage,
    DateTime? now,
    int soonWithinDays = 30,
    double soonWithinKm = 500,
  }) {
    return RoutineKind.values
        .map(
          (k) => statusFor(
            k,
            currentMileage: currentMileage,
            now: now,
            soonWithinDays: soonWithinDays,
            soonWithinKm: soonWithinKm,
          ),
        )
        .whereType<RoutineDueStatus>()
        .toList();
  }

  RoutineDueStatus? statusFor(
    RoutineKind kind, {
    required double? currentMileage,
    DateTime? now,
    int soonWithinDays = 30,
    double soonWithinKm = 500,
  }) {
    final today = now ?? DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);

    double? lastKm;
    DateTime? lastDate;
    double? intervalKm;
    int? intervalDays;
    int? intervalMonths;

    switch (kind) {
      case RoutineKind.oilChange:
        lastKm = oilLastMileage;
        lastDate = oilLastDate;
        intervalKm = oilIntervalKm;
        intervalDays = oilIntervalDays;
      case RoutineKind.tires:
        lastKm = tiresLastMileage;
        lastDate = tiresLastDate;
        intervalKm = tiresIntervalKm;
        intervalDays = tiresIntervalDays;
      case RoutineKind.timingBelt:
        lastKm = timingBeltLastMileage;
        lastDate = timingBeltLastDate;
        intervalKm = timingBeltIntervalKm;
      case RoutineKind.battery:
        lastDate = batteryLastDate;
        intervalMonths = batteryIntervalMonths;
    }

    final hasInterval = intervalKm != null ||
        intervalDays != null ||
        intervalMonths != null;
    if (!hasInterval) return null;

    // Pas encore de point de départ → pas d'échéance calculable.
    if (lastKm == null && lastDate == null) {
      return RoutineDueStatus(
        kind: kind,
        nextDueMileage: null,
        nextDueDate: null,
        isOverdue: false,
        isDueSoon: false,
        summary: 'En attente du premier entretien',
      );
    }

    final next = nextDueAfter(
      kind: kind,
      serviceMileage: lastKm ?? currentMileage ?? 0,
      serviceDate: lastDate ?? todayDay,
    );

    final nextKm = next.nextKm;
    final nextDate = next.nextDate == null
        ? null
        : DateTime(next.nextDate!.year, next.nextDate!.month, next.nextDate!.day);

    var overdueByKm = false;
    var soonByKm = false;
    if (nextKm != null && currentMileage != null) {
      overdueByKm = currentMileage >= nextKm;
      soonByKm = !overdueByKm && (nextKm - currentMileage) <= soonWithinKm;
    }

    var overdueByDate = false;
    var soonByDate = false;
    if (nextDate != null) {
      overdueByDate = !todayDay.isBefore(nextDate);
      if (!overdueByDate) {
        final daysLeft = nextDate.difference(todayDay).inDays;
        soonByDate = daysLeft <= soonWithinDays;
      }
    }

    final isOverdue = overdueByKm || overdueByDate;
    final isDueSoon = !isOverdue && (soonByKm || soonByDate);

    final parts = <String>[];
    if (nextKm != null) {
      parts.add('à ${nextKm.toStringAsFixed(0)} km');
    }
    if (nextDate != null) {
      final d =
          '${nextDate.day.toString().padLeft(2, '0')}/${nextDate.month.toString().padLeft(2, '0')}/${nextDate.year}';
      parts.add('le $d');
    }

    String summary;
    if (isOverdue) {
      summary = 'En retard (${parts.join(' ou ')})';
    } else if (isDueSoon) {
      summary = 'Bientôt (${parts.join(' ou ')})';
    } else if (parts.isEmpty) {
      summary = 'Intervalle configuré';
    } else {
      summary = 'Prochain : ${parts.join(' ou ')}';
    }

    return RoutineDueStatus(
      kind: kind,
      nextDueMileage: nextKm,
      nextDueDate: nextDate,
      isOverdue: isOverdue,
      isDueSoon: isDueSoon,
      summary: summary,
    );
  }
}
