// lib/features/vehicles/presentation/screens/add_vehicle_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_state_notifier.dart';
import '../../application/vehicle_service.dart';
import '../../domain/models/vehicule_model.dart';
import '../widgets/vehicle_form.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  late final String _vehicleId;
  String? _userId;
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _vinController = TextEditingController(); // Ajouté pour VIN
  final _formKey = GlobalKey<FormState>();
  DateTime? _dpmc;
  DateTime? _insuranceExpiry;
  DateTime? _inspectionExpiry;
  DateTime? _taxExpiry;
  VehiclePowertrain? _powertrain;
  VehicleFuelType? _fuelType;

  @override
  void initState() {
    super.initState();
    _vehicleId = FirebaseFirestore.instance.collection('vehicles').doc().id;
    _initializeUser();
  }

  void _initializeUser() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userState = ref.read(authStateNotifierProvider);
      final user = userState.asData?.value;
      if (user == null) {
        if (context.mounted) {
          context.push('/login');
        }
        return;
      }
      setState(() {
        _userId = user.uid;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un véhicule')),
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
        onInspectionExpiryChanged: (d) => setState(() => _inspectionExpiry = d),
        onTaxExpiryChanged: (d) => setState(() => _taxExpiry = d),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!_formKey.currentState!.validate()) return;

          try {
            final now = DateTime.now();
            final year = int.tryParse(_yearController.text);

            if (year == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Année invalide')),
              );
              return;
            }

            // ✅ CORRIGÉ : Utiliser le constructeur correct de Vehicle
            final vehicle = Vehicle(
              id: _vehicleId,
              userId: _userId!, // ✅ Le propriétaire actuel
              ownerId: _userId!, // ✅ Propriétaire = utilisateur qui crée
              brand: _brandController.text.trim(),
              model: _modelController.text.trim(),
              year: year, // ✅ Déjà converti en int
              plateNumber: _plateController.text.trim().isEmpty
                  ? null
                  : _plateController.text.trim(),
              vin: _vinController.text.trim().isEmpty
                  ? null
                  : _vinController.text.trim(),
              mileage: double.tryParse(_mileageController.text),
              powertrain: _powertrain,
              fuelType: _powertrain == VehiclePowertrain.electric
                  ? null
                  : _fuelType,
              dpmc: _dpmc,
              insuranceExpiry: _insuranceExpiry,
              technicalInspectionExpiry: _inspectionExpiry,
              taxExpiry: _taxExpiry,
              createdAt: now,
              updatedAt: now,
              attachments: [],
              sharedWith: [], // ✅ Liste vide au début
              mainPhotoUrl: null,
              ownerName: currentUserProvider.name,
            );

            await ref.read(vehicleServiceProvider).addVehicle(vehicle);

            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Véhicule ajouté avec succès !')),
            );

            // Retour à l'écran principal
            context.push('/home');
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: $e')),
              );
            }
          }
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}