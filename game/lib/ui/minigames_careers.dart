part of 'minigames.dart';

// Original mini-games for the special careers ("Calling", spec 6.2). Each
// career's played moment is its own design, not a reworded general game:
//
// Decisions against the clock (one shared engine, each with its own rules,
// content and scene):
// - Cold read (actor): read the subtext under each line and pick the delivery.
// - Debate (politician): read the room and pick the rebuttal.
// - Objection (lawyer): check each line of testimony against your notes.
// - Triage (doctor): send each arrival to resus, majors or minors.
// - Diagnose (vet): match two signs to their cause with the handbook.
// - Match day (athlete): find the open teammate, or shoot when it is on.
// - Runway (model): turn to the press pit, then pose to the brief.
// - Obstacle course (armed forces): the right move for each obstacle, faster
//   as you tire.
//
// Played with your hands:
// - Soundcheck (musician): ride four faders to the levels the room needs
//   while the room fills up.
// - Crosswind (pilot): crab into the gusts to stay on the centreline, then
//   flare over the threshold.
// - Pitch (street hustler): call out to the people who are looking, never
//   while an officer is passing.
//
// With Reduce motion or a screen reader every game is turn-based: no
// timers, the same decisions.

bool _turnBasedFor(BuildContext context) {
  final mq = MediaQuery.of(context);
  return mq.disableAnimations || mq.accessibleNavigation;
}

// ---------------- Decisions: the shared engine ----------------

typedef _Call = ({
  String cue,
  String detail,
  List<String> options,
  List<double> worth,
  List<String> replies,
  Object? scene,
});

typedef _Deck = ({String? notes, List<_Call> calls});

_Call _call(
  String cue,
  String detail,
  List<(String, double, String)> options, {
  Object? scene,
}) => (
  cue: cue,
  detail: detail,
  options: [for (final o in options) o.$1],
  worth: [for (final o in options) o.$2],
  replies: [for (final o in options) o.$3],
  scene: scene,
);

/// Paints a call's scene behind its card ([left]: 1 → 0 as time runs out).
typedef _ScenePaint = void Function(Canvas c, Size s, _Call call, double left);

class _DecisionGame extends StatefulWidget {
  const _DecisionGame({
    required this.onDone,
    required this.ease,
    required this.deal,
    required this.seconds,
    required this.verdict,
    this.shrink = 0,
    this.paint,
    this.notesTitle = 'Your notes',
  });
  final void Function(double) onDone;
  final double ease;
  final _Deck Function(Random rng) deal;

  /// Seconds for each call at an average stat, before [shrink].
  final double seconds;

  /// Seconds taken off each later call (fatigue, pressure).
  final double shrink;
  final String Function(double score) verdict;
  final _ScenePaint? paint;
  final String notesTitle;

  @override
  State<_DecisionGame> createState() => _DecisionGameState();
}

class _DecisionGameState extends State<_DecisionGame> with _Ticking {
  late final _Deck _deck = widget.deal(Random());
  int _i = 0;
  double _points = 0, _window = 1, _left = 1;
  bool _turnBased = false, _started = false;
  String _last = '';
  double? _score;

  _Call get _now => _deck.calls[_i];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _turnBased = _turnBasedFor(context);
    if (!_started) {
      _started = true;
      _arm();
      if (!_turnBased) startTicking(_tick);
    }
  }

  void _arm() {
    _window = (widget.seconds * (1 + widget.ease * 0.6) - _i * widget.shrink)
        .clamp(1.4, 20.0);
    _left = _window;
  }

  void _tick(double dt) {
    if (_score != null) return;
    _left -= dt;
    if (_left <= 0) _pick(null);
  }

  void _pick(int? option) {
    if (_score != null) return;
    final call = _now;
    final w = option == null ? 0.0 : call.worth[option];
    _points += w;
    _last = option == null ? 'Too slow.' : call.replies[option];
    if (w >= 0.99) {
      Sound.instance.hit();
    } else {
      Sound.instance.miss();
    }
    if (_i + 1 >= _deck.calls.length) {
      stopTicking();
      final s = (_points / _deck.calls.length).clamp(0.0, 1.0);
      _score = s;
      _last = widget.verdict(s);
      return;
    }
    _i++;
    _arm();
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(score: _score!, line: _last, onDone: widget.onDone);
    }
    final skin = _skinOf(context);
    final call = _now;
    final left = _turnBased ? 1.0 : (_left / _window).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '${_i + 1} of ${_deck.calls.length}',
              style: NF.sora(13, weight: FontWeight.w700, color: NF.muted),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _turnBased
                  ? const SizedBox.shrink()
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: left,
                        minHeight: 8,
                        backgroundColor: skin.panel,
                        color: left < 0.3 ? NF.danger : skin.zone,
                      ),
                    ),
            ),
          ],
        ),
        if (_deck.notes != null) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 76),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: skin.panel,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Text(
                '${widget.notesTitle}: ${_deck.notes}',
                style: NF.sora(13, color: NF.soft, height: 1.35),
              ),
            ),
          ),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: Semantics(
            liveRegion: true,
            label: '${call.cue}. ${call.detail}. $_last',
            child: CustomPaint(
              painter: widget.paint == null
                  ? null
                  : _CallPainter(widget.paint!, call, left),
              child: Align(
                alignment: widget.paint == null
                    ? Alignment.center
                    : Alignment.bottomCenter,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: skin.bottom.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: skin.accent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          call.cue,
                          textAlign: TextAlign.center,
                          style: NF.sora(20, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          call.detail,
                          textAlign: TextAlign.center,
                          style: NF.sora(14, color: NF.soft, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 22,
          child: Text(
            _last,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NF.sora(13, color: skin.accent),
          ),
        ),
        const SizedBox(height: 6),
        // Up to three choices share a row; four make a 2 × 2 grid.
        for (final row
            in call.options.length > 3
                ? [
                    [0, 1],
                    [2, 3],
                  ]
                : [
                    [for (var o = 0; o < call.options.length; o++) o],
                  ]) ...[
          Row(
            children: [
              for (final o in row) ...[
                if (o != row.first) const SizedBox(width: 6),
                Expanded(
                  child: FilledButton(
                    style: _compact(skin),
                    onPressed: () => setState(() => _pick(o)),
                    child: FittedBox(child: Text(call.options[o])),
                  ),
                ),
              ],
            ],
          ),
          if (row.first == 0 && call.options.length > 3)
            const SizedBox(height: 6),
        ],
      ],
    );
  }
}

class _CallPainter extends CustomPainter {
  _CallPainter(this.fn, this.call, this.left);
  final _ScenePaint fn;
  final _Call call;
  final double left;
  @override
  void paint(Canvas c, Size s) => fn(c, s, call, left);
  @override
  bool shouldRepaint(_CallPainter old) => old.call != call || old.left != left;
}

List<T> _shuffled<T>(List<T> items, Random rng) => [...items]..shuffle(rng);

// ---------------- Cold read (actor) ----------------

const _scriptLines = <(String, String, int)>[
  ('"I\'m fine. Really."', 'She has just lost the case. She is not fine.', 0),
  ('"Get out of my house."', 'He has just found the letter.', 2),
  (
    '"The car is outside."',
    'Two strangers are listening at the next table.',
    0,
  ),
  ('"You came back."', 'Ten years apart. No one else in the room.', 0),
  (
    '"Ladies and gentlemen, the winner…"',
    'A packed hall, a live broadcast.',
    2,
  ),
  ('"Pass the salt, please."', 'An ordinary dinner. Nothing is wrong yet.', 1),
  (
    '"We\'re not lost. I know this road."',
    'He is lost, and the kids are in the back.',
    1,
  ),
  ('"I said NO."', 'The third time she has had to say it.', 2),
  ('"It\'s a boy."', 'A tired midwife at 4am, smiling.', 1),
  ('"Don\'t wake the baby."', 'A nursery, lights off.', 0),
];

_Deck _coldRead(Random rng) => (
  notes: null,
  calls: [
    for (final (line, sub, best) in _shuffled(_scriptLines, rng).take(5))
      _call(line, sub, [
        for (final (i, d) in [
          'Hold it back',
          'Play it straight',
          'Let it rip',
        ].indexed)
          (
            d,
            i == best ? 1.0 : ((i - best).abs() == 1 ? 0.35 : 0.0),
            i == best
                ? 'The room goes quiet. That was the read.'
                : (i - best).abs() == 1
                ? '"Fine. Again, but with what\'s underneath."'
                : 'The casting director looks at the clock.',
          ),
      ]),
  ],
);

// ---------------- Debate (politician) ----------------

const _claims = <(String, String, int, int)>[
  // (Their claim, the room, best answer, second best)
  (
    '"Their plan will cost every family more, every year."',
    'The audience looks sceptical of both of you.',
    0,
    3,
  ),
  (
    '"I\'ve met the nurses. They\'re exhausted."',
    'The room is worried, nodding along.',
    1,
    3,
  ),
  (
    '"My opponent has never run anything."',
    'A cheap shot. The room winces.',
    2,
    1,
  ),
  ('"We all want safer streets."', 'A fair point, and the room agrees.', 3, 1),
  (
    '"Crime is up 40% on their watch."',
    'The number sounds wrong, and people know it.',
    0,
    2,
  ),
  (
    '"Ask the families who lost their homes."',
    'The flood was last month. Faces are raw.',
    1,
    3,
  ),
  (
    '"Their own party doesn\'t back them."',
    'A gaffe: they misquoted your leader.',
    2,
    0,
  ),
  (
    '"Schools need more money."',
    'Everyone in the hall agrees with that.',
    3,
    0,
  ),
];
const _rebuttals = [
  'The facts',
  'A real story',
  'Hit back',
  'Agree, then pivot',
];

_Deck _debate(Random rng) => (
  notes: null,
  calls: [
    for (final (claim, room, best, next) in _shuffled(_claims, rng).take(5))
      _call(claim, room, [
        for (final (i, r) in _rebuttals.indexed)
          (
            r,
            i == best ? 1.0 : (i == next ? 0.5 : 0.0),
            i == best
                ? 'Applause. The polls tick your way.'
                : i == next
                ? 'It lands, just.'
                : 'Groans. That was the wrong note.',
          ),
      ]),
  ],
);

// ---------------- Objection (lawyer) ----------------

_Deck _objection(Random rng) {
  final facts = <String, (List<String>, String)>{
    'time': (['9pm', 'midnight', '7am'], 'It happened at %.'),
    'weather': (['raining', 'clear', 'foggy'], 'It was % that night.'),
    'colour': (['red', 'blue', 'white'], 'The car was %.'),
    'place': (
      ['the bus stop', 'the café', 'the corner shop'],
      'I was standing at %.',
    ),
  };
  final truth = {
    for (final k in facts.keys)
      k: facts[k]!.$1[rng.nextInt(facts[k]!.$1.length)],
  };
  final notes =
      'At ${truth['time']}, ${truth['weather']}, a ${truth['colour']} '
      'car, seen from ${truth['place']}.';
  final lines = <(String, bool)>[];
  for (final k in _shuffled(facts.keys.toList(), rng)) {
    final (values, frame) = facts[k]!;
    final lie = rng.nextBool();
    final v = lie
        ? values.where((x) => x != truth[k]).toList()[rng.nextInt(2)]
        : truth[k]!;
    lines.add((frame.replaceFirst('%', v), lie));
  }
  lines.insert(
    rng.nextInt(lines.length),
    rng.nextBool()
        ? ('My neighbour told me he did it.', true)
        : ('I\'m sure. I got a good look at him.', false),
  );
  return (
    notes: notes,
    calls: [
      for (final (line, objectionable) in lines)
        _call('The witness: $line', 'Does it square with your notes?', [
          (
            'Let it stand',
            objectionable ? 0.0 : 1.0,
            objectionable
                ? 'It goes unchallenged. The jury writes it down.'
                : 'Good: you save your objections for when they count.',
          ),
          (
            'Objection!',
            objectionable ? 1.0 : 0.0,
            objectionable
                ? '"Sustained." The jury saw that.'
                : '"Overruled." The judge is losing patience.',
          ),
        ]),
    ],
  );
}

// ---------------- Triage (doctor) ----------------

const _arrivals = <(String, String, int)>[
  // (Who, signs, bay: 0 resus, 1 majors, 2 minors)
  ('Man, 58, grey and sweating', 'Chest pain, pulse 130, breathing fast', 0),
  ('Cyclist, 24', 'Not responding to voice after a fall', 0),
  ('Woman, 71', 'Breathing 34 a minute, lips blue', 0),
  ('Child, 6', 'Swollen face after a bee sting, wheezing', 0),
  ('Woman, 40', 'Chest tightness, normal pulse and breathing', 1),
  ('Man, 30', 'Arm clearly broken, pulse in the hand', 1),
  ('Teen, 16', 'Fever 39.5 and a stiff neck', 0),
  ('Man, 65', 'Fell, hip pain, cannot stand', 1),
  ('Woman, 22', 'Twisted ankle, walking on it', 2),
  ('Boy, 9', 'Small cut on the chin, bleeding stopped', 2),
  ('Man, 45', 'Back pain for a week, walking normally', 2),
  ('Woman, 33', 'Belly pain, vomiting, pulse 110', 1),
];

_Deck _triage(Random rng) => (
  notes: 'Resus: life at risk now. Majors: serious, stable. Minors: can wait.',
  calls: [
    for (final (who, signs, bay) in _shuffled(_arrivals, rng).take(6))
      _call(who, signs, [
        for (final (i, b) in ['Resus', 'Majors', 'Minors'].indexed)
          (
            b,
            i == bay ? 1.0 : (i < bay ? 0.4 : 0.0),
            i == bay
                ? 'Right bay. The charge nurse nods.'
                : i < bay
                ? 'Safe, but you took a bed someone sicker needs.'
                : 'They get worse in the waiting room.',
          ),
      ]),
  ],
);

// ---------------- Diagnose (vet) ----------------

const _causes = <(String, String, String)>[
  ('Sprain', 'Limp', 'Swollen leg'),
  ('Kennel cough', 'Cough', 'Fever'),
  ('Bad tooth', 'Off food', 'Drooling'),
  ('Fleas', 'Itching', 'Hair loss'),
  ('Ate something', 'Vomiting', 'Tired'),
  ('Ear infection', 'Head shaking', 'Smelly ear'),
];
const _animals = [
  'A spaniel',
  'A ginger cat',
  'A rabbit',
  'A sheepdog',
  'A pony',
  'A tabby kitten',
];

_Deck _diagnose(Random rng) => (
  notes: [for (final (c, a, b) in _causes) '$a + $b = $c'].join(' · '),
  calls: [
    for (var i = 0; i < 5; i++)
      () {
        final (cause, a, b) = _causes[rng.nextInt(_causes.length)];
        final wrong = _shuffled(
          _causes.where((x) => x.$1 != cause).map((x) => x.$1).toList(),
          rng,
        ).take(3);
        return _call(
          _animals[rng.nextInt(_animals.length)],
          'Signs: $a, ${b.toLowerCase()}.',
          [
            for (final o in _shuffled([cause, ...wrong], rng))
              (
                o,
                o == cause ? 1.0 : 0.0,
                o == cause
                    ? 'Right. The owner breathes out.'
                    : 'Not that: check the handbook.',
              ),
          ],
        );
      }(),
  ],
);

// ---------------- Match day (athlete) ----------------

typedef _Play = ({List<bool> marked, bool goalOn});

_Deck _matchDay(Random rng) {
  final calls = <_Call>[];
  for (var i = 0; i < 5; i++) {
    final goalOn = rng.nextInt(4) == 0;
    final marked = [rng.nextBool(), rng.nextBool(), rng.nextBool()];
    if (!goalOn && !marked.contains(false)) marked[rng.nextInt(3)] = false;
    final open = [
      for (final (j, m) in marked.indexed)
        if (!m) ['left', 'centre', 'right'][j],
    ];
    calls.add(
      _call(
        goalOn ? 'The keeper is off his line!' : 'You have the ball.',
        goalOn
            ? 'A clear sight of goal.'
            : 'Open: ${open.join(' and ')}. Marked: the rest.',
        [
          for (final (j, side) in [
            'Pass left',
            'Pass centre',
            'Pass right',
          ].indexed)
            (
              side,
              goalOn ? 0.3 : (marked[j] ? 0.0 : 1.0),
              marked[j]
                  ? 'Intercepted.'
                  : goalOn
                  ? 'Safe, but the chance has gone.'
                  : 'Clean pass. The move goes on.',
            ),
          ('Shoot', goalOn ? 1.0 : 0.1, goalOn ? 'GOAL!' : 'Blocked. Wasted.'),
        ],
        scene: (marked: marked, goalOn: goalOn),
      ),
    );
  }
  return (notes: null, calls: calls);
}

void _paintPitch(Canvas c, Size s, _Call call, double left) {
  final play = call.scene as _Play;
  final line = Paint()
    ..color = Colors.white.withValues(alpha: 0.18)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  c.drawRect(Rect.fromLTWH(30, 8, s.width - 60, s.height - 16), line);
  c.drawRect(Rect.fromLTWH(s.width / 2 - 50, 8, 100, 34), line);
  final mate = Paint()..color = const Color(0xFFC6FF4D);
  final foe = Paint()..color = const Color(0xFFFF6B70);
  for (var j = 0; j < 3; j++) {
    final p = Offset(s.width * (0.2 + j * 0.3), s.height * 0.32);
    c.drawCircle(p, 10, mate);
    if (play.marked[j]) c.drawCircle(p + const Offset(14, -10), 10, foe);
  }
  // The keeper.
  c.drawCircle(
    Offset(s.width / 2 + (play.goalOn ? 46 : 0), play.goalOn ? 66 : 30),
    9,
    foe,
  );
  // You.
  c.drawCircle(Offset(s.width / 2, s.height * 0.86), 12, mate);
}

// ---------------- Runway (model) ----------------

const _briefs = ['Fierce', 'Soft', 'Playful'];

_Deck _runway(Random rng) {
  final brief = _briefs[rng.nextInt(3)];
  final calls = <_Call>[];
  for (var i = 0; i < 4; i++) {
    final pit = rng.nextInt(3);
    final shout = (pit + 1 + rng.nextInt(2)) % 3;
    const sides = ['left', 'centre', 'right'];
    calls.add(
      _call(
        'Mark ${i + 1}',
        'The press pit is ${sides[pit]}. Someone shouts from the ${sides[shout]}.',
        [
          for (final (j, t) in [
            'Turn left',
            'Hold centre',
            'Turn right',
          ].indexed)
            (
              t,
              j == pit ? 1.0 : 0.0,
              j == pit
                  ? 'Flashes. That is the shot they will print.'
                  : j == shout
                  ? 'You turned to the wrong voice.'
                  : 'The pit got the back of your head.',
            ),
        ],
        scene: pit,
      ),
    );
  }
  calls.add(
    _call('End of the runway', 'Pose for the designer\'s brief.', [
      for (final b in _briefs)
        (
          b,
          b == brief ? 1.0 : 0.2,
          b == brief ? 'The designer is on their feet.' : 'Not the brief.',
        ),
    ], scene: -1),
  );
  return (notes: 'The brief: $brief.', calls: calls);
}

void _paintRunway(Canvas c, Size s, _Call call, double left) {
  final pit = call.scene as int;
  final w = s.width;
  final path = Path()
    ..moveTo(w * 0.42, 0)
    ..lineTo(w * 0.58, 0)
    ..lineTo(w * 0.72, s.height)
    ..lineTo(w * 0.28, s.height)
    ..close();
  c.drawPath(path, Paint()..color = Colors.white.withValues(alpha: 0.08));
  for (var j = 0; j < 3; j++) {
    final lit = j == pit;
    final x = w * (0.12 + j * 0.38);
    for (var k = 0; k < 3; k++) {
      c.drawCircle(
        Offset(x, s.height * (0.2 + k * 0.25)),
        lit ? 7 : 4,
        Paint()
          ..color = (lit ? Colors.white : Colors.white24).withValues(
            alpha: lit ? 0.4 + 0.6 * ((k + left * 6) % 1) : 0.3,
          ),
      );
    }
  }
}

// ---------------- Obstacle course (armed forces) ----------------

const _obstacles = <(String, String, int)>[
  ('A 2-metre wall', 'Smooth, no footholds.', 0),
  ('A cargo net', 'Hanging off a frame.', 0),
  ('Low barbed wire', 'Knee height, 10 metres long.', 1),
  ('A muddy pipe', 'A tunnel under the track.', 1),
  ('A water ditch', 'Two metres across.', 2),
  ('Hurdles', 'Waist high, three in a row.', 2),
  ('A narrow beam', 'Over a pit of mud.', 3),
  ('A log bridge', 'Wet, and it rolls.', 3),
];
const _moves = ['Climb', 'Crawl', 'Jump', 'Balance'];

_Deck _obstacleCourse(Random rng) => (
  notes: null,
  calls: [
    for (final (o, d, best) in [..._shuffled(_obstacles, rng)].take(7))
      _call(o, d, [
        for (final (i, m) in _moves.indexed)
          (
            m,
            i == best ? 1.0 : 0.0,
            i == best
                ? 'Over it. Keep moving.'
                : 'The instructor yells. Again!',
          ),
      ], scene: best),
  ],
);

void _paintObstacle(Canvas c, Size s, _Call call, double left) {
  final kind = call.scene as int;
  final ground = s.height * 0.78;
  final p = Paint()..color = const Color(0xFF8C9A5B).withValues(alpha: 0.7);
  c.drawLine(
    Offset(0, ground),
    Offset(s.width, ground),
    Paint()
      ..color = Colors.white24
      ..strokeWidth = 2,
  );
  // The obstacle comes closer as time runs out.
  final x = s.width * (0.2 + 0.6 * left);
  switch (kind) {
    case 0:
      c.drawRect(Rect.fromLTWH(x, ground - 90, 26, 90), p);
    case 1:
      for (var i = 0; i < 5; i++) {
        c.drawLine(
          Offset(x + i * 14, ground - 24),
          Offset(x + i * 14 + 10, ground - 30),
          p..strokeWidth = 3,
        );
      }
    case 2:
      c.drawRect(
        Rect.fromLTWH(x, ground - 4, 60, 12),
        Paint()..color = const Color(0xFF4F8FD6).withValues(alpha: 0.7),
      );
    default:
      c.drawRect(Rect.fromLTWH(x, ground - 40, 80, 6), p);
  }
  // The recruit.
  c.drawCircle(Offset(s.width * 0.1, ground - 40), 9, Paint()..color = NF.text);
}

// ---------------- Soundcheck (musician) ----------------

class _SoundcheckGame extends StatefulWidget {
  const _SoundcheckGame({required this.onDone, required this.ease});
  final void Function(double) onDone;
  final double ease;
  @override
  State<_SoundcheckGame> createState() => _SoundcheckGameState();
}

class _SoundcheckGameState extends State<_SoundcheckGame> with _Ticking {
  static const _names = ['Vocals', 'Guitar', 'Bass', 'Drums'];
  static const _seconds = 14.0, _turns = 16;
  final _rng = Random();
  late final _level = List<int>.generate(4, (_) => 5);
  late final _target = List<int>.generate(4, (_) => 2 + _rng.nextInt(7));
  double _sum = 0, _time = 0, _nextDrift = 1.5;
  int _turn = 0;
  bool _turnBased = false, _started = false;
  double? _score;
  String _line = 'Doors open in a minute. Get the mix right.';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _turnBased = _turnBasedFor(context);
    if (!_started) {
      _started = true;
      if (!_turnBased) startTicking(_tick);
    }
  }

  /// 1 when every fader sits on its mark, 0 when the mix is way off.
  double get _quality {
    var err = 0.0;
    for (var i = 0; i < 4; i++) {
      err += (_level[i] - _target[i]).abs();
    }
    return (1 - err / (8 * (1 + widget.ease))).clamp(0.0, 1.0);
  }

  void _drift() {
    final i = _rng.nextInt(4);
    _target[i] =
        (_target[i] + (_rng.nextBool() ? 1 : -1) * (1 + _rng.nextInt(2))).clamp(
          1,
          9,
        );
    _line = '${_names[i]} sounds different now the room is filling up.';
  }

  void _tick(double dt) {
    if (_score != null) return;
    _time += dt;
    _sum += _quality * dt;
    _nextDrift -= dt;
    if (_nextDrift <= 0) {
      _drift();
      _nextDrift = (1.8 - _time / 20).clamp(0.9, 2.0);
    }
    if (_time >= _seconds) _end(_sum / _seconds);
  }

  void _nudge(int i, int by) {
    if (_score != null) return;
    _level[i] = (_level[i] + by).clamp(0, 10);
    Sound.instance.tick();
    if (_turnBased) _turnDone();
  }

  void _turnDone() {
    _turn++;
    _sum += _quality;
    if (_rng.nextInt(3) == 0) _drift();
    if (_turn >= _turns) _end(_sum / _turns);
  }

  void _end(double s) {
    stopTicking();
    _score = s.clamp(0.0, 1.0);
    _line = _score! >= 0.7
        ? 'The engineer gives you a thumbs up. Great mix.'
        : _score! >= 0.4
        ? 'Passable. The vocals got lost in places.'
        : 'Feedback squeals through the PA.';
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(score: _score!, line: _line, onDone: widget.onDone);
    }
    final skin = _skinOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _progress(
          context,
          _turnBased ? 'Turn ${_turn + 1} of $_turns' : 'Doors open',
          _turnBased ? _turn / _turns : _time / _seconds,
        ),
        const SizedBox(height: 6),
        _progress(context, 'The mix', _quality, color: skin.accent),
        const SizedBox(height: 10),
        Expanded(
          child: Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Semantics(
                    label: '${_names[i]}: at ${_level[i]}, needs ${_target[i]}',
                    child: Column(
                      children: [
                        IconButton(
                          tooltip: '${_names[i]} up',
                          onPressed: () => setState(() => _nudge(i, 1)),
                          icon: const Icon(Icons.keyboard_arrow_up_rounded),
                        ),
                        Expanded(
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _FaderPainter(
                              level: _level[i] / 10,
                              target: _target[i] / 10,
                              color: skin.pads[i % skin.pads.length],
                              panel: skin.panel,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: '${_names[i]} down',
                          onPressed: () => setState(() => _nudge(i, -1)),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        ),
                        FittedBox(
                          child: Text(
                            _names[i],
                            style: NF.sora(13, weight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _line,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: NF.sora(13, color: NF.soft),
        ),
        if (_turnBased) ...[
          const SizedBox(height: 6),
          FilledButton(
            style: _compact(skin),
            onPressed: () => setState(_turnDone),
            child: const Text('Leave it'),
          ),
        ],
      ],
    );
  }
}

class _FaderPainter extends CustomPainter {
  _FaderPainter({
    required this.level,
    required this.target,
    required this.color,
    required this.panel,
  });
  final double level, target;
  final Color color, panel;

  @override
  void paint(Canvas c, Size s) {
    final x = s.width / 2;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x, s.height / 2),
          width: 10,
          height: s.height,
        ),
        const Radius.circular(5),
      ),
      Paint()..color = panel,
    );
    // Where the room needs it.
    final ty = s.height * (1 - target);
    c.drawLine(
      Offset(x - 22, ty),
      Offset(x + 22, ty),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 2,
    );
    // The fader cap.
    final ly = s.height * (1 - level);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, ly), width: 34, height: 16),
        const Radius.circular(4),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_FaderPainter old) =>
      old.level != level || old.target != target;
}

// ---------------- Crosswind landing (pilot) ----------------

class _CrosswindGame extends StatefulWidget {
  const _CrosswindGame({required this.onDone, required this.ease});
  final void Function(double) onDone;
  final double ease;
  @override
  State<_CrosswindGame> createState() => _CrosswindGameState();
}

class _CrosswindGameState extends State<_CrosswindGame> with _Ticking {
  static const _seconds = 10.0, _steps = 10;
  final _rng = Random();
  late final double _phase = _rng.nextDouble() * 6;
  late final List<double> _gusts = [
    for (var i = 0; i < _steps; i++)
      (_rng.nextBool() ? 1 : -1) * (_rng.nextBool() ? 0.12 : 0.24),
  ];
  double _x = 0, _t = 0, _align = 0, _steer = 0;
  int _step = 0;
  double? _flareAt, _score;
  bool _turnBased = false, _started = false;
  String _line = 'Wind from the side. Keep her on the centreline.';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _turnBased = _turnBasedFor(context);
    if (!_started) {
      _started = true;
      if (!_turnBased) startTicking(_tick);
    }
  }

  /// Height above the runway, 1 at the start of the approach.
  double get _height =>
      _turnBased ? 1 - _step / _steps : (1 - _t / _seconds).clamp(0.0, 1.0);

  double get _wind => _turnBased
      ? (_step < _steps ? _gusts[_step] : 0)
      : 0.5 * sin(_t * 1.3 + _phase) + 0.35 * sin(_t * 3.1 + _phase * 2);

  void _tick(double dt) {
    if (_score != null) return;
    _t += dt;
    _x += (_wind * 0.55 + _steer * 0.6) * dt * (1 - widget.ease * 0.4);
    _align += (1 - _x.abs().clamp(0.0, 1.0)) * dt;
    if (_x.abs() > 1) {
      _land(goAround: true);
    } else if (_t >= _seconds) {
      _land();
    }
  }

  void _turn(int steer) {
    _x += _gusts[_step] + steer * 0.18;
    _align += 1 - _x.abs().clamp(0.0, 1.0);
    _step++;
    Sound.instance.tick();
    if (_x.abs() > 1) {
      _land(goAround: true);
    } else if (_step >= _steps) {
      _land();
    }
  }

  void _flare() {
    if (_flareAt != null || _score != null) return;
    _flareAt = _height;
    _line = 'Flare.';
    Sound.instance.hit();
    if (_turnBased) _turn(0);
  }

  void _land({bool goAround = false}) {
    stopTicking();
    final align = _turnBased ? _align / max(1, _step) : _align / max(0.1, _t);
    final f = _flareAt;
    final flare = f == null
        ? 0.0
        : (f >= 0.05 && f <= 0.25)
        ? 1.0
        : (f < 0.4 ? 0.5 : 0.1);
    final s = goAround
        ? 0.15
        : (align * 0.7 + flare * 0.3).clamp(0.0, 1.0).toDouble();
    _score = s;
    _line = goAround
        ? 'Too far off the centreline. Go around.'
        : f == null
        ? 'You never flared. A hard landing, and a long talk with the captain.'
        : s >= 0.75
        ? 'Greaser. The cabin claps.'
        : s >= 0.45
        ? 'Down, a little firm.'
        : 'Down, but the training captain wrote a lot.';
    if (goAround) Sound.instance.miss();
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(score: _score!, line: _line, onDone: widget.onDone);
    }
    final skin = _skinOf(context);
    final windWord = _wind.abs() < 0.05
        ? 'calm'
        : '${_wind.abs() > 0.2 ? 'strong' : 'light'} gust from the ${_wind > 0 ? 'left' : 'right'}';
    final canFlare = _height < 0.45;
    Widget steerButton(String label, int dir) => Expanded(
      child: _turnBased
          ? FilledButton(
              style: _compact(skin),
              onPressed: () => setState(() => _turn(dir)),
              child: FittedBox(child: Text(label)),
            )
          : Listener(
              onPointerDown: (_) => _steer = dir.toDouble(),
              onPointerUp: (_) => _steer = 0,
              onPointerCancel: (_) => _steer = 0,
              child: FilledButton(
                style: _compact(skin),
                onPressed: () {},
                child: FittedBox(child: Text(label)),
              ),
            ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _progress(context, 'Height', _height),
        const SizedBox(height: 6),
        Text(
          'Wind: $windWord',
          style: NF.sora(13, weight: FontWeight.w700, color: NF.muted),
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            label:
                'You are ${_x.abs() < 0.15 ? 'on the centreline' : '${(_x.abs() * 100).round()}% ${_x > 0 ? 'right' : 'left'} of it'}. Wind: $windWord.',
            child: CustomPaint(
              size: Size.infinite,
              painter: _RunwayPainter(
                x: _x,
                height: _height,
                accent: skin.accent,
              ),
            ),
          ),
        ),
        Text(
          _line,
          textAlign: TextAlign.center,
          style: NF.sora(13, color: NF.soft),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            steerButton('Steer left', -1),
            const SizedBox(width: 8),
            if (_turnBased) ...[
              Expanded(
                child: FilledButton(
                  style: _compact(skin),
                  onPressed: () => setState(() => _turn(0)),
                  child: const FittedBox(child: Text('Hold')),
                ),
              ),
              const SizedBox(width: 8),
            ],
            steerButton('Steer right', 1),
          ],
        ),
        const SizedBox(height: 6),
        FilledButton(
          style: _compact(skin),
          onPressed: canFlare ? () => setState(_flare) : null,
          child: const Text('Flare'),
        ),
      ],
    );
  }
}

class _RunwayPainter extends CustomPainter {
  _RunwayPainter({required this.x, required this.height, required this.accent});
  final double x, height;
  final Color accent;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    // The runway grows as you descend.
    final near = 0.3 + 0.6 * (1 - height);
    final top = h * (0.15 + 0.35 * (1 - height));
    final path = Path()
      ..moveTo(w / 2 - w * near * 0.18, top)
      ..lineTo(w / 2 + w * near * 0.18, top)
      ..lineTo(w / 2 + w * near * 0.5, h)
      ..lineTo(w / 2 - w * near * 0.5, h)
      ..close();
    c.drawPath(path, Paint()..color = const Color(0xFF2A2F3A));
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 3;
    for (var y = top + 10; y < h; y += 26) {
      c.drawLine(Offset(w / 2, y), Offset(w / 2, y + 12), dash);
    }
    // The aircraft, seen from behind.
    final px = w / 2 + x * w * 0.4, py = h * 0.62;
    final plane = Paint()..color = accent;
    c.drawRect(
      Rect.fromCenter(center: Offset(px, py), width: 90, height: 6),
      plane,
    );
    c.drawRect(
      Rect.fromCenter(center: Offset(px, py - 8), width: 8, height: 24),
      plane,
    );
  }

  @override
  bool shouldRepaint(_RunwayPainter old) => old.x != x || old.height != height;
}

// ---------------- Pitch (street hustler) ----------------

class _Walker {
  _Walker(this.x, this.dir, this.kind, this.speed);
  double x;
  final double dir, speed;

  /// 'look' (interested), 'pass' (busy) or 'cop'.
  final String kind;
}

class _PitchGame extends StatefulWidget {
  const _PitchGame({required this.onDone, required this.ease});
  final void Function(double) onDone;
  final double ease;
  @override
  State<_PitchGame> createState() => _PitchGameState();
}

class _PitchGameState extends State<_PitchGame> with _Ticking {
  static const _seconds = 16.0, _turns = 24;
  final _rng = Random();
  final _walkers = <_Walker>[];
  double _t = 0, _spawn = 0, _cooldown = 0;
  int _crowd = 0, _turn = 0;
  bool _turnBased = false, _started = false, _fined = false;
  double? _score;
  String _line = 'A good corner. Call out to people who are looking.';

  int get _target => (7 - widget.ease * 4).round();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _turnBased = _turnBasedFor(context);
    if (!_started) {
      _started = true;
      for (var i = 0; i < 3; i++) {
        _add(-0.9 + i * 0.6);
      }
      if (!_turnBased) startTicking(_tick);
    }
  }

  void _add([double? at]) {
    final r = _rng.nextInt(10);
    final kind = r < 4 ? 'look' : (r < 9 ? 'pass' : 'cop');
    final dir = _rng.nextBool() ? 1.0 : -1.0;
    _walkers.add(
      _Walker(at ?? -1.1 * dir, dir, kind, 0.22 + _rng.nextDouble() * 0.18),
    );
  }

  void _move(double dt) {
    for (final w in _walkers) {
      w.x += w.dir * w.speed * dt;
    }
    _walkers.removeWhere((w) => w.x.abs() > 1.2);
  }

  void _tick(double dt) {
    if (_score != null) return;
    _t += dt;
    _cooldown -= dt;
    _move(dt);
    _spawn -= dt;
    if (_spawn <= 0) {
      _add();
      _spawn = 0.7 + _rng.nextDouble() * 0.6;
    }
    if (_t >= _seconds) _end();
  }

  void _wait() {
    _turn++;
    _move(0.55);
    if (_rng.nextInt(3) > 0) _add();
    if (_turn >= _turns) _end();
  }

  bool _inPitch(_Walker w) => w.x.abs() < 0.2;

  void _callOut() {
    if (_score != null || (!_turnBased && _cooldown > 0)) return;
    _cooldown = 0.5;
    final here = _walkers.where(_inPitch).toList();
    if (here.any((w) => w.kind == 'cop')) {
      _crowd = max(0, _crowd - 2);
      _fined = true;
      _line = 'An officer moves you on. The crowd drifts away.';
      Sound.instance.miss();
    } else if (here.any((w) => w.kind == 'look')) {
      final w = here.firstWhere((w) => w.kind == 'look');
      _walkers.remove(w);
      _crowd++;
      _line = 'They stop and watch. Crowd: $_crowd.';
      Sound.instance.hit();
    } else {
      _line = here.isEmpty
          ? 'You called to an empty pavement.'
          : 'They are in a hurry. They walk on.';
      Sound.instance.miss();
    }
    if (_turnBased) _wait();
  }

  void _end() {
    stopTicking();
    final s = (_crowd / _target).clamp(0.0, 1.0) * (_fined ? 0.8 : 1.0);
    _score = s;
    _line = s >= 0.75
        ? 'A proper crowd. The hat is heavy.'
        : s >= 0.4
        ? 'A few coins and a couple of fans.'
        : 'Nobody stopped. Tomorrow, maybe.';
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(score: _score!, line: _line, onDone: widget.onDone);
    }
    final skin = _skinOf(context);
    final here = _walkers.where(_inPitch).map((w) => w.kind).toSet();
    final say = here.contains('cop')
        ? 'An officer is passing your pitch.'
        : here.contains('look')
        ? 'Someone in your pitch is looking your way.'
        : here.isEmpty
        ? 'Nobody in your pitch.'
        : 'Busy people in your pitch.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _progress(
          context,
          _turnBased ? 'Turn ${_turn + 1} of $_turns' : 'Rush hour',
          _turnBased ? _turn / _turns : _t / _seconds,
        ),
        const SizedBox(height: 6),
        _progress(
          context,
          'Crowd $_crowd',
          _crowd / _target,
          color: skin.accent,
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            label: say,
            child: CustomPaint(
              size: Size.infinite,
              painter: _StreetPainter(_walkers, skin.zone),
            ),
          ),
        ),
        Text(
          _line,
          textAlign: TextAlign.center,
          style: NF.sora(13, color: NF.soft),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: FilledButton(
                style: _compact(skin),
                onPressed: () => setState(_callOut),
                child: const FittedBox(child: Text('Call out')),
              ),
            ),
            if (_turnBased) ...[
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: _compact(skin),
                  onPressed: () => setState(_wait),
                  child: const FittedBox(child: Text('Wait')),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _StreetPainter extends CustomPainter {
  _StreetPainter(this.walkers, this.zone);
  final List<_Walker> walkers;
  final Color zone;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, y = s.height * 0.55;
    // Pavement and your pitch.
    c.drawRect(
      Rect.fromLTWH(0, y - 40, w, 80),
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );
    c.drawOval(
      Rect.fromCenter(center: Offset(w / 2, y), width: w * 0.4, height: 70),
      Paint()
        ..color = zone.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    for (final p in walkers) {
      final pos = Offset(w / 2 + p.x * w / 2, y);
      final color = switch (p.kind) {
        'cop' => const Color(0xFF5C9BFF),
        'look' => const Color(0xFFFFD45E),
        _ => Colors.white54,
      };
      c.drawCircle(pos - const Offset(0, 18), 8, Paint()..color = color);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: pos + const Offset(0, 4),
            width: 14,
            height: 26,
          ),
          const Radius.circular(6),
        ),
        Paint()..color = color,
      );
      if (p.kind == 'look') {
        c.drawCircle(pos - const Offset(0, 36), 4, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(_StreetPainter old) => true;
}

// ---------------- Wiring ----------------

/// The career games built on the decision engine, by game id.
Widget? _careerGame(String id, void Function(double) finish, double ease) =>
    switch (id) {
      'coldread' => _DecisionGame(
        onDone: finish,
        ease: ease,
        deal: _coldRead,
        seconds: 6,
        verdict: (s) => s >= 0.7
            ? '"Thank you. We\'ll be in touch." They mean it.'
            : s >= 0.4
            ? '"Thanks for coming in."'
            : '"Next!"',
      ),
      'debate' => _DecisionGame(
        onDone: finish,
        ease: ease,
        deal: _debate,
        seconds: 7,
        verdict: (s) => s >= 0.7
            ? 'The snap poll says you won the night.'
            : s >= 0.4
            ? 'A draw, say the pundits.'
            : 'The clips doing the rounds are not kind.',
      ),
      'objection' => _DecisionGame(
        onDone: finish,
        ease: ease,
        deal: _objection,
        seconds: 6,
        verdict: (s) => s >= 0.7
            ? 'The witness is rattled. The jury noticed.'
            : s >= 0.4
            ? 'Some points scored, some missed.'
            : 'Their story stood up, and the judge is irritated.',
      ),
      'triage' => _DecisionGame(
        onDone: finish,
        ease: ease,
        deal: _triage,
        seconds: 6,
        shrink: 0.4,
        verdict: (s) => s >= 0.7
            ? 'A hard shift, and everyone is where they should be.'
            : s >= 0.4
            ? 'You kept up, mostly.'
            : 'The waiting room is a problem, and it is yours.',
      ),
      'diagnose' => _DecisionGame(
        onDone: finish,
        ease: ease,
        deal: _diagnose,
        seconds: 8,
        notesTitle: 'Handbook',
        verdict: (s) => s >= 0.7
            ? 'Five patients, five right calls.'
            : s >= 0.4
            ? 'Most of them, right.'
            : 'Owners are asking for a second opinion.',
      ),
      'matchday' => _DecisionGame(
        onDone: finish,
        ease: ease,
        deal: _matchDay,
        seconds: 3.5,
        paint: _paintPitch,
        verdict: (s) => s >= 0.7
            ? 'Player of the match.'
            : s >= 0.4
            ? 'A solid shift.'
            : 'Subbed off at half-time.',
      ),
      'runway' => _DecisionGame(
        onDone: finish,
        ease: ease,
        deal: _runway,
        seconds: 4,
        paint: _paintRunway,
        notesTitle: 'Backstage',
        verdict: (s) => s >= 0.7
            ? 'Booked on the spot.'
            : s >= 0.4
            ? '"We\'ll let your agency know."'
            : 'Not this season.',
      ),
      'obstacle' => _DecisionGame(
        onDone: finish,
        ease: ease,
        deal: _obstacleCourse,
        seconds: 3.6,
        shrink: 0.3,
        paint: _paintObstacle,
        verdict: (s) => s >= 0.7
            ? 'Top time of the intake.'
            : s >= 0.4
            ? 'Through, with mud in your ears.'
            : 'Back to the start, recruit.',
      ),
      'soundcheck' => _SoundcheckGame(onDone: finish, ease: ease),
      'crosswind' => _CrosswindGame(onDone: finish, ease: ease),
      'pitch' => _PitchGame(onDone: finish, ease: ease),
      _ => null,
    };
