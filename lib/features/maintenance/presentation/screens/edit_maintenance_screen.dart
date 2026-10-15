import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/security/password_confirm_dialog.dart';
import '../../../auth/application/auth_state_notifier.dart';
import '../../../settings/application/currency_provider.dart';
import '../../../settings/domain/app_settings.dart';
import '../../../vehicules/application/vehicle_expiry_notification_service.dart';
import '../../../vehicules/application/vehicle_service.dart';
import '../../application/maintenance_service.dart';
import '../../domain/estimate_next_due_date.dart';
import '../../domain/maintenance_type_ui.dart';
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
  late final TextEditingController _nextDueMileageController;

  // État
  late DateTime _selectedDate;
  late double _selectedMileage;
  late MaintenanceType _selectedType;
  DateTime? _nextDueDate;
  double? _nextDueMileage;
  bool _nextDueDateFromEstimate = false;
  bool _isFullTank = true;

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
    final currency = ref.read(currencyProvider);
    _costController = TextEditingController(
      text: formatMoneyForInput(m.cost, currency),
    );
    _mileageController = TextEditingController(
      text: m.mileage.toStringAsFixed(0),
    );

    _selectedDate = m.date;
    _selectedMileage = m.mileage;
    _selectedType = m.type;
    _nextDueDate = m.nextDueDate;
    _nextDueMileage = m.nextDueMileage;
    _isFullTank = m.isFullTank;
    _nextDueMileageController = TextEditingController(
      text: m.nextDueMileage?.toStringAsFixed(0) ?? '',
    );

    _fuelVolumeController = TextEditingController();
    _fuelUnitPriceController = TextEditingController();

    if (_selectedType == MaintenanceType.fuel && m.items.isNotEmpty) {
      _fuelVolumeController.text = m.items.first.quantity.toString();
      _fuelUnitPriceController.text =
          formatMoneyForInput(m.items.first.price, currency);
    }

    _initItems(m.items, currency);
  }

  void _initItems(List<MaintenanceItem> items, CurrencyEnum currency) {
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
        TextEditingController(
          text: formatMoneyForInput(item.price, currency),
        ),
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
    _nextDueMileageController.dispose();
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
    final currency = ref.read(currencyProvider);
    if (_selectedType == MaintenanceType.fuel) {
      final vol = double.tryParse(_fuelVolumeController.text) ?? 0;
      final unit = parseMoneyInput(_fuelUnitPriceController.text, currency);
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
    return parseMoneyInput(_costController.text, currency);
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencyProvider);
    final totalCost = _calculateTotalCost();
    final user = ref.watch(authStateNotifierProvider).asData?.value;
    // Garde le stream véhicule actif pour accéder à la DPMC
    ref.watch(vehicleByIdStreamProvider(widget.maintenance.vehicleId));

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
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Row(
                        children: [
                          Icon(MaintenanceTypeUi.icon(t), size: 20),
                          const SizedBox(width: 10),
                          Text(MaintenanceTypeUi.label(t)),
                        ],
                      ),
                    ),
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
                    onChanged: (v) {
                      setState(() {
                        _selectedMileage = double.tryParse(v) ?? 0;
                        _refreshEstimatedDateIfNeeded();
                      });
                    },
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
                      if (d != null) {
                        setState(() {
                          _selectedDate = d;
                          _refreshEstimatedDateIfNeeded();
                        });
                      }
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
                    controller: _nextDueMileageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Prochain Km',
                      border: OutlineInputBorder(),
                      suffixText: 'km',
                    ),
                    onChanged: (v) {
                      setState(() => _nextDueMileage = double.tryParse(v));
                      _estimateNextDueDateFromDpmc();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ListTile(
                    title: const Text('Date prévue'),
                    subtitle: Text(
                      _nextDueDate == null
                          ? 'Non définie'
                          : '${DateFormat('dd/MM/yyyy').format(_nextDueDate!)}'
                              '${_nextDueDateFromEstimate ? ' (estimée)' : ''}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _nextDueDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) {
                        setState(() {
                          _nextDueDate = d;
                          _nextDueDateFromEstimate = false;
                        });
                      }
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
                decoration: InputDecoration(
                  labelText: usesMillimeInput(currency)
                      ? 'Coût Total (millimes)'
                      : 'Coût Total',
                  border: const OutlineInputBorder(),
                  suffixText: currencyInputSuffix(currency),
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
                price: parseMoneyInput(
                  _fuelUnitPriceController.text,
                  ref.read(currencyProvider),
                ),
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
            isFullTank:
                _selectedType == MaintenanceType.fuel ? _isFullTank : false,
            updatedAt: DateTime.now(),
          );

          try {
            await ref
                .read(maintenanceServiceProvider)
                .updateMaintenance(updatedMaintenance);

            final authUser =
                ref.read(authStateNotifierProvider).asData?.value;
            if (authUser != null) {
              final vehicles =
                  ref.read(vehiclesStreamProvider(authUser.uid)).asData?.value;
              if (vehicles != null) {
                await ref
                    .read(vehicleExpiryNotificationServiceProvider)
                    .syncVehicles(vehicles, force: true);
              }
            }

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
    final currency = ref.watch(currencyProvider);
    final symbol = currencyInputSuffix(currency);
    return [
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _fuelUnitPriceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: usesMillimeInput(currency)
                    ? 'Prix/L (millimes)'
                    : 'Prix/L',
                border: const OutlineInputBorder(),
                suffixText: symbol,
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
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Plein complet'),
        subtitle: const Text(
          'Coché = calcul L/100 km possible (recommandé)',
        ),
        value: _isFullTank,
        onChanged: (v) => setState(() => _isFullTank = v ?? true),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildOilChangeSection() {
    final currency = ref.watch(currencyProvider);
    final symbol = currencyInputSuffix(currency);
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
                              initialValue:
                                  formatMoneyForInput(item.price, currency),
                              decoration: InputDecoration(
                                labelText: 'Prix HT',
                                isDense: true,
                                suffixText: symbol,
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (v) => setState(
                                () => _fixedItems[i] = _fixedItems[i].copyWith(
                                  price: parseMoneyInput(v, currency),
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
      final currency = ref.watch(currencyProvider);
      final symbol = currencyInputSuffix(currency);
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
                  decoration: InputDecoration(
                    labelText: 'Prix HT',
                    suffixText: symbol,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) => setState(
                    () => _otherItems[i] = _otherItems[i].copyWith(
                      price: parseMoneyInput(v, currency),
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

  void _refreshEstimatedDateIfNeeded() {
    if (_nextDueMileageController.text.trim().isEmpty) return;
    if (_nextDueDate != null && !_nextDueDateFromEstimate) return;
    _estimateNextDueDateFromDpmc(notify: false);
  }

  Future<void> _estimateNextDueDateFromDpmc({bool notify = true}) async {
    final nextKm = _nextDueMileage ??
        double.tryParse(_nextDueMileageController.text.trim());
    if (nextKm == null) return;

    var vehicle = ref
        .read(vehicleByIdStreamProvider(widget.maintenance.vehicleId))
        .asData
        ?.value;
    if (vehicle == null) {
      try {
        vehicle = await ref.read(
          vehicleByIdStreamProvider(widget.maintenance.vehicleId).future,
        );
      } catch (_) {
        return;
      }
    }
    final dpmc = vehicle?.dpmc;
    if (dpmc == null || !mounted) return;

    final estimated = estimateNextDueDateFromMileage(
      dpmc: dpmc,
      asOfDate: _selectedDate,
      currentMileage: _selectedMileage,
      nextDueMileage: nextKm,
    );
    if (estimated == null) return;

    void apply() {
      _nextDueMileage = nextKm;
      _nextDueDate = estimated;
      _nextDueDateFromEstimate = true;
    }

    if (notify) {
      setState(apply);
    } else {
      apply();
    }
  }

}
