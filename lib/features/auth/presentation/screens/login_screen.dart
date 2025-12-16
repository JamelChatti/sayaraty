import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/auth_service.dart';


class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
            ),
            ElevatedButton(
              onPressed: () async {
                final error = await ref.read(authServiceProvider).signIn(
                  emailController.text.trim(),
                  passwordController.text.trim(),
                );
                if (error != null) {

                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                  print(error);
                }else{
                  // ✅ S'assurer que l'utilisateur existe dans Firestore
                  await ref.read(authServiceProvider).ensureUserExists();
                  context.push('/home');
                }
              },
              child: const Text('Se connecter'),
            ),
            TextButton(
              onPressed: () => context.push('/signup'),
              child: const Text('Pas de compte ? Créer un compte'),
            ),
          ],
        ),
      ),
    );
  }
}