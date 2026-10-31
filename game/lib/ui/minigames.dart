import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../sound.dart';
import '../theme.dart';

part 'minigame_skins.dart';
part 'minigames_more.dart';

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
  String? game,
}) {
  id = game ?? pickMiniGame(activity, id);
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
        intro: miniIntro(activity, id),
        activity: activity,
      ),
    ),
  );
}

/// The games each activity rotates between, so the same activity is not
/// always the same game.
const miniPools = <String, List<String>>{
  'study': ['quiz', 'words'],
  'gym': ['reps', 'whack'],
  'shoplift': ['sneak', 'timing'],
  'pickpocket': ['sneak', 'timing'],
  'reflect': ['breath', 'balance'],
  'yoga': ['balance', 'breath', 'timing'],
  'casino': ['blackjack', 'cards'],
  'instrument': ['rhythm', 'memory'],
  'write_song': ['rhythm', 'memory'],
  'write_story': ['words', 'memory'],
  'video_games': ['whack', 'lanes', 'reaction'],
  'driving_lessons': ['lanes', 'reaction'],
};

final _lastGame = <String, String>{};
final _pickRng = Random();

/// A game for [activity], never the one played there last time.
String pickMiniGame(String? activity, String fallback) {
  final pool = miniPools[activity];
  if (activity == null || pool == null || pool.isEmpty) return fallback;
  final options = pool.where((g) => g != _lastGame[activity]).toList();
  final g = options[_pickRng.nextInt(options.length)];
  _lastGame[activity] = g;
  return g;
}

/// Instructions for one game, worded for the activity.
String miniIntro(String? activity, String game) =>
    _intros[activity]?[game] ??
    (activity != null && miniPools[activity]?.first == game
        ? miniThemes[activity]?.intro
        : null) ??
    _defaults[game]!.intro;

const _intros = <String, Map<String, String>>{
  'study': {
    'words':
        'Unscramble three words from today\'s lessons before time runs out.',
  },
  'gym': {'whack': 'Hit the pads as they light up. Leave the grey ones alone.'},
  'shoplift': {
    'sneak': 'Hold to edge closer, but only while the guard looks away.',
    'timing': 'The guard keeps glancing over. Grab it while the marker is in the blind spot. Three tries, each faster.',
  },
  'pickpocket': {
    'sneak': 'Hold to get closer while they are distracted. Freeze when they look round.',
    'timing': 'Wait for the crowd to jostle. Lift the wallet while the marker is in the green. Three tries, each faster.',
  },
  'reflect': {
    'breath': 'Hold to breathe in. Let go when your breath reaches the ring. Three breaths.',
    'balance':
        'Keep your thoughts centred: nudge the marker back into the calm zone.',
  },
  'yoga': {
    'balance': 'Hold the pose: nudge left and right to stay in the steady zone for 8 seconds.',
    'breath': 'Breathe with the pose. Hold to breathe in, let go at the ring.',
    'timing': 'Find your balance: tap while the marker is in the steady zone. Three poses, each harder.',
  },
  'casino': {
    'blackjack': 'Blackjack: three hands against the dealer. Get closer to 21 without going over.',
    'cards': 'Higher or lower: five cards. A streak pays best.',
  },
  'write_song': {
    'rhythm': 'Find the groove: tap each part as it lights up, on the beat.',
    'memory': 'Remember the song\'s structure, then play it back. Each round adds a part.',
  },
  'instrument': {
    'rhythm': 'Play along: tap each pad as it lights up, on the beat. The song speeds up.',
    'memory':
        'Listen to the melody, then play it back. Each round adds a note.',
  },
  'write_story': {
    'words': 'Unscramble three words for your story before the ink dries.',
    'memory': 'Remember the plot beats, then write them in order. Each round adds a beat.',
  },
  'video_games': {
    'whack': 'Enemies pop up: tap them fast. Do not shoot your teammates (the grey ones).',
    'lanes': 'Dodge the asteroids: move left and right for 12 seconds.',
    'reaction': 'Final boss, three rounds. Fire the moment the target lights up, not on the fake-outs.',
  },
  'driving_lessons': {
    'lanes': 'Stay in your lane, then change lanes to miss the cones. Three hits and you fail.',
    'reaction': 'The light is red. Brake the moment it turns green. Three junctions, and watch for amber.',
  },
};

/// Words for the unscramble game, by activity.
const _wordLists = <String, List<String>>{
  'study': [
    'atom',
    'verb',
    'graph',
    'planet',
    'fraction',
    'history',
    'energy',
    'climate',
    'equation',
    'poem',
    'magnet',
    'theory',
  ],
  'write_story': [
    'hero',
    'secret',
    'twist',
    'villain',
    'castle',
    'letter',
    'storm',
    'ending',
    'mystery',
    'journey',
    'promise',
    'shadow',
  ],
};

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
  'sneak': _t('Hold to move, but only while nobody is looking.'),
  'balance': _t('Nudge left and right to keep the marker in the middle.'),
  'breath': _t('Hold to breathe in, let go at the ring.'),
  'blackjack': _t('Blackjack: get closer to 21 than the dealer.'),
  'lanes': _t('Move left and right to dodge what comes at you.'),
  'whack': _t('Tap the targets as they pop up. Not the grey ones.'),
  'rhythm': _t('Tap each pad as it lights up, on the beat.'),
  'words': _t('Unscramble the words before time runs out.'),
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
  'write_song': _t(
    'Find the groove: tap each part as it lights up, on the beat.',
    pads: ['Verse', 'Chorus', 'Bridge', 'Hook'],
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
    required this.intro,
    this.activity,
  });
  final String id;
  final int age;
  final String title;
  final MiniTheme theme;
  final String intro;
  final String? activity;

  /// −0.5 (the stat is far below average) to 0.5 (far above).
  final double ease;

  @override
  Widget build(BuildContext context) {
    void finish(double s) => Navigator.of(context).pop(s);
    final instructions = intro;
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
      'sneak' => _SneakGame(onDone: finish, button: theme.button, ease: ease),
      'balance' => _BalanceGame(onDone: finish, ease: ease),
      'breath' => _BreathGame(onDone: finish, ease: ease),
      'blackjack' => _BlackjackGame(onDone: finish),
      'lanes' => _LanesGame(
        onDone: finish,
        ease: ease,
        hazard: skinFor(activity).hazard,
      ),
      'whack' => _WhackGame(
        onDone: finish,
        ease: ease,
        target: skinFor(activity).target,
        decoy: skinFor(activity).decoy,
      ),
      'rhythm' => _RhythmGame(onDone: finish, names: theme.pads, ease: ease),
      'words' => _WordsGame(
        onDone: finish,
        words: _wordLists[activity] ?? _wordLists['study']!,
        ease: ease,
      ),
      _ => const SizedBox.shrink(),
    };
    final skin = skinFor(activity);
    return Scaffold(
      backgroundColor: skin.bottom,
      body: _SkinScope(
        skin: skin,
        child: CustomPaint(
          painter: _ScenePainter(skin),
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
      ),
    );
  }
}

/// Shows the score and a Continue button once a game ends.
class _Done extends StatefulWidget {
  const _Done({required this.score, required this.line, required this.onDone});
  final double score;
  final String line;
  final void Function(double) onDone;

  @override
  State<_Done> createState() => _DoneState();
}

class _DoneState extends State<_Done> {
  @override
  void initState() {
    super.initState();
    Sound.instance.gameOver(widget.score);
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.score;
    final line = widget.line;
    final onDone = widget.onDone;
    final pct = (score * 100).round();
    final color = score >= 0.7
        ? _skinOf(context).zone
        : (score >= 0.4 ? _skinOf(context).accent : NF.danger);
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
          style: _skinOf(context).button(),
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
    Sound.instance.tick();
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
        _Barbell(lift: min(1.0, _taps / widget.target)),
        Text('$_taps', style: NF.sora(56, weight: FontWeight.w700)),
        Text(
          _t == null ? 'Tap to start' : '${_left.toStringAsFixed(1)} s left',
          style: NF.sora(15, color: NF.muted),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: 160,
          height: 160,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _skinOf(context).accent,
              foregroundColor: _skinOf(context).onAccent,
              shape: const CircleBorder(),
            ),
            onPressed: _tap,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.button,
                style: NF.sora(
                  28,
                  weight: FontWeight.w700,
                  color: _skinOf(context).onAccent,
                ),
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
    ('How many legs does a spider have?', '8', ['6', '10', '12']),
    ('What is the capital of Japan?', 'Tokyo', ['Kyoto', 'Osaka', 'Seoul']),
    ('Which is a mammal?', 'Dolphin', ['Shark', 'Trout', 'Octopus']),
    ('What is 3 squared?', '9', ['6', '8', '12']),
    (
      'Which colour do blue and yellow make?',
      'Green',
      ['Purple', 'Orange', 'Brown'],
    ),
    ('How many minutes are in two hours?', '120', ['100', '90', '140']),
    ('What is the opposite of "ancient"?', 'Modern', ['Old', 'Huge', 'Rare']),
    (
      'Which planet has rings you can see?',
      'Saturn',
      ['Mars', 'Mercury', 'Venus'],
    ),
    ('What is a baby frog called?', 'Tadpole', ['Cub', 'Kid', 'Fry']),
    (
      'Who painted the Mona Lisa?',
      'Leonardo da Vinci',
      ['Picasso', 'Van Gogh', 'Monet'],
    ),
    ('How many continents are there?', '7', ['5', '6', '8']),
    (
      'What is the hardest natural material?',
      'Diamond',
      ['Gold', 'Iron', 'Granite'],
    ),
    (
      'What is the longest river in Africa?',
      'The Nile',
      ['The Congo', 'The Niger', 'The Zambezi'],
    ),
    (
      'What do you call a shape with 8 sides?',
      'Octagon',
      ['Hexagon', 'Pentagon', 'Decagon'],
    ),
    ('What is 1/4 as a percentage?', '25%', ['20%', '40%', '75%']),
    (
      'Which gas do we breathe out?',
      'Carbon dioxide',
      ['Oxygen', 'Hydrogen', 'Neon'],
    ),
    (
      'Which bone protects the brain?',
      'The skull',
      ['The spine', 'The ribs', 'The pelvis'],
    ),
    (
      'What is the freezing point of water?',
      '0 °C',
      ['10 °C', '−10 °C', '4 °C'],
    ),
    ('Which is the smallest prime number?', '2', ['1', '3', '5']),
    (
      'Who developed the theory of relativity?',
      'Einstein',
      ['Newton', 'Darwin', 'Curie'],
    ),
    ('What is the plural of "mouse"?', 'Mice', ['Mouses', 'Meese', 'Mousen']),
    (
      'In which country are the pyramids of Giza?',
      'Egypt',
      ['Mexico', 'Peru', 'Greece'],
    ),
    ('What is 7 × 8?', '56', ['54', '48', '64']),
    ('Which instrument has 88 keys?', 'Piano', ['Organ', 'Harp', 'Accordion']),
    (
      'What does a thermometer measure?',
      'Temperature',
      ['Weight', 'Speed', 'Pressure'],
    ),
    ('How many days are in a leap year?', '366', ['365', '364', '360']),
    ('What is the largest planet?', 'Jupiter', ['Saturn', 'Neptune', 'Earth']),
  ];

  /// Facts already asked this session, so quizzes do not repeat.
  static final _asked = <int>{};

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
    if (_asked.length >= _facts.length - 3) _asked.clear();
    var k = _rng.nextInt(_facts.length);
    while (_used.contains(k) || _asked.contains(k)) {
      k = (k + 1) % _facts.length;
    }
    _used.add(k);
    _asked.add(k);
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
                        ? _skinOf(context).panel
                        : (o == a
                              ? _skinOf(context).zone
                              : (o == _picked
                                    ? NF.danger
                                    : _skinOf(context).panel)),
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
  // Three rounds: each one faster, with a narrower window in a new place.
  static const _rounds = 3;
  final _rng = Random();
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);
  int _round = 0;
  int _hits = 0;
  bool _paused = false;
  String _msg = '';
  late double _zone = widget.zone;
  late double _zoneStart = _place();

  double _place() => 0.05 + _rng.nextDouble() * (0.9 - _zone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _stop() {
    if (_paused || _round >= _rounds) return;
    _c.stop();
    final v = _c.value;
    final hit = v >= _zoneStart && v <= _zoneStart + _zone;
    hit ? Sound.instance.hit() : Sound.instance.miss();
    setState(() {
      if (hit) _hits++;
      _msg = hit ? 'In the window!' : 'Missed.';
      _paused = true;
    });
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      setState(() {
        _round++;
        _paused = false;
        if (_round >= _rounds) return;
        _zone = max(0.07, _zone * 0.75);
        _zoneStart = _place();
        _c.duration = Duration(milliseconds: 1100 - _round * 250);
        _c.repeat(reverse: true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_round >= _rounds) {
      return _Done(
        score: _hits / _rounds,
        line: _hits == _rounds
            ? 'Perfect timing, every time.'
            : '$_hits of $_rounds in the window',
        onDone: widget.onDone,
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Try ${_round + 1} of $_rounds${_msg.isEmpty ? '' : ' · $_msg'}',
          style: NF.sora(14, color: NF.muted),
        ),
        const SizedBox(height: 14),
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
                        color: _skinOf(context).panel,
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
                        color: _skinOf(context).zone.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _c,
                    // The marker carries the activity's icon (a bag, a
                    // wallet, a pose) when it has one.
                    builder: (_, _) {
                      final k = _skinOf(context);
                      final mw = k.marker == null ? 8.0 : 40.0;
                      return Positioned(
                        left: (w - mw) * _c.value,
                        top: 0,
                        bottom: 0,
                        width: mw,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: k.accent,
                            borderRadius: BorderRadius.circular(
                              k.marker == null ? 4 : 12,
                            ),
                          ),
                          child: k.marker == null
                              ? null
                              : Icon(k.marker, color: k.onAccent, size: 26),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        FilledButton(
          style: _skinOf(context).button(),
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
  static const _rounds = 5;
  int _round = 0;
  int _wins = 0;
  int _streak = 0;
  int _best = 0;
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
    win ? Sound.instance.hit() : Sound.instance.miss();
    setState(() {
      if (win) {
        _wins++;
        _best = max(_best, ++_streak);
      } else {
        _streak = 0;
      }
      _msg =
          '${_name(next)}: ${win ? 'you win the round' : 'you lose the round'}';
      _card = next;
      _round++;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_round >= _rounds) {
      // A run of wins pays a little extra.
      return _Done(
        score: ((_wins + (_best >= 3 ? 1 : 0)) / _rounds).clamp(0.0, 1.0),
        line: '$_wins of $_rounds right · best streak $_best',
        onDone: widget.onDone,
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Card ${_round + 1} of $_rounds${_streak >= 2 ? ' · streak $_streak' : ''}',
          style: NF.sora(14, color: NF.muted),
        ),
        const SizedBox(height: 14),
        _PlayingCard(
          rank: _name(_card),
          suit: (_card + _round) % 4,
          width: 120,
        ),
        const SizedBox(height: 12),
        Text(_msg, style: NF.sora(14, color: NF.soft)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton(
              style: _skinOf(context).button(),
              onPressed: () => _guess(false),
              child: const Text('Lower'),
            ),
            const SizedBox(width: 12),
            FilledButton(
              style: _skinOf(context).button(),
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
  // Three rounds; sometimes the light flashes amber first. Tapping on amber
  // or red counts as a false start.
  static const _rounds = 3;
  final _rng = Random();
  String _light = 'red';
  DateTime? _greenAt;
  Timer? _t;
  int _round = 0;
  final _scores = <double>[];
  String _line = '';

  @override
  void initState() {
    super.initState();
    _arm();
  }

  void _arm() {
    _light = 'red';
    final wait = 1000 + _rng.nextInt(1800);
    final fake = _round > 0 && _rng.nextInt(100) < 50;
    _t = Timer(Duration(milliseconds: fake ? wait ~/ 2 : wait), () {
      if (!mounted) return;
      if (fake) {
        setState(() => _light = 'amber');
        _t = Timer(Duration(milliseconds: 500 + _rng.nextInt(500)), () {
          if (!mounted) return;
          setState(() => _light = 'red');
          _t = Timer(Duration(milliseconds: 600 + _rng.nextInt(900)), _go);
        });
      } else {
        _go();
      }
    });
  }

  void _go() {
    if (!mounted) return;
    setState(() {
      _light = 'green';
      _greenAt = DateTime.now();
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _tap() {
    if (_round >= _rounds || _light == 'wait') return;
    _t?.cancel();
    double s;
    if (_light != 'green') {
      Sound.instance.miss();
      s = 0;
      _line = 'False start!';
    } else {
      Sound.instance.hit();
      final ms = DateTime.now().difference(_greenAt!).inMilliseconds;
      s = ((900 + widget.bonusMs - ms) / 600).clamp(0.0, 1.0);
      _line = '$ms ms';
    }
    setState(() {
      _scores.add(s);
      _light = 'wait';
    });
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _round++;
        if (_round < _rounds) _arm();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_round >= _rounds) {
      return _Done(
        score: _scores.reduce((a, b) => a + b) / _rounds,
        line: 'Three rounds · last: $_line',
        onDone: widget.onDone,
      );
    }
    final k = _skinOf(context);
    final arcade = k.scene == 'arcade';
    final (color, text) = switch (_light) {
      'green' => (arcade ? k.zone : const Color(0xFF2E9E6A), widget.go),
      'amber' => (const Color(0xFFB8860B), 'Not yet…'),
      'wait' => (k.panel, _line),
      _ => (arcade ? k.panel : const Color(0xFF8A2E3A), widget.wait),
    };
    // Driving: a real traffic light. The arcade: a target in the sights.
    final Widget face = switch (k.scene) {
      'road' => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TrafficLight(light: _light),
          const SizedBox(height: 12),
          Text(text, style: NF.sora(30, weight: FontWeight.w700)),
        ],
      ),
      'arcade' => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _light == 'green' ? k.target : Icons.gps_not_fixed_rounded,
            size: 120,
            color: _light == 'green' ? k.onAccent : k.zone,
          ),
          const SizedBox(height: 12),
          Text(text, style: NF.sora(34, weight: FontWeight.w700)),
        ],
      ),
      _ => Text(text, style: NF.sora(40, weight: FontWeight.w700)),
    };
    return Column(
      children: [
        Text(
          'Round ${_round + 1} of $_rounds',
          style: NF.sora(14, color: NF.muted),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GestureDetector(
            onTapDown: (_) => _tap(),
            child: Semantics(
              button: true,
              label: _light == 'green' ? '${widget.go} Tap now' : 'Wait',
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                decoration: BoxDecoration(
                  color: k.scene == 'road' ? Colors.transparent : color,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: arcade && _light == 'green'
                      ? [BoxShadow(color: k.zone, blurRadius: 40)]
                      : null,
                ),
                alignment: Alignment.center,
                child: FittedBox(fit: BoxFit.scaleDown, child: face),
              ),
            ),
          ),
        ),
      ],
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
  // Simon-style: start with three steps and add one each round, up to
  // seven. The score is how far you got.
  static const _start = 3, _top = 7;
  final _rng = Random();
  late final _seq = List.generate(_start, (_) => _rng.nextInt(4));
  int? _lit;
  bool _showing = true;
  int _pos = 0;
  int _cleared = 0;
  double? _score;

  @override
  void initState() {
    super.initState();
    _play();
  }

  Future<void> _play() async {
    setState(() => _showing = true);
    await Future.delayed(const Duration(milliseconds: 600));
    // Later rounds play a little faster.
    final step = max(260, widget.stepMs - _cleared * 50);
    for (final s in List.of(_seq)) {
      if (!mounted) return;
      setState(() => _lit = s);
      await Future.delayed(Duration(milliseconds: step));
      if (!mounted) return;
      setState(() => _lit = null);
      await Future.delayed(const Duration(milliseconds: 180));
    }
    if (mounted) setState(() => _showing = false);
  }

  void _press(int i) {
    if (_showing || _score != null) return;
    if (_seq[_pos] != i) {
      Sound.instance.miss();
      setState(() => _score = _cleared / (_top - _start + 1));
      return;
    }
    Sound.instance.tick();
    setState(() => _pos++);
    if (_pos < _seq.length) return;
    _cleared++;
    if (_seq.length >= _top) {
      setState(() => _score = 1);
      return;
    }
    _pos = 0;
    _seq.add(_rng.nextInt(4));
    _play();
  }

  @override
  Widget build(BuildContext context) {
    if (_score != null) {
      return _Done(
        score: _score!,
        line: _score == 1
            ? 'All the way to seven. Flawless.'
            : 'Remembered $_cleared round${_cleared == 1 ? '' : 's'} (longest ${_cleared == 0 ? 0 : _start + _cleared - 1})',
        onDone: widget.onDone,
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _showing
              ? 'Watch… (${_seq.length} steps)'
              : 'Your turn: ${_pos + 1} of ${_seq.length}',
          style: NF.sora(16, color: NF.soft),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (var i = 0; i < 4; i++)
              _Pad(
                index: i,
                label: widget.names[i],
                lit: _lit == i,
                onTap: () => _press(i),
              ),
          ],
        ),
      ],
    );
  }
}
