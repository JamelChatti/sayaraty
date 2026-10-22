import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency_utils.dart';
import '../../../settings/domain/app_settings.dart';
import '../../domain/estimate_next_due_date.dart';
import '../../domain/maintenance_line_catalog.dart';
import '../../domain/models/maintenance_item.dart';

/// Liste extensible d'éléments d'entretien (prix, qté, TVA, marque, prochain km/date).
class MaintenanceLineItemsEditor extends StatelessWidget {
  final List<MaintenanceItem> items;
  final CurrencyEnum currency;
  final double currentMileage;
  final DateTime interventionDate;
  final DateTime? dpmc;
  final Map<String, LineItemDefaults> lastDefaults;
  final ValueChanged<List<MaintenanceItem>> onChanged;

  const MaintenanceLineItemsEditor({
    super.key,
    required this.items,
    required this.currency,
    required this.currentMileage,
    required this.interventionDate,
    required this.dpmc,
    this.lastDefaults = const {},
    required this.onChanged,
  });

  MaintenanceItem _withLastPriceIfEmpty(MaintenanceItem item) {
    if (item.price > 0 || lastDefaults.isEmpty) return item;
    final d = MaintenanceLineCatalog.lookupDefaults(item, lastDefaults);
    if (d == null) return item;
    return item.copyWith(
      price: d.price,
      taxRate: item.category == 'fuel' ? item.taxRate : d.taxRate,
      brand: (item.brand == null || item.brand!.isEmpty) ? d.brand : item.brand,
    );
  }

  void _update(int index, MaintenanceItem item) {
    final next = List<MaintenanceItem>.from(items);
    next[index] = item;
    onChanged(next);
  }

  void _addCustom() {
    onChanged([
      ...items,
      const MaintenanceItem(
        name: '',
        category: 'other',
        isSelected: true,
      ),
    ]);
  }

  void _removeAt(int index) {
    final next = List<MaintenanceItem>.from(items)..removeAt(index);
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final symbol = currencyInputSuffix(currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Éléments d’intervention',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          'Cochez les opérations réalisées. Pour chaque ligne : prix, qté, TVA, '
          'marque, et le prochain rappel (km / date).',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isCustom = item.category == 'other';
          final isFuel = item.category == 'fuel';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: item.isSelected,
                        onChanged: (v) {
                          final selected = v ?? false;
                          var updated = item.copyWith(isSelected: selected);
                          if (selected) {
                            updated = _withLastPriceIfEmpty(updated);
                          }
                          _update(i, updated);
                        },
                      ),
                      Expanded(
                        child: isCustom
                            ? TextFormField(
                                initialValue: item.name,
                                decoration: const InputDecoration(
                                  labelText: 'Nom de l’élément',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (v) {
                                  var updated = item.copyWith(name: v);
                                  if (item.price <= 0) {
                                    updated = _withLastPriceIfEmpty(updated);
                                  }
                                  _update(i, updated);
                                },
                              )
                            : Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      if (isCustom)
                        IconButton(
                          tooltip: 'Retirer',
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _removeAt(i),
                        ),
                    ],
                  ),
                  if (item.isSelected) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            key: ValueKey(
                              'price_${i}_${item.category}_${item.name}',
                            ),
                            initialValue: item.price == 0
                                ? ''
                                : formatMoneyForInput(item.price, currency),
                            decoration: InputDecoration(
                              labelText: isFuel ? 'Prix / L' : 'Prix HT',
                              isDense: true,
                              suffixText: symbol,
                              helperText: () {
                                final d = MaintenanceLineCatalog.lookupDefaults(
                                  item,
                                  lastDefaults,
                                );
                                if (d != null && item.price == d.price) {
                                  return 'Dernier prix (modifiable)';
                                }
                                return null;
                              }(),
                              helperMaxLines: 1,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (v) => _update(
                              i,
                              item.copyWith(
                                price: parseMoneyInput(v, currency),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: item.quantity.toString(),
                            decoration: InputDecoration(
                              labelText: isFuel ? 'Litres' : 'Qté',
                              isDense: true,
                              suffixText: isFuel ? 'L' : null,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (v) => _update(
                              i,
                              item.copyWith(
                                quantity: double.tryParse(v) ?? 1.0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: item.taxRate.toStringAsFixed(0),
                            decoration: const InputDecoration(
                              labelText: 'TVA %',
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (v) => _update(
                              i,
                              item.copyWith(
                                taxRate: double.tryParse(v) ?? 19.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: item.brand ?? '',
                      decoration: InputDecoration(
                        labelText: isFuel
                            ? 'Station / type (ex: SP95)'
                            : 'Marque / réf.',
                        isDense: true,
                        prefixIcon: const Icon(Icons.edit_note, size: 20),
                      ),
                      onChanged: (v) => _update(
                        i,
                        item.copyWith(brand: v.trim().isEmpty ? null : v.trim()),
                      ),
                    ),
                    if (isFuel) ...[
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('Plein complet'),
                        subtitle: const Text(
                          'Recommandé pour le calcul L/100 km',
                        ),
                        value: item.isFullTank,
                        onChanged: (v) => _update(
                          i,
                          item.copyWith(isFullTank: v ?? false),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Prochain rappel (${item.name.isEmpty ? 'élément' : item.name})',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: item.nextDueMileage?.toStringAsFixed(0) ??
                                '',
                            decoration: const InputDecoration(
                              labelText: 'Prochain km',
                              isDense: true,
                              suffixText: 'km',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              final km = double.tryParse(v.trim());
                              var updated = item.copyWith(
                                nextDueMileage: km,
                              );
                              if (km != null && dpmc != null) {
                                final estimated = estimateNextDueDateFromMileage(
                                  dpmc: dpmc!,
                                  asOfDate: interventionDate,
                                  currentMileage: currentMileage,
                                  nextDueMileage: km,
                                );
                                if (estimated != null) {
                                  updated = updated.copyWith(
                                    nextDueDate: estimated,
                                  );
                                }
                              }
                              _update(i, updated);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Date prévue', style: TextStyle(fontSize: 13)),
                            subtitle: Text(
                              item.nextDueDate == null
                                  ? 'Non définie'
                                  : DateFormat('dd/MM/yyyy')
                                      .format(item.nextDueDate!),
                              style: const TextStyle(fontSize: 13),
                            ),
                            trailing: const Icon(Icons.calendar_today, size: 18),
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: item.nextDueDate ??
                                    interventionDate.add(
                                      const Duration(days: 180),
                                    ),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );
                              if (d != null) {
                                _update(i, item.copyWith(nextDueDate: d));
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        TextButton.icon(
          onPressed: _addCustom,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un élément'),
        ),
      ],
    );
  }
}
