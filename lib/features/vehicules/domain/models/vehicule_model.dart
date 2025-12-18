import 'package:cloud_firestore/cloud_firestore.dart';

class Vehicle {
  final String id;
  final String userId;

  // Infos principales
  final String brand;
  final String model;
  final String? plateNumber;
  final String? vin;

  // Données techniques
  final int year;
  final double? mileage;

  // Dates administratives
  final DateTime? insuranceExpiry;
  final DateTime? technicalInspectionExpiry;
  final DateTime? taxExpiry;

  // Métadonnées
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> attachments;
  final List<String> sharedWith;
  final String? mainPhotoUrl;

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
  this.attachments = const [],
    required this.sharedWith,
    this.mainPhotoUrl,
  });

  // ----------------------------
  // Firestore mapping
  // ----------------------------

  factory Vehicle.fromMap(Map<String, dynamic> map, String documentId) {
    // Vérifiez les champs obligatoires

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

    DateTime? _toDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value); // ISO 8601
      throw Exception('Format de date non supporté: ${value.runtimeType}');
    }

    return Vehicle(
      id: documentId,
      userId: map['userId'] as String,
      brand: map['brand'] as String,
      model: map['model'] as String,
      plateNumber: map['plateNumber'] as String?,
      vin: map['vin'] as String?,
      year: map['year'] as int,
      mileage: (map['mileage'] as num?)?.toDouble(),
      insuranceExpiry: _toDate(map['insuranceExpiry']),
      technicalInspectionExpiry: _toDate(map['technicalInspectionExpiry']),
      taxExpiry: _toDate(map['taxExpiry']),
      createdAt: _toDate(map['createdAt'])!,
      updatedAt: _toDate(map['updatedAt']),
      attachments: List<String>.from(map['attachments'] ?? []),
      sharedWith: List<String>.from(map['sharedWith'] ?? []),
      mainPhotoUrl: map['mainPhotoUrl'] as String?,
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
      'attachments': attachments,
      'sharedWith': sharedWith,
      'mainPhotoUrl': mainPhotoUrl,
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
    List<String>? attachments,
    List<String>? sharedWith,
    String? mainPhotoUrl,
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
      attachments: attachments ?? this.attachments,
        sharedWith: sharedWith ?? this.sharedWith,
      mainPhotoUrl: mainPhotoUrl ?? this.mainPhotoUrl,

    );
  }
}
