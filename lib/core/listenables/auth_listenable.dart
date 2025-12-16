import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_state_notifier.dart';


// Ce Listenable permet à GoRouter de "rafraîchir" quand l'utilisateur change
class AuthListenable extends ChangeNotifier {
  AuthListenable(this.ref) {
    ref.listen(authStateProvider, (_, state) {
      // Chaque fois que l'état change, on notifie GoRouter
      notifyListeners();
    });
  }

  final WidgetRef ref;
}