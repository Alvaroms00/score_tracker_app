# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

"Contador de puntuaciones" (`contador_de_puntuaciones`) is a Flutter app for tracking scores in card/board games. It opens on a main menu and navigates into a specific game screen. Two games exist so far: a generic free-form counter (add players, add/accumulate scores per player, reset scores or clear everything) and a Dardos (darts) game with random turn order and 301/501/701/901 countdown scoring. All UI text is in Spanish.

## Commands

Standard Flutter tooling (SDK ^3.5.0, targets Android/iOS/Linux/macOS/Windows/Web):

- `flutter pub get` — install dependencies
- `flutter run` — run on a connected device/emulator
- `flutter analyze` — static analysis (uses `package:flutter_lints/flutter.yaml`, see [analysis_options.yaml](analysis_options.yaml))
- `dart format lib/` — format source (run after any manual multi-block edit)
- `flutter test` — run all tests
- `flutter test test/widget_test.dart` — run a single test file
- `flutter build apk` / `flutter build ios` / `flutter build web` — platform builds

Note: [test/widget_test.dart](test/widget_test.dart) is the default Flutter counter-app template test and does not match this app's actual UI (it looks for a `+` icon and numeric counter text right after pumping the widget, but the app now opens on `MainMenuScreen` first). It will fail if run as-is and needs rewriting to test real app behavior before it's useful.

Windows desktop builds (`flutter run -d windows`) require Developer Mode enabled in Windows settings (symlink support for plugins) — not enabled in this dev environment, so prefer the connected Android device or `flutter build web` + a static server for quick visual checks.

## Theming

[lib/main.dart](lib/main.dart) — `ScoreTrackerApp` builds light/dark `ThemeData` via `buildAppTheme(Brightness)`: Material 3 (`useMaterial3: true`), `ColorScheme.fromSeed` from a single soft seed color (`_seedColor`), and shared component themes (`FilledButtonThemeData`, `OutlinedButtonThemeData`, `cardTheme`, `inputDecorationTheme`, `chipTheme`, `segmentedButtonTheme`, `dialogTheme`, `bottomSheetTheme` — all `...ThemeData`, not the deprecated bare `...Theme` classes). `themeMode: ThemeMode.system`.

Screens should **not** hardcode `Colors.*` for buttons/backgrounds — use the theme instead:
- Primary navigation/add actions → `FilledButton` (inherits theme, no per-button style needed).
- Secondary/confirm actions (start game, submit) → `FilledButton` with `backgroundColor: colorScheme.tertiaryContainer` / `foregroundColor: colorScheme.onTertiaryContainer` for a distinct soft accent.
- Destructive actions (clear/delete) → `OutlinedButton` with `foregroundColor: colorScheme.error`, `side: BorderSide(color: colorScheme.error)`.
- Exclusive single-choice controls (e.g. dart multiplier x1/x2/x3) → `SegmentedButton` with `expandedInsets: EdgeInsets.zero` to fill width; disable individual segments via `ButtonSegment.enabled`, not by hiding them.
- Lists of entities (players, turn history) → wrap rows in `Card` (uses `cardTheme`) rather than bare `ListTile`s directly on the scaffold background.

Every `Scaffold.body` must be wrapped in `SafeArea` — without it, bottom-pinned buttons get obscured by Android's gesture/nav bar. This was a real bug fixed across all screens; don't regress it when adding a new screen.

## Architecture

No state management library. Navigation is plain `Navigator.push` with `MaterialPageRoute` (no named routes).

- [lib/main.dart](lib/main.dart) — `ScoreTrackerApp`, the root `MaterialApp`. See Theming above. Sets `home: const MainMenuScreen()`.
- [lib/screens/main_menu_screen.dart](lib/screens/main_menu_screen.dart) — `MainMenuScreen`, a stateless mode-selector screen: one big `FilledButton.icon` per game, each pushing that game's screen. This is where a new game gets a button when it's added.
- [lib/screens/generic_counter_screen.dart](lib/screens/generic_counter_screen.dart) — `GenericCounterScreen` / `_GenericCounterScreenState`, the free-form player/score counter (formerly the app's only screen, `HomePage`):
  - `players: List<String>` and `scores: Map<String, int>` are the core state, kept in sync with a `Map<String, TextEditingController>` (one score-input controller per player, keyed by player name).
  - Player names are used directly as map keys and controller keys — there's no unique ID, so renaming/duplicate-name handling isn't supported.
  - Persistence is manual via `shared_preferences`: `saveData()`/`loadData()` JSON-encode/decode `players` and `scores` into two separate string prefs entries (`players`, `scores`). Any state mutation that should persist must call `saveData()` explicitly — there's no automatic sync.
  - All mutating methods (`addPlayer`, `addScore`, `addAllScores`, `clearScores`, `clearPlayersAndScores`) wrap changes in `setState` and call `saveData()` inline.
  - This screen uses fixed pref keys (`players`, `scores`), so it's a singleton counter, not per-session — this is why Dardos below uses a differently-named key.

When editing `GenericCounterScreen`, keep persistence calls paired with state mutations, and keep `controllers` in sync with `players` (each player must have a corresponding controller, disposed when removed).

### Dardos (darts)

Three screens, chained via `Navigator.push`:

- [lib/screens/darts_screen.dart](lib/screens/darts_screen.dart) — `DartsScreen`. Two phases in one widget (`order == null ? _buildSetup() : _buildOrder()`):
  - Setup: add/remove player names (in-memory only, not persisted — this is just the pre-game roster).
  - Order: `players.shuffle()` produces a random turn order; "Sortear de nuevo" re-shuffles, "Editar jugadores" goes back to setup, "Elegir puntuación y jugar" pushes `DartsScoreScreen`.
  - On `initState`, checks `DartsGameScreen.hasSavedGame()` and shows a "Continuar partida guardada" button if an in-progress game exists in prefs, bypassing setup/order entirely via `DartsGameScreen.resume()`.
- [lib/screens/darts_score_screen.dart](lib/screens/darts_score_screen.dart) — `DartsScoreScreen`. Stateless; presets only (`301, 501, 701, 901`), no free-form input. Pushes `DartsGameScreen(players, startingScore)`.
- [lib/screens/darts_game_screen.dart](lib/screens/darts_game_screen.dart) — `DartsGameScreen` / `_DartsGameScreenState`. The scoring engine:
  - Two ways to construct: `DartsGameScreen(players, startingScore)` for a fresh game, or `DartsGameScreen.resume()` (empty players/startingScore, `resume: true`) which loads everything from prefs in `initState`.
  - Turn loop: `dartsThisTurn` (current turn, up to 3 darts) → each dart is `_Dart(value, multiplier)` where `value` ∈ `{0, 1..20, 25}` (0 = miss, 25 = bull) and `multiplier` ∈ `{1, 2, 3}` (triple disabled for miss/bull in the UI).
  - Bust rules (classic darts, enforced in `_throwDart`): a dart that would take the remaining score below 0, to exactly 1, or to exactly 0 *without* being a double (`multiplier == 2`) busts the turn — score reverts to `turnStartRemaining` and the turn ends immediately (remaining darts in that turn are not thrown). Reaching exactly 0 *with* a double wins the game.
  - `_finishTurn` is the single place a turn ends (bust, win, or 3 darts thrown normally) — it appends a `_TurnRecord` to `history` (most recent first), persists state, and shows a blocking `AlertDialog` for bust/win before advancing via `_nextTurn`.
  - Persistence: the *entire* game state (players, startingScore, remaining scores, current player, in-progress turn, full history, winner) is JSON-encoded into one `shared_preferences` key, `darts_game_state` (see `_prefsKey` at the top of the file) — namespaced separately from `GenericCounterScreen`'s `players`/`scores` keys to avoid collision. Saved after every dart throw and turn transition; cleared via `DartsGameScreen.clearSavedGame()` when the winner returns to the main menu.
  - History/stats: bottom sheet (history icon in the `AppBar`) shows all turns via `_buildHistoryList`. The winner screen (`_buildWinnerView`) aggregates `_PlayerStats` (turns, darts, points, average per dart) per player from `history` and shows them in a `DataTable`, plus the full history below.

### Adding a new game

1. Create a new screen (or set of screens) under `lib/screens/` for the game. Reuse the theme (see Theming above) instead of hardcoding colors. Wrap `Scaffold.body` in `SafeArea`.
2. If it persists data via `shared_preferences`, namespace its pref key(s) distinctly from `players`/`scores` (generic counter) and `darts_game_state` (darts) — e.g. a single JSON blob under one game-specific key, following the Dardos pattern, is easier to reason about than several parallel keys.
3. Add a `FilledButton.icon` for it in `MainMenuScreen` that pushes the new screen.

## App icon

`flutter_launcher_icons` is configured in [pubspec.yaml](pubspec.yaml) to generate platform icons from `assets/icon/icon.png` (with separate iOS/Android source images). Run `dart run flutter_launcher_icons` after changing icon assets.
