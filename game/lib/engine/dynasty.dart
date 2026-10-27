import 'dart:math';

import 'actions.dart';
import 'careers.dart';
import 'family.dart';
import 'lifespan.dart';
import 'love.dart';
import 'models.dart';
import 'possessions.dart';
import 'storylet.dart';

/// Generations and dynasty (plan Social §4): continue as an heir, the heir
/// picker, default inheritance and wills, trusts for minors, and the
/// 8-generation cap (free players reach Generation 4; Plus extends to 8).

int dynastyCap({required bool plus}) => plus ? 8 : 4;

/// Eligible heirs: living children (biological or adopted).
List<Npc> heirsOf(Life l) => childrenOf(l).where((c) => c.alive).toList();

/// Estate after debts and estate tax (20% above \$500,000). Heirs never
/// inherit negative net worth (plan GE-005).
int estateOf(Life l) {
  final gross = max(0, l.netWorth - heirloomValue(l));
  final tax = gross > 500000 ? ((gross - 500000) * 0.2).round() : 0;
  return gross - tax;
}

/// Each heir's share under the will (or the default rules: a surviving
/// partner gets half, the children split the rest).
int shareFor(Life l, Npc heir) {
  final estate = estateOf(l);
  final kids = heirsOf(l).length;
  if (kids == 0) return 0;
  final partner = partnerOf(l) != null;
  final forKids = switch (l.will) {
    'partner' => partner ? 0 : estate,
    'charity' => estate ~/ 2,
    'equal' => estate,
    _ => partner ? estate ~/ 2 : estate,
  };
  return forKids ~/ kids;
}

/// What this child remembers of you, in one line for the heir card.
String memoryOf(Npc child) {
  final good = child.memories.where((m) => !m.negative).length;
  final bad = child.memories.where((m) => m.negative).length;
  if (child.bond >= 80) {
    return '${child.name} remembers you as warm and always there.';
  }
  if (bad > good) return '${child.name} remembers a lot of arguments.';
  if (child.bond < 40) return '${child.name} remembers you as distant.';
  return '${child.name} remembers you fondly, mostly.';
}

/// The heir's life starts where the parent's ended: same world, same family
/// name, the parent now a memory (plan GE-001/004).
Life heirLife(Life old, Npc heir) {
  final share = shareFor(old, heir);
  final age = heir.ageIn(old.year);
  final stats = Stats.random(Random(old.seed + heir.id.hashCode));
  final inherited = Map<String, dynamic>.from(heir.info['stats'] ?? {});
  inherited.forEach((k, v) => stats.values[k] = (v as int).clamp(0, 100));
  final parentRole = old.gender == 'female' ? 'Mother' : 'Father';
  final parentId = old.gender == 'female' ? 'mother' : 'father';
  final otherParent = partnerOf(old);
  final npcs = <Npc>[
    Npc(
      id: parentId,
      role: parentRole,
      name: old.firstName,
      birthYear: old.birthYear,
      circle: 'Family',
      bond: heir.bond,
      memories: heir.memories,
    )..alive = false,
    if (otherParent != null)
      Npc(
        id: parentId == 'mother' ? 'father' : 'mother',
        role: parentId == 'mother' ? 'Father' : 'Mother',
        name: otherParent.name.split(' ').first,
        birthYear: otherParent.birthYear,
        circle: 'Family',
        bond: 70,
      )..lastContactAge = old.age,
  ];
  // Pets stay with the family.
  for (final p in old.npcs.where((n) => n.circle == 'Pets' && n.alive)) {
    npcs.add(p);
  }
  var sib = 0;
  for (final c in heirsOf(old).where((c) => c != heir)) {
    sib++;
    npcs.add(
      Npc(
        id: sib == 1 ? 'sibling' : 'sibling$sib',
        role: c.gender == 'female' ? 'Sister' : 'Brother',
        name: c.name,
        birthYear: c.birthYear,
        circle: 'Family',
        bond: 60,
      )..lastContactAge = old.age,
    );
  }
  final life =
      Life(
          seed: old.seed * 31 + heir.id.hashCode,
          firstName: heir.name,
          surname: old.surname,
          gender: heir.gender,
          country: old.country,
          city: old.city,
          birthYear: heir.birthYear,
          stats: stats,
          npcs: npcs,
          age: age,
          education: age < 5
              ? 'none'
              : age < 12
              ? 'primary'
              : age < 18
              ? 'secondary'
              : 'high school graduate',
        )
        ..generation = old.generation + 1
        ..difficulty = old.difficulty
        ..ironman = old.ironman
        ..classic = old.classic
        ..economy = old.economy;
  life.lineage
    ..addAll(old.lineage)
    ..add({
      'name': old.fullName,
      'born': old.birthYear,
      'died': old.year,
      'title': titleFor(old).name,
      'cause': old.causeOfDeath ?? '',
      'job': old.job ?? (old.retired ? 'Retired' : ''),
    });
  if (age >= 18) {
    life.money = share;
  } else {
    life.trust = share;
  }
  life.flags['heir'] = Memory(age, 'inheriting from ${old.firstName}');
  final heirlooms = passHeirlooms(old);
  life.assets.addAll(heirlooms);
  for (final h in heirlooms) {
    life.feed.add(
      FeedEntry(
        age,
        'You inherited the family ${h.name.toLowerCase()}: ${h.info['about']}. ${heirloomHistory(h).length} people have owned it before you.',
        kind: 'milestone',
      ),
    );
  }
  life.feed.add(
    FeedEntry(
      age,
      'You are ${heir.name} ${old.surname}, Generation ${life.generation}. ${memoryOf(heir)} ${share > 0 ? (age >= 18 ? 'You inherited \$$share.' : '\$$share is held in trust until you turn 18.') : ''}',
      kind: 'milestone',
    ),
  );
  return life;
}

/// Trust money is released at 18 (plan AS-010).
String? releaseTrust(Life l) {
  if (l.age != 18 || l.trust <= 0) return null;
  final t = l.trust;
  l.money += t;
  l.trust = 0;
  return 'You turned 18: the \$$t held in trust for you is now yours.';
}

Storylet willScene() => Storylet(
  id: 'scene:will',
  text: 'A solicitor slides a form across the desk. "Who should inherit your estate?" Without a will, a partner gets half and your children split the rest.',
  category: 'money',
  scene: true,
  choices: [
    for (final (k, label, text) in const [
      (
        'equal',
        'Everything to my children, equally',
        'Your children will split everything equally.',
      ),
      (
        'partner',
        'Everything to my partner',
        'Your partner will inherit everything; the children inherit from them later.',
      ),
      (
        'charity',
        'Half to charity, half to my children',
        'Half your estate will go to charity. Your name will be remembered for it.',
      ),
      (
        'default',
        'Use the default rules',
        'You left it to the default: half to a partner, the rest to the children.',
      ),
    ])
      Choice(
        label: label,
        outcome: text,
        run: (life, rng) {
          life.will = k;
          life.flags['will'] = Memory(life.age, 'writing a will');
          return null;
        },
      ),
  ],
);

final dynastyActions = <GameAction>[
  GameAction(
    id: 'write_will',
    label: 'Write a will',
    category: 'Money',
    keywords: ['will', 'inheritance', 'estate', 'heirs', 'solicitor'],
    minAge: 18,
    cost: 300,
    run: (l, rng) {
      l.money -= 300;
      l.sceneQueue.add('will');
      return ActionResult('You book a solicitor.', ['Money −\$300']);
    },
  ),
];

/// Careers that count toward the dynasty's record (for the family tree).
String careerLabel(Life l) => careerById(l.careerId)?.field ?? (l.job ?? '');
