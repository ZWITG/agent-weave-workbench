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
  l.money += gain;
  l.notoriety += c.band == 'minor' ? 0 : 2;
  _setSkill(l, skill + 4);
  final ev = (c.evidence + rng.nextInt(15) - 5 - skill ~/ 10).clamp(5, 95);
  l.cases.add({'crime': c.id, 'age': l.age, 'evidence': ev});
  final text = c.done.replaceAll('{gain}', _m(gain));
  return '$text${gain > 0 ? ' (Money +${_m(gain)}.)' : ''} You left evidence behind: $ev/100. Street skill is now ${skillName(crimeSkill(l)).toLowerCase()}.';
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
  _ => null,
};
