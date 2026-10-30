import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../theme.dart';
import 'widgets.dart';

/// Short mini-games for some activities. Each returns a score from 0 to 1,
/// or null if the player closes it. "Skip" always resolves at 0.6, so
/// nobody is penalised for not playing (plan: accessible by default).
/// [activity] themes the game (words, buttons, pads, questions) and [life]
/// eases it a little with the stat that activity uses.
Future<double?> showMiniGame(
  BuildContext context,
  String id, {
  required int age,
  required String title,
  String? activity,
  Life? life,
}) {
  final theme = miniThemes[activity] ?? _defaults[id]!;
  final stat = life == null ? 50 : life.stats[theme.stat];
  final ease = ((stat - 50) / 100).clamp(-0.5, 0.5).toDouble();
  return Navigator.of(context).push<double>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _MiniGameScreen(
        id: id,
        age: age,
        title: title,
        theme: theme,
        ease: ease,
      ),
    ),
  );
}

const _skipScore = 0.6;

/// How a mini-game looks and reads for one activity.
typedef MiniTheme = ({
  String intro,
  String button,
  String wait,
  List<String> pads,
  String stat,
});

MiniTheme _t(
  String intro, {
  String button = 'Now!',
  String wait = 'Wait…',
  List<String> pads = const ['Blue', 'Orange', 'Green', 'Pink'],
  String stat = 'smarts',
}) => (intro: intro, button: button, wait: wait, pads: pads, stat: stat);

final _defaults = <String, MiniTheme>{
  'reps': _t(
    'Tap as many times as you can in 6 seconds.',
    button: 'GO',
    stat: 'athleticism',
  ),
  'quiz': _t('Answer three quick questions.'),
  'timing': _t('Tap when the marker is inside the green zone.'),
  'cards': _t('Will the next card be higher or lower? Three rounds.'),
  'reaction': _t(
    'Tap the moment the light turns green.',
    button: 'NOW!',
    stat: 'athleticism',
  ),
  'memory': _t('Watch the pattern, then play it back.', stat: 'creativity'),
};

/// Themes by activity id.
final miniThemes = <String, MiniTheme>{
  'gym': _t(
    'Tap LIFT as many times as you can in 6 seconds. The fitter you are, the fewer reps a top score needs.',
    button: 'LIFT',
    stat: 'athleticism',
  ),
  'study': _t('Three questions from today\'s lessons.'),
  'shoplift': _t(
    'The guard keeps glancing over. Grab it while the marker is in the blind spot.',
    button: 'Grab it',
    stat: 'willpower',
  ),
  'pickpocket': _t(
    'Wait for the crowd to jostle. Lift the wallet while the marker is in the green.',
    button: 'Lift it',
    stat: 'willpower',
  ),
  'casino': _t('Higher or lower: three hands at the table.'),
  'instrument': _t(
    'Listen to the melody, then play the notes back in order.',
    pads: ['C', 'E', 'G', 'B'],
    stat: 'creativity',
  ),
  'driving_lessons': _t(
    'The light is red. Brake the moment it turns green, not before!',
    button: 'BRAKE!',
    wait: 'Red light…',
    stat: 'athleticism',
  ),
  'yoga': _t(
    'Find your balance: tap while the marker is in the steady zone.',
    button: 'Hold the pose',
    stat: 'athleticism',
  ),
  'video_games': _t(
    'Final boss. Fire the moment the target lights up.',
    button: 'FIRE!',
    wait: 'Ready…',
  ),
  'write_story': _t(
    'Remember the plot beats, then write them in order.',
    pads: ['Hero', 'Secret', 'Twist', 'Ending'],
    stat: 'creativity',
  ),
  'reflect': _t(
    'Breathe slowly. Breathe out while the marker is in the calm zone.',
    button: 'Breathe out',
    stat: 'willpower',
  ),
};

class _MiniGameScreen extends StatelessWidget {
  const _MiniGameScreen({
    required this.id,
    required this.age,
    required this.title,
    required this.theme,
    required this.ease,
  });
  final String id;
  final int age;
  final String title;
  final MiniTheme theme;

  /// −0.5 (the stat is far below average) to 0.5 (far above).
  final double ease;

  @override
  Widget build(BuildContext context) {
    void finish(double s) => Navigator.of(context).pop(s);
    final instructions = theme.intro;
    final Widget game = switch (id) {
      'reps' => _RepsGame(
        onDone: finish,
        button: theme.button,
        target: (35 - ease * 10).round(),
      ),
      'quiz' => _QuizGame(age: age, onDone: finish),
      'timing' => _TimingGame(
        onDone: finish,
        button: theme.button,
        zone: (0.2 + ease * 0.12).clamp(0.12, 0.28).toDouble(),
      ),
      'cards' => _CardsGame(onDone: finish),
      'reaction' => _ReactionGame(
        onDone: finish,
        wait: theme.wait,
        go: theme.button,
        bonusMs: (ease * 200).round(),
      ),
      'memory' => _MemoryGame(
        onDone: finish,
        names: theme.pads,
        stepMs: (500 + ease * 200).round(),
      ),
      _ => const SizedBox.shrink(),
    };
    return Scaffold(
      backgroundColor: NF.bg,
      body: GlowBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Close without playing',
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            title,
                            style: NF.sora(20, weight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      instructions,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: NF.sora(15, color: NF.soft, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    // Every game is laid out on the same stage and scaled
                    // down to fit small phones and large text.
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(width: 360, height: 480, child: game),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => finish(_skipScore),
                      child: const Text('Skip and decide for me'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the score and a Continue button once a game ends.
class _Done extends StatelessWidget {
  const _Done({required this.score, required this.line, required this.onDone});
  final double score;
  final String line;
  final void Function(double) onDone;

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).round();
    final color = score >= 0.7
        ? const Color(0xFF5EE6A8)
        : (score >= 0.4 ? NF.orange : NF.danger);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$pct%',
          style: NF.sora(64, weight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          line,
          textAlign: TextAlign.center,
          style: NF.sora(16, color: NF.soft),
        ),
        const SizedBox(height: 24),
        FilledButton(
          style: primaryButton(),
          onPressed: () => onDone(score),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}

// ---------------- Reps: tap fast ----------------

class _RepsGame extends StatefulWidget {
  const _RepsGame({
    required this.onDone,
    required this.button,
    required this.target,
  });
  final void Function(double) onDone;
  final String button;

  /// Taps for a perfect score.
  final int target;
  @override
  State<_RepsGame> createState() => _RepsGameState();
}

class _RepsGameState extends State<_RepsGame> {
  int _taps = 0;
  double _left = 6;
  Timer? _t;
  bool _over = false;

  void _tap() {
    if (_over) return;
    _t ??= Timer.periodic(const Duration(milliseconds: 100), (t) {
      setState(() => _left = max(0, _left - 0.1));
      if (_left <= 0) {
        t.cancel();
        setState(() => _over = true);
      }
    });
    setState(() => _taps++);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final score = min(1.0, _taps / widget.target);
    if (_over) {
      return _Done(score: score, line: '$_taps reps', onDone: widget.onDone);
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$_taps', style: NF.sora(72, weight: FontWeight.w700)),
        Text(
          _t == null ? 'Tap to start' : '${_left.toStringAsFixed(1)} s left',
          style: NF.sora(15, color: NF.muted),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: 180,
          height: 180,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: NF.orange,
              foregroundColor: NF.bg,
              shape: const CircleBorder(),
            ),
            onPressed: _tap,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.button,
                style: NF.sora(28, weight: FontWeight.w700, color: NF.bg),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- Quiz ----------------

class _QuizGame extends StatefulWidget {
  const _QuizGame({required this.age, required this.onDone});
  final int age;
  final void Function(double) onDone;
  @override
  State<_QuizGame> createState() => _QuizGameState();
}

class _QuizGameState extends State<_QuizGame> {
  final _rng = Random();

  /// Questions from lessons, harder with age: sums, times tables, then a
  /// mix of maths and general knowledge.
  static const _facts = [
    (
      'Which planet is called the Red Planet?',
      'Mars',
      ['Venus', 'Jupiter', 'Saturn'],
    ),
    (
      'What gas do plants take in?',
      'Carbon dioxide',
      ['Oxygen', 'Helium', 'Nitrogen'],
    ),
    ('How many sides does a hexagon have?', '6', ['5', '7', '8']),
    ('What is H₂O?', 'Water', ['Salt', 'Hydrogen', 'Oxygen']),
    (
      'Which is the largest ocean?',
      'Pacific',
      ['Atlantic', 'Indian', 'Arctic'],
    ),
    ('What is 15% of 200?', '30', ['15', '20', '35']),
    (
      'Who wrote Romeo and Juliet?',
      'Shakespeare',
      ['Dickens', 'Austen', 'Tolkien'],
    ),
    ('Water boils at sea level at…', '100 °C', ['90 °C', '80 °C', '120 °C']),
    (
      'Which organ pumps blood?',
      'The heart',
      ['The lungs', 'The liver', 'The brain'],
    ),
    ('What is the square root of 81?', '9', ['8', '7', '12']),
    (
      'Which continent is Kenya in?',
      'Africa',
      ['Asia', 'Europe', 'South America'],
    ),
    ('What do bees make?', 'Honey', ['Silk', 'Wax only', 'Milk']),
  ];

  late final List<(String, String, List<String>)> _qs = [
    for (var i = 0; i < 3; i++)
      widget.age >= 16 && i < 2 || widget.age >= 12 && widget.age < 16 && i == 0
          ? _fact()
          : _sum(),
  ];
  final _used = <int>{};
  int _i = 0;
  int _right = 0;
  String? _picked;

  (String, String, List<String>) _fact() {
    var k = _rng.nextInt(_facts.length);
    while (_used.contains(k)) {
      k = (k + 1) % _facts.length;
    }
    _used.add(k);
    final (q, a, wrong) = _facts[k];
    return (q, a, [a, ...wrong]..shuffle(_rng));
  }

  (String, String, List<String>) _sum() {
    late String q;
    late int a;
    if (widget.age < 10) {
      final x = 1 + _rng.nextInt(9), y = 1 + _rng.nextInt(9);
      q = '$x + $y = ?';
      a = x + y;
    } else if (widget.age < 16) {
      final x = 2 + _rng.nextInt(11), y = 2 + _rng.nextInt(11);
      q = '$x × $y = ?';
      a = x * y;
    } else {
      final x = 12 + _rng.nextInt(40),
          y = 3 + _rng.nextInt(9),
          z = 2 + _rng.nextInt(20);
      q = '$x × $y − $z = ?';
      a = x * y - z;
    }
    final opts = {a};
    while (opts.length < 4) {
      opts.add(a + _rng.nextInt(11) - 5);
    }
    return (q, '$a', [for (final o in opts) '$o']..shuffle(_rng));
  }

  void _answer(String v) {
    if (_picked != null) return;
    setState(() {
      _picked = v;
      if (v == _qs[_i].$2) _right++;
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _i++;
        _picked = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_i >= _qs.length) {
      return _Done(
        score: _right / 3,
        line: '$_right of 3 correct',
        onDone: widget.onDone,
      );
    }
    final (q, a, opts) = _qs[_i];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Question ${_i + 1} of 3', style: NF.sora(14, color: NF.muted)),
        const SizedBox(height: 10),
        Text(
          q,
          textAlign: TextAlign.center,
          style: NF.sora(q.length > 16 ? 22 : 40, weight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (final o in opts)
              SizedBox(
                width: 140,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(120, 60),
                    backgroundColor: _picked == null
                        ? NF.surface2
                        : (o == a
                              ? const Color(0xFF5EE6A8)
                              : (o == _picked ? NF.danger : NF.surface2)),
                    foregroundColor: _picked != null && (o == a || o == _picked)
                        ? NF.bg
                        : NF.text,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _answer(o),
                  child: Text(
                    o,
                    textAlign: TextAlign.center,
                    style: NF.sora(
                      o.length > 6 ? 15 : 20,
                      weight: FontWeight.w700,
                      color: _picked != null && (o == a || o == _picked)
                          ? NF.bg
                          : NF.text,
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

// ---------------- Timing bar ----------------

class _TimingGame extends StatefulWidget {
  const _TimingGame({
    required this.onDone,
    required this.button,
    required this.zone,
  });
  final void Function(double) onDone;
  final String button;

  /// Width of the green zone (0..1 of the bar).
  final double zone;
  @override
  State<_TimingGame> createState() => _TimingGameState();
}

class _TimingGameState extends State<_TimingGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  late final double _zone = widget.zone;
  late final double _zoneStart =
      0.1 + Random().nextDouble() * (0.85 - widget.zone);
  double? _stoppedAt;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _stop() {
    if (_stoppedAt != null) return;
    _c.stop();
    setState(() => _stoppedAt = _c.value);
  }

  @override
  Widget build(BuildContext context) {
    if (_stoppedAt != null) {
      final hit =
          _stoppedAt! >= _zoneStart && _stoppedAt! <= _zoneStart + _zone;
      return _Done(
        score: hit ? 1 : 0,
        line: hit ? 'Perfect timing.' : 'Missed the window.',
        onDone: widget.onDone,
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return SizedBox(
              height: 56,
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
                    left: w * _zoneStart,
                    width: w * _zone,
                    top: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF5EE6A8).withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _c,
                    builder: (_, _) => Positioned(
                      left: (w - 8) * _c.value,
                      top: 0,
                      bottom: 0,
                      width: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: NF.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        FilledButton(
          style: orangeButton(),
          onPressed: _stop,
          child: Text(widget.button),
        ),
      ],
    );
  }
}

// ---------------- Higher or lower ----------------

class _CardsGame extends StatefulWidget {
  const _CardsGame({required this.onDone});
  final void Function(double) onDone;
  @override
  State<_CardsGame> createState() => _CardsGameState();
}

class _CardsGameState extends State<_CardsGame> {
  final _rng = Random();
  late int _card = 2 + _rng.nextInt(11);
  int _round = 0;
  int _wins = 0;
  String _msg = '';

  static String _name(int v) => switch (v) {
    1 => 'A',
    11 => 'J',
    12 => 'Q',
    13 => 'K',
    _ => '$v',
  };

  void _guess(bool higher) {
    final next = 1 + _rng.nextInt(13);
    final win = next == _card || (higher ? next > _card : next < _card);
    setState(() {
      if (win) _wins++;
      _msg =
          '${_name(next)}: ${win ? 'you win the round' : 'you lose the round'}';
      _card = next;
      _round++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_round >= 3) {
      return _Done(
        score: _wins / 3,
        line: '$_wins of 3 rounds won',
        onDone: widget.onDone,
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Round ${_round + 1} of 3', style: NF.sora(14, color: NF.muted)),
        const SizedBox(height: 14),
        Container(
          width: 120,
          height: 170,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F3EC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _name(_card),
            style: NF.sora(
              52,
              weight: FontWeight.w700,
              color: const Color(0xFF16213A),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(_msg, style: NF.sora(14, color: NF.soft)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              style: primaryButton(),
              onPressed: () => _guess(false),
              child: const Text('Lower'),
            ),
            const SizedBox(width: 12),
            FilledButton(
              style: orangeButton(),
              onPressed: () => _guess(true),
              child: const Text('Higher'),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------- Reaction ----------------

class _ReactionGame extends StatefulWidget {
  const _ReactionGame({
    required this.onDone,
    required this.wait,
    required this.go,
    required this.bonusMs,
  });
  final void Function(double) onDone;
  final String wait;
  final String go;

  /// Extra milliseconds allowed (a high stat is a little more forgiving).
  final int bonusMs;
  @override
  State<_ReactionGame> createState() => _ReactionGameState();
}

class _ReactionGameState extends State<_ReactionGame> {
  bool _green = false;
  DateTime? _greenAt;
  Timer? _t;
  double? _score;
  String _line = '';

  @override
  void initState() {
    super.initState();
    _t = Timer(Duration(milliseconds: 1200 + Random().nextInt(1800)), () {
      if (!mounted) return;
      setState(() {
        _green = true;
        _greenAt = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _tap() {
    if (_score != null) return;
    _t?.cancel();
    if (!_green) {
      setState(() {
        _score = 0;
        _line = 'Too soon! Wait for it.';
      });
      return;
    }
    final ms = DateTime.now().difference(_greenAt!).inMilliseconds;
    setState(() {
      _score = ((900 + widget.bonusMs - ms) / 600).clamp(0.0, 1.0);
      _line = '$ms ms reaction';
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(score: _score!, line: _line, onDone: widget.onDone);
    }
    return GestureDetector(
      onTap: _tap,
      child: Semantics(
        button: true,
        label: _green ? '${widget.go} Tap now' : '${widget.wait} Wait',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _green ? const Color(0xFF2E9E6A) : const Color(0xFF8A2E3A),
            borderRadius: BorderRadius.circular(28),
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _green ? widget.go : widget.wait,
              style: NF.sora(40, weight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- Memory pattern ----------------

class _MemoryGame extends StatefulWidget {
  const _MemoryGame({
    required this.onDone,
    required this.names,
    required this.stepMs,
  });
  final void Function(double) onDone;

  /// What each pad is (notes, plot beats, colours), shown on the pad.
  final List<String> names;

  /// How long each step lights up.
  final int stepMs;
  @override
  State<_MemoryGame> createState() => _MemoryGameState();
}

class _MemoryGameState extends State<_MemoryGame> {
  static const _colors = [
    Color(0xFF7C9CFF),
    Color(0xFFFFB86B),
    Color(0xFF5EE6A8),
    Color(0xFFFF8FC7),
  ];
  final _seq = List.generate(4, (_) => Random().nextInt(4));
  int? _lit;
  bool _showing = true;
  int _pos = 0;
  double? _score;

  @override
  void initState() {
    super.initState();
    _play();
  }

  Future<void> _play() async {
    await Future.delayed(const Duration(milliseconds: 600));
    for (final s in _seq) {
      if (!mounted) return;
      setState(() => _lit = s);
      await Future.delayed(Duration(milliseconds: widget.stepMs));
      if (!mounted) return;
      setState(() => _lit = null);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (mounted) setState(() => _showing = false);
  }

  void _press(int i) {
    if (_showing || _score != null) return;
    if (_seq[_pos] == i) {
      _pos++;
      if (_pos == _seq.length) setState(() => _score = 1);
      setState(() {});
    } else {
      setState(() => _score = _pos / _seq.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(
        score: _score!,
        line: '$_pos of 4 in the right order',
        onDone: widget.onDone,
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _showing ? 'Watch…' : 'Your turn: ${_pos + 1} of 4',
          style: NF.sora(16, color: NF.soft),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (var i = 0; i < 4; i++)
              Semantics(
                button: true,
                label: widget.names[i],
                child: GestureDetector(
                  onTap: () => _press(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 130,
                    height: 130,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _colors[i].withValues(alpha: _lit == i ? 1 : 0.35),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: _lit == i
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
