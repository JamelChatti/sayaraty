import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../data/car_brands.dart';


class BrandDropdown extends StatelessWidget {
  final TextEditingController controller;

  const BrandDropdown({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return DropdownSearch<String>(
      items: getCarBrands(),
      selectedItem:
      controller.text.isEmpty ? null : controller.text,
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: const TextFieldProps(
          decoration: InputDecoration(
            hintText: 'Rechercher une marque...',
          ),
        ),
      ),
      dropdownDecoratorProps: const DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: 'Marque *',
          border: OutlineInputBorder(),
        ),
      ),
      onChanged: (value) {
        controller.text = value ?? '';
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Champ obligatoire';
        }
        return null;
      },
    );
  }
}
