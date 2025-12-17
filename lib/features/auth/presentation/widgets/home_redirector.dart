import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // 🔑 Importe GoRouter

// Provider
import '../../../auth/application/auth_state_notifier.dart';
import '../../../vehicules/presentation/screens/pro_vehicle_list_screen.dart';
import '../../../vehicules/presentation/screens/vehicle_list_screen.dart';
import '../screens/company_admin_home_screen.dart';

class HomeRedirector extends ConsumerWidget {
  const HomeRedirector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Erreur: $err'))),
      data: (user) { // ✅ Utilise "data", pas "(user)"
        if (user == null) {

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.push('/select-role');
          });
          return const SizedBox();
        }

        // ✅ Retourne le bon écran en fonction du rôle
        switch (user.role) {
          case 'owner':
            return VehicleListScreen();
          case 'pro':
            return ProVehicleListScreen();
          case 'company_admin':
          case 'employee':
            return CompanyAdminHomeScreen(user: user);
          default:
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) context.push('/login');
            });
            return const SizedBox();
        }
      },
    );
  }
}