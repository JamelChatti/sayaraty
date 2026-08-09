// import 'package:flutter/material.dart';
// import '../../../../core/utils/currency_formatter.dart';
// import '../../../settings/domain/app_settings.dart';
// import '../../domain/models/maintenance_item.dart';
//
// class _EditableMaintenanceItem extends StatefulWidget {
//   final MaintenanceItem item;
//   final ValueChanged<MaintenanceItem> onChanged;
//   final CurrencyEnum currency;
//
//   const _EditableMaintenanceItem({
//     required Key key,
//     required this.item,
//     required this.onChanged,
//     required this.currency,
//   }) : super(key: key);
//
//   @override
//   State<_EditableMaintenanceItem> createState() =>
//       _EditableMaintenanceItemState();
// }
//
// class _EditableMaintenanceItemState extends State<_EditableMaintenanceItem> {
//   late MaintenanceItem _currentItem;
//   late TextEditingController _brandController;
//   late TextEditingController _priceController;
//   late TextEditingController _quantityController;
//
//   @override
//   void initState() {
//     super.initState();
//     _currentItem = widget.item;
//     _brandController = TextEditingController(text: _currentItem.brand ?? '');
//     _priceController = TextEditingController(
//       text: _currentItem.price == 0 ? '' : _currentItem.price.toString(),
//     );
//     _quantityController = TextEditingController(
//       text: _currentItem.quantity.toString(),
//     );
//   }
//
//   @override
//   void didUpdateWidget(_EditableMaintenanceItem oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     // Ne met à jour depuis le parent que si l'item a vraiment changé
//     // et seulement si nous ne sommes pas en train d'éditer
//     if (oldWidget.item != widget.item &&
//         _currentItem.price.toString() == _priceController.text) {
//       _currentItem = widget.item;
//       _brandController.text = _currentItem.brand ?? '';
//       _priceController.text = _currentItem.price == 0 ? '' : _currentItem.price.toString();
//       _quantityController.text = _currentItem.quantity.toString();
//     }
//   }
//
//   @override
//   void dispose() {
//     _brandController.dispose();
//     _priceController.dispose();
//     _quantityController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 4),
//       child: CheckboxListTile(
//         title: Text(_currentItem.name),
//         value: _currentItem.isSelected,
//         onChanged: (bool? value) {
//           if (value != null) {
//             setState(() => _currentItem = _currentItem.copyWith(isSelected: value));
//             widget.onChanged(_currentItem);
//           }
//         },
//         subtitle: _currentItem.isSelected
//             ? Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               controller: _brandController,
//               decoration: const InputDecoration(
//                 labelText: 'Marque (optionnel)',
//                 border: OutlineInputBorder(),
//               ),
//               onChanged: (v) {
//                 _currentItem = _currentItem.copyWith(
//                   brand: v.trim().isEmpty ? null : v.trim(),
//                 );
//                 widget.onChanged(_currentItem);
//               },
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: // Alternative avec TextField.withoutController
//                   TextField(
//                     decoration: InputDecoration(
//                       labelText: 'Prix',
//                       hintText: widget.currency == CurrencyEnum.tnd ? '0.000' : '0.00',
//                       border: const OutlineInputBorder(),
//                     ),
//                     keyboardType: TextInputType.numberWithOptions(decimal: true),
//                     onChanged: (value) {
//                       final cleanValue = value.replaceAll(',', '.');
//                       final parsedValue = double.tryParse(cleanValue) ?? 0;
//                       _currentItem = _currentItem.copyWith(price: parsedValue);
//                       widget.onChanged(_currentItem);
//                     },
//                   ),
//                 ),
//                 if (_currentItem.category != 'engine_oil' && _currentItem.name != 'Autre') ...[
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: TextField(
//                       controller: _quantityController,
//                       decoration: const InputDecoration(
//                         labelText: 'Quantité',
//                         border: OutlineInputBorder(),
//                       ),
//                       keyboardType: TextInputType.number,
//                       onChanged: (v) {
//                         final val = int.tryParse(v) ?? 1;
//                         _currentItem = _currentItem.copyWith(quantity: val);
//                         widget.onChanged(_currentItem);
//                       },
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'Sous-total : ${formatCurrency(_currentItem.price * _currentItem.quantity, widget.currency)}',
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.green,
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         )
//             : null,
//       ),
//     );
//   }
// }
