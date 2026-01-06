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
        return null;
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
        'role': 'user', // Valeur par défaut
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

      // Créer le document utilisateur dans Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'role': role,
        'companyId': companyId,
        'createdAt': FieldValue.serverTimestamp(),
      });

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

      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e);
    } catch (e) {
      return 'Une erreur inattendue est survenue';
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

  // Méthode utilitaire pour les messages d'erreur
  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email';
      case 'wrong-password':
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