part of 'minigames.dart';

// More mini-games, so activities rotate between different kinds of play.
// Each one finishes through _Done with a score from 0 to 1.

const _good = Color(0xFF5EE6A8);

/// A repeating game clock, cancelled with the widget.
mixin _Ticking<T extends StatefulWidget> on State<T> {
  static const _step = Duration(milliseconds: 33);
  Timer? _clock;
  double _elapsed = 0;

  /// Calls [tick] about 30 times a second with the seconds since the last
  /// call. Time is counted in ticks, so tests can run it on a fake clock.
  void startTicking(void Function(double seconds) tick) {
    _clock = Timer.periodic(_step, (_) {
      if (!mounted) return;
      const dt = 0.033;
      _elapsed += dt;
      setState(() => tick(dt));
    });
  }

  void stopTicking() => _clock?.cancel();

  double get elapsed => _elapsed;

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }
}

Widget _progress(String label, double v, {Color color = _good}) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    Text(label, style: NF.sora(14, color: NF.muted)),
    const SizedBox(height: 6),
    ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: v.clamp(0.0, 1.0),
        minHeight: 12,
        backgroundColor: NF.surface2,
        color: color,
      ),
    ),
  ],
);

// ---------------- Sneak: move only while the guard looks away ----------------

class _SneakGame extends StatefulWidget {
  const _SneakGame({
    required this.onDone,
    required this.button,
    required this.ease,
  });
  final void Function(double) onDone;
  final String button;
  final double ease;
  @override
  State<_SneakGame> createState() => _SneakGameState();
}

class _SneakGameState extends State<_SneakGame> with _Ticking {
  final _rng = Random();
  double _pos = 0;
  bool _holding = false;
  bool _watching = false;
  double _turnIn = 1.5;
  double _seen = 0;
  double? _score;
  String _line = '';

  @override
  void initState() {
    super.initState();
    startTicking(_tick);
  }

  void _tick(double dt) {
    if (_score != null) return;
    _turnIn -= dt;
    if (_turnIn <= 0) {
      _watching = !_watching;
      _turnIn = _watching
          ? 0.8 + _rng.nextDouble() * 1.2
          : 0.6 + _rng.nextDouble() * (1.6 + widget.ease);
    }
    if (_holding) {
      _pos += dt * 0.28;
      // A short grace period after the guard turns round.
      if (_watching) _seen += dt;
    }
    if (_seen > 0.25 + widget.ease * 0.15) {
      _end(_pos * 0.4, 'The guard saw you move.');
    } else if (_pos >= 1) {
      _end((1.6 - elapsed / 12).clamp(0.6, 1.0), 'Clean. Nobody saw a thing.');
    }
  }

  void _end(double s, String line) {
    stopTicking();
    _score = s.clamp(0.0, 1.0);
    _line = line;
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(score: _score!, line: _line, onDone: widget.onDone);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 150,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _watching
                ? NF.danger.withValues(alpha: 0.35)
                : _good.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _watching
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                size: 56,
              ),
              const SizedBox(height: 6),
              Text(
                _watching ? 'Watching!' : 'Looking away',
                style: NF.sora(22, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _progress('How close you are', _pos),
        const SizedBox(height: 28),
        Listener(
          onPointerDown: (_) => setState(() => _holding = true),
          onPointerUp: (_) => setState(() => _holding = false),
          onPointerCancel: (_) => setState(() => _holding = false),
          child: Container(
            height: 90,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _holding ? NF.orange : NF.surface2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Hold to ${widget.button.toLowerCase()}',
              style: NF.sora(20, weight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- Balance: keep the marker in the middle ----------------

class _BalanceGame extends StatefulWidget {
  const _BalanceGame({required this.onDone, required this.ease});
  final void Function(double) onDone;
  final double ease;
  @override
  State<_BalanceGame> createState() => _BalanceGameState();
}

class _BalanceGameState extends State<_BalanceGame> with _Ticking {
  final _rng = Random();
  double _x = 0, _v = 0, _push = 0, _inside = 0, _total = 0;
  static const _length = 8.0;
  double? _score;

  @override
  void initState() {
    super.initState();
    startTicking(_tick);
  }

  void _tick(double dt) {
    if (_score != null) return;
    // Gusts get stronger as the pose goes on.
    final gust = (_rng.nextDouble() - 0.5) * (1.2 + elapsed * 0.25);
    _v += (gust + _push + _x * 0.6) * dt;
    _v *= 0.97;
    _x = (_x + _v * dt).clamp(-1.0, 1.0);
    if (_x.abs() == 1) _v = 0;
    _push = 0;
    _total += dt;
    if (_x.abs() < 0.3 + widget.ease * 0.1) _inside += dt;
    if (elapsed >= _length) {
      stopTicking();
      _score = (_inside / _total * 1.15).clamp(0.0, 1.0);
    }
  }

  void _nudge(double d) => _push = d * 22;

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(
        score: _score!,
        line: 'Steady for ${(_inside).toStringAsFixed(1)} of 8 seconds',
        onDone: widget.onDone,
      );
    }
    final zone = 0.3 + widget.ease * 0.1;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _progress('Hold it…', elapsed / _length, color: NF.orange),
        const SizedBox(height: 30),
        LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return SizedBox(
              height: 70,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: NF.surface2,
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  Positioned(
                    left: w * (0.5 - zone / 2),
                    width: w * zone,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _good.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (w - 24) * (_x + 1) / 2,
                    top: 10,
                    bottom: 10,
                    width: 24,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: NF.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                style: primaryButton(),
                onPressed: () => _nudge(-1),
                child: const Icon(Icons.chevron_left_rounded, size: 36),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                style: primaryButton(),
                onPressed: () => _nudge(1),
                child: const Icon(Icons.chevron_right_rounded, size: 36),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------- Breathe: hold, release at the ring ----------------

class _BreathGame extends StatefulWidget {
  const _BreathGame({required this.onDone, required this.ease});
  final void Function(double) onDone;
  final double ease;
  @override
  State<_BreathGame> createState() => _BreathGameState();
}

class _BreathGameState extends State<_BreathGame> with _Ticking {
  final _rng = Random();
  late double _target = _newTarget();
  double _r = 0.15;
  bool _holding = false;
  int _round = 0;
  final _scores = <double>[];
  String _msg = 'Hold to breathe in';

  double _newTarget() => 0.5 + _rng.nextDouble() * 0.4;

  @override
  void initState() {
    super.initState();
    startTicking(_tick);
  }

  void _tick(double dt) {
    if (_holding) {
      _r += dt * (0.22 + _round * 0.05);
      if (_r >= 1) _release();
    } else if (_r > 0.15) {
      _r = max(0.15, _r - dt * 0.6);
    }
  }

  void _release() {
    if (!_holding) return;
    _holding = false;
    final miss = (_r - _target).abs();
    final s = (1 - miss / (0.18 + widget.ease * 0.06)).clamp(0.0, 1.0);
    _scores.add(s);
    _msg = s > 0.8
        ? 'Perfect breath.'
        : s > 0.4
        ? 'Close.'
        : (_r > _target ? 'Too long.' : 'Too short.');
    _round++;
    _target = _newTarget();
    if (_round >= 3) stopTicking();
  }

  @override
  Widget build(BuildContext context) {
    if (_round >= 3) {
      final s = _scores.reduce((a, b) => a + b) / 3;
      return _Done(score: s, line: 'Three slow breaths', onDone: widget.onDone);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Breath ${_round + 1} of 3 · $_msg',
          style: NF.sora(15, color: NF.soft),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 260 * _target,
                height: 260 * _target,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _good, width: 4),
                ),
              ),
              Container(
                width: 260 * _r,
                height: 260 * _r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NF.blue.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Listener(
          onPointerDown: (_) => setState(() => _holding = true),
          onPointerUp: (_) => setState(_release),
          onPointerCancel: (_) => setState(_release),
          child: Container(
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _holding ? NF.blue : NF.surface2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _holding ? 'Let go at the ring' : 'Hold to breathe in',
              style: NF.sora(18, weight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- Blackjack ----------------

class _BlackjackGame extends StatefulWidget {
  const _BlackjackGame({required this.onDone});
  final void Function(double) onDone;
  @override
  State<_BlackjackGame> createState() => _BlackjackGameState();
}

class _BlackjackGameState extends State<_BlackjackGame> {
  final _rng = Random();
  List<int> _you = [], _dealer = [];
  int _hand = 0;
  double _points = 0;
  String _msg = '';
  bool _over = false;

  @override
  void initState() {
    super.initState();
    _deal();
  }

  int _card() => min(10, 1 + _rng.nextInt(13));

  static int total(List<int> h) {
    var t = h.fold(0, (a, b) => a + b);
    if (h.contains(1) && t + 10 <= 21) t += 10;
    return t;
  }

  void _deal() {
    _you = [_card(), _card()];
    _dealer = [_card()];
    _over = false;
    if (total(_you) == 21) _settle();
  }

  void _hit() => setState(() {
    _you.add(_card());
    if (total(_you) > 21) _settle();
  });

  void _stand() => setState(_settle);

  void _settle() {
    while (total(_dealer) < 17 && total(_you) <= 21) {
      _dealer.add(_card());
    }
    final y = total(_you), d = total(_dealer);
    if (y > 21) {
      _msg = 'Bust with $y.';
    } else if (d > 21 || y > d) {
      _points += 1;
      _msg = y == 21 && _you.length == 2
          ? 'Blackjack!'
          : 'You win, $y against $d.';
    } else if (y == d) {
      _points += 0.5;
      _msg = 'Push, $y each.';
    } else {
      _msg = 'Dealer wins, $d against $y.';
    }
    _over = true;
  }

  void _next() => setState(() {
    _hand++;
    _msg = '';
    if (_hand < 3) _deal();
  });

  Widget _cards(String who, List<int> h) => Column(
    children: [
      Text('$who · ${total(h)}', style: NF.sora(14, color: NF.muted)),
      const SizedBox(height: 6),
      Wrap(
        spacing: 6,
        children: [
          for (final c in h)
            Container(
              width: 48,
              height: 68,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3EC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                c == 1 ? 'A' : '$c',
                style: NF.sora(
                  22,
                  weight: FontWeight.w700,
                  color: const Color(0xFF16213A),
                ),
              ),
            ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (_hand >= 3) {
      return _Done(
        score: _points / 3,
        line:
            '${_points == _points.roundToDouble() ? _points.round() : _points} of 3 hands won',
        onDone: widget.onDone,
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Hand ${_hand + 1} of 3', style: NF.sora(14, color: NF.muted)),
        const SizedBox(height: 14),
        _cards('Dealer', _dealer),
        const SizedBox(height: 18),
        _cards('You', _you),
        const SizedBox(height: 14),
        Text(_msg, style: NF.sora(16, color: NF.soft)),
        const SizedBox(height: 16),
        if (_over)
          FilledButton(
            style: primaryButton(),
            onPressed: _next,
            child: Text(_hand == 2 ? 'See result' : 'Next hand'),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                style: orangeButton(),
                onPressed: _hit,
                child: const Text('Hit'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                style: primaryButton(),
                onPressed: _stand,
                child: const Text('Stand'),
              ),
            ],
          ),
      ],
    );
  }
}

// ---------------- Lanes: dodge what comes at you ----------------

class _LanesGame extends StatefulWidget {
  const _LanesGame({
    required this.onDone,
    required this.ease,
    required this.hazard,
  });
  final void Function(double) onDone;
  final double ease;

  /// What comes down the lanes (cones, asteroids...).
  final IconData hazard;
  @override
  State<_LanesGame> createState() => _LanesGameState();
}

class _LanesGameState extends State<_LanesGame> with _Ticking {
  final _rng = Random();
  int _lane = 1;
  final _things = <(int, double)>[];
  double _spawn = 0.6;
  int _hits = 0;
  static const _length = 12.0;
  double? _score;

  @override
  void initState() {
    super.initState();
    startTicking(_tick);
  }

  void _tick(double dt) {
    if (_score != null) return;
    final speed = 0.45 + elapsed * 0.05 - widget.ease * 0.1;
    for (var i = 0; i < _things.length; i++) {
      _things[i] = (_things[i].$1, _things[i].$2 + speed * dt);
    }
    _things.removeWhere((t) {
      if (t.$2 >= 0.86 && t.$2 < 0.96 && t.$1 == _lane) {
        _hits++;
        return true;
      }
      return t.$2 > 1.05;
    });
    _spawn -= dt;
    if (_spawn <= 0) {
      _things.add((_rng.nextInt(3), -0.1));
      _spawn = max(0.45, 1.1 - elapsed * 0.05) + _rng.nextDouble() * 0.3;
    }
    if (_hits >= 3 || elapsed >= _length) {
      stopTicking();
      _score = _hits >= 3 ? elapsed / _length * 0.5 : 1 - _hits / 3;
    }
  }

  void _move(int d) => setState(() => _lane = (_lane + d).clamp(0, 2));

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(
        score: _score!,
        line: _hits >= 3
            ? 'Three hits. Game over.'
            : '$_hits hit${_hits == 1 ? '' : 's'} in 12 seconds',
        onDone: widget.onDone,
      );
    }
    return Column(
      children: [
        _progress('Hits $_hits of 3', elapsed / _length, color: NF.orange),
        const SizedBox(height: 10),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth / 3, h = box.maxHeight;
              return Stack(
                children: [
                  for (var i = 0; i < 3; i++)
                    Positioned(
                      left: w * i + 4,
                      width: w - 8,
                      top: 0,
                      bottom: 0,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: NF.surface2,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  for (final t in _things)
                    Positioned(
                      left: w * t.$1 + w / 2 - 20,
                      top: h * t.$2,
                      child: Icon(widget.hazard, size: 40, color: NF.danger),
                    ),
                  Positioned(
                    left: w * _lane + w / 2 - 24,
                    top: h * 0.88,
                    child: const Icon(
                      Icons.directions_car_filled_rounded,
                      size: 48,
                      color: NF.orange,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                style: primaryButton(),
                onPressed: () => _move(-1),
                child: const Icon(Icons.chevron_left_rounded, size: 36),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                style: primaryButton(),
                onPressed: () => _move(1),
                child: const Icon(Icons.chevron_right_rounded, size: 36),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------- Whack: hit targets, not decoys ----------------

class _WhackGame extends StatefulWidget {
  const _WhackGame({
    required this.onDone,
    required this.ease,
    required this.target,
    required this.decoy,
  });
  final void Function(double) onDone;
  final double ease;
  final IconData target;
  final IconData decoy;
  @override
  State<_WhackGame> createState() => _WhackGameState();
}

class _WhackGameState extends State<_WhackGame> with _Ticking {
  final _rng = Random();

  /// Cell -> (is a decoy, seconds left).
  final _up = <int, (bool, double)>{};
  double _spawn = 0.4;
  int _hit = 0, _shown = 0, _bad = 0;
  static const _length = 10.0;
  double? _score;

  @override
  void initState() {
    super.initState();
    startTicking(_tick);
  }

  void _tick(double dt) {
    if (_score != null) return;
    _up.updateAll((k, v) => (v.$1, v.$2 - dt));
    _up.removeWhere((k, v) => v.$2 <= 0);
    _spawn -= dt;
    if (_spawn <= 0) {
      final free = [
        for (var i = 0; i < 9; i++)
          if (!_up.containsKey(i)) i,
      ];
      if (free.isNotEmpty) {
        final decoy = _rng.nextInt(100) < 25;
        if (!decoy) _shown++;
        _up[free[_rng.nextInt(free.length)]] = (
          decoy,
          max(0.55, 1.2 - elapsed * 0.06) + widget.ease * 0.3,
        );
      }
      _spawn = max(0.3, 0.75 - elapsed * 0.04);
    }
    if (elapsed >= _length) {
      stopTicking();
      _score = ((_hit - _bad * 2) / max(1, _shown)).clamp(0.0, 1.0);
    }
  }

  void _tap(int i) {
    final v = _up.remove(i);
    if (v == null) return;
    setState(() => v.$1 ? _bad++ : _hit++);
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(
        score: _score!,
        line: '$_hit hit, $_bad wrong',
        onDone: widget.onDone,
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _progress(
          'Hit $_hit · avoid the grey ones',
          elapsed / _length,
          color: NF.orange,
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < 9; i++)
              GestureDetector(
                onTap: () => _tap(i),
                child: Container(
                  width: 104,
                  height: 104,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: NF.surface2,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: switch (_up[i]) {
                    (true, _) => Icon(widget.decoy, size: 52, color: NF.muted),
                    (false, _) => Icon(
                      widget.target,
                      size: 56,
                      color: NF.orange,
                    ),
                    _ => null,
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------- Rhythm: tap the pad on the beat ----------------

class _RhythmGame extends StatefulWidget {
  const _RhythmGame({
    required this.onDone,
    required this.names,
    required this.ease,
  });
  final void Function(double) onDone;
  final List<String> names;
  final double ease;
  @override
  State<_RhythmGame> createState() => _RhythmGameState();
}

class _RhythmGameState extends State<_RhythmGame> with _Ticking {
  static const _colors = [
    Color(0xFF7C9CFF),
    Color(0xFFFFB86B),
    Color(0xFF5EE6A8),
    Color(0xFFFF8FC7),
  ];
  static const _notes = 14;
  final _rng = Random();
  late final _song = List.generate(_notes, (_) => _rng.nextInt(4));
  int _beat = -1;
  double _next = 0.8;
  bool _tapped = false;
  int _good = 0;
  double? _score;

  double get _gap => max(0.42, 0.85 - _beat * 0.03) + widget.ease * 0.1;

  @override
  void initState() {
    super.initState();
    startTicking(_tick);
  }

  void _tick(double dt) {
    if (_score != null) return;
    _next -= dt;
    if (_next <= 0) {
      _beat++;
      _tapped = false;
      _next = _gap;
      if (_beat >= _notes) {
        stopTicking();
        _score = _good / _notes;
      }
    }
  }

  void _press(int i) {
    if (_beat < 0 || _beat >= _notes || _tapped) return;
    setState(() {
      _tapped = true;
      if (_song[_beat] == i) _good++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(
        score: _score!,
        line: '$_good of $_notes notes on the beat',
        onDone: widget.onDone,
      );
    }
    final lit = _beat >= 0 && !_tapped ? _song[_beat] : null;
    final upcoming = _beat + 1 < _notes ? _song[_beat + 1] : null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _beat < 0 ? 'Get ready…' : 'Note ${_beat + 1} of $_notes',
          style: NF.sora(16, color: NF.soft),
        ),
        const SizedBox(height: 6),
        Text(
          upcoming == null ? '' : 'Next: ${widget.names[upcoming]}',
          style: NF.sora(13, color: NF.muted),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (var i = 0; i < 4; i++)
              Semantics(
                button: true,
                label: widget.names[i],
                child: GestureDetector(
                  onTapDown: (_) => _press(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: 130,
                    height: 130,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _colors[i].withValues(alpha: lit == i ? 1 : 0.3),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: lit == i
                          ? [BoxShadow(color: _colors[i], blurRadius: 30)]
                          : null,
                    ),
                    child: Text(
                      widget.names[i],
                      style: NF.sora(18, weight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ---------------- Words: unscramble ----------------

class _WordsGame extends StatefulWidget {
  const _WordsGame({
    required this.onDone,
    required this.words,
    required this.ease,
  });
  final void Function(double) onDone;
  final List<String> words;
  final double ease;
  @override
  State<_WordsGame> createState() => _WordsGameState();
}

class _WordsGameState extends State<_WordsGame> with _Ticking {
  final _rng = Random();
  late final List<String> _picks = (List.of(
    widget.words,
  )..shuffle(_rng)).take(3).toList();
  int _i = 0;
  late List<(int, String)> _tiles = _scramble();
  final _typed = <int>[];
  int _solved = 0;
  double _left = 0;
  double? _score;

  double get _limit => 14 + widget.ease * 6;

  List<(int, String)> _scramble() {
    final w = _picks[_i].toUpperCase();
    var t = [for (var k = 0; k < w.length; k++) (k, w[k])];
    do {
      t.shuffle(_rng);
    } while (w.length > 1 && t.map((e) => e.$2).join() == w);
    return t;
  }

  @override
  void initState() {
    super.initState();
    _left = _limit;
    startTicking(_tick);
  }

  void _tick(double dt) {
    if (_score != null) return;
    _left -= dt;
    if (_left <= 0) _advance();
  }

  void _advance() {
    _i++;
    _typed.clear();
    if (_i >= _picks.length) {
      stopTicking();
      _score = _solved / _picks.length;
      return;
    }
    _tiles = _scramble();
    _left = _limit;
  }

  void _tap(int k) {
    if (_typed.contains(k)) return;
    setState(() {
      _typed.add(k);
      if (_typed.length == _tiles.length) {
        final word = [for (final t in _typed) _tiles[t].$2].join();
        if (word == _picks[_i].toUpperCase()) _solved++;
        _advance();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(
        score: _score!,
        line: '$_solved of ${_picks.length} words',
        onDone: widget.onDone,
      );
    }
    final typed = [for (final t in _typed) _tiles[t].$2].join();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _progress(
          'Word ${_i + 1} of ${_picks.length}',
          _left / _limit,
          color: NF.orange,
        ),
        const SizedBox(height: 24),
        Container(
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: NF.surface2,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            typed.isEmpty ? '…' : typed,
            style: NF.sora(30, weight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (var k = 0; k < _tiles.length; k++)
              SizedBox(
                width: 52,
                height: 58,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: _typed.contains(k)
                        ? NF.surface
                        : NF.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _tap(k),
                  child: Text(
                    _tiles[k].$2,
                    style: NF.sora(22, weight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        TextButton(
          onPressed: () => setState(_typed.clear),
          child: const Text('Clear'),
        ),
      ],
    );
  }
}
