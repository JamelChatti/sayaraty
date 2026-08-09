import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/security/password_confirm_dialog.dart';
import '../../../auth/application/auth_state_notifier.dart';
import '../../../settings/application/currency_provider.dart';
import '../../application/maintenance_service.dart';
import '../../domain/models/maintenance_item.dart';
import '../../domain/models/maintenance_model.dart';

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

  // Contrôleurs
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _garageNameController;
  late final TextEditingController _garageContactController;
  late final TextEditingController _costController;
  late final TextEditingController _mileageController;
  late final TextEditingController _fuelVolumeController;
  late final TextEditingController _fuelUnitPriceController;

  // État
  late DateTime _selectedDate;
  late double _selectedMileage;
  late MaintenanceType _selectedType;
  DateTime? _nextDueDate;
  double? _nextDueMileage;

  // Listes pour les items
  List<MaintenanceItem> _fixedItems = [];
  final List<MaintenanceItem> _otherItems = [];
  final List<TextEditingController> _otherNameControllers = [];
  final List<TextEditingController> _otherPriceControllers = [];
  final List<TextEditingController> _otherQtyControllers = [];

  @override
  void initState() {
    super.initState();
    final m = widget.maintenance;

    _titleController = TextEditingController(text: m.title);
    _descriptionController = TextEditingController(text: m.description);
    _garageNameController = TextEditingController(text: m.garageName);
    _garageContactController = TextEditingController(text: m.garageContact);
    _costController = TextEditingController(text: m.cost.toString());
    _mileageController = TextEditingController(
      text: m.mileage.toStringAsFixed(0),
    );

    _selectedDate = m.date;
    _selectedMileage = m.mileage;
    _selectedType = m.type;
    _nextDueDate = m.nextDueDate;
    _nextDueMileage = m.nextDueMileage;

    _fuelVolumeController = TextEditingController();
    _fuelUnitPriceController = TextEditingController();

    if (_selectedType == MaintenanceType.fuel && m.items.isNotEmpty) {
      _fuelVolumeController.text = m.items.first.quantity.toString();
      _fuelUnitPriceController.text = m.items.first.price.toString();
    }

    _initItems(m.items);
  }

  void _initItems(List<MaintenanceItem> items) {
    final fixedNames = [
      'Filtre à huile',
      'Filtre à air',
      'Filtre habitacle',
      'Filtre à carburant',
      'Huile moteur',
    ];

    _fixedItems = fixedNames.map((name) {
      final existing = items.where((i) => i.name == name).firstOrNull;
      return existing?.copyWith(isSelected: true) ??
          MaintenanceItem(name: name, category: 'fixed', isSelected: false);
    }).toList();

    final others = items
        .where((i) => !fixedNames.contains(i.name) && i.category != 'fuel')
        .toList();
    for (var item in others) {
      _otherItems.add(item);
      _otherNameControllers.add(TextEditingController(text: item.name));
      _otherPriceControllers.add(
        TextEditingController(text: item.price.toString()),
      );
      _otherQtyControllers.add(
        TextEditingController(text: item.quantity.toString()),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _garageNameController.dispose();
    _garageContactController.dispose();
    _costController.dispose();
    _mileageController.dispose();
    _fuelVolumeController.dispose();
    _fuelUnitPriceController.dispose();
    for (var c in _otherNameControllers) {
      c.dispose();
    }
    for (var c in _otherPriceControllers) {
      c.dispose();
    }
    for (var c in _otherQtyControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double _calculateTotalCost() {
    if (_selectedType == MaintenanceType.fuel) {
      final vol = double.tryParse(_fuelVolumeController.text) ?? 0;
      final unit = double.tryParse(_fuelUnitPriceController.text) ?? 0;
      return vol * unit;
    }
    if (_selectedType == MaintenanceType.oilChange) {
      final fixed = _fixedItems
          .where((i) => i.isSelected)
          .fold(0.0, (s, i) => s + i.priceWithTax);
      final others = _otherItems.fold(
        0.0,
        (s, i) => s + i.priceWithTax,
      );
      return fixed + others;
    }
    return double.tryParse(_costController.text) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final totalCost = _calculateTotalCost();
    final user = ref.watch(authStateNotifierProvider).asData?.value;

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
            DropdownButtonFormField<MaintenanceType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: "Type d'intervention",
                border: OutlineInputBorder(),
              ),
              items: MaintenanceType.values
                  .map(
                    (t) =>
                        DropdownMenuItem(value: t, child: Text(_getLabel(t))),
                  )
                  .toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 20),

            if (_selectedType == MaintenanceType.fuel) ..._buildFuelSection(),
            if (_selectedType == MaintenanceType.oilChange)
              ..._buildOilChangeSection(),

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
                    onChanged: (v) =>
                        _selectedMileage = double.tryParse(v) ?? 0,
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
            const SizedBox(height: 24),
            const Text(
              'Prochaine Échéance (Rappel)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _nextDueMileage?.toStringAsFixed(0),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Prochain Km',
                      border: OutlineInputBorder(),
                      suffixText: 'km',
                    ),
                    onChanged: (v) => _nextDueMileage = double.tryParse(v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ListTile(
                    title: const Text('Date prévue'),
                    subtitle: Text(
                      _nextDueDate == null
                          ? 'Non définie'
                          : DateFormat('dd/MM/yyyy').format(_nextDueDate!),
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _nextDueDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setState(() => _nextDueDate = d);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_selectedType != MaintenanceType.fuel &&
                _selectedType != MaintenanceType.oilChange)
              TextFormField(
                controller: _costController,
                decoration: const InputDecoration(
                  labelText: 'Coût Total',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
              ),
            const SizedBox(height: 90),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Mettre à jour'),
        icon: const Icon(Icons.update),
        onPressed: () async {
          if (!_formKey.currentState!.validate() || user == null) return;

          final confirmed = await confirmWithPassword(
            context,
            title: 'Enregistrer les modifications ?',
            message:
                'Confirmez la mise à jour de cette intervention.\n'
                'Entrez votre mot de passe pour continuer.',
            confirmLabel: 'Enregistrer',
          );
          if (confirmed != true || !context.mounted) return;

          final List<MaintenanceItem> allItems;
          if (_selectedType == MaintenanceType.fuel) {
            allItems = [
              MaintenanceItem(
                name: 'Plein Carburant',
                category: 'fuel',
                quantity: double.tryParse(_fuelVolumeController.text) ?? 0,
                price: double.tryParse(_fuelUnitPriceController.text) ?? 0,
                isSelected: true,
              ),
            ];
          } else if (_selectedType == MaintenanceType.oilChange) {
            allItems = [
              ..._fixedItems.where((i) => i.isSelected),
              ..._otherItems.where((i) => i.name.isNotEmpty),
            ];
          } else {
            allItems = [];
          }

          final updatedMaintenance = widget.maintenance.copyWith(
            type: _selectedType,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            date: _selectedDate,
            mileage: _selectedMileage,
            garageName: _garageNameController.text.trim(),
            garageContact: _garageContactController.text.trim(),
            cost: totalCost,
            items: allItems,
            nextDueMileage: _nextDueMileage,
            nextDueDate: _nextDueDate,
            updatedAt: DateTime.now(),
          );

          try {
            await ref
                .read(maintenanceServiceProvider)
                .updateMaintenance(updatedMaintenance);

            if (!context.mounted) return;
            Navigator.pop(context);
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erreur : $e')));
          }
        },
      ),
    );
  }

  // --- SECTIONS UI REUTILISEES ---
  List<Widget> _buildFuelSection() {
    return [
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _fuelUnitPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Prix/L',
                border: OutlineInputBorder(),
                suffixText: 'DT',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _fuelVolumeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Volume (L)',
                border: OutlineInputBorder(),
                suffixText: 'L',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
    ];
  }

  List<Widget> _buildOilChangeSection() {
    return [
      const Text('Articles', style: TextStyle(fontWeight: FontWeight.bold)),
      ..._fixedItems.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return Card(
          child: CheckboxListTile(
            title: Text(item.name),
            value: item.isSelected,
            onChanged: (v) =>
                setState(() => _fixedItems[i] = item.copyWith(isSelected: v)),

            subtitle: item.isSelected
                ? Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              initialValue: item.price.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Prix HT',
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setState(
                                () => _fixedItems[i] = _fixedItems[i].copyWith(
                                  price: double.tryParse(v) ?? 0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: item.quantity.toString(),
                              decoration: const InputDecoration(
                                labelText: 'Qté',
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setState(
                                () => _fixedItems[i] = _fixedItems[i].copyWith(
                                  quantity: double.tryParse(v) ?? 1.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              initialValue: item.taxRate.toString(),
                              decoration: const InputDecoration(
                                labelText: 'TVA %',
                                isDense: true,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setState(
                                () => _fixedItems[i] = _fixedItems[i].copyWith(
                                  taxRate: double.tryParse(v) ?? 19.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: item.description,
                        decoration: const InputDecoration(
                          labelText: 'Marque / Référence',
                          isDense: true,
                        ),
                        onChanged: (v) => setState(
                          () => _fixedItems[i] = _fixedItems[i].copyWith(
                            description: v,
                          ),
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        );
      }),
      ..._renderOtherItems(),
      TextButton.icon(
        onPressed: _addOtherItem,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter autre'),
      ),
      const Divider(),
    ];
  }

  void _addOtherItem() {
    setState(() {
      _otherItems.add(
        const MaintenanceItem(
          name: '',
          category: 'other',
          isSelected: true,
          taxRate: 19.0,
        ),
      );
      _otherNameControllers.add(TextEditingController());
      _otherPriceControllers.add(TextEditingController());
      _otherQtyControllers.add(TextEditingController(text: '1.0'));
    });
  }

  List<Widget> _renderOtherItems() {
    return _otherItems.asMap().entries.map((entry) {
      final i = entry.key;
      return Card(
        color: Colors.grey.shade50,
        child: ListTile(
          title: TextFormField(
            controller: _otherNameControllers[i],
            decoration: const InputDecoration(labelText: 'Nom'),
            onChanged: (v) => _otherItems[i] = _otherItems[i].copyWith(name: v),
          ),
          subtitle: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _otherPriceControllers[i],
                  decoration: const InputDecoration(
                    labelText: 'Prix HT',
                    suffixText: 'DT',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) => setState(
                    () => _otherItems[i] = _otherItems[i].copyWith(
                      price: double.tryParse(v) ?? 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextFormField(
                  controller: _otherQtyControllers[i],
                  decoration: const InputDecoration(labelText: 'Qté'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) => setState(
                    () => _otherItems[i] = _otherItems[i].copyWith(
                      quantity: double.tryParse(v) ?? 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextFormField(
                  initialValue: _otherItems[i].taxRate.toString(),
                  decoration: const InputDecoration(labelText: 'TVA %'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) => setState(
                    () => _otherItems[i] = _otherItems[i].copyWith(
                      taxRate: double.tryParse(v) ?? 19.0,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() {
                  _otherItems.removeAt(i);
                  _otherNameControllers.removeAt(i);
                  _otherPriceControllers.removeAt(i);
                  _otherQtyControllers.removeAt(i);
                }),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  String _getLabel(MaintenanceType t) {
    switch (t) {
      case MaintenanceType.oilChange:
        return 'Vidange';
      case MaintenanceType.fuel:
        return 'Carburant';
      case MaintenanceType.technicalInspection:
        return 'Contrôle Technique';
      case MaintenanceType.repair:
        return 'Réparation';
      default:
        return 'Autre';
    }
  }
}
