// lib/features/vehicles/presentation/screens/share_vehicle_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/pros_provider.dart'; // 👈 Ajouté
import '../../../auth/domain/models/user_model.dart'; // 👈 AppUser
import '../../application/vehicle_service.dart';
import '../../domain/models/vehicule_model.dart';

class ShareVehicleScreen extends ConsumerStatefulWidget {
  final Vehicle vehicle;
  const ShareVehicleScreen({super.key, required this.vehicle});

  @override
  ConsumerState<ShareVehicleScreen> createState() => _ShareVehicleScreenState();
}

class _ShareVehicleScreenState extends ConsumerState<ShareVehicleScreen> {
  AppUser? _selectedPro; // 👈 Changé de ProModel à AppUser

  @override
  Widget build(BuildContext context) {
    final prosAsync = ref.watch(prosListProvider); // ✅ Maintenant défini

    return Scaffold(
      appBar: AppBar(title: const Text('Partager le véhicule')),
      body: prosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
        data: (pros) {
          return Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Sélectionnez un professionnel autorisé :'),
              ),
              Expanded( flex: 3,
                child: ListView.builder(
                  itemCount: pros.length,
                  itemBuilder: (context, index) {
                    return RadioGroup<AppUser>(
                      groupValue: _selectedPro,
                      onChanged: (value) {
                        setState(() => _selectedPro = value);
                      },
                      child: Column(
                        children: pros.map((pro) {
                          return RadioListTile<AppUser>(
                            value: pro,
                            title: Text(pro.name ?? pro.email),
                            subtitle: Text(pro.email),
                          );
                        }).toList(),
                      ),
                    );
                    
                  },
                ),
              ),
              Expanded(flex: 1,
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: ElevatedButton(
                    onPressed: _selectedPro == null
                        ? null
                        : () async {
                      final updatedSharedWith = List<String>.from(widget.vehicle.sharedWith)
                        ..add(_selectedPro!.uid) // 👈 uid au lieu de proUid
                        ..toSet().toList();

                      final updatedVehicle = widget.vehicle.copyWith(
                        sharedWith: updatedSharedWith,
                      );

                      await ref.read(vehicleServiceProvider).updateVehicle(updatedVehicle);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Partagé avec succès !')),
                        );
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Partager'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}