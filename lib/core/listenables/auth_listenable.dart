import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_state_notifier.dart';
import '../../features/auth/domain/models/user_model.dart';


// Ce Listenable permet à GoRouter de "rafraîchir" quand l'utilisateur change
class AuthListenable extends ChangeNotifier {
  AuthListenable(this.ref) {
    ref.listen<AsyncValue<AppUser?>>(authStateNotifierProvider, (_, state) {
      // Chaque fois que l'état d'authentification change, on notifie GoRouter
      notifyListeners();
    });
  }

  final WidgetRef ref;
}