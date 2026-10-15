import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/vehicle_service.dart';
import '../../domain/models/routine_maintenance.dart';
import '../../domain/models/vehicule_model.dart';

class RoutineConfigScreen extends ConsumerStatefulWidget {
  final Vehicle vehicle;

  const RoutineConfigScreen({super.key, required this.vehicle});

  @override
  ConsumerState<RoutineConfigScreen> createState() =>
      _RoutineConfigScreenState();
}

class _RoutineConfigScreenState extends ConsumerState<RoutineConfigScreen> {
  bool _saving = false;

  final _oilKm = TextEditingController();
  final _oilDays = TextEditingController();
  final _oilLastKm = TextEditingController();
  final _tiresKm = TextEditingController();
  final _tiresDays = TextEditingController();
  final _tiresLastKm = TextEditingController();
  final _beltKm = TextEditingController();
  final _beltLastKm = TextEditingController();
  final _batteryMonths = TextEditingController();

  DateTime? _oilLastDate;
  DateTime? _tiresLastDate;
  DateTime? _beltLastDate;
  DateTime? _batteryLastDate;

  @override
  void initState() {
    super.initState();
    final r = widget.vehicle.routine.hasAnyInterval
        ? widget.vehicle.routine
        : RoutineMaintenanceSettings.defaults().copyWith(
            oilLastMileage: widget.vehicle.routine.oilLastMileage,
            oilLastDate: widget.vehicle.routine.oilLastDate,
            tiresLastMileage: widget.vehicle.routine.tiresLastMileage,
            tiresLastDate: widget.vehicle.routine.tiresLastDate,
            timingBeltLastMileage:
                widget.vehicle.routine.timingBeltLastMileage,
            timingBeltLastDate: widget.vehicle.routine.timingBeltLastDate,
            batteryLastDate: widget.vehicle.routine.batteryLastDate,
          );
    _oilKm.text = _num(r.oilIntervalKm);
    _oilDays.text = _int(r.oilIntervalDays);
    _oilLastKm.text = _num(r.oilLastMileage);
    _oilLastDate = r.oilLastDate;
    _tiresKm.text = _num(r.tiresIntervalKm);
    _tiresDays.text = _int(r.tiresIntervalDays);
    _tiresLastKm.text = _num(r.tiresLastMileage);
    _tiresLastDate = r.tiresLastDate;
    _beltKm.text = _num(r.timingBeltIntervalKm);
    _beltLastKm.text = _num(r.timingBeltLastMileage);
    _beltLastDate = r.timingBeltLastDate;
    _batteryMonths.text = _int(r.batteryIntervalMonths);
    _batteryLastDate = r.batteryLastDate;
  }

  String _num(double? v) => v == null ? '' : v.toStringAsFixed(0);
  String _int(int? v) => v?.toString() ?? '';

  @override
  void dispose() {
    _oilKm.dispose();
    _oilDays.dispose();
    _oilLastKm.dispose();
    _tiresKm.dispose();
    _tiresDays.dispose();
    _tiresLastKm.dispose();
    _beltKm.dispose();
    _beltLastKm.dispose();
    _batteryMonths.dispose();
    super.dispose();
  }

  Future<void> _pickDate(ValueChanged<DateTime?> onPicked, DateTime? current) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) onPicked(selected);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.vehicle.copyWith(
        routine: RoutineMaintenanceSettings(
          oilIntervalKm: double.tryParse(_oilKm.text.trim()),
          oilIntervalDays: int.tryParse(_oilDays.text.trim()),
          oilLastMileage: double.tryParse(_oilLastKm.text.trim()),
          oilLastDate: _oilLastDate,
          tiresIntervalKm: double.tryParse(_tiresKm.text.trim()),
          tiresIntervalDays: int.tryParse(_tiresDays.text.trim()),
          tiresLastMileage: double.tryParse(_tiresLastKm.text.trim()),
          tiresLastDate: _tiresLastDate,
          timingBeltIntervalKm: double.tryParse(_beltKm.text.trim()),
          timingBeltLastMileage: double.tryParse(_beltLastKm.text.trim()),
          timingBeltLastDate: _beltLastDate,
          batteryIntervalMonths: int.tryParse(_batteryMonths.text.trim()),
          batteryLastDate: _batteryLastDate,
        ),
        updatedAt: DateTime.now(),
      );
      await ref.read(vehicleServiceProvider).updateVehicle(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entretiens de routine enregistrés')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entretiens de routine'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${widget.vehicle.brand} ${widget.vehicle.model}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'Définissez les intervalles. L’échéance arrive au premier '
            'seuil atteint (km ou délai), sauf pour la chaîne (km) et '
            'la batterie (mois).',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _section(
            title: 'Vidange',
            hint: RoutineKind.oilChange.ruleHint,
            children: [
              _numberField(_oilKm, 'Intervalle (km)'),
              _numberField(_oilDays, 'Intervalle (jours)'),
              _numberField(_oilLastKm, 'Dernier entretien (km)'),
              _dateTile(
                'Date du dernier entretien',
                _oilLastDate,
                df,
                () => _pickDate((d) => setState(() => _oilLastDate = d), _oilLastDate),
                () => setState(() => _oilLastDate = null),
              ),
            ],
          ),
          _section(
            title: 'Pneus',
            hint: RoutineKind.tires.ruleHint,
            children: [
              _numberField(_tiresKm, 'Intervalle (km)'),
              _numberField(_tiresDays, 'Intervalle (jours)'),
              _numberField(_tiresLastKm, 'Dernier entretien (km)'),
              _dateTile(
                'Date du dernier entretien',
                _tiresLastDate,
                df,
                () => _pickDate(
                  (d) => setState(() => _tiresLastDate = d),
                  _tiresLastDate,
                ),
                () => setState(() => _tiresLastDate = null),
              ),
            ],
          ),
          _section(
            title: 'Chaîne / courroie',
            hint: RoutineKind.timingBelt.ruleHint,
            children: [
              _numberField(_beltKm, 'Intervalle (km)'),
              _numberField(_beltLastKm, 'Dernier entretien (km)'),
              _dateTile(
                'Date du dernier entretien (info)',
                _beltLastDate,
                df,
                () => _pickDate(
                  (d) => setState(() => _beltLastDate = d),
                  _beltLastDate,
                ),
                () => setState(() => _beltLastDate = null),
              ),
            ],
          ),
          _section(
            title: 'Batterie',
            hint: RoutineKind.battery.ruleHint,
            children: [
              _numberField(_batteryMonths, 'Intervalle (mois)'),
              _dateTile(
                'Date du dernier remplacement',
                _batteryLastDate,
                df,
                () => _pickDate(
                  (d) => setState(() => _batteryLastDate = d),
                  _batteryLastDate,
                ),
                () => setState(() => _batteryLastDate = null),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check),
            label: const Text('Enregistrer'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required String hint,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _numberField(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _dateTile(
    String label,
    DateTime? date,
    DateFormat df,
    VoidCallback onPick,
    VoidCallback onClear,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(date == null ? 'Non défini' : df.format(date)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (date != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: onClear,
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: onPick,
          ),
        ],
      ),
    );
  }
}
