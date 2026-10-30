import 'dart:math';

import 'actions.dart';
import 'justice.dart';
import 'models.dart';
import 'storylet.dart';

// Crimes as small jobs: pick a target, pick how to do it, and sometimes
// deal with a twist halfway through. Street skill grows with every job you
// get away with: lower risk and bigger takes.

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'crime',
  scene: true,
  choices: choices,
);

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '\$$s';
}

/// Crimes that play out as a planned job.
const plannedCrimes = {
  'porch_theft',
  'burglary',
  'car_theft',
  'fraud',
  'hacking',
  'assault',
  'armed_robbery',
};

int crimeSkill(Life l) {
  for (final m in l.marks) {
    if (m.startsWith('crime_skill:')) return int.tryParse(m.substring(12)) ?? 0;
  }
  return 0;
}

void _setSkill(Life l, int v) {
  l.marks.removeWhere((m) => m.startsWith('crime_skill:'));
  l.marks.add('crime_skill:${v.clamp(0, 100)}');
}

String skillName(int s) => s >= 70
    ? 'Mastermind'
    : s >= 45
    ? 'Professional'
    : s >= 20
    ? 'Getting good'
    : 'Amateur';

typedef Target = ({String label, String text, int risk, int gain});

/// Three targets per crime: easy and small, middling, risky and rich.
List<Target> targetsFor(String id) => switch (id) {
  'porch_theft' => [
    (
      label: 'A quiet cul-de-sac',
      text: 'Small parcels, nobody around',
      risk: -8,
      gain: 60,
    ),
    (
      label: 'A busy terrace',
      text: 'Lots of parcels, lots of windows',
      risk: 0,
      gain: 100,
    ),
    (
      label: 'A gated estate',
      text: 'Designer boxes and security guards',
      risk: 15,
      gain: 260,
    ),
  ],
  'burglary' => [
    (
      label: 'A flat with a window left open',
      text: 'Easy in, not much inside',
      risk: -10,
      gain: 50,
    ),
    (
      label: 'A family house on holiday',
      text: 'Empty for two weeks',
      risk: 0,
      gain: 100,
    ),
    (
      label: 'A mansion in the hills',
      text: 'Alarms, a safe and a big payday',
      risk: 15,
      gain: 300,
    ),
  ],
  'car_theft' => [
    (
      label: 'An old hatchback',
      text: 'No alarm, sells for parts',
      risk: -10,
      gain: 50,
    ),
    (
      label: 'A family SUV',
      text: 'Decent resale, a steering lock',
      risk: 0,
      gain: 100,
    ),
    (
      label: 'A sports car outside a club',
      text: 'Keyless entry and cameras',
      risk: 15,
      gain: 280,
    ),
  ],
  'fraud' => [
    (
      label: 'A fake raffle',
      text: 'Small sums from many people',
      risk: -10,
      gain: 50,
    ),
    (label: 'A phone scam', text: 'Pretend to be the bank', risk: 0, gain: 100),
    (
      label: 'A fake investment fund',
      text: 'Rich investors, a paper trail',
      risk: 15,
      gain: 320,
    ),
  ],
  'hacking' => [
    (label: 'A small online shop', text: 'Weak passwords', risk: -10, gain: 50),
    (
      label: 'A crypto wallet',
      text: 'Anonymous, if you are careful',
      risk: 0,
      gain: 110,
    ),
    (
      label: 'A bank',
      text: 'The best security money can buy',
      risk: 18,
      gain: 350,
    ),
  ],
  'assault' => [
    (
      label: 'Someone who insulted you',
      text: 'In a dark car park',
      risk: -5,
      gain: 100,
    ),
    (label: 'A rival in the pub', text: 'With witnesses', risk: 8, gain: 100),
    (
      label: 'Someone with friends',
      text: 'They might hit back',
      risk: 0,
      gain: 100,
    ),
  ],
  'armed_robbery' => [
    (label: 'A corner shop', text: 'One nervous cashier', risk: -10, gain: 40),
    (
      label: 'A petrol station',
      text: 'Cameras, but a full till',
      risk: 0,
      gain: 100,
    ),
    (
      label: 'A bank branch',
      text: 'Guards, a silent alarm and a vault',
      risk: 20,
      gain: 400,
    ),
  ],
  _ => [(label: 'Just do it', text: '', risk: 0, gain: 100)],
};

/// Pick a target.
Storylet? planScene(List<String> args, Life l) {
  if (args.isEmpty || l.prison != null) return null;
  final c = crimeById(args.first);
  final base = caughtOdds(l, c).$1;
  return _scene(
    'crime_plan',
    'You start planning the ${c.label.toLowerCase()}. Street skill: ${skillName(crimeSkill(l))}. First, the target.',
    [
      for (final t in targetsFor(c.id))
        Choice(
          label: t.label,
          outcome: '',
          risk:
              '${t.text} · risk about ${(base + t.risk).clamp(3, 90)}%${c.id == 'assault' ? '' : ' · take ×${(t.gain / 100).toStringAsFixed(1)}'}',
          run: (l, rng) {
            l.sceneQueue.insert(0, 'crime_go:${c.id}:${t.risk}:${t.gain}');
            return 'You watch the place for a few days and make a plan.';
          },
        ),
      Choice(
        label: 'Forget it',
        outcome: 'You decided it was not worth it. Your conscience thanks you.',
      ),
    ],
  );
}

/// How to do it.
Storylet? goScene(List<String> args, Life l) {
  if (args.length < 3 || l.prison != null) return null;
  final c = crimeById(args[0]);
  final risk = int.tryParse(args[1]) ?? 0;
  final gain = int.tryParse(args[2]) ?? 100;
  final base = caughtOdds(l, c).$1 + risk - crimeSkill(l) ~/ 10;
  final hasCrew =
      l.marks.any((m) => m.startsWith('ex_gang:')) ||
      l.npcs.any((n) => n.alive && n.circle == 'Friends' && n.bond >= 60);
  Choice how(
    String label,
    String note,
    int dRisk,
    int dGain, {
    String? Function(Life)? lock,
  }) {
    final odds = (base + dRisk).clamp(3, 90);
    return Choice(
      label: label,
      outcome: '',
      risk: '$note · risk about $odds%',
      lock: lock,
      run: (l, rng) {
        if (rng.nextInt(100) < 25) {
          l.sceneQueue.insert(
            0,
            'crime_twist:${c.id}:${odds - base + risk}:${gain * dGain ~/ 100}',
          );
          return 'You are halfway through when something changes.';
        }
        return finishCrime(l, c, rng, odds, gain * dGain ~/ 100);
      },
    );
  }

  return _scene('crime_go', 'The night comes. How do you do it?', [
    how(
      'Slow and careful',
      'Smarts help · smaller take',
      -8 - (l.stats['smarts'] - 50) ~/ 10,
      80,
    ),
    how(
      'Fast and bold',
      'Athleticism helps · bigger take',
      6 - (l.stats['athleticism'] - 50) ~/ 10,
      125,
    ),
    how(
      'Bring a lookout',
      'Needs a close friend or an old crew · you split the take',
      -14,
      65,
      lock: (_) => hasCrew ? null : 'Needs a close friend or an old crew',
    ),
    Choice(
      label: 'Back out',
      outcome: 'At the last moment you walked away. No harm done.',
    ),
  ]);
}

/// Something goes wrong halfway through.
Storylet? twistScene(List<String> args, Life l) {
  if (args.length < 3 || l.prison != null) return null;
  final c = crimeById(args[0]);
  final risk = int.tryParse(args[1]) ?? 0;
  final gain = int.tryParse(args[2]) ?? 100;
  final base = (caughtOdds(l, c).$1 + risk - crimeSkill(l) ~/ 10).clamp(3, 90);
  final twist = const [
    'A light comes on upstairs.',
    'A dog starts barking next door.',
    'A police car turns into the street and slows down.',
    'Someone you know walks past and looks straight at you.',
  ][(l.age + c.id.length) % 4];
  final nerve = (l.stats['willpower'] - 50) ~/ 5;
  return _scene('crime_twist', '$twist Your heart is pounding.', [
    Choice(
      label: 'Grab what you have and go',
      outcome: '',
      risk: 'Risk about ${(base * 0.6).round()}% · a small take',
      run: (l, rng) =>
          finishCrime(l, c, rng, (base * 0.6).round(), gain * 40 ~/ 100),
    ),
    Choice(
      label: 'Keep your nerve',
      outcome: '',
      risk:
          'Willpower helps · risk about ${(base + 12 - nerve).clamp(3, 90)}% · the full take',
      run: (l, rng) =>
          finishCrime(l, c, rng, (base + 12 - nerve).clamp(3, 90), gain),
    ),
    Choice(
      label: 'Drop everything and run',
      outcome: '',
      risk: 'Nothing taken · risk about ${(base * 0.3).round()}%',
      run: (l, rng) {
        if (rng.nextInt(100) < (base * 0.3).round()) {
          l.notoriety += 2;
          l.sceneQueue.insert(0, 'arrest:${c.id}:${min(95, c.evidence + 10)}');
          return 'You ran straight into a patrol car.';
        }
        l.stats.add('happiness', -2);
        return 'You ran until your lungs burned, empty-handed and shaking. Nobody followed.';
      },
    ),
  ]);
}

/// The end of a job: caught (arrest scene) or away with the take.
String finishCrime(Life l, Crime c, Random rng, int odds, int gainPct) {
  l.reason = c.label;
  l.stats.add('karma', c.karma);
  if (rng.nextInt(100) < odds) {
    l.notoriety += 2;
    l.sceneQueue.insert(0, 'arrest:${c.id}:${min(95, c.evidence + 25)}');
    return '${c.caught} (Risk was $odds%.)';
  }
  final skill = crimeSkill(l);
  final base = c.gainMax <= 0
      ? 0
      : c.gainMin + rng.nextInt(c.gainMax - c.gainMin + 1);
  final gain = base * gainPct * (100 + skill) ~/ 10000;
  l.notoriety += c.band == 'minor' ? 0 : 2;
  _setSkill(l, skill + 4);
  final ev = (c.evidence + rng.nextInt(15) - 5 - skill ~/ 10).clamp(5, 95);
  l.cases.add({'crime': c.id, 'age': l.age, 'evidence': ev});
  if (c.id == 'car_theft' && gain > 0) {
    l.sceneQueue.insert(0, 'crime_car:$gain');
    return 'You got the car away clean. You left evidence behind: $ev/100. Street skill is now ${skillName(crimeSkill(l)).toLowerCase()}.';
  }
  l.money += gain;
  final text = c.done.replaceAll('{gain}', _m(gain));
  return '$text${gain > 0 ? ' (Money +${_m(gain)}.)' : ''} You left evidence behind: $ev/100. Street skill is now ${skillName(crimeSkill(l)).toLowerCase()}.';
}

/// A stolen car: sell it to a chop shop or keep it with swapped plates.
/// A kept car is more evidence, and a car theft conviction takes it away.
Storylet? stolenCarScene(List<String> args, Life l) {
  final gain = int.tryParse(args.firstOrNull ?? '') ?? 0;
  if (gain <= 0 || l.prison != null) return null;
  final c = crimeById('car_theft');
  final name = gain < 4000
      ? 'Stolen hatchback'
      : gain < 12000
      ? 'Stolen SUV'
      : 'Stolen sports car';
  final cars = l.assets.where((a) => a.kind == 'car').length;
  return _scene('crime_car', 'The car is yours for now. What do you do with it?', [
    Choice(
      label: 'Sell it to a chop shop',
      outcome: '',
      risk: 'Money +${_m(gain)} today',
      run: (l, rng) {
        l.money += gain;
        return '${c.done.replaceAll('{gain}', _m(gain))} (Money +${_m(gain)}.)';
      },
    ),
    Choice(
      label: 'Keep it',
      outcome: '',
      risk: 'Swap the plates · more evidence · seized if you are convicted',
      lock: (_) => cars >= 2 ? 'You already have two cars' : null,
      run: (l, rng) {
        l.flags['owns_car'] = Memory(l.age, 'keeping a stolen car');
        l.assets.add(
          Asset(
            id: 'stolen${l.age}_${l.assets.length}',
            kind: 'car',
            name: name,
            value: gain,
            yearlyCost: 600 + gain ~/ 10,
            since: l.age,
            condition: 60 + rng.nextInt(31),
            info: {'dep': 15, 'stolen': true},
          ),
        );
        for (final k in l.cases.reversed) {
          if (k['crime'] == 'car_theft' && k['age'] == l.age) {
            k['evidence'] = min(95, (k['evidence'] as int) + 12);
            break;
          }
        }
        l.stats.add('happiness', 3);
        return 'New plates, a respray in a friend\'s garage and a story about an auction. The ${name.substring(7)} is yours now. Evidence +12.';
      },
    ),
  ]);
}

// ---------------- Murder ----------------

/// People you could go after: living adults you know, people who wronged
/// you first.
List<Npc> murderTargets(Life l) =>
    l.npcs
        .where(
          (n) =>
              n.alive &&
              n.circle != 'Pets' &&
              n.circle != 'Children' &&
              n.circle != 'Grandchildren' &&
              n.ageIn(l.year) >= 18,
        )
        .toList()
      ..sort(
        (a, b) => (b.resentment - b.bond).compareTo(a.resentment - a.bond),
      );

Storylet? murderPickScene(Life l) {
  final people = murderTargets(l).take(5).toList();
  if (people.isEmpty || l.prison != null) return null;
  return _scene('murder_pick', 'You cannot stop thinking about it. Who?', [
    for (final n in people)
      Choice(
        label: '${n.name} (${n.role.toLowerCase()})',
        outcome: '',
        risk: n.circle == 'Family' || n.circle == 'Partner'
            ? 'Family · the police always look close to home first'
            : 'Bond ${n.bond}',
        run: (l, rng) {
          l.sceneQueue.insert(0, 'murder_how:${n.id}');
          return 'You start watching ${n.name.split(' ').first}: when they leave, when they are alone.';
        },
      ),
    Choice(
      label: 'Let it go',
      outcome:
          'You pushed the thought away. Some lines are not worth crossing.',
    ),
  ]);
}

Storylet? murderHowScene(List<String> args, Life l) {
  if (args.isEmpty || l.prison != null) return null;
  final n = l.npcs.where((x) => x.id == args.first && x.alive).firstOrNull;
  if (n == null) return null;
  final c = crimeById('murder');
  final close = n.circle == 'Family' || n.circle == 'Partner';
  final base = caughtOdds(l, c).$1 + (close ? 10 : 0) - crimeSkill(l) ~/ 10;
  const hitman = 25000;
  Choice how(String label, String note, int dRisk, {int cost = 0}) {
    final odds = (base + dRisk).clamp(5, 95);
    return Choice(
      label: label,
      outcome: '',
      risk: '$note · risk about $odds%',
      lock: (l) => l.money < cost ? 'Needs ${_m(cost)}' : null,
      run: (l, rng) => commitMurder(l, n, rng, odds, cost),
    );
  }

  final first = n.name.split(' ').first;
  return _scene('murder_how', 'You have a plan for $first. How?', [
    how(
      'Make it look like an accident',
      'Smarts help',
      -5 - (l.stats['smarts'] - 50) ~/ 5,
    ),
    how(
      'Do it yourself, quickly',
      'Athleticism helps',
      8 - (l.stats['athleticism'] - 50) ~/ 10,
    ),
    how('Hire someone', '${_m(hitman)} · they might talk', -15, cost: hitman),
    Choice(
      label: 'Walk away',
      outcome: 'You could not go through with it. You never told anyone how close you came.',
    ),
  ]);
}

/// The victim dies; the player either gets away with it (a case that
/// never goes cold) or is arrested.
String commitMurder(Life l, Npc n, Random rng, int odds, int cost) {
  final c = crimeById('murder');
  l.reason = c.label;
  l.money -= cost;
  l.stats.add('karma', c.karma);
  l.stats.add('happiness', -8);
  n.alive = false;
  n.info['diedAge'] = n.ageIn(l.year);
  n.info['murdered'] = true;
  l.flags['killer'] = Memory(l.age, 'what you did to ${n.name}');
  l.notoriety += 5;
  if (n.circle == 'Partner') {
    l.flags['widowed'] = Memory(l.age, 'losing ${n.name}');
  }
  // Killing someone in the family leaves the rest of it uneasy around you.
  if (n.circle == 'Family' || n.circle == 'Partner') {
    for (final o in l.npcs) {
      if (o.alive && (o.circle == 'Family' || o.circle == 'Partner')) {
        o.addFacets(trust: -8);
      }
    }
  }
  final first = n.name.split(' ').first;
  if (rng.nextInt(100) < odds) {
    l.sceneQueue.insert(0, 'arrest:murder:${min(95, c.evidence + 10)}');
    return '$first is dead. ${c.caught} (Risk was $odds%.)';
  }
  final ev = (c.evidence - 20 + rng.nextInt(20) - crimeSkill(l) ~/ 5).clamp(
    20,
    95,
  );
  l.cases.add({'crime': c.id, 'age': l.age, 'evidence': ev});
  _setSkill(l, crimeSkill(l) + 6);
  return '$first is dead, and for now nobody knows it was you. At the funeral you stood at the back. A murder case never closes: evidence $ev/100.';
}

final crimeJobActions = <GameAction>[
  GameAction(
    id: 'lie_low',
    label: 'Lie low',
    category: 'Crime',
    keywords: ['lie low', 'hide', 'evidence', 'heat', 'police'],
    minAge: 12,
    extraCheck: (l) => l.cases.isEmpty ? 'No open cases against you' : null,
    hint: (l) =>
        '${l.cases.length} open case${l.cases.length == 1 ? '' : 's'} · the trail goes cold faster',
    run: (l, rng) {
      for (final c in l.cases) {
        c['evidence'] = max(0, (c['evidence'] as int) - 12);
      }
      l.cases.removeWhere((c) => (c['evidence'] as int) < 5);
      l.notoriety = max(0, l.notoriety - 3);
      return statChange(
        l,
        'You stayed home, kept your head down and burned a few things in the garden.',
        {'happiness': -2},
      );
    },
  ),
];

Storylet? crimeJobScene(String id, List<String> args, Life l) => switch (id) {
  'crime_plan' => planScene(args, l),
  'crime_go' => goScene(args, l),
  'crime_twist' => twistScene(args, l),
  'crime_car' => stolenCarScene(args, l),
  'murder_pick' => murderPickScene(l),
  'murder_how' => murderHowScene(args, l),
  _ => null,
};
