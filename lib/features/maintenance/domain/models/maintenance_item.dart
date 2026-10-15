import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class MaintenanceItem extends Equatable {
  final String? id;
  final String name;
  final String category;
  final bool isSelected;
  final String? brand;
  final double price;
  final double quantity;
  final String description;
  final double taxRate;
  /// Prochain km pour ce type d'opération (rappel).
  final double? nextDueMileage;
  /// Date approximative du prochain rappel (notification).
  final DateTime? nextDueDate;
  /// Plein complet — pertinent pour la catégorie carburant.
  final bool isFullTank;

  const MaintenanceItem({
    this.id,
    required this.name,
    required this.category,
    this.isSelected = false,
    this.brand,
    this.price = 0.0,
    this.quantity = 1.0,
    this.description = '',
    this.taxRate = 19.0,
    this.nextDueMileage,
    this.nextDueDate,
    this.isFullTank = false,
  });

  double get priceWithTax => price * quantity * (1 + taxRate / 100);

  bool get hasReminder => nextDueDate != null || nextDueMileage != null;

  static const _unset = Object();

  MaintenanceItem copyWith({
    String? id,
    String? name,
    String? category,
    bool? isSelected,
    Object? brand = _unset,
    double? price,
    double? quantity,
    String? description,
    double? taxRate,
    Object? nextDueMileage = _unset,
    Object? nextDueDate = _unset,
    bool? isFullTank,
  }) {
    return MaintenanceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      isSelected: isSelected ?? this.isSelected,
      brand: identical(brand, _unset) ? this.brand : brand as String?,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      taxRate: taxRate ?? this.taxRate,
      nextDueMileage: identical(nextDueMileage, _unset)
          ? this.nextDueMileage
          : nextDueMileage as double?,
      nextDueDate: identical(nextDueDate, _unset)
          ? this.nextDueDate
          : nextDueDate as DateTime?,
      isFullTank: isFullTank ?? this.isFullTank,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category,
        'isSelected': isSelected,
        'brand': brand,
        'price': price,
        'quantity': quantity,
        'description': description,
        'taxRate': taxRate,
        'nextDueMileage': nextDueMileage,
        'nextDueDate': nextDueDate?.millisecondsSinceEpoch,
        'isFullTank': isFullTank,
      };

  factory MaintenanceItem.fromMap(Map<String, dynamic> map) => MaintenanceItem(
        name: map['name'] as String? ?? '',
        category: map['category'] as String? ?? '',
        isSelected: map['isSelected'] as bool? ?? false,
        brand: map['brand'] as String?,
        price: (map['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
        description: map['description'] as String? ?? '',
        taxRate: (map['taxRate'] as num?)?.toDouble() ?? 19.0,
        nextDueMileage: (map['nextDueMileage'] as num?)?.toDouble(),
        nextDueDate: _optionalDate(map['nextDueDate']),
        isFullTank: map['isFullTank'] as bool? ?? false,
      );

  static DateTime? _optionalDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.round());
    }
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        isSelected,
        brand,
        price,
        quantity,
        description,
        taxRate,
        nextDueMileage,
        nextDueDate,
        isFullTank,
      ];
}
