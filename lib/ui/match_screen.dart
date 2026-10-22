import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/duel_game.dart';
import 'player_panel.dart';
import 'player_style.dart';
import 'sound_bank.dart';

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
        onFire: _game.onFire(p),
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

/// Shown to both players: the result faces each side, rematch sits in the middle.
class _WinnerOverlay extends StatefulWidget {
  const _WinnerOverlay({required this.style, required this.onRematch});
  final PlayerStyle style;
  final VoidCallback onRematch;

  @override
  State<_WinnerOverlay> createState() => _WinnerOverlayState();
}

class _WinnerOverlayState extends State<_WinnerOverlay> {
  final _confetti = ConfettiController(duration: const Duration(seconds: 3));
  // Ignore rematch taps for a moment so a last frantic tap doesn't skip the result.
  var _canRematch = false;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    SoundBank.instance.play('win');
    _confetti.play();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _canRematch = true);
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final result = _ResultText(style: style);
    return Positioned.fill(
      child: Stack(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, t, child) => ColoredBox(
              color: Colors.black.withValues(alpha: 0.78 * t.clamp(0, 1)),
              child: Transform.scale(scale: t, child: child),
            ),
            child: Column(
              children: [
                Expanded(child: RotatedBox(quarterTurns: 2, child: result)),
                AnimatedOpacity(
                  opacity: _canRematch ? 1 : 0.3,
                  duration: const Duration(milliseconds: 200),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: style.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                    ),
                    onPressed: _canRematch ? widget.onRematch : null,
                    child: const Text('REMATCH',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 3)),
                  ),
                ),
                Expanded(child: result),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.06,
              numberOfParticles: 20,
              gravity: 0.15,
              colors: [style.accent, style.primary, Colors.white, const Color(0xFFFF8A00)],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultText extends StatelessWidget {
  const _ResultText({required this.style});
  final PlayerStyle style;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🏆', style: TextStyle(fontSize: 64)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${style.name} WINS!',
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: style.accent,
              shadows: [Shadow(color: style.primary, blurRadius: 24)],
            ),
          ),
        ),
      ],
    );
  }
}
