import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _prefsKey = 'darts_game_state';

class _Dart {
  final int value;
  final int multiplier;

  const _Dart(this.value, this.multiplier);

  int get score => value * multiplier;

  String get label {
    if (value == 0) return 'Fallo';
    if (value == 25) {
      return multiplier == 2 ? 'Bull doble ($score)' : 'Bull ($score)';
    }
    switch (multiplier) {
      case 3:
        return 'T$value ($score)';
      case 2:
        return 'D$value ($score)';
      default:
        return '$value';
    }
  }

  Map<String, dynamic> toJson() => {'value': value, 'multiplier': multiplier};

  factory _Dart.fromJson(Map<String, dynamic> json) =>
      _Dart(json['value'] as int, json['multiplier'] as int);
}

class _TurnRecord {
  final String player;
  final List<_Dart> darts;
  final int scoredPoints;
  final bool busted;
  final int remainingAfter;

  const _TurnRecord({
    required this.player,
    required this.darts,
    required this.scoredPoints,
    required this.busted,
    required this.remainingAfter,
  });

  Map<String, dynamic> toJson() => {
        'player': player,
        'darts': darts.map((d) => d.toJson()).toList(),
        'scoredPoints': scoredPoints,
        'busted': busted,
        'remainingAfter': remainingAfter,
      };

  factory _TurnRecord.fromJson(Map<String, dynamic> json) => _TurnRecord(
        player: json['player'] as String,
        darts: (json['darts'] as List)
            .map((d) => _Dart.fromJson(d as Map<String, dynamic>))
            .toList(),
        scoredPoints: json['scoredPoints'] as int,
        busted: json['busted'] as bool,
        remainingAfter: json['remainingAfter'] as int,
      );
}

class _PlayerStats {
  int turns = 0;
  int darts = 0;
  int points = 0;

  double get average => darts == 0 ? 0 : points / darts;
}

class DartsGameScreen extends StatefulWidget {
  final List<String> players;
  final int startingScore;
  final bool resume;

  const DartsGameScreen({
    super.key,
    required this.players,
    required this.startingScore,
  }) : resume = false;

  const DartsGameScreen.resume({super.key})
      : players = const [],
        startingScore = 0,
        resume = true;

  static Future<bool> hasSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_prefsKey);
  }

  static Future<void> clearSavedGame() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  @override
  State<DartsGameScreen> createState() => _DartsGameScreenState();
}

class _DartsGameScreenState extends State<DartsGameScreen> {
  static const List<int> dartValues = [
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    25,
  ];

  late List<String> players;
  late int startingScore;
  late Map<String, int> remaining;
  int currentPlayerIndex = 0;
  late int turnStartRemaining;
  List<_Dart> dartsThisTurn = [];
  List<_TurnRecord> history = [];

  int selectedValue = 20;
  int selectedMultiplier = 1;

  String? winner;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.resume) {
      _loadState();
    } else {
      players = widget.players;
      startingScore = widget.startingScore;
      remaining = {for (final player in players) player: startingScore};
      turnStartRemaining = remaining[currentPlayer]!;
      loading = false;
      _saveState();
    }
  }

  String get currentPlayer => players[currentPlayerIndex];

  bool get tripleAllowed => selectedValue != 0 && selectedValue != 25;

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'players': players,
        'startingScore': startingScore,
        'remaining': remaining,
        'currentPlayerIndex': currentPlayerIndex,
        'turnStartRemaining': turnStartRemaining,
        'dartsThisTurn': dartsThisTurn.map((d) => d.toJson()).toList(),
        'history': history.map((r) => r.toJson()).toList(),
        'winner': winner,
      }),
    );
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    setState(() {
      players = List<String>.from(json['players'] as List);
      startingScore = json['startingScore'] as int;
      remaining = Map<String, int>.from(json['remaining'] as Map);
      currentPlayerIndex = json['currentPlayerIndex'] as int;
      turnStartRemaining = json['turnStartRemaining'] as int;
      dartsThisTurn = (json['dartsThisTurn'] as List)
          .map((d) => _Dart.fromJson(d as Map<String, dynamic>))
          .toList();
      history = (json['history'] as List)
          .map((r) => _TurnRecord.fromJson(r as Map<String, dynamic>))
          .toList();
      winner = json['winner'] as String?;
      loading = false;
    });
  }

  void _selectValue(int value) {
    setState(() {
      selectedValue = value;
      if (!tripleAllowed && selectedMultiplier == 3) {
        selectedMultiplier = 1;
      }
      if (value == 0) {
        selectedMultiplier = 1;
      }
    });
  }

  void _selectMultiplier(int multiplier) {
    if (multiplier == 3 && !tripleAllowed) return;
    if (selectedValue == 0) return;
    setState(() {
      selectedMultiplier = multiplier;
    });
  }

  void _throwDart() {
    if (winner != null) return;

    final dart = _Dart(selectedValue, selectedMultiplier);
    final currentRemaining = remaining[currentPlayer]!;
    final tentative = currentRemaining - dart.score;

    setState(() {
      dartsThisTurn.add(dart);
    });

    if (tentative < 0 || tentative == 1) {
      _finishTurn(busted: true, remainingAfter: turnStartRemaining);
      return;
    }

    if (tentative == 0) {
      if (dart.multiplier == 2) {
        setState(() {
          remaining[currentPlayer] = 0;
        });
        _finishTurn(busted: false, remainingAfter: 0, isWin: true);
      } else {
        _finishTurn(busted: true, remainingAfter: turnStartRemaining);
      }
      return;
    }

    setState(() {
      remaining[currentPlayer] = tentative;
    });

    if (dartsThisTurn.length == 3) {
      _finishTurn(busted: false, remainingAfter: tentative);
    } else {
      _saveState();
    }
  }

  void _finishTurn({
    required bool busted,
    required int remainingAfter,
    bool isWin = false,
  }) {
    final scoredPoints = busted ? 0 : (turnStartRemaining - remainingAfter);
    final record = _TurnRecord(
      player: currentPlayer,
      darts: List<_Dart>.from(dartsThisTurn),
      scoredPoints: scoredPoints,
      busted: busted,
      remainingAfter: remainingAfter,
    );

    setState(() {
      if (busted) {
        remaining[currentPlayer] = turnStartRemaining;
      }
      history.insert(0, record);
      if (isWin) {
        winner = currentPlayer;
      }
    });
    _saveState();

    if (isWin) {
      _showEndOfTurnDialog(
        title: '¡Partida ganada!',
        message:
            '$currentPlayer ha cerrado en 0 con un doble y gana la partida.',
      );
    } else if (busted) {
      _showEndOfTurnDialog(
        title: '¡Turno anulado!',
        message: '$currentPlayer se ha pasado o no ha cerrado con un doble. '
            'La puntuación vuelve a $turnStartRemaining.',
      );
    } else {
      _nextTurn();
    }
  }

  void _showEndOfTurnDialog({required String title, required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (winner == null) {
                _nextTurn();
              }
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  void _nextTurn() {
    setState(() {
      currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
      turnStartRemaining = remaining[currentPlayer]!;
      dartsThisTurn = [];
      selectedValue = 20;
      selectedMultiplier = 1;
    });
    _saveState();
  }

  void _showHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Historial de turnos',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildHistoryList(scrollController)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(ScrollController? scrollController) {
    if (history.isEmpty) {
      return const Center(child: Text('Todavía no se han lanzado dardos.'));
    }
    return ListView.builder(
      controller: scrollController,
      itemCount: history.length,
      itemBuilder: (context, index) {
        final record = history[index];
        final dartsLabel = record.darts.map((d) => d.label).join(', ');
        final colorScheme = Theme.of(context).colorScheme;
        return ListTile(
          dense: true,
          leading: Icon(
            record.busted ? Icons.block : Icons.check_circle,
            color: record.busted ? colorScheme.error : colorScheme.tertiary,
          ),
          title: Text('${record.player}: $dartsLabel'),
          subtitle: Text(
            record.busted
                ? 'Turno anulado · restante: ${record.remainingAfter}'
                : '${record.scoredPoints} pts · restante: ${record.remainingAfter}',
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Dardos - a $startingScore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de turnos',
            onPressed: _showHistorySheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildScoreboard(),
            const Divider(height: 1),
            if (winner != null)
              Expanded(child: _buildWinnerView())
            else
              Expanded(child: _buildThrowControls()),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreboard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          for (final player in players)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: player == currentPlayer && winner == null
                    ? colorScheme.primaryContainer
                    : colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  if (player == currentPlayer && winner == null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.sports_esports,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      player,
                      style: TextStyle(
                        fontWeight: player == currentPlayer && winner == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: player == currentPlayer && winner == null
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${remaining[player]}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: player == currentPlayer && winner == null
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWinnerView() {
    final statsByPlayer = <String, _PlayerStats>{
      for (final player in players) player: _PlayerStats(),
    };
    for (final record in history) {
      final stats = statsByPlayer[record.player]!;
      stats.turns += 1;
      stats.darts += record.darts.length;
      stats.points += record.scoredPoints;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Icon(Icons.emoji_events, color: colorScheme.primary, size: 40),
          const SizedBox(height: 8),
          Text(
            '¡$winner ha ganado la partida!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Jugador')),
                    DataColumn(label: Text('Turnos')),
                    DataColumn(label: Text('Dardos')),
                    DataColumn(label: Text('Puntos')),
                    DataColumn(label: Text('Media/dardo')),
                  ],
                  rows: [
                    for (final player in players)
                      DataRow(cells: [
                        DataCell(Text(player)),
                        DataCell(Text('${statsByPlayer[player]!.turns}')),
                        DataCell(Text('${statsByPlayer[player]!.darts}')),
                        DataCell(Text('${statsByPlayer[player]!.points}')),
                        DataCell(
                          Text(
                            statsByPlayer[player]!.average.toStringAsFixed(1),
                          ),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Historial de turnos',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: Card(child: _buildHistoryList(null))),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await DartsGameScreen.clearSavedGame();
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              },
              icon: const Icon(Icons.home_outlined),
              label: const Text('Volver al menú'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThrowControls() {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Text(
            'Turno de $currentPlayer  ·  dardo ${dartsThisTurn.length + 1} de 3',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: dartsThisTurn.isEmpty
                ? null
                : ListView(
                    scrollDirection: Axis.horizontal,
                    children: dartsThisTurn
                        .map((dart) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Chip(label: Text(dart.label)),
                            ))
                        .toList(),
                  ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 6,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: dartValues.map((value) {
                  final selected = value == selectedValue;
                  final label = value == 25
                      ? 'Bull'
                      : value == 0
                          ? 'X'
                          : '$value';
                  return selected
                      ? FilledButton(
                          onPressed: () => _selectValue(value),
                          style:
                              FilledButton.styleFrom(padding: EdgeInsets.zero),
                          child: Text(label),
                        )
                      : OutlinedButton(
                          onPressed: () => _selectValue(value),
                          style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero),
                          child: Text(label),
                        );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            expandedInsets: EdgeInsets.zero,
            showSelectedIcon: false,
            segments: [
              const ButtonSegment(value: 1, label: Text('x1')),
              ButtonSegment(
                value: 2,
                label: const Text('x2 (Doble)'),
                enabled: selectedValue != 0,
              ),
              ButtonSegment(
                value: 3,
                label: const Text('x3 (Triple)'),
                enabled: tripleAllowed,
              ),
            ],
            selected: {selectedMultiplier},
            onSelectionChanged: (selection) =>
                _selectMultiplier(selection.first),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _throwDart,
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.tertiaryContainer,
                foregroundColor: colorScheme.onTertiaryContainer,
              ),
              icon: const Icon(Icons.sports_score),
              label: const Text('Lanzar dardo'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
