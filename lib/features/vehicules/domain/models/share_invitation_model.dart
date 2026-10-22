import 'package:equatable/equatable.dart';

enum ShareInvitationStatus { pending, accepted, rejected, cancelled }

class ShareInvitation extends Equatable {
  final String id;
  final String vehicleId;
  final String vehicleLabel;
  final String fromUserId;
  final String fromEmail;
  final String? fromName;
  final String? toUserId;
  final String toEmail;
  final String? toDisplayName;
  final String? toPhone;
  final String inviteCode;
  final List<String> permissions;
  final ShareInvitationStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const ShareInvitation({
    required this.id,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.fromUserId,
    required this.fromEmail,
    this.fromName,
    this.toUserId,
    required this.toEmail,
    this.toDisplayName,
    this.toPhone,
    this.inviteCode = '',
    required this.permissions,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  bool get isPending => status == ShareInvitationStatus.pending;

  bool get canWrite =>
      permissions.contains('edit') || permissions.contains('maintenance_add');

  factory ShareInvitation.fromMap(Map<String, dynamic> map, String id) {
    return ShareInvitation(
      id: id,
      vehicleId: map['vehicleId'] as String? ?? '',
      vehicleLabel: map['vehicleLabel'] as String? ?? 'Véhicule',
      fromUserId: map['fromUserId'] as String? ?? '',
      fromEmail: map['fromEmail'] as String? ?? '',
      fromName: map['fromName'] as String?,
      toUserId: map['toUserId'] as String?,
      toEmail: (map['toEmail'] as String? ?? '').toLowerCase(),
      toDisplayName: map['toDisplayName'] as String?,
      toPhone: map['toPhone'] as String?,
      inviteCode: (map['inviteCode'] as String? ?? '').toUpperCase(),
      permissions: List<String>.from(map['permissions'] ?? ['view']),
      status: _statusFrom(map['status'] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      respondedAt: map['respondedAt'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['respondedAt'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleId': vehicleId,
      'vehicleLabel': vehicleLabel,
      'fromUserId': fromUserId,
      'fromEmail': fromEmail,
      'fromName': fromName,
      'toUserId': toUserId,
      'toEmail': toEmail.toLowerCase(),
      'toDisplayName': toDisplayName,
      'toPhone': toPhone,
      'inviteCode': inviteCode.toUpperCase(),
      'permissions': permissions,
      'status': status.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'respondedAt': respondedAt?.millisecondsSinceEpoch,
    };
  }

  static ShareInvitationStatus _statusFrom(String? raw) {
    return ShareInvitationStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => ShareInvitationStatus.pending,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vehicleId,
        toUserId,
        toEmail,
        inviteCode,
        status,
        permissions,
        createdAt,
      ];
}
