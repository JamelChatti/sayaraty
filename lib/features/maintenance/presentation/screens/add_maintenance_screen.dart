import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../auth/application/auth_state_notifier.dart';
import '../../../settings/application/currency_provider.dart';
import '../../../vehicules/application/vehicle_expiry_notification_service.dart';
import '../../../vehicules/application/vehicle_service.dart';
import '../../../vehicules/domain/models/routine_maintenance.dart';
import '../../application/maintenance_service.dart';
import '../../domain/maintenance_line_catalog.dart';
import '../../domain/models/maintenance_item.dart';
import '../../domain/models/maintenance_model.dart';
import '../widgets/maintenance_line_items_editor.dart';

class AddMaintenanceScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  final String ownerId;
  final String vehicleName;

  const AddMaintenanceScreen({
    super.key,
    required this.ownerId,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  ConsumerState<AddMaintenanceScreen> createState() =>
      _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends ConsumerState<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _garageNameController;
  late final TextEditingController _garageContactController;
  late final TextEditingController _mileageController;

  DateTime _selectedDate = DateTime.now();
  double _selectedMileage = 0;
  List<MaintenanceItem> _items = MaintenanceLineCatalog.presets();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _garageNameController = TextEditingController();
    _garageContactController = TextEditingController();
    _mileageController = TextEditingController(text: '0');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _garageNameController.dispose();
    _garageContactController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  List<MaintenanceItem> get _selectedItems =>
      _items.where((i) => i.isSelected && i.name.trim().isNotEmpty).toList();

  double _calculateTotalCost() =>
      _selectedItems.fold(0.0, (s, i) => s + i.priceWithTax);

  void _syncTitleFromSelection() {
    if (_titleController.text.trim().isNotEmpty &&
        !_titleController.text.startsWith('Intervention')) {
      // L'utilisateur a saisi un titre personnalisé : ne pas écraser.
      final selectedNames = _selectedItems.map((e) => e.name).toSet();
      final current = _titleController.text.trim();
      if (!selectedNames.contains(current) &&
          current != selectedNames.join(', ')) {
        return;
      }
    }
    final selected = _selectedItems;
    if (selected.isEmpty) {
      _titleController.text = '';
      return;
    }
    if (selected.length == 1) {
      _titleController.text = selected.first.name;
    } else {
      _titleController.text = selected.map((e) => e.name).join(', ');
    }
  }

  Future<void> _save() async {
    final user = ref.read(authStateNotifierProvider).asData?.value;
    if (!_formKey.currentState!.validate() || user == null) return;

    final selected = _selectedItems;
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez au moins un élément d’intervention'),
        ),
      );
      return;
    }

    final type = MaintenanceLineCatalog.deriveType(selected);
    final reminder = MaintenanceLineCatalog.earliestReminder(selected);
    final totalCost = _calculateTotalCost();
    final hasFuel = selected.any((i) => i.category == 'fuel');

    final maintenance = Maintenance(
      id: FirebaseFirestore.instance.collection('maintenances').doc().id,
      ownerId: widget.ownerId,
      userId: user.uid,
      vehicleId: widget.vehicleId,
      type: type,
      title: _titleController.text.trim().isEmpty
          ? selected.map((e) => e.name).join(', ')
          : _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _selectedDate,
      mileage: _selectedMileage,
      garageName: _garageNameController.text.trim(),
      garageContact: _garageContactController.text.trim(),
      cost: totalCost,
      items: selected,
      nextDueMileage: reminder.mileage,
      nextDueDate: reminder.date,
      isFullTank: selected.any((i) => i.category == 'fuel' && i.isFullTank),
      createdAt: DateTime.now(),
      status: MaintenanceStatus.completed,
    );

    try {
      await ref.read(maintenanceServiceProvider).addMaintenanceWithPermissionCheck(
            maintenance: maintenance,
            currentUserId: user.uid,
          );

      // Met à jour les derniers services de routine pour les types concernés.
      for (final item in selected) {
        final kind = RoutineKindX.fromMaintenanceType(
          MaintenanceLineCatalog.categoryToType(item.category),
        );
        if (kind != null) {
          await ref.read(vehicleServiceProvider).recordRoutineService(
                vehicleId: widget.vehicleId,
                kind: kind,
                mileage: _selectedMileage,
                date: _selectedDate,
              );
        }
      }

      if (hasFuel) {
        final fuel = selected.firstWhere((i) => i.category == 'fuel');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('last_fuel_unit_price', fuel.price);
      }

      if (reminder.date != null) {
        final vehicles =
            ref.read(vehiclesStreamProvider(user.uid)).asData?.value;
        if (vehicles != null) {
          await ref
              .read(vehicleExpiryNotificationServiceProvider)
              .syncVehicles(vehicles, force: true);
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final totalCost = _calculateTotalCost();
    final vehicle =
        ref.watch(vehicleByIdStreamProvider(widget.vehicleId)).asData?.value;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicleName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Chip(label: Text(formatCurrency(totalCost, currency))),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Titre',
                border: OutlineInputBorder(),
                helperText: 'Généré automatiquement si vide',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _mileageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Kilométrage actuel',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(
                      () => _selectedMileage = double.tryParse(v) ?? 0,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ListTile(
                    title: const Text('Date intervention'),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(_selectedDate),
                    ),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _selectedDate = d);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            MaintenanceLineItemsEditor(
              items: _items,
              currency: currency,
              currentMileage: _selectedMileage,
              interventionDate: _selectedDate,
              dpmc: vehicle?.dpmc,
              onChanged: (next) {
                setState(() {
                  _items = next;
                  _syncTitleFromSelection();
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Commentaire global',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _garageNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du Garage',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _garageContactController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Garage',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Enregistrer'),
        icon: const Icon(Icons.check),
        onPressed: _save,
      ),
    );
  }
}
