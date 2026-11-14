part of 'minigames.dart';

// Two original mini-games for "Calling" step 6:
//
// - Fight night (fighters): three rounds. Each exchange your opponent shows
//   a tell — a jab, a hook or an opening — and you answer it: Guard a jab,
//   Slip a hook, Strike an opening. Strikes cost stamina, and a tired
//   strike lands soft. A knockout ends it early.
// - Docking (astronauts): the station's port drifts in your window as you
//   close in. Nudge left and right, brake (fuel is limited) and arrive
//   centred and slow.
//
// With Reduce motion (or a screen reader) both are turn-based: no timers,
// the same decisions.

enum _Tell { jab, hook, opening }

/// The skin's button, allowed to shrink so three fit side by side.
ButtonStyle _compact(MiniSkin skin) => skin.button().copyWith(
  minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
  padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
);

class _FightGame extends StatefulWidget {
  const _FightGame({required this.onDone, required this.ease});
  final void Function(double) onDone;
  final double ease;
  @override
  State<_FightGame> createState() => _FightGameState();
}

class _FightGameState extends State<_FightGame> with _Ticking {
  static const _rounds = 3, _perRound = 6;
  final _rng = Random();
  int _round = 1, _exchange = 0;
  double _me = 100, _them = 100, _stamina = 100;
  _Tell _tell = _Tell.jab;
  double _window = 1, _left = 1;
  bool _turnBased = false, _started = false, _resting = false;
  double? _score;
  String _line = 'Touch gloves.';
  String _flash = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.of(context);
    _turnBased = mq.disableAnimations || mq.accessibleNavigation;
    if (!_started) {
      _started = true;
      _next();
      if (!_turnBased) startTicking(_tick);
    }
  }

  void _next() {
    final r = _rng.nextInt(100);
    _tell = r < 35
        ? _Tell.opening
        : r < 70
        ? _Tell.jab
        : _Tell.hook;
    _window = (1.35 - _round * 0.18 + widget.ease * 0.4).clamp(0.55, 1.6);
    _left = _window;
  }

  void _tick(double dt) {
    if (_score != null || _resting) return;
    _left -= dt;
    if (_left <= 0) _answer(null);
  }

  /// Your answer to the tell (null: too slow).
  void _answer(_Tell? to) {
    if (_score != null || _resting) return;
    final hit = switch (_tell) {
      _Tell.jab => 9.0,
      _Tell.hook => 16.0,
      _Tell.opening => 0.0,
    };
    final strong = _stamina >= 20;
    switch ((_tell, to)) {
      case (_Tell.opening, _Tell.opening):
        final dmg = strong ? 16.0 + _rng.nextInt(6) : 7.0;
        _them -= dmg;
        _stamina = max(0, _stamina - 18);
        _flash = strong ? 'CLEAN!' : 'TIRED';
        _line = strong
            ? 'Straight down the middle.'
            : 'You landed, but there was nothing on it.';
        Sound.instance.hit();
      case (_Tell.opening, _):
        _flash = 'MISSED';
        _line = 'The opening closed before you took it.';
        Sound.instance.miss();
      case (_Tell.jab, _Tell.jab) || (_Tell.hook, _Tell.hook):
        _stamina = min(100, _stamina + 6);
        _flash = _tell == _Tell.jab ? 'BLOCKED' : 'SLIPPED';
        _line = 'Nothing landed. Breathe.';
        Sound.instance.hit();
      case (_, _Tell.opening):
        // Swinging into a punch: you both land, you come off worse.
        _me -= hit;
        _them -= 5;
        _stamina = max(0, _stamina - 18);
        _flash = 'COUNTERED';
        _line = 'You swung into it.';
        Sound.instance.miss();
      case (_Tell.hook, _Tell.jab):
        _me -= hit / 2;
        _flash = 'PARTLY';
        _line = 'The hook went round your guard.';
        Sound.instance.miss();
      default:
        _me -= hit;
        _flash = to == null ? 'TOO SLOW' : 'CAUGHT';
        _line = to == null ? 'You saw it too late.' : 'Wrong read.';
        Sound.instance.miss();
    }
    if (_me <= 0 || _them <= 0) {
      _end();
      return;
    }
    _exchange++;
    if (_exchange >= _perRound) {
      _exchange = 0;
      if (_round >= _rounds) {
        _end();
        return;
      }
      _round++;
      _resting = true;
      _stamina = min(100, _stamina + 35);
      _line = 'Bell. Back to your corner: water, a word, round $_round.';
    }
    _next();
  }

  void _end() {
    stopTicking();
    final ko = _them <= 0
        ? 'KNOCKOUT!'
        : _me <= 0
        ? 'Knocked down and out.'
        : null;
    final s = _them <= 0
        ? 1.0
        : _me <= 0
        ? 0.05
        : (0.5 + ((100 - _them) - (100 - _me)) / 120).clamp(0.0, 1.0);
    setState(() {
      _score = s;
      _line =
          ko ??
          (s >= 0.5
              ? 'Three rounds, and you landed more.'
              : 'Three rounds, and they landed more.');
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(score: _score!, line: _line, onDone: widget.onDone);
    }
    final skin = _skinOf(context);
    final tellWord = switch (_tell) {
      _Tell.jab => 'JAB',
      _Tell.hook => 'HOOK',
      _Tell.opening => 'OPENING!',
    };
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _progress(context, 'You', max(0, _me) / 100)),
            const SizedBox(width: 12),
            Expanded(
              child: _progress(
                context,
                'Opponent',
                max(0, _them) / 100,
                color: NF.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _progress(context, 'Stamina', _stamina / 100, color: skin.zone),
        const SizedBox(height: 8),
        Text(
          'Round $_round of $_rounds',
          style: NF.sora(13, weight: FontWeight.w700, color: NF.muted),
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            label: _resting ? _line : 'Your opponent shows a $tellWord. $_line',
            child: CustomPaint(
              painter: _RingPainter(
                tell: _resting ? null : _tell,
                flash: _flash,
                timeLeft: _turnBased ? 1 : (_left / _window).clamp(0, 1),
                accent: skin.accent,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 150),
                  child: Text(
                    _resting ? 'BETWEEN ROUNDS' : tellWord,
                    style: NF.stencil(
                      30,
                      color: _tell == _Tell.opening && !_resting
                          ? skin.zone
                          : NF.text,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Text(
          _line,
          textAlign: TextAlign.center,
          style: NF.sora(14, color: NF.soft),
        ),
        const SizedBox(height: 10),
        if (_resting)
          FilledButton(
            style: _compact(skin),
            onPressed: () => setState(() => _resting = false),
            child: Text('Round $_round'),
          )
        else
          Row(
            children: [
              for (final (label, t) in const [
                ('Guard', _Tell.jab),
                ('Slip', _Tell.hook),
                ('Strike', _Tell.opening),
              ]) ...[
                Expanded(
                  child: FilledButton(
                    style: _compact(skin),
                    onPressed: () => setState(() => _answer(t)),
                    child: FittedBox(child: Text(label)),
                  ),
                ),
                if (t != _Tell.opening) const SizedBox(width: 8),
              ],
            ],
          ),
      ],
    );
  }
}

/// The ring from your corner: ropes, the lights and your opponent showing
/// the tell (a jab arm, a wide hook arm, or a dropped guard).
class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.tell,
    required this.flash,
    required this.timeLeft,
    required this.accent,
  });
  final _Tell? tell;
  final String flash;
  final double timeLeft;
  final Color accent;

  @override
  void paint(Canvas c, Size s) {
    // Ring lights.
    c.drawCircle(
      Offset(s.width / 2, 0),
      s.width * 0.6,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.14),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(s.width / 2, 0),
                radius: s.width * 0.6,
              ),
            ),
    );
    // Ropes.
    for (var i = 0; i < 3; i++) {
      final y = s.height * (0.25 + i * 0.12);
      c.drawLine(
        Offset(0, y),
        Offset(s.width, y),
        Paint()
          ..color = (i == 1 ? Colors.white : const Color(0xFFFF5252))
              .withValues(alpha: 0.45)
          ..strokeWidth = 3,
      );
    }
    // The opponent.
    final body = Paint()..color = const Color(0xFF2A1A1A);
    final glove = Paint()..color = const Color(0xFFFF5252);
    final cx = s.width / 2, top = s.height * 0.14;
    c.drawCircle(Offset(cx, top + 22), 22, body);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, top + 92), width: 86, height: 100),
        const Radius.circular(26),
      ),
      body,
    );
    switch (tell) {
      case _Tell.jab:
        // Left glove coming straight at you.
        c.drawCircle(Offset(cx - 14, top + 70), 26, glove);
        c.drawCircle(Offset(cx + 30, top + 46), 15, glove);
      case _Tell.hook:
        c.drawCircle(Offset(cx - 70, top + 40), 18, glove);
        c.drawCircle(Offset(cx + 26, top + 44), 15, glove);
      case _Tell.opening:
        // Hands low: the chin is open.
        c.drawCircle(Offset(cx - 34, top + 120), 15, glove);
        c.drawCircle(Offset(cx + 34, top + 120), 15, glove);
        c.drawCircle(
          Offset(cx, top + 30),
          32,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = accent,
        );
      case null:
        c.drawCircle(Offset(cx - 22, top + 44), 15, glove);
        c.drawCircle(Offset(cx + 22, top + 44), 15, glove);
    }
    // Time to answer, as a shrinking bar under the opponent.
    final w = s.width * 0.6 * timeLeft;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, s.height * 0.62),
          width: w,
          height: 6,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = accent,
    );
    if (flash.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: flash,
          style: NF.stencil(18, color: accent),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(s.width - tp.width - 6, 6));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) =>
      o.tell != tell || o.flash != flash || o.timeLeft != timeLeft;
}

// ---------------- Docking ----------------

class _DockingGame extends StatefulWidget {
  const _DockingGame({required this.onDone, required this.ease});
  final void Function(double) onDone;
  final double ease;
  @override
  State<_DockingGame> createState() => _DockingGameState();
}

class _DockingGameState extends State<_DockingGame> with _Ticking {
  final _rng = Random();
  double _x = 0, _vx = 0, _dist = 60, _rate = 4.2;
  int _fuel = 12;
  bool _turnBased = false, _started = false;
  double? _score;
  String _line = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mq = MediaQuery.of(context);
    _turnBased = mq.disableAnimations || mq.accessibleNavigation;
    if (!_started) {
      _started = true;
      _x = (_rng.nextBool() ? 1 : -1) * (0.35 + _rng.nextDouble() * 0.3);
      if (!_turnBased) startTicking(_tick);
    }
  }

  double get _drift => 0.05 - widget.ease * 0.03;

  void _tick(double dt) => _step(dt);

  void _step(double dt) {
    if (_score != null) return;
    _vx += (_rng.nextDouble() - 0.5) * _drift * dt * 6;
    _x = (_x + _vx * dt).clamp(-1.4, 1.4);
    _dist -= _rate * dt;
    if (_dist <= 0) _dock();
  }

  void _thrust(int dir) {
    if (_score != null) return;
    _vx += dir * 0.09;
    Sound.instance.tick();
    if (_turnBased) _step(1.2);
  }

  void _brake() {
    if (_score != null || _fuel <= 0) return;
    _fuel--;
    _rate = max(0.4, _rate - 0.7);
    Sound.instance.tick();
    if (_turnBased) _step(1.2);
  }

  void _dock() {
    stopTicking();
    final align = (1 - _x.abs() / 0.6).clamp(0.0, 1.0);
    final speed = (1 - (_rate - 0.8) / 3).clamp(0.0, 1.0);
    final s = (align * 0.6 + speed * 0.4).clamp(0.0, 1.0);
    setState(() {
      _score = s;
      _line = s >= 0.8
          ? 'Soft capture. The latches closed with a sound you will remember.'
          : s >= 0.5
          ? 'Docked, a little hard. The station creaked about it.'
          : _x.abs() > 0.6
          ? 'You missed the port and bumped the hull.'
          : 'You came in far too fast.';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(score: _score!, line: _line, onDone: widget.onDone);
    }
    final skin = _skinOf(context);
    final side = _x.abs() < 0.08
        ? 'centred'
        : _x > 0
        ? 'port to your right'
        : 'port to your left';
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              'RANGE ${_dist.toStringAsFixed(1)} m',
              style: NF.stencil(15, color: NF.text),
            ),
            Text(
              'RATE ${_rate.toStringAsFixed(1)} m/s',
              style: NF.stencil(15, color: _rate > 2 ? NF.danger : skin.zone),
            ),
            Text('FUEL $_fuel', style: NF.stencil(15, color: NF.soft)),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Semantics(
            liveRegion: true,
            label:
                'Range ${_dist.round()} metres, closing at ${_rate.toStringAsFixed(1)}, $side.',
            child: CustomPaint(
              size: Size.infinite,
              painter: _PortPainter(_x, _dist, skin.zone, skin.accent),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                style: _compact(skin),
                onPressed: () => setState(() => _thrust(1)),
                child: const FittedBox(
                  child: Row(
                    children: [Icon(Icons.chevron_left_rounded), Text('Left')],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                style: _compact(skin),
                onPressed: _fuel > 0 ? () => setState(_brake) : null,
                child: const FittedBox(child: Text('Brake')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton(
                style: _compact(skin),
                onPressed: () => setState(() => _thrust(-1)),
                child: const FittedBox(
                  child: Row(
                    children: [
                      Text('Right'),
                      Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_turnBased) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _step(1.2)),
            child: const Text('Coast'),
          ),
        ],
      ],
    );
  }
}

/// The view through the docking window: stars, the port and its target
/// cross, growing as you close in, offset by your drift.
class _PortPainter extends CustomPainter {
  _PortPainter(this.x, this.dist, this.good, this.accent);
  final double x, dist;
  final Color good, accent;

  @override
  void paint(Canvas c, Size s) {
    final rnd = Random(4);
    for (var i = 0; i < 40; i++) {
      c.drawCircle(
        Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height),
        rnd.nextDouble() * 1.3,
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    }
    final centre = s.center(Offset.zero);
    // Your crosshair.
    final cross = Paint()
      ..color = accent
      ..strokeWidth = 2;
    c.drawLine(centre.translate(-16, 0), centre.translate(16, 0), cross);
    c.drawLine(centre.translate(0, -16), centre.translate(0, 16), cross);
    // The port, offset by drift (you move right: it slides left).
    final scale = (1 - dist / 70).clamp(0.12, 1.0);
    final port = centre.translate(-x * s.width * 0.45, 0);
    final r = 30 + 90 * scale;
    final ok = x.abs() < 0.15;
    c.drawCircle(port, r, Paint()..color = const Color(0xFF1B2236));
    c.drawCircle(
      port,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = ok ? good : Colors.white.withValues(alpha: 0.7),
    );
    c.drawCircle(
      port,
      r * 0.55,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: 0.4),
    );
    final t = Paint()
      ..color = ok ? good : Colors.white
      ..strokeWidth = 3;
    c.drawLine(port.translate(-r * 0.3, 0), port.translate(r * 0.3, 0), t);
    c.drawLine(port.translate(0, -r * 0.3), port.translate(0, r * 0.3), t);
  }

  @override
  bool shouldRepaint(_PortPainter o) => o.x != x || o.dist != dist;
}
