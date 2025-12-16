import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../domain/models/user_model.dart';

class CompanyAdminHomeScreen extends StatelessWidget {
  final AppUser user;
  const CompanyAdminHomeScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accueil Société')),
      body: Center(child: Text('Société : ${user.name}')),
    );
  }
}