import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/fuel_consumption.dart';
import 'maintenance_service.dart';

/// Stats carburant d'un véhicule (pleins + conso L/100 km).
final vehicleFuelStatsProvider =
    Provider.autoDispose.family<AsyncValue<FuelStats>, String>((ref, vehicleId) {
  final maintenancesAsync =
      ref.watch(vehicleMaintenancesStreamProvider(vehicleId));

  return maintenancesAsync.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (list) =>
        AsyncData(FuelConsumptionCalculator.fromMaintenances(list)),
  );
});
