import 'package:flutter/material.dart';
import 'darts_game_screen.dart';

class DartsScoreScreen extends StatelessWidget {
  final List<String> players;

  const DartsScoreScreen({super.key, required this.players});

  static const List<int> presets = [301, 501, 701, 901];

  void _start(BuildContext context, int startingScore) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DartsGameScreen(
          players: players,
          startingScore: startingScore,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Puntuación de salida'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Elige la puntuación de salida',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                for (final score in presets) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _start(context, score),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: Text(
                        '$score',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
