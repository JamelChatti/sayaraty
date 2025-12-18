// lib/features/vehicles/presentation/screens/vehicle_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../application/vehicle_service.dart';
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
            // Dans VehicleDetailScreen
            if (vehicle.attachments.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Photo principale', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: vehicle.attachments.map((url) {
                      final isMain = url == vehicle.mainPhotoUrl;
                      return GestureDetector(
                        onLongPress: (){

                        },
                        onTap: () async {
                          final updated = vehicle.copyWith(mainPhotoUrl: url);
                          await ref.read(vehicleServiceProvider).updateVehicle(updated);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Image choisi avec succès !')),
                          );
                        },
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: url,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => const Icon(Icons.insert_drive_file),
                              ),
                            ),
                            if (isMain)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.check, color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
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