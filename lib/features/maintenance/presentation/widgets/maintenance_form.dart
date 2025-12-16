// lib/features/maintenance/presentation/widgets/maintenance_form.dart
import 'package:flutter/material.dart';
import '../../domain/models/maintenance_model.dart';

class MaintenanceForm extends StatefulWidget {
  final Maintenance? initialMaintenance; // null = ajout, non null = édition
  final String vehicleName;
  final void Function(Maintenance) onSave;

  const MaintenanceForm({
    super.key,
    this.initialMaintenance,
    required this.vehicleName,
    required this.onSave,
  });

  @override
  State<MaintenanceForm> createState() => _MaintenanceFormState();
}

class _MaintenanceFormState extends State<MaintenanceForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _garageNameController;
  late final TextEditingController _garageContactController;
  late final TextEditingController _costController;
  late final TextEditingController _mileageController;

  late MaintenanceType _selectedType;
  late DateTime _selectedDate;
  late double _selectedMileage;
  double? _nextDueMileage;
  DateTime? _nextDueDate;

  @override
  void initState() {
    super.initState();

    final m = widget.initialMaintenance;
    if (m != null) {
      // Mode ÉDITION
      _selectedType = m.type;
      _selectedDate = m.date;
      _selectedMileage = m.mileage;
      _nextDueMileage = m.nextDueMileage;
      _nextDueDate = m.nextDueDate;
      _titleController = TextEditingController(text: m.title);
      _descriptionController = TextEditingController(text: m.description);
      _garageNameController = TextEditingController(text: m.garageName);
      _garageContactController = TextEditingController(text: m.garageContact);
      _costController = TextEditingController(text: m.cost.toString());
      _mileageController = TextEditingController(text: m.mileage.toString());
    } else {
      // Mode AJOUT
      _selectedType = MaintenanceType.oilChange;
      _selectedDate = DateTime.now();
      _selectedMileage = 0.0;
      _updateNextDueValues();
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _garageNameController = TextEditingController();
      _garageContactController = TextEditingController();
      _costController = TextEditingController();
      _mileageController = TextEditingController();
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
    super.dispose();
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateNextDueValues();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Véhicule : ${widget.vehicleName}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

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
            subtitle: Text('Le ${_selectedDate.toLocal()}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: _selectDate,
          ),

          // Kilométrage
          TextFormField(
            controller: _mileageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Kilométrage *'),
            onChanged: (value) {
              final num = double.tryParse(value);
              if (num != null && num != _selectedMileage) {
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

          // Prochaines échéances (lecture seule)
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
            decoration: const InputDecoration(labelText: 'Coût total (€) *'),
            validator: (v) => v!.trim().isEmpty || double.tryParse(v) == null
                ? 'Coût invalide'
                : null,
          ),
          const SizedBox(height: 24),

          // Bouton de sauvegarde
          ElevatedButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;

              final maintenance = Maintenance(
                id: widget.initialMaintenance?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                userId: 'PLACEHOLDER_USER_ID', // ⚠️ À remplacer par l'UID réel dans le parent
                vehicleId: 'PLACEHOLDER_VEHICLE_ID', // ⚠️ À remplacer dans le parent
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
                receiptImageUrl: null,
                nextDueMileage: _nextDueMileage,
                nextDueDate: _nextDueDate,
                status: MaintenanceStatus.completed,
                createdAt: widget.initialMaintenance?.createdAt ?? DateTime.now(),
                updatedAt: widget.initialMaintenance != null ? DateTime.now() : null,
                items:  [],
              );

              widget.onSave(maintenance);
            },
            child: Text(widget.initialMaintenance == null ? 'Ajouter' : 'Modifier'),
          ),
        ],
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
}