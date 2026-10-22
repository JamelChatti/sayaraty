// lib/features/vehicles/presentation/screens/edit_vehicle_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/security/password_confirm_dialog.dart';
import '../../application/vehicle_expiry_notification_service.dart';
import '../../application/vehicle_service.dart';
import '../../domain/models/vehicule_model.dart';
import '../widgets/vehicle_form.dart';

// 👇 Widget principal
class EditVehicleScreen extends ConsumerWidget {
  final String vehicleId;

  const EditVehicleScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(vehicleByIdStreamProvider(vehicleId));

    return vehicleAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Erreur: $err')),
      ),
      data: (vehicle) {
        if (vehicle == null) {
          return Scaffold(
            body: Center(child: Text('Véhicule non trouvé')),
          );
        }
        return _EditVehicleForm(vehicle: vehicle);
      },
    );
  }
}

// 👇 Widget privé pour le formulaire (StatefulWidget)
class _EditVehicleForm extends ConsumerStatefulWidget {
  final Vehicle vehicle;
  const _EditVehicleForm({required this.vehicle});

  @override
  ConsumerState<_EditVehicleForm> createState() => _EditVehicleFormState();
}

class _EditVehicleFormState extends ConsumerState<_EditVehicleForm> {
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _plateController;
  late final TextEditingController _yearController;
  late final TextEditingController _mileageController;
  late final TextEditingController _vinController;

  DateTime? _dpmc;
  DateTime? _insuranceExpiry;
  DateTime? _inspectionExpiry;
  DateTime? _taxExpiry;
  VehiclePowertrain? _powertrain;
  VehicleFuelType? _fuelType;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _brandController = TextEditingController(text: v.brand);
    _modelController = TextEditingController(text: v.model);
    _plateController = TextEditingController(text: v.plateNumber ?? '');
    _yearController = TextEditingController(text: v.year.toString());
    _mileageController = TextEditingController(
      text: v.mileage?.toStringAsFixed(0) ?? '',
    );
    _vinController = TextEditingController(text: v.vin ?? '');
    _dpmc = v.dpmc;
    _insuranceExpiry = v.insuranceExpiry;
    _inspectionExpiry = v.technicalInspectionExpiry;
    _taxExpiry = v.taxExpiry;
    _powertrain = v.powertrain;
    _fuelType = v.fuelType;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    _vinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le véhicule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirm = await confirmWithPassword(
                context,
                title: 'Supprimer le véhicule ?',
                message:
                    'Êtes-vous sûr de vouloir supprimer ce véhicule ? '
                    'Toutes les interventions associées seront également '
                    'supprimées.\nEntrez votre mot de passe pour confirmer.',
                confirmLabel: 'Supprimer',
                isDestructive: true,
              );
              if (confirm == true) {
                try {
                  await ref
                      .read(vehicleServiceProvider)
                      .deleteVehicle(widget.vehicle.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Véhicule supprimé avec succès'),
                      ),
                    );
                    context.go('/home');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e')),
                    );
                  }
                }
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
        vinController: _vinController,
        powertrain: _powertrain,
        fuelType: _fuelType,
        onPowertrainChanged: (p) => setState(() {
          _powertrain = p;
          if (p == VehiclePowertrain.electric) _fuelType = null;
        }),
        onFuelTypeChanged: (f) => setState(() => _fuelType = f),
        dpmc: _dpmc,
        insuranceExpiry: _insuranceExpiry,
        inspectionExpiry: _inspectionExpiry,
        taxExpiry: _taxExpiry,
        onDpmcChanged: (d) => setState(() => _dpmc = d),
        onInsuranceExpiryChanged: (d) => setState(() => _insuranceExpiry = d),
        onInspectionExpiryChanged: (d) =>
            setState(() => _inspectionExpiry = d),
        onTaxExpiryChanged: (d) => setState(() => _taxExpiry = d),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () async {
          if (!_formKey.currentState!.validate()) return;

          final confirmed = await confirmWithPassword(
            context,
            title: 'Enregistrer les modifications ?',
            message:
                'Confirmez la mise à jour de ce véhicule.\n'
                'Entrez votre mot de passe pour continuer.',
            confirmLabel: 'Enregistrer',
          );
          if (confirmed != true || !context.mounted) return;

          try {
            final year = int.tryParse(_yearController.text);
            if (year == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Année invalide')),
              );
              return;
            }

            final updatedVehicle = widget.vehicle.copyWith(
              brand: _brandController.text.trim(),
              model: _modelController.text.trim(),
              plateNumber: _plateController.text.trim().isEmpty
                  ? null
                  : _plateController.text.trim(),
              year: year,
              mileage: double.tryParse(_mileageController.text),
              vin: _vinController.text.trim().isEmpty
                  ? null
                  : _vinController.text.trim(),
              powertrain: _powertrain,
              fuelType: _powertrain == VehiclePowertrain.electric
                  ? null
                  : _fuelType,
              dpmc: _dpmc,
              insuranceExpiry: _insuranceExpiry,
              technicalInspectionExpiry: _inspectionExpiry,
              taxExpiry: _taxExpiry,
              updatedAt: DateTime.now(),
            );

            await ref
                .read(vehicleServiceProvider)
                .updateVehicle(updatedVehicle);

            // Reprogramme les rappels : annule les anciennes notifs liées
            // à l’ancienne date, puis planifie J−7 → J pour la nouvelle.
            final vehicles = ref
                .read(vehiclesStreamProvider(updatedVehicle.userId))
                .asData
                ?.value;
            final toSync = vehicles == null
                ? <Vehicle>[updatedVehicle]
                : [
                    for (final v in vehicles)
                      if (v.id == updatedVehicle.id) updatedVehicle else v,
                  ];
            await ref
                .read(vehicleExpiryNotificationServiceProvider)
                .syncVehicles(toSync, force: true);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Véhicule mis à jour avec succès'),
                ),
              );
              context.pop();
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: $e')),
              );
            }
          }
        },
      ),
    );
  }
}