import 'dart:math';

import 'echelon.dart' show inheritEchelon;
import 'elite.dart' show upperEchelon;
import 'actions.dart';
import 'careers.dart';
import 'family.dart';
import 'lifespan.dart';
import 'love.dart';
import 'homes.dart' show homeOf;
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
  final oldTitle = titleFor(old);
  life.lineage
    ..addAll(old.lineage)
    ..add({
      'name': old.fullName,
      'born': old.birthYear,
      'died': old.year,
      'title': oldTitle.name,
      'rarity': oldTitle.rarity,
      'echelon': upperEchelon(old),
      'cause': old.causeOfDeath ?? '',
      'job': old.job ?? (old.retired ? 'Retired' : ''),
    });
  // Heirs to the upper echelon: prepared or not (echelon.dart).
  final (kept, why) = inheritEchelon(old, life, heir, share);
  if (age >= 18) {
    life.money = kept;
  } else {
    life.trust = kept;
  }
  if (why != null) life.feed.add(FeedEntry(age, why, kind: 'milestone'));
  life.flags['heir'] = Memory(age, 'inheriting from ${old.firstName}');
  // A child cannot hold property: it goes to auction and the money joins
  // their trust.
  if (auctionForMinor(old, life, heir, share) case final note?) {
    life.feed.add(FeedEntry(age, note, kind: 'milestone'));
  }
  // The family home stays in the family when the heir's share covers it.
  if (passFamilyHome(old, life, age) case final note?) {
    life.feed.add(FeedEntry(age, note, kind: 'milestone'));
  }
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
      'You are ${heir.name} ${old.surname}, Generation ${life.generation}. ${memoryOf(heir)} ${share > 0 ? (age >= 18 ? 'You inherited \$$share.' : '\$${life.trust} is held in trust until you turn 18.') : ''}',
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

/// An heir under 18 cannot inherit property, so every building the parent
/// owned is auctioned. Auctions rarely fetch the full valuation (85% to
/// 105%, 75% to 95% in a slump); the heir's trust moves by their share of
/// the difference. Returns the feed line, or null when there was nothing to
/// sell or the heir is grown up.
String? auctionForMinor(Life old, Life heir, Npc child, int share) {
  final age = child.ageIn(old.year);
  final homes = old.assets.where((a) => a.kind == 'house').toList();
  if (age >= 18 || homes.isEmpty) return null;
  final rng = Random(old.seed ^ 0xA0C7 ^ child.id.hashCode);
  final slump = old.economy == 'Recession' || old.economy == 'Crash';
  var gap = 0;
  final sold = <String>[];
  for (final h in homes) {
    final pct = (slump ? 75 : 85) + rng.nextInt(21);
    final price = (h.value * pct / 100 / 1000).round() * 1000;
    gap += price - h.value;
    final area = h.info['area'];
    sold.add(
      '${h.name.toLowerCase()}${area != null ? ' in $area' : ''} (${_money(price)})',
    );
  }
  final estate = estateOf(old);
  final move = estate > 0 ? (gap * share / estate).round() : 0;
  heir.trust = max(0, heir.trust + move);
  heir.marks.add('estate_auction');
  final list = sold.length <= 3
      ? sold.join(', ')
      : '${sold.take(3).join(', ')} and ${sold.length - 3} more';
  final verdict = move == 0
      ? ''
      : move > 0
      ? ' The bidding went well, adding ${_money(move)} to your share.'
      : ' The hammer fell below the valuations, costing your share ${_money(-move)}.';
  final what = homes.length == 1
      ? 'home was'
      : '${homes.length} properties were';
  return "You were too young to own property, so ${old.firstName}'s $what sold at auction: $list.$verdict The money is held in trust until you turn 18.";
}

String _money(int v) =>
    '\$${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

/// Hands the family home to a grown-up heir instead of that much cash,
/// when the heir's share covers what the home is worth after its
/// mortgage. Returns the feed line, or null when the home is sold.
String? passFamilyHome(Life old, Life heir, int age) {
  final home = homeOf(old);
  if (home == null || age < 18 || old.will == 'charity') return null;
  final equity = max(0, home.value - (old.debts['Mortgage'] ?? 0));
  if (heir.money < equity) return null;
  heir.money -= equity;
  heir.assets.add(
    Asset(
      id: 'family_home',
      kind: 'house',
      name: home.name,
      value: home.value,
      yearlyCost: home.yearlyCost,
      since: age,
      condition: home.condition,
      info: {...home.info, 'inherited': old.firstName}
        ..removeWhere((k, _) => k == 'let' || k == 'tenant' || k == 'warmed'),
    ),
  );
  heir.flags['owns_house'] = Memory(age, 'inheriting the family home');
  return 'You inherited the family ${home.name.toLowerCase()} in ${home.info['area'] ?? old.city}, where ${old.firstName} lived. It came out of your share of the estate.';
}

/// Why an ancestor stands out in the family tree, or null: the upper
/// echelon, or a Rare or Legendary Life Title. Records from before rarity
/// was stored look the title up by name.
String? notableAncestor(Map<String, dynamic> g) {
  if (g['echelon'] == true) return 'Upper echelon';
  final rarity =
      g['rarity'] as String? ??
      lifeTitles.where((t) => t.name == g['title']).firstOrNull?.rarity;
  if (rarity == 'Legendary' || rarity == 'Rare') return '$rarity title';
  return null;
}
