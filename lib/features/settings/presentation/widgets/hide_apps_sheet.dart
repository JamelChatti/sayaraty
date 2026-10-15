import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'hidden_app_icons';

class _DeviceApp {
  final String packageName;
  final String name;
  final Uint8List? icon;

  const _DeviceApp({
    required this.packageName,
    required this.name,
    this.icon,
  });
}

Future<Set<String>> loadHiddenAppIds() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_prefsKey);
  if (raw == null || raw.isEmpty) return {};
  final list = (jsonDecode(raw) as List).cast<String>();
  return list.toSet();
}

Future<void> saveHiddenAppIds(Set<String> ids) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_prefsKey, jsonEncode(ids.toList()));
}

Future<void> showHideAppsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _HideAppsSheet(),
  );
}

class _HideAppsSheet extends StatefulWidget {
  const _HideAppsSheet();

  @override
  State<_HideAppsSheet> createState() => _HideAppsSheetState();
}

class _HideAppsSheetState extends State<_HideAppsSheet> {
  Set<String> _hidden = {};
  List<_DeviceApp> _apps = [];
  bool _loading = true;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final hidden = await loadHiddenAppIds();
      if (!Platform.isAndroid) {
        if (!mounted) return;
        setState(() {
          _hidden = hidden;
          _apps = [];
          _loading = false;
          _error = 'Disponible uniquement sur Android';
        });
        return;
      }

      final installed = await InstalledApps.getInstalledApps(
        excludeSystemApps: false,
        excludeNonLaunchableApps: true,
        withIcon: true,
      );

      final apps = installed
          .where((app) => app.packageName != 'com.sayaraty.app')
          .map(
            (app) => _DeviceApp(
              packageName: app.packageName,
              name: app.name.trim().isEmpty ? app.packageName : app.name,
              icon: app.icon,
            ),
          )
          .toList()
        ..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

      if (!mounted) return;
      setState(() {
        _hidden = hidden;
        _apps = apps;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les applications';
      });
    }
  }

  Future<void> _hide(String packageName) async {
    setState(() => _hidden = {..._hidden, packageName});
    await saveHiddenAppIds(_hidden);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Application masquée'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _restoreAll() async {
    setState(() => _hidden = {});
    await saveHiddenAppIds(_hidden);
  }

  List<_DeviceApp> get _visible {
    final q = _query.trim().toLowerCase();
    return _apps.where((app) {
      if (_hidden.contains(app.packageName)) return false;
      if (q.isEmpty) return true;
      return app.name.toLowerCase().contains(q) ||
          app.packageName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.75;

    return SizedBox(
      height: sheetHeight,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Masquer des apps',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _loading
                            ? 'Chargement des applications…'
                            : 'Liste privée dans Sayaraty uniquement '
                                '(pas le menu du téléphone)'
                                '${_apps.isEmpty ? '' : ' · ${visible.length}'}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (_hidden.isNotEmpty)
                  TextButton(
                    onPressed: _restoreAll,
                    child: const Text('Tout afficher'),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Rechercher une application',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _load,
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : visible.isEmpty
                        ? Center(
                            child: Text(
                              _query.trim().isEmpty
                                  ? 'Toutes les applications sont masquées'
                                  : 'Aucun résultat',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: visible.length,
                            itemBuilder: (context, index) {
                              final app = visible[index];
                              return Dismissible(
                                key: ValueKey(app.packageName),
                                direction: DismissDirection.horizontal,
                                onDismissed: (_) => _hide(app.packageName),
                                background: _hideBackground(),
                                secondaryBackground: _hideBackground(),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.grey.shade200,
                                      backgroundImage: app.icon != null
                                          ? MemoryImage(app.icon!)
                                          : null,
                                      child: app.icon == null
                                          ? const Icon(
                                              Icons.android,
                                              color: Colors.grey,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      app.name,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _hideBackground() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.visibility_off,
        color: Colors.red,
      ),
    );
  }
}
