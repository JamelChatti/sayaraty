import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String uid;
  final String email;
  final String? name;
  final String? role; // ← rendu nullable
  final String? companyId;

  const AppUser({
    required this.uid,
    required this.email,
    this.name,
    this.role, // ← pas "required"
    this.companyId,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final uid = map['uid'];
    final email = map['email'];

    if (uid == null) {
      throw Exception('Champ "uid" manquant dans le document utilisateur');
    }
    if (email == null) {
      throw Exception('Champ "email" manquant dans le document utilisateur');
    }

    return AppUser(
      uid: uid as String,
      email: email as String,
      name: map['name'] as String?,
      role: map['role'] as String?, // ✅ pas de ?? '' si vous gardez role nullable
      companyId: map['companyId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role, // peut être null
      'companyId': companyId,
    };
  }

  @override
  List<Object?> get props => [uid, email, name, role, companyId];
}