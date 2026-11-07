import 'dart:math';

import 'actions.dart';
import 'models.dart';
import 'storylet.dart';
import 'world_data.dart';

/// Identity and inclusion (plan Social §8): gender identity, pronouns and
/// orientation from creation, changeable in life; coming-out moments whose
/// reactions change relationships, never stats; legal name change; and
/// families of every shape at birth.

const genderIdentities = [
  'Woman',
  'Man',
  'Non-binary',
  'Genderqueer',
  'Agender',
];

const orientations = [
  'Straight',
  'Gay',
  'Lesbian',
  'Bisexual',
  'Pansexual',
  'Asexual',
  'Questioning',
];

/// Pronoun sets: subject, object, possessive.
const pronounSets = <String, (String, String, String)>{
  'she/her': ('she', 'her', 'her'),
  'he/him': ('he', 'him', 'his'),
  'they/them': ('they', 'them', 'their'),
};

String identityOf(Life l) => l.genderIdentity.isNotEmpty
    ? l.genderIdentity
    : (l.gender == 'female' ? 'Woman' : 'Man');

String pronounLabel(Life l) => l.pronouns.isNotEmpty
    ? l.pronouns
    : (l.gender == 'female' ? 'she/her' : 'he/him');

/// The player's pronouns for text tokens {they} {them} {their}. Custom
/// sets are written "ze/zir/zir".
(String, String, String) pronounsOf(Life l) {
  final set = pronounSets[pronounLabel(l)];
  if (set != null) return set;
  final p = l.pronouns.split('/').map((s) => s.trim()).toList();
  return (p[0], p.length > 1 ? p[1] : p[0], p.length > 2 ? p[2] : p.last);
}

String orientationOf(Life l) => l.orientation.isNotEmpty
    ? l.orientation
    : switch (l.attractedTo) {
        'everyone' => 'Bisexual',
        'men' => l.gender == 'male' ? 'Gay' : 'Straight',
        'women' => l.gender == 'female' ? 'Lesbian' : 'Straight',
        _ => 'Straight',
      };

/// Who the dating filter shows for an orientation (players can still
/// change "interested in" on its own).
String interestFor(Life l, String orientation) => switch (orientation) {
  'Gay' => l.gender == 'male' ? 'men' : 'women',
  'Lesbian' => 'women',
  'Straight' => l.gender == 'female' ? 'men' : 'women',
  _ => 'everyone',
};

/// The word a child uses for this parent.
String parentWord(Life l) => switch (identityOf(l)) {
  'Woman' => 'Mother',
  'Man' => 'Father',
  _ => 'Parent',
};

bool _cis(Life l) => identityOf(l) == (l.gender == 'female' ? 'Woman' : 'Man');

/// Sets identity fields; from 10, telling your family becomes a scene.
String setIdentity(
  Life l, {
  String? identity,
  String? pronouns,
  String? orientation,
  String? interest,
}) {
  final before = (identityOf(l), orientationOf(l));
  if (identity != null) l.genderIdentity = identity;
  if (pronouns != null) l.pronouns = pronouns;
  if (orientation != null) {
    l.orientation = orientation;
    l.attractedTo = interestFor(l, orientation);
  }
  if (interest != null) l.attractedTo = interest;
  final changed =
      before.$1 != identityOf(l) ||
      (before.$2 != orientationOf(l) && orientationOf(l) != 'Straight');
  if (changed && l.age >= 10 && !l.sceneQueue.contains('coming_out')) {
    l.sceneQueue.add('coming_out');
  }
  return 'Updated. ${identityOf(l)}, ${pronounLabel(l)}, ${orientationOf(l).toLowerCase()}.';
}

/// Each family member's outlook, seeded per person and nudged by the
/// country's climate (plan: supportive, mixed or traditional).
String outlookOf(Life l, Npc n) {
  final climate = countryProfile(l.country).climate;
  final roll =
      Random(n.name.hashCode ^ l.seed).nextInt(100) +
      (climate == 'supportive'
          ? 15
          : climate == 'hostile'
          ? -20
          : 0);
  return roll >= 45
      ? 'supportive'
      : roll >= 15
      ? 'mixed'
      : 'traditional';
}

Storylet? identityScene(String id, List<String> args, Life l) {
  switch (id) {
    case 'coming_out':
      final family = l.npcs
          .where(
            (n) => n.alive && (n.circle == 'Family' || n.circle == 'Partner'),
          )
          .toList();
      if (family.isEmpty) return null;
      final what = !_cis(l)
          ? '${identityOf(l).toLowerCase()} and use ${pronounLabel(l)}'
          : orientationOf(l).toLowerCase();
      String tell(Life l, List<Npc> who) {
        final lines = <String>[];
        for (final n in who) {
          final first = n.name.split(' ').first;
          switch (outlookOf(l, n)) {
            case 'supportive':
              n.addFacets(affection: 6, trust: 6);
              n.remember(
                NpcMemory(
                  age: l.age,
                  text: 'you trusting them with who you are',
                  valence: 2,
                  intensity: 3,
                  tags: ['identity'],
                ),
              );
              lines.add(
                '$first hugged you and said, "Thank you for telling me."',
              );
            case 'mixed':
              n.addFacets(affection: -2);
              lines.add(
                '$first went quiet, then said they needed a little time.',
              );
              l.marks.add('reconcile:${n.id}:${l.age + 3}');
            default:
              n.addFacets(affection: -8, trust: -4);
              n.remember(
                NpcMemory(
                  age: l.age,
                  text: 'not understanding you when you came out',
                  valence: -2,
                  intensity: 3,
                  tags: ['identity'],
                ),
              );
              lines.add(
                '$first said things that hurt. That is on them, not you.',
              );
              l.marks.add('reconcile:${n.id}:${l.age + 5}');
          }
        }
        l.flags['came_out'] = Memory(l.age, 'telling your family who you are');
        final supported = who.where((n) => outlookOf(l, n) == 'supportive');
        l.stats.add('happiness', supported.isEmpty ? -2 : 4);
        return lines.join(' ');
      }

      final closest =
          (family.toList()..sort((a, b) => b.bond.compareTo(a.bond))).first;
      return Storylet(
        id: 'scene:coming_out',
        text:
            'You have known for a while that you are $what. Saying it out loud to your family feels huge. How do you want to tell them?',
        category: 'identity',
        scene: true,
        choices: [
          Choice(
            label: 'Tell everyone at dinner',
            outcome: '',
            risk: 'Reactions vary; your stats never change for who you are',
            run: (l, rng) => tell(l, family),
          ),
          Choice(
            label: 'Tell ${closest.name.split(' ').first} first',
            outcome: '',
            run: (l, rng) => tell(l, [closest]),
          ),
          Choice(
            label: 'Not yet',
            outcome:
                'You decided to wait until it feels right. That is allowed.',
          ),
        ],
      );
    case 'name_change':
      final c = countryNamed(l.country);
      final rng = Random(l.seed + l.age * 5);
      final pool = [...c.female, ...c.male]..shuffle(rng);
      final options = pool.where((n) => n != l.firstName).take(3).toList();
      final partner = l.who('@partner');
      final theirSurname = partner?.name.split(' ').last;
      return Storylet(
        id: 'scene:name_change',
        text: 'The legal name change form is surprisingly short. A name is a small thing on paper and a big thing everywhere else.',
        category: 'identity',
        scene: true,
        choices: [
          for (final n in options)
            Choice(
              label: 'First name: $n',
              outcome: '',
              run: (l, rng) {
                final old = l.firstName;
                l.firstName = n;
                l.flags['name_change'] = Memory(l.age, 'becoming $n');
                return 'From today you are $n ${l.surname}. $old is a chapter, not the whole book.';
              },
            ),
          if (theirSurname != null && theirSurname != l.surname)
            Choice(
              label:
                  'Take ${partner!.name.split(' ').first}\'s surname: $theirSurname',
              outcome: '',
              run: (l, rng) {
                l.surname = theirSurname;
                return 'You are ${l.firstName} $theirSurname now. ${partner.name.split(' ').first} pretended not to be thrilled.';
              },
            ),
          Choice(
            label: 'Keep my name',
            outcome: 'You decided your name suits you.',
          ),
        ],
      );
  }
  return null;
}

/// Family members who needed time can come round (plan: reconciliation).
List<String> identityYear(Life l) {
  final feed = <String>[];
  for (final m in l.marks.where((m) => m.startsWith('reconcile:')).toList()) {
    final parts = m.split(':');
    if (int.tryParse(parts[2]) != l.age) continue;
    l.marks.remove(m);
    final n = l.npc(parts[1]);
    if (n == null || !n.alive) continue;
    n.addFacets(affection: 10, trust: 8, resentment: -10);
    feed.add(
      '${n.name.split(' ').first} asked to talk. "I was wrong, and I am sorry. I love you exactly as you are."',
    );
  }
  return feed;
}

final identityActions = <GameAction>[
  GameAction(
    id: 'name_change',
    label: 'Change your legal name',
    category: 'Identity',
    keywords: ['name', 'rename', 'legal name', 'surname', 'identity'],
    minAge: 18,
    cost: 250,
    run: (l, rng) {
      l.money -= 250;
      l.sceneQueue.add('name_change');
      return ActionResult('You pick up the form at the registry office.', [
        'Money −\$250',
      ]);
    },
  ),
];
