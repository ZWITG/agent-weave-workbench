import 'dart:math';

import 'actions.dart';
import 'justice.dart' show onParole;
import 'love.dart' show recircle;
import 'models.dart';
import 'storylet.dart';

// Life inside and after prison: visits, contraband, jobs with perks and
// trustee status, named courses that matter after release, solitary
// confinement, life on the run after an escape, parole check-ins, sealing
// a record, the old crew coming calling, and a halfway house.

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'crime',
  scene: true,
  choices: choices,
);

String _first(Npc n) => n.name.split(' ').first;

String? _inPrison(Life l) => l.prison == null ? 'Only in prison' : null;

// ---------------- Visits ----------------

List<Npc> visitors(Life l) =>
    (l.npcs
        .where(
          (n) =>
              n.alive &&
              !n.contactCut &&
              const {
                'Family',
                'Partner',
                'Friends',
                'Children',
              }.contains(n.circle) &&
              !(l.prison?.banned.contains(n.id) ?? false) &&
              (n.circle != 'Children' || n.ageIn(l.year) >= 4),
        )
        .toList()
      ..sort((a, b) => b.bond.compareTo(a.bond)));

Storylet? visitPickScene(Life l) {
  final p = l.prison;
  if (p == null) return null;
  final who = visitors(l).where((n) => n.bond >= 25).take(4).toList();
  return _scene(
    'visit_pick',
    who.isEmpty
        ? 'You put in a visiting order. Nobody filled it in.'
        : 'Visiting hours are Saturday afternoon. Who do you ask to come?',
    [
      for (final n in who)
        Choice(
          label: '${_first(n)} · ${n.role}',
          outcome: '',
          risk: 'Bond ${n.bond}%',
          run: (l, rng) {
            l.sceneQueue.insert(0, 'visit:${n.id}');
            return '${_first(n)} said yes.';
          },
        ),
      Choice(
        label: 'Nobody this time',
        outcome: 'You spent Saturday on your bunk.',
      ),
    ],
  );
}

Storylet? visitScene(List<String> args, Life l) {
  final p = l.prison;
  final n = args.isEmpty ? null : l.npc(args.first);
  if (p == null || n == null || !n.alive) return null;
  final name = _first(n);
  final partner = n.circle == 'Partner';
  return _scene(
    'visit',
    '$name sits across the plastic table, trying not to look at the guards. "How are you, really?"',
    [
      Choice(
        label: 'Tell them the truth',
        outcome: '',
        run: (l, rng) {
          n.addFacets(affection: 6, trust: 4);
          n.lastContactAge = l.age;
          l.stats.add('happiness', 4);
          return 'You told $name how it really is in here. They held your hand across the table until a guard said no touching.';
        },
      ),
      Choice(
        label: 'Ask them to smuggle something in',
        outcome: '',
        risk: 'Needs Bond 50% · about 30% chance they are caught',
        lock: (l) => n.bond < 50 ? '$name would never agree' : null,
        run: (l, rng) {
          if (rng.nextInt(100) < 30) {
            p.banned.add(n.id);
            p.behaviour = max(0, p.behaviour - 10);
            n.addFacets(affection: -6, resentment: 6);
            return 'The guards found it in $name\'s shoe. They are banned from visiting, and they are furious with you.';
          }
          p.stash += 4;
          n.addFacets(affection: -1);
          return '$name slipped you a packet when they hugged you goodbye. Your stash just got bigger.';
        },
      ),
      if (partner)
        Choice(
          label: 'Ask them to wait for you',
          outcome: '',
          risk: 'Their answer depends on your Bond (${n.bond}%)',
          run: (l, rng) {
            if (rng.nextInt(100) < n.bond) {
              l.marks.add('waiting:${n.id}');
              n.addFacets(affection: 5, trust: 5);
              return '$name squeezed your hand. "I am not going anywhere." You believe them.';
            }
            recircle(l, n, circle: 'Exes', role: 'Ex-partner');
            l.stats.add('happiness', -8);
            return '$name looked at the table for a long time. "I can\'t do ${p.left} more years." It was the last visit.';
          },
        ),
      Choice(
        label: 'Say sorry for what you did',
        outcome: '',
        run: (l, rng) {
          n.addFacets(resentment: -6, trust: 2);
          l.stats.add('karma', 1);
          return '$name was quiet, then nodded. "Then make it count when you get out."';
        },
      ),
    ],
  );
}

// ---------------- Courses ----------------

typedef Course = ({String id, String name, String effect});

const prisonCourses = <Course>[
  (
    id: 'ged',
    name: 'High-school equivalency',
    effect: 'Gives you a school diploma',
  ),
  (
    id: 'trade',
    name: 'Trade certificate',
    effect: 'Better odds at job interviews after release',
  ),
  (
    id: 'anger',
    name: 'Anger management',
    effect: 'Calmer, and the parole board notices',
  ),
  (
    id: 'addiction',
    name: 'Addiction programme',
    effect: 'Moves any addiction into recovery',
  ),
  (
    id: 'degree',
    name: 'Degree by correspondence',
    effect: 'Three years of study for a real degree',
  ),
];

String? courseLock(Life l, Course c) {
  final p = l.prison!;
  if (c.id != 'degree' && p.courses.contains(c.id)) return 'Done';
  return switch (c.id) {
    'ged' =>
      const {'none', 'primary', 'secondary'}.contains(l.education)
          ? null
          : 'You already have a diploma',
    'addiction' => l.addictions.isEmpty ? 'No addiction to treat' : null,
    'degree' =>
      p.courses.contains('degree')
          ? 'Done'
          : l.stats['smarts'] < 55
          ? 'Needs Smarts 55+'
          : const {'none', 'primary', 'secondary'}.contains(l.education)
          ? 'Needs a school diploma first'
          : null,
    _ => null,
  };
}

Storylet? courseScene(Life l) {
  final p = l.prison;
  if (p == null) return null;
  return _scene(
    'prison_course',
    'The education office has a list on the noticeboard. Each course counts at parole, and some follow you out.',
    [
      for (final c in prisonCourses)
        Choice(
          label: c.id == 'degree' && p.degreeYears > 0
              ? '${c.name} (year ${p.degreeYears + 1} of 3)'
              : c.name,
          outcome: '',
          risk: c.effect,
          lock: (l) => courseLock(l, c),
          run: (l, rng) {
            p.programmes++;
            p.behaviour = min(100, p.behaviour + 4);
            l.stats.add('smarts', 2);
            switch (c.id) {
              case 'ged':
                l.education = 'high school graduate';
                p.courses.add('ged');
                return 'You passed the equivalency exam. You framed the certificate with toilet roll tubes.';
              case 'trade':
                p.courses.add('trade');
                l.marks.add('trade_cert');
                l.stats.add('discipline', 2);
                return 'Electrics, plumbing and a lot of measuring twice. You are now qualified.';
              case 'anger':
                p.courses.add('anger');
                l.stats.add('impulsivity', -6);
                l.stats.add('willpower', 3);
                return 'Twelve weeks of circles and breathing. It works better than you will admit.';
              case 'addiction':
                p.courses.add('addiction');
                for (final k in l.addictions.keys.toList()) {
                  l.addictions.remove(k);
                  l.recovery[k] = l.age;
                }
                return 'The programme was hard and honest. You are in recovery now, one day at a time.';
              default:
                p.degreeYears++;
                if (p.degreeYears >= 3) {
                  p.courses.add('degree');
                  l.education = 'graduate';
                  l.school.degrees.add('Degree by correspondence');
                  return 'Three years of envelopes and essays. You graduated in a prison classroom, in a paper hat.';
                }
                return 'Another year of correspondence study done. ${3 - p.degreeYears} to go.';
            }
          },
        ),
      Choice(label: 'Not this year', outcome: 'You decided to wait.'),
    ],
  );
}

// ---------------- Trustee ----------------

Storylet? trusteeScene(Life l) {
  final p = l.prison;
  if (p == null || p.trustee) return null;
  return _scene(
    'trustee',
    'The governor calls you in. Your record is good: would you like to be a trustee? More freedom, a better cell, and a lot of side-eye from the other inmates.',
    [
      Choice(
        label: 'Accept',
        outcome: '',
        run: (l, rng) {
          p.trustee = true;
          p.behaviour = min(100, p.behaviour + 8);
          p.respect = max(0, p.respect - 6);
          return 'You got a key to the library and a lot of new enemies. Worth it.';
        },
      ),
      Choice(
        label: 'Turn it down',
        outcome: 'You said you would rather keep your head down. Some people respected that.',
      ),
    ],
  );
}

// ---------------- Life on the run ----------------

bool isFugitive(Life l) => l.marks.contains('fugitive');

void recapture(Life l, Random rng) {
  l.marks.remove('fugitive');
  l.cases.removeWhere((c) => c['crime'] == 'escape');
  l.prison = Prison(
    crime: 'escape',
    years: 3 + rng.nextInt(3),
    since: l.age,
    security: 'maximum',
  );
}

Storylet? onTheRunScene(Life l) {
  if (!isFugitive(l)) return null;
  return _scene(
    'on_the_run',
    'Your face was on the news again tonight. A neighbour looked at you a beat too long in the lift.',
    [
      Choice(
        label: 'Lie low',
        outcome: '',
        run: (l, rng) {
          l.stats.add('happiness', -3);
          l.marks.add('lying_low:${l.age}');
          return 'You stayed inside, paid cash and spoke to nobody. Lonely, and safer.';
        },
      ),
      Choice(
        label: 'Buy a new identity (\$5,000)',
        outcome: '',
        needsMoney: 5000,
        run: (l, rng) {
          l.money -= 5000;
          l.marks.add('new_identity');
          return 'A man in a car park sold you a passport and a past. You practise your new signature every night.';
        },
      ),
      Choice(
        label: 'Turn yourself in',
        outcome: '',
        run: (l, rng) {
          l.stats.add('karma', 4);
          recapture(l, rng);
          l.prison!.years = max(1, l.prison!.years - 2);
          l.prison!.security = 'medium';
          return 'You walked into a police station and said your name. The judge noted that you came in by yourself.';
        },
      ),
    ],
  );
}

// ---------------- Parole check-ins ----------------

Storylet? checkinScene(Life l) {
  if (!onParole(l) || l.prison != null) return null;
  return _scene(
    'parole_checkin',
    'Your monthly parole check-in is tomorrow morning, the same time as an interview you really want.',
    [
      Choice(
        label: 'Show up',
        outcome: '',
        run: (l, rng) {
          l.stats.add('discipline', 1);
          return 'Twenty minutes, a urine test and a signature. Your officer says you are doing well.';
        },
      ),
      Choice(
        label: 'Skip it',
        outcome: '',
        risk: 'About 40% chance of a warrant: back inside',
        run: (l, rng) {
          if (rng.nextInt(100) < 40) {
            final m = l.marks.firstWhere((m) => m.startsWith('parole_until:'));
            final left = max(
              1,
              (int.tryParse(m.substring(13)) ?? l.age) - l.age,
            );
            l.marks.removeWhere((m) => m.startsWith('parole_until:'));
            l.prison = Prison(
              crime: 'parole violation',
              years: left,
              since: l.age,
            );
            return 'A warrant went out the same afternoon. You are going back to serve the rest: $left years.';
          }
          return 'Your officer let it go with a warning. Once.';
        },
      ),
      Choice(
        label: 'Ask to reschedule',
        outcome: 'Your officer moved it by a day. Polite, and on the record.',
      ),
    ],
  );
}

// ---------------- The old crew ----------------

Storylet? oldCrewScene(Life l) {
  if (l.prison != null || !l.marks.any((m) => m.startsWith('ex_gang:'))) {
    return null;
  }
  return _scene(
    'old_crew',
    'A face from inside turns up at your door. "The crew remembers you. We need a small favour: hold a bag for a week."',
    [
      Choice(
        label: 'Do the favour',
        outcome: '',
        risk: 'About 30% chance it goes wrong',
        run: (l, rng) {
          if (rng.nextInt(100) < 30) {
            l.sceneQueue.insert(0, 'arrest:burglary:70');
            return 'The police were watching the bag, not you. Now they are watching you.';
          }
          l.money += 1000;
          return 'A week later the bag was gone and an envelope was in its place: \$1,000.';
        },
      ),
      Choice(
        label: 'Refuse',
        outcome: 'You said you are out. They said "for now" and left.',
      ),
      Choice(
        label: 'Tell the police',
        outcome: '',
        risk: 'The crew may find out',
        run: (l, rng) {
          l.stats.add('karma', 3);
          if (rng.nextInt(100) < 30) {
            l.stats.add('health', -6);
            return 'The arrests made the news. Someone made sure you knew they knew.';
          }
          l.marks.removeWhere((m) => m.startsWith('ex_gang:'));
          return 'Three arrests and a quiet thank-you from a detective. Your old crew will not be calling again.';
        },
      ),
    ],
  );
}

// ---------------- Each birthday ----------------

/// Inside: solitary, job perks, cell searches, visits drying up, trustee
/// offers. Outside: life on the run, parole check-ins, the old crew and the
/// halfway house running out.
List<String> prisonLifeYear(Life l, Random rng) {
  final feed = <String>[];
  final p = l.prison;
  if (p != null) {
    if (p.solitary > 0) {
      p.solitary--;
      l.stats.add('happiness', -5);
      l.stats.add('health', -1);
      feed.add(
        p.solitary > 0
            ? 'Another year in solitary. Twenty-three hours a day in a concrete box.'
            : 'You came out of solitary blinking at the light. The yard has never looked so big.',
      );
    }
    switch (p.job) {
      case 'Kitchen':
        p.stash += 2;
        l.stats.add('health', 1);
      case 'Library':
        p.stash += 1;
        l.stats.add('smarts', 1);
      case 'Laundry':
        p.stash += 1;
      case 'Workshop':
        p.stash += 1;
        l.stats.add('creativity', 1);
    }
    if (p.gangId == 'owls') p.stash += 1;
    if (p.trustee) p.behaviour = min(100, p.behaviour + 3);
    final search = switch (p.security) {
      'maximum' => 35,
      'medium' => 25,
      _ => 15,
    };
    if (p.stash >= 6 && rng.nextInt(100) < search) {
      p.stash = 0;
      p.behaviour = max(0, p.behaviour - 10);
      if (rng.nextBool()) p.solitary = max(p.solitary, 1);
      feed.add(
        'A cell search turned up your whole stash. ${p.solitary > 0 ? 'A year in solitary.' : 'Behaviour down.'}',
      );
    }
    for (final n in visitors(l).where((n) => n.circle == 'Partner')) {
      if (n.bond < 35 &&
          p.left >= 3 &&
          !l.marks.contains('waiting:${n.id}') &&
          rng.nextInt(100) < 40) {
        recircle(l, n, circle: 'Exes', role: 'Ex-partner');
        l.stats.add('happiness', -8);
        feed.add(
          'A letter from ${_first(n)}: they cannot wait any longer. It is over.',
        );
      }
    }
    if (!p.trustee &&
        p.job != null &&
        p.behaviour >= 80 &&
        p.served >= 2 &&
        rng.nextInt(100) < 35) {
      l.sceneQueue.add('trustee');
    }
    return feed;
  }
  if (isFugitive(l)) {
    var odds = 20 + l.fame * 2;
    if (l.job != null && !l.marks.contains('new_identity')) odds += 15;
    if (l.marks.contains('new_identity')) odds -= 12;
    if (l.marks.contains('lying_low:${l.age - 1}')) odds -= 8;
    if (rng.nextInt(100) < odds.clamp(5, 80)) {
      recapture(l, rng);
      feed.add(
        'Police officers at the door at 6am. They had your name, your new address and handcuffs. Back to prison, maximum security, for ${l.prison!.years} years.',
      );
    } else if (rng.nextBool()) {
      l.sceneQueue.add('on_the_run');
    }
    return feed;
  }
  if (onParole(l) && rng.nextInt(100) < 50) l.sceneQueue.add('parole_checkin');
  if (l.marks.any((m) => m.startsWith('ex_gang:')) && rng.nextInt(100) < 6) {
    l.sceneQueue.add('old_crew');
  }
  final halfway = l.assets.where((a) => a.info['halfway'] != null).firstOrNull;
  if (halfway != null && l.age >= (halfway.info['halfway'] as int)) {
    l.assets.remove(halfway);
    feed.add(
      'Your time at the halfway house is up. You packed one bag and said goodbye to the curfew.',
    );
  }
  return feed;
}

/// On release with nowhere to live: a place at a halfway house.
String? offerHalfwayHouse(Life l) {
  if (l.age < 18 || l.has('house') || l.has('rental')) return null;
  l.assets.add(
    Asset(
      id: 'halfway${l.age}',
      kind: 'rental',
      name: 'Halfway house',
      value: 0,
      yearlyCost: 0,
      since: l.age,
      info: {'halfway': l.age + 2},
    ),
  );
  return 'A place at a halfway house is waiting: a bed, a curfew and no rent for two years.';
}

// ---------------- Activities ----------------

final prisonLifeActions = <GameAction>[
  GameAction(
    id: 'prison_visit',
    label: 'Ask for a visit',
    category: 'Prison',
    keywords: ['visit', 'visitor', 'family', 'partner'],
    hint: (l) => l.prison == null
        ? 'Only in prison'
        : '${visitors(l).where((n) => n.bond >= 25).length} people might come',
    extraCheck: _inPrison,
    run: (l, rng) {
      l.sceneQueue.add('visit_pick');
      return ActionResult('You fill in a visiting order.');
    },
  ),
  GameAction(
    id: 'prison_trade',
    label: 'Trade in the yard',
    category: 'Prison',
    keywords: ['trade', 'contraband', 'stash', 'deal', 'swap'],
    hint: (l) =>
        l.prison == null ? 'Only in prison' : 'Stash: ${l.prison!.stash}',
    extraCheck: _inPrison,
    run: (l, rng) =>
        ActionResult('You wander the yard with your pockets full.'),
  ),
  GameAction(
    id: 'cell_exercise',
    label: 'Exercise in your cell',
    category: 'Prison',
    keywords: ['exercise', 'cell', 'push-ups', 'solitary'],
    extraCheck: _inPrison,
    run: (l, rng) {
      l.fitness = min(100, l.fitness + 4);
      return statChange(
        l,
        'Push-ups, sit-ups, counting the bricks. It keeps you sane.',
        {'health': 2, 'willpower': 1},
      );
    },
  ),
  GameAction(
    id: 'seal_record',
    label: 'Get your record sealed',
    category: 'Law',
    cost: 2000,
    priceNote: 'Costs \$2,000 · needs five years without a conviction',
    keywords: ['seal', 'expunge', 'record', 'clean slate', 'lawyer'],
    minAge: 18,
    extraCheck: (l) {
      final open = l.record.where((r) => r['sealed'] != true).toList();
      if (open.isEmpty) return 'Nothing to seal';
      if (l.prison != null || isFugitive(l) || onParole(l)) {
        return 'Not while serving a sentence';
      }
      final last = open.map((r) => r['age'] as int? ?? 0).fold(0, max);
      return l.age - last < 5
          ? 'Needs five years since your last conviction'
          : null;
    },
    run: (l, rng) {
      l.money -= 2000;
      for (final r in l.record) {
        r['sealed'] = true;
      }
      l.flags['record_sealed'] = Memory(l.age, 'getting a clean slate');
      return ActionResult(
        'A judge signed the order. Your record is sealed: most employers will never see it.',
        ['Money −\$2,000', 'Jobs that check records are open again'],
      );
    },
  ),
];

/// Scenes in this file, dispatched from buildScene.
Storylet? prisonLifeScene(String id, List<String> args, Life l) => switch (id) {
  'visit_pick' => visitPickScene(l),
  'visit' => visitScene(args, l),
  'prison_course' => courseScene(l),
  'trustee' => trusteeScene(l),
  'on_the_run' => onTheRunScene(l),
  'parole_checkin' => checkinScene(l),
  'old_crew' => oldCrewScene(l),
  _ => null,
};
