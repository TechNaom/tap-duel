# Tap Duel 🏏

A two-player tap race on one phone. **Kohli (red) vs Rohit (blue), first to 1000 wins.**

*By Manohar Papasani*

## Rules

- **Tap** your half of the screen: **+1**
- **Double tap** (two taps within ~200 ms): **−1**. The first tap's +1 is undone and −1 is applied.
- Tap fast, but not too fast. The rhythm meter turns orange, then red, when you get close to double-tap speed.
- Scores never go below 0. The first to 1000 wins.

## Run locally

```bash
flutter pub get
flutter test          # game rules
flutter run -d chrome # play in the browser
```

## Photos

Drop `kohli.png` and `rohit.png` into [`assets/players/`](assets/players/). Until they're there, a styled initial is shown.

## Structure

```
lib/game/duel_game.dart   pure rules (unit-tested)
lib/ui/match_screen.dart  split screen + winner overlay
lib/ui/player_panel.dart  one player's half: photo, score, effects
lib/ui/player_style.dart  colours, names, jersey numbers
```

Built with Flutter: one codebase for Android, iOS and web.
