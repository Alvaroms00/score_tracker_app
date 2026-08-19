import 'package:flutter/material.dart';
import 'darts_game_screen.dart';
import 'darts_score_screen.dart';

class DartsScreen extends StatefulWidget {
  const DartsScreen({super.key});

  @override
  State<DartsScreen> createState() => _DartsScreenState();
}

class _DartsScreenState extends State<DartsScreen> {
  final List<String> players = [];
  final TextEditingController nameController = TextEditingController();
  List<String>? order;
  bool hasSavedGame = false;

  @override
  void initState() {
    super.initState();
    _checkSavedGame();
  }

  Future<void> _checkSavedGame() async {
    final saved = await DartsGameScreen.hasSavedGame();
    if (mounted) {
      setState(() {
        hasSavedGame = saved;
      });
    }
  }

  void addPlayer() {
    final name = nameController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      players.add(name);
      nameController.clear();
    });
  }

  void removePlayer(int index) {
    setState(() {
      players.removeAt(index);
    });
  }

  void shuffleAndStart() {
    setState(() {
      order = List<String>.from(players)..shuffle();
    });
  }

  void editPlayers() {
    setState(() {
      order = null;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dardos'),
      ),
      body: SafeArea(
        child: order == null ? _buildSetup() : _buildOrder(),
      ),
    );
  }

  Widget _buildSetup() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        if (hasSavedGame)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const DartsGameScreen.resume(),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                ),
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('Continuar partida guardada'),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Introduce el nombre del jugador',
              prefixIcon: Icon(Icons.person_add_alt_1_outlined),
            ),
            onSubmitted: (value) => addPlayer(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: addPlayer,
              icon: const Icon(Icons.add),
              label: const Text('Añadir jugador'),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            itemCount: players.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  title: Text(players[index]),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    onPressed: () => removePlayer(index),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: players.length >= 2 ? shuffleAndStart : null,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.tertiaryContainer,
                foregroundColor: colorScheme.onTertiaryContainer,
                disabledBackgroundColor:
                    colorScheme.onSurface.withValues(alpha: 0.12),
              ),
              icon: const Icon(Icons.shuffle),
              label: const Text('Sortear y comenzar'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrder() {
    final colorScheme = Theme.of(context).colorScheme;
    final players = order!;
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            itemCount: players.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(players[index]),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: shuffleAndStart,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('Sortear de nuevo'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: editPlayers,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar jugadores'),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DartsScoreScreen(players: players),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.tertiaryContainer,
                foregroundColor: colorScheme.onTertiaryContainer,
              ),
              icon: const Icon(Icons.sports_score),
              label: const Text('Elegir puntuación y jugar'),
            ),
          ),
        ),
      ],
    );
  }
}
