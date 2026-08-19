import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'generic_counter_screen.dart';
import 'darts_screen.dart';
import '../services/update_checker.dart';

const String _dismissedUpdateKey = 'dismissed_update_version';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  UpdateInfo? _update;

  @override
  void initState() {
    super.initState();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    final update = await checkForUpdate();
    if (update == null || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getString(_dismissedUpdateKey);
    if (dismissed == update.version) return;

    if (mounted) {
      setState(() {
        _update = update;
      });
    }
  }

  Future<void> _dismissUpdate() async {
    final update = _update;
    if (update == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedUpdateKey, update.version);
    setState(() {
      _update = null;
    });
  }

  Future<void> _openRelease() async {
    final update = _update;
    if (update == null) return;
    await launchUrl(
      Uri.parse(update.releaseUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contador de puntuaciones'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_update != null) ...[
                  Card(
                    color: colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.new_releases_outlined,
                                color: colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Nueva versión disponible: ${_update!.version}',
                                  style: TextStyle(
                                    color: colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _openRelease,
                                  icon: const Icon(Icons.download_outlined),
                                  label: const Text('Descargar'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: _dismissUpdate,
                                child: const Text('Ahora no'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const GenericCounterScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text(
                      'Contador general',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const DartsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.track_changes_outlined),
                    label: const Text(
                      'Dardos',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
