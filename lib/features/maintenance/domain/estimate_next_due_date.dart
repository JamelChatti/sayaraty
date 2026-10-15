/// Estime la date du prochain entretien par règle de trois :
/// moyenne km/jour depuis la DPMC → jours restants jusqu'au km cible.
DateTime? estimateNextDueDateFromMileage({
  required DateTime dpmc,
  required DateTime asOfDate,
  required double currentMileage,
  required double nextDueMileage,
}) {
  if (currentMileage <= 0) return null;

  final dpmcDay = DateTime(dpmc.year, dpmc.month, dpmc.day);
  final asOfDay = DateTime(asOfDate.year, asOfDate.month, asOfDate.day);
  final daysElapsed = asOfDay.difference(dpmcDay).inDays;
  if (daysElapsed <= 0) return null;

  final remainingKm = nextDueMileage - currentMileage;
  if (remainingKm <= 0) return asOfDay;

  final kmPerDay = currentMileage / daysElapsed;
  if (kmPerDay <= 0) return null;

  final daysUntil = (remainingKm / kmPerDay).round();
  return asOfDay.add(Duration(days: daysUntil));
}
