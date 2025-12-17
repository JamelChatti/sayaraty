// lib/features/auth/application/pros_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/user_model.dart';

// Charge tous les utilisateurs avec role == 'pro'
final prosListProvider = StreamProvider<List<AppUser>>((ref) {
  return FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'pro')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['uid'] = doc.id;
      return AppUser.fromMap(data);
    }).toList();
  });
});