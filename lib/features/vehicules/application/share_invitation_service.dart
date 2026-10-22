import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_service.dart';
import '../domain/models/share_invitation_model.dart';
import '../domain/models/shared_access_model.dart';
import '../domain/models/vehicule_model.dart';
import 'sharing_service.dart';

final shareInvitationServiceProvider = Provider<ShareInvitationService>((ref) {
  return ShareInvitationService(ref);
});

/// Invitations en attente reçues par l'utilisateur connecté.
final pendingShareInvitationsProvider =
    StreamProvider.autoDispose.family<List<ShareInvitation>, String>((
  ref,
  userId,
) {
  return ref
      .watch(shareInvitationServiceProvider)
      .watchIncomingPending(userId: userId);
});

/// Invitations en attente envoyées par le propriétaire connecté.
final myOutgoingInvitationsProvider =
    StreamProvider.autoDispose.family<List<ShareInvitation>, String>((
  ref,
  userId,
) {
  return ref
      .watch(shareInvitationServiceProvider)
      .watchOutgoingByOwner(userId: userId);
});

/// Invitations en attente envoyées pour un véhicule.
final outgoingPendingInvitationsProvider =
    StreamProvider.autoDispose.family<List<ShareInvitation>, String>((
  ref,
  vehicleId,
) {
  return ref
      .watch(shareInvitationServiceProvider)
      .watchOutgoingPending(vehicleId: vehicleId);
});

class ShareInvitationService {
  final Ref _ref;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _collection = 'shareInvitations';

  ShareInvitationService(this._ref);

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(_collection);

  /// Envoie une invitation : l'accès n'est accordé qu'après acceptation.
  Future<ShareInvitation> sendInvitation({
    required String vehicleId,
    String toEmail = '',
    required List<String> permissions,
    String? toDisplayName,
    String? toPhone,
    String? toUserId,
  }) async {
    final currentUser = _ref.read(authServiceProvider).currentUser;
    if (currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    final normalizedEmail = toEmail.trim().toLowerCase();
    final hasEmail = normalizedEmail.contains('@');

    if (hasEmail && currentUser.email?.toLowerCase() == normalizedEmail) {
      throw Exception('Vous ne pouvez pas partager avec vous-même');
    }

    final vehicleDoc =
        await _firestore.collection('vehicles').doc(vehicleId).get();
    final vehicleData = vehicleDoc.data();
    if (vehicleData == null) {
      throw Exception('Véhicule non trouvé');
    }
    if (vehicleData['ownerId'] != currentUser.uid) {
      throw Exception('Vous n\'êtes pas propriétaire de ce véhicule');
    }

    final existingShared = Vehicle.parseSharedWith(vehicleData['sharedWith']);

    // Résoudre le destinataire s'il a déjà un compte.
    final resolvedUserId = toUserId ??
        (hasEmail ? await _findUserIdByEmail(normalizedEmail) : null);

    if (resolvedUserId != null && resolvedUserId == currentUser.uid) {
      throw Exception('Vous ne pouvez pas partager avec vous-même');
    }

    if (resolvedUserId != null &&
        existingShared.any((a) => a.userId == resolvedUserId)) {
      throw Exception('Cet utilisateur a déjà accès à ce véhicule');
    }

    // Déjà une invitation en attente ? (filtre client pour éviter un index composé)
    final pendingSnap =
        await _col.where('vehicleId', isEqualTo: vehicleId).get();
    final phoneKey = _digits(toPhone);
    final hasPending = pendingSnap.docs.any((doc) {
      final data = doc.data();
      if (data['status'] != ShareInvitationStatus.pending.name) return false;
      if (hasEmail) {
        return (data['toEmail'] as String?)?.toLowerCase() == normalizedEmail;
      }
      if (phoneKey.isNotEmpty) {
        return _digits(data['toPhone'] as String?) == phoneKey;
      }
      final name = (toDisplayName ?? '').trim().toLowerCase();
      return name.isNotEmpty &&
          (data['toDisplayName'] as String?)?.trim().toLowerCase() == name;
    });
    if (hasPending) {
      throw Exception('Une invitation est déjà en attente pour cette personne');
    }

    final fromDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
    final fromData = fromDoc.data() ?? {};
    final fromName =
        (fromData['name'] as String?) ?? currentUser.displayName;
    final vehicleLabel =
        '${vehicleData['brand'] ?? ''} ${vehicleData['model'] ?? ''}'.trim();

    final invitation = ShareInvitation(
      id: '',
      vehicleId: vehicleId,
      vehicleLabel: vehicleLabel.isEmpty ? 'Véhicule' : vehicleLabel,
      fromUserId: currentUser.uid,
      fromEmail: (currentUser.email ?? '').toLowerCase(),
      fromName: fromName,
      toUserId: resolvedUserId,
      toEmail: hasEmail ? normalizedEmail : '',
      toDisplayName: toDisplayName,
      toPhone: toPhone,
      inviteCode: _newInviteCode(),
      permissions: permissions,
      status: ShareInvitationStatus.pending,
      createdAt: DateTime.now(),
    );

    final docRef = await _col.add(invitation.toMap());
    return ShareInvitation.fromMap(invitation.toMap(), docRef.id);
  }

  /// Invitation ouverte (sans contact choisi) : on réutilise le code en attente.
  Future<ShareInvitation> prepareOpenInvitation({
    required String vehicleId,
    List<String> permissions = const ['view', 'edit', 'maintenance_add'],
  }) async {
    final currentUser = _ref.read(authServiceProvider).currentUser;
    if (currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    final pendingSnap =
        await _col.where('vehicleId', isEqualTo: vehicleId).get();
    final reusable = pendingSnap.docs
        .map((d) => ShareInvitation.fromMap(d.data(), d.id))
        .where(
          (i) =>
              i.isPending &&
              i.fromUserId == currentUser.uid &&
              i.inviteCode.isNotEmpty,
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (reusable.isNotEmpty) return reusable.first;

    return sendInvitation(
      vehicleId: vehicleId,
      permissions: permissions,
    );
  }

  Future<void> acceptInvitation(String invitationId) async {
    final currentUser = _ref.read(authServiceProvider).currentUser;
    if (currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    final doc = await _col.doc(invitationId).get();
    if (!doc.exists) {
      throw Exception('Invitation introuvable');
    }

    final invitation = ShareInvitation.fromMap(doc.data()!, doc.id);
    if (!invitation.isPending) {
      throw Exception('Cette invitation n\'est plus valide');
    }

    final myEmail = (currentUser.email ?? '').toLowerCase();
    final isRecipient = invitation.toUserId == currentUser.uid ||
        (invitation.toEmail.isNotEmpty && invitation.toEmail == myEmail);
    if (!isRecipient) {
      throw Exception('Cette invitation ne vous est pas destinée');
    }

    await _grantAccessAfterAccept(
      invitation: invitation,
      recipientUserId: currentUser.uid,
      recipientEmail: myEmail.isNotEmpty ? myEmail : invitation.toEmail,
      recipientName: currentUser.displayName,
    );

    await _col.doc(invitationId).update({
      'status': ShareInvitationStatus.accepted.name,
      'toUserId': currentUser.uid,
      'respondedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _grantAccessAfterAccept({
    required ShareInvitation invitation,
    required String recipientUserId,
    required String recipientEmail,
    String? recipientName,
  }) async {
    final vehicleDoc = await _firestore
        .collection('vehicles')
        .doc(invitation.vehicleId)
        .get();
    final vehicleData = vehicleDoc.data();
    if (vehicleData == null) {
      throw Exception('Véhicule non trouvé');
    }

    final existingShared = Vehicle.parseSharedWith(vehicleData['sharedWith']);
    if (existingShared.any((a) => a.userId == recipientUserId)) {
      return;
    }

    final sharedAccess = SharedAccess(
      userId: recipientUserId,
      email: recipientEmail.toLowerCase(),
      displayName: recipientName ?? invitation.toDisplayName,
      permissions: invitation.permissions,
      sharedAt: DateTime.now(),
    );

    final updatedShared = [...existingShared, sharedAccess];
    await _firestore.collection('vehicles').doc(invitation.vehicleId).update({
      'sharedWith': updatedShared.map((a) => a.toMap()).toList(),
    });

    await _ref
        .read(sharingServiceProvider)
        .updateVehicleSearchIndex(invitation.vehicleId);
  }

  /// Le destinataire saisit le code reçu dans Messenger, WhatsApp, SMS, etc.
  Future<void> acceptByCode(String rawCode) async {
    final currentUser = _ref.read(authServiceProvider).currentUser;
    if (currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    final code = rawCode.trim().toUpperCase();
    if (code.length < 4) {
      throw Exception('Code invalide');
    }

    final snap =
        await _col.where('inviteCode', isEqualTo: code).limit(5).get();
    final pending = snap.docs
        .map((d) => ShareInvitation.fromMap(d.data(), d.id))
        .where((i) => i.isPending)
        .toList();
    if (pending.isEmpty) {
      throw Exception('Aucune invitation en attente pour ce code');
    }

    final invitation = pending.first;
    if (invitation.fromUserId == currentUser.uid) {
      throw Exception('Vous ne pouvez pas accepter votre propre invitation');
    }

    final myEmail = (currentUser.email ?? '').toLowerCase();
    await _grantAccessAfterAccept(
      invitation: invitation,
      recipientUserId: currentUser.uid,
      recipientEmail: myEmail.isNotEmpty ? myEmail : invitation.toEmail,
      recipientName: currentUser.displayName ?? invitation.toDisplayName,
    );

    await _col.doc(invitation.id).update({
      'status': ShareInvitationStatus.accepted.name,
      'toUserId': currentUser.uid,
      'toEmail': myEmail.isNotEmpty ? myEmail : invitation.toEmail,
      'respondedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> rejectInvitation(String invitationId) async {
    final currentUser = _ref.read(authServiceProvider).currentUser;
    if (currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    final doc = await _col.doc(invitationId).get();
    if (!doc.exists) {
      throw Exception('Invitation introuvable');
    }

    final invitation = ShareInvitation.fromMap(doc.data()!, doc.id);
    if (!invitation.isPending) {
      throw Exception('Cette invitation n\'est plus valide');
    }

    final myEmail = (currentUser.email ?? '').toLowerCase();
    final isRecipient = invitation.toUserId == currentUser.uid ||
        invitation.toEmail == myEmail;
    if (!isRecipient) {
      throw Exception('Cette invitation ne vous est pas destinée');
    }

    await _col.doc(invitationId).update({
      'status': ShareInvitationStatus.rejected.name,
      'toUserId': currentUser.uid,
      'respondedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> cancelInvitation(String invitationId) async {
    final currentUser = _ref.read(authServiceProvider).currentUser;
    if (currentUser == null) {
      throw Exception('Utilisateur non connecté');
    }

    final doc = await _col.doc(invitationId).get();
    if (!doc.exists) {
      throw Exception('Invitation introuvable');
    }

    final invitation = ShareInvitation.fromMap(doc.data()!, doc.id);
    if (invitation.fromUserId != currentUser.uid) {
      throw Exception('Seul l\'expéditeur peut annuler cette invitation');
    }
    if (!invitation.isPending) return;

    await _col.doc(invitationId).update({
      'status': ShareInvitationStatus.cancelled.name,
      'respondedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Lie les invitations email → userId après inscription / connexion.
  Future<int> claimPendingInvitations({
    required String userId,
    required String email,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return 0;

    final snap = await _col.where('toEmail', isEqualTo: normalized).get();

    var count = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['status'] != ShareInvitationStatus.pending.name) continue;
      if (data['toUserId'] == userId) continue;
      await doc.reference.update({'toUserId': userId});
      count++;
    }
    return count;
  }

  Stream<List<ShareInvitation>> watchIncomingPending({
    required String userId,
  }) {
    return _col
        .where('toUserId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ShareInvitation.fromMap(d.data(), d.id))
          .where((i) => i.isPending)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<ShareInvitation>> watchOutgoingByOwner({
    required String userId,
  }) {
    return _col.where('fromUserId', isEqualTo: userId).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => ShareInvitation.fromMap(d.data(), d.id))
          .where((i) => i.isPending)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<ShareInvitation>> watchOutgoingPending({
    required String vehicleId,
  }) {
    return _col
        .where('vehicleId', isEqualTo: vehicleId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ShareInvitation.fromMap(d.data(), d.id))
          .where((i) => i.isPending)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  String _newInviteCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      6,
      (_) => alphabet[random.nextInt(alphabet.length)],
    ).join();
  }

  String _digits(String? value) =>
      (value ?? '').replaceAll(RegExp(r'\D'), '');

  Future<String?> _findUserIdByEmail(String email) async {
    var snap = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }
}

/// Affiche une notification locale quand une nouvelle invitation arrive.
class ShareInvitationNotifier {
  ShareInvitationNotifier._();
  static final instance = ShareInvitationNotifier._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Set<String> _seenIds = {};
  bool _ready = false;

  Future<void> ensureReady() async {
    if (_ready || kIsWeb) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  Future<void> notifyNewInvitations(List<ShareInvitation> invites) async {
    if (kIsWeb) return;
    await ensureReady();

    for (final invite in invites) {
      if (_seenIds.contains(invite.id)) continue;
      _seenIds.add(invite.id);

      final from = invite.fromName?.trim().isNotEmpty == true
          ? invite.fromName!
          : invite.fromEmail;

      await _plugin.show(
        id: invite.id.hashCode & 0x7fffffff,
        title: 'Invitation de partage',
        body: '$from vous invite à accéder à ${invite.vehicleLabel}',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'share_invitations',
            'Invitations de partage',
            channelDescription: 'Demandes d\'accès à un véhicule',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    }
  }

  void markSeen(Iterable<String> ids) {
    _seenIds.addAll(ids);
  }
}
