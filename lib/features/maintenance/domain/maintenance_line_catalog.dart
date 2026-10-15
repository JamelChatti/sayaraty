import 'models/maintenance_item.dart';
import 'models/maintenance_model.dart';

/// Catalogue d'éléments d'intervention (extensible via « Ajouter »).
class MaintenanceLineCatalog {
  const MaintenanceLineCatalog._();

  static const oilCategories = {
    'oil_filter',
    'air_filter',
    'cabin_air_filter',
    'fuel_filter',
    'engine_oil',
  };

  /// Éléments proposés par défaut (vidange + freins, pneus, etc.).
  static List<MaintenanceItem> presets() => const [
        MaintenanceItem(name: 'Filtre à huile', category: 'oil_filter'),
        MaintenanceItem(name: 'Filtre à air', category: 'air_filter'),
        MaintenanceItem(name: 'Filtre habitacle', category: 'cabin_air_filter'),
        MaintenanceItem(name: 'Filtre à carburant', category: 'fuel_filter'),
        MaintenanceItem(name: 'Huile moteur', category: 'engine_oil'),
        MaintenanceItem(name: 'Freins', category: 'brakes'),
        MaintenanceItem(name: 'Pneus', category: 'tires'),
        MaintenanceItem(name: 'Batterie', category: 'battery'),
        MaintenanceItem(name: 'Courroie / chaîne', category: 'timing_belt'),
        MaintenanceItem(name: 'Réparation', category: 'repair'),
        MaintenanceItem(name: 'Carburant', category: 'fuel', taxRate: 0),
      ];

  /// Fusionne le catalogue avec les items déjà enregistrés (préserve les données).
  static List<MaintenanceItem> mergeWithExisting(List<MaintenanceItem> existing) {
    MaintenanceItem? findMatch(MaintenanceItem preset) {
      for (final e in existing) {
        if (preset.category.isNotEmpty && e.category == preset.category) {
          return e;
        }
        if (e.name.toLowerCase() == preset.name.toLowerCase()) return e;
      }
      return null;
    }

    final result = <MaintenanceItem>[];
    for (final p in presets()) {
      final match = findMatch(p);
      if (match == null) {
        result.add(p);
      } else {
        result.add(
          match.copyWith(
            name: p.name,
            category: p.category.isNotEmpty ? p.category : match.category,
            isSelected: true,
          ),
        );
      }
    }

    for (final e in existing) {
      final already = result.any(
        (r) =>
            (r.category.isNotEmpty &&
                e.category.isNotEmpty &&
                r.category == e.category) ||
            r.name.toLowerCase() == e.name.toLowerCase(),
      );
      if (!already) {
        result.add(e.copyWith(isSelected: true));
      }
    }
    return result;
  }

  static MaintenanceType deriveType(List<MaintenanceItem> selected) {
    if (selected.isEmpty) return MaintenanceType.other;

    final cats = selected.map((e) => e.category).where((c) => c.isNotEmpty).toSet();
    if (cats.length == 1) {
      return categoryToType(cats.first);
    }
    if (cats.isNotEmpty && cats.every(oilCategories.contains)) {
      return MaintenanceType.oilChange;
    }
    return MaintenanceType.other;
  }

  static MaintenanceType categoryToType(String category) {
    switch (category) {
      case 'oil_filter':
      case 'air_filter':
      case 'cabin_air_filter':
      case 'fuel_filter':
      case 'engine_oil':
        return MaintenanceType.oilChange;
      case 'brakes':
        return MaintenanceType.brakes;
      case 'tires':
        return MaintenanceType.tires;
      case 'battery':
        return MaintenanceType.battery;
      case 'timing_belt':
        return MaintenanceType.timingBelt;
      case 'repair':
        return MaintenanceType.repair;
      case 'fuel':
        return MaintenanceType.fuel;
      case 'technical_inspection':
        return MaintenanceType.technicalInspection;
      default:
        return MaintenanceType.other;
    }
  }

  /// Prochaine échéance globale = la plus proche parmi les éléments.
  static ({DateTime? date, double? mileage}) earliestReminder(
    List<MaintenanceItem> selected,
  ) {
    DateTime? bestDate;
    double? bestKm;
    for (final item in selected) {
      if (item.nextDueDate != null) {
        if (bestDate == null || item.nextDueDate!.isBefore(bestDate)) {
          bestDate = item.nextDueDate;
        }
      }
      if (item.nextDueMileage != null) {
        if (bestKm == null || item.nextDueMileage! < bestKm) {
          bestKm = item.nextDueMileage;
        }
      }
    }
    return (date: bestDate, mileage: bestKm);
  }
}
