// lib/features/vehicles/presentation/screens/edit_vehicle_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/vehicle_service.dart';
import '../../domain/models/vehicule_model.dart';
import '../widgets/vehicle_form.dart';

class EditVehicleScreen extends ConsumerStatefulWidget {
  final Vehicle vehicle;
  const EditVehicleScreen({super.key, required this.vehicle});

  @override
  ConsumerState<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends ConsumerState<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _plateController;
  late final TextEditingController _yearController;
  late final TextEditingController _mileageController;

  DateTime? _insuranceExpiry;
  DateTime? _inspectionExpiry;
  DateTime? _taxExpiry;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;

    _brandController = TextEditingController(text: v.brand);
    _modelController = TextEditingController(text: v.model);
    _plateController = TextEditingController(text: v.plateNumber ?? '');
    _yearController = TextEditingController(text: v.year.toString());
    _mileageController =
        TextEditingController(text: v.mileage?.toString() ?? '');

    _insuranceExpiry = v.insuranceExpiry;
    _inspectionExpiry = v.technicalInspectionExpiry;
    _taxExpiry = v.taxExpiry;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le véhicule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Supprimer ?'),
                  content: const Text(
                      'Êtes-vous sûr de vouloir supprimer ce véhicule ?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Annuler')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Supprimer')),
                  ],
                ),
              );

              if (confirm == true) {
                await ref
                    .read(vehicleServiceProvider)
                    .deleteVehicle(widget.vehicle.id);
                if (!mounted) return;
                context.push('/vehicles');
              }
            },
          ),
        ],
      ),
      body: VehicleForm(
        formKey: _formKey,
        brandController: _brandController,
        modelController: _modelController,
        plateController: _plateController,
        yearController: _yearController,
        mileageController: _mileageController,
        insuranceExpiry: _insuranceExpiry,
        inspectionExpiry: _inspectionExpiry,
        taxExpiry: _taxExpiry,
        onInsuranceExpiryChanged: (d) =>
            setState(() => _insuranceExpiry = d),
        onInspectionExpiryChanged: (d) =>
            setState(() => _inspectionExpiry = d),
        onTaxExpiryChanged: (d) => setState(() => _taxExpiry = d),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () async {
          if (!_formKey.currentState!.validate()) return;

          final updatedVehicle = widget.vehicle.copyWith(
            brand: _brandController.text.trim(),
            model: _modelController.text.trim(),
            plateNumber: _plateController.text.trim(),
            year: int.parse(_yearController.text),
            mileage: double.tryParse(_mileageController.text),
            insuranceExpiry: _insuranceExpiry,
            technicalInspectionExpiry: _inspectionExpiry,
            taxExpiry: _taxExpiry,
            updatedAt: DateTime.now(),
          );

          await ref
              .read(vehicleServiceProvider)
              .updateVehicle(updatedVehicle);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Véhicule mis à jour')),
          );
          context.push('/vehicles');
        },
      ),
    );
  }
}
