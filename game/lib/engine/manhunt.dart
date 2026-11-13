import 'dart:math';

import 'crime_wall.dart' show bountyOf;
import 'justice.dart' show crimeById, cunning;
import 'models.dart';
import 'storylet.dart';
import 'underworld.dart' show heat;

// Hot Pursuit: when your heat runs red hot the police stop waiting for
// evidence and come looking. You go on the Most Wanted list, and each
// year brings one push: a roadblock, a dawn raid, a bounty hunter, a TV
// appeal, or somebody who knows you being tempted by the reward. Nothing
// comes out of nowhere: a would-be informer is named a year ahead (spend
// time with them and the danger passes), and every choice shows its odds.
//
// Chases play as the Getaway mini-game (ui/minigames_crime.dart); the
// score shifts the shown odds, and Skip keeps them as they are.

/// Heat at which you go on the list, and below which you come off it.
const wantedAt = 70;
const clearAt = 45;

bool mostWanted(Life l) => l.marks.contains('most_wanted');

/// The person thinking about turning you in, if anyone (set a year ahead).
Npc? informer(Life l) {
  for (final m in l.marks) {
    if (m.startsWith('tip_risk:')) {
      final id = m.split(':')[1];
      return l.npcs.where((n) => n.id == id && n.alive).firstOrNull;
    }
  }
  return null;
}

/// People who might sell you out: grown-ups who know you, not close to you.
List<Npc> _tempted(Life l) => [
  for (final n in l.npcs)
    if (n.alive &&
        n.ageIn(l.year) >= 16 &&
        const {
          'Family',
          'Friends',
          'Partner',
          'Lover',
          'Exes',
          'Work',
        }.contains(n.circle) &&
        n.bond < 45)
      n,
];

/// Odds shifted by how the chase went: Skip (0.6) keeps them as shown.
int chaseOdds(int base, double score) =>
    (base + ((score - 0.6) * 80).round()).clamp(5, 95);

String _m(int v) =>
    '\$${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'crime',
  scene: true,
  choices: choices,
);

// ---------------- Each birthday ----------------

List<String> manhuntYear(Life l, Random rng) {
  final feed = <String>[];
  if (l.prison != null || !l.alive) return feed;
  final h = heat(l);
  final listed = mostWanted(l);
  if (!listed && h >= wantedAt) {
    l.marks.add('most_wanted');
    l.flags['most_wanted'] = Memory(l.age, 'making the Most Wanted list');
    l.sceneQueue.add('manhunt:listed');
    return feed;
  }
  if (listed && h < clearAt) {
    l.marks
      ..remove('most_wanted')
      ..removeWhere((m) => m.startsWith('tip_risk:'));
    feed.add(
      'Your face came off the Most Wanted list. Somebody newer and louder took your place.',
    );
    return feed;
  }
  if (!listed) return feed;

  // A named informer from last year acts, unless you won them back.
  final rat = informer(l);
  l.marks.removeWhere((m) => m.startsWith('tip_risk:'));
  if (rat != null) {
    if (rat.bond < 45) {
      l.sceneQueue.add('manhunt:tip:${rat.id}');
      return feed;
    }
    feed.add(
      '${rat.name.split(' ').first} stopped asking about the reward. Whatever you did, it worked.',
    );
  }
  // Somebody new starts eyeing the reward.
  final tempted = _tempted(l);
  if (tempted.isNotEmpty && rng.nextInt(100) < 45) {
    tempted.sort((a, b) => a.bond.compareTo(b.bond));
    final n = tempted[rng.nextInt(min(2, tempted.length))];
    l.marks.add('tip_risk:${n.id}');
    feed.add(
      '${n.name.split(' ').first} has been asking how big the reward on you is. Spend some time with them, or keep away.',
    );
  }
  if (rng.nextInt(100) < 65) {
    final kinds = [
      'roadblock',
      if (l.assets.any((a) => a.kind == 'house' || a.kind == 'rental')) 'raid',
      'hunter',
      'appeal',
    ];
    l.sceneQueue.add('manhunt:${kinds[rng.nextInt(kinds.length)]}');
  }
  return feed;
}

// ---------------- Helpers for outcomes ----------------

/// The case the police most want you for, taken off the open list.
Map<String, dynamic>? _worstCase(Life l) {
  if (l.cases.isEmpty) return null;
  final worst =
      (l.cases.toList()..sort(
            (a, b) => (b['evidence'] as int).compareTo(a['evidence'] as int),
          ))
          .first;
  l.cases.remove(worst);
  return worst;
}

/// Caught: the strongest case goes to an arrest. With no case to hold
/// you on, you are questioned and let go.
String _caught(Life l, String how, {bool quietly = false}) {
  final c = _worstCase(l);
  if (c == null) {
    l.notoriety = max(0, l.notoriety - 4);
    return '$how Twelve hours in an interview room, and nothing they could charge you with. They let you go, furious.';
  }
  final ev = min(95, (c['evidence'] as int) + 20);
  if (quietly) {
    l.marks.add('surrendered');
    l.sceneQueue.add('charge:${c['crime']}:$ev');
  } else {
    l.sceneQueue.add('arrest:${c['crime']}:$ev');
  }
  return '$how They had a warrant for the ${crimeById(c['crime'] as String).label.toLowerCase()}.';
}

/// Got away: the chase makes you more famous to the police.
String _away(Life l, String how) {
  l.notoriety += 2;
  l.stats.add('happiness', 2);
  return how;
}

// ---------------- Scenes ----------------

Storylet? manhuntScene(List<String> args, Life l) {
  final kind = args.isEmpty ? 'listed' : args.first;
  final bounty = bountyOf(l);
  final run = (35 + (l.stats['athleticism'] - 50) ~/ 3 + cunning(l) ~/ 5).clamp(
    10,
    75,
  );
  Choice chase(String label, String away, String caught, {int bonus = 0}) {
    final odds = (run + bonus).clamp(10, 85);
    return Choice(
      label: label,
      outcome: '',
      risk:
          '$odds% chance to get away (Athleticism, Cunning) · played as a chase',
      miniGame: 'getaway',
      scored: (l, rng, score) {
        final p = chaseOdds(odds, score);
        return rng.nextInt(100) < p ? _away(l, away) : _caught(l, caught);
      },
    );
  }

  Choice giveUp(String label) => Choice(
    label: label,
    outcome: '',
    risk: 'Turning yourself in cuts any sentence by 30%',
    run: (l, rng) {
      l.stats.add('karma', 4);
      return _caught(l, 'You put your hands up.', quietly: true);
    },
  );

  switch (kind) {
    case 'listed':
      return _scene(
        'manhunt',
        'The evening news ends with four faces. The last one is yours. "${l.fullName}, ${l.age}. Do not approach. A reward of ${_m(bounty)} is offered." You are on the Most Wanted list.',
        [
          Choice(
            label: 'Go to ground',
            outcome: '',
            risk: 'Heat cools faster; a lonely year',
            run: (l, rng) {
              l.marks.add('lying_low:${l.age}');
              l.notoriety = max(0, l.notoriety - 3);
              l.stats.add('happiness', -4);
              return 'You moved into a rented room, cut your hair in the sink and stopped answering your phone.';
            },
          ),
          Choice(
            label: 'Buy a new identity (\$15,000)',
            outcome: '',
            needsMoney: 15000,
            risk: 'Heat falls a long way',
            run: (l, rng) {
              l.money -= 15000;
              l.marks.add('new_identity');
              l.notoriety = max(0, l.notoriety - 10);
              for (final c in l.cases) {
                c['evidence'] = max(5, (c['evidence'] as int) - 15);
              }
              return 'A forger in a back room took your photo against a white sheet. You have a new name, a new birthday and a past you keep rehearsing.';
            },
          ),
          giveUp('Turn yourself in'),
          Choice(
            label: 'Carry on as normal',
            outcome: '',
            risk: 'The manhunt comes to you',
            run: (l, rng) {
              l.stats.add('happiness', 2);
              return 'You watched yourself on the news, turned the TV off and went out for dinner.';
            },
          ),
        ],
      );
    case 'roadblock':
      final calm = (30 + cunning(l) ~/ 2 + l.stats['looks'] ~/ 10).clamp(
        10,
        80,
      );
      return _scene(
        'manhunt',
        'Blue lights across both lanes ahead. Cones, torches, an officer waving each car through one at a time, looking hard at every driver.',
        [
          Choice(
            label: 'Stay calm and drive up',
            outcome: '',
            risk: '$calm% chance they wave you through (Cunning, Looks)',
            run: (l, rng) => rng.nextInt(100) < calm
                ? 'The officer shone a torch in your face, yawned and waved you on. Your hands did not stop shaking for an hour.'
                : _caught(
                    l,
                    'The officer looked at you, then at a photo, then at you again.',
                  ),
          ),
          chase(
            'Swing round and floor it',
            'You took the back roads with your lights off and lost them by the reservoir.',
            'You ran out of road at a cattle grid.',
          ),
          giveUp('Get out with your hands up'),
        ],
      );
    case 'raid':
      final stash = l.dirty;
      return _scene(
        'manhunt',
        'Six in the morning. Boots on the stairs, a battering ram at the door. "Police! Search warrant!"${stash > 0 ? ' The bag of cash is under the bed.' : ''}',
        [
          if (stash > 0)
            Choice(
              label: 'Stuff the cash out of the window',
              outcome: '',
              risk: 'Lose some of the dirty money; they find little',
              run: (l, rng) {
                final lost = (stash * (0.3 + rng.nextDouble() * 0.3)).round();
                l.dirty -= lost;
                l.notoriety = max(0, l.notoriety - 2);
                return 'Notes fluttered into the neighbour\'s garden. The police found a tidy flat and nothing else. You lost ${_m(lost)} of it to the wind and a lucky dog walker.';
              },
            ),
          chase(
            'Out the back window',
            'You dropped onto the bins, went over two fences and caught the first bus out of town in your socks.',
            'There was an officer in the back garden, waiting.',
            bonus: -10,
          ),
          giveUp('Open the door'),
        ],
      );
    case 'hunter':
      final fee = max(5000, bounty ~/ 3);
      final fight = (25 + (l.stats['athleticism'] - 50) ~/ 2).clamp(5, 70);
      return _scene(
        'manhunt',
        'A big man in a quiet car has been parked across the street for two days. A bounty hunter, after the ${_m(bounty)} on your head.',
        [
          Choice(
            label: 'Pay him to look elsewhere (${_m(fee)})',
            outcome: '',
            needsMoney: fee,
            run: (l, rng) {
              l.money -= fee;
              return 'He counted it twice, said "never saw you" and drove off. He might come back when he runs short.';
            },
          ),
          Choice(
            label: 'Confront him',
            outcome: '',
            risk:
                '$fight% chance you see him off (Athleticism) · an assault charge if seen',
            run: (l, rng) {
              if (rng.nextInt(100) < fight) {
                l.cases.add({'crime': 'assault', 'age': l.age, 'evidence': 25});
                return 'It was short and ugly. He drove off holding his nose, and a neighbour might have seen.';
              }
              l.stats.add('health', -8);
              return _caught(
                l,
                'He was bigger than he looked. You woke up in the back of a police car.',
              );
            },
          ),
          chase(
            'Slip out the back',
            'You left through the garages at 3am. By the time he noticed, you were three towns away.',
            'He was waiting at the garages.',
          ),
        ],
      );
    case 'appeal':
      return _scene(
        'manhunt',
        'A detective on breakfast TV holds up your photo. "Somebody knows where ${l.firstName} is. The reward is ${_m(bounty)}." Your phone buzzes with messages you do not open.',
        [
          Choice(
            label: 'Change your look (\$2,000)',
            outcome: '',
            needsMoney: 2000,
            risk: 'Heat down a little',
            run: (l, rng) {
              l.money -= 2000;
              l.notoriety = max(0, l.notoriety - 4);
              return 'New hair, new glasses, a beard or none. Your own mother would walk past you.';
            },
          ),
          Choice(
            label: 'Lie low for the year',
            outcome: '',
            risk: 'Heat cools; a lonely year',
            run: (l, rng) {
              l.marks.add('lying_low:${l.age}');
              l.notoriety = max(0, l.notoriety - 3);
              l.stats.add('happiness', -3);
              return 'You lived on takeaways and daytime TV and did not go out once.';
            },
          ),
          Choice(
            label: 'Call the show and taunt them',
            outcome: '',
            risk: 'Fame up, heat up',
            run: (l, rng) {
              l.notoriety += 3;
              l.fame = min(100, l.fame + 6);
              return 'You rang in from a payphone and asked the detective how the search was going. It went viral.';
            },
          ),
        ],
      );
    case 'tip':
      final n = l.npcs
          .where((x) => args.length > 1 && x.id == args[1])
          .firstOrNull;
      final who = n?.name.split(' ').first ?? 'Someone you know';
      return _scene(
        'manhunt',
        'Unmarked cars at both ends of the street. They knew exactly where you would be tonight, and only one person knew that: $who. The reward was ${_m(bounty)}.',
        [
          for (final c in [
            chase(
              'Run',
              'You went over a wall you did not know you could climb and kept running until the sirens faded.',
              'They had every exit covered.',
              bonus: -15,
            ),
            giveUp('Hold out your wrists'),
          ])
            Choice(
              label: c.label,
              outcome: '',
              risk: c.risk,
              miniGame: c.miniGame,
              scored: c.scored == null
                  ? null
                  : (l, rng, s) {
                      if (n != null) rememberBetrayal(l, n.id);
                      return c.scored!(l, rng, s);
                    },
              run: c.run == null
                  ? null
                  : (l, rng) {
                      if (n != null) rememberBetrayal(l, n.id);
                      return c.run!(l, rng);
                    },
            ),
        ],
      );
  }
  return null;
}

/// Once the scene is resolved, the informer is remembered.
void rememberBetrayal(Life l, String npcId) {
  final n = l.npcs.where((x) => x.id == npcId).firstOrNull;
  if (n == null) return;
  n.resentment += 30;
  l.flags['betrayed'] = Memory(l.age, 'being sold out by ${n.name}');
}
