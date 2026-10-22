import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../application/share_invite_message.dart';
import '../../application/share_invitation_service.dart';
import '../../application/sharing_service.dart';
import '../../application/vehicle_service.dart';
import '../../domain/models/share_invitation_model.dart';
import '../../domain/models/shared_access_model.dart';
import '../../domain/models/vehicule_model.dart';

/// Partage direct : le choix de l'application (Messenger, WhatsApp, SMS…).
class ShareVehiclePickerScreen extends ConsumerStatefulWidget {
  final Vehicle vehicle;

  const ShareVehiclePickerScreen({super.key, required this.vehicle});

  @override
  ConsumerState<ShareVehiclePickerScreen> createState() =>
      _ShareVehiclePickerScreenState();
}

class _ShareVehiclePickerScreenState
    extends ConsumerState<ShareVehiclePickerScreen> {
  ShareInvitation? _invitation;
  bool _opening = true;
  String? _error;
  bool _includePlayLink = false;
  final _playLinkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepare());
  }

  @override
  void dispose() {
    _playLinkController.dispose();
    super.dispose();
  }

  Future<void> _prepare() async {
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final saved = await SharePlayLinkPrefs.load();
      final invitation =
          await ref.read(shareInvitationServiceProvider).prepareOpenInvitation(
                vehicleId: widget.vehicle.id,
              );
      if (!mounted) return;
      _playLinkController.text = saved.link;
      setState(() {
        _invitation = invitation;
        _includePlayLink = saved.include && saved.link.trim().isNotEmpty;
        _opening = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _opening = false;
        _error = '$e'.replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _share(ShareInvitation invitation) async {
    final link = _playLinkController.text.trim();
    if (_includePlayLink && link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Collez le lien Google Play, ou décochez l\'option.'),
        ),
      );
      return;
    }
    await SharePlayLinkPrefs.save(include: _includePlayLink, link: link);

    final label = invitation.vehicleLabel.trim().isEmpty
        ? '${widget.vehicle.brand} ${widget.vehicle.model}'.trim()
        : invitation.vehicleLabel;
    await Share.share(
      buildVehicleInviteMessage(
        vehicleLabel: label,
        code: invitation.inviteCode,
        includePlayLink: _includePlayLink,
        playLink: link,
      ),
      subject: 'Invitation Sayaraty — $label',
    );
  }

  Future<void> _revoke(SharedAccess access) async {
    final name = access.displayName?.trim().isNotEmpty == true
        ? access.displayName!
        : access.email;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer l\'accès'),
        content: Text('Retirer l\'accès de $name ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await ref.read(sharingServiceProvider).revokeAccess(
          vehicleId: widget.vehicle.id,
          userId: access.userId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = ref
            .watch(vehicleByIdStreamProvider(widget.vehicle.id))
            .asData
            ?.value ??
        widget.vehicle;
    final code = _invitation?.inviteCode ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text('Partager ${vehicle.brand} ${vehicle.model}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_opening)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))
          else ...[
            const Text(
              'La personne entre le code dans Sayaraty pour accepter. '
              'Vous pouvez ajouter le lien Google Play du test interne.',
            ),
            const SizedBox(height: 16),
            if (code.isNotEmpty)
              Text(
                'Code : $code',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ajouter le lien Google Play'),
              subtitle: const Text(
                'Lien du test interne, collé dans le message',
              ),
              value: _includePlayLink,
              onChanged: (value) => setState(() => _includePlayLink = value),
            ),
            if (_includePlayLink)
              TextField(
                controller: _playLinkController,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Lien Google Play',
                  hintText: 'https://play.google.com/apps/internaltest/…',
                ),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _invitation == null
                  ? _prepare
                  : () => _share(_invitation!),
              icon: const Icon(Icons.share),
              label: const Text('Choisir l\'application'),
            ),
          ],
          if (vehicle.sharedWith.isNotEmpty) ...[
            const SizedBox(height: 28),
            const Text(
              'Déjà accepté',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            ...vehicle.sharedWith.map(
              (access) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  access.displayName?.trim().isNotEmpty == true
                      ? access.displayName!
                      : access.email,
                ),
                subtitle: Text(
                  access.permissions.contains('edit')
                      ? 'Lecture et écriture'
                      : 'Lecture seule',
                ),
                trailing: TextButton(
                  onPressed: () => _revoke(access),
                  child: const Text('Retirer'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
