// lib/features/maintenance/presentation/screens/edit_maintenance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_state_notifier.dart';
import '../../../vehicules/domain/models/vehicule_model.dart';
import '../../application/maintenance_service.dart';
import '../../domain/models/maintenance_model.dart';


class EditMaintenanceScreen extends ConsumerStatefulWidget {
  final String maintenanceId;

  const EditMaintenanceScreen({
    super.key,
    required this.maintenanceId,
  });

  @override
  ConsumerState<EditMaintenanceScreen> createState() => _EditMaintenanceScreenState();
}

class _EditMaintenanceScreenState extends ConsumerState<EditMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _garageNameController;
  late final TextEditingController _garageContactController;
  late final TextEditingController _costController;
  late final TextEditingController _mileageController;

  Maintenance? _maintenance;
  Vehicle? _vehicle;

  @override
  Widget build(BuildContext context) {
    // Charger la maintenance à modifier
    final maintenanceAsync = ref.watch(maintenanceByIdStreamProvider(widget.maintenanceId));

    return maintenanceAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Erreur: $err'))),
      data: (maintenance) {
        if (maintenance == null) {
          return Scaffold(body: Center(child: Text('Intervention non trouvée')));
        }

        // Charger le véhicule associé (optionnel, pour afficher le nom)
        if (_maintenance == null) {
          _maintenance = maintenance;
          _titleController = TextEditingController(text: maintenance.title);
          _descriptionController = TextEditingController(text: maintenance.description);
          _garageNameController = TextEditingController(text: maintenance.garageName);
          _garageContactController = TextEditingController(text: maintenance.garageContact);
          _costController = TextEditingController(text: maintenance.cost.toString());
          _mileageController = TextEditingController(text: maintenance.mileage.toString());
        }

        return _MaintenanceEditForm(
          maintenance: maintenance,
          titleController: _titleController,
          descriptionController: _descriptionController,
          garageNameController: _garageNameController,
          garageContactController: _garageContactController,
          costController: _costController,
          mileageController: _mileageController,
          onSaved: (updatedMaintenance) async {
            await ref.read(maintenanceServiceProvider).updateMaintenance(updatedMaintenance);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modifié avec succès !')));
              context.push('/vehicles'); // ou retour à la fiche véhicule
            }
          },
        );
      },
    );
  }
}

// Widget séparé pour le formulaire (facilite la gestion de l'état local)
class _MaintenanceEditForm extends ConsumerWidget {
  final Maintenance maintenance;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController garageNameController;
  final TextEditingController garageContactController;
  final TextEditingController costController;
  final TextEditingController mileageController;
  final void Function(Maintenance) onSaved;

  const _MaintenanceEditForm({
    required this.maintenance,
    required this.titleController,
    required this.descriptionController,
    required this.garageNameController,
    required this.garageContactController,
    required this.costController,
    required this.mileageController,
    required this.onSaved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) return const SizedBox();

    double currentMileage = maintenance.mileage;
    DateTime currentDate = maintenance.date;
    MaintenanceType currentType = maintenance.type;
    MaintenanceStatus currentStatus = maintenance.status;

    return Scaffold(
      appBar: AppBar(title: const Text('Modifier l\'intervention')),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type (non modifiable si déjà terminée ? optionnel)
            DropdownButtonFormField<MaintenanceType>(
              value: currentType,
              decoration: const InputDecoration(labelText: 'Type *'),
              items: MaintenanceType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getMaintenanceTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  // Recalculer les échéances si besoin
                  // (vous pouvez ajouter cette logique si nécessaire)
                }
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Titre *'),
              validator: (v) => v!.trim().isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              title: const Text('Date *'),
              subtitle: Text('Le ${currentDate.toLocal()}'),
              trailing: const Icon(Icons.calendar_today),
            ),

            // Kilométrage
            TextFormField(
              controller: mileageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kilométrage *'),
              validator: (v) => v!.trim().isEmpty || double.tryParse(v) == null
                  ? 'Kilométrage invalide'
                  : null,
            ),
            const SizedBox(height: 16),

            // Garage
            TextFormField(
              controller: garageNameController,
              decoration: const InputDecoration(labelText: 'Nom du garage'),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: garageContactController,
              decoration: const InputDecoration(labelText: 'Contact'),
            ),
            const SizedBox(height: 16),

            // Coût
            TextFormField(
              controller: costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Coût total (€) *'),
              validator: (v) => v!.trim().isEmpty || double.tryParse(v) == null
                  ? 'Coût invalide'
                  : null,
            ),
            const SizedBox(height: 16),

            // Statut (optionnel)
            DropdownButtonFormField<MaintenanceStatus>(
              value: currentStatus,
              decoration: const InputDecoration(labelText: 'Statut *'),
              items: MaintenanceStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_getMaintenanceStatusLabel(status)),
                );
              }).toList(),
              onChanged: null, // Désactivé pour l'instant — vous pouvez l'activer si besoin
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (titleController.text.trim().isEmpty ||
              mileageController.text.trim().isEmpty ||
              costController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires.')));
            return;
          }

          final updatedMaintenance = maintenance.copyWith(
            title: titleController.text.trim(),
            description: descriptionController.text.trim().isNotEmpty ? descriptionController.text.trim() : null,
            garageName: garageNameController.text.trim().isNotEmpty ? garageNameController.text.trim() : null,
            garageContact: garageContactController.text.trim().isNotEmpty ? garageContactController.text.trim() : null,
            mileage: double.parse(mileageController.text.trim()),
            cost: double.parse(costController.text.trim()),
            updatedAt: DateTime.now(),
          );

          onSaved(updatedMaintenance);
        },
        child: const Icon(Icons.check),
      ),
    );
  }

  String _getMaintenanceTypeLabel(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.oilChange: return 'Vidange';
      case MaintenanceType.brakes: return 'Freins';
      case MaintenanceType.tires: return 'Pneus';
      case MaintenanceType.battery: return 'Batterie';
      case MaintenanceType.timingBelt: return 'Courroie';
      case MaintenanceType.technicalInspection: return 'Contrôle technique';
      case MaintenanceType.repair: return 'Réparation';
      case MaintenanceType.other: return 'Autre';
    }
  }

  String _getMaintenanceStatusLabel(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.completed: return 'Terminée';
      case MaintenanceStatus.planned: return 'Planifiée';
      case MaintenanceStatus.canceled: return 'Annulée';
    }
  }
}

// 🔹 Ajoutez une méthode copyWith à votre modèle Maintenance (si ce n'est pas déjà fait)
extension MaintenanceCopyWith on Maintenance {
  Maintenance copyWith({
    String? id,
    String? userId,
    String? vehicleId,
    MaintenanceType? type,
    String? title,
    String? description,
    DateTime? date,
    double? mileage,
    String? garageName,
    String? garageContact,
    double? cost,
    String? receiptImageUrl,
    double? nextDueMileage,
    DateTime? nextDueDate,
    MaintenanceStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Maintenance(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      vehicleId: vehicleId ?? this.vehicleId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      mileage: mileage ?? this.mileage,
      garageName: garageName ?? this.garageName,
      garageContact: garageContact ?? this.garageContact,
      cost: cost ?? this.cost,
      receiptImageUrl: receiptImageUrl ?? this.receiptImageUrl,
      nextDueMileage: nextDueMileage ?? this.nextDueMileage,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      items: items,
    );
  }
}