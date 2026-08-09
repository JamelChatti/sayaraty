import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Demande confirmation + mot de passe du compte, puis re-authentifie via Firebase.
/// Retourne `true` si l'utilisateur a confirmé et le mot de passe est correct.
Future<bool> confirmWithPassword(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmer',
  bool isDestructive = false,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  final email = user?.email;

  if (user == null || email == null || email.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expirée. Reconnectez-vous.')),
      );
    }
    return false;
  }

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PasswordConfirmDialog(
      title: title,
      message: message,
      email: email,
      user: user,
      confirmLabel: confirmLabel,
      isDestructive: isDestructive,
    ),
  );

  return result == true;
}

class _PasswordConfirmDialog extends StatefulWidget {
  final String title;
  final String message;
  final String email;
  final User user;
  final String confirmLabel;
  final bool isDestructive;

  const _PasswordConfirmDialog({
    required this.title,
    required this.message,
    required this.email,
    required this.user,
    required this.confirmLabel,
    required this.isDestructive,
  });

  @override
  State<_PasswordConfirmDialog> createState() => _PasswordConfirmDialogState();
}

class _PasswordConfirmDialogState extends State<_PasswordConfirmDialog> {
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _loading = false;
  String? _authError;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _authError = null;
    });

    try {
      final credential = EmailAuthProvider.credential(
        email: widget.email,
        password: _passwordController.text,
      );
      await widget.user.reauthenticateWithCredential(credential);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _authError = _mapAuthError(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _authError = 'Impossible de vérifier le mot de passe';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.45;

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.message),
                  const SizedBox(height: 16),
                  Text(
                    'Compte : ${widget.email}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscure,
                    enabled: !_loading,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: const OutlineInputBorder(),
                      errorText: _authError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: _loading
                            ? null
                            : () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: widget.isDestructive
              ? FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                )
              : null,
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

String _mapAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'wrong-password':
    case 'invalid-credential':
    case 'invalid-login-credentials':
      return 'Mot de passe incorrect';
    case 'too-many-requests':
      return 'Trop de tentatives. Réessayez plus tard';
    case 'user-mismatch':
    case 'user-not-found':
      return 'Session invalide. Reconnectez-vous';
    case 'network-request-failed':
      return 'Erreur réseau. Vérifiez votre connexion';
    default:
      return e.message ?? 'Authentification échouée';
  }
}
