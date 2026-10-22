import 'package:shared_preferences/shared_preferences.dart';

const sharePlayStoreLinkKey = 'share_play_store_link';
const sharePlayStoreLinkEnabledKey = 'share_play_store_link_enabled';

class SharePlayLinkPrefs {
  final bool include;
  final String link;

  const SharePlayLinkPrefs({required this.include, required this.link});

  static Future<SharePlayLinkPrefs> load() async {
    final prefs = await SharedPreferences.getInstance();
    return SharePlayLinkPrefs(
      include: prefs.getBool(sharePlayStoreLinkEnabledKey) ?? false,
      link: prefs.getString(sharePlayStoreLinkKey) ?? '',
    );
  }

  static Future<void> save({
    required bool include,
    required String link,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(sharePlayStoreLinkEnabledKey, include);
    await prefs.setString(sharePlayStoreLinkKey, link.trim());
  }
}

String buildVehicleInviteMessage({
  required String vehicleLabel,
  required String code,
  String greetingName = '',
  bool includePlayLink = false,
  String playLink = '',
}) {
  final who = greetingName.trim().isEmpty ? '' : ' ${greetingName.trim()}';
  final hello = who.isEmpty ? 'Bonjour' : 'Salut$who';
  final buffer = StringBuffer(
    '$hello, je t\'invite à accéder à mon véhicule $vehicleLabel sur Sayaraty.\n'
    'Ouvre l\'application, appuie sur l\'enveloppe '
    '« Invitations de partage », puis entre le code : $code',
  );
  final link = playLink.trim();
  if (includePlayLink && link.isNotEmpty) {
    buffer
      ..writeln()
      ..writeln()
      ..writeln('Installe Sayaraty avec ce lien Google Play :')
      ..write(link);
  }
  return buffer.toString();
}
