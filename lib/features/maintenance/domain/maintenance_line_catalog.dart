import 'models/maintenance_item.dart';
import 'models/maintenance_model.dart';

/// Derniers prix / infos saisis pour un élément sur un véhicule.
class LineItemDefaults {
  final double price;
  final double taxRate;
  final String? brand;

  const LineItemDefaults({
    required this.price,
    required this.taxRate,
    this.brand,
  });
}

/// Catalogue d'éléments d'intervention (extensible via « Ajouter »).
class MaintenanceLineCatalog {
  const MaintenanceLineCatalog._();

  static String categoryKey(String category) => 'cat:$category';

  static String nameKey(String name) =>
      'name:${name.trim().toLowerCase()}';

  static String itemKey(MaintenanceItem item) {
    if (item.category.isNotEmpty &&
        item.category != 'other' &&
        item.category != 'fixed') {
      return categoryKey(item.category);
    }
    final name = item.name.trim().toLowerCase();
    return name.isEmpty ? '' : nameKey(item.name);
  }

  /// Recherche le dernier prix connu (catégorie puis nom — rétrocompat).
  static LineItemDefaults? lookupDefaults(
    MaintenanceItem item,
    Map<String, LineItemDefaults> defaults,
  ) {
    if (defaults.isEmpty) return null;
    if (item.category.isNotEmpty &&
        item.category != 'other' &&
        item.category != 'fixed') {
      final byCat = defaults[categoryKey(item.category)];
      if (byCat != null) return byCat;
    }
    final name = item.name.trim();
    if (name.isNotEmpty) {
      final byName = defaults[nameKey(name)];
      if (byName != null) return byName;
      // Alias fréquents
      if (name.toLowerCase().contains('carburant') ||
          name.toLowerCase() == 'plein carburant') {
        return defaults[categoryKey('fuel')] ??
            defaults[nameKey('Carburant')];
      }
    }
    return defaults[itemKey(item)];
  }

  /// Dernier prix HT (et TVA / marque) par élément, du plus récent au plus ancien.
  /// Indexé à la fois par catégorie et par nom pour les anciennes données.
  static Map<String, LineItemDefaults> lastDefaultsFromHistory(
    List<Maintenance> history,
  ) {
    final sorted = List<Maintenance>.from(history)
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        if (byDate != 0) return byDate;
        return (b.updatedAt ?? b.createdAt)
            .compareTo(a.updatedAt ?? a.createdAt);
      });
    final map = <String, LineItemDefaults>{};

    for (final m in sorted) {
      for (final item in m.items) {
        if (item.price <= 0) continue;
        final defaults = LineItemDefaults(
          price: item.price,
          taxRate: item.taxRate,
          brand: item.brand,
        );
        if (item.category.isNotEmpty &&
            item.category != 'other' &&
            item.category != 'fixed') {
          map.putIfAbsent(categoryKey(item.category), () => defaults);
        }
        final name = item.name.trim();
        if (name.isNotEmpty) {
          map.putIfAbsent(nameKey(name), () => defaults);
        }
        // Anciens pleins
        if (m.type == MaintenanceType.fuel || item.category == 'fuel') {
          map.putIfAbsent(categoryKey('fuel'), () => defaults);
          map.putIfAbsent(nameKey('Carburant'), () => defaults);
        }
      }
    }
    return map;
  }

  /// Applique les derniers prix uniquement si le prix actuel est vide (0).
  static List<MaintenanceItem> applyLastDefaults(
    List<MaintenanceItem> items,
    Map<String, LineItemDefaults> defaults,
  ) {
    if (defaults.isEmpty) return items;
    return items.map((item) {
      if (item.price > 0) return item;
      final d = lookupDefaults(item, defaults);
      if (d == null) return item;
      return item.copyWith(
        price: d.price,
        taxRate: item.category == 'fuel' ? item.taxRate : d.taxRate,
        brand: (item.brand == null || item.brand!.isEmpty) ? d.brand : item.brand,
      );
    }).toList();
  }

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
