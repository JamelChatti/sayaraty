// lib/features/vehicles/presentation/screens/vehicle_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/models/vehicule_model.dart';

class VehicleDetailScreen extends ConsumerWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('${vehicle.brand} ${vehicle.model}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Marque', vehicle.brand),
            _buildDetailRow('Modèle', vehicle.model),
            if (vehicle.plateNumber != null) _buildDetailRow('Immatriculation', vehicle.plateNumber!),
            if (vehicle.vin != null) _buildDetailRow('VIN', vehicle.vin!),
            _buildDetailRow('Année', vehicle.year.toString()),
            if (vehicle.mileage != null) _buildDetailRow('Kilométrage', '${vehicle.mileage!.toStringAsFixed(0)} km'),
            if (vehicle.insuranceExpiry != null)
              _buildDetailRow('Assurance', DateFormat('dd/MM/yyyy').format(vehicle.insuranceExpiry!)),
            if (vehicle.technicalInspectionExpiry != null)
              _buildDetailRow('Contrôle technique', DateFormat('dd/MM/yyyy').format(vehicle.technicalInspectionExpiry!)),
            if (vehicle.taxExpiry != null)
              _buildDetailRow('Taxe', DateFormat('dd/MM/yyyy').format(vehicle.taxExpiry!)),
           // const Spacer(),
            const SizedBox(height: 30,),
            Center(child:
            IconButton(
                onPressed: () => context.push('/attached', extra: vehicle),
                icon: Icon(Icons.attach_file)),),
            // Dans VehicleDetailScreen
            ElevatedButton(
              onPressed: () => context.push('/vehicles/share', extra: vehicle),
              child: const Text('Partager avec un pro'),
            ),
            // ElevatedButton(
            //   onPressed: () async {
            //     final newSharedWith = List<String>.from(vehicle.sharedWith)..remove(proUid);
            //     final updated = vehicle.copyWith(sharedWith: newSharedWith);
            //     await ref.read(vehicleServiceProvider).updateVehicle(updated);
            //   },
            //   child: const Text('Révoquer l’accès'),
            // ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label : ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}