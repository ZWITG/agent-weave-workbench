import 'dart:math';

import 'models.dart';
import 'storylet.dart';

/// Big moments that leave a mark and ask for your input: losing someone
/// (the funeral and the will), a honeymoon, being fired, your child's
/// wedding, a grandchild, a parent remarrying. And the aftermath: how the
/// biggest moments keep shaping the next few years (grief, heartbreak,
/// newlywed glow, sleepless new-parent years, the months after a firing).

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '\$$s';
}

String _first(Npc n) => n.name.split(' ').first;

// ---------------- Aftermath ----------------

typedef Aftermath = ({
  String label,
  int happiness,
  int stress,
  int health,
  bool heavy,
  List<String> lines,
});

const aftermaths = <String, Aftermath>{
  'grief': (
    label: 'Grieving',
    happiness: -4,
    stress: 4,
    health: -1,
    heavy: true,
    lines: [
      'You still reach for the phone to call {who}, then remember.',
      'A song in a shop brought {who} back so suddenly you had to leave.',
      'Grief is quieter this year, but it still comes in waves.',
    ],
  ),
  'heartbreak': (
    label: 'Heartbroken',
    happiness: -3,
    stress: 3,
    health: 0,
    heavy: true,
    lines: [
      'You saw {who} across a street and your heart did something stupid.',
      'Some nights the flat feels very big without {who}.',
    ],
  ),
  'newlywed': (
    label: 'Newlywed glow',
    happiness: 3,
    stress: -2,
    health: 0,
    heavy: false,
    lines: [
      'You still catch yourself smiling at the ring.',
      'Married life with {who}: arguments about towels, and a lot of laughing.',
    ],
  ),
  'new_parent': (
    label: 'New parent',
    happiness: 2,
    stress: 8,
    health: -1,
    heavy: false,
    lines: [
      'You have not slept a full night in months. {who} smiled at you this morning and it was worth it.',
      'Nappies, lullabies and cold coffee. Life revolves around {who} now.',
    ],
  ),
  'jobless': (
    label: 'Out of work',
    happiness: -3,
    stress: 5,
    health: 0,
    heavy: true,
    lines: [
      'Another week of applications and silence. Being out of work wears on you.',
      'People keep asking what you do now. You have started saying "consulting".',
    ],
  ),
};

/// Starts (or restarts) an aftermath for [years] years, about [who].
void addAftermath(Life l, String kind, int years, {String who = ''}) {
  l.marks.removeWhere((m) => m.startsWith('after:$kind:'));
  l.marks.add('after:$kind:${l.age + years}:$who');
}

/// The aftermaths you are living through: (kind, years left, who).
List<(String, int, String)> activeAftermaths(Life l) => [
  for (final m in l.marks.where((m) => m.startsWith('after:')))
    () {
      final p = m.split(':');
      return (
        p[1],
        (int.tryParse(p[2]) ?? l.age) - l.age,
        p.sublist(3).join(':'),
      );
    }(),
];

/// Each birthday: the aftermaths shape the year, then fade.
List<String> aftermathYear(Life l, Random rng) {
  final feed = <String>[];
  for (final (kind, left, who) in activeAftermaths(l)) {
    final a = aftermaths[kind];
    if (a == null ||
        left < 0 ||
        (kind == 'jobless' && l.job != null) ||
        (kind == 'newlywed' && !l.flags.containsKey('married'))) {
      l.marks.removeWhere((m) => m.startsWith('after:$kind:'));
      continue;
    }
    l.stats.add('happiness', a.happiness);
    if (a.health != 0) l.stats.add('health', a.health);
    l.stress = l.stress + a.stress;
    final line = a.lines[rng.nextInt(a.lines.length)].replaceAll(
      '{who}',
      who.isEmpty ? 'them' : who,
    );
    feed.add(line);
    if (left == 0) l.marks.removeWhere((m) => m.startsWith('after:$kind:'));
  }
  return feed;
}

/// Therapy, rest and support shorten the heavy aftermaths by a year.
String? easeAftermath(Life l) {
  for (final (kind, left, who) in activeAftermaths(l)) {
    final a = aftermaths[kind];
    if (a == null || !a.heavy) continue;
    l.marks.removeWhere((m) => m.startsWith('after:$kind:'));
    if (left > 1) l.marks.add('after:$kind:${l.age + left - 1}:$who');
    return '${a.label} feels a little lighter.';
  }
  return null;
}

// ---------------- Scenes ----------------

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'family',
  scene: true,
  choices: choices,
);

bool _isParentOrGrandparent(Npc n) => const {
  'Mother',
  'Father',
  'Grandmother',
  'Grandfather',
  'Stepmother',
  'Stepfather',
}.contains(n.role);

List<Npc> _family(Life l) =>
    l.npcs.where((n) => n.alive && n.circle == 'Family').toList();

/// Queues the funeral (and, for a parent or grandparent, the will) after
/// someone close dies.
void onCloseDeath(Life l, Npc n) {
  addAftermath(
    l,
    'grief',
    n.circle == 'Partner' || n.circle == 'Children' || n.bond >= 70 ? 3 : 2,
    who: _first(n),
  );
  // Children grieve, but the funeral and the will are for the adults.
  if (l.age < 16) return;
  l.sceneQueue.add('loss:${n.id}');
  if (_isParentOrGrandparent(n) && l.age >= 18) {
    l.sceneQueue.add('estate:${n.id}');
  }
}

/// After a wedding: a honeymoon, and a couple of happy years.
void onWedding(Life l, Npc spouse) {
  addAftermath(l, 'newlywed', 2, who: _first(spouse));
  l.sceneQueue.add('honeymoon');
}

void onBirth(Life l, String name) =>
    addAftermath(l, 'new_parent', 2, who: name);

void onBreakUp(Life l, Npc ex) =>
    addAftermath(l, 'heartbreak', 2, who: _first(ex));

/// Fired from a job: the months after, and what you do about it.
void onFired(Life l, int salary) {
  addAftermath(l, 'jobless', 3);
  l.marks.removeWhere((m) => m.startsWith('fired_pay:'));
  l.marks.add('fired_pay:$salary');
  l.sceneQueue.add('fired_now');
}

Storylet? lifeEventScene(String id, List<String> args, Life l) {
  final rng = Random(l.seed + l.age * 31 + id.hashCode);
  switch (id) {
    case 'loss':
      final n = l.npc(args.join(':'));
      if (n == null || n.alive) return null;
      final who = _first(n);
      final family = _family(l);
      final cost = 4000 + rng.nextInt(5) * 1000;
      Choice choice(
        String label,
        String text, {
        int needs = 0,
        int familyBond = 0,
        int karma = 0,
        int happiness = 0,
        bool easesGrief = false,
        String? risk,
        String Function(Life l, Random rng)? custom,
      }) => Choice(
        label: label,
        outcome: '',
        risk: risk,
        needsMoney: needs,
        run: (l, rng) {
          l.money -= needs;
          for (final f in family) {
            f.addFacets(affection: familyBond);
          }
          if (karma != 0) l.stats.add('karma', karma);
          if (happiness != 0) l.stats.add('happiness', happiness);
          if (easesGrief) easeAftermath(l);
          l.flags['funeral:${n.id}'] = Memory(l.age, 'saying goodbye to $who');
          return custom?.call(l, rng) ?? text;
        },
      );
      return _scene(
        'loss',
        'The funeral for $who is on Friday. ${family.isEmpty ? 'It falls to you to decide how to say goodbye.' : 'The family is looking to you.'}',
        [
          choice(
            'Give the eulogy',
            '',
            familyBond: 4,
            easesGrief: true,
            risk: 'Charisma helps',
            custom: (l, rng) {
              if (rng.nextInt(100) < 40 + l.stats['charisma'] ~/ 2) {
                l.stats.add('happiness', 3);
                return 'You told the story of $who that nobody else knew, and the whole room laughed and cried at once. People hugged you for an hour afterwards.';
              }
              return 'Your voice broke halfway through and you could not finish. Someone squeezed your shoulder. It said enough.';
            },
          ),
          choice(
            'Pay for a beautiful funeral (${_m(cost)})',
            'Flowers, a choir and a long table of food afterwards. $who would have loved the fuss.',
            needs: cost,
            familyBond: 6,
            karma: 2,
          ),
          choice(
            'Keep it small and quiet',
            'A handful of people, a few words, a walk afterwards. It felt right.',
            easesGrief: true,
          ),
          choice(
            'Stay away',
            'You could not face it. The family noticed, and so will you, for a long time.',
            familyBond: -8,
            karma: -3,
            happiness: -3,
          ),
        ],
      );
    case 'estate':
      final n = l.npc(args.join(':'));
      if (n == null) return null;
      final who = _first(n);
      final estate =
          (20000 + rng.nextInt(30) * 10000) *
          (n.role.startsWith('Grand') ? 1 : 2);
      final siblings = l.npcs
          .where((s) => s.alive && (s.role == 'Brother' || s.role == 'Sister'))
          .toList();
      final share = estate ~/ (siblings.length + 1);
      return _scene(
        'estate',
        'The solicitor reads $who\'s will. The estate comes to ${_m(estate)}${siblings.isEmpty ? ', and it all comes to you.' : ', split between you and ${siblings.length == 1 ? _first(siblings.first) : 'your ${siblings.length} siblings'}: ${_m(share)} each.'}',
        [
          Choice(
            label: 'Accept your share (${_m(share)})',
            outcome: '',
            run: (l, rng) {
              l.money += share;
              return 'The money arrived a few months later. You spent the first of it on something $who would have approved of.';
            },
          ),
          Choice(
            label: 'Give half to a cause $who loved',
            outcome: '',
            run: (l, rng) {
              l.money += share - share ~/ 2;
              l.stats.add('karma', 5);
              l.stats.add('happiness', 3);
              return 'You gave ${_m(share ~/ 2)} in $who\'s name. A small plaque went up, and you visit it more than you expected.';
            },
          ),
          if (siblings.isNotEmpty) ...[
            Choice(
              label: 'Give your share to your siblings',
              outcome: '',
              run: (l, rng) {
                for (final s in siblings) {
                  s.addFacets(affection: 15, trust: 10);
                }
                l.stats.add('karma', 6);
                return 'You signed it over. ${_first(siblings.first)} cried on the phone. "$who would be so proud of you."';
              },
            ),
            Choice(
              label: 'Contest the will for more',
              outcome: '',
              risk: 'Lawyers, and your siblings may never forgive you',
              run: (l, rng) {
                for (final s in siblings) {
                  s.addFacets(affection: -20, trust: -20, resentment: 15);
                }
                l.money -= 8000;
                if (rng.nextInt(100) < 40) {
                  l.money += estate ~/ 2 + share ~/ 2;
                  return 'The judge gave you more than your share. Christmas will be very quiet from now on.';
                }
                l.money += share;
                return 'The judge upheld the will. You got your share, minus ${_m(8000)} in legal fees, and lost your siblings\' trust.';
              },
            ),
          ],
        ],
      );
    case 'honeymoon':
      final p = l.npcs
          .where((n) => n.alive && n.circle == 'Partner')
          .firstOrNull;
      if (p == null) return null;
      Choice trip(String label, int cost, int joy, String text) => Choice(
        label: cost > 0 ? '$label (${_m(cost)})' : label,
        outcome: '',
        needsMoney: cost,
        run: (l, rng) {
          l.money -= cost;
          l.stats.add('happiness', joy);
          p.addFacets(affection: joy, familiarity: 3);
          l.flags['honeymoon'] = Memory(l.age, 'your honeymoon');
          return text;
        },
      );
      return _scene('honeymoon', 'Married! Now: the honeymoon. Where to?', [
        trip(
          'Two weeks on a tropical beach',
          6000,
          8,
          'White sand, too much sun cream and a hammock built for two. You came home tanned and a little smug.',
        ),
        trip(
          'A city break full of museums and food',
          3000,
          6,
          'You walked twenty thousand steps a day and ate everything. ${_first(p)} still talks about the pastries.',
        ),
        trip(
          'A road trip with no plan',
          1500,
          5,
          'A broken-down car, a lake at sunset and a diner you will never find again. The best kind of trip.',
        ),
        trip(
          'Stay home and save the money',
          0,
          1,
          'A takeaway, a film and a promise to go somewhere "next year".',
        ),
      ]);
    case 'fired_now':
      final pay = l.marks
          .where((m) => m.startsWith('fired_pay:'))
          .map((m) => int.tryParse(m.substring(10)) ?? 0)
          .firstOrNull;
      l.marks.removeWhere((m) => m.startsWith('fired_pay:'));
      if (pay == null) return null;
      return _scene(
        'fired_now',
        'You were walked to the door with a cardboard box. The badge stopped working before you reached the car park. What now?',
        [
          Choice(
            label: 'Claim unfair dismissal',
            outcome: '',
            risk: 'Might win a payout, takes months',
            run: (l, rng) {
              l.stress = l.stress + 8;
              if (rng.nextInt(100) < 40 + l.stats['smarts'] ~/ 5) {
                final award = pay ~/ 2;
                l.money += award;
                return 'Six months of letters later, the tribunal ruled in your favour: ${_m(award)} in compensation.';
              }
              return 'The tribunal sided with your employer. At least you said your piece.';
            },
          ),
          Choice(
            label: 'Take a few months to breathe',
            outcome: '',
            run: (l, rng) {
              l.stress = l.stress - 15;
              l.stats.add('happiness', 4);
              return 'You slept in, walked a lot and remembered what you like doing. You will go back to job hunting rested.';
            },
          ),
          Choice(
            label: 'Start applying tonight',
            outcome: '',
            run: (l, rng) {
              l.stats.add('discipline', 2);
              l.marks.removeWhere((m) => m.startsWith('after:jobless:'));
              addAftermath(l, 'jobless', 1);
              return 'Twelve applications before midnight. Being busy helps, and the next job will come sooner.';
            },
          ),
        ],
      );
    case 'child_wedding':
      final c = l.npc(args.join(':'));
      if (c == null || !c.alive) return null;
      final who = _first(c);
      return _scene(
        'child_wedding',
        '$who is getting married! The invitations are out and $who asks, a bit shyly, how involved you want to be.',
        [
          Choice(
            label: 'Pay for the wedding (${_m(15000)})',
            outcome: '',
            needsMoney: 15000,
            run: (l, rng) {
              l.money -= 15000;
              c.addFacets(affection: 15, trust: 8);
              l.stats.add('happiness', 6);
              return 'A marquee, a band and a cake taller than $who. They thanked you in the speech and you pretended not to cry.';
            },
          ),
          Choice(
            label: 'Give a speech',
            outcome: '',
            risk: 'Charisma helps',
            run: (l, rng) {
              if (rng.nextInt(100) < 40 + l.stats['charisma'] ~/ 2) {
                c.addFacets(affection: 10);
                return 'Your speech had the whole room laughing, then silent, then cheering. $who hugged you for a long time.';
              }
              c.addFacets(affection: 2);
              return 'You told one embarrassing story too many. $who laughed, eventually.';
            },
          ),
          Choice(
            label: 'Just enjoy the day',
            outcome:
                'You danced badly, ate well and watched $who glow. A perfect day.',
            run: (l, rng) {
              c.addFacets(affection: 4);
              l.stats.add('happiness', 4);
              return null;
            },
          ),
          Choice(
            label: 'You do not approve of the match',
            outcome: '',
            risk: 'They may not forgive this',
            run: (l, rng) {
              c.addFacets(affection: -20, trust: -15, resentment: 15);
              return 'You said what you thought. $who married anyway, and you were not at the top table.';
            },
          ),
        ],
      );
    case 'grandchild':
      final g = l.npc(args.join(':'));
      if (g == null || !g.alive) return null;
      final parent = l.npc('${g.info['parent'] ?? ''}');
      final who = _first(g);
      return _scene(
        'grandchild',
        'You are holding $who for the first time: your grandchild, an hour old and already gripping your finger. ${parent == null ? '' : '${_first(parent)} looks exhausted and very proud.'}',
        [
          Choice(
            label: 'Offer to babysit every week',
            outcome: '',
            run: (l, rng) {
              g.addFacets(affection: 15, familiarity: 15);
              parent?.addFacets(affection: 10);
              l.stress = l.stress + 4;
              l.stats.add('happiness', 6);
              return 'Tuesdays are grandparent day now. $who will grow up knowing you very well.';
            },
          ),
          Choice(
            label: 'Start a college fund (${_m(10000)})',
            outcome: '',
            needsMoney: 10000,
            run: (l, rng) {
              l.money -= 10000;
              g.info['fund'] = ((g.info['fund'] as int?) ?? 0) + 10000;
              parent?.addFacets(affection: 8, trust: 6);
              l.stats.add('karma', 3);
              return 'You opened an account in $who\'s name. It will be worth a lot more by the time they need it.';
            },
          ),
          Choice(
            label: 'Bring a mountain of gifts',
            outcome: '',
            needsMoney: 500,
            run: (l, rng) {
              l.money -= 500;
              g.addFacets(affection: 6);
              parent?.addFacets(affection: 3);
              return 'Three teddy bears, a tiny jumper and a drum kit. ${parent == null ? 'Everyone' : _first(parent)} confiscated the drum kit.';
            },
          ),
          Choice(
            label: 'Keep some distance',
            outcome: '',
            run: (l, rng) {
              parent?.addFacets(affection: -6);
              return 'You visited once and sent a card. You have your own life, you told yourself.';
            },
          ),
        ],
      );
    case 'step_parent':
      final s = l.npc(args.join(':'));
      if (s == null || !s.alive) return null;
      final parent = l.npc(s.role == 'Stepmother' ? 'father' : 'mother');
      final who = _first(s);
      return _scene(
        'step_parent',
        '${parent == null ? 'Your parent' : _first(parent)} has remarried. $who is your ${s.role.toLowerCase()} now, and is trying very hard at the first family dinner.',
        [
          Choice(
            label: 'Welcome them warmly',
            outcome: '',
            run: (l, rng) {
              s.addFacets(affection: 15, trust: 10);
              parent?.addFacets(affection: 6);
              return 'You asked $who about their life and actually listened. ${parent == null ? '' : _first(parent)} mouthed "thank you" across the table.';
            },
          ),
          Choice(
            label: 'Stay polite, nothing more',
            outcome:
                'Small talk about the weather and the traffic. It is a start.',
          ),
          Choice(
            label: 'Make it clear they are not your parent',
            outcome: '',
            run: (l, rng) {
              s.addFacets(affection: -15, resentment: 10);
              parent?.addFacets(affection: -10);
              l.stats.add('karma', -2);
              return 'Dinner ended early. $who drove home in silence.';
            },
          ),
        ],
      );
  }
  return null;
}
