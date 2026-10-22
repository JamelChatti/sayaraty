// lib/features/vehicles/presentation/widgets/vehicle_form.dart
import 'package:flutter/material.dart';

import '../../data/car_brands.dart';
import '../../domain/models/vehicule_model.dart';

class VehicleForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController brandController;
  final TextEditingController modelController;
  final TextEditingController plateController;
  final TextEditingController yearController;
  final TextEditingController mileageController;
  final TextEditingController vinController;
  final VehiclePowertrain? powertrain;
  final VehicleFuelType? fuelType;
  final ValueChanged<VehiclePowertrain?> onPowertrainChanged;
  final ValueChanged<VehicleFuelType?> onFuelTypeChanged;
  final DateTime? dpmc;
  final DateTime? insuranceExpiry;
  final DateTime? inspectionExpiry;
  final DateTime? taxExpiry;
  final Function(DateTime?) onDpmcChanged;
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
    required this.vinController,
    required this.powertrain,
    required this.fuelType,
    required this.onPowertrainChanged,
    required this.onFuelTypeChanged,
    this.dpmc,
    this.insuranceExpiry,
    this.inspectionExpiry,
    this.taxExpiry,
    required this.onDpmcChanged,
    required this.onInsuranceExpiryChanged,
    required this.onInspectionExpiryChanged,
    required this.onTaxExpiryChanged,
  });

  Future<void> _selectDate(
    BuildContext context,
    Function(DateTime?) onChanged, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1980),
      lastDate: lastDate ?? DateTime(DateTime.now().year + 5),
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
          DropdownButtonFormField<String>(
            initialValue:
                brandController.text.isEmpty ? null : brandController.text,
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
              if (year == null ||
                  year < 1900 ||
                  year > DateTime.now().year + 1) {
                return 'Année invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: plateController,
            decoration: const InputDecoration(
              labelText: 'Plaque d\'immatriculation',
              hintText: 'ex: AB-123-CD',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: vinController,
            decoration: const InputDecoration(
              labelText: 'VIN (Numéro de série)',
              hintText: 'ex: VF1BZ060123456789',
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: mileageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Kilométrage actuel (km)',
              hintText: 'ex: 15000',
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<VehiclePowertrain>(
            key: ValueKey('powertrain_${powertrain?.name}'),
            initialValue: powertrain,
            decoration: const InputDecoration(
              labelText: 'Motorisation *',
              border: OutlineInputBorder(),
            ),
            items: VehiclePowertrain.values
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(p.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              onPowertrainChanged(value);
              if (value == VehiclePowertrain.electric) {
                onFuelTypeChanged(null);
              }
            },
            validator: (value) =>
                value == null ? 'Choisissez la motorisation' : null,
          ),
          if (powertrain != null && powertrain!.needsFuelType) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<VehicleFuelType>(
              key: ValueKey('fuel_${powertrain?.name}_${fuelType?.name}'),
              initialValue: fuelType,
              decoration: const InputDecoration(
                labelText: 'Type de carburant *',
                border: OutlineInputBorder(),
              ),
              items: VehicleFuelType.values
                  .map(
                    (f) => DropdownMenuItem(
                      value: f,
                      child: Text(f.label),
                    ),
                  )
                  .toList(),
              onChanged: onFuelTypeChanged,
              validator: (value) =>
                  value == null ? 'Choisissez essence ou diesel' : null,
            ),
          ],
          _buildDateSection(
            context,
            title: 'DPMC',
            subtitle: 'Date de première mise en circulation',
            date: dpmc,
            onTap: () => _selectDate(
              context,
              onDpmcChanged,
              initialDate: dpmc ?? DateTime(DateTime.now().year - 5),
              firstDate: DateTime(1980),
              lastDate: DateTime.now(),
            ),
            onClear: () => onDpmcChanged(null),
          ),
          _buildDateSection(
            context,
            title: 'Assurance',
            date: insuranceExpiry,
            onTap: () => _selectDate(context, onInsuranceExpiryChanged),
            onClear: () => onInsuranceExpiryChanged(null),
          ),
          _buildDateSection(
            context,
            title: 'Contrôle technique',
            date: inspectionExpiry,
            onTap: () => _selectDate(context, onInspectionExpiryChanged),
            onClear: () => onInspectionExpiryChanged(null),
          ),
          _buildDateSection(
            context,
            title: 'Taxe',
            date: taxExpiry,
            onTap: () => _selectDate(context, onTaxExpiryChanged),
            onClear: () => onTaxExpiryChanged(null),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildDateSection(
    BuildContext context, {
    required String title,
    String? subtitle,
    required DateTime? date,
    required VoidCallback onTap,
    required VoidCallback onClear,
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
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
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
                  onPressed: onClear,
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
