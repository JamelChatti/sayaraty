import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String uid;
  final String email;
  final String? name;
  final String? role; // ← rendu nullable
  final String? companyId;
  final String? userType;

  const AppUser({
    required this.uid,
    required this.email,
    this.name,
    this.role, // ← pas "required"
    this.companyId,
    this.userType,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final uid = _asString(map['uid']);
    if (uid == null || uid.isEmpty) {
      throw Exception('Champ "uid" manquant dans le document utilisateur');
    }

    return AppUser(
      uid: uid,
      email: _asString(map['email']) ?? '',
      name: _asString(map['name']) ?? _asString(map['displayName']),
      role: _asString(map['role']),
      companyId: _asString(map['companyId']),
      userType: _asString(map['userType']),
    );
  }

  static String? _asString(dynamic value) {
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role, // peut être null
      'companyId': companyId,
      'userType':userType
    };
  }

  @override
  List<Object?> get props => [uid, email, name, role, companyId,userType];
}