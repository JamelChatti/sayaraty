// lib/features/vehicles/domain/models/shared_access_model.dart
import 'package:equatable/equatable.dart';

class SharedAccess extends Equatable {
  final String userId;
  final String email;
  final String? displayName;
  final List<String> permissions;
  final DateTime sharedAt;

  const SharedAccess({
    required this.userId,
    required this.email,
    this.displayName,
    required this.permissions,
    required this.sharedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'permissions': permissions,
      'sharedAt': sharedAt.millisecondsSinceEpoch,
    };
  }

  factory SharedAccess.fromMap(Map<String, dynamic> map) {
    return SharedAccess(
      userId: map['userId'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      permissions: List<String>.from(map['permissions'] ?? ['view']),
      sharedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['sharedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  SharedAccess copyWith({
    String? userId,
    String? email,
    String? displayName,
    List<String>? permissions,
    DateTime? sharedAt,
  }) {
    return SharedAccess(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      permissions: permissions ?? this.permissions,
      sharedAt: sharedAt ?? this.sharedAt,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    email,
    displayName,
    permissions,
    sharedAt,
  ];
}