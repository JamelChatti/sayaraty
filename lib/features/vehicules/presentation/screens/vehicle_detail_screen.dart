// lib/features/vehicles/presentation/screens/vehicle_detail_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/security/password_confirm_dialog.dart';
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
                        onTap: () => _confirmSetMainPhoto(context, ref, url, isMain),
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

  Future<void> _confirmSetMainPhoto(
    BuildContext context,
    WidgetRef ref,
    String url,
    bool isMain,
  ) async {
    if (isMain) return;

    final confirmed = await confirmWithPassword(
      context,
      title: 'Photo principale',
      message:
          'Voulez-vous définir cette photo comme photo principale '
          'du véhicule ?\nEntrez votre mot de passe pour confirmer.',
      confirmLabel: 'Confirmer',
    );

    if (confirmed != true || !context.mounted) return;

    try {
      final updated = vehicle.copyWith(mainPhotoUrl: url);
      await ref.read(vehicleServiceProvider).updateVehicle(updated);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo principale mise à jour')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
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