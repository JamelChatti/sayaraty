import 'package:equatable/equatable.dart';

import 'maintenance_item.dart';

// 🔹 Types d'intervention
enum MaintenanceType {
  oilChange,              // Vidange
  brakes,                 // Freins
  tires,                  // Pneus
  battery,                // Batterie
  timingBelt,             // Courroie
  technicalInspection,    // Contrôle technique
  repair,                 // Réparation
  other                   // Autre
}

// 🔹 Statut de l'intervention
enum MaintenanceStatus {
  completed,  // Terminée
  planned,    // Planifiée
  canceled,   // Annulée
}

// 🔹 Pièce détachée
class Part {
  final String name;
  final int quantity;
  final double unitPrice;

  const Part({
    required this.name,
    this.quantity = 1,
    this.unitPrice = 0.0,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };

  factory Part.fromMap(Map<String, dynamic> map) => Part(
    name: map['name'] as String,
    quantity: map['quantity'] as int? ?? 1,
    unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Part &&
              name == other.name &&
              quantity == other.quantity &&
              unitPrice == other.unitPrice;

  @override
  int get hashCode => name.hashCode ^ quantity.hashCode ^ unitPrice.hashCode;
}

// 🔹 Consommable (huile, filtre, etc.)
class Consumable {
  final String name;
  final double quantity;
  final String unit;
  final double unitPrice;

  const Consumable({
    required this.name,
    this.quantity = 0.0,
    this.unit = 'L',
    this.unitPrice = 0.0,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'unitPrice': unitPrice,
  };

  factory Consumable.fromMap(Map<String, dynamic> map) => Consumable(
    name: map['name'] as String,
    quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
    unit: map['unit'] as String? ?? 'L',
    unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Consumable &&
              name == other.name &&
              quantity == other.quantity &&
              unit == other.unit &&
              unitPrice == other.unitPrice;

  @override
  int get hashCode => name.hashCode ^ quantity.hashCode ^ unit.hashCode ^ unitPrice.hashCode;
}

// 🔹 Modèle principal : Maintenance
class Maintenance extends Equatable {
  final String id;
  final String userId;
  final String vehicleId;
  final MaintenanceType type;
  final String title;
  final String? description;
  final DateTime date;
  final double mileage;
  final String? garageName;
  final String? garageContact;
  final double cost;
  final String? receiptImageUrl;
  final double? nextDueMileage;
  final DateTime? nextDueDate;
  final MaintenanceStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? ownerId;
  final List<MaintenanceItem> items;

  const Maintenance({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.type,
    required this.title,
    this.description,
    required this.date,
    required this.mileage,
    this.garageName,
    this.garageContact,
    required this.cost,
    this.receiptImageUrl,
    this.nextDueMileage,
    this.nextDueDate,
    this.status = MaintenanceStatus.completed,
    required this.createdAt,
    this.updatedAt,
    this.ownerId,
    required this.items,
  });

  // Conversion vers Map (pour Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'vehicleId': vehicleId,
      'type': type.name,
      'title': title,
      'description': description,
      'date': date.millisecondsSinceEpoch,
      'mileage': mileage,
      'garageName': garageName,
      'garageContact': garageContact,
      'cost': cost,
      'receiptImageUrl': receiptImageUrl,
      'nextDueMileage': nextDueMileage,
      'nextDueDate': nextDueDate?.millisecondsSinceEpoch,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'ownerId': ownerId,
      'parts': <Map<String, dynamic>>[],
      'consumables': <Map<String, dynamic>>[],
    };
  }

  // Dans la classe Maintenance, ajoutez cette méthode :
  Maintenance copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    MaintenanceType? type,
    String? title,
    String? description,
    DateTime? date,
    double? mileage,
    String? garageName,
    String? garageContact,
    double? cost,
    String? receiptImageUrl,
    double? nextDueMileage,
    DateTime? nextDueDate,
    MaintenanceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ownerId,
    List<MaintenanceItem>? items,
  }) {
    return Maintenance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      mileage: mileage ?? this.mileage,
      garageName: garageName ?? this.garageName,
      garageContact: garageContact ?? this.garageContact,
      cost: cost ?? this.cost,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      nextDueMileage: nextDueMileage ?? this.nextDueMileage,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerId: ownerId ?? this.ownerId,
      items: items ?? this.items,
    );
  }

  // Création depuis Map (Firestore)
  factory Maintenance.fromMap(Map<String, dynamic> map) {
    final typeStr = map['type'] as String?;
    final statusStr = map['status'] as String?;

    return Maintenance(
      id: map['id'] as String,
      userId: map['userId'] as String,
      vehicleId: map['vehicleId'] as String,
      type: typeStr != null
          ? MaintenanceType.values.firstWhere((e) => e.name == typeStr, orElse: () => MaintenanceType.other)
          : MaintenanceType.other,
      title: map['title'] as String,
      description: map['description'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      mileage: (map['mileage'] as num).toDouble(),
      garageName: map['garageName'] as String?,
      garageContact: map['garageContact'] as String?,
      cost: (map['cost'] as num).toDouble(),
      receiptImageUrl: map['receiptImageUrl'] as String?,
      nextDueMileage: (map['nextDueMileage'] as num?)?.toDouble(),
      nextDueDate: map['nextDueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['nextDueDate'] as int)
          : null,
      status: statusStr != null
          ? MaintenanceStatus.values.firstWhere((e) => e.name == statusStr, orElse: () => MaintenanceStatus.completed)
          : MaintenanceStatus.completed,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      ownerId: map['ownerId'] as String?,
      updatedAt:
      map['updatedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] as int) : null,
      items: (map['maintenanceItems'] as List?)
          ?.map((e) => MaintenanceItem.fromMap(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    vehicleId,
    type,
    title,
    description,
    date,
    mileage,
    garageName,
    garageContact,
    cost,
    receiptImageUrl,
    nextDueMileage,
    nextDueDate,
    status,
    createdAt,
    ownerId,
    updatedAt,
  ];

}