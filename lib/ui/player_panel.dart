import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';

import '../game/duel_game.dart';
import 'player_style.dart';
import 'sound_bank.dart';

/// One half of the screen: photo, score, progress and tap effects.
class PlayerPanel extends StatefulWidget {
  const PlayerPanel({
    super.key,
    required this.style,
    required this.score,
    required this.target,
    required this.danger,
    required this.onFire,
    required this.onTap,
  });

  final PlayerStyle style;
  final int score;
  final int target;
  final double danger;
  final bool onFire;
  final TapOutcome Function(Duration at) onTap;

  @override
  State<PlayerPanel> createState() => _PlayerPanelState();
}

class _FloatingLabel {
  _FloatingLabel(this.id, this.text, this.color, this.dx);
  final int id;
  final String text;
  final Color color;
  final double dx;
}

class _PlayerPanelState extends State<PlayerPanel> with TickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
  late final _flash = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  late final _fireGlow = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
    ..repeat(reverse: true);
  final _burst = ConfettiController(duration: const Duration(milliseconds: 400));
  int? _milestone;
  var _milestoneId = 0;
  final _labels = <_FloatingLabel>[];
  final _random = Random();
  var _nextId = 0;
  var _hot = false;
  Timer? _coolDown;

  @override
  void dispose() {
    _pulse.dispose();
    _flash.dispose();
    _fireGlow.dispose();
    _burst.dispose();
    _coolDown?.cancel();
    super.dispose();
  }

  void _handleDown(PointerDownEvent e) {
    final outcome = widget.onTap(e.timeStamp);
    if (outcome.delta == 0 && !outcome.isDoubleTap) return;

    final sounds = SoundBank.instance;
    if (outcome.isDoubleTap) {
      HapticFeedback.heavyImpact();
      sounds.play('minus');
      _flash.forward(from: 0);
    } else {
      HapticFeedback.lightImpact();
      sounds.play(widget.style == PlayerStyle.kohli ? 'tap_red' : 'tap_blue', volume: 0.6);
      _pulse.forward(from: 0).then((_) => _pulse.reverse());
    }
    if (outcome.milestone != null) {
      HapticFeedback.mediumImpact();
      sounds.play('milestone');
      _burst.play();
      setState(() {
        _milestone = outcome.milestone;
        _milestoneId++;
      });
    }

    setState(() {
      _labels.add(_FloatingLabel(
        _nextId++,
        outcome.isDoubleTap ? '-1' : '+1',
        outcome.isDoubleTap ? const Color(0xFFFF4D4D) : widget.style.accent,
        _random.nextDouble() * 1.4 - 0.7,
      ));
      if (_labels.length > 14) _labels.removeAt(0);
      _hot = true;
    });
    _coolDown?.cancel();
    _coolDown = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _hot = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.style;
    final onFire = _hot && widget.onFire;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handleDown,
      child: AnimatedBuilder(
        animation: _flash,
        builder: (context, child) {
          final t = _flash.value;
          final shake = t == 0 ? 0.0 : sin(t * pi * 8) * 10 * (1 - t);
          return Transform.translate(offset: Offset(shake, 0), child: child);
        },
        child: LayoutBuilder(builder: (context, box) {
          final photoSize = min(box.maxHeight * 0.42, box.maxWidth * 0.48);
          return Stack(
            fit: StackFit.expand,
            children: [
              _Background(style: s),
              _JerseyWatermark(style: s, height: box.maxHeight),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          ScaleTransition(
                            scale: Tween(begin: 1.0, end: 1.08)
                                .animate(CurvedAnimation(parent: _pulse, curve: Curves.easeOut)),
                            child: _Photo(style: s, size: photoSize, onFire: onFire),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _ScoreBlock(style: s, score: widget.score, onFire: onFire),
                          ),
                        ],
                      ),
                    ),
                    _ProgressBar(style: s, score: widget.score, target: widget.target),
                    const SizedBox(height: 10),
                    _RhythmMeter(danger: _hot ? widget.danger : 0),
                  ],
                ),
              ),
              if (onFire) _FireBorder(glow: _fireGlow),
              if (_milestone != null)
                _MilestoneBanner(
                  key: ValueKey(_milestoneId),
                  value: _milestone!,
                  style: s,
                  onDone: () => setState(() => _milestone = null),
                ),
              Align(
                alignment: Alignment.center,
                child: ConfettiWidget(
                  confettiController: _burst,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 25,
                  maxBlastForce: 30,
                  minBlastForce: 10,
                  gravity: 0.3,
                  colors: [s.accent, Colors.white, s.primary],
                ),
              ),
              for (final label in _labels)
                _FloatingText(
                  key: ValueKey(label.id),
                  label: label,
                  onDone: () => setState(() => _labels.remove(label)),
                ),
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _flash,
                  builder: (context, _) => ColoredBox(
                    color: const Color(0xFFFF1A1A)
                        .withValues(alpha: _flash.value == 0 ? 0 : 0.45 * (1 - _flash.value)),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background({required this.style});
  final PlayerStyle style;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.6, -0.2),
          radius: 1.3,
          colors: [style.primary, style.deep],
        ),
      ),
    );
  }
}

class _JerseyWatermark extends StatelessWidget {
  const _JerseyWatermark({required this.style, required this.height});
  final PlayerStyle style;
  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(1.1, 0),
        child: Text(
          style.jersey,
          style: TextStyle(
            fontSize: height * 0.75,
            height: 1,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.style, required this.size, required this.onFire});
  final PlayerStyle style;
  final double size;
  final bool onFire;

  @override
  Widget build(BuildContext context) {
    const fire = Color(0xFFFF8A00);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: onFire ? fire : style.accent, width: onFire ? 6 : 4),
        boxShadow: [
          BoxShadow(
            color: onFire ? fire : style.primary.withValues(alpha: 0.8),
            blurRadius: onFire ? 50 : 30,
            spreadRadius: onFire ? 8 : 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          style.photo,
          fit: BoxFit.cover,
          // Placeholder until real photos are dropped into assets/players/.
          errorBuilder: (context, error, stack) => ColoredBox(
            color: style.deep,
            child: Center(
              child: Text(
                style.name[0],
                style: TextStyle(
                  fontSize: size * 0.5,
                  fontWeight: FontWeight.w900,
                  color: style.accent,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreBlock extends StatelessWidget {
  const _ScoreBlock({required this.style, required this.score, required this.onFire});
  final PlayerStyle style;
  final int score;
  final bool onFire;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          style.name,
          style: TextStyle(
            fontSize: 22,
            letterSpacing: 6,
            fontWeight: FontWeight.w800,
            color: style.accent,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            '$score',
            style: const TextStyle(
              fontSize: 84,
              height: 1,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
              shadows: [Shadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4))],
            ),
          ),
        ),
        AnimatedOpacity(
          opacity: onFire ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: const Text(
            '🔥 ON FIRE',
            style: TextStyle(
              fontSize: 16,
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFB300),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.style, required this.score, required this.target});
  final PlayerStyle style;
  final int score;
  final int target;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$score / $target',
          style: TextStyle(fontSize: 12, letterSpacing: 2, color: Colors.white.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 14,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (score / target).clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [style.accent, Colors.white]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Green → orange → red as the tapping rhythm approaches double-tap speed.
class _RhythmMeter extends StatelessWidget {
  const _RhythmMeter({required this.danger});
  final double danger;

  @override
  Widget build(BuildContext context) {
    final color = Color.lerp(
      Color.lerp(const Color(0xFF3DDC84), const Color(0xFFFFA726), (danger * 2).clamp(0, 1)),
      const Color(0xFFFF3B3B),
      ((danger - 0.5) * 2).clamp(0, 1),
    )!;
    final label = danger >= 1
        ? 'TOO FAST!'
        : danger > 0.5
            ? 'CAREFUL'
            : 'RHYTHM';
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: TextStyle(fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.w700, color: color),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: danger),
              duration: const Duration(milliseconds: 150),
              builder: (context, v, _) => LinearProgressIndicator(
                value: max(v, 0.04),
                minHeight: 6,
                color: color,
                backgroundColor: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FloatingText extends StatelessWidget {
  const _FloatingText({super.key, required this.label, required this.onDone});
  final _FloatingLabel label;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        onEnd: onDone,
        builder: (context, t, child) => Align(
          alignment: Alignment(label.dx * 0.6 + 0.3, 0.1 - t * 0.9),
          child: Opacity(
            opacity: 1 - t,
            child: Transform.scale(scale: 1 + t * 0.4, child: child),
          ),
        ),
        child: Text(
          label.text,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w900,
            color: label.color,
            shadows: const [Shadow(color: Colors.black87, blurRadius: 8)],
          ),
        ),
      ),
    );
  }
}

class _FireBorder extends StatelessWidget {
  const _FireBorder({required this.glow});
  final Animation<double> glow;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: glow,
        builder: (context, _) => DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Color.lerp(const Color(0xFFFF5500), const Color(0xFFFFC400), glow.value)!,
              width: 4 + glow.value * 3,
            ),
          ),
        ),
      ),
    );
  }
}

/// Big "250!" that pops in and fades out when a quarter mark is reached.
class _MilestoneBanner extends StatelessWidget {
  const _MilestoneBanner({super.key, required this.value, required this.style, required this.onDone});
  final int value;
  final PlayerStyle style;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1200),
        onEnd: onDone,
        builder: (context, t, child) {
          final scale = t < 0.25 ? Curves.easeOutBack.transform(t / 0.25) : 1.0;
          final opacity = t < 0.7 ? 1.0 : 1 - (t - 0.7) / 0.3;
          return Center(
            child: Opacity(opacity: opacity, child: Transform.scale(scale: scale * 1.2, child: child)),
          );
        },
        child: Text(
          '$value!',
          style: TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: style.accent,
            shadows: [
              Shadow(color: style.deep, offset: const Offset(4, 4)),
              const Shadow(color: Colors.black, blurRadius: 24),
            ],
          ),
        ),
      ),
    );
  }
}
