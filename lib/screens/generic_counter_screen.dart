// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GenericCounterScreen extends StatefulWidget {
  const GenericCounterScreen({super.key});

  @override
  _GenericCounterScreenState createState() => _GenericCounterScreenState();
}

class _GenericCounterScreenState extends State<GenericCounterScreen> {
  List<String> players = [];
  Map<String, int> scores = {};
  TextEditingController playerNameController = TextEditingController();
  Map<String, TextEditingController> controllers = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void addPlayer() {
    setState(() {
      String newPlayer = playerNameController.text;
      if (newPlayer.isNotEmpty) {
        players.add(newPlayer);
        scores[newPlayer] = 0;
        controllers[newPlayer] = TextEditingController();
        playerNameController.clear();
        saveData();
      }
    });
  }

  void addScore(String player) {
    setState(() {
      String score = controllers[player]!.text;
      if (score.isNotEmpty) {
        int scoreValue = int.tryParse(score) ?? 0;
        scores[player] = scores[player]! + scoreValue;
        controllers[player]!.clear();
        saveData();
      }
    });
  }

  void addAllScores() {
    setState(() {
      for (String player in players) {
        String score = controllers[player]!.text;
        if (score.isNotEmpty) {
          int scoreValue = int.tryParse(score) ?? 0;
          scores[player] = scores[player]! + scoreValue;
          controllers[player]!.clear();
        }
      }
      saveData();
    });
  }

  void clearScores() {
    setState(() {
      scores.forEach((key, value) {
        scores[key] = 0;
      });
      saveData();
    });
  }

  void clearPlayersAndScores() {
    setState(() {
      players.clear();
      scores.clear();
      controllers.clear();
      saveData();
    });
  }

  Future<void> saveData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('players', jsonEncode(players));
    prefs.setString('scores', jsonEncode(scores));
  }

  Future<void> loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? playersString = prefs.getString('players');
    String? scoresString = prefs.getString('scores');

    if (playersString != null && scoresString != null) {
      setState(() {
        players = List<String>.from(jsonDecode(playersString));
        scores = Map<String, int>.from(jsonDecode(scoresString));
        controllers = {
          for (var player in players) player: TextEditingController()
        };
      });
    }
  }

  @override
  void dispose() {
    playerNameController.dispose();
    controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contador general'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: playerNameController,
                decoration: const InputDecoration(
                  labelText: 'Introduce el nombre del jugador',
                  prefixIcon: Icon(Icons.person_add_alt_1_outlined),
                ),
                onSubmitted: (value) {
                  addPlayer();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: addPlayer,
                      icon: const Icon(Icons.add),
                      label: const Text('Añadir jugador'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: clearPlayersAndScores,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                      ),
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('Borrar todo'),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: players.length,
                itemBuilder: (context, index) {
                  String player = players[index];
                  return Card(
                    child: ListTile(
                      title: Text(player),
                      subtitle: Text('${scores[player]} puntos'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 84,
                            child: TextField(
                              controller: controllers[player],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Pts',
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              onSubmitted: (value) {
                                addScore(player);
                              },
                            ),
                          ),
                          IconButton.filledTonal(
                            icon: const Icon(Icons.add),
                            onPressed: () => addScore(player),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: addAllScores,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.tertiaryContainer,
                        foregroundColor: colorScheme.onTertiaryContainer,
                      ),
                      icon: const Icon(Icons.playlist_add_check),
                      label: const Text('Añadir puntuación'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: clearScores,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                      ),
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Borrar puntuación'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
