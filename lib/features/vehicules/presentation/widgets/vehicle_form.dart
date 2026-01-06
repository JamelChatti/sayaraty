// lib/features/vehicles/presentation/widgets/vehicle_form.dart
import 'package:flutter/material.dart';

import '../../data/car_brands.dart';

class VehicleForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController brandController;
  final TextEditingController modelController;
  final TextEditingController plateController;
  final TextEditingController yearController;
  final TextEditingController mileageController;
  final TextEditingController vinController; // Ajouté
  final DateTime? insuranceExpiry;
  final DateTime? inspectionExpiry;
  final DateTime? taxExpiry;
  final Function(DateTime?) onInsuranceExpiryChanged;
  final Function(DateTime?) onInspectionExpiryChanged;
  final Function(DateTime?) onTaxExpiryChanged;

  const VehicleForm({
    super.key,
    required this.formKey,
    required this.brandController,
    required this.modelController,
    required this.plateController,
    required this.yearController,
    required this.mileageController,
    required this.vinController, // Ajouté
    this.insuranceExpiry,
    this.inspectionExpiry,
    this.taxExpiry,
    required this.onInsuranceExpiryChanged,
    required this.onInspectionExpiryChanged,
    required this.onTaxExpiryChanged,
  });

  Future<void> _selectDate(
      BuildContext context,
      Function(DateTime?) onChanged,
      ) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (selected != null) {
      onChanged(selected);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non défini';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Marque
          DropdownButtonFormField<String>(
            initialValue: brandController.text.isEmpty ? null : brandController.text,
            onChanged: (value) {
              if (value != null) {
                brandController.text = value;
              }
            },
            decoration: const InputDecoration(labelText: 'Marque'),
            items: getCarBrands().map<DropdownMenuItem<String>>((String brand) {
              return DropdownMenuItem<String>(
                value: brand,
                child: Text(brand),
              );
            }).toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez sélectionner une marque';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Modèle
          TextFormField(
            controller: modelController,
            decoration: const InputDecoration(
              labelText: 'Modèle *',
              hintText: 'ex: Clio',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le modèle est obligatoire';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Année
          TextFormField(
            controller: yearController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Année *',
              hintText: 'ex: 2020',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'L\'année est obligatoire';
              }
              final year = int.tryParse(value);
              if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                return 'Année invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Numéro d'immatriculation
          TextFormField(
            controller: plateController,
            decoration: const InputDecoration(
              labelText: 'Plaque d\'immatriculation',
              hintText: 'ex: AB-123-CD',
            ),
          ),
          const SizedBox(height: 16),

          // VIN (Numéro de série)
          TextFormField(
            controller: vinController,
            decoration: const InputDecoration(
              labelText: 'VIN (Numéro de série)',
              hintText: 'ex: VF1BZ060123456789',
            ),
          ),
          const SizedBox(height: 16),

          // Kilométrage
          TextFormField(
            controller: mileageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Kilométrage actuel (km)',
              hintText: 'ex: 15000',
            ),
          ),
          const SizedBox(height: 16),

          // Dates d'expiration
          _buildDateSection(
            context,
            title: 'Assurance',
            date: insuranceExpiry,
            onTap: () => _selectDate(context, onInsuranceExpiryChanged),
          ),
          _buildDateSection(
            context,
            title: 'Contrôle technique',
            date: inspectionExpiry,
            onTap: () => _selectDate(context, onInspectionExpiryChanged),
          ),
          _buildDateSection(
            context,
            title: 'Taxe',
            date: taxExpiry,
            onTap: () => _selectDate(context, onTaxExpiryChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(
      BuildContext context, {
        required String title,
        required DateTime? date,
        required VoidCallback onTap,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 12),
                Text(_formatDate(date)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    if (title == 'Assurance') {
                      onInsuranceExpiryChanged(null);
                    } else if (title == 'Contrôle technique') {
                      onInspectionExpiryChanged(null);
                    } else if (title == 'Taxe') {
                      onTaxExpiryChanged(null);
                    }
                  },
                  tooltip: 'Effacer',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}