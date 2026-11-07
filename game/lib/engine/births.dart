import 'dart:math';

import 'love.dart';
import 'models.dart';
import 'storylet.dart';

/// Babies that arrive without a plan: a surprise with your partner, a
/// secret lover, a fling from a night out, a recent ex, or later in life.
/// Only adults (18+) can become parents this way. Also the birth plan, and placing a baby for adoption
/// (with a chance they find you when they are grown).
///
/// Marks used while expecting:
/// - `baby_other:<name>`: the other parent, when it is not your partner;
/// - `baby_secret`: a child of an affair, kept quiet;
/// - `baby_place`: the baby will be placed for adoption at birth;
/// - `birth_plan:<home|hospital|private>`.

bool _expecting(Life l) => l.flags.containsKey('expecting');

/// Can this pairing carry a baby (one of you can carry, one can father)?
bool _canConceive(Life l, Npc? other) {
  final theirGender = other?.gender;
  if (theirGender == null) return true;
  return theirGender != l.gender;
}

/// Whose age matters for the pregnancy.
int _carrierAge(Life l, Npc? other) =>
    l.gender == 'female' || other == null ? l.age : other.ageIn(l.year);

bool _fertileAge(int age) => age >= 18 && age <= 48;

String _first(String name) => name.split(' ').first;

void _expect(Life l, String memory) {
  l.flags['expecting'] = Memory(l.age, memory);
  l.marks.removeWhere((m) => m.startsWith('birth_plan:'));
  maybeBirthPlan(l);
}

/// Yearly: the chance of a baby nobody planned. Runs before deliberate
/// "trying" and only when nobody is expecting already.
void surpriseBabyYear(Life l, Random rng) {
  if (_expecting(l) || l.prison != null || l.age < 18) return;
  final p = partnerOf(l);
  final lover = loverOf(l);
  final roll = rng.nextInt(1000);

  // A partner, not trying: contraception mostly works.
  if (p != null &&
      !l.tryingForBaby &&
      _canConceive(l, p) &&
      _fertileAge(_carrierAge(l, p))) {
    final age = _carrierAge(l, p);
    final chance = age >= 40
        ? 12
        : l.flags.containsKey('no_kids')
        ? 8
        : 25;
    if (roll < chance) {
      l.sceneQueue.add('baby_surprise');
      return;
    }
  }
  // A secret lover.
  if (lover != null &&
      _canConceive(l, lover) &&
      _fertileAge(_carrierAge(l, lover)) &&
      roll >= 900 &&
      roll < 940) {
    l.sceneQueue.add('baby_lover');
    return;
  }
  // A fling after a night out while single.
  if (p == null &&
      l.age >= 18 &&
      l.age <= 45 &&
      l.marks.contains('went_out:${l.age - 1}') &&
      roll >= 950 &&
      roll < 975) {
    l.sceneQueue.add('baby_fling');
    return;
  }
  // An ex from the last year or two.
  final ex = l.npcs
      .where(
        (n) =>
            n.alive &&
            n.circle == 'Exes' &&
            n.lastContactAge >= l.age - 1 &&
            _canConceive(l, n) &&
            _fertileAge(_carrierAge(l, n)),
      )
      .firstOrNull;
  if (ex != null && roll >= 980 && roll < 992) {
    l.sceneQueue.add('baby_ex:${ex.id}');
  }
}

/// The year you are expecting: choose where the baby will be born.
void maybeBirthPlan(Life l) {
  if (_expecting(l) &&
      l.prison == null &&
      !l.marks.any((m) => m.startsWith('birth_plan:')) &&
      !l.sceneQueue.contains('birth_plan')) {
    l.sceneQueue.add('birth_plan');
  }
}

/// A baby placed for adoption may look for you once grown.
void reunionYear(Life l, Random rng) {
  for (final m in l.marks.where((m) => m.startsWith('placed:')).toList()) {
    final parts = m.split(':');
    final born = int.tryParse(parts.last) ?? l.year;
    if (l.year - born >= 18 && rng.nextInt(100) < 20) {
      l.marks.remove(m);
      l.sceneQueue.add('adopted_reunion:${parts[1]}:$born');
      return;
    }
  }
}

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'family',
  scene: true,
  choices: choices,
);

/// "Keep" / "place for adoption" choices shared by the surprise scenes.
List<Choice> _keepOrPlace(
  String memory, {
  String? otherParent,
  String keepText =
      'You looked at each other and said yes. Ready or not, a baby is coming.',
  void Function(Life l)? onKeep,
}) => [
  Choice(
    label: 'Keep the baby',
    outcome: '',
    run: (l, rng) {
      _expect(l, memory);
      if (otherParent != null) l.marks.add('baby_other:$otherParent');
      onKeep?.call(l);
      l.stats.add('happiness', 3);
      l.stress = l.stress + 10;
      return keepText;
    },
  ),
  Choice(
    label: 'Plan to place the baby for adoption',
    outcome: '',
    risk: 'A family is chosen before the birth',
    run: (l, rng) {
      _expect(l, memory);
      if (otherParent != null) l.marks.add('baby_other:$otherParent');
      l.marks.add('baby_place');
      l.stats.add('happiness', -3);
      return 'You met a couple who had waited years for a child. It was the hardest and kindest decision you have made.';
    },
  ),
];

Storylet? birthScene(String id, List<String> args, Life l) {
  final p = partnerOf(l);
  switch (id) {
    case 'baby_surprise':
      if (p == null || _expecting(l)) return null;
      final carrier = l.gender == 'female' ? 'You are' : '${_first(p.name)} is';
      return _scene(
        id,
        'A late period, a test bought at midnight, and two pink lines. $carrier pregnant. You had not planned this at all.',
        _keepOrPlace(
          'a surprise pregnancy',
          keepText: 'You held hands at the kitchen table and laughed, a little hysterically. You are going to be parents.',
          onKeep: (l) => partnerOf(l)?.addFacets(affection: 6),
        ),
      );
    case 'baby_lover':
      final lover = loverOf(l);
      if (lover == null || _expecting(l)) return null;
      final who = _first(lover.name);
      final carrier = l.gender == 'female' ? 'you are' : '$who is';
      return _scene(
        id,
        'A message from $who, at 2am: "We need to talk." The affair has a consequence: $carrier pregnant.${p == null ? '' : ' ${_first(p.name)} has no idea.'}',
        [
          if (p != null)
            Choice(
              label: 'Tell ${_first(p.name)} the truth',
              outcome: '',
              risk: 'They may leave',
              run: (l, rng) {
                _expect(l, 'a baby with $who');
                l.marks.add('baby_other:${lover.name}');
                final partner = partnerOf(l);
                if (partner != null && rng.nextInt(100) < 60) {
                  endRelationship(l, partner, 'your affair and the baby');
                  return '${_first(partner.name)} packed a bag that night. You will raise this baby without them.';
                }
                partner?.addFacets(affection: -25, trust: -30);
                return '${_first(partner?.name ?? 'They')} stayed, somehow. Nothing will be the same, but the baby will have a home.';
              },
            ),
          Choice(
            label: 'Keep it secret',
            outcome: '',
            risk: 'Secrets like this come out',
            run: (l, rng) {
              _expect(l, 'a secret baby with $who');
              l.marks.addAll(['baby_other:${lover.name}', 'baby_secret']);
              lover.info['risk'] = ((lover.info['risk'] as int?) ?? 0) + 30;
              return 'You agreed to tell no one. $who looked at you for a long time and said, "For now."';
            },
          ),
          ..._keepOrPlace('a baby with $who', otherParent: lover.name).skip(1),
        ],
      );
    case 'baby_fling':
      if (p != null || _expecting(l)) return null;
      final fling = candidate(l, Random(l.seed + l.age * 7));
      final who = _first(fling.name);
      final carrier = l.gender == 'female' ? 'You are' : '$who is';
      return _scene(
        id,
        '${l.gender == 'female' ? 'Weeks after' : 'Months after'} a night out you barely remember, a surprise: $carrier pregnant. You met $who once, at a bar, and never got their number${l.gender == 'female' ? '' : ' until now'}.',
        [
          Choice(
            label: 'Raise the baby together',
            outcome: '',
            risk: 'Start dating $who',
            run: (l, rng) {
              l.npcs.add(fling);
              l.flags['partner'] = Memory(l.age, 'meeting ${fling.name}');
              _expect(l, 'a baby with $who');
              return 'You went for coffee, then dinner, then a scan. Two strangers, about to become a family.';
            },
          ),
          ..._keepOrPlace(
            'a baby with $who',
            otherParent: fling.name,
            keepText: 'You decided to do it on your own terms: one parent, one baby, and a lot of help from friends.',
          ),
        ],
      );
    case 'baby_ex':
      final ex = l.npc(args.isEmpty ? '' : args.first);
      if (ex == null || _expecting(l)) return null;
      final who = _first(ex.name);
      final carrier = l.gender == 'female' ? 'you are' : '$who is';
      return _scene(
        id,
        'Months after the break-up, a call from $who: $carrier pregnant, and the baby is yours together.',
        [
          Choice(
            label: 'Get back together',
            outcome: '',
            risk: 'Depends how it ended',
            run: (l, rng) {
              _expect(l, 'a baby with $who');
              if (partnerOf(l) == null &&
                  rng.nextInt(100) < 30 + ex.bond ~/ 2) {
                final back = recircle(
                  l,
                  ex,
                  circle: 'Partner',
                  role: 'Partner',
                );
                setStage(l, back, 'dating');
                return 'You gave it another go, for the baby and maybe for yourselves.';
              }
              l.marks.add('baby_other:${ex.name}');
              return '$who said no. You will raise the baby between two homes.';
            },
          ),
          ..._keepOrPlace(
            'a baby with $who',
            otherParent: ex.name,
            keepText: 'You agreed to co-parent: two homes, one shared calendar and a lot of polite texts.',
          ),
        ],
      );
    case 'birth_plan':
      if (!_expecting(l)) return null;
      Choice plan(String label, String key, int cost, String text) => Choice(
        label: label,
        outcome: '',
        needsMoney: cost,
        run: (l, rng) {
          l.money -= cost;
          l.marks.add('birth_plan:$key');
          return text;
        },
      );
      return _scene(
        id,
        'The bump is showing and the midwife asks the big question: where do you want the baby to be born?',
        [
          plan(
            'At the hospital',
            'hospital',
            0,
            'You packed a bag and left it by the door. It has been there for weeks.',
          ),
          plan(
            'At home, with a midwife',
            'home',
            500,
            'A birthing pool arrived and now lives in the living room.',
          ),
          plan(
            'A private clinic (\$20,000)',
            'private',
            20000,
            'A suite with a view, a chef and a nurse for every question.',
          ),
        ],
      );
    case 'adopted_reunion':
      if (args.length < 2) return null;
      final name = args.first;
      final born = int.tryParse(args[1]) ?? l.year - 18;
      return _scene(
        id,
        'A letter arrives in careful handwriting: "My name is $name. I was born ${l.year - born} years ago and adopted at birth. I think you might be my parent."',
        [
          Choice(
            label: 'Meet them',
            outcome: '',
            run: (l, rng) {
              final g = rng.nextBool() ? 'female' : 'male';
              final child =
                  Npc(
                      id: freshNpcId(l, 'child'),
                      role: g == 'female' ? 'Daughter' : 'Son',
                      name: name,
                      birthYear: born,
                      circle: 'Children',
                      bond: 45,
                    )
                    ..lastContactAge = l.age
                    ..info.addAll({
                      'gender': g,
                      'adopted': false,
                      'placed': true,
                    });
              l.npcs.add(child);
              l.stats.add('happiness', 8);
              return 'You met in a café and talked for four hours. They have your laugh. $name is part of your life now.';
            },
          ),
          Choice(
            label: 'Write back, but do not meet',
            outcome: 'You wrote the longest letter of your life. They wrote back once, and said thank you.',
          ),
        ],
      );
  }
  return null;
}

/// How the birth went, from the plan and a little luck.
String birthSituation(Life l, Random rng) {
  if (l.prison != null) {
    return 'The baby was born in the prison hospital ward, with a guard outside the door. They will live with family until you are out.';
  }
  final plan = l.marks
      .where((m) => m.startsWith('birth_plan:'))
      .map((m) => m.substring(11))
      .firstOrNull;
  final roll = rng.nextInt(100);
  if (roll < 4) {
    return 'The baby did not wait: they arrived in the back of a taxi, with the driver shouting encouragement.';
  }
  if (roll < 9) {
    return 'The baby came seven weeks early and spent a month in an incubator, tiny and fierce.';
  }
  if (l.marks.any((m) => m.startsWith('lived:')) && roll < 14) {
    return 'The baby arrived in ${l.city}, far from where you grew up. A nurse taught you the local lullaby.';
  }
  return switch (plan) {
    'home' => 'The baby was born at home in the birthing pool, with the cat watching from the stairs.',
    'private' => 'The baby was born in a private suite with soft lighting and a champagne menu nobody touched.',
    _ => 'After a long night at the hospital, the baby arrived: tiny, furious and perfect.',
  };
}
