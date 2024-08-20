import 'package:flutter/material.dart';

void main() {
  runApp(const ScoreTrackerApp());
}

class ScoreTrackerApp extends StatelessWidget {
  const ScoreTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Score Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black87)
        )
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.black87,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white70),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white)
          )
        )
      ),
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

  void addPlayer() {
    setState(() {
      String newPlayer = playerNameController.text;
      if (newPlayer.isNotEmpty) {
        players.add(newPlayer);
        scores[newPlayer] = 0;
        controllers[newPlayer] = TextEditingController();
        playerNameController.clear();
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
      }
    });
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
        title: const Text('Score Tracker'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: playerNameController,
              decoration: const InputDecoration(
                labelText: 'Enter player name',
              ),
              onSubmitted: (value){
                addPlayer();
              },
            ),
          ),
          ElevatedButton(
            onPressed: addPlayer,
            child: const Text('Add Player'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                String player = players[index];
                return ListTile(
                  title: Text(
                    '$player: ${scores[player]} points',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 50,
                        child: TextField(
                          controller: controllers[player],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Score',
                          ),
                          onSubmitted: (value){
                            addScore(player);
                          },
                          style: Theme.of(context).textTheme.bodyMedium,
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
        ],
      ),
    );
  }
}

