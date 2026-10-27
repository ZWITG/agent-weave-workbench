import 'dart:math';

import 'actions.dart';
import 'models.dart';
import 'relationships.dart';
import 'storylet.dart';
import 'world_data.dart';

/// Love and marriage (plan Social §2): meeting routes and the Kindling app
/// with two-way, explained compatibility; explicit stages (dating,
/// exclusive, living together, engaged, married); proposals, weddings,
/// prenups, divorce, affairs and exes. No explicit content: intimacy is a
/// fade to black.

String _m(int v) =>
    '\$${v.abs().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

Npc? partnerOf(Life l) =>
    l.npcs.where((n) => n.alive && n.circle == 'Partner').firstOrNull;
Npc? loverOf(Life l) =>
    l.npcs.where((n) => n.alive && n.circle == 'Lover').firstOrNull;

/// dating, exclusive, living, engaged or married.
String stageOf(Life l, Npc p) {
  final s = p.info['stage'] as String?;
  if (s != null) return s;
  if (l.flags.containsKey('married')) return 'married';
  if (l.flags.containsKey('engaged')) return 'engaged';
  if (l.flags.containsKey('living_together')) return 'living';
  return 'dating';
}

const stageLabels = {
  'dating': 'Dating',
  'exclusive': 'Exclusive',
  'living': 'Living together',
  'engaged': 'Engaged',
  'married': 'Married',
};

void setStage(Life l, Npc p, String stage) {
  p.info['stage'] = stage;
  p.info['stageSince'] = l.age;
  switch (stage) {
    case 'living':
      l.flags['living_together'] = Memory(l.age, 'moving in with ${p.name}');
    case 'engaged':
      l.flags['engaged'] = Memory(l.age, 'getting engaged to ${p.name}');
    case 'married':
      l.flags['married'] = Memory(l.age, 'marrying ${p.name}');
  }
}

/// Moves a person to another circle (partner → ex, colleague → friend),
/// keeping their memories and history.
Npc recircle(Life l, Npc n, {required String circle, required String role}) {
  final copy =
      Npc(
          id: n.id,
          role: role,
          name: n.name,
          birthYear: n.birthYear,
          circle: circle,
          memories: n.memories,
        )
        ..affection = n.affection
        ..trust = n.trust
        ..respect = n.respect
        ..familiarity = n.familiarity
        ..resentment = n.resentment
        ..lastContactAge = n.lastContactAge
        ..debt = n.debt;
  copy.news.addAll(n.news);
  copy.done.addAll(n.done);
  copy.info.addAll(n.info);
  final i = l.npcs.indexOf(n);
  l.npcs[i] = copy;
  return copy;
}

/// Who the player is looking for.
String seeking(Life l) => switch (l.attractedTo) {
  'men' => 'male',
  'women' => 'female',
  'everyone' => 'any',
  _ => l.gender == 'female' ? 'male' : 'female',
};

// ---------------- Compatibility (plan: bands, not one opaque number) ----------------

/// A possible partner, generated with their own values and wishes.
Npc candidate(Life l, Random rng, {String id = 'partner'}) {
  final c = countryNamed(l.country);
  final want = seeking(l);
  final g = want == 'any' ? (rng.nextBool() ? 'female' : 'male') : want;
  final pool = g == 'female' ? c.female : c.male;
  final age = max(18, l.age - 4 + rng.nextInt(9));
  const jobs = [
    'nurse',
    'teacher',
    'chef',
    'designer',
    'mechanic',
    'accountant',
    'paramedic',
    'barista',
    'engineer',
    'artist',
  ];
  final n = Npc(
    id: id,
    role: 'Partner',
    name:
        '${pool[rng.nextInt(pool.length)]} ${c.surnames[rng.nextInt(c.surnames.length)]}',
    birthYear: l.year - age,
    circle: 'Partner',
    bond: 55 + rng.nextInt(15),
  )..lastContactAge = l.age;
  n.info.addAll({
    'gender': g,
    'job': jobs[rng.nextInt(jobs.length)],
    'wantsKids': rng.nextInt(100) < 65,
    'karma': 25 + rng.nextInt(70),
    'impulsivity': 20 + rng.nextInt(70),
    'looks': 30 + rng.nextInt(65),
    'fertility': 40 + rng.nextInt(55),
    'stage': 'dating',
    'stageSince': l.age,
  });
  return n;
}

({int score, String band, List<String> click, List<String> friction})
compatibility(Life l, Npc n) {
  final click = <String>[];
  final friction = <String>[];
  var score = 70;
  final karma = (n.info['karma'] as int?) ?? 60;
  final imp = (n.info['impulsivity'] as int?) ?? 50;
  final looks = (n.info['looks'] as int?) ?? 60;
  final kd = (karma - l.stats['karma']).abs();
  if (kd < 15) {
    click.add('You care about the same things');
    score += 8;
  } else if (kd > 35) {
    friction.add('Different values');
    score -= kd ~/ 3;
  }
  final id = (imp - l.stats['impulsivity']).abs();
  if (id < 15) {
    click.add('Similar energy');
    score += 6;
  } else if (id > 35) {
    friction.add(
      imp > l.stats['impulsivity']
          ? 'They are far more spontaneous'
          : 'They like a quieter life',
    );
    score -= id ~/ 4;
  }
  final attraction = (looks + l.stats['looks']) ~/ 2;
  if (attraction >= 65) {
    click.add('Mutual attraction');
    score += 8;
  }
  final wants = n.info['wantsKids'] as bool?;
  if (wants != null && l.flags.containsKey('no_kids') && wants) {
    friction.add('They want children, you do not');
    score -= 25;
  }
  final gap = (n.ageIn(l.year) - l.age).abs();
  if (gap >= 10) {
    friction.add('A big age gap');
    score -= gap;
  }
  score = score.clamp(0, 100);
  final band = score >= 80
      ? 'Spark'
      : score >= 62
      ? 'Steady'
      : score >= 42
      ? 'Mixed'
      : 'Rocky';
  if (click.isEmpty) click.add('Easy conversation');
  return (score: score, band: band, click: click, friction: friction);
}

// ---------------- Meeting people ----------------

Storylet? kindlingScene(Life l) {
  if (partnerOf(l) != null) return null;
  final rng = Random(l.seed + l.age * 101);
  final people = [for (var i = 0; i < 3; i++) candidate(l, rng)];
  return Storylet(
    id: 'scene:kindling',
    text:
        'You open Kindling and set it to show ${seeking(l) == 'any'
            ? 'everyone'
            : seeking(l) == 'female'
            ? 'women'
            : 'men'} nearby. Three profiles catch your eye. Each shows why you might click, and what might not work. A first date costs about \$60.',
    category: 'love',
    scene: true,
    choices: [
      for (final p in people)
        () {
          final c = compatibility(l, p);
          return Choice(
            label:
                '${p.name.split(' ').first}, ${p.ageIn(l.year)} · ${p.info['job']}',
            outcome: '',
            risk:
                '${c.band}: ${c.click.first}${c.friction.isEmpty ? '' : ' · but ${c.friction.first.toLowerCase()}'}',
            needsMoney: 60,
            run: (life, rng) {
              life.money -= 60;
              final odds =
                  (35 +
                          c.score ~/ 2 +
                          (life.stats['charisma'] - 50) ~/ 5 +
                          (life.stats['looks'] - 50) ~/ 4)
                      .clamp(5, 95);
              if (rng.nextInt(100) < odds) {
                life.npcs.removeWhere((n) => n.id == 'partner');
                life.npcs.add(p);
                life.flags['partner'] = Memory(
                  life.age,
                  'meeting ${p.name} on Kindling',
                );
                return 'The date ran three hours over. ${p.name.split(' ').first} laughed at your jokes and texted before you got home. You are dating! (${c.band}: ${c.click.join(', ').toLowerCase()}.)';
              }
              life.stats.add('happiness', -2);
              return 'Nice enough, but no spark. ${p.name.split(' ').first} sent a polite "good luck out there" the next day. Odds were about $odds% (compatibility, Charisma, Looks).';
            },
          );
        }(),
      Choice(
        label: 'Close the app',
        outcome: 'You deleted the app for the third time this year.',
      ),
    ],
  );
}

/// The everyday ways to meet someone (plan routes table), as one activity.
ActionResult goingOut(Life l, Random rng) {
  l.money -= 60;
  if (partnerOf(l) == null &&
      rng.nextInt(100) < 25 + l.stats['charisma'] ~/ 5) {
    final p = candidate(l, rng);
    l.npcs.removeWhere((n) => n.id == 'partner');
    l.npcs.add(p);
    l.flags['partner'] = Memory(l.age, 'meeting ${p.name} on a night out');
    return ActionResult(
      'You got talking to ${p.name} at the bar and did not stop until closing time. You spent the night together, and the next morning you made plans for dinner.',
      ['Money −\$60', 'You are dating ${p.name.split(' ').first}'],
    );
  }
  if (rng.nextInt(100) < 20) {
    l.stats.add('health', -2);
    return ActionResult(
      'A great night, followed by a terrible morning. Your head is still pounding.',
      ['Money −\$60', 'Health −2'],
    );
  }
  l.stats.add('happiness', 4);
  return ActionResult(
    'Dancing, terrible karaoke and chips on the walk home. Exactly what you needed.',
    ['Money −\$60', 'Happiness +4'],
  );
}

// ---------------- Partner interactions ----------------

bool _isPartner(Npc n) => n.circle == 'Partner';
String? _stage(Life l, Npc n, Set<String> allowed, String reason) =>
    allowed.contains(stageOf(l, n)) ? null : reason;

final loveInteractions = <Interaction>[
  Interaction(
    id: 'date_night',
    label: 'Date night',
    group: 'Special',
    positive: true,
    cost: 50,
    keywords: ['date', 'dinner', 'romance', 'night out'],
    only: _isPartner,
    run: (life, n, k, rng) {
      life.money -= 50;
      const kinds = [
        'a candlelit dinner',
        'a film you both pretended to understand',
        'a long walk by the water',
        'an escape room you failed spectacularly',
      ];
      return bondResult(
        life,
        n,
        'You and ${n.name.split(' ').first} went on ${kinds[rng.nextInt(kinds.length)]}. It felt like the first date again.',
        affection: (5 * k).round(),
        familiarity: 2,
        extra: ['Money −\$50'],
      );
    },
  ),
  Interaction(
    id: 'define_relationship',
    label: 'Make it official',
    group: 'Special',
    keywords: ['exclusive', 'official', 'girlfriend', 'boyfriend', 'define'],
    only: _isPartner,
    check: (life, n) => _stage(life, n, {'dating'}, 'Already official'),
    run: (life, n, k, rng) {
      if (n.bond >= 55) {
        setStage(life, n, 'exclusive');
        return bondResult(
          life,
          n,
          '"So... are we a thing?" ${n.name.split(' ').first} grinned. "We have been a thing for weeks." It is official.',
          affection: 4,
        );
      }
      return bondResult(
        life,
        n,
        '${n.name.split(' ').first} said they were not ready to put a label on it yet.',
        extra: ['Why: Bond ${n.bond}% (needs 55%)'],
      );
    },
  ),
  Interaction(
    id: 'move_in',
    label: 'Ask to move in together',
    group: 'Special',
    minAge: 18,
    keywords: ['move in', 'live together', 'flat', 'home'],
    only: _isPartner,
    check: (life, n) =>
        _stage(life, n, {'dating', 'exclusive'}, 'You already live together'),
    run: (life, n, k, rng) {
      if (n.bond >= 62) {
        setStage(life, n, 'living');
        life.stats.add('happiness', 5);
        return bondResult(
          life,
          n,
          'You moved in together. There are now two kettles, too many cushions and one strong opinion each about the dishwasher. You are very happy.',
          affection: 3,
          familiarity: 6,
          extra: ['Happiness +5'],
        );
      }
      return bondResult(
        life,
        n,
        '${n.name.split(' ').first} said it was too soon.',
        extra: ['Why: Bond ${n.bond}% (needs 62%)'],
      );
    },
  ),
  Interaction(
    id: 'propose',
    label: 'Propose',
    group: 'Special',
    minAge: 18,
    keywords: ['propose', 'ring', 'marry', 'engagement'],
    only: _isPartner,
    check: (life, n) => _stage(
      life,
      n,
      {'exclusive', 'living'},
      stageOf(life, n) == 'dating'
          ? 'Make it official first'
          : 'Already engaged',
    ),
    run: (life, n, k, rng) {
      life.sceneQueue.add('proposal');
      return ActionResult('You start looking at rings...');
    },
  ),
  Interaction(
    id: 'plan_wedding',
    label: 'Plan the wedding',
    group: 'Special',
    keywords: ['wedding', 'marry', 'venue', 'guests'],
    only: _isPartner,
    check: (life, n) => _stage(life, n, {'engaged'}, 'Get engaged first'),
    run: (life, n, k, rng) {
      if (life.netWorth >= 50000 ||
          ((n.info['wealth'] as int?) ?? 0) >= 50000) {
        life.sceneQueue.add('prenup');
      } else {
        life.sceneQueue.add('wedding');
      }
      return ActionResult('You start planning the big day...');
    },
  ),
  Interaction(
    id: 'counselling',
    label: 'Couples counselling',
    group: 'Repair',
    cost: 150,
    keywords: ['counselling', 'therapy', 'couples', 'fix'],
    only: _isPartner,
    run: (life, n, k, rng) {
      life.money -= 150;
      return bondResult(
        life,
        n,
        'A kind counsellor helped you both say the things you had been swallowing for months. It was hard, and it helped.',
        trust: 6,
        affection: 3,
        resentment: -10,
        extra: ['Money −\$150'],
      );
    },
  ),
  Interaction(
    id: 'family_planning',
    label: 'Talk about children',
    group: 'Special',
    minAge: 18,
    maxAge: 55,
    keywords: ['children', 'kids', 'baby', 'family', 'pregnant'],
    only: _isPartner,
    check: (life, n) => _stage(life, n, {
      'living',
      'engaged',
      'married',
    }, 'Live together first'),
    run: (life, n, k, rng) {
      life.sceneQueue.add('family_planning');
      return ActionResult('You sit down for the big conversation...');
    },
  ),
  Interaction(
    id: 'break_up',
    label: 'Break up',
    group: 'Conflict',
    keywords: ['break up', 'dump', 'leave', 'end it'],
    only: _isPartner,
    check: (life, n) => stageOf(life, n) == 'married'
        ? 'You are married: this would be a divorce'
        : null,
    run: (life, n, k, rng) {
      endRelationship(life, n, 'breaking up with you');
      life.stats.add('happiness', -6);
      return ActionResult(
        'You ended it with ${n.name.split(' ').first}. There were tears on both sides, and a box of belongings changed hands on a rainy Tuesday.',
        ['Happiness −6', '${n.name.split(' ').first} is now an ex'],
      );
    },
  ),
  Interaction(
    id: 'divorce',
    label: 'Ask for a divorce',
    group: 'Conflict',
    keywords: ['divorce', 'separate', 'split'],
    only: _isPartner,
    check: (life, n) =>
        stageOf(life, n) == 'married' ? null : 'Only when married',
    run: (life, n, k, rng) {
      life.sceneQueue.add('divorce');
      return ActionResult('You sit down at the kitchen table...');
    },
  ),
  Interaction(
    id: 'reconcile',
    label: 'Try getting back together',
    group: 'Repair',
    keywords: ['ex', 'back together', 'reconcile', 'second chance'],
    only: (n) => n.circle == 'Exes',
    check: (life, n) => partnerOf(life) != null
        ? 'You are with someone'
        : (n.grudge != null ? '${n.name} still resents you' : null),
    run: (life, n, k, rng) {
      if (rng.nextInt(100) < n.bond) {
        final p = recircle(life, n, circle: 'Partner', role: 'Partner');
        setStage(life, p, 'dating');
        return bondResult(
          life,
          p,
          'You met for coffee "just to talk". Three hours later you were holding hands. Second time lucky?',
          affection: 6,
        );
      }
      return bondResult(
        life,
        n,
        '${n.name.split(' ').first} said some doors are better left closed.',
        extra: ['Why: Bond ${n.bond}%'],
      );
    },
  ),
  Interaction(
    id: 'end_affair',
    label: 'End the affair',
    group: 'Conflict',
    keywords: ['affair', 'end', 'stop'],
    only: (n) => n.circle == 'Lover',
    run: (life, n, k, rng) {
      life.npcs.remove(n);
      life.flags.remove('affair');
      return ActionResult(
        'You ended it. ${n.name.split(' ').first} did not take it well, but the secret stayed a secret. For now.',
      );
    },
  ),
];

/// Ends a relationship: the partner becomes an ex who remembers why.
void endRelationship(Life l, Npc p, String memory) {
  final ex = recircle(l, p, circle: 'Exes', role: 'Ex');
  ex.info.remove('stage');
  ex.remember(
    NpcMemory(
      age: l.age,
      text: memory,
      valence: -2,
      intensity: 3,
      tags: ['love'],
    ),
  );
  ex.addFacets(affection: -20, resentment: 15);
  l.flags.remove('partner');
  l.flags.remove('living_together');
  l.flags.remove('engaged');
  l.flags.remove('married');
  l.tryingForBaby = false;
}

// ---------------- Scenes ----------------

Storylet? loveScene(String kind, Life l) {
  final p = partnerOf(l);
  Storylet scene(String text, List<Choice> choices) => Storylet(
    id: 'scene:$kind',
    text: text,
    category: 'love',
    scene: true,
    choices: choices,
  );
  switch (kind) {
    case 'kindling':
      return kindlingScene(l);
    case 'proposal':
      if (p == null) return null;
      Choice ring(
        String label,
        int cost,
        int bonus, {
        bool public = false,
      }) => Choice(
        label: label,
        outcome: '',
        needsMoney: cost,
        risk: public ? 'Big gesture, big pressure' : null,
        run: (life, rng) {
          life.money -= cost;
          final odds =
              (p.bond + bonus + (public ? (p.bond >= 75 ? 5 : -15) : 0)).clamp(
                5,
                98,
              );
          if (rng.nextInt(100) < odds) {
            setStage(life, p, 'engaged');
            p.addFacets(affection: 8);
            life.stats.add('happiness', 8);
            return '${p.name.split(' ').first} said yes before you finished the question${public ? ', and the whole restaurant applauded' : ''}. You are engaged!';
          }
          p.remember(
            NpcMemory(
              age: life.age,
              text: 'a proposal they were not ready for',
              valence: -1,
              intensity: 2,
              tags: ['love'],
            ),
          );
          life.stats.add('happiness', -8);
          return '${p.name.split(' ').first} went pale and said, gently, "I am not ready." ${public ? 'Forty strangers pretended not to watch.' : ''} Odds were about $odds% (Bond ${p.bond}%).';
        },
      );
      return scene(
        'You have been carrying the ring box in your pocket for a week, checking it every ten minutes. Tonight is the night. How do you do it?',
        [
          ring('Simple ring, quiet dinner (\$500)', 500, 0),
          ring('Classic ring, their favourite place (\$3,000)', 3000, 5),
          ring(
            'Showstopper ring, public proposal (\$15,000)',
            15000,
            10,
            public: true,
          ),
          Choice(
            label: 'Not yet',
            outcome: 'The ring went back in the sock drawer.',
          ),
        ],
      );
    case 'prenup':
      if (p == null) return null;
      return scene(
        'Before the wedding, there is the awkward question of money. You have ${_m(l.netWorth)} to your name. A prenup protects what you bring in; it may also bruise feelings.',
        [
          Choice(
            label: 'No prenup',
            outcome: '',
            run: (life, rng) {
              p.info['prenup'] = 'none';
              life.sceneQueue.add('wedding');
              return 'You decided love was enough. ${p.name.split(' ').first} looked relieved. If you ever divorce, savings are split 50/50.';
            },
          ),
          Choice(
            label: 'Standard: protect what you had before',
            outcome: '',
            run: (life, rng) {
              p.info['prenup'] = 'standard';
              p.addFacets(trust: -3);
              life.sceneQueue.add('wedding');
              return 'You both signed a standard prenup. It felt very grown-up and slightly unromantic.';
            },
          ),
          Choice(
            label: 'Ironclad: protect everything',
            outcome: '',
            risk: 'They may refuse',
            run: (life, rng) {
              if (p.bond < 70) {
                p.addFacets(trust: -10, resentment: 6);
                return '${p.name.split(' ').first} read it, put the pen down and said, "So you are already planning the divorce?" The wedding is on hold.';
              }
              p.info['prenup'] = 'ironclad';
              p.addFacets(trust: -8);
              life.sceneQueue.add('wedding');
              return 'They signed, but something cooled between you. Your money is very safe.';
            },
          ),
        ],
      );
    case 'wedding':
      if (p == null) return null;
      Choice venue(String label, int cost, int joy) => Choice(
        label: label,
        outcome: '',
        needsMoney: cost,
        run: (life, rng) {
          life.money -= cost;
          setStage(life, p, 'married');
          final spouse = recircle(
            life,
            p,
            circle: 'Partner',
            role: p.gender == 'female' ? 'Wife' : 'Husband',
          );
          spouse.addFacets(affection: 10, familiarity: 5);
          life.stats.add('happiness', joy);
          for (final g in life.npcs.where(
            (n) => n.circle == 'Family' || n.circle == 'Friends',
          )) {
            g.addFacets(affection: 3);
            g.remember(
              NpcMemory(
                age: life.age,
                text: 'being at your wedding',
                valence: 2,
                intensity: 2,
                tags: ['love'],
              ),
            );
          }
          const mishaps = [
            'It rained, and nobody cared.',
            'An ex turned up uninvited and was escorted out by your uncle.',
            'Your uncle gave a speech nobody asked for. It was weirdly moving.',
            'The cake leaned like a tower in Pisa.',
          ];
          final mishap = rng.nextInt(100) < 35
              ? ' ${mishaps[rng.nextInt(mishaps.length)]}'
              : '';
          return 'You married ${p.name}.$mishap Everyone you love was there, and they will remember it.';
        },
      );
      return scene(
        'The big day needs a venue. Guests, food and flowers grow with the budget. Everyone in your Family and Friends circles is invited.',
        [
          venue('Courthouse, then lunch (\$200)', 200, 6),
          venue('Garden party (\$3,000)', 3000, 9),
          venue('Hall with a band (\$12,000)', 12000, 11),
          venue('Destination wedding (\$25,000)', 25000, 13),
          Choice(
            label: 'Postpone',
            outcome: 'You decided to wait a little longer.',
          ),
        ],
      );
    case 'divorce':
      if (p == null) return null;
      final prenup = (p.info['prenup'] as String?) ?? 'none';
      final kids = l.npcs
          .where(
            (n) => n.circle == 'Children' && n.alive && n.ageIn(l.year) < 18,
          )
          .toList();
      String split(Life life, Random rng, {required bool court}) {
        final liquid = life.money + life.savings + life.invested;
        final share = switch (prenup) {
          'ironclad' => 0.1,
          'standard' => 0.25,
          _ => 0.5,
        };
        final payout = (max(0, liquid) * share).round();
        final fee = court ? 10000 : 2000;
        life.money -= payout + fee;
        var custody = 'joint custody';
        if (kids.isNotEmpty) {
          final odds = court
              ? (40 +
                        (life.stats['karma'] - 50) ~/ 2 +
                        (kids.first.bond - 50) ~/ 2)
                    .clamp(10, 90)
              : 100;
          custody = court
              ? (rng.nextInt(100) < odds
                    ? 'primary custody'
                    : 'visiting rights')
              : 'joint custody';
          life.flags['custody'] = Memory(life.age, custody);
          if (custody == 'visiting rights') {
            life.flags['child_support'] = Memory(
              life.age,
              'paying child support',
            );
          }
          for (final k in kids) {
            k.addFacets(affection: -5, trust: -4);
            k.remember(
              NpcMemory(
                age: life.age,
                text: 'your divorce',
                valence: -2,
                intensity: 3,
                tags: ['family'],
              ),
            );
          }
        }
        endRelationship(life, p, 'the divorce');
        life.flags['divorced'] = Memory(
          life.age,
          'your divorce from ${p.name}',
        );
        life.stats.add('happiness', -10);
        return '${court ? 'A long court battle' : 'A mediated divorce'} ended your marriage. You paid ${_m(fee)} in fees and ${_m(payout)} to ${p.name.split(' ').first} (prenup: $prenup).${kids.isEmpty ? '' : ' Children: $custody${custody == 'visiting rights' ? ', and you pay child support' : ''}.'}';
      }
      return scene(
        'You both know it is over. The question is how it ends: quietly with a mediator, or in court.${kids.isEmpty ? '' : ' The children are the hardest part.'}',
        [
          Choice(
            label: 'Mediated divorce (\$2,000)',
            outcome: '',
            run: (life, rng) => split(life, rng, court: false),
          ),
          Choice(
            label: 'Fight it in court (\$10,000)',
            outcome: '',
            risk: kids.isEmpty ? 'Costly' : 'Custody at stake',
            run: (life, rng) => split(life, rng, court: true),
          ),
          Choice(
            label: 'Try counselling first',
            outcome: '',
            run: (life, rng) {
              p.addFacets(trust: 4, resentment: -5);
              return 'You agreed to give it one more try with a counsellor. Some weeks are better than others.';
            },
          ),
        ],
      );
    case 'affair_found':
      if (p == null) return null;
      final lover = loverOf(l);
      return scene(
        '${p.name.split(' ').first} is holding your phone. Their face is white. "Who is ${lover?.name.split(' ').first ?? 'this'}?"',
        [
          Choice(
            label: 'Deny everything',
            outcome: '',
            risk: 'Risky',
            run: (life, rng) {
              if (rng.nextInt(100) < 30) {
                p.addFacets(trust: -15);
                return 'You lied smoothly. They want to believe you, but they check your phone now.';
              }
              p.addFacets(trust: -30, affection: -20, resentment: 25);
              p.remember(
                NpcMemory(
                  age: life.age,
                  text: 'lying about the affair',
                  valence: -3,
                  intensity: 5,
                  tags: ['betrayal'],
                ),
              );
              return 'The lie fell apart in minutes. The lie hurt more than the affair.';
            },
          ),
          Choice(
            label: 'Confess',
            outcome: '',
            run: (life, rng) {
              p.addFacets(trust: -25, affection: -10, resentment: 15);
              p.remember(
                NpcMemory(
                  age: life.age,
                  text: 'the affair',
                  valence: -3,
                  intensity: 4,
                  tags: ['betrayal'],
                ),
              );
              if (lover != null) life.npcs.remove(lover);
              life.flags.remove('affair');
              return 'You told the truth and ended it with ${lover?.name.split(' ').first ?? 'them'}. ${p.name.split(' ').first} has not decided whether to stay. They are sleeping in the spare room.';
            },
          ),
          Choice(
            label: 'Leave for the lover',
            outcome: '',
            run: (life, rng) {
              endRelationship(life, p, 'leaving them for someone else');
              if (lover != null) {
                final np = recircle(
                  life,
                  lover,
                  circle: 'Partner',
                  role: 'Partner',
                );
                setStage(life, np, 'dating');
              }
              life.flags.remove('affair');
              return 'You packed a bag and left. Some friends stopped calling. The new relationship began with a lot to prove.';
            },
          ),
        ],
      );
    case 'ultimatum':
      if (p == null) return null;
      return scene(
        '${p.name.split(' ').first} puts down their fork. "We have been engaged for three years. Are we actually getting married, or not?"',
        [
          Choice(
            label: 'Set a date',
            outcome: '',
            run: (life, rng) {
              life.sceneQueue.add(
                life.netWorth >= 50000 ? 'prenup' : 'wedding',
              );
              p.addFacets(affection: 4);
              return 'You picked a date that night. They cried, then started a spreadsheet.';
            },
          ),
          Choice(
            label: 'Ask for more time',
            outcome: '',
            run: (life, rng) {
              p.addFacets(affection: -8, resentment: 8);
              return '"More time," they repeated, flatly. Something shifted.';
            },
          ),
          Choice(
            label: 'Call it off',
            outcome: '',
            run: (life, rng) {
              endRelationship(life, p, 'calling off the engagement');
              return 'You gave back the ring. It was the right thing, and it hurt anyway.';
            },
          ),
        ],
      );
    case 'partner_affair':
      if (p == null) return null;
      return scene(
        'The late nights, the new phone password, the vague answers. Tonight ${p.name.split(' ').first} admits it: they have been seeing someone else.',
        [
          Choice(
            label: 'Forgive them',
            outcome: '',
            run: (life, rng) {
              p.addFacets(resentment: -5);
              life.stats.add('happiness', -6);
              return 'You chose to try again. Trust is a slow thing to rebuild, but you are both trying.';
            },
          ),
          Choice(
            label: 'Leave',
            outcome: '',
            run: (life, rng) {
              if (stageOf(life, p) == 'married') {
                life.sceneQueue.add('divorce');
                return 'You told them you wanted a divorce.';
              }
              endRelationship(life, p, 'cheating on you');
              life.stats.add('happiness', -8);
              return 'You walked out and did not look back. Your friends brought wine and opinions.';
            },
          ),
        ],
      );
  }
  return null;
}

/// Yearly love life: affair discovery, engagement patience, a partner who
/// strays (hints first), and the wish for children.
void loveYear(Life l, Random rng) {
  final p = partnerOf(l);
  if (p == null) return;
  final lover = loverOf(l);
  if (lover != null) {
    // Plan: discovery = 15% + 10% per risky year, modified by trust.
    final risk = ((lover.info['risk'] as int?) ?? 0) + 1;
    lover.info['risk'] = risk;
    final odds = 15 + 10 * (risk - 1) - (p.trust - 50) ~/ 10;
    if (rng.nextInt(100) < odds) l.sceneQueue.add('affair_found');
  }
  final stage = stageOf(l, p);
  final since = (p.info['stageSince'] as int?) ?? l.age;
  if (stage == 'engaged' && l.age - since >= 3) l.sceneQueue.add('ultimatum');
  if (p.bond < 35 && rng.nextInt(100) < 6) {
    if (p.info['straying'] == true) {
      p.info.remove('straying');
      l.sceneQueue.add('partner_affair');
    } else {
      p.info['straying'] = true;
      l.feed.add(
        FeedEntry(
          l.age,
          '${p.name.split(' ').first} has been working late a lot, and their phone has a new password.',
          kind: 'nudge',
        ),
      );
    }
  }
}

final loveActions = <GameAction>[
  GameAction(
    id: 'kindling',
    label: 'Open Kindling (dating app)',
    category: 'Love',
    keywords: ['dating', 'app', 'kindling', 'tinder', 'match', 'love'],
    minAge: 18,
    extraCheck: (l) => partnerOf(l) != null
        ? 'You are in a relationship'
        : (l.money < 60 ? 'Needs \$60 for a date' : null),
    run: (l, rng) {
      l.sceneQueue.add('kindling');
      return ActionResult('You open the app...');
    },
  ),
  GameAction(
    id: 'go_out',
    label: 'Go out for the night',
    category: 'Social',
    keywords: ['night out', 'bar', 'club', 'dance', 'party', 'meet someone'],
    minAge: 18,
    cost: 60,
    run: goingOut,
  ),
  GameAction(
    id: 'affair',
    label: 'Have an affair',
    category: 'Love',
    keywords: ['affair', 'cheat', 'secret', 'lover'],
    minAge: 18,
    extraCheck: (l) => partnerOf(l) == null
        ? 'You are single'
        : (loverOf(l) != null ? 'You already have one' : null),
    run: (l, rng) {
      final lover = candidate(l, rng, id: 'lover');
      final n = Npc(
        id: 'lover',
        role: 'Secret lover',
        name: lover.name,
        birthYear: lover.birthYear,
        circle: 'Lover',
        bond: 60,
      )..lastContactAge = l.age;
      n.info.addAll(lover.info..remove('stage'));
      n.info['risk'] = 0;
      l.npcs.add(n);
      l.flags['affair'] = Memory(l.age, 'an affair with ${n.name}');
      l.stats.add('karma', -6);
      return ActionResult(
        'It started with a look across a room, and then it was not just a look. You and ${n.name.split(' ').first} are having an affair. Every year it goes on, the chance of being found out grows.',
        ['Karma −6', 'Discovery: 15% a year, rising'],
      );
    },
  ),
];
