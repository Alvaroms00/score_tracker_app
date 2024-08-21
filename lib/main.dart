import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const ScoreTrackerApp());
}

class ScoreTrackerApp extends StatelessWidget {
  const ScoreTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contador de puntuaciones',
      theme: ThemeData(
          primarySwatch: Colors.blue,
          brightness: Brightness.light,
          textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black),
              bodyMedium: TextStyle(color: Colors.black))),
      darkTheme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.black87,
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white),
          ),
          inputDecorationTheme: const InputDecorationTheme(
              labelStyle: TextStyle(color: Colors.white),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white)))),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contador de puntuaciones'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: playerNameController,
              decoration: const InputDecoration(
                labelText: 'Introduce el nombre del jugador',
              ),
              onSubmitted: (value) {
                addPlayer();
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: addPlayer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue[200],
                  iconColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Añadir jugador'),
              ),
              ElevatedButton(
                onPressed: clearPlayersAndScores,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  iconColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Borrar todo'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                String player = players[index];
                return ListTile(
                  title: Text('$player: ${scores[player]} puntos'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: controllers[player],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Puntos',
                          ),
                          onSubmitted: (value) {
                            addScore(player);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => addScore(player),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: addAllScores,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  iconColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Añadir puntuación'),
              ),
              ElevatedButton(
                onPressed: clearScores,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  iconColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Borrar puntuación'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
