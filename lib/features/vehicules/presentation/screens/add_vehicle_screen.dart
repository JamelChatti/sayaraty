// lib/features/vehicles/presentation/screens/add_vehicle_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/vehicle_service.dart';
import '../../domain/models/vehicule_model.dart';
import '../widgets/vehicle_form.dart';
import '../../../auth/application/auth_state_notifier.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  late final String _vehicleId;
  late final String _userId;
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _yearController = TextEditingController();
  final _mileageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime? _insuranceExpiry;
  DateTime? _inspectionExpiry;
  DateTime? _taxExpiry;

  @override
  void initState() {
    super.initState();
    final userState = ref.read(authStateProvider);
    final user = userState.asData?.value;
    if (user == null) {
      if (context.mounted) context.push('/login');
      return;
    }
    _userId = user.uid;
    _vehicleId = FirebaseFirestore.instance.collection('vehicles').doc().id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter un véhicule')),
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
      onInsuranceExpiryChanged: (d) => setState(() => _insuranceExpiry = d),
      onInspectionExpiryChanged: (d) => setState(() => _inspectionExpiry = d),
      onTaxExpiryChanged: (d) => setState(() => _taxExpiry = d),
    ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!_formKey.currentState!.validate()) return;

          final vehicle = Vehicle(
            id: _vehicleId,
            userId: _userId,
            brand: _brandController.text.trim(),
            model: _modelController.text.trim(),
              plateNumber: _plateController.text.trim(),
            year: int.parse(_yearController.text),
            mileage: double.tryParse(_mileageController.text),
            insuranceExpiry: _insuranceExpiry,
            technicalInspectionExpiry: _inspectionExpiry,
            taxExpiry: _taxExpiry,
            createdAt: DateTime.now(),
          );


          await ref.read(vehicleServiceProvider).addVehicle(vehicle);

          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Véhicule ajouté !')));
          context.push('/home');
        },
        child: const Icon(Icons.check),
      ),

    );
  }
}