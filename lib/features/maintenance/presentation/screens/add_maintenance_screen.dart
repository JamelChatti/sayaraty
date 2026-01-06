// lib/features/maintenance/presentation/screens/add_maintenance_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/application/auth_state_notifier.dart';
import '../../../settings/application/settings_service.dart';
import '../../../settings/domain/app_settings.dart';
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

  DateTime _selectedDate = DateTime.now();
  double _selectedMileage = 0.0;
  MaintenanceType _selectedType = MaintenanceType.oilChange;
  MaintenanceStatus _status = MaintenanceStatus.completed;
  double? _nextDueMileage;
  DateTime? _nextDueDate;

  // Liste des items pour la vidange
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

  // ✅ CORRIGÉ : Calcul du coût total
  double calculateTotalCost() {
    if (_selectedType == MaintenanceType.oilChange) {
      // Calculer le coût total des items sélectionnés
      double total = _oilChangeItems
          .where((item) => item.isSelected)
          .map((item) => item.price * item.quantity)
          .fold(0.0, (sum, cost) => sum + cost);

      return total;
    }

    // Pour les autres types, utiliser le champ coût
    return double.tryParse(_costController.text.trim()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(appSettingsProvider).asData?.value.currency ?? CurrencyEnum.eur;
    final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(_selectedDate);

    final user = ref.watch(authStateNotifierProvider).asData?.value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // ✅ CORRIGÉ : Calculer le coût total
    final totalCost = calculateTotalCost();
    final currencySymbol = _getCurrencySymbol(currency);

    return Scaffold(
      appBar: AppBar(
        title: Text('Nouvelle intervention - ${widget.vehicleName}'),
        actions: [
          // ✅ CORRIGÉ : Afficher le coût total dans l'app bar
          if (_selectedType == MaintenanceType.oilChange)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                label: Text(
                  '$totalCost $currencySymbol',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                backgroundColor: Colors.blue,
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type d'intervention
            DropdownButtonFormField<MaintenanceType>(
              initialValue: _selectedType,
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

            // ✅ CORRIGÉ : Afficher les items seulement pour la vidange
            if (_selectedType == MaintenanceType.oilChange) ...[
              const Divider(),
              const Text(
                'Éléments remplacés',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
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
                currencySymbol: currencySymbol,
              )),
              const Divider(),
            ],

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
              subtitle: Text('Le $formattedDate'),
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
                  title: const Text('Prochaine échéance (km)'),
                  subtitle: Text('À ${_nextDueMileage!.toStringAsFixed(0)} km'),
                ),
              if (_nextDueDate != null)
                ListTile(
                  title: const Text('Prochaine échéance (date)'),
                  subtitle: Text('Le ${DateFormat('dd/MM/yyyy').format(_nextDueDate!)}'),
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

            // ✅ CORRIGÉ : Champ coût conditionnel
            if (_selectedType != MaintenanceType.oilChange)
              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Coût total ($currencySymbol) *',
                ),
                validator: (v) {
                  if (_selectedType != MaintenanceType.oilChange) {
                    if (v!.trim().isEmpty || double.tryParse(v) == null) {
                      return 'Coût invalide';
                    }
                  }
                  return null;
                },
              ),
            if (_selectedType == MaintenanceType.oilChange)
              ListTile(
                title: const Text('Coût total'),
                subtitle: Text(
                  '$totalCost $currencySymbol',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                leading: const Icon(Icons.attach_money, color: Colors.green),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!_formKey.currentState!.validate()) return;

          try {
            // ✅ CORRIGÉ : Utiliser la méthode avec vérification de permissions
            final maintenance = Maintenance(
              id: FirebaseFirestore.instance.collection('maintenances').doc().id,
              ownerId: widget.ownerId,
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
              cost: totalCost, // ✅ CORRIGÉ : Utiliser le total calculé
              receiptImageUrl: null,
              nextDueMileage: _nextDueMileage,
              nextDueDate: _nextDueDate,
              status: _status,
              createdAt: DateTime.now(),
              items: _selectedType == MaintenanceType.oilChange
                  ? _oilChangeItems.where((item) => item.isSelected).toList()
                  : [],
            );

            await ref.read(maintenanceServiceProvider)
                .addMaintenanceWithPermissionCheck(
              maintenance: maintenance,
              currentUserId: user.uid,
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Intervention enregistrée !')),
              );
              // Retour à l'écran précédent
              Navigator.of(context).pop();
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur : $e')),
              );
            }
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
  final String currencySymbol;

  const _EditableMaintenanceItem({
    required this.item,
    required this.onChanged,
    required this.currencySymbol,
  });

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
            // Champ marque ou détail
            TextField(
              decoration: InputDecoration(
                labelText: widget.item.name == 'Autre'
                    ? 'Détail de l\'élément'
                    : 'Marque (optionnel)',
              ),
              onChanged: (v) {
                setState(() => _brand = v.trim().isEmpty ? null : v.trim());
                _update();
              },
              controller: TextEditingController(text: _brand ?? ''),
            ),
            const SizedBox(height: 8),

            // Prix et quantité
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Prix (${widget.currencySymbol})',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) {
                      final num = double.tryParse(v);
                      if (num != null && num >= 0) {
                        setState(() => _price = num);
                        _update();
                      }
                    },
                    controller: TextEditingController(text: _price.toStringAsFixed(2)),
                  ),
                ),
                if (widget.item.category != 'engine_oil' && widget.item.name != 'Autre')
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(labelText: 'Quantité'),
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

            // Affichage du sous-total
            if (_isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Sous-total : ${(_price * _quantity).toStringAsFixed(2)} ${widget.currencySymbol}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        )
            : null,
      ),
    );
  }
}