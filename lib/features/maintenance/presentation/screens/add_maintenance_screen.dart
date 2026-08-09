import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../auth/application/auth_state_notifier.dart';
import '../../../settings/application/currency_provider.dart';
import '../../application/maintenance_service.dart';
import '../../domain/models/maintenance_item.dart';
import '../../domain/models/maintenance_model.dart';

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
  late final TextEditingController _costController;
  late final TextEditingController _mileageController;
  late final TextEditingController _fuelVolumeController;
  late final TextEditingController _fuelUnitPriceController;

  DateTime _selectedDate = DateTime.now();
  double _selectedMileage = 0;
  MaintenanceType _selectedType = MaintenanceType.oilChange;
  DateTime? _nextDueDate;
  double? _nextDueMileage;

  final List<MaintenanceItem> _fixedItems = [
    const MaintenanceItem(name: 'Filtre à huile', category: 'oil_filter'),
    const MaintenanceItem(name: 'Filtre à air', category: 'air_filter'),
    const MaintenanceItem(
      name: 'Filtre habitacle',
      category: 'cabin_air_filter',
    ),
    const MaintenanceItem(name: 'Filtre à carburant', category: 'fuel_filter'),
    const MaintenanceItem(name: 'Huile moteur', category: 'engine_oil'),
  ];
  final List<MaintenanceItem> _otherItems = [];
  final List<TextEditingController> _otherNameControllers = [];
  final List<TextEditingController> _otherPriceControllers = [];
  final List<TextEditingController> _otherQtyControllers = [];
  final List<TextEditingController> _otherDescControllers =
      []; // Pour les notes "Autres"

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _garageNameController = TextEditingController();
    _garageContactController = TextEditingController();
    _costController = TextEditingController();
    _mileageController = TextEditingController(text: '0');
    _fuelVolumeController = TextEditingController();
    _fuelUnitPriceController = TextEditingController();
    _loadLastFuelPrice();
  }

  Future<void> _loadLastFuelPrice() async {
    final prefs = await SharedPreferences.getInstance();
    final lastPrice = prefs.getDouble('last_fuel_unit_price');
    if (lastPrice != null && mounted) {
      setState(() => _fuelUnitPriceController.text = lastPrice.toString());
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
    for (var c in _otherDescControllers) {
      c.dispose();
    }
    super.dispose();
  }

  double _calculateTotalCost() {
    if (_selectedType == MaintenanceType.fuel) {
      final vol = double.tryParse(_fuelVolumeController.text) ?? 0;
      final unit = double.tryParse(_fuelUnitPriceController.text) ?? 0;
      // Pour le carburant, on considère souvent le prix TTC au litre,
      // sinon appliquez le même calcul : (vol * unit) * 1.19
      return vol * unit;
    }

    if (_selectedType == MaintenanceType.oilChange) {
      final fixed = _fixedItems
          .where((i) => i.isSelected)
          .fold(0.0, (s, i) => s + i.priceWithTax);
      final others = _otherItems.fold(0.0, (s, i) => s + i.priceWithTax);
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
              onChanged: (val) => setState(() {
                _selectedType = val!;
                if (_selectedType == MaintenanceType.fuel) {
                  _titleController.text = 'Plein Carburant';
                }
              }),
            ),
            const SizedBox(height: 20),

            if (_selectedType == MaintenanceType.fuel) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fuelUnitPriceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Prix/Litre',
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
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
            ],

            if (_selectedType == MaintenanceType.oilChange) ...[
              const Text(
                'Éléments de vidange',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ..._fixedItems.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Card(
                  child: CheckboxListTile(
                    title: Text(item.name),
                    value: item.isSelected,
                    onChanged: (v) => setState(
                      () => _fixedItems[i] = item.copyWith(isSelected: v),
                    ),
                    subtitle: item.isSelected
                        ? Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Prix HT',
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => setState(
                                        () => _fixedItems[i] = _fixedItems[i]
                                            .copyWith(
                                              price: double.tryParse(v) ?? 0,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      initialValue: '1.0',
                                      decoration: const InputDecoration(
                                        labelText: 'Qté',
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => setState(
                                        () => _fixedItems[i] = _fixedItems[i]
                                            .copyWith(
                                              quantity:
                                                  double.tryParse(v) ?? 1.0,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 1,
                                    child: TextFormField(
                                      initialValue: '19', // Valeur par défaut
                                      decoration: const InputDecoration(
                                        labelText: 'TVA %',
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => setState(
                                        () => _fixedItems[i] = _fixedItems[i]
                                            .copyWith(
                                              taxRate:
                                                  double.tryParse(v) ?? 19.0,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText:
                                      'Marque / Réf / Viscosité (ex: Total 5W30)',
                                  isDense: true,
                                  prefixIcon: Icon(Icons.edit_note, size: 20),
                                ),
                                onChanged: (v) => setState(
                                  () => _fixedItems[i] = _fixedItems[i]
                                      .copyWith(description: v),
                                ),
                              ),
                              const SizedBox(height: 8),
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
                label: const Text('Ajouter un autre article'),
              ),
              const Divider(),
            ],

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
                        initialDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
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
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Enregistrer'),
        icon: const Icon(Icons.check),
        onPressed: () async {
          if (!_formKey.currentState!.validate() || user == null) return;

          final List<MaintenanceItem> allItems;
          if (_selectedType == MaintenanceType.fuel) {
            final unitPrice =
                double.tryParse(_fuelUnitPriceController.text) ?? 0;
            allItems = [
              MaintenanceItem(
                name: 'Plein Carburant',
                category: 'fuel',
                quantity: double.tryParse(_fuelVolumeController.text) ?? 0,
                price: unitPrice,
                isSelected: true,
                description: '',
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

          final maintenance = Maintenance(
            id: FirebaseFirestore.instance.collection('maintenances').doc().id,
            ownerId: widget.ownerId,
            userId: user.uid,
            vehicleId: widget.vehicleId,
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
            createdAt: DateTime.now(),
            status: MaintenanceStatus.completed,
          );

          try {
            await ref
                .read(maintenanceServiceProvider)
                .addMaintenanceWithPermissionCheck(
                  maintenance: maintenance,
                  currentUserId: user.uid,
                );
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

  void _addOtherItem() {
    setState(() {
      _otherItems.add(
        const MaintenanceItem(
          name: '',
          category: 'other',
          isSelected: true,
          description: '',
          taxRate: 19.0, // ✅ TVA par défaut pour les nouveaux items
        ),
      );
      _otherNameControllers.add(TextEditingController());
      _otherPriceControllers.add(TextEditingController());
      _otherQtyControllers.add(TextEditingController(text: '1.0'));
      _otherDescControllers.add(TextEditingController());
    });
  }

  List<Widget> _renderOtherItems() {
    return _otherItems.asMap().entries.map((entry) {
      final i = entry.key;
      return Card(
        color: Colors.grey.shade50,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _otherNameControllers[i],
                      decoration: const InputDecoration(
                        labelText: 'Nom de l\'article',
                      ),
                      onChanged: (v) =>
                          _otherItems[i] = _otherItems[i].copyWith(name: v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() {
                      _otherItems.removeAt(i);
                      _otherNameControllers.removeAt(i);
                      _otherPriceControllers.removeAt(i);
                      _otherQtyControllers.removeAt(i);
                      _otherDescControllers.removeAt(i);
                    }),
                  ),
                ],
              ),
              Row(
                children: [
                  // PRIX HT
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
                      ), // ✅ FIX CLAVIER
                      onChanged: (v) => setState(() {
                        _otherItems[i] = _otherItems[i].copyWith(
                          price: double.tryParse(v) ?? 0,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // QUANTITÉ
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _otherQtyControllers[i],
                      decoration: const InputDecoration(labelText: 'Qté'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ), // ✅ FIX CLAVIER
                      onChanged: (v) => setState(() {
                        _otherItems[i] = _otherItems[i].copyWith(
                          quantity: double.tryParse(v) ?? 1.0,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // TVA
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: '19', // TVA par défaut
                      decoration: const InputDecoration(labelText: 'TVA %'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ), // ✅ FIX CLAVIER
                      onChanged: (v) => setState(() {
                        _otherItems[i] = _otherItems[i].copyWith(
                          taxRate: double.tryParse(v) ?? 19.0,
                        );
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // DESCRIPTION / RÉFÉRENCE
              TextFormField(
                controller: _otherDescControllers[i],
                decoration: const InputDecoration(
                  labelText: 'Marque / Référence / Détails',
                  isDense: true,
                  prefixIcon: Icon(Icons.edit_note, size: 20),
                ),
                onChanged: (v) =>
                    _otherItems[i] = _otherItems[i].copyWith(description: v),
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
