import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/user_model.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream corrigé pour éviter les déconnexions spontanées
  Stream<AppUser?> get user {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;

      try {
        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (!doc.exists) {
          // Créer automatiquement le document utilisateur s'il n'existe pas
          await _ensureUserDocument(firebaseUser);
          final newDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
          return AppUser.fromMap(newDoc.data()!..['uid'] = firebaseUser.uid);
        }
        return AppUser.fromMap(doc.data()!..['uid'] = firebaseUser.uid);
      } catch (e) {
        print('Erreur lors de la récupération de l\'utilisateur: $e');
        return AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          name: firebaseUser.displayName,
          role: 'owner',
        );
      }
    });
  }

  // Méthode interne pour créer le document utilisateur
  Future<void> _ensureUserDocument(User firebaseUser) async {
    final userDocRef = _firestore.collection('users').doc(firebaseUser.uid);
    final snapshot = await userDocRef.get();

    if (!snapshot.exists) {
      await userDocRef.set({
        'uid': firebaseUser.uid,
        'email': firebaseUser.email ?? '',
        'name': firebaseUser.displayName ?? '',
        'role': 'owner',
        'companyId': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> ensureUserExists() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _ensureUserDocument(user);
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? companyId,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      final normalizedEmail = email.trim().toLowerCase();

      // Créer le document utilisateur dans Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': normalizedEmail,
        'name': name,
        'role': role,
        'companyId': companyId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Rattacher les invitations de partage en attente pour cet email.
      await _claimPendingShareInvitations(
        userId: uid,
        email: normalizedEmail,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return 'Une erreur inattendue est survenue';
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      // S'assurer que le document utilisateur existe après la connexion
      await ensureUserExists();

      final user = _auth.currentUser;
      if (user?.email != null) {
        await _claimPendingShareInvitations(
          userId: user!.uid,
          email: user.email!,
        );
      }

      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return 'Une erreur inattendue est survenue';
    }
  }

  Future<void> _claimPendingShareInvitations({
    required String userId,
    required String email,
  }) async {
    try {
      final normalized = email.trim().toLowerCase();
      final snap = await _firestore
          .collection('shareInvitations')
          .where('toEmail', isEqualTo: normalized)
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['status'] != 'pending') continue;
        if (data['toUserId'] == userId) continue;
        await doc.reference.update({'toUserId': userId});
      }
    } catch (e) {
      print('Claim share invitations failed: $e');
    }
  }

  /// Envoie l'email Firebase pour choisir un nouveau mot de passe.
  Future<String?> sendPasswordResetEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      return 'Saisissez une adresse e-mail valide';
    }
    try {
      await _auth.sendPasswordResetEmail(email: normalized);
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (_) {
      return 'Impossible d\'envoyer l\'e-mail de réinitialisation';
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Erreur lors de la déconnexion: $e');
      rethrow;
    }
  }

  /// Re-authentifie l'utilisateur avec son mot de passe (avant action sensible).
  Future<String?> reauthenticate(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      return 'Session expirée. Reconnectez-vous';
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (_) {
      return 'Impossible de vérifier le mot de passe';
    }
  }

  // Méthode utilitaire pour les messages d'erreur
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
        return 'Mot de passe incorrect';
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return 'Mot de passe incorrect';
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé';
      case 'weak-password':
        return 'Le mot de passe est trop faible';
      case 'invalid-email':
        return 'Email invalide';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      default:
        return e.message ?? 'Une erreur d\'authentification est survenue';
    }
  }
  User? get currentUser => FirebaseAuth.instance.currentUser;
  // Getters utiles
 // User? get currentUser => _auth.currentUser;
}