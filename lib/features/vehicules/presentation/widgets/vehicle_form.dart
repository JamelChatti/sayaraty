import 'package:flutter/material.dart';

import 'brand_dropdown.dart';

class VehicleForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  final TextEditingController brandController;
  final TextEditingController modelController;
  final TextEditingController plateController;
  final TextEditingController yearController;
  final TextEditingController mileageController;

  final DateTime? insuranceExpiry;
  final DateTime? inspectionExpiry;
  final DateTime? taxExpiry;

  final ValueChanged<DateTime?> onInsuranceExpiryChanged;
  final ValueChanged<DateTime?> onInspectionExpiryChanged;
  final ValueChanged<DateTime?> onTaxExpiryChanged;

  const VehicleForm({
    super.key,
    required this.formKey,
    required this.brandController,
    required this.modelController,
    required this.plateController,
    required this.yearController,
    required this.mileageController,
    required this.insuranceExpiry,
    required this.inspectionExpiry,
    required this.taxExpiry,
    required this.onInsuranceExpiryChanged,
    required this.onInspectionExpiryChanged,
    required this.onTaxExpiryChanged,
  });

  Future<void> _pickDate(
      BuildContext context,
      DateTime? current,
      ValueChanged<DateTime?> onChanged,
      ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onChanged(picked);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non défini';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // --------------------
          // Marque
          // --------------------
          BrandDropdown(
            controller: brandController,
          ),

          // --------------------
          // Modèle
          // --------------------
          TextFormField(
            controller: modelController,
            decoration: const InputDecoration(labelText: 'Modèle *'),
            validator: (v) =>
            v == null || v.trim().isEmpty ? 'Champ obligatoire' : null,
          ),

          // --------------------
          // Immatriculation
          // --------------------
          TextFormField(
            controller: plateController,
            decoration:
            const InputDecoration(labelText: 'Immatriculation'),
          ),

          // --------------------
          // Année
          // --------------------
          TextFormField(
            controller: yearController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Année *'),
            validator: (v) {
              final year = int.tryParse(v ?? '');
              if (year == null) return 'Année invalide';
              if (year < 1900 || year > DateTime.now().year + 1) {
                return 'Année incorrecte';
              }
              return null;
            },
          ),

          // --------------------
          // Kilométrage
          // --------------------
          TextFormField(
            controller: mileageController,
            keyboardType: TextInputType.number,
            decoration:
            const InputDecoration(labelText: 'Kilométrage (km)'),
          ),

          const SizedBox(height: 16),

          // --------------------
          // Assurance
          // --------------------
          ListTile(
            title: const Text('Expiration assurance'),
            subtitle: Text(_formatDate(insuranceExpiry)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDate(
              context,
              insuranceExpiry,
              onInsuranceExpiryChanged,
            ),
          ),

          // --------------------
          // Contrôle technique
          // --------------------
          ListTile(
            title: const Text('Contrôle technique'),
            subtitle: Text(_formatDate(inspectionExpiry)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDate(
              context,
              inspectionExpiry,
              onInspectionExpiryChanged,
            ),
          ),

          // --------------------
          // Taxe
          // --------------------
          ListTile(
            title: const Text('Expiration taxe'),
            subtitle: Text(_formatDate(taxExpiry)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pickDate(
              context,
              taxExpiry,
              onTaxExpiryChanged,
            ),
          ),
        ],
      ),
    );
  }
}
