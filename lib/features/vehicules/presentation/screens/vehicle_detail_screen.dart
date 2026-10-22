// lib/features/vehicles/presentation/screens/vehicle_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../application/vehicle_service.dart';
import '../../domain/models/vehicule_model.dart';
import '../widgets/fuel_consumption_section.dart';
import '../widgets/routine_status_section.dart';

class VehicleDetailScreen extends ConsumerWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(vehicleByIdStreamProvider(vehicle.id)).asData?.value ??
        vehicle;

    return Scaffold(
      appBar: AppBar(title: Text('${live.brand} ${live.model}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDetailRow('Marque', live.brand),
          _buildDetailRow('Modèle', live.model),
          if (live.plateNumber != null)
            _buildDetailRow('Immatriculation', live.plateNumber!),
          if (live.vin != null) _buildDetailRow('VIN', live.vin!),
          _buildDetailRow('Année', live.year.toString()),
          if (live.mileage != null)
            _buildDetailRow(
              'Kilométrage',
              '${live.mileage!.toStringAsFixed(0)} km',
            ),
          _buildDetailRow(
            'Motorisation',
            live.powertrain?.label ?? 'Non définie',
          ),
          if (live.powertrain != null && live.powertrain!.needsFuelType)
            _buildDetailRow(
              'Carburant',
              live.fuelType?.label ?? 'Non défini',
            ),
          _buildDetailRow(
            'DPMC',
            live.dpmc != null
                ? DateFormat('dd/MM/yyyy').format(live.dpmc!)
                : 'Non défini',
          ),
          if (live.insuranceExpiry != null)
            _buildDetailRow(
              'Assurance',
              DateFormat('dd/MM/yyyy').format(live.insuranceExpiry!),
            ),
          if (live.technicalInspectionExpiry != null)
            _buildDetailRow(
              'Contrôle technique',
              DateFormat('dd/MM/yyyy')
                  .format(live.technicalInspectionExpiry!),
            ),
          if (live.taxExpiry != null)
            _buildDetailRow(
              'Taxe',
              DateFormat('dd/MM/yyyy').format(live.taxExpiry!),
            ),
          const SizedBox(height: 24),
          FuelConsumptionSection(vehicleId: live.id),
          const SizedBox(height: 24),
          RoutineStatusSection(vehicleId: live.id),
          const SizedBox(height: 24),
          Center(
            child: IconButton(
              onPressed: () => context.push('/attached', extra: live),
              icon: const Icon(Icons.attach_file),
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/vehicles/share', extra: live),
            child: const Text('Partager'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Retour'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label : ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }
}
