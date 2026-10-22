import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../auth/application/auth_state_notifier.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../application/share_invite_message.dart';
import '../../application/share_invitation_service.dart';
import '../../domain/models/share_invitation_model.dart';

/// Liste des invitations de partage à accepter ou refuser.
class ShareInvitationsInboxScreen extends ConsumerWidget {
  const ShareInvitationsInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authStateNotifierProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('Connectez-vous pour voir vos invitations')),
          );
        }
        return _InboxBody(user: user);
      },
    );
  }
}

class _InboxBody extends ConsumerStatefulWidget {
  final AppUser user;

  const _InboxBody({required this.user});

  @override
  ConsumerState<_InboxBody> createState() => _InboxBodyState();
}

class _InboxBodyState extends ConsumerState<_InboxBody> {
  final _busyIds = <String>{};
  final _codeController = TextEditingController();
  bool _acceptingCode = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _acceptCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    setState(() => _acceptingCode = true);
    try {
      await ref.read(shareInvitationServiceProvider).acceptByCode(code);
      if (!mounted) return;
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation acceptée. Le véhicule est accessible.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _acceptingCode = false);
    }
  }

  Future<void> _resend(ShareInvitation invite) async {
    final saved = await SharePlayLinkPrefs.load();
    final who = invite.toDisplayName?.trim() ?? '';
    await Share.share(
      buildVehicleInviteMessage(
        vehicleLabel: invite.vehicleLabel,
        code: invite.inviteCode,
        greetingName: who,
        includePlayLink: saved.include,
        playLink: saved.link,
      ),
      subject: 'Invitation Sayaraty — ${invite.vehicleLabel}',
    );
  }

  Future<void> _accept(ShareInvitation invite) async {
    setState(() => _busyIds.add(invite.id));
    try {
      await ref
          .read(shareInvitationServiceProvider)
          .acceptInvitation(invite.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Accès à ${invite.vehicleLabel} accepté'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(invite.id));
    }
  }

  Future<void> _reject(ShareInvitation invite) async {
    setState(() => _busyIds.add(invite.id));
    try {
      await ref
          .read(shareInvitationServiceProvider)
          .rejectInvitation(invite.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation refusée')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(invite.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitesAsync =
        ref.watch(pendingShareInvitationsProvider(widget.user.uid));
    final outgoingAsync =
        ref.watch(myOutgoingInvitationsProvider(widget.user.uid));
    final incoming = invitesAsync.asData?.value ?? const <ShareInvitation>[];
    final outgoing = outgoingAsync.asData?.value ?? const <ShareInvitation>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitations de partage'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const Text(
            'Vous avez reçu un code',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Collez le code envoyé par Messenger, WhatsApp ou SMS, puis acceptez.',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(8),
            ],
            decoration: InputDecoration(
              hintText: 'Ex. K7MQ2P',
              prefixIcon: const Icon(Icons.vpn_key_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _acceptingCode ? null : _acceptCode,
            child: _acceptingCode
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Accepter avec ce code'),
          ),
          if (incoming.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text(
              'Invitations reçues',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            ...incoming.map(_incomingTile),
          ],
          const SizedBox(height: 28),
          const Text(
            'Invitations que vous avez envoyées',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (outgoingAsync.isLoading && outgoing.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (outgoing.isEmpty)
            Text(
              'Aucune invitation en attente. Depuis un véhicule, '
              'appuyez sur Partager : le code apparaît ici et dans le message.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...outgoing.map(_outgoingTile),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.push('/vehicles/shared'),
            child: const Text('Voir les véhicules partagés'),
          ),
        ],
      ),
    );
  }

  Widget _incomingTile(ShareInvitation invite) {
    final busy = _busyIds.contains(invite.id);
    final from = invite.fromName?.trim().isNotEmpty == true
        ? invite.fromName!
        : invite.fromEmail;
    final access = invite.canWrite ? 'Lecture et écriture' : 'Lecture seule';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.teal.shade400,
        child: const Icon(Icons.directions_car, color: Colors.white),
      ),
      title: Text(invite.vehicleLabel),
      subtitle: Text('$from vous invite · $access'),
      trailing: busy
          ? const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Refuser',
                  onPressed: () => _reject(invite),
                  icon: const Icon(Icons.close, color: Colors.red),
                ),
                IconButton(
                  tooltip: 'Accepter',
                  onPressed: () => _accept(invite),
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                ),
              ],
            ),
    );
  }

  Widget _outgoingTile(ShareInvitation invite) {
    final name = invite.toDisplayName?.trim().isNotEmpty == true
        ? invite.toDisplayName!
        : (invite.toEmail.isNotEmpty ? invite.toEmail : 'Contact');
    return Card(
      child: ListTile(
        title: Text(invite.vehicleLabel),
        subtitle: Text(
          '$name\nCode ${invite.inviteCode.isEmpty ? '—' : invite.inviteCode}',
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'resend') _resend(invite);
            if (value == 'cancel') {
              ref
                  .read(shareInvitationServiceProvider)
                  .cancelInvitation(invite.id);
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'resend', child: Text('Renvoyer le message')),
            PopupMenuItem(value: 'cancel', child: Text('Annuler')),
          ],
        ),
      ),
    );
  }
}
