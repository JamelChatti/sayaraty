import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/maintenance/presentation/screens/add_maintenance_screen.dart';
import '../features/maintenance/presentation/screens/edit_maintenance_screen.dart';
import '../features/maintenance/presentation/screens/maintenance_list_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/vehicules/presentation/screens/vehicle_list_screen.dart';
import '../features/vehicules/presentation/screens/add_vehicle_screen.dart';

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
        builder: (_, __) => const VehicleListScreen(),
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
            // Gestion d'erreur : rediriger ou afficher un message
            return const Scaffold(body: Center(child: Text('Données manquantes')));
          }
          final args = extra as Map<String, dynamic>;
          final vehicleId = args['vehicleId'] as String?;
          final vehicleName = args['vehicleName'] as String?;

          if (vehicleId == null || vehicleName == null) {
            return const Scaffold(body: Center(child: Text('Données invalides')));
          }

          return MaintenanceListScreen(
            vehicleId: vehicleId,
            vehicleName: vehicleName,
          );
        },
      ),
      GoRoute(
        path: '/maintenance/add',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>?;
          return AddMaintenanceScreen(
            vehicleId: args!['vehicleId'] as String,
            vehicleName: args['vehicleName'] as String,
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
    ],
  );
});

