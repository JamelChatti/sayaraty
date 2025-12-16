import 'package:cloud_firestore/cloud_firestore.dart';

class Vehicle {
  final String id;
  final String userId;

  final String brand;
  final String model;
  final String? plateNumber;
  final String? vin;

  final int year;
  final double? mileage;

  final DateTime? insuranceExpiry;
  final DateTime? technicalInspectionExpiry;
  final DateTime? taxExpiry;

  final DateTime createdAt;
  final DateTime? updatedAt;

  Vehicle({
    required this.id,
    required this.userId,
    required this.brand,
    required this.model,
    this.plateNumber,
    this.vin,
    required this.year,
    this.mileage,
    this.insuranceExpiry,
    this.technicalInspectionExpiry,
    this.taxExpiry,
    required this.createdAt,
    this.updatedAt,
  });

  // ----------------------------
  // Firestore mapping (CORRECT)
  // ----------------------------

  factory Vehicle.fromMap(Map<String, dynamic> map, String documentId) {
    final userId = map['userId'];
    final brand = map['brand'];
    final model = map['model'];
    final year = map['year'];
    final createdAt = map['createdAt'];

    if (userId == null) throw Exception('Champ "userId" manquant');
    if (brand == null) throw Exception('Champ "brand" manquant');
    if (model == null) throw Exception('Champ "model" manquant');
    if (year == null) throw Exception('Champ "year" manquant');
    if (createdAt == null) throw Exception('Champ "createdAt" manquant');

    return Vehicle(
      id: documentId, // ✅ ID Firestore
      userId: userId as String,
      brand: brand as String,
      model: model as String,
      plateNumber: map['plateNumber'] as String?,
      vin: map['vin'] as String?,
      year: year as int,
      mileage: (map['mileage'] as num?)?.toDouble(),
      insuranceExpiry: (map['insuranceExpiry'] as Timestamp?)?.toDate(),
      technicalInspectionExpiry:
      (map['technicalInspectionExpiry'] as Timestamp?)?.toDate(),
      taxExpiry: (map['taxExpiry'] as Timestamp?)?.toDate(),
      createdAt: (createdAt as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'brand': brand,
      'model': model,
      'plateNumber': plateNumber,
      'vin': vin,
      'year': year,
      'mileage': mileage,
      'insuranceExpiry': insuranceExpiry,
      'technicalInspectionExpiry': technicalInspectionExpiry,
      'taxExpiry': taxExpiry,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

// ----------------------------
// copyWith extension
// ----------------------------

extension VehicleCopyWith on Vehicle {
  Vehicle copyWith({
    String? id,
    String? userId,
    String? brand,
    String? model,
    String? plateNumber,
    String? vin,
    int? year,
    double? mileage,
    DateTime? insuranceExpiry,
    DateTime? technicalInspectionExpiry,
    DateTime? taxExpiry,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      plateNumber: plateNumber ?? this.plateNumber,
      vin: vin ?? this.vin,
      year: year ?? this.year,
      mileage: mileage ?? this.mileage,
      insuranceExpiry: insuranceExpiry ?? this.insuranceExpiry,
      technicalInspectionExpiry:
      technicalInspectionExpiry ?? this.technicalInspectionExpiry,
      taxExpiry: taxExpiry ?? this.taxExpiry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
