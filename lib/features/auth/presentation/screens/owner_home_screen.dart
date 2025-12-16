import 'package:flutter/material.dart';

import '../../domain/models/user_model.dart';

class OwnerHomeScreen extends StatelessWidget {
  final AppUser user;

  const OwnerHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accueil Propriétaire')),
      body: Center(
        child: Text('Bienvenue, ${user.name ?? user.email} (Rôle: ${user.role})'),
      ),
    );
  }
}