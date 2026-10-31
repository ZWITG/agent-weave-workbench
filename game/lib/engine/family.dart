import 'dart:math';

import 'actions.dart';
import 'births.dart';
import 'love.dart';
import 'models.dart';
import 'relationships.dart';
import 'storylet.dart';
import 'world_data.dart';

/// Children and family (plan Social §3): your parents' own marriage, family
/// planning, conception, IVF and adoption, children as people with
/// inherited traits and memories, parenting cards by age, custody and
/// child support.

List<Npc> childrenOf(Life l) =>
    l.npcs.where((n) => n.circle == 'Children').toList();
bool _isChild(Npc n) => n.circle == 'Children';

// ---------------- Your parents' marriage ----------------

/// Plan: parents' Marriage Health drifts; below 25 for two years they may
/// separate; divorced parents may remarry (step-parents).
void parentsYear(Life l, Random rng) {
  final mum = l.npc('mother');
  final dad = l.npc('father');
  if (mum == null || dad == null || !mum.alive || !dad.alive) return;
  if (l.flags.containsKey('parents_divorced')) {
    if (l.age < 30 && rng.nextInt(100) < 10) {
      final c = countryNamed(l.country);
      final stepmum = l.npc('stepmother') == null && rng.nextBool();
      final id = stepmum ? 'stepmother' : 'stepfather';
      if (l.npc(id) == null) {
        final pool = stepmum ? c.female : c.male;
        final n = Npc(
          id: id,
          role: stepmum ? 'Stepmother' : 'Stepfather',
          name: pool[rng.nextInt(pool.length)],
          birthYear: (stepmum ? dad : mum).birthYear + rng.nextInt(7) - 3,
          circle: 'Family',
          bond: 40 + rng.nextInt(20),
        )..lastContactAge = l.age;
        l.npcs.add(n);
        l.feed.add(
          FeedEntry(
            l.age,
            '${stepmum ? dad.name : mum.name} remarried. ${n.name} is now your ${n.role.toLowerCase()}.',
            kind: 'milestone',
          ),
        );
      }
    }
    return;
  }
  l.parentsMarriage = (l.parentsMarriage + rng.nextInt(7) - 4).clamp(0, 100);
  if (l.parentsMarriage < 25) {
    l.parentsLowYears++;
    if (l.parentsLowYears >= 2 && rng.nextInt(100) < 45) {
      l.sceneQueue.add('parents_split');
    }
  } else {
    l.parentsLowYears = 0;
  }
}

// ---------------- Children ----------------

const _babyNames = {
  'female': [
    'Ava',
    'Maya',
    'Lucia',
    'Zara',
    'Nora',
    'Iris',
    'Amara',
    'Sofia',
    'Rosa',
    'Elena',
  ],
  'male': [
    'Leo',
    'Noah',
    'Mateo',
    'Kai',
    'Theo',
    'Sami',
    'Jonah',
    'Rafael',
    'Felix',
    'Omar',
  ],
};

/// A child inherits from both parents, plus noise (plan CH-006).
Npc newChild(
  Life l,
  Random rng, {
  String? name,
  String? gender,
  int ageNow = 0,
  bool adopted = false,
  String? otherParent,
}) {
  final g = gender ?? (rng.nextBool() ? 'female' : 'male');
  final p = partnerOf(l);
  final pool = _babyNames[g]!;
  int inherit(String s, int fromPartner) => adopted
      ? 30 + rng.nextInt(60)
      : ((l.stats[s] + fromPartner) ~/ 2 + rng.nextInt(31) - 15).clamp(5, 100);
  final n = Npc(
    id: freshNpcId(l, 'child'),
    role: g == 'female' ? 'Daughter' : 'Son',
    name: name ?? pool[rng.nextInt(pool.length)],
    birthYear: l.year - ageNow,
    circle: 'Children',
    bond: 85,
  )..lastContactAge = l.age;
  n.info.addAll({
    'gender': g,
    'adopted': adopted,
    'otherParent': otherParent ?? p?.name,
    'stats': {
      'smarts': inherit('smarts', 60),
      'looks': inherit('looks', (p?.info['looks'] as int?) ?? 60),
      'athleticism': inherit('athleticism', 55),
      'creativity': inherit('creativity', 55),
      'karma': inherit('karma', (p?.info['karma'] as int?) ?? 60),
    },
  });
  return n;
}

bool sameSexCouple(Life l) {
  final p = partnerOf(l);
  return p != null && p.gender == l.gender;
}

/// Yearly: trying for a baby, births, children growing.
void familyYear(Life l, Random rng) {
  if (l.flags.containsKey('expecting')) {
    l.flags.remove('expecting');
    l.sceneQueue.add('birth');
    return;
  }
  reunionYear(l, rng);
  final p = partnerOf(l);
  if (!l.tryingForBaby || p == null || sameSexCouple(l)) {
    surpriseBabyYear(l, rng);
    return;
  }
  final myFert = l.stats['fertility'];
  final theirFert = (p.info['fertility'] as int?) ?? 60;
  final age = l.gender == 'female' ? l.age : p.ageIn(l.year);
  final agePenalty = age > 35 ? (age - 35) * 6 : 0;
  final odds = ((myFert + theirFert) ~/ 2 * 0.7 - agePenalty).round().clamp(
    2,
    70,
  );
  if (rng.nextInt(100) < odds) {
    l.flags['expecting'] = Memory(l.age, 'finding out you were expecting');
    maybeBirthPlan(l);
    l.feed.add(
      FeedEntry(
        l.age,
        'Two pink lines. You and ${p.name.split(' ').first} are expecting a baby!',
        kind: 'milestone',
      ),
    );
  }
}

/// Feed lines for children growing up (plan: children as people).
List<FeedEntry> childUpdates(Life l, Random rng) {
  final out = <FeedEntry>[];
  for (final c in childrenOf(l).where((c) => c.alive)) {
    final a = c.ageIn(l.year);
    final stats = Map<String, int>.from(c.info['stats'] ?? {});
    final first = c.name;
    String? line;
    if (a == 1) {
      line =
          '$first took their first wobbly steps, straight into the coffee table.';
    }
    if (a == 5) {
      line = '$first started school and announced they now know everything.';
    }
    if (a == 13) {
      line = '$first became a teenager overnight. The door is now always shut.';
    }
    if (a == 18) {
      final smart = (stats['smarts'] ?? 50) >= 60;
      line = smart
          ? '$first finished school with great grades and is off to university.'
          : '$first finished school and got a job at a local café.';
    }
    if (a == 22 && rng.nextBool()) {
      line = '$first moved into their own place. Your house is very quiet.';
    }
    if (a >= 26 &&
        a <= 34 &&
        !c.done.contains('married') &&
        rng.nextInt(100) < 15) {
      c.done.add('married');
      line = '$first got married. You cried through the whole ceremony.';
    }
    if (a >= 28 &&
        a <= 40 &&
        !c.done.contains('baby') &&
        rng.nextInt(100) < 12) {
      c.done.add('baby');
      line = '$first had a baby. You are a grandparent!';
      l.flags['grandparent'] = Memory(l.age, 'becoming a grandparent');
    }
    if (line != null) {
      c.news.add('Age ${l.age}: $line');
      out.add(FeedEntry(l.age, line, kind: 'npc', who: c.name));
    }
  }
  return out;
}

/// Raises one of a child's stats (parenting effects).
void _grow(Npc c, String stat, int by) {
  final s = Map<String, dynamic>.from(c.info['stats'] ?? {});
  s[stat] = ((s[stat] as int? ?? 50) + by).clamp(0, 100);
  c.info['stats'] = s;
}

int _age(Life l, Npc c) => c.ageIn(l.year);

final familyInteractions = <Interaction>[
  Interaction(
    id: 'read_together',
    label: 'Read a story together',
    group: 'Special',
    positive: true,
    keywords: ['read', 'story', 'book', 'bedtime'],
    only: _isChild,
    check: (l, c) => _age(l, c) > 9 ? 'Better for younger children' : null,
    run: (l, c, k, rng) {
      _grow(c, 'smarts', (3 * k).round());
      return bondResult(
        l,
        c,
        'You read ${c.name} the same story for the fourth time, with all the voices. They mouthed every word.',
        affection: (5 * k).round(),
        extra: ['${c.name}: Smarts up'],
      );
    },
  ),
  Interaction(
    id: 'play_together',
    label: 'Play together',
    group: 'Special',
    positive: true,
    keywords: ['play', 'games', 'park', 'fun'],
    only: _isChild,
    check: (l, c) =>
        _age(l, c) > 13 ? 'They think they are too old for this' : null,
    run: (l, c, k, rng) {
      _grow(c, 'creativity', (2 * k).round());
      l.stats.add('happiness', 2);
      return bondResult(
        l,
        c,
        'An afternoon of dens, dragons and you being the horse. ${c.name} will remember it longer than you think.',
        affection: (6 * k).round(),
        extra: ['Happiness +2'],
      );
    },
  ),
  Interaction(
    id: 'help_homework',
    label: 'Help with homework',
    group: 'Special',
    positive: true,
    keywords: ['homework', 'school', 'help', 'study'],
    only: _isChild,
    check: (l, c) => _age(l, c) < 6 || _age(l, c) > 18
        ? 'Only for school-age children'
        : null,
    run: (l, c, k, rng) {
      _grow(c, 'smarts', (4 * k).round());
      return bondResult(
        l,
        c,
        'You worked through ${c.name}\'s fractions together. Some of it came back to you; most of it did not.',
        respect: 3,
        affection: 2,
        extra: ['${c.name}: Smarts up'],
      );
    },
  ),
  Interaction(
    id: 'take_to_sport',
    label: 'Take them to sport',
    group: 'Special',
    positive: true,
    keywords: ['sport', 'football', 'swimming', 'training', 'match'],
    only: _isChild,
    check: (l, c) => _age(l, c) < 5 || _age(l, c) > 17 ? 'Ages 5 to 17' : null,
    run: (l, c, k, rng) {
      _grow(c, 'athleticism', (4 * k).round());
      return bondResult(
        l,
        c,
        'Cold sidelines, orange slices and very loud cheering. ${c.name} pretended to be embarrassed.',
        affection: 3,
        extra: ['${c.name}: Athleticism up'],
      );
    },
  ),
  Interaction(
    id: 'heart_to_heart',
    label: 'Have a heart-to-heart',
    group: 'Special',
    keywords: ['talk', 'feelings', 'advice', 'listen'],
    only: _isChild,
    check: (l, c) => _age(l, c) < 8 ? 'They are a bit young' : null,
    run: (l, c, k, rng) => bondResult(
      l,
      c,
      'You talked properly with ${c.name}: about friends, fears and what they want to be. You mostly listened, which was the point.',
      trust: 6,
      affection: 3,
    ),
  ),
  Interaction(
    id: 'teach_drive',
    label: 'Teach them to drive',
    group: 'Special',
    keywords: ['drive', 'driving', 'car', 'lessons'],
    only: _isChild,
    check: (l, c) =>
        _age(l, c) < 16 || _age(l, c) > 20 ? 'Ages 16 to 20' : null,
    run: (l, c, k, rng) => bondResult(
      l,
      c,
      'Your knuckles went white on the handbrake. ${c.name} only mounted the kerb twice. Progress.',
      affection: 4,
      respect: 2,
    ),
  ),
  Interaction(
    id: 'ground_them',
    label: 'Ground them',
    group: 'Conflict',
    keywords: ['ground', 'punish', 'discipline', 'rules'],
    only: _isChild,
    check: (l, c) => _age(l, c) < 6 || _age(l, c) > 17 ? 'Ages 6 to 17' : null,
    run: (l, c, k, rng) {
      c.remember(
        NpcMemory(
          age: l.age,
          text: 'being grounded',
          valence: -1,
          intensity: 1,
          tags: ['family'],
        ),
      );
      return bondResult(
        l,
        c,
        '${c.name} was grounded for a week and told you that you had ruined their entire life.',
        affection: -4,
        respect: 3,
      );
    },
  ),
];

// ---------------- Scenes ----------------

Storylet? familyScene(String kind, Life l) {
  final p = partnerOf(l);
  Storylet scene(String text, List<Choice> choices) => Storylet(
    id: 'scene:$kind',
    text: text,
    category: 'family',
    scene: true,
    choices: choices,
  );
  switch (kind) {
    case 'parents_split':
      final mum = l.npc('mother'), dad = l.npc('father');
      if (mum == null || dad == null) return null;
      Choice react(
        String label,
        String text, {
        int mumD = 0,
        int dadD = 0,
        Map<String, int> stats = const {},
      }) => Choice(
        label: label,
        outcome: '',
        run: (life, rng) {
          life.flags['parents_divorced'] = Memory(
            life.age,
            'your parents separating',
          );
          mum.addFacets(affection: mumD);
          dad.addFacets(affection: dadD);
          stats.forEach(life.stats.add);
          return text;
        },
      );
      return scene(
        '{mother} and {father} sit you down at the kitchen table. Nobody is shouting, which is somehow worse. "We have decided to separate," says {father}. "This is not your fault." You will live in two homes now.',
        [
          react(
            'Stay with {mother}',
            'You moved in with {mother} and see {father} every other weekend. Two birthdays, two Christmases, two toothbrushes.',
            mumD: 6,
            dadD: -6,
          ),
          react(
            'Stay with {father}',
            'You moved in with {father}. His cooking is worse, but he is trying very hard.',
            mumD: -6,
            dadD: 6,
          ),
          react(
            'Try to fix it',
            'You made them both a card and a "family meeting" agenda. They cried and hugged you. It did not change their minds, but they never forgot it.',
            mumD: 3,
            dadD: 3,
            stats: {'happiness': -4, 'karma': 2},
          ),
          react(
            'Act out',
            'You slammed doors for a year. Everyone understood, and nobody knew what to do.',
            mumD: -3,
            dadD: -3,
            stats: {'impulsivity': 3, 'happiness': -2},
          ),
        ],
      );
    case 'family_planning':
      if (p == null) return null;
      final wants = (p.info['wantsKids'] as bool?) ?? true;
      return scene(
        'You and ${p.name.split(' ').first} are curled up on the sofa when the conversation turns to children. ${wants ? 'They clearly want a family. ' : 'They seem unsure. '}What do you say?',
        [
          Choice(
            label: 'Let\'s start trying',
            outcome: '',
            run: (life, rng) {
              life.tryingForBaby = true;
              p.addFacets(affection: wants ? 6 : -2);
              return sameSexCouple(life)
                  ? 'You agreed you want a family. You will need IVF, a surrogate or adoption (see Activities).'
                  : 'You agreed to start trying. Every month brings hope and a lot of tests.';
            },
          ),
          Choice(
            label: 'Not yet',
            outcome: '',
            run: (life, rng) {
              p.addFacets(affection: wants ? -3 : 1);
              return 'You agreed to wait a few years. ${wants ? 'They said "fine" in the voice that means not fine.' : 'They looked relieved.'}';
            },
          ),
          Choice(
            label: 'I don\'t want children',
            outcome: '',
            run: (life, rng) {
              life.flags['no_kids'] = Memory(
                life.age,
                'deciding not to have children',
              );
              life.tryingForBaby = false;
              if (wants) {
                p.addFacets(affection: -12, resentment: 10);
                p.remember(
                  NpcMemory(
                    age: life.age,
                    text: 'not wanting children',
                    valence: -2,
                    intensity: 4,
                    tags: ['love'],
                  ),
                );
                return 'You told them the truth. ${p.name.split(' ').first} went very quiet. This is a big difference, and you both know it.';
              }
              p.addFacets(affection: 5);
              return 'They hugged you. "Me neither." It turns out you were both scared to say it.';
            },
          ),
        ],
      );
    case 'birth':
      final roll = Random(l.seed + l.age).nextInt(1000);
      final babies = roll < 3
          ? 3
          : roll < 33
          ? 2
          : 1;
      final g = Random(l.seed * 3 + l.age).nextBool() ? 'female' : 'male';
      final names = _babyNames[g]!;
      final picks = [
        names[l.age % names.length],
        names[(l.age + 3) % names.length],
        names[(l.age + 7) % names.length],
      ];
      final other = l.marks
          .where((m) => m.startsWith('baby_other:'))
          .map((m) => m.substring(11))
          .firstOrNull;
      final placing = l.marks.contains('baby_place');
      final secret = l.marks.contains('baby_secret');
      final where = birthSituation(l, Random(l.seed + l.age * 5));
      final many = babies == 3
          ? ' And then another, and another: triplets!'
          : babies == 2
          ? ' And then, to everyone\'s surprise, a twin.'
          : '';
      void tidy(Life life) => life.marks.removeWhere(
        (m) =>
            m.startsWith('baby_other:') ||
            m.startsWith('birth_plan:') ||
            m == 'baby_place' ||
            m == 'baby_secret',
      );
      return scene(
        '$where It\'s a ${g == 'female' ? 'girl' : 'boy'}.$many ${placing ? 'You have a little time together before the new family arrives. What name will you give ${g == 'female' ? 'her' : 'him'} to carry?' : 'Everyone is looking at you: what is ${g == 'female' ? 'her' : 'his'} name?'}',
        [
          for (final name in picks)
            Choice(
              label: name,
              outcome: '',
              run: (life, rng) {
                tidy(life);
                if (placing) {
                  life.marks.add('placed:$name:${life.year}');
                  life.flags['placed_child'] = Memory(
                    life.age,
                    'placing $name with a new family',
                  );
                  life.stats.add('happiness', -6);
                  return 'You held $name for an hour and whispered everything you wanted them to know. Then you let them go to a family who will love them.';
                }
                // Added one at a time so twins get their own ids.
                final born = <Npc>[];
                for (var i = 0; i < babies; i++) {
                  final gi = i == 0 ? g : (rng.nextBool() ? 'female' : 'male');
                  final free = _babyNames[gi]!
                      .where((n) => !born.any((b) => b.name == n) && n != name)
                      .toList();
                  final c = newChild(
                    life,
                    rng,
                    name: i == 0 ? name : free[rng.nextInt(free.length)],
                    gender: gi,
                    otherParent: other,
                  );
                  if (secret) c.info['secret'] = true;
                  life.npcs.add(c);
                  born.add(c);
                }
                life.flags['parent'] = Memory(life.age, 'the birth of $name');
                life.stats.add('happiness', 10);
                life.stress = life.stress + 15 * babies;
                final rest = born.skip(1).map((c) => c.name).join(' and ');
                return 'Welcome to the world, $name${rest.isEmpty ? '' : ' and $rest'}. You have never been so tired or so happy.${secret ? ' Only a handful of people know who the other parent is.' : ''}';
              },
            ),
        ],
      );
    case 'adopt':
      return scene(
        'The adoption agency calls: three children are waiting for a family. The social worker reminds you, kindly, that every age comes with its own joys and challenges.',
        [
          for (final (label, age) in const [
            ('A baby', 0),
            ('A toddler', 3),
            ('An older child', 8),
          ])
            Choice(
              label: label,
              outcome: '',
              run: (life, rng) {
                final child = newChild(life, rng, ageNow: age, adopted: true);
                life.npcs.add(child);
                if (age >= 6) {
                  child.addFacets(affection: -35, trust: -35, familiarity: -35);
                }
                life.flags['parent'] = Memory(
                  life.age,
                  'adopting ${child.name}',
                );
                life.stats.add('happiness', 8);
                return '${child.name}${age > 0 ? ', $age,' : ''} came home with you. ${age >= 6 ? 'Trust will take time: their Bond starts lower, and grows with care.' : 'The nursery is finally being used.'}';
              },
            ),
          Choice(
            label: 'Wait a little longer',
            outcome: 'You asked the agency to keep you on the list.',
          ),
        ],
      );
  }
  return null;
}

final familyActions = <GameAction>[
  GameAction(
    id: 'ivf',
    label: 'Try IVF',
    category: 'Family',
    keywords: ['ivf', 'fertility', 'baby', 'pregnant', 'surrogate'],
    minAge: 21,
    maxAge: 52,
    cost: 12000,
    extraCheck: (l) =>
        l.flags.containsKey('expecting') ? 'You are already expecting' : null,
    run: (l, rng) {
      l.money -= 12000;
      final odds = (25 + l.stats['fertility'] ~/ 3 - max(0, l.age - 38) * 3)
          .clamp(5, 60);
      if (rng.nextInt(100) < odds) {
        l.flags['expecting'] = Memory(l.age, 'a successful round of IVF');
        maybeBirthPlan(l);
        return ActionResult(
          'After months of appointments and injections, the call came: it worked. A baby is on the way!',
          ['Money −\$12,000', 'Odds were about $odds%'],
        );
      }
      l.stats.add('happiness', -6);
      return ActionResult(
        'This round did not work. The clinic says many people need more than one try.',
        ['Money −\$12,000', 'Why: odds about $odds% (Fertility, age)'],
      );
    },
  ),
  GameAction(
    id: 'adopt',
    label: 'Adopt a child',
    category: 'Family',
    keywords: ['adopt', 'adoption', 'child', 'foster'],
    minAge: 23,
    cost: 5000,
    extraCheck: (l) =>
        l.netWorth < 10000 ? 'Agencies look for net worth of \$10,000+' : null,
    run: (l, rng) {
      l.money -= 5000;
      l.sceneQueue.add('adopt');
      return ActionResult(
        'Months of forms and home visits later, the agency calls.',
        ['Money −\$5,000'],
      );
    },
  ),
];
