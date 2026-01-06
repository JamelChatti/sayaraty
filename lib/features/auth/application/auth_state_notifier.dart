import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../domain/models/user_model.dart';
import 'auth_service.dart';


// Nouveau StateNotifier simplifié et plus stable
class AuthStateNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final Ref ref;
  StreamSubscription<AppUser?>? _userSubscription;

  AuthStateNotifier(this.ref) : super(const AsyncLoading()) {
    _init();
  }

  void _init() {
    // Écouter le stream d'authentification
    _userSubscription = ref.read(authServiceProvider).user.listen(
          (user) {
        state = AsyncData(user);
      },
      onError: (error, stackTrace) {
        state = AsyncError(error, stackTrace);
      },
    );
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  // Méthodes pour les actions d'authentification
  Future<void> signOut() async {
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<String?> signIn(String email, String password) async {
    return await ref.read(authServiceProvider).signIn(email, password);
  }
}

// Provider pour le StateNotifier
final authStateNotifierProvider = StateNotifierProvider<AuthStateNotifier, AsyncValue<AppUser?>>(
      (ref) => AuthStateNotifier(ref),
);

// Provider pour l'utilisateur actuel (plus simple à utiliser)
final currentUserProvider = Provider<AppUser?>((ref) {
  final authState = ref.watch(authStateNotifierProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, __) => null,
  );
});

// Provider pour savoir si l'utilisateur est connecté
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});