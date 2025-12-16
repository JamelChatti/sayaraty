import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/user_model.dart';
import 'auth_service.dart';

/// Provider qui expose l'état d'authentification en temps réel
final authStateProvider = StreamProvider<AppUser?>((ref) {
  // Écoute le stream d'utilisateur depuis AuthService
  return ref.watch(authServiceProvider).user;
});

class AuthStateNotifier extends AsyncNotifier<AppUser?> {
  @override
  FutureOr<AppUser?> build() {
    // Écouter l'état de l'utilisateur
    ref.onDispose(() {
      // Optionnel : nettoyer les écouteurs si besoin
    });
    return _loadUser();
  }

  Future<AppUser?> _loadUser() async {
    final userStream = ref.read(authServiceProvider).user;
    final subscription = userStream.listen((user) {
      state = AsyncData(user);
    });
    ref.onDispose(subscription.cancel);
    // Retourne la valeur initiale
    final initialUser = await userStream.first;
    return initialUser;
  }
}