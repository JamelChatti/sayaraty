// lib/features/vehicles/domain/models/vehicle_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'routine_maintenance.dart';
import 'shared_access_model.dart';

/// Motorisation du véhicule.
enum VehiclePowertrain {
  electric,
  hybrid,
  mechanical,
}

extension VehiclePowertrainX on VehiclePowertrain {
  String get label {
    switch (this) {
      case VehiclePowertrain.electric:
        return 'Électrique';
      case VehiclePowertrain.hybrid:
        return 'Hybride';
      case VehiclePowertrain.mechanical:
        return 'Mécanique';
    }
  }

  bool get needsFuelType => this != VehiclePowertrain.electric;
}

/// Carburant (si non 100 % électrique).
enum VehicleFuelType { petrol, diesel }

extension VehicleFuelTypeX on VehicleFuelType {
  String get label {
    switch (this) {
      case VehicleFuelType.petrol:
        return 'Essence';
      case VehicleFuelType.diesel:
        return 'Diesel';
    }
  }
}

class Vehicle {
  final String id;
  final String userId;
  final String ownerId;

  // Infos principales
  final String brand;
  final String model;
  final String? plateNumber;
  final String? vin;

  // Données techniques
  final int year;
  final double? mileage;
  final VehiclePowertrain? powertrain;
  final VehicleFuelType? fuelType;

  /// Date de première mise en circulation
  final DateTime? dpmc;

  // Dates administratives
  final DateTime? insuranceExpiry;
  final DateTime? technicalInspectionExpiry;
  final DateTime? taxExpiry;

  /// Intervalles d'entretiens de routine (vidange, pneus, chaîne, batterie).
  final RoutineMaintenanceSettings routine;

  // Métadonnées
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> attachments;
  final List<SharedAccess> sharedWith;
  final List<String> sharedWithUserIds;
  final String? mainPhotoUrl;
  final String? ownerName;

  Vehicle({
    required this.id,
    required this.userId,
    required this.ownerId,
    required this.brand,
    required this.model,
    this.plateNumber,
    this.vin,
    required this.year,
    this.mileage,
    this.powertrain,
    this.fuelType,
    this.dpmc,
    this.insuranceExpiry,
    this.technicalInspectionExpiry,
    this.taxExpiry,
    this.routine = const RoutineMaintenanceSettings(),
    required this.createdAt,
    this.updatedAt,
    this.attachments = const [],
    required this.sharedWith,
    this.sharedWithUserIds = const [],
    this.mainPhotoUrl,
    this.ownerName,
  });

  // Helper method to parse sharedWith
  static List<SharedAccess> parseSharedWith(dynamic value) {
    if (value == null) return [];
    if (value is! List) return [];

    return value.map((item) {
      if (item is Map<String, dynamic>) {
        return SharedAccess.fromMap(item);
      } else if (item is String) {
        // Legacy format: convert String to SharedAccess
        return SharedAccess(
          userId: item,
          email: '',
          displayName: null,
          permissions: ['view'],
          sharedAt: DateTime.now(),
        );
      }
      return SharedAccess(
        userId: '',
        email: '',
        displayName: null,
        permissions: [],
        sharedAt: DateTime.now(),
      );
    }).toList();
  }

  // Helper method to convert dates
  static DateTime? toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  factory Vehicle.fromMap(Map<String, dynamic> map, String documentId) {
    final userId = map['userId'];
    final brand = map['brand'];
    final model = map['model'];
    final year = map['year'];
    final createdAt = map['createdAt'];
    final ownerId = map['ownerId'];

    if (userId == null) throw Exception('Champ "userId" manquant');
    if (brand == null) throw Exception('Champ "brand" manquant');
    if (model == null) throw Exception('Champ "model" manquant');
    if (year == null) throw Exception('Champ "year" manquant');
    if (createdAt == null) throw Exception('Champ "createdAt" manquant');
    if (ownerId == null) throw Exception('Champ "ownerId" manquant');

    return Vehicle(
      id: documentId,
      userId: userId as String,
      ownerId: ownerId as String,
      brand: brand as String,
      model: model as String,
      plateNumber: map['plateNumber'] as String?,
      vin: map['vin'] as String?,
      year: (year as num).toInt(),
      mileage: (map['mileage'] as num?)?.toDouble(),
      powertrain: _powertrainFrom(map['powertrain']),
      fuelType: _fuelTypeFrom(map['fuelType']),
      dpmc: toDate(map['dpmc'] ?? map['firstRegistrationDate']),
      insuranceExpiry: toDate(map['insuranceExpiry']),
      technicalInspectionExpiry: toDate(
        map['technicalInspectionExpiry'] ?? map['inspectionExpiry'],
      ),
      taxExpiry: toDate(map['taxExpiry'] ?? map['vignetteExpiry']),
      routine: RoutineMaintenanceSettings.fromMap(
        map['routine'] is Map
            ? Map<String, dynamic>.from(map['routine'] as Map)
            : null,
      ),
      createdAt: toDate(createdAt)!,
      updatedAt: toDate(map['updatedAt']),
      attachments: List<String>.from(map['attachments'] ?? []),
      sharedWith: parseSharedWith(map['sharedWith']),
      sharedWithUserIds: List<String>.from(map['sharedWithUserIds'] ?? []),
      mainPhotoUrl: map['mainPhotoUrl'] as String?,
      ownerName: map['ownerName'] as String?,
    );
  }

  static VehiclePowertrain? _powertrainFrom(dynamic value) {
    if (value is! String) return null;
    for (final e in VehiclePowertrain.values) {
      if (e.name == value) return e;
    }
    return null;
  }

  static VehicleFuelType? _fuelTypeFrom(dynamic value) {
    if (value is! String) return null;
    if (value == 'essence' || value == 'gasoline') {
      return VehicleFuelType.petrol;
    }
    for (final e in VehicleFuelType.values) {
      if (e.name == value) return e;
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'ownerId': ownerId,
      'brand': brand,
      'model': model,
      'plateNumber': plateNumber,
      'vin': vin,
      'year': year,
      'mileage': mileage,
      'powertrain': powertrain?.name,
      'fuelType': fuelType?.name,
      'dpmc': dpmc,
      'insuranceExpiry': insuranceExpiry,
      'technicalInspectionExpiry': technicalInspectionExpiry,
      'taxExpiry': taxExpiry,
      'routine': routine.toMap(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'attachments': attachments,
      'sharedWith': sharedWith.map((access) => access.toMap()).toList(),
      'sharedWithUserIds': sharedWithUserIds,
      'mainPhotoUrl': mainPhotoUrl,
      'ownerName': ownerName,
    };
  }

  // Helper methods
  bool hasAccess(String userId) {
    return this.userId == userId ||
        this.ownerId == userId ||
        sharedWith.any((access) => access.userId == userId);
  }

  List<String> getUserPermissions(String userId) {
    if (this.userId == userId || this.ownerId == userId) {
      return ['view', 'edit', 'delete', 'share'];
    }

    final access = sharedWith.firstWhere(
          (access) => access.userId == userId,
      orElse: () => SharedAccess(
        userId: '',
        email: '',
        permissions: [],
        sharedAt: DateTime.now(),
      ),
    );

    return access.permissions;
  }

  static const _unset = Object();

  Vehicle copyWith({
    String? id,
    String? userId,
    String? ownerId,
    String? brand,
    String? model,
    String? plateNumber,
    String? vin,
    int? year,
    double? mileage,
    Object? powertrain = _unset,
    Object? fuelType = _unset,
    Object? dpmc = _unset,
    Object? insuranceExpiry = _unset,
    Object? technicalInspectionExpiry = _unset,
    Object? taxExpiry = _unset,
    RoutineMaintenanceSettings? routine,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? attachments,
    List<SharedAccess>? sharedWith,
    String? mainPhotoUrl,
    String? ownerName,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ownerId: ownerId ?? this.ownerId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      plateNumber: plateNumber ?? this.plateNumber,
      vin: vin ?? this.vin,
      year: year ?? this.year,
      mileage: mileage ?? this.mileage,
      powertrain: identical(powertrain, _unset)
          ? this.powertrain
          : powertrain as VehiclePowertrain?,
      fuelType: identical(fuelType, _unset)
          ? this.fuelType
          : fuelType as VehicleFuelType?,
      dpmc: identical(dpmc, _unset) ? this.dpmc : dpmc as DateTime?,
      insuranceExpiry: identical(insuranceExpiry, _unset)
          ? this.insuranceExpiry
          : insuranceExpiry as DateTime?,
      technicalInspectionExpiry: identical(technicalInspectionExpiry, _unset)
          ? this.technicalInspectionExpiry
          : technicalInspectionExpiry as DateTime?,
      taxExpiry: identical(taxExpiry, _unset)
          ? this.taxExpiry
          : taxExpiry as DateTime?,
      routine: routine ?? this.routine,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
      sharedWith: sharedWith ?? this.sharedWith,
      mainPhotoUrl: mainPhotoUrl ?? this.mainPhotoUrl,
      ownerName: ownerName ?? this.ownerName,
    );
  }
}