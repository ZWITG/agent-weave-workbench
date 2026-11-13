part of 'minigames.dart';

// Hot Pursuit: three crime mini-games played on a grid.
// - Getaway: a police chase through city blocks to the motorway.
// - Break-in: a turn-based floor plan; a torch sweeps the hall, every step
//   makes noise, and a heavy bag makes more.
// - Breakout: a turn-based prison yard at night; a searchlight on a fixed
//   track (its next spot is shown) and two guards on routes you can read.
// Every rule is visible before it bites, and Skip still resolves at 0.6.

typedef _P = (int, int);

const _dirs = <_P>[(0, -1), (1, 0), (0, 1), (-1, 0)];

_P _add(_P a, _P b) => (a.$1 + b.$1, a.$2 + b.$2);

/// The next step from [from] towards [to] over open cells, or null.
_P? _stepTowards(_P from, _P to, bool Function(_P) open, int w, int h) {
  if (from == to) return null;
  final prev = <_P, _P>{from: from};
  final queue = [from];
  for (var i = 0; i < queue.length; i++) {
    final c = queue[i];
    if (c == to) break;
    for (final d in _dirs) {
      final n = _add(c, d);
      if (n.$1 < 0 || n.$2 < 0 || n.$1 >= w || n.$2 >= h) continue;
      if (!open(n) || prev.containsKey(n)) continue;
      prev[n] = c;
      queue.add(n);
    }
  }
  if (!prev.containsKey(to)) return null;
  var c = to;
  while (prev[c] != from) {
    c = prev[c]!;
  }
  return c;
}

/// Paints a Material icon on a canvas.
void _icon(Canvas c, IconData icon, Offset center, double size, Color color) {
  final tp = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        fontSize: size,
        color: color,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
}

/// Arrows (and an optional Wait) under a grid game; swipes work too.
class _DPad extends StatelessWidget {
  const _DPad({required this.onMove, this.onWait});
  final void Function(_P) onMove;
  final VoidCallback? onWait;

  @override
  Widget build(BuildContext context) {
    final skin = _skinOf(context);
    Widget b(IconData icon, _P d, String label) => Semantics(
      label: label,
      button: true,
      child: SizedBox(
        width: 64,
        height: 44,
        child: FilledButton(
          style: skin.button().copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          ),
          onPressed: () => onMove(d),
          child: Icon(icon, size: 28),
        ),
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        b(Icons.chevron_left_rounded, (-1, 0), 'Left'),
        const SizedBox(width: 8),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            b(Icons.expand_less_rounded, (0, -1), 'Up'),
            const SizedBox(height: 6),
            b(Icons.expand_more_rounded, (0, 1), 'Down'),
          ],
        ),
        const SizedBox(width: 8),
        b(Icons.chevron_right_rounded, (1, 0), 'Right'),
        if (onWait != null) ...[
          const SizedBox(width: 14),
          SizedBox(
            height: 94,
            child: FilledButton(
              style: skin.quiet(),
              onPressed: onWait,
              child: const Text('Wait'),
            ),
          ),
        ],
      ],
    );
  }
}

/// Turns a swipe into a direction.
_P? _swipe(DragEndDetails d) {
  final v = d.velocity.pixelsPerSecond;
  if (v.distance < 120) return null;
  return v.dx.abs() > v.dy.abs()
      ? (v.dx > 0 ? (1, 0) : (-1, 0))
      : (v.dy > 0 ? (0, 1) : (0, -1));
}

// ---------------- Getaway ----------------

class _GetawayGame extends StatefulWidget {
  const _GetawayGame({required this.onDone, required this.ease});
  final void Function(double) onDone;
  final double ease;
  @override
  State<_GetawayGame> createState() => _GetawayGameState();
}

class _GetawayGameState extends State<_GetawayGame> with _Ticking {
  static const w = 9, h = 11;
  static const limit = 22.0;
  final _rng = Random();
  late _P _me = (4, h - 1);
  _P _dir = (0, -1);
  _P? _want;
  late final _P _exit = (_rng.nextInt(5) * 2, 0);
  late final _P _tunnel = (1 + _rng.nextInt(4) * 2, 4 + _rng.nextInt(2) * 2);
  late _P _garage = (_rng.nextBool() ? 0 : 8, 3 + _rng.nextInt(3) * 2 - 1);
  late final List<_P> _cops = [
    (0, h - 1),
    (8, h - 1),
    (_exit.$1 >= 4 ? 0 : 8, 0),
  ];
  double _myClock = 0, _copClock = 0, _lost = 0, _backup = 7;
  int _turns = 0;
  bool _turnBased = false, _started = false;
  double? _score;
  String _line = '';

  static bool road(_P p) =>
      p.$1 >= 0 &&
      p.$2 >= 0 &&
      p.$1 < w &&
      p.$2 < h &&
      (p.$1.isEven || p.$2.isEven);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _turnBased = MediaQuery.of(context).disableAnimations;
    if (!_turnBased && !_started) {
      _started = true;
      startTicking(_tick);
    }
  }

  double get _mySpeed => 0.2 - widget.ease * 0.04;

  void _tick(double dt) {
    if (_score != null) return;
    _myClock += dt;
    _copClock += dt;
    _lost = max(0, _lost - dt);
    if (_myClock >= _mySpeed) {
      _myClock = 0;
      _stepMe();
    }
    if (_copClock >= 0.27 && _score == null) {
      _copClock = 0;
      _stepCops();
    }
    if (elapsed >= _backup && _cops.length < 4) {
      _cops.add(
        _me.$2 > h ~/ 2
            ? (_rng.nextInt(5) * 2, 0)
            : (_rng.nextInt(5) * 2, h - 1),
      );
      _backup = 1e9;
    }
    if (_score == null && elapsed >= limit) {
      _end(
        0.45,
        'Still loose when the sirens thinned out, but not clear of the city.',
      );
    }
  }

  void _stepMe() {
    final want = _want;
    if (want != null && road(_add(_me, want))) {
      _dir = want;
      _want = null;
    }
    final next = _add(_me, _dir);
    if (road(next)) _me = next;
    if (_me == _tunnel) _lost = _turnBased ? 4 : 2.6;
    if (_me == _garage) {
      _garage = (-9, -9);
      _lost = _turnBased ? 3 : 1.8;
      for (var i = 0; i < _cops.length; i++) {
        _cops[i] = (i.isEven ? 0 : 8, i < 2 ? h - 1 : 0);
      }
    }
    if (_me == _exit) {
      final t = _turnBased ? _turns / 40 : elapsed / limit;
      _end(
        0.75 + 0.25 * (1 - t).clamp(0, 1),
        'Onto the motorway and gone. Clean getaway.',
      );
      return;
    }
    _checkCaught();
  }

  void _stepCops() {
    for (var i = 0; i < _cops.length; i++) {
      final c = _cops[i];
      _P? next;
      if (_lost > 0) {
        final opts = [
          for (final d in _dirs)
            if (road(_add(c, d))) _add(c, d),
        ];
        next = opts[_rng.nextInt(opts.length)];
      } else {
        next = _stepTowards(c, _me, road, w, h);
      }
      if (next != null && !_cops.contains(next)) _cops[i] = next;
    }
    _checkCaught();
  }

  void _checkCaught() {
    if (_score != null) return;
    if (_cops.contains(_me)) {
      final progress = (h - 1 - _me.$2) / (h - 1);
      _end(0.1 + 0.3 * progress, 'Boxed in. Doors open, hands on the roof.');
    }
  }

  void _end(double s, String line) {
    stopTicking();
    _score = s.clamp(0, 1).toDouble();
    _line = line;
  }

  void _move(_P d) {
    if (_score != null) return;
    setState(() {
      if (!_turnBased) {
        _want = d;
        return;
      }
      // Turn by turn: you move, then the police (they skip every 4th turn).
      _turns++;
      if (road(_add(_me, d))) _dir = d;
      _want = null;
      _stepMe();
      if (_lost > 0) _lost -= 1;
      if (_score == null && _turns % 4 != 0) _stepCops();
      if (_turns == 8 && _cops.length < 4) _cops.add((_rng.nextInt(5) * 2, 0));
      if (_score == null && _turns >= 40) {
        _end(0.45, 'Still loose at dawn, but not clear of the city.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(score: _score!, line: _line, onDone: widget.onDone);
    }
    return Column(
      children: [
        _progress(
          context,
          _lost > 0
              ? 'They lost sight of you!'
              : _turnBased
              ? 'Turn $_turns of 40 · reach the motorway (M)'
              : 'Reach the motorway (M) · ${max(0, limit - elapsed).ceil()}s',
          _turnBased ? _turns / 40 : elapsed / limit,
          color: _lost > 0 ? _skinOf(context).zone : NF.danger,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GestureDetector(
            onPanEnd: (d) {
              final s = _swipe(d);
              if (s != null) _move(s);
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: _CityPainter(
                me: _me,
                dir: _dir,
                cops: List.of(_cops),
                exit: _exit,
                tunnel: _tunnel,
                garage: _garage,
                flash: (elapsed * 4).floor().isEven,
                lost: _lost > 0,
                skin: _skinOf(context),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The dark tunnel breaks their line of sight · the green garage swaps your car',
          textAlign: TextAlign.center,
          style: NF.sora(11, color: NF.muted),
        ),
        const SizedBox(height: 6),
        _DPad(onMove: _move),
      ],
    );
  }
}

class _CityPainter extends CustomPainter {
  _CityPainter({
    required this.me,
    required this.dir,
    required this.cops,
    required this.exit,
    required this.tunnel,
    required this.garage,
    required this.flash,
    required this.lost,
    required this.skin,
  });
  final _P me, dir, exit, tunnel, garage;
  final List<_P> cops;
  final bool flash, lost;
  final MiniSkin skin;

  @override
  void paint(Canvas canvas, Size size) {
    const w = _GetawayGameState.w, h = _GetawayGameState.h;
    final cell = min(size.width / w, size.height / h);
    final ox = (size.width - cell * w) / 2, oy = (size.height - cell * h) / 2;
    Rect r(_P p) =>
        Rect.fromLTWH(ox + p.$1 * cell, oy + p.$2 * cell, cell, cell);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(ox, oy, cell * w, cell * h),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF15171B),
    );
    final rng = Random(7);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = (x, y);
        if (_GetawayGameState.road(p)) {
          canvas.drawRect(
            r(p).deflate(0.5),
            Paint()..color = const Color(0xFF2A2D33),
          );
        } else {
          // A block of buildings with lit windows.
          final b = r(p).deflate(3);
          canvas.drawRRect(
            RRect.fromRectAndRadius(b, const Radius.circular(3)),
            Paint()..color = const Color(0xFF3A3340),
          );
          for (var i = 0; i < 4; i++) {
            if (rng.nextInt(3) == 0) continue;
            canvas.drawRect(
              Rect.fromLTWH(
                b.left + 4 + (i % 2) * b.width / 2,
                b.top + 4 + (i ~/ 2) * b.height / 2,
                b.width / 2 - 8,
                b.height / 2 - 8,
              ),
              Paint()..color = const Color(0x88FFC861),
            );
          }
        }
      }
    }
    // Tunnel, garage, motorway.
    canvas.drawRect(
      r(tunnel).deflate(2),
      Paint()..color = const Color(0xFF0B0C0E),
    );
    _icon(
      canvas,
      Icons.dark_mode_rounded,
      r(tunnel).center,
      cell * 0.5,
      const Color(0xFF7D8590),
    );
    if (garage.$1 >= 0) {
      canvas.drawRect(
        r(garage).deflate(2),
        Paint()..color = const Color(0xFF2E4A3A),
      );
      _icon(
        canvas,
        Icons.garage_rounded,
        r(garage).center,
        cell * 0.6,
        const Color(0xFF8BE0A8),
      );
    }
    canvas.drawRect(
      r(exit).deflate(1),
      Paint()..color = const Color(0xFF1F6F43),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: 'M',
        style: NF.sora(
          cell * 0.55,
          weight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, r(exit).center - Offset(tp.width / 2, tp.height / 2));
    // Police cars, flashing.
    for (final c in cops) {
      final cr = r(c).deflate(cell * 0.15);
      canvas.drawRRect(
        RRect.fromRectAndRadius(cr, Radius.circular(cell * 0.12)),
        Paint()..color = const Color(0xFFE8ECF2),
      );
      canvas.drawRect(
        Rect.fromLTWH(cr.left, cr.center.dy - 3, cr.width / 2, 6),
        Paint()
          ..color = flash ? const Color(0xFFFF3B3B) : const Color(0xFF7A1D1D),
      );
      canvas.drawRect(
        Rect.fromLTWH(cr.center.dx, cr.center.dy - 3, cr.width / 2, 6),
        Paint()
          ..color = flash ? const Color(0xFF1E3B7A) : const Color(0xFF3B6BFF),
      );
      if (!lost) {
        canvas.drawCircle(
          cr.center,
          cell * 0.7,
          Paint()
            ..color = (flash
                ? const Color(0x33FF3B3B)
                : const Color(0x333B6BFF)),
        );
      }
    }
    // You, with headlights.
    final mr = r(me);
    canvas.drawCircle(
      mr.center + Offset(dir.$1 * cell * 0.6, dir.$2 * cell * 0.6),
      cell * 0.45,
      Paint()..color = const Color(0x33FFE9A0),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        mr.deflate(cell * 0.18),
        Radius.circular(cell * 0.12),
      ),
      Paint()..color = skin.accent,
    );
  }

  @override
  bool shouldRepaint(_CityPainter old) => true;
}

// ---------------- Break-in ----------------

/// The house: # wall, . floor, D doorway, W window (a way out),
/// S the back door you came in by (also a way out), $ where things are.
const _house = [
  '#########',
  '#...#...#',
  '#.\$.D.\$.W',
  '#...#...#',
  '##D###D##',
  'W.......#',
  '##D###D##',
  '#...#.\$.#',
  '#.\$.D...W',
  '#..\$#.\$.#',
  '##S######',
];

typedef _Loot = ({IconData icon, String name, int value, int weight});

const _lootKinds = <_Loot>[
  (icon: Icons.payments_rounded, name: 'cash box', value: 5, weight: 1),
  (icon: Icons.diamond_rounded, name: 'ring', value: 6, weight: 1),
  (icon: Icons.watch_rounded, name: 'watch', value: 4, weight: 1),
  (icon: Icons.laptop_rounded, name: 'laptop', value: 4, weight: 2),
  (icon: Icons.tv_rounded, name: 'television', value: 5, weight: 3),
  (icon: Icons.image_rounded, name: 'painting', value: 7, weight: 3),
  (icon: Icons.headphones_rounded, name: 'headphones', value: 2, weight: 1),
];

class _BreakInGame extends StatefulWidget {
  const _BreakInGame({required this.onDone, required this.ease});
  final void Function(double) onDone;
  final double ease;
  @override
  State<_BreakInGame> createState() => _BreakInGameState();
}

class _BreakInGameState extends State<_BreakInGame> {
  static const w = 9, h = 11, capacity = 6;
  final _rng = Random();
  late final bool _flip = _rng.nextBool();
  late final Map<_P, _Loot> _loot = {
    for (final p in _spots()) p: _lootKinds[_rng.nextInt(_lootKinds.length)],
  };
  final _bag = <_Loot>[];
  late _P _me = _find('S');
  // The occupant walks the hall end to end with a torch.
  _P _them = (1, 5);
  _P _face = (1, 0);
  bool _awake = false;
  int _noise = 0, _turns = 0;

  /// The house wakes up at last: after this many turns they are up.
  static const dawn = 60;
  double? _score;
  String _line = '';

  String _at(_P p) {
    if (p.$1 < 0 || p.$2 < 0 || p.$1 >= w || p.$2 >= h) return '#';
    final x = _flip ? w - 1 - p.$1 : p.$1;
    return _house[p.$2][x];
  }

  _P _find(String ch) {
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (_at((x, y)) == ch) return (x, y);
      }
    }
    return (4, h - 1);
  }

  List<_P> _spots() => [
    for (var y = 0; y < h; y++)
      for (var x = 0; x < w; x++)
        if (_at((x, y)) == r'$') (x, y),
  ];

  bool _open(_P p) => _at(p) != '#';
  bool _exitCell(_P p) => _at(p) == 'W' || _at(p) == 'S';
  int get _weight => _bag.fold(0, (s, l) => s + l.weight);
  int get _value => _bag.fold(0, (s, l) => s + l.value);

  /// Cells the torch lights: theirs and three ahead, stopped by walls.
  Set<_P> get _lit {
    final out = {_them};
    var c = _them;
    for (var i = 0; i < 3; i++) {
      c = _add(c, _face);
      if (!_open(c)) break;
      out.add(c);
    }
    return out;
  }

  void _act(_P? d) {
    if (_score != null) return;
    setState(() {
      _turns++;
      if (d == null) {
        _noise = max(0, _noise - 12);
      } else {
        final n = _add(_me, d);
        if (!_open(n)) return;
        _me = n;
        _noise = min(100, _noise + 4 + 3 * _weight - (widget.ease * 4).round());
        final l = _loot.remove(n);
        if (l != null) {
          if (_weight + l.weight <= capacity) {
            _bag.add(l);
          } else {
            _loot[n] = l; // too heavy: leave it
          }
        }
        if (_exitCell(n) && _bag.isNotEmpty) {
          final best = _bestPossible();
          _end(
            0.45 + 0.55 * (_value / best).clamp(0, 1),
            'Out through the ${_at(n) == 'S' ? 'back door' : 'window'} with ${_bag.map((b) => b.name).join(', ')}.',
          );
          return;
        }
      }
      if (_caught()) return;
      _moveThem();
      _caught();
    });
  }

  int _bestPossible() {
    final all = [..._loot.values, ..._bag]
      ..sort((a, b) => (b.value / b.weight).compareTo(a.value / a.weight));
    var wgt = 0, val = 0;
    for (final l in all) {
      if (wgt + l.weight > capacity) continue;
      wgt += l.weight;
      val += l.value;
    }
    return max(1, val);
  }

  void _moveThem() {
    if ((_noise >= 100 || _turns >= dawn) && !_awake) _awake = true;
    if (_awake) {
      final next = _stepTowards(_them, _me, _open, w, h);
      if (next != null) {
        _face = (next.$1 - _them.$1, next.$2 - _them.$2);
        _them = next;
      }
      return;
    }
    // Pace the hall; turn at either end.
    final next = _add(_them, _face);
    if (_at(next) == '.' && next.$2 == 5) {
      _them = next;
    } else {
      _face = (-_face.$1, 0);
    }
  }

  bool _caught() {
    if (_lit.contains(_me) || _them == _me) {
      _end(
        0.08 + 0.02 * _bag.length,
        _awake
            ? 'They heard you and came looking. Caught in the doorway.'
            : 'The torch swung round and found your face.',
      );
      return true;
    }
    return false;
  }

  void _end(double s, String line) {
    _score = s.clamp(0, 1).toDouble();
    _line = line;
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(score: _score!, line: _line, onDone: widget.onDone);
    }
    return Column(
      children: [
        _progress(
          context,
          _awake
              ? 'They are awake and looking for you!'
              : 'Noise ${_noise.round()}% · bag $_weight/$capacity kg',
          _noise / 100,
          color: _noise >= 70 ? NF.danger : _skinOf(context).accent,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GestureDetector(
            onPanEnd: (d) {
              final s = _swipe(d);
              if (s != null) _act(s);
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: _HousePainter(this, _skinOf(context)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Keep out of the torchlight · a full bag is louder · Wait to let the noise settle · leave by a window or the back door',
          textAlign: TextAlign.center,
          style: NF.sora(11, color: NF.muted),
        ),
        const SizedBox(height: 6),
        _DPad(onMove: _act, onWait: () => _act(null)),
      ],
    );
  }
}

class _HousePainter extends CustomPainter {
  _HousePainter(this.g, this.skin);
  final _BreakInGameState g;
  final MiniSkin skin;

  @override
  void paint(Canvas canvas, Size size) {
    const w = _BreakInGameState.w, h = _BreakInGameState.h;
    final cell = min(size.width / w, size.height / h);
    final ox = (size.width - cell * w) / 2, oy = (size.height - cell * h) / 2;
    Rect r(_P p) =>
        Rect.fromLTWH(ox + p.$1 * cell, oy + p.$2 * cell, cell, cell);
    final lit = g._lit;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = (x, y);
        final ch = g._at(p);
        final paint = Paint()
          ..color = switch (ch) {
            '#' => const Color(0xFF3B3F48),
            'W' => const Color(0xFF4C7BA8),
            'S' => const Color(0xFF6D5A3A),
            _ => const Color(0xFF1A1C22),
          };
        canvas.drawRect(r(p).deflate(ch == '#' ? 0 : 0.6), paint);
        if (lit.contains(p)) {
          canvas.drawRect(r(p), Paint()..color = const Color(0x88FFE27A));
        }
      }
    }
    for (final e in g._loot.entries) {
      _icon(
        canvas,
        e.value.icon,
        r(e.key).center,
        cell * 0.62,
        const Color(0xFFFFD36B),
      );
    }
    _icon(
      canvas,
      g._awake ? Icons.directions_run_rounded : Icons.flashlight_on_rounded,
      r(g._them).center,
      cell * 0.7,
      g._awake ? const Color(0xFFFF5A4A) : const Color(0xFFFFF1B8),
    );
    canvas.drawCircle(
      r(g._me).center,
      cell * 0.46,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      r(g._me).center,
      cell * 0.4,
      Paint()..color = skin.accent,
    );
    _icon(
      canvas,
      Icons.backpack_rounded,
      r(g._me).center,
      cell * 0.42,
      const Color(0xFF14161C),
    );
  }

  @override
  bool shouldRepaint(_HousePainter old) => true;
}

// ---------------- Breakout ----------------

class _BreakoutGame extends StatefulWidget {
  const _BreakoutGame({required this.onDone, required this.ease});
  final void Function(double) onDone;
  final double ease;
  @override
  State<_BreakoutGame> createState() => _BreakoutGameState();
}

class _BreakoutGameState extends State<_BreakoutGame> {
  static const w = 9, h = 11, maxTurns = 40;
  final _rng = Random();
  late final int _gap = 1 + _rng.nextInt(7);
  static const _blocks = {
    (2, 3),
    (3, 3),
    (6, 4),
    (5, 6),
    (6, 6),
    (1, 7),
    (2, 7),
    (7, 8),
    (4, 9),
  };
  _P _me = (4, h - 1);
  int _turns = 0, _light = 0;
  // Two guards: one paces row 8, one walks column 7.
  _P _g1 = (1, 8), _f1 = (1, 0);
  _P _g2 = (8, 1), _f2 = (0, 1);
  // (The second guard walks the east fence line, top to bottom and back.)
  double? _score;
  String _line = '';

  /// The searchlight's track: along row 2, then back along row 5.
  static final _track = <_P>[
    for (var x = 1; x <= 7; x++) (x, 2),
    for (var x = 7; x >= 1; x--) (x, 5),
  ];

  _P get _beam => _track[_light % _track.length];
  _P get _nextBeam => _track[(_light + 1) % _track.length];

  bool _open(_P p) =>
      p.$1 >= 0 &&
      p.$1 < w &&
      p.$2 >= 0 &&
      p.$2 < h &&
      !_blocks.contains(p) &&
      (p.$2 > 0 || p.$1 == _gap);

  static bool _inBeam(_P c, _P p) =>
      (c.$1 - p.$1).abs() <= 1 && (c.$2 - p.$2).abs() <= 1;

  Set<_P> _sight(_P g, _P f) {
    final out = {g};
    var c = g;
    for (var i = 0; i < 2; i++) {
      c = _add(c, f);
      if (!_open(c)) break;
      out.add(c);
    }
    return out;
  }

  _P _patrol(_P g, _P f, void Function(_P) face) {
    final n = _add(g, f);
    if (_open(n) && n.$2 > 0) return n;
    final back = (-f.$1, -f.$2);
    face(back);
    return _add(g, back);
  }

  bool get _seen =>
      _inBeam(_beam, _me) ||
      _sight(_g1, _f1).contains(_me) ||
      _sight(_g2, _f2).contains(_me);

  void _act(_P? d) {
    if (_score != null) return;
    setState(() {
      if (d != null) {
        final n = _add(_me, d);
        if (!_open(n)) return;
        _me = n;
      }
      _turns++;
      if (_me.$2 == 0) {
        _end(
          0.7 + 0.3 * (1 - _turns / maxTurns),
          'Through the gap in the fence and into the dark. Free.',
        );
        return;
      }
      if (_seen) return _caughtNow();
      _light++;
      _g1 = _patrol(_g1, _f1, (f) => _f1 = f);
      _g2 = _patrol(_g2, _f2, (f) => _f2 = f);
      if (_seen) return _caughtNow();
      if (_turns >= maxTurns) {
        _end(
          0.35,
          'Dawn broke before you reached the fence. You crept back to your bunk.',
        );
      }
    });
  }

  void _caughtNow() {
    final progress = (h - 1 - _me.$2) / (h - 1);
    _end(
      0.05 + 0.35 * progress,
      'A light hit you full in the face. Sirens, dogs, a long walk back.',
    );
  }

  void _end(double s, String line) {
    _score = s.clamp(0, 1).toDouble();
    _line = line;
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(score: _score!, line: _line, onDone: widget.onDone);
    }
    return Column(
      children: [
        _progress(
          context,
          'Turn $_turns of $maxTurns · reach the gap in the fence',
          _turns / maxTurns,
          color: _skinOf(context).accent,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GestureDetector(
            onPanEnd: (d) {
              final s = _swipe(d);
              if (s != null) _act(s);
            },
            child: CustomPaint(
              size: Size.infinite,
              painter: _YardPainter(this),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'The dotted square is where the searchlight goes next · guards see two squares ahead',
          textAlign: TextAlign.center,
          style: NF.sora(11, color: NF.muted),
        ),
        const SizedBox(height: 6),
        _DPad(onMove: _act, onWait: () => _act(null)),
      ],
    );
  }
}

class _YardPainter extends CustomPainter {
  _YardPainter(this.g);
  final _BreakoutGameState g;

  @override
  void paint(Canvas canvas, Size size) {
    const w = _BreakoutGameState.w, h = _BreakoutGameState.h;
    final cell = min(size.width / w, size.height / h);
    final ox = (size.width - cell * w) / 2, oy = (size.height - cell * h) / 2;
    Rect r(_P p) =>
        Rect.fromLTWH(ox + p.$1 * cell, oy + p.$2 * cell, cell, cell);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = (x, y);
        final Color c;
        if (y == 0) {
          c = x == g._gap ? const Color(0xFF0E1A14) : const Color(0xFF55605B);
        } else if (_BreakoutGameState._blocks.contains(p)) {
          c = const Color(0xFF3E4C46);
        } else {
          c = const Color(0xFF17201C);
        }
        canvas.drawRect(r(p).deflate(0.6), Paint()..color = c);
        if (y == 0 && x != g._gap) {
          // Chain-link and wire on the fence.
          final f = Paint()
            ..color = const Color(0xFF8A9690)
            ..strokeWidth = 1;
          final b = r(p);
          canvas.drawLine(b.topLeft, b.bottomRight, f);
          canvas.drawLine(b.topRight, b.bottomLeft, f);
        }
      }
    }
    _icon(
      canvas,
      Icons.exit_to_app_rounded,
      r((g._gap, 0)).center,
      cell * 0.55,
      const Color(0xFF9FE0C1),
    );
    // Guards' sight lines.
    for (final (pos, face) in [(g._g1, g._f1), (g._g2, g._f2)]) {
      for (final s in g._sight(pos, face)) {
        canvas.drawRect(r(s), Paint()..color = const Color(0x44FF8A5C));
      }
      _icon(
        canvas,
        Icons.local_police_rounded,
        r(pos).center,
        cell * 0.66,
        const Color(0xFFFFB38A),
      );
    }
    // Searchlight now (solid) and next (dotted).
    final now = Rect.fromCenter(
      center: r(g._beam).center,
      width: cell * 3,
      height: cell * 3,
    );
    canvas.drawRect(now, Paint()..color = const Color(0x66FFF6C4));
    final next = Rect.fromCenter(
      center: r(g._nextBeam).center,
      width: cell * 3,
      height: cell * 3,
    );
    final dash = Paint()
      ..color = const Color(0xAAFFF6C4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0.0; i < 1; i += 0.1) {
      for (final (a, b) in [
        (next.topLeft, next.topRight),
        (next.topRight, next.bottomRight),
        (next.bottomRight, next.bottomLeft),
        (next.bottomLeft, next.topLeft),
      ]) {
        canvas.drawLine(
          Offset.lerp(a, b, i)!,
          Offset.lerp(a, b, i + 0.05)!,
          dash,
        );
      }
    }
    canvas.drawCircle(
      r(g._me).center,
      cell * 0.46,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      r(g._me).center,
      cell * 0.4,
      Paint()..color = const Color(0xFFFF9F43),
    );
    _icon(
      canvas,
      Icons.directions_walk_rounded,
      r(g._me).center,
      cell * 0.44,
      const Color(0xFF14161C),
    );
  }

  @override
  bool shouldRepaint(_YardPainter old) => true;
}
