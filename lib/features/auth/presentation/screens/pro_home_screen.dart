import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../domain/models/user_model.dart';

class ProHomeScreen extends StatelessWidget {
  final AppUser user;
  const ProHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accueil Professionnel')),
      body: Center(child: Text('Pro : ${user.name}')),
    );
  }
}