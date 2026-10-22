import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/models/user_model.dart';

/// Contact téléphone croisé avec un éventuel compte Sayaraty.
class ShareCandidate {
  final String displayName;
  final String? email;
  final String? phone;
  final AppUser? sayaratyUser;
  final bool fromDeviceContacts;

  const ShareCandidate({
    required this.displayName,
    this.email,
    this.phone,
    this.sayaratyUser,
    this.fromDeviceContacts = true,
  });

  bool get isOnSayaraty => sayaratyUser != null;

  String get sortKey => displayName.toLowerCase();
}

final contactShareServiceProvider = Provider<ContactShareService>((ref) {
  return ContactShareService();
});

class ContactShareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> requestContactsPermission() {
    return FlutterContacts.requestPermission(readonly: true);
  }

  Future<List<ShareCandidate>> loadShareCandidates({
    required String currentUserId,
  }) async {
    final granted = await requestContactsPermission();
    if (!granted) {
      throw Exception('permission_denied');
    }

    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: false,
    );

    final byEmail = <String, ShareCandidate>{};

    for (final contact in contacts) {
      final name = contact.displayName.trim().isEmpty
          ? 'Sans nom'
          : contact.displayName.trim();
      final phone = contact.phones.isNotEmpty
          ? contact.phones.first.number
          : null;

      for (final emailAddr in contact.emails) {
        final email = emailAddr.address.trim().toLowerCase();
        if (email.isEmpty || !email.contains('@')) continue;

        byEmail.putIfAbsent(
          email,
          () => ShareCandidate(
            displayName: name,
            email: email,
            phone: phone,
            fromDeviceContacts: true,
          ),
        );
      }

      // Contact sans email : visible pour invitation, pas matchable sur Sayaraty.
      if (contact.emails.isEmpty && phone != null && phone.trim().isNotEmpty) {
        final key = 'phone:${phone.trim()}';
        byEmail.putIfAbsent(
          key,
          () => ShareCandidate(
            displayName: name,
            phone: phone.trim(),
            fromDeviceContacts: true,
          ),
        );
      }
    }

    final emails = byEmail.keys
        .where((k) => k.contains('@'))
        .toList(growable: false);

    final usersByEmail = await _lookupUsersByEmails(emails);
    usersByEmail.remove(currentUserId);

    final emailToUser = <String, AppUser>{};
    for (final user in usersByEmail.values) {
      emailToUser[user.email.trim().toLowerCase()] = user;
    }

    final result = <ShareCandidate>[];
    for (final entry in byEmail.entries) {
      final email = entry.key.contains('@') ? entry.key : entry.value.email;
      final user = email != null ? emailToUser[email] : null;
      if (user != null && user.uid == currentUserId) continue;

      result.add(
        ShareCandidate(
          displayName: entry.value.displayName,
          email: email ?? entry.value.email,
          phone: entry.value.phone,
          sayaratyUser: user,
          fromDeviceContacts: true,
        ),
      );
    }

    result.sort((a, b) {
      if (a.isOnSayaraty != b.isOnSayaraty) {
        return a.isOnSayaraty ? -1 : 1;
      }
      return a.sortKey.compareTo(b.sortKey);
    });

    return result;
  }

  /// Recherche un utilisateur Sayaraty par email exact (saisie manuelle).
  Future<AppUser?> findUserByEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) return null;

    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalized)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      // Essai avec l'email tel quel (comptes créés sans normalisation).
      final raw = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .limit(1)
          .get();
      if (raw.docs.isEmpty) return null;
      return _userFromDoc(raw.docs.first);
    }

    return _userFromDoc(snapshot.docs.first);
  }

  Future<Map<String, AppUser>> _lookupUsersByEmails(List<String> emails) async {
    final result = <String, AppUser>{};
    if (emails.isEmpty) return result;

    // Firestore whereIn : max 30 valeurs.
    const chunkSize = 30;
    for (var i = 0; i < emails.length; i += chunkSize) {
      final chunk = emails.sublist(
        i,
        i + chunkSize > emails.length ? emails.length : i + chunkSize,
      );

      final snapshot = await _firestore
          .collection('users')
          .where('email', whereIn: chunk)
          .get();

      for (final doc in snapshot.docs) {
        final user = _userFromDoc(doc);
        result[user.uid] = user;
      }
    }

    return result;
  }

  AppUser _userFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = Map<String, dynamic>.from(doc.data());
    data['uid'] = data['uid'] ?? doc.id;
    return AppUser.fromMap(data);
  }
}
