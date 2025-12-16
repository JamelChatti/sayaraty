import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../domain/models/maintenance_item.dart';

class _EditableMaintenanceItem extends StatefulWidget {
  final MaintenanceItem item;
  final ValueChanged<MaintenanceItem> onChanged;

  const _EditableMaintenanceItem({required this.item, required this.onChanged});

  @override
  State<_EditableMaintenanceItem> createState() => _EditableMaintenanceItemState();
}

class _EditableMaintenanceItemState extends State<_EditableMaintenanceItem> {
  late bool _isSelected;
  late String? _brand;
  late double _price;
  late int _quantity;

  @override
  void initState() {
    final item = widget.item;
    _isSelected = item.isSelected;
    _brand = item.brand;
    _price = item.price;
    _quantity = item.quantity;
    super.initState();
  }

  void _update() {
    final updated = widget.item.copyWith(
      isSelected: _isSelected,
      brand: _brand?.isNotEmpty == true ? _brand : null,
      price: _price,
      quantity: _quantity,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: CheckboxListTile(
        title: Text(widget.item.name),
        value: _isSelected,
        onChanged: (value) {
          setState(() {
            _isSelected = value ?? false;
          });
          _update();
        },
        subtitle: _isSelected
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Marque (optionnel)'),
              onChanged: (v) {
                setState(() => _brand = v);
                _update();
              },
              controller: TextEditingController(text: _brand),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Prix (€)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final num = double.tryParse(v);
                      if (num != null) {
                        setState(() => _price = num);
                        _update();
                      }
                    },
                    controller: TextEditingController(text: _price.toString()),
                  ),
                ),
                if (widget.item.category != 'engine_oil') // quantité = 1 pour l'huile
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Qté'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final num = int.tryParse(v);
                        if (num != null && num > 0) {
                          setState(() => _quantity = num);
                          _update();
                        }
                      },
                      controller: TextEditingController(text: _quantity.toString()),
                    ),
                  ),
              ],
            ),
          ],
        )
            : null,
      ),
    );
  }
}