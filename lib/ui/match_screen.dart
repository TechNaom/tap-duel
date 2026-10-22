import 'package:flutter/material.dart';

import '../game/duel_game.dart';
import 'player_panel.dart';
import 'player_style.dart';

/// Split screen: Rohit on top (rotated to face the opposite player), Kohli at the bottom.
class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  var _game = DuelGame();

  Widget _panel(Player p) => PlayerPanel(
        style: PlayerStyle.of(p),
        score: _game.score(p),
        target: _game.target,
        danger: _game.danger(p),
        onTap: (at) {
          late TapOutcome outcome;
          setState(() => outcome = _game.tap(p, at));
          return outcome;
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: RotatedBox(quarterTurns: 2, child: _panel(Player.rohit))),
              const _VsBar(),
              Expanded(child: _panel(Player.kohli)),
            ],
          ),
          if (_game.isOver)
            _WinnerOverlay(
              style: PlayerStyle.of(_game.winner!),
              onRematch: () => setState(() => _game = DuelGame()),
            ),
        ],
      ),
    );
  }
}

class _VsBar extends StatelessWidget {
  const _VsBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A5BD6), Colors.black, Colors.black, Color(0xFFE0161E)],
          stops: [0, 0.35, 0.65, 1],
        ),
      ),
      alignment: Alignment.center,
      child: const Text(
        'VS',
        style: TextStyle(
          fontSize: 20,
          letterSpacing: 4,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: Color(0xFFF5C542),
        ),
      ),
    );
  }
}

class _WinnerOverlay extends StatelessWidget {
  const _WinnerOverlay({required this.style, required this.onRematch});
  final PlayerStyle style;
  final VoidCallback onRematch;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, t, child) => ColoredBox(
          color: Colors.black.withValues(alpha: 0.75 * t.clamp(0, 1)),
          child: Transform.scale(scale: t, child: child),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 72)),
            Text(
              '${style.name} WINS!',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                color: style.accent,
                shadows: [Shadow(color: style.primary, blurRadius: 24)],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: style.primary,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
              ),
              onPressed: onRematch,
              child: const Text('REMATCH',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 3)),
            ),
          ],
        ),
      ),
    );
  }
}
