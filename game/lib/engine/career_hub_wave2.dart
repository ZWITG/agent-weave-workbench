part of 'career_hub.dart';

// "Calling" wave 2 (docs/phase-2/03, 6.2): the Career Hub for models,
// doctors, vets, pilots, the armed forces, lawyers and street hustlers.
// Same shape as wave 1: a signature meter, the career's own activities
// (category 'Career', prefixes in _prefixes), a season of four beats with
// scenes, and promotion from the meter (hubRankNeeds / hubYear).

String? _only(Life l, String id, String who) =>
    l.careerId != id ? 'Only for $who' : null;

/// [r] with more notes (through the constructor, so money is localised).
ActionResult _with(ActionResult r, List<String> more) =>
    ActionResult(r.text, [...r.notes, ...more]);

int _count(Life l, String key) => (l.hub[key] as int?) ?? 0;

void _add(Life l, String key, [int by = 1]) => l.hub[key] = _count(l, key) + by;

/// Moves the meter by [by] and returns its note ("Portfolio +4").
String _meterNote(Life l, int by) {
  _bump(l, by);
  final name = hubSpecs[l.careerId]?.meter ?? 'Meter';
  return '$name ${by >= 0 ? '+' : '−'}${by.abs()}';
}

// ================= Model · Runway =================

const _model = HubSpec(
  id: 'model',
  meter: 'Portfolio',
  meterBlurb: 'Castings, shoots and shows build it. After 30 it fades faster unless you keep working.',
  seasons: ['Castings', 'Fashion week', 'Campaigns', 'Off-season'],
  details: _modelDetails,
);

List<(String, String)> _modelDetails(Life l) => [
  ('Agency', _count(l, 'agency') == 1 ? 'Top agency' : 'Small agency'),
  ('Shows walked', '${_count(l, 'shows')}'),
  ('Campaigns', '${_count(l, 'campaigns')}'),
  if (_count(l, 'covers') > 0) ('Magazine covers', '${_count(l, 'covers')}'),
];

final _modelActions = <GameAction>[
  GameAction(
    id: 'mod_casting',
    label: 'Go to castings',
    category: 'Career',
    keywords: ['casting', 'go-see', 'model', 'audition'],
    miniGame: 'timing',
    extraCheck: (l) => _only(l, 'model', 'models'),
    run: (l, rng) => _casting(l, rng, 0.6),
    scored: _casting,
  ),
  GameAction(
    id: 'mod_shoot',
    label: 'Book a test shoot',
    category: 'Career',
    keywords: ['shoot', 'photos', 'portfolio', 'photographer'],
    cost: 800,
    extraCheck: (l) => _only(l, 'model', 'models'),
    run: (l, rng) {
      l.money -= 800;
      final up = 3 + l.stats['creativity'] ~/ 30;
      return ActionResult(
        'A rooftop at dawn, a photographer who only said "again", and three frames worth keeping.',
        [_meterNote(l, up)],
      );
    },
  ),
  GameAction(
    id: 'mod_fashion_week',
    label: 'Walk at fashion week',
    category: 'Career',
    keywords: ['fashion week', 'runway', 'show', 'catwalk'],
    extraCheck: (l) =>
        _only(l, 'model', 'models') ??
        (l.careerRank < 1 && hubMeter(l) < 30
            ? 'Needs Portfolio 30 or Runway model'
            : null),
    run: (l, rng) {
      _add(l, 'shows', 2 + rng.nextInt(3));
      l.fame = min(100, l.fame + 2);
      final up = 4 + l.careerRank;
      return ActionResult(
        'Four shows in five days, eleven outfit changes and one heel that did not survive. The front row noticed you.',
        [_meterNote(l, up), 'Fame +2'],
      );
    },
  ),
  GameAction(
    id: 'mod_campaign',
    label: 'Pitch for a brand campaign',
    category: 'Career',
    keywords: ['campaign', 'brand', 'advert', 'deal'],
    extraCheck: (l) =>
        _only(l, 'model', 'models') ??
        (hubMeter(l) < 45 ? 'Needs Portfolio 45' : null),
    run: (l, rng) {
      final odds = 35 + hubMeter(l) ~/ 2 + l.stats['looks'] ~/ 5;
      if (rng.nextInt(100) >= odds) {
        return ActionResult(
          'They went with someone "more on brand". Nobody could say what that meant.',
          [_meterNote(l, -1)],
        );
      }
      final fee = 15000 * (l.careerRank + 1) + rng.nextInt(10000);
      l.money += fee;
      _add(l, 'campaigns');
      l.fame = min(100, l.fame + 3);
      _log(l, 'fronted a brand campaign');
      return ActionResult(
        'Your face is on the side of buses now. The fee helps you get used to it.',
        [_meterNote(l, 6), 'Money +${_m(fee)}', 'Fame +3'],
      );
    },
  ),
  GameAction(
    id: 'mod_agency',
    label: 'Sign with a top agency',
    category: 'Career',
    keywords: ['agency', 'agent', 'sign'],
    extraCheck: (l) =>
        _only(l, 'model', 'models') ??
        (_count(l, 'agency') == 1
            ? 'You are with a top agency'
            : hubMeter(l) < 40
            ? 'Needs Portfolio 40'
            : null),
    run: (l, rng) {
      l.hub['agency'] = 1;
      _log(l, 'signed with a top agency');
      return ActionResult(
        'A glass office, a contract with a lot of pages and a booker who calls you "darling". Bigger jobs, bigger cut.',
        [_meterNote(l, 5)],
      );
    },
  ),
];

ActionResult _casting(Life l, Random rng, double score) {
  final up = ((score - 0.35) * 12).round() + (_count(l, 'agency') == 1 ? 1 : 0);
  return ActionResult(
    score >= 0.7
        ? 'You walked in, turned once and they stopped looking at the next card. Booked.'
        : score >= 0.4
        ? 'Twelve castings across the city. Two callbacks, one maybe.'
        : 'You tripped on the turn. They were very kind about it, which was worse.',
    [_meterNote(l, up)],
  );
}

List<String> _modelYear(Life l, Random rng, int beat) {
  final feed = <String>[];
  if (l.age > 30) {
    final fade = l.age > 38 ? 6 : 3;
    l.hub['meter'] = max(0, hubMeter(l) - fade);
    feed.add('The industry likes its models young: Portfolio −$fade.');
  }
  if (beat == 1 && hubMeter(l) >= 50 && rng.nextInt(100) < 45) {
    l.sceneQueue.add('hub:model:cover');
  }
  return feed;
}

Storylet _coverScene(Life l) => _scene(
  'model_cover',
  'A magazine wants you on the cover. The editor has two ideas: a classic portrait, or something bolder that will get people talking.',
  [
    Choice(
      label: 'The classic portrait',
      outcome: '',
      risk: 'Safe',
      run: (l, rng) {
        _add(l, 'covers');
        _bump(l, 5);
        l.fame = min(100, l.fame + 3);
        _log(l, 'a magazine cover');
        return 'Timeless, they said. Your mum bought six copies. Portfolio +5.';
      },
    ),
    Choice(
      label: 'Something bold',
      outcome: '',
      risk: 'Could go either way',
      run: (l, rng) {
        _add(l, 'covers');
        l.fame = min(100, l.fame + 6);
        _log(l, 'a talked-about magazine cover');
        if (rng.nextInt(100) < 60) {
          _bump(l, 9);
          l.image = min(100, l.image + 4);
          return 'It sold out in two days. Designers started asking for you by name. Portfolio +9.';
        }
        _bump(l, 2);
        l.image = max(-100, l.image - 6);
        return 'It got people talking, mostly about whether it was too much. Portfolio +2.';
      },
    ),
    Choice(
      label: 'Turn it down',
      outcome: 'You said you were not ready. The editor said that was a shame.',
    ),
  ],
);

// ================= Doctor · Night Shift =================

const _doctor = HubSpec(
  id: 'doctor',
  meter: 'Ward trust',
  meterBlurb: 'How much your team and patients rely on you. Shifts, good calls and teaching build it; mistakes cost it.',
  seasons: ['Rotations', 'Winter crisis', 'Research', 'Review'],
  details: _doctorDetails,
);

const _specialties = ['Emergency medicine', 'Cardiology', 'Paediatrics'];

String? doctorSpecialty(Life l) => l.hub['specialty'] as String?;

List<(String, String)> _doctorDetails(Life l) => [
  ('Specialty', doctorSpecialty(l) ?? 'Not chosen yet'),
  ('Patients treated', '${_count(l, 'patients')}'),
  ('Papers published', '${_count(l, 'papers')}'),
];

final _doctorActions = <GameAction>[
  GameAction(
    id: 'doc_triage',
    label: 'Run the A&E triage',
    category: 'Career',
    keywords: ['triage', 'emergency', 'patients', 'hospital'],
    miniGame: 'memory',
    extraCheck: (l) => _only(l, 'doctor', 'doctors'),
    run: (l, rng) => _triage(l, rng, 0.6),
    scored: _triage,
  ),
  GameAction(
    id: 'doc_shift',
    label: 'Take an extra night shift',
    category: 'Career',
    keywords: ['shift', 'night', 'overtime', 'ward'],
    extraCheck: (l) => _only(l, 'doctor', 'doctors'),
    run: (l, rng) {
      final pay = 600 + 200 * l.careerRank;
      l.money += pay;
      _add(l, 'patients', 20 + rng.nextInt(20));
      return _with(
        statChange(
          l,
          'Three in the morning, a vending-machine dinner and a ward that would not sleep. Everyone made it to breakfast.',
          {'health': -3, 'happiness': -1},
        ),
        [_meterNote(l, 4), 'Money +${_m(pay)}'],
      );
    },
  ),
  GameAction(
    id: 'doc_research',
    label: 'Write up research',
    category: 'Career',
    keywords: ['research', 'paper', 'study', 'journal'],
    extraCheck: (l) => _only(l, 'doctor', 'doctors'),
    run: (l, rng) {
      final odds = 30 + l.stats['smarts'] ~/ 2;
      if (rng.nextInt(100) >= odds) {
        return statChange(
          l,
          'Reviewer 2 wanted "a fundamentally different study". You put the draft in a drawer.',
          {'smarts': 1, 'happiness': -2},
        );
      }
      _add(l, 'papers');
      _log(l, 'published a paper');
      return _with(
        statChange(
          l,
          'Your paper was accepted. Somebody in another country cited it within a month.',
          {'smarts': 2},
        ),
        [_meterNote(l, 5)],
      );
    },
  ),
  GameAction(
    id: 'doc_teach',
    label: 'Teach medical students',
    category: 'Career',
    keywords: ['teach', 'students', 'mentor'],
    extraCheck: (l) =>
        _only(l, 'doctor', 'doctors') ??
        (l.careerRank < 1 ? 'Attending physicians and up' : null),
    run: (l, rng) => _with(
      statChange(
        l,
        'A ward round with six students who all wrote down everything you said, including the joke.',
        {'karma': 2},
      ),
      [_meterNote(l, 3)],
    ),
  ),
  GameAction(
    id: 'doc_abroad',
    label: 'Volunteer with an aid mission',
    category: 'Career',
    keywords: ['volunteer', 'abroad', 'aid', 'charity', 'mission'],
    extraCheck: (l) =>
        _only(l, 'doctor', 'doctors') ??
        (l.hub['abroad'] == l.age - 1 ? 'You went last year' : null),
    run: (l, rng) {
      l.hub['abroad'] = l.age;
      _log(l, 'volunteered with an aid mission');
      return _with(
        statChange(
          l,
          'Six weeks in a field clinic with a generator, a kettle and more patients than hours. You came back changed.',
          {'karma': 6, 'happiness': 3, 'health': -2},
        ),
        [_meterNote(l, 6)],
      );
    },
  ),
];

ActionResult _triage(Life l, Random rng, double score) {
  _add(l, 'patients', 10 + (score * 20).round());
  final up = ((score - 0.4) * 14).round();
  return ActionResult(
    score >= 0.7
        ? 'Chest pain to resus, the broken wrist can wait, the quiet one in the corner needs you now. You read the room perfectly.'
        : score >= 0.4
        ? 'A busy night. You got most of the order right, and the nurses fixed the rest without a word.'
        : 'You saw the loud patients first. The charge nurse had a word.',
    [_meterNote(l, up)],
  );
}

List<String> _doctorYear(Life l, Random rng, int beat) {
  if (doctorSpecialty(l) == null &&
      l.careerRank >= 1 &&
      !l.sceneQueue.contains('hub:doctor:specialty')) {
    l.sceneQueue.add('hub:doctor:specialty');
  }
  if (beat == 1 && !l.sceneQueue.contains('hub:doctor:winter')) {
    l.sceneQueue.add('hub:doctor:winter');
  }
  return const [];
}

Storylet _specialtyScene(Life l) => _scene(
  'doctor_specialty',
  'It is time to choose a specialty. Each one changes your days, and your nights.',
  [
    for (final s in _specialties)
      Choice(
        label: s,
        outcome: '',
        run: (l, rng) {
          l.hub['specialty'] = s;
          _log(l, 'chose $s');
          return switch (s) {
            'Emergency medicine' => 'Every shift a surprise. You will never be bored again, or rested.',
            'Cardiology' =>
              'Hearts: the most dramatic organ. Better pay, longer training.',
            _ => 'Children, worried parents and a lot of stickers.',
          };
        },
      ),
  ],
);

Storylet _winterScene(Life l) => _scene(
  'doctor_winter',
  'Winter flu has filled every bed. The rota has gaps and the department head is asking who can cover double shifts.',
  [
    Choice(
      label: 'Cover the doubles',
      outcome: '',
      risk: 'Hard on your health',
      run: (l, rng) {
        _bump(l, 8);
        l.stats.add('health', -6);
        l.stats.add('happiness', -3);
        _add(l, 'patients', 80);
        return 'You lived at the hospital for a month. The team will not forget it. Ward trust +8.';
      },
    ),
    Choice(
      label: 'Stick to your rota',
      outcome: '',
      run: (l, rng) {
        _bump(l, 1);
        _add(l, 'patients', 30);
        return 'You did your shifts well and slept between them. Someone has to stay standing.';
      },
    ),
    Choice(
      label: 'Call in sick',
      outcome: '',
      risk: 'The team will notice',
      run: (l, rng) {
        _bump(l, -7);
        l.stats.add('happiness', 2);
        return 'You watched the news about the crisis from the sofa. Ward trust −7.';
      },
    ),
  ],
);

// ================= Vet · Meadow =================

const _vet = HubSpec(
  id: 'vet',
  meter: 'Standing',
  meterBlurb: 'Your name among farmers and pet owners. Clinics, farm calls and nights on call build it.',
  seasons: ['Lambing', 'Summer clinics', 'Harvest', 'Winter calls'],
  details: _vetDetails,
);

bool ownsPractice(Life l) => l.hub['practice'] == true;

List<(String, String)> _vetDetails(Life l) => [
  ('Animals treated', '${_count(l, 'animals')}'),
  ('Farm calls', '${_count(l, 'farms')}'),
  ('Practice', ownsPractice(l) ? 'Your own' : 'Employed'),
];

final _vetActions = <GameAction>[
  GameAction(
    id: 'vet_clinic',
    label: 'Run the clinic',
    category: 'Career',
    keywords: ['clinic', 'diagnose', 'animals', 'surgery'],
    miniGame: 'memory',
    extraCheck: (l) => _only(l, 'vet', 'vets'),
    run: (l, rng) => _clinic(l, rng, 0.6),
    scored: _clinic,
  ),
  GameAction(
    id: 'vet_farm',
    label: 'Go on farm calls',
    category: 'Career',
    keywords: ['farm', 'cows', 'horses', 'calls'],
    extraCheck: (l) => _only(l, 'vet', 'vets'),
    run: (l, rng) {
      _add(l, 'farms', 3 + rng.nextInt(4));
      _add(l, 'animals', 20);
      final fee = 900 + 300 * l.careerRank;
      l.money += fee;
      return _with(
        statChange(
          l,
          'Mud to the knees, a cow with opinions and a farmer who paid in cash and eggs.',
          {'health': -1, 'happiness': 2},
        ),
        [_meterNote(l, 4), 'Money +${_m(fee)}'],
      );
    },
  ),
  GameAction(
    id: 'vet_oncall',
    label: 'Take the night on call',
    category: 'Career',
    keywords: ['on call', 'night', 'emergency'],
    extraCheck: (l) => _only(l, 'vet', 'vets'),
    run: (l, rng) {
      _add(l, 'animals', 4);
      final saved = rng.nextInt(100) < 55 + l.stats['smarts'] ~/ 4;
      return _with(
        statChange(
          l,
          saved
              ? 'A dog that ate a sock, a cat stuck behind a boiler and a foal born at 4am. Everyone went home.'
              : 'A long night and a hard conversation with a family about their old dog. You stayed with them.',
          {'happiness': saved ? 1 : -3, 'health': -2, 'karma': 1},
        ),
        [_meterNote(l, saved ? 6 : 3)],
      );
    },
  ),
  GameAction(
    id: 'vet_own_pets',
    label: 'Check over your own pets',
    category: 'Career',
    keywords: ['pets', 'check-up', 'my animals'],
    extraCheck: (l) =>
        _only(l, 'vet', 'vets') ??
        (petsOf(l).isEmpty ? 'You have no pets' : null),
    run: (l, rng) {
      final pets = petsOf(l);
      for (final p in pets) {
        p.info['health'] = min(100, petHealth(p) + 15);
      }
      return _with(
        statChange(
          l,
          'A free check-up for ${pets.length == 1 ? pets.first.name : 'all ${pets.length} of them'}, on the kitchen table. The perks of the job.',
          {'happiness': 2},
        ),
        ['Pet health +15'],
      );
    },
  ),
  GameAction(
    id: 'vet_practice',
    label: 'Open your own practice',
    category: 'Career',
    keywords: ['practice', 'open', 'business', 'own'],
    cost: 60000,
    extraCheck: (l) =>
        _only(l, 'vet', 'vets') ??
        (ownsPractice(l)
            ? 'You own the practice'
            : l.careerRank < 2
            ? 'Senior vets only'
            : hubMeter(l) < 55
            ? 'Needs Standing 55'
            : null),
    run: (l, rng) {
      l.money -= 60000;
      l.hub['practice'] = true;
      _log(l, 'opened a practice');
      return ActionResult(
        'A brass plate with your name on it, a waiting room that smells of disinfectant and dog, and a loan you will pay off one cat at a time.',
        [_meterNote(l, 8), 'Money −${_m(60000)}'],
      );
    },
  ),
];

ActionResult _clinic(Life l, Random rng, double score) {
  _add(l, 'animals', 10 + (score * 15).round());
  final up = ((score - 0.4) * 14).round();
  return ActionResult(
    score >= 0.7
        ? 'A limp, a cough and a rabbit off its food: you matched every sign to its cause before the owners finished explaining.'
        : score >= 0.4
        ? 'A steady clinic. One budgie stumped you until it did it again.'
        : 'You mixed up two charts. The labrador got the cat\'s worming tablet. Both were fine; you were not.',
    [_meterNote(l, up)],
  );
}

List<String> _vetYear(Life l, Random rng, int beat) {
  if (ownsPractice(l)) {
    final profit = 8000 + hubMeter(l) * 300 + rng.nextInt(6000);
    l.money += profit;
    return ['Your practice made ${_m(profit)} this year.'];
  }
  if (beat == 0 && rng.nextInt(100) < 50) l.sceneQueue.add('hub:vet:lambing');
  return const [];
}

Storylet _lambingScene(Life l) => _scene(
  'vet_lambing',
  'Lambing season. A farmer rings at midnight: a ewe in trouble, and it is sleeting. You are already in bed.',
  [
    Choice(
      label: 'Get dressed and go',
      outcome: '',
      run: (l, rng) {
        _bump(l, 7);
        l.stats.add('health', -2);
        _add(l, 'animals', 2);
        return 'Twins, both breathing, at 3am in a barn. The farmer told the whole valley. Standing +7.';
      },
    ),
    Choice(
      label: 'Talk the farmer through it on the phone',
      outcome: '',
      risk: 'Might not be enough',
      run: (l, rng) {
        if (rng.nextInt(100) < 50) {
          _bump(l, 2);
          return 'It worked. The farmer sounded impressed and a little smug.';
        }
        _bump(l, -4);
        return 'It did not work. The farmer will call someone else next year. Standing −4.';
      },
    ),
  ],
);

// ================= Pilot · Flight Deck =================

const _pilot = HubSpec(
  id: 'pilot',
  meter: 'Flight hours',
  meterBlurb: 'Each point is a hundred hours in the logbook. Routes add them; captains need hours and a passed check ride.',
  seasons: ['Rosters', 'Check ride', 'Peak season', 'Winter ops'],
  details: _pilotDetails,
);

bool checkRidePassed(Life l) => l.hub['check'] == l.careerRank;

List<(String, String)> _pilotDetails(Life l) => [
  ('Logbook', '${hubMeter(l) * 100} hours'),
  ('Check ride', checkRidePassed(l) ? 'Passed for this rank' : 'Due'),
  ('Union', l.hub['union'] == true ? 'Member' : 'Not a member'),
];

ActionResult _fly(Life l, Random rng, String route) {
  final (hours, text, deltas) = switch (route) {
    'long' => (
      8,
      'Thirteen hours to the other side of the world, a sunrise over the ocean and a hotel you saw only with your eyes closed.',
      {'health': -2, 'happiness': 2},
    ),
    'cargo' => (
      6,
      'Night freight: no passengers, no announcements, forty tonnes of parcels and the best coffee in aviation.',
      {'happiness': 1},
    ),
    _ => (
      5,
      'Four short hops before lunch. Seventeen announcements, one fainting passenger and an on-time record.',
      {'happiness': 1},
    ),
  };
  if (route == 'cargo') l.money += 1200;
  return _with(statChange(l, text, deltas), [
    _meterNote(l, hours),
    if (route == 'cargo') 'Money +${_m(1200)}',
  ]);
}

final _pilotActions = <GameAction>[
  GameAction(
    id: 'pil_short',
    label: 'Fly short-haul',
    category: 'Career',
    keywords: ['fly', 'short-haul', 'route', 'flight'],
    extraCheck: (l) => _only(l, 'pilot', 'pilots'),
    run: (l, rng) => _fly(l, rng, 'short'),
  ),
  GameAction(
    id: 'pil_long',
    label: 'Fly long-haul',
    category: 'Career',
    keywords: ['fly', 'long-haul', 'route', 'flight'],
    extraCheck: (l) => _only(l, 'pilot', 'pilots'),
    run: (l, rng) => _fly(l, rng, 'long'),
  ),
  GameAction(
    id: 'pil_cargo',
    label: 'Fly cargo',
    category: 'Career',
    keywords: ['cargo', 'freight', 'night flight'],
    extraCheck: (l) => _only(l, 'pilot', 'pilots'),
    run: (l, rng) => _fly(l, rng, 'cargo'),
  ),
  GameAction(
    id: 'pil_check',
    label: 'Take your check ride',
    category: 'Career',
    keywords: ['simulator', 'check ride', 'test', 'landing'],
    miniGame: 'timing',
    extraCheck: (l) =>
        _only(l, 'pilot', 'pilots') ??
        (checkRidePassed(l) ? 'Passed for this rank' : null),
    run: (l, rng) => _checkRide(l, rng, 0.6),
    scored: _checkRide,
  ),
  GameAction(
    id: 'pil_staff_travel',
    label: 'Use staff travel',
    category: 'Career',
    keywords: ['holiday', 'staff travel', 'trip', 'cheap flight'],
    cost: 300,
    extraCheck: (l) => _only(l, 'pilot', 'pilots'),
    run: (l, rng) {
      l.money -= 300;
      return statChange(
        l,
        'A standby seat to somewhere warm for the price of a taxi. You did not look at a single instrument.',
        {'happiness': 6, 'health': 1},
      );
    },
  ),
  GameAction(
    id: 'pil_union',
    label: 'Join the pilots\' union',
    category: 'Career',
    keywords: ['union', 'pay', 'rights'],
    extraCheck: (l) =>
        _only(l, 'pilot', 'pilots') ??
        (l.hub['union'] == true ? 'You are a member' : null),
    run: (l, rng) {
      l.hub['union'] = true;
      l.salary = (l.salary * 1.04).round();
      return ActionResult(
        'Dues, a badge and a pay deal that came through within the year.',
        ['Salary +4%'],
      );
    },
  ),
];

ActionResult _checkRide(Life l, Random rng, double score) {
  if (score >= 0.5) {
    l.hub['check'] = l.careerRank;
    _log(l, 'passed a check ride');
    return ActionResult(
      score >= 0.8
          ? 'Engine failure on take-off, a crosswind landing and a smile from the examiner. Textbook.'
          : 'A firm landing in a gusty crosswind, but on the centreline. Passed.',
      [_meterNote(l, 2), 'Check ride passed'],
    );
  }
  return ActionResult(
    'You floated half the runway and went around twice. The examiner wrote for a long time. Try again next year.',
    [_meterNote(l, -2)],
  );
}

List<String> _pilotYear(Life l, Random rng, int beat) {
  if (beat == 2 && rng.nextInt(100) < 35) l.sceneQueue.add('hub:pilot:divert');
  return const [];
}

Storylet _divertScene(Life l) => _scene(
  'pilot_divert',
  'Ninety minutes from home, a warning light: low oil pressure in the left engine. It could be a faulty sensor. The nearest airport is small and the passengers have connections.',
  [
    Choice(
      label: 'Divert to the nearest airport',
      outcome: '',
      risk: 'Safe',
      run: (l, rng) {
        _bump(l, 4);
        _log(l, 'diverted safely with an engine warning');
        return 'You landed on one engine as the fire trucks rolled alongside. It was not the sensor. The airline sent a letter of thanks. Flight hours +4.';
      },
    ),
    Choice(
      label: 'Run the checklist and carry on',
      outcome: '',
      risk: 'Risky',
      run: (l, rng) {
        if (rng.nextInt(100) < 60) {
          _bump(l, 2);
          return 'The pressure held. It was the sensor. You landed on time and filled in a lot of forms.';
        }
        _bump(l, -12);
        l.performance = max(0, l.performance - 20);
        _log(l, 'investigated after an engine incident');
        return 'The engine failed over the sea. You landed safely, but the investigation said you should have diverted. Flight hours −12.';
      },
    ),
  ],
);

// ================= Armed forces · Field Kit =================

const _military = HubSpec(
  id: 'military',
  meter: 'Readiness',
  meterBlurb: 'Fitness, training and time in the field. Drills and courses build it; long leave lets it slip.',
  seasons: ['Training', 'Exercises', 'Deployment', 'Leave'],
  details: _militaryDetails,
);

/// Medals won (older saves only have the 'medal' flag).
int medals(Life l) =>
    max(_count(l, 'medals'), l.flags.containsKey('medal') ? 1 : 0);

List<(String, String)> _militaryDetails(Life l) => [
  ('Courses passed', '${_count(l, 'courses')}'),
  ('Officer course', l.hub['officer'] == true ? 'Passed' : 'Not yet'),
  ('Medals', '${medals(l)}'),
];

final _militaryActions = <GameAction>[
  GameAction(
    id: 'mil_drill',
    label: 'Run the obstacle course',
    category: 'Career',
    keywords: ['drill', 'obstacle', 'training', 'fitness'],
    miniGame: 'reps',
    extraCheck: (l) => _only(l, 'military', 'the armed forces'),
    run: (l, rng) => _drill(l, rng, 0.6),
    scored: _drill,
  ),
  GameAction(
    id: 'mil_course',
    label: 'Take a training course',
    category: 'Career',
    keywords: ['course', 'training', 'officer', 'qualification'],
    extraCheck: (l) => _only(l, 'military', 'the armed forces'),
    run: (l, rng) {
      _add(l, 'courses');
      final officer = l.careerRank >= 2 && l.hub['officer'] != true;
      if (officer) {
        if (rng.nextInt(100) < 40 + l.stats['smarts'] ~/ 3) {
          l.hub['officer'] = true;
          _log(l, 'passed the officer course');
          return _with(
            statChange(
              l,
              'Twelve weeks of tactics, leadership and being shouted at politely. You passed the officer course.',
              {'smarts': 2, 'discipline': 2},
            ),
            [_meterNote(l, 6)],
          );
        }
        return _with(
          statChange(
            l,
            'The officer course board said "not yet". You can try again next year.',
            {'happiness': -2},
          ),
          [_meterNote(l, 1)],
        );
      }
      const courses = ['field medic', 'signals', 'mountain warfare', 'driving'];
      final name = courses[rng.nextInt(courses.length)];
      return _with(
        statChange(
          l,
          'You passed the $name course and got a new badge for your sleeve.',
          {'smarts': 1},
        ),
        [_meterNote(l, 4)],
      );
    },
  ),
  GameAction(
    id: 'mil_mission',
    label: 'Volunteer for a mission',
    category: 'Career',
    keywords: ['mission', 'deploy', 'volunteer', 'overseas'],
    extraCheck: (l) =>
        _only(l, 'military', 'the armed forces') ??
        (hubMeter(l) < 40 ? 'Needs Readiness 40' : null),
    run: (l, rng) {
      l.sceneQueue.insert(0, 'deployment');
      return ActionResult('Your name went on the list.');
    },
  ),
  GameAction(
    id: 'mil_mentor',
    label: 'Mentor new recruits',
    category: 'Career',
    keywords: ['mentor', 'recruits', 'teach'],
    extraCheck: (l) =>
        _only(l, 'military', 'the armed forces') ??
        (l.careerRank < 2 ? 'Sergeants and up' : null),
    run: (l, rng) => _with(
      statChange(
        l,
        'Thirty recruits who could not march in step on Monday could by Friday. One of them saluted you in the canteen.',
        {'karma': 2, 'charisma': 1},
      ),
      [_meterNote(l, 3)],
    ),
  ),
  GameAction(
    id: 'mil_leave',
    label: 'Take your leave',
    category: 'Career',
    keywords: ['leave', 'holiday', 'home', 'rest'],
    extraCheck: (l) => _only(l, 'military', 'the armed forces'),
    run: (l, rng) => _with(
      statChange(
        l,
        'Two weeks at home: your own bed, real food and nobody shouting at dawn.',
        {'happiness': 6, 'health': 3},
      ),
      [_meterNote(l, -2)],
    ),
  ),
];

ActionResult _drill(Life l, Random rng, double score) {
  final up = ((score - 0.4) * 14).round();
  if (score >= 0.5) l.fitness = min(100, l.fitness + 2);
  return ActionResult(
    score >= 0.7
        ? 'Wall, net, rope, ditch: you went through it like it was not there and beat the platoon record.'
        : score >= 0.4
        ? 'Muddy and on time. The sergeant said nothing, which is a compliment.'
        : 'The rope won. The sergeant had a lot to say about it.',
    [_meterNote(l, up)],
  );
}

List<String> _militaryYear(Life l, Random rng, int beat) {
  if (beat == 1 && rng.nextInt(100) < 50) {
    l.sceneQueue.add('hub:military:exercise');
  }
  return const [];
}

Storylet _exerciseScene(Life l) => _scene(
  'military_exercise',
  'A night exercise on the moors. Your section is lost, cold and behind schedule. There is a short cut across a bog the map says to avoid.',
  [
    Choice(
      label: 'Take charge and navigate',
      outcome: '',
      risk: 'Needs a cool head',
      run: (l, rng) {
        if (rng.nextInt(100) < 45 + l.stats['smarts'] ~/ 3) {
          _bump(l, 7);
          return 'You found the checkpoint with ten minutes to spare. The officers noticed who was leading. Readiness +7.';
        }
        _bump(l, 1);
        return 'You got them there late, but together. A lesson in humility and map reading.';
      },
    ),
    Choice(
      label: 'Cut across the bog',
      outcome: '',
      risk: 'Risky',
      run: (l, rng) {
        if (rng.nextInt(100) < 40) {
          _bump(l, 4);
          return 'You made it, wet to the waist and first to the checkpoint. Readiness +4.';
        }
        _bump(l, -6);
        l.stats.add('health', -4);
        return 'The bog took a boot and most of your pride. Readiness −6.';
      },
    ),
    Choice(
      label: 'Wait for the corporal\'s call',
      outcome:
          'You followed orders. The section came in last, but nobody got hurt.',
    ),
  ],
);

// ================= Lawyer · Mahogany =================

const _lawyer = HubSpec(
  id: 'lawyer',
  meter: 'Reputation',
  meterBlurb: 'Your name at the bar. Wins, research and good clients build it; losses and shortcuts cost it.',
  seasons: ['Caseload', 'Trial', 'Appeals', 'Review'],
  details: _lawyerDetails,
);

bool isJudge(Life l) => l.careerId == 'lawyer' && l.careerRank >= 3;

List<(String, String)> _lawyerDetails(Life l) => [
  ('Cases won', '${_count(l, 'won')}'),
  ('Cases lost', '${_count(l, 'lost')}'),
  if (isJudge(l)) ('Cases heard', '${_count(l, 'heard')}'),
  if (_count(l, 'probono') > 0) ('Pro bono', '${_count(l, 'probono')}'),
];

String? _counsel(Life l, String judgeSays) =>
    _only(l, 'lawyer', 'lawyers') ?? (isJudge(l) ? judgeSays : null);

final _lawyerActions = <GameAction>[
  GameAction(
    id: 'law_case',
    label: 'Take on a case',
    category: 'Career',
    keywords: ['case', 'client', 'trial', 'court'],
    extraCheck: (l) => _counsel(l, 'Judges hear cases instead'),
    run: (l, rng) {
      l.sceneQueue.insert(0, 'hub:lawyer:case:${rng.nextInt(_cases.length)}');
      return ActionResult('A new file landed on your desk.');
    },
  ),
  GameAction(
    id: 'law_cross',
    label: 'Cross-examine a witness',
    category: 'Career',
    keywords: ['cross-examine', 'objection', 'witness', 'trial'],
    miniGame: 'memory',
    extraCheck: (l) => _counsel(l, 'Judges keep order instead'),
    run: (l, rng) => _cross(l, rng, 0.6),
    scored: _cross,
  ),
  GameAction(
    id: 'law_research',
    label: 'Research precedent',
    category: 'Career',
    keywords: ['research', 'library', 'precedent', 'law'],
    extraCheck: (l) => _only(l, 'lawyer', 'lawyers'),
    run: (l, rng) => _with(
      statChange(
        l,
        'A week in the law library with a case from 1887 that nobody else had read. It changes everything, slightly.',
        {'smarts': 2},
      ),
      [_meterNote(l, 3)],
    ),
  ),
  GameAction(
    id: 'law_client',
    label: 'Court a wealthy client',
    category: 'Career',
    keywords: ['client', 'lunch', 'networking', 'billing'],
    extraCheck: (l) => _counsel(l, 'Judges cannot take clients'),
    run: (l, rng) {
      final odds = 35 + l.stats['charisma'] ~/ 2;
      if (rng.nextInt(100) >= odds) {
        return ActionResult(
          'Three lunches, one golf day and a polite "we will be in touch". They were not.',
          [_meterNote(l, -1)],
        );
      }
      final fee = 8000 + 6000 * l.careerRank;
      l.money += fee;
      return ActionResult(
        'A shipping company with a lot of disputes and a large retainer. The partners smiled at you in the corridor.',
        [_meterNote(l, 4), 'Money +${_m(fee)}'],
      );
    },
  ),
  GameAction(
    id: 'law_probono',
    label: 'Work a case pro bono',
    category: 'Career',
    keywords: ['pro bono', 'free', 'charity', 'help'],
    extraCheck: (l) => _counsel(l, 'Judges cannot take cases'),
    run: (l, rng) {
      _add(l, 'probono');
      return _with(
        statChange(
          l,
          'A tenant facing eviction from a landlord who forgot the law. You reminded him. She kept her home.',
          {'karma': 4, 'happiness': 2},
        ),
        [_meterNote(l, 2)],
      );
    },
  ),
  GameAction(
    id: 'law_hear',
    label: 'Hear a case',
    category: 'Career',
    keywords: ['judge', 'hear', 'sentence', 'bench'],
    extraCheck: (l) =>
        _only(l, 'lawyer', 'lawyers') ?? (!isJudge(l) ? 'Judges only' : null),
    run: (l, rng) {
      l.sceneQueue.insert(0, 'hub:lawyer:bench:${rng.nextInt(1000)}');
      return ActionResult('"All rise."');
    },
  ),
];

/// (who, what, side): cases a lawyer can take.
const _cases = <(String, String, String)>[
  (
    'a teenager',
    'accused of a burglary he swears he did not commit',
    'defence',
  ),
  ('the city', 'prosecuting a landlord for unsafe flats', 'prosecution'),
  ('a café owner', 'suing a chain that copied her name', 'civil'),
  ('a nurse', 'accused of stealing medicine from the ward', 'defence'),
  (
    'the state',
    'prosecuting a fraud that emptied a pension fund',
    'prosecution',
  ),
  ('a family', 'suing a builder whose wall fell on their car', 'civil'),
];

Storylet _caseScene(Life l, String? which) {
  final i = (int.tryParse(which ?? '') ?? 0) % _cases.length;
  final (who, what, side) = _cases[i];
  String result(Life l, Random rng, int bonus, String how) {
    final odds = 30 + l.stats['smarts'] ~/ 3 + hubMeter(l) ~/ 4 + bonus;
    if (rng.nextInt(100) < odds) {
      _add(l, 'won');
      _bump(l, 7);
      final fee = 4000 + 3000 * l.careerRank;
      l.money += fee;
      _log(l, 'won a $side case');
      return '$how The verdict went your way, with a ${_m(fee)} bonus. Reputation +7.';
    }
    _add(l, 'lost');
    _bump(l, -4);
    return '$how The verdict went against you. Reputation −4.';
  }

  return _scene(
    'lawyer_case',
    'You are acting for $who, $what. It is a $side case and it comes to trial this term.',
    [
      Choice(
        label: 'Prepare thoroughly',
        outcome: '',
        risk: 'Steady',
        run: (l, rng) {
          l.stats.add('happiness', -1);
          return result(
            l,
            rng,
            10,
            'Late nights and a binder the size of a brick.',
          );
        },
      ),
      Choice(
        label: 'Rely on your closing speech',
        outcome: '',
        risk: 'Depends on your charisma',
        run: (l, rng) => result(
          l,
          rng,
          l.stats['charisma'] ~/ 5 - 5,
          'You kept the jury\'s eyes on you for twenty minutes.',
        ),
      ),
      Choice(
        label: 'Bend the rules a little',
        outcome: '',
        risk: 'Could end your career',
        run: (l, rng) {
          l.stats.add('karma', -4);
          if (rng.nextInt(100) < 20) {
            _bump(l, -20);
            l.performance = max(0, l.performance - 30);
            l.marks.add('scandal:lawyer:${l.age}');
            _log(l, 'reported to the bar for misconduct');
            return 'A witness you coached told the judge. You were reported to the bar. Reputation −20.';
          }
          return result(l, rng, 20, 'A document arrived late, conveniently.');
        },
      ),
    ],
  );
}

ActionResult _cross(Life l, Random rng, double score) {
  final up = ((score - 0.4) * 14).round();
  return ActionResult(
    score >= 0.7
        ? '"You said the car was red. Your statement says blue." The witness had nothing, and the case turned.'
        : score >= 0.4
        ? 'You found one crack in the story. The jury leaned forward.'
        : 'You asked one question too many and the witness explained everything, beautifully, for the other side.',
    [_meterNote(l, up)],
  );
}

// ================= Street hustler · Market Day =================

const _hustler = HubSpec(
  id: 'hustler',
  meter: 'Street rep',
  meterBlurb: 'How well the street knows you. Busking, selling and a good pitch build it; fines and slow seasons cost it.',
  seasons: ['Market days', 'Festival season', 'Autumn', 'Winter'],
  details: _hustlerDetails,
);

/// (id, name, what it is like, takings multiplier, fine risk without a
/// licence).
const _pitches = <(String, String, String, int, int)>[
  ('high', 'The high street', 'Busy, but the council patrols', 3, 25),
  ('market', 'The covered market', 'Steady regulars, few fines', 2, 5),
  ('square', 'The tourist square', 'Big tips, lots of competition', 4, 15),
];

(String, String, String, int, int)? hustlerPitch(Life l) {
  final id = l.hub['pitch'];
  for (final p in _pitches) {
    if (p.$1 == id) return p;
  }
  return null;
}

bool hasLicence(Life l) => l.hub['licence'] == true;

List<(String, String)> _hustlerDetails(Life l) => [
  ('Pitch', hustlerPitch(l)?.$2 ?? 'Not chosen'),
  ('Trading licence', hasLicence(l) ? 'Yes' : 'No'),
  ('Fines paid', '${_count(l, 'fines')}'),
];

String? _hustlerCheck(Life l) =>
    _only(l, 'hustler', 'street hustlers') ??
    (hustlerPitch(l) == null ? 'Pick a pitch first' : null);

/// Takings from a day at your pitch, with the council's fine risk.
ActionResult _streetDay(Life l, Random rng, String text, int base, int up) {
  final p = hustlerPitch(l)!;
  final take = base * p.$4 + rng.nextInt(base);
  l.money += take;
  if (!hasLicence(l) && rng.nextInt(100) < p.$5) {
    _add(l, 'fines');
    l.money -= 150;
    return ActionResult(
      '$text Then a council officer asked for your licence: a ${_m(150)} fine.',
      [_meterNote(l, up - 2), 'Money +${_m(take - 150)}'],
    );
  }
  return ActionResult(text, [_meterNote(l, up), 'Money +${_m(take)}']);
}

final _hustlerActions = <GameAction>[
  GameAction(
    id: 'hus_pitch',
    label: 'Pick a pitch',
    category: 'Career',
    keywords: ['pitch', 'street', 'spot', 'corner'],
    extraCheck: (l) => _only(l, 'hustler', 'street hustlers'),
    run: (l, rng) {
      l.sceneQueue.insert(0, 'hub:hustler:pitch');
      return ActionResult('You walked the town looking for the right spot.');
    },
  ),
  GameAction(
    id: 'hus_busk',
    label: 'Busk',
    category: 'Career',
    keywords: ['busk', 'music', 'perform', 'play'],
    miniGame: 'rhythm',
    extraCheck: _hustlerCheck,
    run: (l, rng) => _busk(l, rng, 0.6),
    scored: _busk,
  ),
  GameAction(
    id: 'hus_sell',
    label: 'Sell from a stall',
    category: 'Career',
    keywords: ['sell', 'stall', 'market', 'trade'],
    extraCheck: _hustlerCheck,
    run: (l, rng) => _streetDay(
      l,
      rng,
      'Phone cases, umbrellas when it rained and sunglasses when it did not.',
      150,
      3,
    ),
  ),
  GameAction(
    id: 'hus_show',
    label: 'Put on a street show',
    category: 'Career',
    keywords: ['show', 'magic', 'juggle', 'crowd'],
    extraCheck: (l) =>
        _hustlerCheck(l) ?? (l.careerRank < 1 ? 'Street sellers and up' : null),
    run: (l, rng) {
      l.fame = min(100, l.fame + 1);
      return _streetDay(
        l,
        rng,
        'Juggling, a disappearing coin and a volunteer from the crowd who stole the show. A ring of people three deep.',
        220,
        5,
      );
    },
  ),
  GameAction(
    id: 'hus_licence',
    label: 'Buy a trading licence',
    category: 'Career',
    keywords: ['licence', 'permit', 'council', 'legal'],
    cost: 500,
    extraCheck: (l) =>
        _only(l, 'hustler', 'street hustlers') ??
        (hasLicence(l) ? 'You have a licence' : null),
    run: (l, rng) {
      l.money -= 500;
      l.hub['licence'] = true;
      return ActionResult(
        'A laminated card with a bad photo of you. The council officers nod at you now.',
        ['No more fines'],
      );
    },
  ),
];

ActionResult _busk(Life l, Random rng, double score) => _streetDay(
  l,
  rng,
  score >= 0.7
      ? 'You found the groove and the street stopped to listen. Someone filmed it.'
      : score >= 0.4
      ? 'A decent set. A dog sat and listened to the whole thing.'
      : 'Your fingers would not warm up. People walked faster past you.',
  (40 + score * 100).round(),
  ((score - 0.3) * 10).round(),
);

List<String> _hustlerYear(Life l, Random rng, int beat) {
  if (hustlerPitch(l) == null && !l.sceneQueue.contains('hub:hustler:pitch')) {
    l.sceneQueue.add('hub:hustler:pitch');
  }
  if (beat == 1 && hustlerPitch(l) != null) {
    final bonus = 300 + hubMeter(l) * 30;
    l.money += bonus;
    return [
      'Festival season brought crowds to your pitch: ${_m(bonus)} extra.',
    ];
  }
  return const [];
}

Storylet _pitchScene(Life l) => _scene(
  'hustler_pitch',
  'Where will you set up? Every street has its own crowd, and its own problems.${hasLicence(l) ? '' : ' Without a licence, the council can fine you.'}',
  [
    for (final p in _pitches)
      Choice(
        label: p.$2,
        outcome: '',
        risk: p.$3,
        run: (l, rng) {
          l.hub['pitch'] = p.$1;
          l.hub['active'] = l.age;
          return 'You chalked your name on ${p.$2.toLowerCase()}. It is your pitch now.';
        },
      ),
  ],
);

// ================= Wave 2 hooks used by career_hub.dart =================

List<String> _wave2Year(Life l, Random rng, String id, int beat) =>
    switch (id) {
      'model' => _modelYear(l, rng, beat),
      'doctor' => _doctorYear(l, rng, beat),
      'vet' => _vetYear(l, rng, beat),
      'pilot' => _pilotYear(l, rng, beat),
      'military' => _militaryYear(l, rng, beat),
      'hustler' => _hustlerYear(l, rng, beat),
      _ => const [],
    };

Storylet? _wave2Scene(List<String> args, Life l) {
  final which = args.length > 2 ? args[2] : null;
  return switch ('${args[0]}:${args[1]}') {
    'model:cover' => _coverScene(l),
    'doctor:specialty' => _specialtyScene(l),
    'doctor:winter' => _winterScene(l),
    'vet:lambing' => _lambingScene(l),
    'pilot:divert' => _divertScene(l),
    'military:exercise' => _exerciseScene(l),
    'lawyer:case' => _caseScene(l, which),
    'lawyer:bench' => _hearingScene(l, which),
    'hustler:pitch' => _pitchScene(l),
    _ => null,
  };
}

/// Extra rules for the next rank (beyond the meter), or null.
String? _wave2Needs(Life l, String id, String meter, int need) => switch (id) {
  'model' when l.careerRank >= 1 && _count(l, 'campaigns') == 0 =>
    'Front a brand campaign and reach $meter $need',
  'doctor' when l.careerRank >= 1 && doctorSpecialty(l) == null =>
    'Choose a specialty and reach $meter $need',
  'doctor' when l.careerRank >= 2 && _count(l, 'papers') == 0 =>
    'Publish a paper and reach $meter $need',
  'vet' when l.careerRank == 2 && !ownsPractice(l) => 'Open your own practice',
  'pilot' when !checkRidePassed(l) =>
    'Pass your check ride and reach $meter $need',
  'military' when l.careerRank == 2 && l.hub['officer'] != true =>
    'Pass the officer course and reach $meter $need',
  'lawyer' when l.careerRank == 2 && l.stats['karma'] < 50 =>
    'Judges need Karma 50+ and $meter $need',
  'hustler' when hustlerPitch(l) == null => 'Pick a pitch',
  _ => null,
};

String _wave2Promotion(String id) => switch (id) {
  'model' => 'Designers are booking you by name.',
  'doctor' => 'The board saw how the ward runs when you are on it.',
  'vet' => 'Word travels fast in the valleys.',
  'pilot' => 'You moved one seat to the left.',
  'military' => 'Your commanding officer pinned on the new rank.',
  'lawyer' => 'The senior partners have been watching your cases.',
  'hustler' => 'Everyone on the street knows your name now.',
  _ => 'Your work was noticed.',
};

const _wave2Specs = <String, HubSpec>{
  'model': _model,
  'doctor': _doctor,
  'vet': _vet,
  'pilot': _pilot,
  'military': _military,
  'lawyer': _lawyer,
  'hustler': _hustler,
};

final _wave2Actions = <GameAction>[
  ..._modelActions,
  ..._doctorActions,
  ..._vetActions,
  ..._pilotActions,
  ..._militaryActions,
  ..._lawyerActions,
  ..._hustlerActions,
];

const _wave2Prefixes = {
  'mod_': 'model',
  'doc_': 'doctor',
  'vet_': 'vet',
  'pil_': 'pilot',
  'mil_': 'military',
  'law_': 'lawyer',
  'hus_': 'hustler',
};

/// Moves a Hub career's meter from scenes elsewhere (jobs.dart's
/// deployment, hospital case and big case).
void hubBoost(Life l, int by) {
  if (hubFor(l) != null && hubSpecs[l.careerId]?.meterOf == null) {
    _bump(l, by);
  }
}
