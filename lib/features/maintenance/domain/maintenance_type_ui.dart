import 'package:flutter/material.dart';

import 'models/maintenance_model.dart';

/// Libellé, icône et couleur associés à chaque type d'entretien.
class MaintenanceTypeUi {
  const MaintenanceTypeUi._();

  static String label(MaintenanceType type) {
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
        return 'Courroie / chaîne';
      case MaintenanceType.technicalInspection:
        return 'Contrôle technique';
      case MaintenanceType.repair:
        return 'Réparation';
      case MaintenanceType.fuel:
        return 'Carburant';
      case MaintenanceType.other:
        return 'Autre';
    }
  }

  static IconData icon(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.oilChange:
        return Icons.water_drop; // huile / vidange
      case MaintenanceType.brakes:
        return Icons.speed; // freinage
      case MaintenanceType.tires:
        return Icons.tire_repair;
      case MaintenanceType.battery:
        return Icons.battery_charging_full;
      case MaintenanceType.timingBelt:
        return Icons.settings_suggest; // courroie / distribution
      case MaintenanceType.technicalInspection:
        return Icons.fact_check;
      case MaintenanceType.repair:
        return Icons.handyman;
      case MaintenanceType.fuel:
        return Icons.local_gas_station; // pompe à essence
      case MaintenanceType.other:
        return Icons.more_horiz;
    }
  }

  static Color color(MaintenanceType type) {
    switch (type) {
      case MaintenanceType.oilChange:
        return Colors.deepPurple;
      case MaintenanceType.brakes:
        return Colors.orange;
      case MaintenanceType.tires:
        return Colors.brown;
      case MaintenanceType.battery:
        return Colors.green.shade700;
      case MaintenanceType.timingBelt:
        return Colors.pink;
      case MaintenanceType.technicalInspection:
        return Colors.blue;
      case MaintenanceType.repair:
        return Colors.redAccent;
      case MaintenanceType.fuel:
        return Colors.teal;
      case MaintenanceType.other:
        return Colors.grey;
    }
  }
}
