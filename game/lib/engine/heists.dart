import 'dart:math';

import 'actions.dart';
import 'justice.dart';
import 'models.dart';
import 'storylet.dart';

/// Heists, lawsuits and prison riots (plan Module 8, Launch scope).
/// Every target shows its window first, so nothing fails for a hidden
/// reason; every heist ends with an after-action report; lawsuits work
/// both ways and defendants remember.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '−' : ''}\$$s';
}

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'crime',
  scene: true,
  choices: choices,
);

// ---------------- Heists ----------------

typedef HeistTarget = ({
  String id,
  String name,
  int security,
  int minTake,
  int maxTake,
  int every,
  String window,
});

/// Targets and their windows (plan: the train heist shows its timetable).
const heistTargets = <HeistTarget>[
  (
    id: 'jewellers',
    name: 'The jewellers on the high street',
    security: 30,
    minTake: 20000,
    maxTake: 80000,
    every: 1,
    window: 'Open all year',
  ),
  (
    id: 'truck',
    name: 'An armoured cash truck',
    security: 45,
    minTake: 50000,
    maxTake: 200000,
    every: 1,
    window: 'Monthly transfers, every year',
  ),
  (
    id: 'train',
    name: 'The night mail train',
    security: 50,
    minTake: 80000,
    maxTake: 300000,
    every: 2,
    window: 'Carries the bank shipment every other year',
  ),
  (
    id: 'museum',
    name: 'The travelling gold exhibit',
    security: 55,
    minTake: 100000,
    maxTake: 900000,
    every: 3,
    window: 'Visits the city every third year',
  ),
  (
    id: 'casino',
    name: 'The casino vault',
    security: 60,
    minTake: 200000,
    maxTake: 800000,
    every: 1,
    window: 'Full every weekend',
  ),
  (
    id: 'bank',
    name: 'The central bank vault',
    security: 70,
    minTake: 300000,
    maxTake: 2000000,
    every: 1,
    window: 'Always there, always guarded',
  ),
];

HeistTarget heistById(String id) => heistTargets.firstWhere(
  (t) => t.id == id,
  orElse: () => heistTargets.first,
);

/// Null when the target is open this year, otherwise when it next is.
String? heistWindowLock(Life l, HeistTarget t) {
  if (t.every <= 1 || l.year % t.every == 0) return null;
  final next = l.year + (t.every - l.year % t.every);
  return 'Not this year: next window in $next';
}

typedef CrewMember = ({
  String name,
  String role,
  int skill,
  int loyalty,
  String? id,
});

const _roles = ['Driver', 'Tech', 'Lookout', 'Muscle'];

/// Crew options: friends you trust, hired professionals, or alone.
List<CrewMember> crewFor(Life l, String kind) {
  switch (kind) {
    case 'friends':
      final friends =
          l.npcs
              .where((n) => n.alive && n.circle == 'Friends' && n.bond >= 40)
              .toList()
            ..sort((a, b) => b.bond.compareTo(a.bond));
      return [
        for (var i = 0; i < min(3, friends.length); i++)
          (
            name: friends[i].name.split(' ').first,
            role: _roles[i],
            skill: 30 + Random(friends[i].name.hashCode).nextInt(55),
            loyalty: friends[i].bond,
            id: friends[i].id,
          ),
      ];
    case 'pros':
      return [
        for (var i = 0; i < 3; i++)
          (
            name: const ['"Ghost"', '"Wheels"', '"Sparky"'][i],
            role: _roles[i],
            skill: 65 + i * 5,
            loyalty: 40,
            id: null,
          ),
      ];
  }
  return const [];
}

int crewSkill(Life l, List<CrewMember> crew) => crew.isEmpty
    ? cunning(l)
    : ((crew.fold(0, (a, c) => a + c.skill) / crew.length + cunning(l)) / 2)
          .round();

Storylet? heistScene(String id, List<String> args, Life l) {
  switch (id) {
    case 'heist':
      return _scene(
        id,
        'You spread a map of ${l.city} across the kitchen table. Every target has a window: miss it, and you wait. Which one?',
        [
          for (final t in heistTargets)
            Choice(
              label: '${t.name} · ${_m(t.minTake)}–${_m(t.maxTake)}',
              outcome: '',
              risk: '${t.window} · security ${t.security}',
              lock: (l) => heistWindowLock(l, t),
              run: (l, rng) {
                l.sceneQueue.add('heist_crew:${t.id}');
                return 'You start planning the ${t.name.toLowerCase()} job.';
              },
            ),
          Choice(
            label: 'Fold the map away',
            outcome: 'You decided you would rather sleep at night.',
          ),
        ],
      );
    case 'heist_crew':
      final t = heistById(args.first);
      final friends = crewFor(l, 'friends');
      String describe(List<CrewMember> c) => c.isEmpty
          ? 'Just you'
          : c
                .map(
                  (m) =>
                      '${m.name} (${m.role}, skill ${m.skill}, loyal ${m.loyalty}%)',
                )
                .join(', ');
      Choice crew(String label, String kind, String risk) => Choice(
        label: label,
        outcome: '',
        risk: risk,
        lock: (l) => kind == 'friends' && friends.isEmpty
            ? 'No friends you trust enough (Bond 40%+)'
            : null,
        run: (l, rng) {
          l.sceneQueue.add('heist_intel:${t.id}:$kind');
          return 'The crew is set.';
        },
      );
      return _scene(
        id,
        'Every job needs a crew. Skill gets you in; loyalty gets you home. Crew members who get caught may talk.',
        [
          crew('Friends you trust', 'friends', describe(friends)),
          crew(
            'Hired professionals (they take 40%)',
            'pros',
            describe(crewFor(l, 'pros')),
          ),
          crew(
            'Go alone',
            'alone',
            'Your Smarts and Charisma only (${cunning(l)})',
          ),
        ],
      );
    case 'heist_intel':
      final t = heistById(args[0]);
      final kind = args.length > 1 ? args[1] : 'alone';
      Choice intel(String label, int cost, int bonus, String risk) => Choice(
        label: label,
        outcome: '',
        needsMoney: cost,
        risk: risk,
        run: (l, rng) {
          l.money -= cost;
          l.sceneQueue.add('heist_go:${t.id}:$kind:$bonus');
          return cost > 0
              ? 'You learned things the guards would rather you did not know.'
              : 'You decided to wing it.';
        },
      );
      return _scene(
        id,
        'Good intel turns guesses into plans: guard rotations, camera blind spots, the night the alarm is serviced.',
        [
          intel('Scout it for a week (\$500)', 500, 10, '+10% on every phase'),
          intel(
            'Pay an insider (\$5,000)',
            5000,
            18,
            '+18%, but the insider might talk one day',
          ),
          intel('Skip the intel', 0, 0, 'No bonus'),
        ],
      );
    case 'heist_go':
      final t = heistById(args[0]);
      final kind = args.length > 1 ? args[1] : 'alone';
      final intelBonus = args.length > 2 ? int.tryParse(args[2]) ?? 0 : 0;
      final crew = crewFor(l, kind);
      String run(Life l, Random rng, String approach) {
        final skill = crewSkill(l, crew);
        final approachMod = switch (approach) {
          'force' => 10,
          'deception' => (l.stats['charisma'] - 50) ~/ 4,
          _ => 0,
        };
        final report = <String>[];
        var phasesOk = 0;
        for (final phase in const ['Entry', 'The take', 'Escape']) {
          final why = <(int, String)>[
            ((skill - 50) ~/ 2, 'crew skill $skill'),
            (-t.security ~/ 2, 'security ${t.security}'),
            (intelBonus, 'intel'),
            (approachMod, approach),
          ];
          final weak = crew.where((c) => c.loyalty < 45).toList();
          if (weak.isNotEmpty && rng.nextInt(100) < 30) {
            why.add((
              -15,
              '${weak.first.name} lost their nerve (loyalty ${weak.first.loyalty}%)',
            ));
          }
          final luck = rng.nextInt(11) - 5;
          final p = (70 + why.fold(0, (a, w) => a + w.$1) + luck).clamp(3, 95);
          final ok = rng.nextInt(100) < p;
          why.sort((a, b) => b.$1.abs().compareTo(a.$1.abs()));
          report.add(
            '$phase: ${ok ? 'clean' : 'failed'} ($p% · ${why.take(2).map((w) => '${w.$2} ${w.$1 >= 0 ? '+' : ''}${w.$1}').join(', ')})',
          );
          if (!ok) break;
          phasesOk++;
        }
        l.stats.add('karma', approach == 'force' ? -15 : -8);
        l.notoriety += 6;
        final ev =
            40 + (approach == 'force' ? 20 : 0) + (phasesOk < 3 ? 25 : 0);
        final crimeId = approach == 'force' ? 'armed_robbery' : 'heist';
        void remember(int valence, String text) {
          for (final c in crew.where((c) => c.id != null)) {
            l
                .npc(c.id!)
                ?.remember(
                  NpcMemory(
                    age: l.age,
                    text: text,
                    valence: valence,
                    intensity: 4,
                    tags: ['crime'],
                  ),
                );
          }
        }

        final take = t.minTake + rng.nextInt(t.maxTake - t.minTake + 1);
        final cut = kind == 'pros' ? 0.4 : (crew.isEmpty ? 0.0 : 0.25);
        final header = 'After-action report: ${report.join('. ')}.';
        switch (phasesOk) {
          case 0:
            l.cases.add({'crime': crimeId, 'age': l.age, 'evidence': 20});
            remember(-1, 'the job that never got started');
            return 'You never got in. Everyone went home and pretended it never happened. $header';
          case 1:
            l.cases.add({'crime': crimeId, 'age': l.age, 'evidence': ev});
            remember(-1, 'the job that went wrong');
            return 'You got in, but it went wrong inside and you ran with nothing. $header';
          case 2:
            l.sceneQueue.add('arrest:$crimeId:${min(95, ev + 20)}');
            remember(-2, 'getting caught on the ${t.name.toLowerCase()} job');
            return 'You had the money in your hands when the sirens came. $header';
          default:
            final mine = (take * (1 - cut)).round();
            l.money += mine;
            addDirty(l, mine);
            l.cases.add({'crime': crimeId, 'age': l.age, 'evidence': ev});
            l.flags['heist'] = Memory(l.age, 'the ${t.name.toLowerCase()} job');
            remember(2, 'pulling off the ${t.name.toLowerCase()} job together');
            return 'Clean. Your share is ${_m(mine)}${cut > 0 ? ' after the crew\'s cut' : ''}. Nobody speaks on the drive home. $header';
        }
      }

      return _scene(
        id,
        'It is the night. ${crew.isEmpty ? 'Just you.' : 'The crew: ${crew.map((c) => c.name).join(', ')}.'} How do you go in?',
        [
          Choice(
            label: 'Stealth',
            outcome: '',
            risk: 'No bonus · the lightest sentence',
            run: (l, rng) => run(l, rng, 'stealth'),
          ),
          Choice(
            label: 'Deception: a disguise and a story',
            outcome: '',
            risk: 'Charisma ${l.stats['charisma']}',
            run: (l, rng) => run(l, rng, 'deception'),
          ),
          Choice(
            label: 'Force',
            outcome: '',
            risk: '+10% · violent: much heavier sentences',
            run: (l, rng) => run(l, rng, 'force'),
          ),
          Choice(
            label: 'Call it off',
            outcome: 'You called it off at the last minute. The crew was furious, and relieved.',
          ),
        ],
      );
  }
  return null;
}

// ---------------- Lawsuits ----------------

typedef Grievance = ({
  String id,
  String label,
  String against,
  int strength,
  int damages,
  String? npc,
});

/// Valid grievances right now (plan: lawsuits appear only with one).
List<Grievance> grievances(Life l) => [
  for (final n in l.npcs.where((n) => n.alive && n.debt > 0))
    (
      id: 'debt:${n.id}',
      label:
          'Sue ${n.name.split(' ').first} for the ${_m(n.debt)} they owe you',
      against: n.name,
      strength: 75,
      damages: n.debt,
      npc: n.id,
    ),
  if (l.flags['fired'] != null && l.age - l.flags['fired']!.age <= 3)
    (
      id: 'dismissal',
      label: 'Sue your old employer for unfair dismissal',
      against: 'your old employer',
      strength: 40,
      damages: 15000,
      npc: null,
    ),
  if (l.flags['acquitted'] != null && l.age - l.flags['acquitted']!.age <= 3)
    (
      id: 'arrest',
      label: 'Sue the police for wrongful arrest',
      against: 'the police',
      strength: 35,
      damages: 40000,
      npc: null,
    ),
  if (l.marks.any((m) => m.startsWith('tenant_damage:')))
    (
      id: 'tenant',
      label: 'Sue your tenant for the damage',
      against: 'your tenant',
      strength: 65,
      damages: 4000,
      npc: null,
    ),
];

Storylet? lawsuitScene(String id, List<String> args, Life l) {
  switch (id) {
    case 'sue':
      final list = grievances(l);
      if (list.isEmpty) return null;
      return _scene(
        id,
        'A lawyer listens, taps a pen and says, "You have a case. Whether you want one is another question: defendants remember."',
        [
          for (final g in list)
            Choice(
              label: g.label,
              outcome: '',
              risk: 'Case strength ${g.strength}% · claim ${_m(g.damages)}',
              run: (l, rng) {
                l.sceneQueue.add('sue_lawyer:${g.id}');
                return 'You file the papers.';
              },
            ),
          Choice(
            label: 'Let it go',
            outcome: 'You let it go. Some fights are not worth the years.',
          ),
        ],
      );
    case 'sue_lawyer':
      final g = grievances(l).where((g) => g.id == args.join(':')).firstOrNull;
      if (g == null) return null;
      Choice lawyer(String label, int cost, int skill) {
        final odds = (g.strength + (skill - 50) ~/ 2).clamp(5, 95);
        return Choice(
          label: '$label${cost > 0 ? ' (${_m(cost)})' : ''}',
          outcome: '',
          needsMoney: cost,
          risk: 'About $odds% to win at trial',
          run: (l, rng) {
            l.money -= cost;
            l.sceneQueue.add('sue_offer:${g.id}:$odds:1');
            return 'Your lawyer sent the letter. The other side has a week to respond.';
          },
        );
      }

      return _scene(id, 'Who takes your case against ${g.against}?', [
        lawyer(
          'Represent yourself',
          0,
          (l.stats['smarts'] + l.stats['charisma']) ~/ 2 - 10,
        ),
        lawyer('A solid lawyer', 8000, 65),
        lawyer('The best in the city', 40000, 88),
      ]);
    case 'sue_offer':
      if (args.length < 4) return null;
      final gid = args.sublist(0, args.length - 2).join(':');
      final g = grievances(l).where((g) => g.id == gid).firstOrNull;
      if (g == null) return null;
      final odds = int.tryParse(args[args.length - 2]) ?? 50;
      final round = int.tryParse(args.last) ?? 1;
      final offer =
          (g.damages * (0.3 + odds / 250 + round * 0.1)).round() ~/ 100 * 100;
      void grudge(Life l) {
        if (g.npc == null) return;
        final n = l.npc(g.npc!);
        n?.addFacets(resentment: 20, affection: -15);
        n?.remember(
          NpcMemory(
            age: l.age,
            text: 'you taking them to court',
            valence: -3,
            intensity: 4,
            tags: ['lawsuit'],
          ),
        );
        if (n != null) n.debt = 0;
        l.marks.add('grudge:${g.npc}:${l.age}');
      }

      return _scene(
        id,
        '${g.against[0].toUpperCase()}${g.against.substring(1)} offers to settle for ${_m(offer)}${round > 1 ? ' (a better offer)' : ''}. At trial you might get ${_m(g.damages)}, or nothing.',
        [
          Choice(
            label: 'Accept ${_m(offer)}',
            outcome: '',
            run: (l, rng) {
              l.money += offer;
              grudge(l);
              return 'You settled for ${_m(offer)}. No courtroom, no headlines, but no apology either.';
            },
          ),
          if (round < 3)
            Choice(
              label: 'Hold out for more',
              outcome: '',
              risk: 'They may raise it, or walk away',
              run: (l, rng) {
                if (rng.nextInt(100) < 70) {
                  l.sceneQueue.add('sue_offer:$gid:$odds:${round + 1}');
                  return 'Your lawyer said, "Wait." A week later the phone rang.';
                }
                l.sceneQueue.add('sue_trial:$gid:$odds');
                return 'They withdrew the offer. It is going to trial.';
              },
            ),
          Choice(
            label: 'Go to trial',
            outcome: '',
            risk: 'About $odds% to win',
            run: (l, rng) {
              l.sceneQueue.add('sue_trial:$gid:$odds');
              return 'You turned it down. See you in court.';
            },
          ),
        ],
      );
    case 'sue_trial':
      final gid = args.sublist(0, args.length - 1).join(':');
      final g = grievances(l).where((g) => g.id == gid).firstOrNull;
      if (g == null) return null;
      final odds = int.tryParse(args.last) ?? 50;
      return _scene(
        id,
        'The judge peers over their glasses at both sides. It is time.',
        [
          Choice(
            label: 'Hear the verdict',
            outcome: '',
            risk: '$odds%',
            run: (l, rng) {
              if (g.npc != null) {
                l.marks.add('grudge:${g.npc}:${l.age}');
                final n = l.npc(g.npc!);
                n?.addFacets(resentment: 25, affection: -20);
                n?.remember(
                  NpcMemory(
                    age: l.age,
                    text: 'you taking them to court',
                    valence: -3,
                    intensity: 4,
                    tags: ['lawsuit'],
                  ),
                );
              }
              if (rng.nextInt(100) < odds) {
                l.money += g.damages;
                if (g.npc != null) l.npc(g.npc!)?.debt = 0;
                l.marks.removeWhere(
                  (m) => m.startsWith('tenant_damage:') && g.id == 'tenant',
                );
                l.flags['won_lawsuit'] = Memory(l.age, 'winning in court');
                return 'You won: ${_m(g.damages)} in damages. ${g.npc == null ? '' : 'Across the room, ${g.against.split(' ').first} did not look at you.'}';
              }
              return 'You lost. The judge found the case "not proven". Your lawyer still sent the bill.';
            },
          ),
        ],
      );
    case 'sued':
      final who = args.isNotEmpty ? args.first : 'a former employee';
      final claim = 10000 + Random(l.seed + l.age).nextInt(40) * 1000;
      return _scene(
        id,
        'A courier hands you an envelope: $who is suing you for ${_m(claim)}.',
        [
          Choice(
            label: 'Settle quietly (${_m(claim ~/ 2)})',
            outcome: '',
            run: (l, rng) {
              l.money -= claim ~/ 2;
              return 'You settled. It hurt your wallet more than your pride.';
            },
          ),
          Choice(
            label: 'Fight it with a lawyer (\$8,000)',
            outcome: '',
            risk: 'About 55% you win',
            run: (l, rng) {
              l.money -= 8000;
              if (rng.nextInt(100) < 55) {
                return 'The case was thrown out. Worth every penny.';
              }
              l.money -= claim;
              return 'You lost and paid ${_m(claim)} in damages.';
            },
          ),
          Choice(
            label: 'Ignore it',
            outcome: '',
            risk: 'They win by default',
            run: (l, rng) {
              l.money -= claim;
              l.credit = l.credit == null ? null : max(300, l.credit! - 40);
              return 'You ignored it. The court did not. You owe ${_m(claim)} and your credit took a hit.';
            },
          ),
        ],
      );
  }
  return null;
}

/// Yearly: grudges strike back (plan: retaliation from memory), and
/// owners of businesses and rentals can be sued.
List<String> lawYear(Life l, Random rng) {
  final feed = <String>[];
  for (final m in l.marks.where((m) => m.startsWith('grudge:')).toList()) {
    final parts = m.split(':');
    final n = l.npc(parts[1]);
    if (n == null || !n.alive) {
      l.marks.remove(m);
      continue;
    }
    if (rng.nextInt(100) >= 25) continue;
    l.marks.remove(m);
    switch (rng.nextInt(3)) {
      case 0:
        l.sceneQueue.add('sued:${n.name}');
        feed.add(
          '${n.name.split(' ').first} has not forgotten the court case.',
        );
      case 1:
        l.stats.add('happiness', -3);
        l.fame = max(0, l.fame - 2);
        feed.add(
          '${n.name.split(' ').first} has been telling everyone you are a snake. Some people believed it.',
        );
      default:
        feed.add(
          '${n.name.split(' ').first} reported you to the council over your bins, your fence and your hedge. All at once.',
        );
        l.money -= 300;
    }
  }
  final exposed =
      l.business != null || l.assets.any((a) => a.info['let'] == true);
  if (exposed && rng.nextInt(100) < 4) {
    l.sceneQueue.add(
      'sued:${l.business != null ? 'a former employee' : 'your tenant'}',
    );
  }
  return feed;
}

// ---------------- Prison riot ----------------

Storylet? riotScene(Life l) {
  final p = l.prison;
  if (p == null) return null;
  String go(Life l, Random rng, String how) {
    final r = switch (how) {
      'rally' => (30 + p.respect ~/ 2 + (l.stats['charisma'] - 50) ~/ 3).clamp(
        5,
        90,
      ),
      'negotiate' => (35 + (l.stats['charisma'] - 50) ~/ 2).clamp(5, 90),
      'protect' => (50 + (l.stats['athleticism'] - 50) ~/ 3).clamp(5, 90),
      _ => 95,
    };
    final ok = rng.nextInt(100) < r;
    switch (how) {
      case 'rally':
        p.respect = min(100, p.respect + (ok ? 20 : 5));
        p.behaviour = max(0, p.behaviour - 20);
        if (!ok) l.stats.add('health', -8);
        return ok
            ? 'Your block held together and won better food and phone time. Respect ${p.respect}%; the parole board will not like it. ($r% chance)'
            : 'The guards broke it up. You took a baton to the ribs. ($r% chance)';
      case 'negotiate':
        p.behaviour = min(100, p.behaviour + (ok ? 15 : 0));
        return ok
            ? 'You talked both sides down. Guards and inmates both owe you now. Behaviour ${p.behaviour}%. ($r% chance)'
            : 'Nobody wanted to listen. You stayed out of the way. ($r% chance)';
      case 'protect':
        l.stats.add('karma', 5);
        if (!ok) l.stats.add('health', -6);
        l.npc('cellmate')?.addFacets(affection: 15, trust: 15);
        return ok
            ? 'You pulled your cellmate out of the chaos. They will never forget it. ($r% chance)'
            : 'You shielded your cellmate and took the hits yourself. ($r% chance)';
      default:
        return 'You stayed in your cell with your hands where everyone could see them. Safe, and invisible.';
    }
  }

  return _scene(
    'riot',
    'Shouting in the block, then the alarm. A riot has started over the canteen and the cancelled visits. Everyone is choosing a side.',
    [
      Choice(
        label: 'Rally your block',
        outcome: '',
        risk: 'Respect and Charisma · behaviour −20',
        run: (l, rng) => go(l, rng, 'rally'),
      ),
      Choice(
        label: 'Negotiate with the guards',
        outcome: '',
        risk: 'Charisma',
        run: (l, rng) => go(l, rng, 'negotiate'),
      ),
      Choice(
        label: 'Protect your cellmate',
        outcome: '',
        risk: 'Athleticism · Karma up',
        run: (l, rng) => go(l, rng, 'protect'),
      ),
      Choice(
        label: 'Step back',
        outcome: '',
        risk: 'Safe',
        run: (l, rng) => go(l, rng, 'back'),
      ),
    ],
  );
}

final heistActions = <GameAction>[
  GameAction(
    id: 'plan_heist',
    label: 'Plan a heist',
    category: 'Crime',
    keywords: [
      'heist',
      'rob',
      'vault',
      'bank',
      'train',
      'museum',
      'casino',
      'job',
    ],
    minAge: 18,
    priceNote: 'Targets show their window first · a serious offence',
    run: (l, rng) {
      l.sceneQueue.add('heist');
      return ActionResult('You start asking around about a crew.');
    },
  ),
  GameAction(
    id: 'sue',
    label: 'Take someone to court',
    category: 'Law',
    keywords: ['sue', 'lawsuit', 'court', 'lawyer', 'claim'],
    minAge: 18,
    extraCheck: (l) =>
        grievances(l).isEmpty ? 'No valid grievance right now' : null,
    run: (l, rng) {
      l.sceneQueue.add('sue');
      return ActionResult('You book a meeting with a lawyer.');
    },
  ),
];
