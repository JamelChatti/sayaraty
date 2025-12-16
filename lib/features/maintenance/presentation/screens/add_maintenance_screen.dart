// lib/features/maintenance/presentation/screens/add_maintenance_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/application/auth_state_notifier.dart';
import '../../../settings/application/settings_service.dart';
import '../../../settings/domain/app_settings.dart';
import '../../application/maintenance_service.dart';
import '../../domain/models/maintenance_item.dart';
import '../../domain/models/maintenance_model.dart';
import '../../presentation/screens/edit_maintenance_screen.dart';


class AddMaintenanceScreen extends ConsumerStatefulWidget {
  final String vehicleId;
  final String vehicleName; // ex: "Renault Clio AB-123-CD"

  const AddMaintenanceScreen({
    super.key,
    required this.vehicleId,
    required this.vehicleName,
  });

  @override
  ConsumerState<AddMaintenanceScreen> createState() => _AddMaintenanceScreenState();
}

class _AddMaintenanceScreenState extends ConsumerState<AddMaintenanceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _garageNameController;
  late final TextEditingController _garageContactController;
  late final TextEditingController _costController;
  late final TextEditingController _mileageController;
  String formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  final now = DateTime.now();
  String formatted = '';

  DateTime _selectedDate = DateTime.now();
  double _selectedMileage = 0.0;
  MaintenanceType _selectedType = MaintenanceType.oilChange;
  MaintenanceStatus _status = MaintenanceStatus.completed;
  double? _nextDueMileage;
  DateTime? _nextDueDate;

  // Dans _AddMaintenanceScreenState
  final List<MaintenanceItem> _oilChangeItems = [
    MaintenanceItem(name: 'Filtre à huile', category: 'oil_filter'),
    MaintenanceItem(name: 'Filtre à air', category: 'air_filter'),
    MaintenanceItem(name: 'Filtre habitacle', category: 'cabin_air_filter'),
    MaintenanceItem(name: 'Filtre à carburant', category: 'fuel_filter'),
    MaintenanceItem(name: 'Huile moteur', category: 'engine_oil'),
    MaintenanceItem(name: 'Autre', category: 'other'),
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _garageNameController = TextEditingController();
    _garageContactController = TextEditingController();
    _costController = TextEditingController();
    _mileageController = TextEditingController()..text = _selectedMileage.toString();

  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _garageNameController.dispose();
    _garageContactController.dispose();
    _costController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    // 1. Sélectionner la date
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );

    if (selectedDate == null) return;

    // 2. Sélectionner l'heure
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );

    if (selectedTime == null) return;

    // 3. Combiner date + heure
    final combined = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    setState(() {
      _selectedDate = combined;
    });
  }

  String _getCurrencySymbol(CurrencyEnum currency) {
    switch (currency) {
      case CurrencyEnum.dzd: return 'DA';
      case CurrencyEnum.eur: return '€';
      case CurrencyEnum.usd: return '\$';
      case CurrencyEnum.tnd: return 'DT';
      case CurrencyEnum.mad: return 'MAD';
      case CurrencyEnum.gbp: return 'GBP';
      case CurrencyEnum.sar: return 'SAR';
      case CurrencyEnum.qar: return 'QAR';

    }
  }

  void _updateNextDueValues() {
    switch (_selectedType) {
      case MaintenanceType.oilChange:
        _nextDueMileage = _selectedMileage + 15000;
        _nextDueDate = DateTime(_selectedDate.year + 1, _selectedDate.month, _selectedDate.day);
        break;
      case MaintenanceType.brakes:
        _nextDueMileage = _selectedMileage + 30000;
        _nextDueDate = null;
        break;
      case MaintenanceType.tires:
        _nextDueMileage = _selectedMileage + 40000;
        _nextDueDate = null;
        break;
      case MaintenanceType.technicalInspection:
        _nextDueMileage = null;
        _nextDueDate = DateTime(_selectedDate.year + 2, _selectedDate.month, _selectedDate.day);
        break;
      default:
        _nextDueMileage = null;
        _nextDueDate = null;
    }
  }

  @override
  Widget build(BuildContext context) {

    final currency = ref.watch(appSettingsProvider).asData?.value?.currency ?? CurrencyEnum.eur;
    formatted = formatDateTime(_selectedDate);

    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) return const SizedBox();
    formatted = formatDateTime(_selectedDate);
    double calculateTotalCost() {
      if (_selectedType == MaintenanceType.oilChange) {
        return _oilChangeItems
            .where((item) => item.isSelected)
            .map((item) => item.price * item.quantity)
            .reduce((a, b) => a + b);
      }
      return double.parse(_costController.text.trim());
    }

    return Scaffold(
      appBar: AppBar(title: Text('Nouvelle intervention - ${widget.vehicleName}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type
            DropdownButtonFormField<MaintenanceType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: 'Type d\'intervention *'),
              items: MaintenanceType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getMaintenanceTypeLabel(type)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedType = value;
                    _updateNextDueValues();
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            if (_selectedType == MaintenanceType.oilChange) ...[
              const Divider(),
              const Text('Éléments remplacés', style: TextStyle(fontWeight: FontWeight.bold)),
              ..._oilChangeItems.map((item) => _EditableMaintenanceItem(
                item: item,
                onChanged: (updatedItem) {
                  setState(() {
                    final index = _oilChangeItems.indexWhere((i) => i.category == item.category);
                    if (index != -1) {
                      _oilChangeItems[index] = updatedItem;
                    }
                  });
                },
              )),
            ],
            const SizedBox(height: 16),
            // Titre
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Titre *'),
              validator: (v) => v!.trim().isEmpty ? 'Champ requis' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Date
            ListTile(
              title: const Text('Date *'),
              subtitle: Text('Le $formatted'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDateTime,
            ),

            // Kilométrage
            TextFormField(
              controller: _mileageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Kilométrage *'),
              onChanged: (value) {
                final num = double.tryParse(value);
                if (num != null) {
                  setState(() {
                    _selectedMileage = num;
                    _updateNextDueValues();
                  });
                }
              },
              validator: (v) => v!.trim().isEmpty || double.tryParse(v) == null
                  ? 'Kilométrage invalide'
                  : null,
            ),
            const SizedBox(height: 16),

            // Prochain kilométrage / date
            if (_nextDueMileage != null || _nextDueDate != null) ...[
              const Divider(),
              if (_nextDueMileage != null)
                ListTile(
                  title: const Text('Prochaine échéance'),
                  subtitle: Text('À ${_nextDueMileage!.toStringAsFixed(0)} km'),
                ),
              if (_nextDueDate != null)
                ListTile(
                  title: const Text('Prochaine échéance'),
                  subtitle: Text('Le ${_nextDueDate!.toLocal()}'),
                ),
              const SizedBox(height: 16),
            ],

            // Garage
            TextFormField(
              controller: _garageNameController,
              decoration: const InputDecoration(labelText: 'Nom du garage'),
            ),
            const SizedBox(height: 16),

            // Contact
            TextFormField(
              controller: _garageContactController,
              decoration: const InputDecoration(labelText: 'Contact (téléphone/email)'),
            ),
            const SizedBox(height: 16),

            // Coût
            TextFormField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Coût total (${_getCurrencySymbol(currency)}) *',
              ),
              validator: (v) => v!.trim().isEmpty || double.tryParse(v) == null
                  ? 'Coût invalide'
                  : null,
            ),
            Text(calculateTotalCost.toString()),

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!_formKey.currentState!.validate()) return;

          final maintenance = Maintenance(
            id: FirebaseFirestore.instance.collection('maintenances').doc().id,
            userId: user.uid,
            vehicleId: widget.vehicleId,
            type: _selectedType,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            date: _selectedDate,
            mileage: _selectedMileage,
            garageName: _garageNameController.text.trim().isEmpty
                ? null
                : _garageNameController.text.trim(),
            garageContact: _garageContactController.text.trim().isEmpty
                ? null
                : _garageContactController.text.trim(),
            cost: double.parse(_costController.text.trim()),
            receiptImageUrl: null, // À implémenter plus tard avec Firebase Storage
            nextDueMileage: _nextDueMileage,
            nextDueDate: _nextDueDate,
            status: _status,
            createdAt: DateTime.now(),
            items: _selectedType == MaintenanceType.oilChange ? _oilChangeItems : [],
          );

          await ref.read(maintenanceServiceProvider).addMaintenance(maintenance);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Intervention enregistrée !')),
            );
            context.push('/vehicles'); // ou retour à la fiche véhicule
          }
        },
        child: const Icon(Icons.check),
      ),
    );
  }

  String _getMaintenanceTypeLabel(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.oilChange:
        return 'Vidange';
      case MaintenanceType.brakes:
        return 'Freins';
      case MaintenanceType.tires:
        return 'Pneus';
      case MaintenanceType.battery:
        return 'Batterie';
      case MaintenanceType.timingBelt:
        return 'Courroie';
      case MaintenanceType.technicalInspection:
        return 'Contrôle technique';
      case MaintenanceType.repair:
        return 'Réparation';
      case MaintenanceType.other:
        return 'Autre';
    }
  }
}


class _EditableMaintenanceItem extends StatefulWidget {
  final MaintenanceItem item;
  final ValueChanged<MaintenanceItem> onChanged;

  const _EditableMaintenanceItem({required this.item, required this.onChanged});

  @override
  State<_EditableMaintenanceItem> createState() => _EditableMaintenanceItemState();
}

class _EditableMaintenanceItemState extends State<_EditableMaintenanceItem> {
  late bool _isSelected;
  late String? _brand;
  late double _price;
  late int _quantity;

  @override
  void initState() {
    final item = widget.item;
    _isSelected = item.isSelected;
    _brand = item.brand;
    _price = item.price;
    _quantity = item.quantity;
    super.initState();
  }

  void _update() {
    final updated = widget.item.copyWith(
      isSelected: _isSelected,
      brand: _brand?.isNotEmpty == true ? _brand : null,
      price: _price,
      quantity: _quantity,
    );
    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: CheckboxListTile(
        title: Text(widget.item.name),
        value: _isSelected,
        onChanged: (value) {
          setState(() {
            _isSelected = value ?? false;
          });
          _update();
        },
        subtitle: _isSelected
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: widget.item.name == 'Autre' ? 'Détail' : 'Marque (optionnel)',
              ),
              onChanged: (v) {
                setState(() => _brand = v);
                _update();
              },
              controller: TextEditingController(text: _brand),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Prix (€)'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) {
                      final num = double.tryParse(v);
                      if (num != null) {
                        setState(() => _price = num);
                        _update();
                      }
                    },
                    controller: TextEditingController(text: _price.toString()),
                  ),
                ),
                if (widget.item.category != 'engine_oil' && widget.item.name != 'Autre')
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Qté'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final num = int.tryParse(v);
                        if (num != null && num > 0) {
                          setState(() => _quantity = num);
                          _update();
                        }
                      },
                      controller: TextEditingController(text: _quantity.toString()),
                    ),
                  ),
              ],
            ),
          ],
        )
            : null,
      ),
    );
  }
}