import 'package:flutter/material.dart';
import '../../data/vehicle_brand_service.dart';

class BrandDropdown extends StatefulWidget {
  final TextEditingController controller;

  const BrandDropdown({super.key, required this.controller});

  @override
  State<BrandDropdown> createState() => _BrandDropdownState();
}

class _BrandDropdownState extends State<BrandDropdown> {
  late Future<List<String>> _brandsFuture;

  @override
  void initState() {
    super.initState();
    _brandsFuture = VehicleBrandService().fetchBrands();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _brandsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) {
          return TextFormField(
            controller: widget.controller,
            decoration: const InputDecoration(
              labelText: 'Marque *',
              helperText: 'Saisie manuelle (API indisponible)',
            ),
            validator: (v) =>
            v == null || v.isEmpty ? 'Champ obligatoire' : null,
          );
        }

        final brands = snapshot.data!;
        return DropdownButtonFormField<String>(
          value: widget.controller.text.isEmpty
              ? null
              : widget.controller.text,
          decoration: const InputDecoration(labelText: 'Marque *'),
          items: brands
              .map(
                (b) => DropdownMenuItem(
              value: b,
              child: Text(b),
            ),
          )
              .toList(),
          onChanged: (value) {
            widget.controller.text = value ?? '';
          },
          validator: (v) =>
          v == null || v.isEmpty ? 'Champ obligatoire' : null,
        );
      },
    );
  }
}
