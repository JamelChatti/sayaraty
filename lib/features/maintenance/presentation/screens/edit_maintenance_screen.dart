import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/application/auth_state_notifier.dart';
import '../../../settings/application/currency_provider.dart';
import '../../../vehicules/application/vehicle_expiry_notification_service.dart';
import '../../../vehicules/application/vehicle_service.dart';
import '../../application/maintenance_service.dart';
import '../../domain/maintenance_line_catalog.dart';
import '../../domain/models/maintenance_item.dart';
import '../../domain/models/maintenance_model.dart';
import '../widgets/maintenance_line_items_editor.dart';

class EditMaintenanceScreen extends ConsumerStatefulWidget {
  final Maintenance maintenance;
  final String vehicleName;

  const EditMaintenanceScreen({
    super.key,
    required this.maintenance,
    required this.vehicleName,
  });

  @override
  ConsumerState<EditMaintenanceScreen> createState() =>
      _EditMaintenanceScreenState();
}

class _EditMaintenanceScreenState extends ConsumerState<EditMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _garageNameController;
  late final TextEditingController _garageContactController;
  late final TextEditingController _mileageController;

  late DateTime _selectedDate;
  late double _selectedMileage;
  late List<MaintenanceItem> _items;
  Map<String, LineItemDefaults> _lastDefaults = const {};
  int _editorEpoch = 0;
  bool _lastPricesLoaded = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final m = widget.maintenance;

    _titleController = TextEditingController(text: m.title);
    _descriptionController = TextEditingController(text: m.description);
    _garageNameController = TextEditingController(text: m.garageName);
    _garageContactController = TextEditingController(text: m.garageContact);
    _mileageController = TextEditingController(
      text: m.mileage.toStringAsFixed(0),
    );

    _selectedDate = m.date;
    _selectedMileage = m.mileage;
    _items = _mergeExistingItems(m);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLastPrices());
  }

  Future<void> _loadLastPrices() async {
    if (_lastPricesLoaded) return;
    try {
      final history = await ref
          .read(maintenanceServiceProvider)
          .fetchMaintenancesForVehicle(widget.maintenance.vehicleId);
      if (!mounted) return;
      final defaults =
          MaintenanceLineCatalog.lastDefaultsFromHistory(history);
      setState(() {
        _lastDefaults = defaults;
        // Ne remplit que les lignes sans prix (éléments pas encore dans cette intervention).
        _items = MaintenanceLineCatalog.applyLastDefaults(_items, defaults);
        _lastPricesLoaded = true;
        _editorEpoch++;
      });
    } catch (e, st) {
      debugPrint('Derniers prix introuvables: $e\n$st');
      if (mounted) setState(() => _lastPricesLoaded = true);
    }
  }

  /// Préserve les items existants et les rattache au nouveau catalogue.
  List<MaintenanceItem> _mergeExistingItems(Maintenance m) {
    var existing = List<MaintenanceItem>.from(m.items);

    // Anciens pleins carburant (type fuel) sans catégorie explicite.
    if (m.type == MaintenanceType.fuel && existing.isNotEmpty) {
      existing = existing
          .map(
            (i) => i.category == 'fuel' || i.category.isEmpty
                ? i.copyWith(
                    category: 'fuel',
                    name: i.name.isEmpty ? 'Carburant' : i.name,
                    isSelected: true,
                    isFullTank: i.isFullTank || m.isFullTank,
                    nextDueMileage: i.nextDueMileage ?? m.nextDueMileage,
                    nextDueDate: i.nextDueDate ?? m.nextDueDate,
                  )
                : i.copyWith(isSelected: true),
          )
          .toList();
    }

    // Ancienne échéance globale → reporter sur le premier item si aucun rappel.
    if ((m.nextDueDate != null || m.nextDueMileage != null) &&
        existing.isNotEmpty &&
        existing.every((i) => !i.hasReminder)) {
      existing = [
        existing.first.copyWith(
          nextDueMileage: m.nextDueMileage,
          nextDueDate: m.nextDueDate,
        ),
        ...existing.skip(1),
      ];
    }

    // Anciennes descriptions « marque » → champ brand si brand vide.
    existing = existing
        .map(
          (i) => (i.brand == null || i.brand!.isEmpty) &&
                  i.description.trim().isNotEmpty
              ? i.copyWith(brand: i.description.trim(), isSelected: true)
              : i.copyWith(isSelected: true),
        )
        .toList();

    return MaintenanceLineCatalog.mergeWithExisting(existing);
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

  Future<void> _save() async {
    if (_saving) return;
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

    final updated = widget.maintenance.copyWith(
      type: type,
      title: _titleController.text.trim().isEmpty
          ? selected.map((e) => e.name).join(', ')
          : _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _selectedDate,
      mileage: _selectedMileage,
      garageName: _garageNameController.text.trim(),
      garageContact: _garageContactController.text.trim(),
      cost: _calculateTotalCost(),
      items: selected,
      nextDueMileage: reminder.mileage,
      nextDueDate: reminder.date,
      isFullTank: selected.any((i) => i.category == 'fuel' && i.isFullTank),
      updatedAt: DateTime.now(),
    );

    setState(() => _saving = true);

    try {
      await ref.read(maintenanceServiceProvider).updateMaintenance(updated);

      final authUser = ref.read(authStateNotifierProvider).asData?.value;
      if (authUser != null) {
        final vehicles =
            ref.read(vehiclesStreamProvider(authUser.uid)).asData?.value;
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
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final totalCost = _calculateTotalCost();
    final vehicle = ref
        .watch(vehicleByIdStreamProvider(widget.maintenance.vehicleId))
        .asData
        ?.value;

    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier : ${widget.vehicleName}'),
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
                labelText: 'Titre *',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
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
                    title: const Text('Date'),
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
              key: ValueKey('lines_$_editorEpoch'),
              items: _items,
              currency: currency,
              currentMileage: _selectedMileage,
              interventionDate: _selectedDate,
              dpmc: vehicle?.dpmc,
              lastDefaults: _lastDefaults,
              onChanged: (next) => setState(() => _items = next),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description / Notes',
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
        label: const Text('Mettre à jour'),
        icon: const Icon(Icons.update),
        onPressed: _saving ? null : _save,
      ),
    );
  }
}
