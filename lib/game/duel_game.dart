import 'dart:math';

/// Pure game rules for Tap Duel. No Flutter imports, so it is easy to unit-test.
enum Player { kohli, rohit }

/// What a single tap did to the tapping player's score.
class TapOutcome {
  const TapOutcome({
    required this.delta,
    required this.isDoubleTap,
    required this.wonGame,
    this.milestone,
  });

  static const ignored = TapOutcome(delta: 0, isDoubleTap: false, wonGame: false);

  final int delta;
  final bool isDoubleTap;
  final bool wonGame;

  /// Set when this tap reached a quarter mark (250, 500, 750) for the first time.
  final int? milestone;
}

/// Rhythm rules:
/// - a tap gives +1 instantly (no waiting to see if a second tap follows)
/// - a second tap inside [doubleTapWindow] turns the pair into a double tap:
///   the first tap's +1 is undone and −1 is applied, so the pair nets −1
/// - scores never drop below 0; first to [target] wins
/// - [fireStreak] fast single taps in a row (each within [streakGap]) puts a player "on fire"
class DuelGame {
  DuelGame({
    this.target = 1000,
    this.doubleTapWindow = const Duration(milliseconds: 200),
    this.streakGap = const Duration(milliseconds: 400),
    this.fireStreak = 15,
  });

  final int target;
  final Duration doubleTapWindow;
  final Duration streakGap;
  final int fireStreak;

  final Map<Player, int> _scores = {for (final p in Player.values) p: 0};
  final Map<Player, Duration> _lastTapAt = {};
  final Map<Player, Duration> _lastInterval = {};
  // Players whose last tap was a single tap that a second tap could still pair with.
  final Set<Player> _canPair = {};
  final Map<Player, int> _streak = {for (final p in Player.values) p: 0};
  final Map<Player, Set<int>> _milestonesHit = {for (final p in Player.values) p: {}};
  Player? _winner;

  int score(Player p) => _scores[p]!;
  Player? get winner => _winner;
  bool get isOver => _winner != null;
  double progress(Player p) => score(p) / target;
  int streak(Player p) => _streak[p]!;
  bool onFire(Player p) => streak(p) >= fireStreak;

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
      _streak[p] = 0;
    } else {
      after = min(target, before + 1);
      _canPair.add(p);
      final fast = interval != null && interval <= streakGap;
      _streak[p] = fast ? streak(p) + 1 : 1;
    }
    _scores[p] = after;

    int? milestone;
    final quarter = target ~/ 4;
    if (quarter > 0 && after > before && after % quarter == 0 && after < target &&
        _milestonesHit[p]!.add(after)) {
      milestone = after;
    }

    final won = after >= target;
    if (won) _winner = p;
    return TapOutcome(
      delta: after - before,
      isDoubleTap: isDouble,
      wonGame: won,
      milestone: milestone,
    );
  }
}
