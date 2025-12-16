// lib/features/maintenance/domain/models/maintenance_item.dart
import 'package:equatable/equatable.dart';

class MaintenanceItem extends Equatable {
  final String name;          // ex: "Filtre à huile"
  final String category;      // ex: "oil_filter", "air_filter", etc.
  final bool isSelected;      // cochée ou non
  final String? brand;        // marque (facultatif)
  final double price;         // prix unitaire
  final int quantity;         // quantité (généralement 1)

  const MaintenanceItem({
    required this.name,
    required this.category,
    this.isSelected = false,
    this.brand,
    this.price = 0.0,
    this.quantity = 1,
  });

  MaintenanceItem copyWith({
    String? name,
    String? category,
    bool? isSelected,
    String? brand,
    double? price,
    int? quantity,
  }) {
    return MaintenanceItem(
      name: name ?? this.name,
      category: category ?? this.category,
      isSelected: isSelected ?? this.isSelected,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'isSelected': isSelected,
    'brand': brand,
    'price': price,
    'quantity': quantity,
  };

  factory MaintenanceItem.fromMap(Map<String, dynamic> map) => MaintenanceItem(
    name: map['name'] as String,
    category: map['category'] as String,
    isSelected: map['isSelected'] as bool? ?? false,
    brand: map['brand'] as String?,
    price: (map['price'] as num?)?.toDouble() ?? 0.0,
    quantity: map['quantity'] as int? ?? 1,
  );

  @override
  List<Object?> get props => [name, category, isSelected, brand, price, quantity];
}