part of 'career_hub.dart';

// "Calling" step 6 (docs/phase-2/03, D1: yes): the Astronaut ("Orbit")
// and the Fighter ("Fight Night"), on the same Hub shape.
//
// Astronauts train for missions that climb with rank: the station (with a
// spacewalk), the Moon, then Mars. Every launch shows its risk to life
// before you commit, and readiness lowers it; you can always scrub. A
// launch can end a life (owner's choice: real danger).
//
// Fighters choose boxing or MMA in a fictional league, build a record,
// manage injuries, and win a title fight to become champion. Crews may
// offer money to throw a fight: taking it is fraud on the crime scale.

// ================= Astronaut · Orbit =================

const _astronaut = HubSpec(
  id: 'astronaut',
  meter: 'Readiness',
  meterBlurb: 'Simulators, fitness and survival training build it. Higher readiness makes every launch safer.',
  seasons: ['Selection', 'Training', 'Launch window', 'Return'],
  details: _astronautDetails,
);

/// (id, name, what happens, base risk to life in tenths of a percent).
const _missions = <(String, String, String, int)>[
  (
    'station',
    'the space station',
    'six months on the station and your first spacewalk',
    10,
  ),
  ('moon', 'the Moon', 'a lunar landing and a week on the surface', 30),
  (
    'mars',
    'Mars',
    'the first crewed expedition to Mars: three years there and back',
    60,
  ),
];

/// The mission for your rank (none for candidates).
(String, String, String, int)? missionFor(Life l) =>
    l.careerId != 'astronaut' || l.careerRank == 0
    ? null
    : _missions[min(l.careerRank, 3) - 1];

List<String> missionsFlown(Life l) =>
    ((l.hub['flown'] as List?) ?? const []).cast<String>();

bool _flownThisRank(Life l) {
  final m = missionFor(l);
  return m != null && missionsFlown(l).contains(m.$1);
}

/// Risk to life of the next launch, in tenths of a percent: readiness can
/// cut it to half; low readiness makes it half as bad again.
int launchRisk(Life l) {
  final m = missionFor(l);
  if (m == null) return 0;
  return (m.$4 * (1.5 - hubMeter(l) / 100)).round().clamp(1, 200);
}

String _riskWords(int tenths) => tenths <= 5
    ? 'A small risk to life'
    : tenths <= 20
    ? 'A real risk to life'
    : tenths <= 45
    ? 'A serious risk to life'
    : 'A grave risk to life';

List<(String, String)> _astronautDetails(Life l) => [
  ('Next mission', missionFor(l)?.$2 ?? 'Pass selection first'),
  ('Missions flown', '${missionsFlown(l).length}'),
  if (missionFor(l) != null && !_flownThisRank(l))
    ('Launch risk', _riskWords(launchRisk(l))),
  if (_count(l, 'eva') > 0) ('Spacewalks', '${_count(l, 'eva')}'),
];

final _astronautActions = <GameAction>[
  GameAction(
    id: 'ast_sim',
    label: 'Practise docking in the simulator',
    category: 'Career',
    keywords: ['simulator', 'docking', 'training', 'space'],
    miniGame: 'docking',
    extraCheck: (l) => _only(l, 'astronaut', 'astronauts'),
    run: (l, rng) => _sim(l, rng, 0.6),
    scored: _sim,
  ),
  GameAction(
    id: 'ast_centrifuge',
    label: 'Ride the centrifuge',
    category: 'Career',
    keywords: ['centrifuge', 'g-force', 'fitness'],
    extraCheck: (l) => _only(l, 'astronaut', 'astronauts'),
    run: (l, rng) => _with(
      statChange(
        l,
        'Eight times your body weight pressing you into the seat. You held on to your breakfast and your consciousness.',
        {'athleticism': 2, 'health': 1, 'happiness': -1},
      ),
      [_meterNote(l, 4)],
    ),
  ),
  GameAction(
    id: 'ast_survival',
    label: 'Do survival training',
    category: 'Career',
    keywords: ['survival', 'desert', 'ocean', 'cave', 'training'],
    extraCheck: (l) => _only(l, 'astronaut', 'astronauts'),
    run: (l, rng) {
      const places = [
        'a week in a cave with no daylight',
        'three days adrift in a capsule off the coast',
        'a frozen forest with a parachute for a tent',
      ];
      return _with(
        statChange(
          l,
          'Survival training: ${places[rng.nextInt(places.length)]}. If you come down in the wrong place, you will know what to do.',
          {'willpower': 2, 'health': -1},
        ),
        [_meterNote(l, 5)],
      );
    },
  ),
  GameAction(
    id: 'ast_research',
    label: 'Run experiments for the mission',
    category: 'Career',
    keywords: ['research', 'science', 'experiment'],
    extraCheck: (l) => _only(l, 'astronaut', 'astronauts'),
    run: (l, rng) => _with(
      statChange(
        l,
        'Crystals that grow better without gravity, and a plant experiment you have named after your nan.',
        {'smarts': 2},
      ),
      [_meterNote(l, 3)],
    ),
  ),
  GameAction(
    id: 'ast_outreach',
    label: 'Visit schools',
    category: 'Career',
    keywords: ['outreach', 'schools', 'talk', 'public'],
    extraCheck: (l) => _only(l, 'astronaut', 'astronauts'),
    run: (l, rng) {
      l.fame = min(100, l.fame + 2);
      return _with(
        statChange(
          l,
          'Two hundred children, one question about how you go to the toilet in space, and one girl at the back who will be an astronaut too.',
          {'happiness': 3, 'karma': 2},
        ),
        ['Fame +2', _meterNote(l, 1)],
      );
    },
  ),
  GameAction(
    id: 'ast_launch',
    label: 'Fly your mission',
    category: 'Career',
    keywords: ['launch', 'mission', 'rocket', 'moon', 'mars'],
    extraCheck: (l) {
      final m = missionFor(l);
      return _only(l, 'astronaut', 'astronauts') ??
          (m == null
              ? 'Mission specialists and up'
              : _flownThisRank(l)
              ? 'You have flown ${m.$2}; next rank for the next mission'
              : hubMeter(l) < 50
              ? 'Needs Readiness 50'
              : null);
    },
    hint: (l) => missionFor(l) == null || _flownThisRank(l)
        ? null
        : '${missionFor(l)!.$2} · ${_riskWords(launchRisk(l)).toLowerCase()}',
    run: (l, rng) {
      l.sceneQueue.insert(0, 'hub:astronaut:launch');
      return ActionResult('The crew bus pulled up to the launch pad.');
    },
  ),
];

ActionResult _sim(Life l, Random rng, double score) {
  final up = ((score - 0.4) * 14).round();
  return ActionResult(
    score >= 0.7
        ? 'Soft capture, hard capture, hatch open. The instructor did not say anything for once.'
        : score >= 0.4
        ? 'You docked a little hot and a little off-centre. The station would have survived it.'
        : 'You hit the port at an angle. In real life that is a very expensive noise.',
    [_meterNote(l, up)],
  );
}

List<String> _astronautYear(Life l, Random rng, int beat) {
  final m = missionFor(l);
  if (beat == 2 && m != null && !_flownThisRank(l)) {
    return [
      'Your launch window for ${m.$2} is open. Fly when your readiness is high.',
    ];
  }
  return const [];
}

Storylet? _launchScene(Life l) {
  final m = missionFor(l);
  if (m == null) return null;
  final risk = launchRisk(l);
  return _scene(
    'astronaut_launch',
    'T-minus ten minutes. You are strapped in on top of a rocket for ${m.$3}. The flight director asks each of you for a go or no-go. ${_riskWords(risk)}: your readiness is ${hubMeter(l)}.',
    [
      Choice(
        label: 'Go for launch',
        outcome: '',
        risk: _riskWords(risk),
        run: (l, rng) {
          final roll = rng.nextInt(1000);
          if (roll < risk) {
            l.alive = false;
            l.causeOfDeath = 'Lost on the mission to ${m.$2}';
            l.flags['lost_in_space'] = Memory(
              l.age,
              'giving your life on the mission to ${m.$2}',
            );
            _log(l, 'lost on the mission to ${m.$2}');
            l.feed.add(
              FeedEntry(
                l.age,
                'The mission to ${m.$2} was lost. Your name was read out at mission control in a silence nobody there will forget.',
                kind: 'milestone',
              ),
            );
            return 'Something went wrong that no simulator had ever shown you. Mission control lost the signal.';
          }
          if (roll < risk * 4) {
            l.stats.add('health', -15);
            _bump(l, -5);
            _log(l, 'survived an aborted mission');
            return 'An alarm at max-q, the abort motor fired and your capsule came down in the sea. Broken ribs, a living crew, and no ${m.$2} this time. Readiness −5.';
          }
          l.hub['flown'] = [...missionsFlown(l), m.$1];
          final bonus = 20000 * l.careerRank;
          l.money += bonus;
          l.fame = min(100, l.fame + 10 * l.careerRank);
          _bump(l, 8);
          _log(l, 'flew to ${m.$2}');
          if (m.$1 == 'station') l.sceneQueue.insert(0, 'hub:astronaut:eva');
          l.flags['went_to_${m.$1}'] = Memory(l.age, 'going to ${m.$2}');
          return switch (m.$1) {
            'station' =>
              'Eight and a half minutes later the engines cut and your pen floated off the checklist. Six months of sunrises every ninety minutes. Bonus ${_m(bonus)}.',
            'moon' =>
              'You stepped off the ladder into grey dust that has waited four billion years for footprints. The Earth fitted behind your thumb. Bonus ${_m(bonus)}.',
            _ =>
              'Seven months out, a year on a red world, seven months home. You are one of the first people to stand on Mars. Bonus ${_m(bonus)}.',
          };
        },
      ),
      Choice(
        label: 'Call a no-go and scrub',
        outcome: '',
        risk: 'Safe',
        run: (l, rng) {
          _bump(l, -3);
          return 'You called a no-go on a sensor reading. The launch slipped a few months. Some people grumbled; nobody died. Readiness −3.';
        },
      ),
    ],
  );
}

Storylet _evaScene(Life l) => _scene(
  'astronaut_eva',
  'Your first spacewalk. Halfway along the truss, your safety tether snags on a bracket. The Earth is turning under your boots. Your partner is ten metres away.',
  [
    Choice(
      label: 'Free it slowly, by the checklist',
      outcome: '',
      run: (l, rng) {
        _add(l, 'eva');
        _bump(l, 4);
        return 'Two minutes that felt like an hour. You finished the repair and stopped to look at the Pacific. Readiness +4.';
      },
    ),
    Choice(
      label: 'Unclip and re-clip further along',
      outcome: '',
      risk: 'A moment with no tether',
      run: (l, rng) {
        _add(l, 'eva');
        if (rng.nextInt(100) < 85) {
          _bump(l, 6);
          return 'For one second nothing held you to anything. Then the clip clicked. Mission control did not need to know. Readiness +6.';
        }
        _bump(l, -6);
        l.stats.add('happiness', -6);
        return 'Your glove slipped. Your partner caught your boot. You will dream about that for years. Readiness −6.';
      },
    ),
  ],
);

// ================= Fighter · Fight Night =================

const _fighter = HubSpec(
  id: 'fighter',
  meter: 'Ranking',
  meterBlurb: 'Your place in the league. Wins lift it, losses and long lay-offs drop it. A title shot comes near the top.',
  seasons: ['Fight camp', 'Weigh-in', 'Fight night', 'Recovery'],
  details: _fighterDetails,
);

String? fightStyle(Life l) => l.hub['style'] as String?;

int _wins(Life l) => _count(l, 'wins');
int _losses(Life l) => _count(l, 'losses');
bool _injured(Life l) => (l.hub['injured'] as int? ?? -1) >= l.age;

String fightRecord(Life l) =>
    '${_wins(l)}–${_losses(l)}${_count(l, 'kos') > 0 ? ' (${_count(l, 'kos')} KO)' : ''}';

List<(String, String)> _fighterDetails(Life l) => [
  ('Discipline', fightStyle(l) ?? 'Not chosen'),
  ('Record', fightRecord(l)),
  if (l.hub['belt'] == true) ('Title', 'Champion'),
  if (_injured(l)) ('Condition', 'Injured: rest first'),
];

String? _fighterCheck(Life l) =>
    _only(l, 'fighter', 'fighters') ??
    (fightStyle(l) == null ? 'Choose boxing or MMA first' : null);

final _fighterActions = <GameAction>[
  GameAction(
    id: 'fig_style',
    label: 'Choose your discipline',
    category: 'Career',
    keywords: ['boxing', 'mma', 'discipline', 'style'],
    extraCheck: (l) =>
        _only(l, 'fighter', 'fighters') ??
        (fightStyle(l) != null ? 'You fight ${fightStyle(l)}' : null),
    run: (l, rng) {
      l.sceneQueue.insert(0, 'hub:fighter:style');
      return ActionResult('You walked into two gyms on the same street.');
    },
  ),
  GameAction(
    id: 'fig_train',
    label: 'Train at the gym',
    category: 'Career',
    keywords: ['train', 'gym', 'pads', 'bag'],
    miniGame: 'reps',
    extraCheck: _fighterCheck,
    run: (l, rng) => _fightTrain(l, rng, 0.6),
    scored: _fightTrain,
  ),
  GameAction(
    id: 'fig_spar',
    label: 'Spar',
    category: 'Career',
    keywords: ['spar', 'sparring', 'practice'],
    extraCheck: (l) =>
        _fighterCheck(l) ?? (_injured(l) ? 'Injured: rest first' : null),
    run: (l, rng) {
      if (rng.nextInt(100) < 12) {
        l.hub['injured'] = l.age;
        return statChange(
          l,
          'Your sparring partner forgot it was sparring. A cut over the eye and a week off.',
          {'health': -6},
        );
      }
      return _with(
        statChange(
          l,
          'Twelve hard rounds with someone better than you. You learned three things and felt all of them.',
          {'athleticism': 1, 'health': -1},
        ),
        [_meterNote(l, 3)],
      );
    },
  ),
  GameAction(
    id: 'fig_cut',
    label: 'Cut weight before the weigh-in',
    category: 'Career',
    keywords: ['weight', 'cut', 'diet', 'weigh-in'],
    extraCheck: (l) =>
        _fighterCheck(l) ??
        (l.hub['cut'] == l.age ? 'Already on weight' : null),
    run: (l, rng) {
      l.hub['cut'] = l.age;
      return statChange(
        l,
        'Saunas, plain chicken and a skipping rope. You made weight by the width of a hair. Your next fight this year starts with an edge.',
        {'health': -3, 'happiness': -2},
      );
    },
  ),
  GameAction(
    id: 'fig_promo',
    label: 'Promote your next fight',
    category: 'Career',
    keywords: ['promote', 'press', 'trash talk', 'media'],
    extraCheck: _fighterCheck,
    run: (l, rng) {
      l.fame = min(100, l.fame + 3);
      l.hub['hype'] = l.age;
      final clean = l.stats['karma'] >= 50;
      l.image = (l.image + (clean ? 2 : -3)).clamp(-100, 100);
      return ActionResult(
        clean
            ? 'A respectful press conference. You said you would win and thanked your mum. The tickets sold anyway.'
            : 'You pushed your opponent at the face-off and called his gym a car park. The pay-per-view numbers doubled.',
        ['Fame +3', 'Bigger purse for your next fight'],
      );
    },
  ),
  GameAction(
    id: 'fig_fight',
    label: 'Fight',
    category: 'Career',
    keywords: ['fight', 'bout', 'match', 'ring', 'cage'],
    miniGame: 'fight',
    extraCheck: (l) =>
        _fighterCheck(l) ?? (_injured(l) ? 'Injured: rest first' : null),
    hint: (l) => l.careerRank == 2 && hubMeter(l) >= 80 && l.hub['belt'] != true
        ? 'A title fight'
        : null,
    run: (l, rng) => _fight(l, rng, 0.6),
    scored: _fight,
  ),
  GameAction(
    id: 'fig_rest',
    label: 'Rest and recover',
    category: 'Career',
    keywords: ['rest', 'recover', 'physio', 'heal'],
    extraCheck: (l) => _only(l, 'fighter', 'fighters'),
    run: (l, rng) {
      l.hub.remove('injured');
      return statChange(
        l,
        'Ice baths, physio and a lot of sleep. Your body thanked you by hurting a bit less.',
        {'health': 5, 'happiness': 2},
      );
    },
  ),
];

ActionResult _fightTrain(Life l, Random rng, double score) {
  final up = ((score - 0.4) * 10).round();
  l.fitness = min(100, l.fitness + (score >= 0.5 ? 2 : 1));
  return ActionResult(
    score >= 0.7
        ? 'Pads, bag, rope, repeat. Your coach stopped counting and started nodding.'
        : score >= 0.4
        ? 'A solid session. You were sick in the bin once, which apparently means it worked.'
        : 'Heavy legs and a heavier bag. Some days are like that.',
    [_meterNote(l, up)],
  );
}

/// Your opponent's name and nickname, from the seed.
String _opponent(Life l, Random rng) {
  const names = [
    ('Danny', 'The Hammer'),
    ('Kofi', 'Silk'),
    ('Mateo', 'El Toro'),
    ('Ivan', 'The Wall'),
    ('Jae-won', 'Lightning'),
    ('Sam', 'The Accountant'),
    ('Luca', 'Nightshift'),
  ];
  final (n, nick) = names[rng.nextInt(names.length)];
  return '$n "$nick"';
}

/// A fight, played as Fight Night (the fight mini-game) or resolved at
/// [score]. The title fight comes for contenders near the top.
ActionResult _fight(Life l, Random rng, double score) {
  final title = l.careerRank == 2 && hubMeter(l) >= 80 && l.hub['belt'] != true;
  final opp = _opponent(l, rng);
  var edge = score - 0.5;
  if (l.hub['cut'] == l.age) edge += 0.06;
  edge += (l.stats['athleticism'] - 60) / 400;
  final won = edge + (rng.nextDouble() - 0.5) * 0.3 > 0;
  final ko = (edge.abs() > 0.25) && rng.nextBool();
  final purse =
      ((3000 + 9000 * l.careerRank) *
              (title ? 3 : 1) *
              (l.hub['hype'] == l.age ? 1.5 : 1))
          .round();
  final notes = <String>[];
  String text;
  if (won) {
    _add(l, 'wins');
    if (ko) _add(l, 'kos');
    l.money += purse;
    notes
      ..add(_meterNote(l, title ? 10 : 7))
      ..add('Money +${_m(purse)}');
    if (title) {
      l.hub['belt'] = true;
      l.flags['champion'] = Memory(l.age, 'winning a ${fightStyle(l)} title');
      _log(l, 'won the title against $opp');
      text =
          'Five rounds against $opp for the belt. ${ko ? 'In the last one you found the opening you had drilled a thousand times.' : 'Split decision. The judges read your name.'} You are the champion.';
    } else {
      _log(l, 'beat $opp${ko ? ' by knockout' : ''}');
      text = ko
          ? 'You walked through $opp\'s jab and ended it in the second round. The crowd was on its feet.'
          : 'A hard, close fight with $opp. You got the decision.';
    }
  } else {
    _add(l, 'losses');
    final half = purse ~/ 3;
    l.money += half;
    notes
      ..add(_meterNote(l, title ? -6 : -5))
      ..add('Money +${_m(half)}');
    _log(l, 'lost to $opp');
    if (ko || rng.nextInt(100) < 20) {
      l.hub['injured'] = l.age;
      l.stats.add('health', -8);
      notes.add('Health −8');
    }
    text = ko
        ? '$opp caught you clean. You remember the lights and then the doctor\'s torch.'
        : 'You lost a decision to $opp. You thought you had done enough. The judges did not.';
  }
  l.hub['active'] = l.age;
  l.hub.remove('hype');
  return ActionResult(text, notes);
}

List<String> _fighterYear(Life l, Random rng, int beat) {
  final feed = <String>[];
  if (fightStyle(l) == null && !l.sceneQueue.contains('hub:fighter:style')) {
    l.sceneQueue.add('hub:fighter:style');
  }
  // Crews look for fighters who can be bought.
  if (l.careerRank >= 1 &&
      rng.nextInt(100) < 18 &&
      !l.sceneQueue.contains('hub:fighter:fix')) {
    l.sceneQueue.add('hub:fighter:fix');
  }
  if (l.age >= 37 && l.hub['belt'] != true && rng.nextInt(100) < 15) {
    feed.add(
      'Your body is starting to say what your coach will not: the end is closer than the start.',
    );
  }
  return feed;
}

Storylet _styleScene(Life l) => _scene(
  'fighter_style',
  'Two gyms on the same street. One smells of leather and has a ring in the middle. The other has a cage, mats and someone being choked very politely.',
  [
    for (final (style, line) in const [
      (
        'Boxing',
        'Gloves, footwork and twelve three-minute rounds. The oldest fight there is.',
      ),
      (
        'MMA',
        'Striking, wrestling and submissions. Anything can happen, and usually does.',
      ),
    ])
      Choice(
        label: style,
        outcome: '',
        run: (l, rng) {
          l.hub['style'] = style;
          _log(l, 'took up $style');
          return line;
        },
      ),
  ],
);

Storylet _fixScene(Life l) {
  final crew = crewOf(l);
  final who = crew == null ? 'A man in a good coat' : 'Someone from your crew';
  return _scene(
    'fighter_fix',
    '$who finds you in the car park after training. "Your next fight. Go down in the third. ${_m(15000 * l.careerRank)} in a bag, and nobody needs to know."',
    [
      Choice(
        label: 'Take the money and throw the fight',
        outcome: '',
        risk: 'Fraud: the police may come looking',
        run: (l, rng) {
          _add(l, 'losses');
          _bump(l, -6);
          _log(l, 'threw a fight');
          final r = commitCrime(
            l,
            crimeById('fraud'),
            rng,
            riskAdj: -10,
            gainMul: 1.5 * l.careerRank,
            text: 'You went down in the third, as agreed. The bag held {gain}. It does not feel like winning.',
          );
          return '${r.text} ${r.notes.join(' · ')}';
        },
      ),
      Choice(
        label: 'Refuse',
        outcome: '',
        risk: 'They may not take it well',
        run: (l, rng) {
          l.stats.add('karma', 2);
          if (rng.nextInt(100) < 45) {
            l.stats.add('health', -5);
            l.stats.add('happiness', -4);
            return 'You said no. A week later someone put a brick through the gym window with a note. Your coach said nothing and paid for the glass.';
          }
          return 'You said no. They shrugged and walked off. You won the fight honestly.';
        },
      ),
      Choice(
        label: 'Report it to the commission',
        outcome: '',
        risk: 'Brave',
        run: (l, rng) {
          l.stats.add('karma', 4);
          _bump(l, 3);
          l.image = min(100, l.image + 4);
          return 'You went to the commission. There was an investigation, two arrests and a headline with your name in it, for the right reasons.';
        },
      ),
    ],
  );
}

// ================= Street hustler scams (D2: yes) =================

/// (label, what happens, risk change, money scale)
const _scams = <(String, String, int, double)>[
  (
    'The three-card trick',
    'A folding table, three cards and a "lucky" friend in the crowd. You cleared {gain} before anyone noticed the queen never moved.',
    0,
    0.4,
  ),
  (
    'A raffle with no prize',
    'Tickets for a car you do not own, sold door to door. {gain} in envelopes.',
    8,
    0.8,
  ),
  (
    'A collection for a charity that does not exist',
    'A bucket, a lanyard and a sad story. The public gave {gain}. You will not sleep well.',
    5,
    0.6,
  ),
];

Storylet _scamScene(Life l) => _scene(
  'hustler_scam',
  'The legal hustle is slow this week. You know a few faster ways to make money on a street. Every one of them is fraud.',
  [
    for (final (label, text, risk, mul) in _scams)
      Choice(
        label: label,
        outcome: '',
        risk: risk > 5 ? 'Riskier' : 'Fraud',
        run: (l, rng) {
          // A licence gets you trusted, and noticed when it goes wrong.
          final r = commitCrime(
            l,
            crimeById('fraud'),
            rng,
            riskAdj: risk + (hasLicence(l) ? 5 : 0),
            gainMul: mul,
            text: text,
          );
          if (r.notes.any((n) => n.startsWith('Caught'))) {
            l.hub.remove('licence');
            _bump(l, -10);
          } else {
            _bump(l, 2);
          }
          return '${r.text} ${r.notes.join(' · ')}';
        },
      ),
    Choice(
      label: 'Keep it legal',
      outcome: 'You put the cards away and got your guitar out instead.',
    ),
  ],
);

final _scamAction = GameAction(
  id: 'hus_scam',
  label: 'Run a scam',
  category: 'Career',
  keywords: ['scam', 'con', 'trick', 'hustle', 'fraud'],
  minAge: 16,
  extraCheck: (l) => _hustlerCheck(l),
  hint: (l) => 'Fraud · leaves evidence',
  run: (l, rng) {
    l.sceneQueue.insert(0, 'hub:hustler:scam');
    return ActionResult(
      'You looked up and down the street for the right mark.',
    );
  },
);

// ================= Hooks =================

List<String> _wave3Year(Life l, Random rng, String id, int beat) =>
    switch (id) {
      'astronaut' => _astronautYear(l, rng, beat),
      'fighter' => _fighterYear(l, rng, beat),
      _ => const [],
    };

Storylet? _wave3Scene(String key, Life l) => switch (key) {
  'astronaut:launch' => _launchScene(l),
  'astronaut:eva' => _evaScene(l),
  'fighter:style' => _styleScene(l),
  'fighter:fix' => _fixScene(l),
  'hustler:scam' => _scamScene(l),
  _ => null,
};

String? _wave3Needs(Life l, String id, String meter, int need) => switch (id) {
  'astronaut' when l.careerRank >= 1 && !_flownThisRank(l) =>
    'Fly your mission to ${missionFor(l)!.$2} and reach $meter $need',
  'fighter' when fightStyle(l) == null => 'Choose boxing or MMA',
  'fighter' when l.careerRank == 2 && l.hub['belt'] != true =>
    'Win a title fight (offered at $meter 80)',
  _ => null,
};
