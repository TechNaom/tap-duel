import 'dart:math';

/// Pure game rules for Tap Duel. No Flutter imports, so it is easy to unit-test.
enum Player { kohli, rohit }

/// What a single tap did to the tapping player's score.
class TapOutcome {
  const TapOutcome({
    required this.delta,
    required this.isDoubleTap,
    required this.wonGame,
  });

  static const ignored = TapOutcome(delta: 0, isDoubleTap: false, wonGame: false);

  final int delta;
  final bool isDoubleTap;
  final bool wonGame;
}

/// Rhythm rules:
/// - a tap gives +1 instantly (no waiting to see if a second tap follows)
/// - a second tap inside [doubleTapWindow] turns the pair into a double tap:
///   the first tap's +1 is undone and −1 is applied, so the pair nets −1
/// - scores never drop below 0; first to [target] wins
class DuelGame {
  DuelGame({
    this.target = 1000,
    this.doubleTapWindow = const Duration(milliseconds: 200),
  });

  final int target;
  final Duration doubleTapWindow;

  final Map<Player, int> _scores = {for (final p in Player.values) p: 0};
  final Map<Player, Duration> _lastTapAt = {};
  final Map<Player, Duration> _lastInterval = {};
  // Players whose last tap was a single tap that a second tap could still pair with.
  final Set<Player> _canPair = {};
  Player? _winner;

  int score(Player p) => _scores[p]!;
  Player? get winner => _winner;
  bool get isOver => _winner != null;
  double progress(Player p) => score(p) / target;

  /// How close the player's tapping rhythm is to the double-tap window:
  /// 0.0 = relaxed, 1.0 = last two taps were a double tap.
  double danger(Player p) {
    final interval = _lastInterval[p];
    if (interval == null) return 0;
    final window = doubleTapWindow.inMicroseconds;
    final safe = window * 2.5;
    final i = interval.inMicroseconds;
    if (i <= window) return 1;
    if (i >= safe) return 0;
    return 1 - (i - window) / (safe - window);
  }

  /// [at] is the tap's timestamp (e.g. a pointer event's timeStamp).
  TapOutcome tap(Player p, Duration at) {
    if (isOver) return TapOutcome.ignored;

    final last = _lastTapAt[p];
    final interval = last == null ? null : at - last;
    _lastTapAt[p] = at;
    if (interval != null) _lastInterval[p] = interval;

    final isDouble =
        interval != null && interval <= doubleTapWindow && _canPair.contains(p);

    final before = score(p);
    final int after;
    if (isDouble) {
      after = max(0, before - 2);
      _canPair.remove(p);
    } else {
      after = min(target, before + 1);
      _canPair.add(p);
    }
    _scores[p] = after;

    final won = after >= target;
    if (won) _winner = p;
    return TapOutcome(delta: after - before, isDoubleTap: isDouble, wonGame: won);
  }
}
