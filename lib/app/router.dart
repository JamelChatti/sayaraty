import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sayaraty/features/auth/presentation/widgets/home_redirector.dart';
import 'package:sayaraty/features/vehicules/domain/models/vehicule_model.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/maintenance/presentation/screens/add_maintenance_screen.dart';
import '../features/maintenance/presentation/screens/edit_maintenance_screen.dart';
import '../features/maintenance/presentation/screens/maintenance_list_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/vehicules/presentation/screens/add_vehicle_screen.dart';
import '../features/vehicules/presentation/screens/edit_vehicle_screen.dart';
import '../features/vehicules/presentation/screens/share_vehicle_screen.dart';
import '../features/vehicules/presentation/screens/vehicle_detail_screen.dart';
import '../features/vehicules/presentation/widgets/attachment_section.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',

    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final location = state.matchedLocation;

      final isLogin = location == '/login';
      final isSignup = location == '/signup';

      if (user == null && !isLogin && !isSignup) {
        return '/login';
      }

      if (user != null && (isLogin || isSignup)) {
        return '/home';
      }

      return null;
    },

    routes: [
      // ✅ ROUTE ROOT
      GoRoute(
        path: '/',
        redirect: (_, __) => '/home',
      ),

      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (_, __) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (_, __) => const HomeRedirector(),
      ),
      GoRoute(
        path: '/vehicles/add',
        builder: (_, __) => const AddVehicleScreen(),
      ),
      GoRoute(
        path: '/maintenance',
        builder: (context, state) {
          final extra = state.extra;
          if (extra == null || extra is! Map) {
            return const Scaffold(body: Center(child: Text('Données manquantes')));
          }
          final args = extra as Map<String, dynamic>;
          final ownerId = args['ownerId'] as String?;  // ← Ajout de ownerId
          final vehicleId = args['vehicleId'] as String?;
          final vehicleName = args['vehicleName'] as String?;

          // Vérifier que tous les paramètres sont présents
          if (ownerId == null || vehicleId == null || vehicleName == null) {
            return const Scaffold(body: Center(child: Text('Données invalides')));
          }

          return MaintenanceListScreen(
            ownerId: ownerId,  // ← Passe l'ownerId au constructeur
            vehicleId: vehicleId,
            vehicleName: vehicleName,
          );
        },
      ),
      GoRoute(
        path: '/maintenance/add',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;

          if (args == null) {
            return const Scaffold(
              body: Center(
                child: Text('Données manquantes pour créer une maintenance'),
              ),
            );
          }

          final ownerId = args['ownerId'] as String?;
          final vehicleId = args['vehicleId'] as String?;
          final vehicleName = args['vehicleName'] as String?;

          // Validation des données requises
          if (ownerId == null || vehicleId == null || vehicleName == null) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Données incomplètes pour créer une maintenance'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      child: const Text('Retour à l\'accueil'),
                    ),
                  ],
                ),
              ),
            );
          }

          return AddMaintenanceScreen(
            ownerId: ownerId,
            vehicleId: vehicleId,
            vehicleName: vehicleName,
          );
        },
      ),
      GoRoute(
        path: '/maintenance/edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return EditMaintenanceScreen(maintenanceId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) {
          return SettingsScreen();
        },
      ),
      GoRoute(
        path: '/vehicles/edit/:id', // 👈 ajoutez ":id"
        builder: (context, state) {
          final vehicleId = state.pathParameters['id']!;
          return EditVehicleScreen(vehicleId: vehicleId); // 👈 passez l'ID, pas l'objet complet
        },
      ),
      GoRoute(
        path: '/vehicles/detail/:id',
        builder: (context, state) {
          // Vous devrez charger le véhicule ici via un provider
          // Pour l'instant, on suppose qu'il est passé via extra (solution rapide)
          final vehicle = state.extra as Vehicle?;
          if (vehicle == null) {
            return const Scaffold(body: Center(child: Text('Véhicule non trouvé')));
          }
          return VehicleDetailScreen(vehicle: vehicle);
        },
      ),
      GoRoute(
        path: '/attached',
        builder: (context, state) {
          final vehicle = state.extra as Vehicle?;
          if (vehicle == null) {
            return const Scaffold(body: Center(child: Text('Véhicule non trouvé')));
          }
          return AttachmentSection(vehicleId: vehicle.id, ); // 👈 Vous devrez créer AttachedScreen
        },
      ),
      GoRoute(
        path: '/vehicles/share',
        builder: (context, state) {

          return SharedVehiclesListScreen();
        },
      ),

    ],
  );
});

