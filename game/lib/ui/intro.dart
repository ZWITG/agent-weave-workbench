import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// The opening: the ZWITG mark (letters settle in, the red line draws
/// across), then the Relivable logo, then a fade into the game. Plays when
/// the game starts and when it is opened again after a while away. A tap
/// skips it; "reduce motion" makes it short and still.
class IntroSplash extends StatefulWidget {
  const IntroSplash({
    super.key,
    required this.onDone,
    this.reduceMotion = false,
  });

  final VoidCallback onDone;
  final bool reduceMotion;

  /// Tests turn the intro off so screens are reachable straight away.
  static bool enabled = true;

  @override
  State<IntroSplash> createState() => _IntroSplashState();
}

class _IntroSplashState extends State<IntroSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.reduceMotion ? 1800 : 3600),
  );
  bool _finished = false;

  static const _ink = Color(0xFF080808);
  static const _cream = Color(0xFFECE7E1);
  static const _red = Color(0xFFC8282E);
  static const _rule = Color(0xFF5A5A5A);

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    });
    _c.forward();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// 0..1 progress of [t] through the window [a]..[b], eased.
  double _span(double t, double a, double b, [Curve curve = Curves.easeOut]) =>
      curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    // Above the app's pages there is no Material yet: give the text its
    // proper style (no debug underlines).
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            // Timeline (fractions of the whole):
            // 0.00-0.45 ZWITG in and hold, 0.42-0.52 ZWITG out,
            // 0.50-0.85 Relivable in and hold, 0.86-1.00 fade to the game.
            final zIn = _span(t, 0.0, 0.18);
            final zLine = _span(t, 0.14, 0.32, Curves.easeInOutCubic);
            final zOut = _span(t, 0.42, 0.52, Curves.easeIn);
            final rIn = _span(t, 0.50, 0.64, Curves.easeOutBack);
            final dot = _span(t, 0.60, 0.70, Curves.elasticOut);
            final word = _span(t, 0.62, 0.74);
            final out = _span(t, 0.86, 1.0, Curves.easeIn);
            final bg = Color.lerp(_ink, NF.bg, _span(t, 0.46, 0.58))!;
            return Opacity(
              opacity: 1 - out,
              child: ColoredBox(
                color: bg,
                child: SizedBox.expand(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (zOut < 1)
                        Opacity(
                          opacity: (1 - zOut) * min(1.0, zIn * 1.4),
                          child: _zwitg(zIn, zLine),
                        ),
                      if (rIn > 0)
                        Opacity(
                          opacity: rIn.clamp(0.0, 1.0),
                          child: _relivable(rIn, dot, word),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _zwitg(double letters, double line) => LayoutBuilder(
    builder: (context, box) {
      final w = min(box.maxWidth * 0.78, 520.0);
      final size = w / 6.3;
      return SizedBox(
        width: w * 1.08,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // The thin grey rule on the left.
            Container(
              width: 2,
              height: size * 1.9 * letters,
              color: _rule.withValues(alpha: letters),
            ),
            SizedBox(width: w * 0.08),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wide letters that settle from further apart.
                  Transform.translate(
                    offset: Offset(0, (1 - letters) * size * 0.25),
                    // The letters are drawn 25% wider than the font (the
                    // extended look), so they are fitted into 1/1.25 of
                    // the room first and never run off the edge.
                    child: LayoutBuilder(
                      builder: (context, box) => Transform(
                        alignment: Alignment.centerLeft,
                        transform: Matrix4.diagonal3Values(1.25, 1, 1),
                        child: SizedBox(
                          width: box.maxWidth / 1.25,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'ZWITG',
                              style: NF
                                  .sora(
                                    size,
                                    weight: FontWeight.w700,
                                    color: _cream,
                                  )
                                  .copyWith(
                                    letterSpacing:
                                        size * (0.32 + (1 - letters) * 0.35),
                                    height: 1,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size * 0.55),
                  // The red line draws across.
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: line,
                      child: Container(
                        height: max(3, size * 0.07),
                        color: _red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  Widget _relivable(double pop, double dot, double word) {
    final side = 104.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: 0.6 + 0.4 * pop,
          child: SizedBox(
            width: side + 16,
            height: side + 16,
            child: Stack(
              children: [
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    width: side,
                    height: side,
                    decoration: BoxDecoration(
                      color: NF.blue,
                      borderRadius: BorderRadius.circular(side * 0.26),
                      boxShadow: [
                        BoxShadow(
                          color: NF.blue.withValues(
                            alpha: 0.35 * pop.clamp(0, 1),
                          ),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'R',
                      style: NF.sora(
                        side * 0.56,
                        weight: FontWeight.w800,
                        color: NF.bg,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Transform.scale(
                    scale: dot,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: const BoxDecoration(
                        color: NF.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Opacity(
          opacity: word,
          child: Transform.translate(
            offset: Offset(0, (1 - word) * 10),
            child: Text(
              'Relivable',
              style: NF
                  .sora(30, weight: FontWeight.w700, color: NF.text)
                  .copyWith(letterSpacing: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}

/// Puts the intro over the game when it starts, and again when the game
/// is opened after being away for a while.
class IntroGate extends StatefulWidget {
  const IntroGate({super.key, required this.child, this.reduceMotion = false});

  final Widget child;
  final bool reduceMotion;

  /// How long the game must be in the background before the intro plays
  /// again on return (switching apps for a moment does not replay it).
  static const awayBeforeReplay = Duration(seconds: 30);

  @override
  State<IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<IntroGate> with WidgetsBindingObserver {
  bool _showing = IntroSplash.enabled;
  int _run = 0;
  DateTime? _leftAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _leftAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final left = _leftAt;
      _leftAt = null;
      if (IntroSplash.enabled &&
          left != null &&
          DateTime.now().difference(left) >= IntroGate.awayBeforeReplay) {
        setState(() {
          _showing = true;
          _run++;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      widget.child,
      if (_showing)
        Positioned.fill(
          child: IntroSplash(
            key: ValueKey(_run),
            reduceMotion: widget.reduceMotion,
            onDone: () => setState(() => _showing = false),
          ),
        ),
    ],
  );
}
