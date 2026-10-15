import 'models/maintenance_model.dart';

/// Segment de consommation entre deux pleins complets.
class FuelSegment {
  final Maintenance fromFill;
  final Maintenance toFill;
  final double distanceKm;
  final double liters;
  final double cost;

  const FuelSegment({
    required this.fromFill,
    required this.toFill,
    required this.distanceKm,
    required this.liters,
    required this.cost,
  });

  double get litersPer100Km =>
      distanceKm > 0 ? (liters * 100) / distanceKm : 0;

  double get costPer100Km =>
      distanceKm > 0 ? (cost * 100) / distanceKm : 0;
}

/// Stats agrégées pour un véhicule.
class FuelStats {
  final List<FuelSegment> segments;
  final int numberOfFills;
  final int fullTankCount;
  final double totalLiters;
  final double totalCost;

  const FuelStats({
    required this.segments,
    required this.numberOfFills,
    required this.fullTankCount,
    required this.totalLiters,
    required this.totalCost,
  });

  static const empty = FuelStats(
    segments: [],
    numberOfFills: 0,
    fullTankCount: 0,
    totalLiters: 0,
    totalCost: 0,
  );

  bool get hasConsumption => segments.isNotEmpty;

  /// Dernière conso mesurée (entre les 2 derniers pleins complets).
  double? get lastLitersPer100Km =>
      hasConsumption ? segments.last.litersPer100Km : null;

  /// Moyenne sur tous les segments calculables.
  double? get averageLitersPer100Km {
    if (!hasConsumption) return null;
    final totalDist = segments.fold<double>(0, (s, e) => s + e.distanceKm);
    final litersSum = segments.fold<double>(0, (s, e) => s + e.liters);
    if (totalDist <= 0) return null;
    return (litersSum * 100) / totalDist;
  }

  double? get averageCostPer100Km {
    if (!hasConsumption) return null;
    final totalDist = segments.fold<double>(0, (s, e) => s + e.distanceKm);
    final costSum = segments.fold<double>(0, (s, e) => s + e.cost);
    if (totalDist <= 0) return null;
    return (costSum * 100) / totalDist;
  }

  double? get lastCostPer100Km =>
      hasConsumption ? segments.last.costPer100Km : null;
}

/// Calcule la conso à partir des pleins : litres du plein N ÷ km depuis le
/// précédent plein complet.
class FuelConsumptionCalculator {
  const FuelConsumptionCalculator._();

  static FuelStats fromMaintenances(List<Maintenance> maintenances) {
    final fills = maintenances.where((m) => m.fuelLiters > 0).toList()
      ..sort((a, b) {
        final byKm = a.mileage.compareTo(b.mileage);
        if (byKm != 0) return byKm;
        return a.date.compareTo(b.date);
      });

    if (fills.isEmpty) return FuelStats.empty;

    final totalLiters = fills.fold<double>(0, (s, f) => s + f.fuelLiters);
    final totalCost = fills.fold<double>(0, (s, f) {
      final fuelCost = f.items
          .where((i) => i.category == 'fuel' || f.type == MaintenanceType.fuel)
          .fold<double>(0, (s2, i) => s2 + i.priceWithTax);
      return s + (fuelCost > 0 ? fuelCost : f.cost);
    });
    final fullCount = fills.where((f) => f.effectiveFullTank).length;

    final segments = <FuelSegment>[];
    Maintenance? lastFull;

    for (final fill in fills) {
      if (lastFull != null && fill.effectiveFullTank) {
        final distance = fill.mileage - lastFull.mileage;
        if (distance > 0) {
          final fuelCost = fill.items
              .where(
                (i) =>
                    i.category == 'fuel' || fill.type == MaintenanceType.fuel,
              )
              .fold<double>(0, (s, i) => s + i.priceWithTax);
          segments.add(
            FuelSegment(
              fromFill: lastFull,
              toFill: fill,
              distanceKm: distance,
              liters: fill.fuelLiters,
              cost: fuelCost > 0 ? fuelCost : fill.cost,
            ),
          );
        }
      }
      if (fill.effectiveFullTank) {
        lastFull = fill;
      }
    }

    return FuelStats(
      segments: segments,
      numberOfFills: fills.length,
      fullTankCount: fullCount,
      totalLiters: totalLiters,
      totalCost: totalCost,
    );
  }
}
