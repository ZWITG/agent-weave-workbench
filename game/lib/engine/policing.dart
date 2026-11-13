import 'dart:math';

import 'careers.dart' show careerById;
import 'jobs.dart' show leaveJob;
import 'justice.dart' show crimeById;
import 'models.dart';
import 'storylet.dart';
import 'underworld.dart' show crewById, crewList;

// The other side of the law (player wishlist: a police academy path).
//
// - Academy: a new recruit sits three tests (fitness, the law exam, the
//   range), each played as a mini-game; pass two of three to graduate.
// - Casework: crimes from the same list players commit, investigated with
//   the same evidence numbers (0–100). Charges stick with roughly that
//   chance, and every choice shows its odds.
// - Promotion by closed cases: 3 for Sergeant, 6 for Detective, 12 (and a
//   clean file) for Police chief.
// - Corruption: crews offer envelopes; planted evidence works; both build a
//   file that Internal Affairs may open.
// - Undercover: detectives can go inside a crew; cover rises and falls with
//   each test, and the takedown is the biggest case of a career.

String _m(int v) =>
    '\$${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'work',
  scene: true,
  choices: choices,
);

bool isCop(Life l) => l.careerId == 'police' && l.job != null;

// ---------------- Counters kept in marks ----------------

int _count(Life l, String key) {
  for (final m in l.marks) {
    if (m.startsWith('$key:')) {
      return int.tryParse(m.substring(key.length + 1)) ?? 0;
    }
  }
  return 0;
}

void _set(Life l, String key, int v) {
  l.marks
    ..removeWhere((m) => m.startsWith('$key:'))
    ..add('$key:$v');
}

int casesClosed(Life l) => _count(l, 'cop_closed');
int casesLost(Life l) => _count(l, 'cop_lost');

/// Bribes taken and evidence planted: what Internal Affairs could find.
int dirtyFile(Life l) => _count(l, 'cop_dirty');

bool academyDone(Life l) => l.marks.contains('academy_done');

/// Undercover: the crew you are inside, and how solid your cover is.
String? undercoverIn(Life l) {
  for (final m in l.marks) {
    if (m.startsWith('undercover:')) return m.split(':')[1];
  }
  return null;
}

int cover(Life l) => _count(l, 'cop_cover');

int _undercoverSince(Life l) {
  for (final m in l.marks) {
    if (m.startsWith('undercover:')) {
      return int.tryParse(m.split(':')[2]) ?? l.age;
    }
  }
  return l.age;
}

// ---------------- Rank ----------------

/// Moves you to a ladder step (police careers only).
String _rankUp(Life l, int rank, String why) {
  final c = careerById('police')!;
  if (rank <= l.careerRank || rank >= c.ladder.length) return '';
  l.careerRank = rank;
  l.jobSince = l.age;
  l.job = c.ladder[rank];
  l.salary = c.payIn(l, rank);
  l.performance = max(l.performance, 60);
  if (rank == c.ladder.length - 1) {
    l.flags['top_of_career'] = Memory(l.age, 'becoming ${l.job}');
  }
  return '$why You are now ${l.job} (${_m(l.salary)} a year).';
}

/// What the next rank needs, for the badge card.
String? nextRankNeeds(Life l) {
  if (!isCop(l)) return null;
  return switch (l.careerRank) {
    0 => 'Pass the academy: two of three tests',
    1 => 'Close ${max(0, 3 - casesClosed(l))} more cases for Sergeant',
    2 => 'Close ${max(0, 6 - casesClosed(l))} more cases for Detective',
    3 =>
      dirtyFile(l) > 0
          ? 'A clean file and 12 closed cases for Police chief'
          : 'Close ${max(0, 12 - casesClosed(l))} more cases for Police chief',
    _ => null,
  };
}

// ---------------- Each year on the force ----------------

List<String> policeYear(Life l, Random rng) {
  final feed = <String>[];
  if (!isCop(l)) return feed;
  if (l.careerRank == 0) {
    if (!academyDone(l) && !l.sceneQueue.any((q) => q.startsWith('academy'))) {
      l.sceneQueue.add('academy:fitness');
    }
    return feed;
  }
  // A crew you crossed does not forget.
  for (final m in l.marks.where((m) => m.startsWith('crew_grudge:')).toList()) {
    if (rng.nextInt(100) < 10) {
      final crew = crewById(m.split(':')[1]);
      l.stats.add('happiness', -3);
      feed.add(
        'A brick came through your front window with a note tied to it: a drawing of a badge, crossed out. ${crew.name} still remembers you.',
      );
      break;
    }
  }
  // Promotion by results.
  final closed = casesClosed(l);
  final up = switch (l.careerRank) {
    1 when closed >= 3 => _rankUp(
      l,
      2,
      'Three cases closed and a commendation on your file.',
    ),
    2 when closed >= 6 => _rankUp(
      l,
      3,
      'You made detective: plain clothes and the hard cases.',
    ),
    3 when closed >= 12 && dirtyFile(l) == 0 && rng.nextInt(100) < 35 =>
      _rankUp(l, 4, 'The mayor shook your hand in front of the cameras.'),
    _ => '',
  };
  if (up.isNotEmpty) feed.add(up);

  final crew = undercoverIn(l);
  if (crew != null) {
    if (l.age - _undercoverSince(l) >= 2 && cover(l) >= 30) {
      l.sceneQueue.add('undercover:bust');
    } else {
      l.sceneQueue.add('undercover:test');
    }
    return feed;
  }
  // Internal Affairs reads the file.
  final dirt = dirtyFile(l);
  if (dirt > 0 && rng.nextInt(100) < min(60, 10 * dirt)) {
    l.sceneQueue.add('internal_affairs');
    return feed;
  }
  if (rng.nextInt(100) < 60) {
    final pool = l.careerRank >= 3
        ? const [
            'fraud',
            'armed_robbery',
            'murder',
            'smuggling',
            'extortion',
            'hacking',
          ]
        : const [
            'shoplifting',
            'burglary',
            'car_theft',
            'assault',
            'vandalism',
            'porch_theft',
          ];
    final crime = pool[rng.nextInt(pool.length)];
    l.sceneQueue.add('beat_case:$crime:${20 + rng.nextInt(21)}');
  }
  if (rng.nextInt(100) < 15) {
    l.sceneQueue.add(
      'bribe_offer:${crewList[rng.nextInt(crewList.length)].id}',
    );
  }
  if (l.careerRank >= 3 && rng.nextInt(100) < 18) {
    l.sceneQueue.add('undercover:offer');
  }
  return feed;
}

// ---------------- Scenes ----------------

Storylet? policeScene(String id, List<String> args, Life l) {
  if (!isCop(l)) return null;
  switch (id) {
    case 'academy':
      return _academy(args.isEmpty ? 'fitness' : args.first, l);
    case 'beat_case':
      return _caseOpen(args, l);
    case 'case_build':
      return _caseBuild(args, l);
    case 'bribe_offer':
      return _bribe(args, l);
    case 'internal_affairs':
      return _internalAffairs(l);
    case 'undercover':
      return _undercover(args.isEmpty ? 'offer' : args.first, l);
  }
  return null;
}

// ---- Academy ----

Storylet _academy(String step, Life l) {
  final (text, game, stat, label, next) = switch (step) {
    'fitness' => (
      'Police academy, day one. A sergeant with a whistle and no patience: "Press-ups until I say stop, recruits." Three tests stand between you and a badge: fitness, the law exam and the range.',
      'reps',
      'athleticism',
      'Give it everything',
      'exam',
    ),
    'exam' => (
      'The law exam: a cold hall, a ticking clock and three hundred questions on powers of arrest, evidence and the rights of the accused.',
      'quiz',
      'smarts',
      'Answer the questions',
      'range',
    ),
    _ => (
      'The firing range. Ear defenders, a paper target, an instructor at your shoulder: "Breathe out. Squeeze. Do not snatch it."',
      'timing',
      'discipline',
      'Hold steady and squeeze',
      'done',
    ),
  };
  String pass(Life l, bool ok) {
    if (ok) l.marks.add('academy_pass:$step');
    if (next != 'done') {
      l.sceneQueue.insert(0, 'academy:$next');
      return ok
          ? 'Passed. One step closer to the badge.'
          : 'Not your day. You will need to pass the other two.';
    }
    final passed = l.marks.where((m) => m.startsWith('academy_pass:')).length;
    l.marks.removeWhere((m) => m.startsWith('academy_pass:'));
    if (passed >= 2) {
      l.marks.add('academy_done');
      l.flags['academy'] = Memory(l.age, 'graduating from the police academy');
      l.stats.add('happiness', 6);
      return '$passed of 3 tests passed. Your family watched you march at the passing-out parade. ${_rankUp(l, 1, 'You graduated.')}';
    }
    l.stats.add('happiness', -4);
    return 'Only $passed of 3 tests passed. You stay a cadet and sit the academy again next year.';
  }

  final odds = (35 + (l.stats[stat] - 50) ~/ 2).clamp(10, 85);
  return _scene('academy', text, [
    Choice(
      label: label,
      outcome: '',
      risk: 'Played as a mini-game · $odds% chance to pass at an average try',
      miniGame: game,
      scored: (l, rng, score) {
        final p = (odds + ((score - 0.6) * 100).round()).clamp(5, 95);
        return pass(l, rng.nextInt(100) < p);
      },
    ),
    Choice(
      label: 'Wing it',
      outcome: '',
      risk: '$odds% chance to pass',
      run: (l, rng) => pass(l, rng.nextInt(100) < odds),
    ),
  ]);
}

// ---- Casework ----

String _caseIntro(String crime) => switch (crime) {
  'shoplifting' => 'A corner shop has been losing stock every Friday night. The owner has a grainy camera and a theory.',
  'burglary' => 'Three break-ins on the same street in a month. No witnesses, and a neighbour who seems to know more than he says.',
  'car_theft' => 'Four cars gone from the same multi-storey car park, all the same make, all at night.',
  'assault' => 'A fight outside a nightclub left a man in hospital. Twenty people saw it and nobody saw anything.',
  'vandalism' => 'Someone keeps spraying the war memorial. The council wants a name before the anniversary.',
  'porch_theft' => 'Parcels are vanishing off doorsteps across a whole estate. The delivery firm blames the residents.',
  'fraud' => 'Pensioners across the city have lost their savings to the same polite voice on the phone.',
  'armed_robbery' => 'Two masked men took a post office with a sawn-off shotgun. The getaway car turned up burnt out by the river.',
  'murder' => 'A body in a canal, a missing wallet and a widow who will not look you in the eye.',
  'smuggling' => 'Customs found a false floor in a lorry, empty. Someone got the cargo out first.',
  'extortion' => 'Every shop on one high street pays "insurance" to the same two men. None of them will make a statement.',
  'hacking' =>
    'A hospital\'s records were locked and a ransom note left on every screen.',
  _ => 'A new file lands on your desk.',
};

Storylet? _caseOpen(List<String> args, Life l) {
  if (args.isEmpty || l.careerRank < 1) return null;
  final crime = args[0];
  final ev = int.tryParse(args.length > 1 ? args[1] : '') ?? 25;
  final label = crimeById(crime).label.toLowerCase();
  Choice lead(
    String text,
    String note,
    int lo,
    int hi, {
    String? Function(Life, Random)? side,
  }) => Choice(
    label: text,
    outcome: '',
    risk: '$note · evidence +$lo to +$hi',
    run: (l, rng) {
      final gain = lo + rng.nextInt(hi - lo + 1);
      final now = min(100, ev + gain);
      final extra = side?.call(l, rng);
      l.sceneQueue.insert(0, 'case_build:$crime:$now');
      return '${extra ?? 'The file gets thicker.'} Evidence on the $label: $now/100.';
    },
  );
  final ch = (l.stats['charisma'] - 50) ~/ 5,
      sm = (l.stats['smarts'] - 50) ~/ 5;
  return _scene(
    'beat_case',
    '${_caseIntro(crime)} Evidence so far: $ev/100. Charges usually need 60 or more.',
    [
      lead(
        'Knock on doors',
        'Charisma helps',
        10 + max(0, ch),
        25 + max(0, ch),
      ),
      lead(
        'Send it to forensics',
        'Smarts helps · stressful',
        15 + max(0, sm),
        30 + max(0, sm),
        side: (l, rng) {
          l.stress = l.stress + 4;
          return 'Weeks of lab reports and late nights.';
        },
      ),
      lead(
        'Stake it out',
        'Long cold nights',
        20,
        30,
        side: (l, rng) {
          l.stats.add('health', -1);
          return 'Three nights in a car with bad coffee, then movement.';
        },
      ),
      lead(
        'Lean hard on a suspect',
        'Fast, but complaints happen (25%)',
        25,
        40,
        side: (l, rng) {
          if (rng.nextInt(100) < 25) {
            l.performance = max(0, l.performance - 10);
            l.stats.add('karma', -3);
            return 'A complaint went in about your methods. It is on your file now.';
          }
          return 'He cracked in the interview room after four hours.';
        },
      ),
    ],
  );
}

Storylet? _caseBuild(List<String> args, Life l) {
  if (args.length < 2) return null;
  final crime = args[0];
  final ev = int.tryParse(args[1]) ?? 40;
  final dug = args.length > 2;
  final label = crimeById(crime).label.toLowerCase();
  String charge(Life l, Random rng, int chance, {bool planted = false}) {
    if (planted) {
      _set(l, 'cop_dirty', dirtyFile(l) + 2);
      l.stats.add('karma', -10);
    }
    if (rng.nextInt(100) < chance) {
      _set(l, 'cop_closed', casesClosed(l) + 1);
      l.performance = min(100, l.performance + (crime == 'murder' ? 18 : 10));
      l.stats.add('happiness', 3);
      return planted
          ? 'Guilty. The jury believed the bag you "found" in the boot. You tell yourself he did it anyway. Cases closed: ${casesClosed(l)}.'
          : 'Guilty. The $label case is closed and the station bought you a drink. Cases closed: ${casesClosed(l)}.';
    }
    _set(l, 'cop_lost', casesLost(l) + 1);
    l.performance = max(0, l.performance - 6);
    l.stats.add('happiness', -3);
    return 'Not guilty. The defence pulled your evidence apart in an afternoon. (Conviction chance was $chance%.)';
  }

  final chance = ev.clamp(5, 95);
  final planted = min(92, ev + 45);
  return _scene(
    'case_build',
    'The $label file: evidence $ev/100. The prosecutor will take it to court if you say so.',
    [
      Choice(
        label: 'Charge them',
        outcome: '',
        risk: '$chance% chance of a conviction',
        run: (l, rng) => charge(l, rng, chance),
      ),
      if (!dug)
        Choice(
          label: 'Keep digging',
          outcome: '',
          risk: 'Evidence +10 to +20 · 30% the trail goes cold',
          run: (l, rng) {
            if (rng.nextInt(100) < 30) {
              _set(l, 'cop_lost', casesLost(l) + 1);
              return 'The suspect left the country while you were digging. The file went into a box in the basement.';
            }
            final now = min(100, ev + 10 + rng.nextInt(11));
            l.sceneQueue.insert(0, 'case_build:$crime:$now:dug');
            return 'Another month, another witness. Evidence: $now/100.';
          },
        ),
      Choice(
        label: 'Plant something to make it stick',
        outcome: '',
        risk:
            '$planted% chance · Karma down · goes on your Internal Affairs file',
        run: (l, rng) => charge(l, rng, planted, planted: true),
      ),
      Choice(
        label: 'Let it go',
        outcome: 'You shelved the file. Not every case can be won.',
      ),
    ],
  );
}

// ---- Corruption ----

Storylet? _bribe(List<String> args, Life l) {
  if (args.isEmpty || l.careerRank < 1) return null;
  final crew = crewById(args.first);
  final amount = 5000 * (l.careerRank + 1);
  return _scene(
    'bribe_offer',
    'A man in a good coat sits next to you on a park bench. "${crew.name} would be grateful if a few things went missing from the evidence room. Very grateful." An envelope with ${_m(amount)} slides along the bench.',
    [
      Choice(
        label: 'Take the envelope',
        outcome: '',
        risk: 'Dirty money · goes on your Internal Affairs file',
        run: (l, rng) {
          l.money += amount;
          l.dirty += amount;
          _set(l, 'cop_dirty', dirtyFile(l) + 1);
          l.stats.add('karma', -6);
          return 'You put it in your inside pocket. A box of seized phones went missing that week. Nobody asked you.';
        },
      ),
      Choice(
        label: 'Say no',
        outcome: '',
        run: (l, rng) {
          l.stats.add('karma', 3);
          return '"Shame," he said, and walked off without looking back.';
        },
      ),
      Choice(
        label: 'Report it',
        outcome: '',
        risk: 'Performance up · the crew will not forget',
        run: (l, rng) {
          l.performance = min(100, l.performance + 10);
          l.stats.add('karma', 6);
          l.marks.add('crew_grudge:${crew.id}');
          return 'You wrote it up and handed in the envelope. Your superintendent nodded slowly. Somewhere, ${crew.name} learned your name.';
        },
      ),
    ],
  );
}

Storylet _internalAffairs(Life l) {
  final deny = (40 + (l.stats['charisma'] - 50) ~/ 2 - dirtyFile(l) * 5).clamp(
    5,
    80,
  );
  String fired(Life l, String how) {
    _set(l, 'cop_dirty', 0);
    leaveJob(l, fired: true);
    l.cases.add({'crime': 'embezzlement', 'age': l.age, 'evidence': 55});
    l.stats.add('happiness', -10);
    return '$how You handed in your badge, and the file went to prosecutors.';
  }

  return _scene(
    'internal_affairs',
    'Two officers from Internal Affairs are waiting at your desk. "We need to talk about some evidence, and some money."',
    [
      Choice(
        label: 'Hire a federation lawyer (\$8,000)',
        outcome: '',
        needsMoney: 8000,
        risk: '60% you keep your job',
        run: (l, rng) {
          l.money -= 8000;
          if (rng.nextInt(100) < 60) {
            _set(l, 'cop_dirty', max(0, dirtyFile(l) - 2));
            l.performance = max(0, l.performance - 10);
            return 'Your lawyer found a procedural hole. Final written warning. You are on thin ice.';
          }
          return fired(
            l,
            'Even the lawyer could not argue with the bank statements.',
          );
        },
      ),
      Choice(
        label: 'Deny everything',
        outcome: '',
        risk: '$deny% they cannot prove it (Charisma)',
        run: (l, rng) {
          if (rng.nextInt(100) < deny) {
            _set(l, 'cop_dirty', max(0, dirtyFile(l) - 1));
            return 'You looked them in the eye for three hours. They closed the inquiry, for now.';
          }
          return fired(l, 'They had photos of the park bench.');
        },
      ),
      Choice(
        label: 'Resign quietly',
        outcome: '',
        risk: 'No charges, no badge',
        run: (l, rng) {
          _set(l, 'cop_dirty', 0);
          leaveJob(l);
          l.stats.add('karma', 3);
          return 'You resigned before the hearing. The file was quietly closed, and so was your career.';
        },
      ),
    ],
  );
}

// ---- Undercover ----

Storylet? _undercover(String step, Life l) {
  final crewId = undercoverIn(l);
  switch (step) {
    case 'offer':
      if (crewId != null || l.careerRank < 3) return null;
      final crew = crewList[(l.age + l.seed) % crewList.length];
      return _scene(
        'undercover',
        'Your superintendent closes the blinds. "${crew.name}. We have tried everything from the outside. We need someone inside. Two years, maybe more. Nobody can know, not even your family."',
        [
          Choice(
            label: 'Go undercover',
            outcome: '',
            risk: 'Two years inside a crew · the biggest case of a career, if your cover holds',
            run: (l, rng) {
              l.marks.add('undercover:${crew.id}:${l.age}');
              _set(l, 'cop_cover', 60);
              l.stats.add('happiness', -3);
              return 'You grew a beard, learned a new name and started drinking in the right bars.';
            },
          ),
          Choice(
            label: 'Say no',
            outcome: 'You said you had a family to think about. The superintendent understood, mostly.',
          ),
        ],
      );
    case 'test':
      if (crewId == null) return null;
      final crew = crewById(crewId);
      final c = cover(l);
      final bluff = (40 + (l.stats['charisma'] - 50) ~/ 2).clamp(10, 85);
      String after(Life l, int change, String text) {
        final now = (c + change).clamp(0, 100);
        _set(l, 'cop_cover', now);
        if (now <= 0) {
          l.sceneQueue.insert(0, 'undercover:blown');
          return '$text Somebody is looking at you differently.';
        }
        return '$text Cover: $now%.';
      }

      return _scene(
        'undercover',
        'A year inside ${crew.name}. Tonight they want you to prove yourself on a ${crew.crime} job. Your handler cannot reach you in time. Cover: $c%.',
        [
          Choice(
            label: 'Do the job',
            outcome: '',
            risk: 'Cover up a lot · Karma down',
            run: (l, rng) {
              l.stats.add('karma', -6);
              return after(
                l,
                20,
                'You did it, and did it well. They poured you a drink.',
              );
            },
          ),
          Choice(
            label: 'Fake it',
            outcome: '',
            risk: '$bluff% they buy it (Charisma)',
            run: (l, rng) => rng.nextInt(100) < bluff
                ? after(l, 5, 'You made it look real without breaking the law.')
                : after(
                    l,
                    -35,
                    'Somebody noticed you never actually took anything.',
                  ),
          ),
          Choice(
            label: 'Refuse',
            outcome: '',
            risk: 'Cover down a lot',
            run: (l, rng) => after(
              l,
              -30,
              'You said you had a bad feeling about it. They did not like that.',
            ),
          ),
        ],
      );
    case 'blown':
      if (crewId == null) return null;
      final crew = crewById(crewId);
      final run = (40 + (l.stats['athleticism'] - 50) ~/ 3).clamp(10, 80);
      String out(Life l, bool away) {
        l.marks.removeWhere(
          (m) => m.startsWith('undercover:') || m.startsWith('cop_cover:'),
        );
        l.marks.add('crew_grudge:${crew.id}');
        if (away) {
          return 'You made it to the safe house with your handler on the phone. The operation is dead, but you are alive.';
        }
        l.stats.add('health', -30);
        l.stats.add('happiness', -10);
        return 'They caught you in a car park. You woke up in hospital three days later. The operation is over.';
      }

      return _scene(
        'undercover',
        'Your phone buzzes: "THEY KNOW. GET OUT." A car without lights pulls into the street behind you. ${crew.name} found the wire.',
        [
          Choice(
            label: 'Drive',
            outcome: '',
            risk: '$run% chance to get away (Athleticism) · played as a chase',
            miniGame: 'getaway',
            scored: (l, rng, score) {
              final p = (run + ((score - 0.6) * 80).round()).clamp(5, 95);
              return out(l, rng.nextInt(100) < p);
            },
          ),
        ],
      );
    case 'bust':
      if (crewId == null) return null;
      final crew = crewById(crewId);
      return _scene(
        'undercover',
        'Two years of recordings, ledgers and names. Tonight a hundred officers are waiting for your signal outside every address ${crew.name} owns.',
        [
          Choice(
            label: 'Give the signal',
            outcome: '',
            run: (l, rng) {
              l.marks.removeWhere(
                (m) =>
                    m.startsWith('undercover:') || m.startsWith('cop_cover:'),
              );
              _set(l, 'cop_closed', casesClosed(l) + 5);
              l.performance = 100;
              l.fame = min(100, l.fame + 10);
              l.stats.add('happiness', 10);
              l.flags['takedown'] = Memory(l.age, 'bringing down ${crew.name}');
              final rank = l.careerRank + 1;
              final up = _rankUp(
                l,
                rank,
                'The takedown made the national news.',
              );
              return 'Dawn raids across the city. Thirty-one arrests, and the boss of ${crew.name} in handcuffs. ${up.isEmpty ? 'The commissioner called you personally.' : up}';
            },
          ),
        ],
      );
  }
  return null;
}
