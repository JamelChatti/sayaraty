import 'package:equatable/equatable.dart';

class MaintenanceItem extends Equatable {
  final String? id;
  final String name;
  final String category;
  final bool isSelected;
  final String? brand;
  final double price;
  final double quantity;
  final String description; // Non-nullable
  final double taxRate;

  const MaintenanceItem({
    this.id,
    required this.name,
    required this.category,
    this.isSelected = false,
    this.brand,
    this.price = 0.0,
    this.quantity = 1.0,
    this.description =
        '', // ✅ Correction : Valeur par défaut vide au lieu de null
    this.taxRate = 19.0, // Valeur par défaut à 19%
  });

  // Calcul du prix TTC pour cet item
  double get priceWithTax => price * quantity * (1 + taxRate / 100);

  MaintenanceItem copyWith({
    String? id,
    String? name,
    String? category,
    bool? isSelected,
    String? brand,
    double? price,
    double? quantity,
    String? description,
    double? taxRate,
  }) {
    return MaintenanceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      isSelected: isSelected ?? this.isSelected,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
      taxRate: taxRate ?? this.taxRate,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'isSelected': isSelected,
    'brand': brand,
    'price': price,
    'quantity': quantity,
    'description': description, // ✅ Ajouté pour Firebase
    'taxRate': taxRate,
  };

  factory MaintenanceItem.fromMap(Map<String, dynamic> map) => MaintenanceItem(
    name: map['name'] ?? '',
    category: map['category'] ?? '',
    isSelected: map['isSelected'] ?? false,
    brand: map['brand'],
    price: (map['price'] as num?)?.toDouble() ?? 0.0,
    quantity: (map['quantity'] as num?)?.toDouble() ?? 1.0,
    description: map['description'] ?? '',
    // ✅ Ajouté pour Firebase
    taxRate: (map['taxRate'] as num?)?.toDouble() ?? 19.0,
  );

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
  ];
}
