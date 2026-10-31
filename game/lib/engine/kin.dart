import 'dart:math';

import 'actions.dart';
import 'family.dart' show childrenOf;
import 'love.dart' show partnerOf;
import 'justice.dart' show hasSeriousRecord;
import 'models.dart';
import 'storylet.dart';

// More ways to make a family and watch it grow: fostering (with the
// choice to adopt when a placement ends), surrogacy that follows the
// country's rules, grandchildren who are people of their own, and
// seasonal events that follow the real calendar.

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
  category: 'family',
  scene: true,
  choices: choices,
);

const _girls = [
  'Ava',
  'Mia',
  'Lena',
  'Zoe',
  'Iris',
  'Nora',
  'Maya',
  'Ruby',
  'Ada',
  'Lila',
];
const _boys = [
  'Leo',
  'Noah',
  'Eli',
  'Kai',
  'Sam',
  'Omar',
  'Theo',
  'Ravi',
  'Hugo',
  'Finn',
];

String _first(Npc n) => n.name.split(' ').first;

// ---------------- Fostering ----------------

const fosterAllowance = 7000;

List<Npc> fostersOf(Life l) =>
    l.npcs.where((n) => n.alive && n.circle == 'Foster').toList();

const _backstories = [
  'Their mum is in hospital for a long time and there is nobody else.',
  'They have moved four times this year and keep their shoes on, just in case.',
  'Their dad is trying to get sober and wants them back when he is ready.',
  'They arrived with one bin bag of clothes and a very old teddy.',
  'They do not talk much yet, but they draw constantly.',
  'Their grandmother could not cope any more and cried when she said goodbye.',
];

String? fosterLock(Life l) {
  if (l.prison != null) return 'Not possible in prison';
  if (hasSeriousRecord(l)) return 'Your record rules you out';
  if (!l.has('house') && !l.has('rental')) {
    return 'Needs a home of your own';
  }
  if (fostersOf(l).length >= 2) return 'You are fostering two children';
  return null;
}

Storylet fosterOfferScene(Life l) {
  final r = Random(l.seed * 7 + l.age * 13 + 1);
  final girl = r.nextBool();
  final name = (girl ? _girls : _boys)[r.nextInt(10)];
  final age = 3 + r.nextInt(13);
  final story = _backstories[r.nextInt(_backstories.length)];
  final stay = 1 + r.nextInt(4);
  return _scene(
    'foster_offer',
    'The social worker calls. "We have $name, $age. $story We think it would be about $stay year${stay == 1 ? '' : 's'}." Carers get ${_m(fosterAllowance)} a year towards their costs.',
    [
      Choice(
        label: 'Welcome $name',
        outcome: '',
        run: (l, rng) {
          l.npcs.add(
            Npc(
                id: 'foster_${l.age}_$name',
                role: girl ? 'Foster daughter' : 'Foster son',
                name: '$name ${l.surname}',
                birthYear: l.year - age,
                circle: 'Foster',
                bond: 35,
              )
              ..lastContactAge = l.age
              ..info.addAll({
                'gender': girl ? 'female' : 'male',
                'placed': l.age,
                'stay': stay,
              }),
          );
          l.flags['foster_carer'] = Memory(l.age, 'becoming a foster carer');
          l.stats.add('karma', 4);
          return '$name stood in the doorway holding the teddy. You showed them their room. "Is this mine?" they asked. "For as long as you need it," you said.';
        },
      ),
      Choice(
        label: 'Not right now',
        outcome: 'You said you could not take a child this year. The social worker understood; there is always next time.',
      ),
    ],
  );
}

Storylet? fosterEndScene(List<String> args, Life l) {
  final n = l.npcs.where((n) => n.id == args.join(':')).firstOrNull;
  if (n == null || !n.alive || n.circle != 'Foster') return null;
  final home = (_hashOf(n.id) + l.age) % 2 == 0;
  final age = n.ageIn(l.year);
  return _scene(
    'foster_end',
    home
        ? '${_first(n)}\'s family is ready to have them home. The court agreed this morning. ${_first(n)} is $age now, and their bag is already half packed.'
        : 'The court has decided ${_first(n)} cannot go home. The social worker asks, gently, whether you would consider adopting them.',
    [
      if (!home)
        Choice(
          label: 'Adopt ${_first(n)}',
          outcome: '',
          run: (l, rng) {
            n.circle = 'Children';
            n.role = n.info['gender'] == 'female' ? 'Daughter' : 'Son';
            n.info.addAll({
              'adopted': true,
              'otherParent': partnerOf(l)?.name,
              'stats': {
                'smarts': 30 + rng.nextInt(60),
                'looks': 30 + rng.nextInt(60),
                'athleticism': 30 + rng.nextInt(60),
                'creativity': 30 + rng.nextInt(60),
              },
            });
            n.addFacets(affection: 15, trust: 15);
            l.flags['adopted_foster'] = Memory(l.age, 'adopting ${_first(n)}');
            l.stats.add('happiness', 8);
            return 'The judge banged the gavel and everyone clapped, including the judge. ${_first(n)} took your name and held your hand all the way to the car.';
          },
        ),
      Choice(
        label: home
            ? 'Throw a goodbye tea and promise to write'
            : 'Help find them a forever family',
        outcome: '',
        run: (l, rng) {
          n.circle = 'Friends';
          n.role =
              'Former foster ${n.info['gender'] == 'female' ? 'daughter' : 'son'}';
          n.remember(
            NpcMemory(
              age: l.age,
              text: 'the years they lived with you',
              valence: 2,
              intensity: 4,
            ),
          );
          l.stats.add('happiness', -2);
          return home
              ? 'There was cake, and a card that said "THANK YOU" in letters of every colour. The house is very quiet now.'
              : 'You met the new family twice and liked them. ${_first(n)} still sends you a drawing every birthday.';
        },
      ),
    ],
  );
}

int _hashOf(String s) => s.codeUnits.fold(5, (a, c) => (a * 31 + c) & 0xffff);

// ---------------- Surrogacy ----------------

/// How this game's countries treat surrogacy: paid, expenses only, or not
/// available (you can still arrange it abroad).
String surrogacyRule(String country) => switch (country) {
  'United States' || 'Mexico' => 'commercial',
  'United Kingdom' ||
  'Canada' ||
  'Australia' ||
  'Netherlands' ||
  'Brazil' ||
  'India' ||
  'Ireland' => 'altruistic',
  _ => 'unavailable',
};

const surrogacyCost = {
  'commercial': 90000,
  'altruistic': 30000,
  'abroad': 120000,
};

Storylet surrogacyScene(Life l) {
  final rule = surrogacyRule(l.country);
  Choice go(String how, int cost, int odds, String label) => Choice(
    label: label,
    outcome: '',
    needsMoney: cost,
    risk: 'About $odds% chance this year',
    run: (l, rng) {
      l.money -= cost;
      if (rng.nextInt(100) < odds) {
        l.flags['expecting'] = Memory(l.age, 'a surrogate carrying your baby');
        l.flags['surrogacy'] = Memory(l.age, 'a family through surrogacy');
        return how == 'abroad'
            ? 'Lawyers, flights and a clinic far from home. Then a video call: the pregnancy has taken. Your baby is due next year.'
            : 'You met the woman who will carry your baby. She is kind, funny and very sure. The pregnancy has taken: your baby is due next year.';
      }
      l.stats.add('happiness', -5);
      return 'The transfer did not take this time. The clinic says it often needs another try.';
    },
  );
  return _scene(
    'surrogacy',
    switch (rule) {
      'commercial' =>
        'In ${l.country} surrogates can be paid. An agency handles the matching, the medical side and the contracts.',
      'altruistic' =>
        'In ${l.country} a surrogate can only be paid her expenses, so matches come through support groups and take patience.',
      _ =>
        'Surrogacy is not available in ${l.country}. Some people arrange it abroad, with lawyers on both sides.',
    },
    [
      if (rule == 'commercial')
        go(
          'agency',
          surrogacyCost['commercial']!,
          70,
          'Use an agency (${_m(surrogacyCost['commercial']!)})',
        ),
      if (rule == 'altruistic')
        go(
          'altruistic',
          surrogacyCost['altruistic']!,
          55,
          'Find a surrogate (${_m(surrogacyCost['altruistic']!)} in expenses)',
        ),
      go(
        'abroad',
        surrogacyCost['abroad']!,
        70,
        'Arrange it abroad (${_m(surrogacyCost['abroad']!)})',
      ),
      Choice(
        label: 'Not now',
        outcome: 'You put the folder in a drawer, for now.',
      ),
    ],
  );
}

// ---------------- Grandchildren ----------------

List<Npc> grandchildrenOf(Life l) =>
    l.npcs.where((n) => n.circle == 'Grandchildren').toList();

/// Your adult children have children of their own, who grow up as people
/// you can see, spoil and babysit.
List<FeedEntry> grandchildrenYear(Life l, Random rng) {
  final out = <FeedEntry>[];
  final all = grandchildrenOf(l);
  if (all.length < 8) {
    for (final c in childrenOf(l).where((c) => c.alive)) {
      final age = c.ageIn(l.year);
      final kids = (c.info['kids'] as int?) ?? 0;
      if (age < 24 || age > 44 || kids >= 3) continue;
      final promised = l.flags.containsKey('grandparent') && all.isEmpty;
      if (!promised && rng.nextInt(100) >= 8) continue;
      final girl = rng.nextBool();
      final name = (girl ? _girls : _boys)[rng.nextInt(10)];
      final g = Npc(
        id: 'gc_${c.id}_$kids',
        role: girl ? 'Granddaughter' : 'Grandson',
        name: '$name ${l.surname}',
        birthYear: l.year,
        circle: 'Grandchildren',
        bond: 60,
      )..lastContactAge = l.age;
      g.info.addAll({'parent': c.id, 'gender': girl ? 'female' : 'male'});
      l.npcs.add(g);
      l.sceneQueue.add('grandchild:${g.id}');
      c.info['kids'] = kids + 1;
      l.flags['grandparent'] ??= Memory(l.age, 'becoming a grandparent');
      out.add(
        FeedEntry(
          l.age,
          '${_first(c)} had a baby ${girl ? 'girl' : 'boy'}: $name. ${all.isEmpty ? 'You are a grandparent!' : 'Another grandchild to spoil.'}',
          kind: 'milestone',
        ),
      );
      break;
    }
  }
  for (final g in all.where((g) => g.alive)) {
    final a = g.ageIn(l.year);
    final line = switch (a) {
      1 =>
        '${_first(g)} took their first steps, straight towards your biscuit tin.',
      5 => '${_first(g)} started school and told the class all about you.',
      13 =>
        '${_first(g)} is a teenager now and only calls when they need something. You do not mind.',
      18 => '${_first(g)} finished school. You cried more than their parents.',
      _ => null,
    };
    if (line != null) out.add(FeedEntry(l.age, line, kind: 'npc'));
  }
  return out;
}

// ---------------- Seasons (real calendar) ----------------

typedef Season = ({String id, String name, int from, int to});

/// Windows as month * 100 + day. New Year wraps around the year's end.
const seasons = <Season>[
  (id: 'new_year', name: 'New Year', from: 1228, to: 103),
  (id: 'lunar_new_year', name: 'Lunar New Year', from: 121, to: 220),
  (id: 'valentines', name: 'Valentine\'s Day', from: 207, to: 215),
  (id: 'spring', name: 'Spring', from: 320, to: 425),
  (id: 'summer', name: 'Midsummer', from: 615, to: 715),
  (id: 'halloween', name: 'Halloween', from: 1020, to: 1102),
  (id: 'winter', name: 'Winter holidays', from: 1210, to: 1227),
];

/// The clock seasons read; tests set a fixed date.
DateTime Function() seasonClock = DateTime.now;

Season? seasonOn(DateTime d) {
  final md = d.month * 100 + d.day;
  for (final s in seasons) {
    final inside = s.from <= s.to
        ? md >= s.from && md <= s.to
        : md >= s.from || md <= s.to;
    if (inside) return s;
  }
  return null;
}

Season? get currentSeason => seasonOn(seasonClock());

/// Once per real season per life, a seasonal moment joins the year.
void seasonalYear(Life l, Random rng) {
  final s = currentSeason;
  if (s == null || l.prison != null) return;
  final mark = 'season:${s.id}:${seasonClock().year}';
  if (l.marks.contains(mark) || rng.nextInt(100) >= 45) return;
  if (s.id == 'valentines' && l.age < 14) return;
  l.marks.add(mark);
  l.sceneQueue.add('season:${s.id}');
}

Storylet? seasonScene(String id, Life l) {
  final kid = l.age < 13;
  final p = l.who('@partner');
  Choice c(
    String label,
    String text,
    Map<String, int> stats, {
    int money = 0,
    int bond = 0,
    Npc? who,
  }) => Choice(
    label: label,
    outcome: '',
    needsMoney: money < 0 ? -money : 0,
    run: (l, rng) {
      l.money += money;
      stats.forEach(l.stats.add);
      if (who != null && bond != 0) {
        who.addFacets(affection: bond);
        who.lastContactAge = l.age;
      }
      return text;
    },
  );
  final parent = l.who('@parent');
  return switch (id) {
    'halloween' => _scene(
      'season:halloween',
      kid
          ? 'It is Halloween! The street is full of tiny witches and wobbly skeletons. What are you going as?'
          : 'Halloween again. Pumpkins glow on every doorstep and the shops have sold out of fake blood.',
      kid
          ? [
              c(
                'A homemade ghost',
                'Two eye holes, one sheet, maximum spookiness. You collected a whole bag of sweets.',
                {'creativity': 2, 'happiness': 3},
              ),
              c(
                'A superhero',
                'You ran from house to house with your cape flying. Best night of the year.',
                {'happiness': 4, 'athleticism': 1},
              ),
              c(
                'Stay in and watch a scary film',
                'You watched through your fingers and slept with the light on.',
                {'happiness': 1},
              ),
            ]
          : [
              c(
                'Throw a costume party (\$200)',
                'Your friends came as famous couples, a haunted lamp and, inexplicably, a sandwich. It was a great night.',
                {'happiness': 4, 'charisma': 1},
                money: -200,
              ),
              c(
                'Hand out sweets at the door',
                'You gave every tiny monster a handful. One vampire said "thank you" with a lisp. Worth it.',
                {'karma': 2, 'happiness': 2},
              ),
              if (p != null)
                c(
                  'Go to a haunted house with ${_first(p)}',
                  '${_first(p)} screamed first. You will never let them forget it.',
                  {'happiness': 3},
                  bond: 4,
                  who: p,
                )
              else
                c(
                  'Turn the lights off and hide',
                  'You hid from the doorbell with a bowl of sweets you ate yourself.',
                  {'happiness': 1},
                ),
            ],
    ),
    'winter' => _scene(
      'season:winter',
      kid
          ? 'The winter holidays are here. There are lights in every window and you cannot sleep for excitement.'
          : 'The winter holidays. The shops are loud, the evenings are dark, and everyone you love wants a piece of your time.',
      kid
          ? [
              c(
                'Make presents for everyone',
                'Your paper snowflakes went on the fridge and stayed there till spring.',
                {'creativity': 2, 'happiness': 3},
                bond: 4,
                who: parent,
              ),
              c(
                'Build a snowman',
                'He had a carrot nose and your dad\'s scarf. Nobody asked for it back.',
                {'happiness': 4},
              ),
            ]
          : [
              c(
                'Buy thoughtful gifts (\$400)',
                'Every present landed. Your family talked about it for weeks.',
                {'happiness': 3, 'karma': 1},
                money: -400,
                bond: 5,
                who: p ?? parent,
              ),
              c(
                'Volunteer at a shelter',
                'You served 200 dinners and felt more festive than you have in years.',
                {'karma': 5, 'happiness': 3},
              ),
              c(
                'Hide from it all with a film marathon',
                'Blanket, snacks, no plans. Pure peace.',
                {'happiness': 2, 'health': 1},
              ),
            ],
    ),
    'new_year' => _scene(
      'season:new_year',
      'Midnight. Fireworks, a countdown and the old question: what will you change this year?',
      [
        c(
          'Get fit',
          'You joined a gym on the 1st. You went more often than most people do.',
          {'health': 3, 'athleticism': 2},
        ),
        c(
          'Learn something new',
          'You signed up for an evening class and actually finished it.',
          {'smarts': 3},
        ),
        c(
          'Save more money',
          'You set up a savings rule and stuck to it. Future you is grateful.',
          {'discipline': 3},
        ),
        c(
          'No resolutions, just a good night',
          'You danced till two and woke up happy.',
          {'happiness': 3},
        ),
      ],
    ),
    'valentines' => _scene(
      'season:valentines',
      p != null
          ? 'Valentine\'s Day. ${_first(p)} is pretending not to care, which means they care a lot.'
          : 'Valentine\'s Day. Hearts in every shop window and a lot of couples in the café.',
      p != null
          ? [
              c(
                'Book a fancy dinner (\$150)',
                'Candles, too many courses, and ${_first(p)} laughing at your jokes all night.',
                {'happiness': 4},
                money: -150,
                bond: 6,
                who: p,
              ),
              c(
                'Make a handmade card',
                'It was wonky and perfect. ${_first(p)} kept it.',
                {'creativity': 2, 'happiness': 2},
                bond: 5,
                who: p,
              ),
              c(
                'Forget it entirely',
                '${_first(p)} did not mention it all day. That was worse than if they had.',
                {'happiness': -2},
                bond: -6,
                who: p,
              ),
            ]
          : [
              c(
                'Send a secret card to a crush',
                'You never signed it. You will always wonder.',
                {'happiness': 1, 'charisma': 1},
              ),
              c(
                'Treat yourself',
                'Flowers, a good book and dinner for one. Excellent company.',
                {'happiness': 3},
              ),
            ],
    ),
    'lunar_new_year' => _scene(
      'season:lunar_new_year',
      'Lunar New Year. Red lanterns, dumplings, firecrackers and the whole family in one room.',
      [
        kid
            ? c(
                'Collect red envelopes',
                'Your aunties were generous. You counted it twice.',
                {'happiness': 4},
                money: 60,
              )
            : c(
                'Give red envelopes to the children (\$100)',
                'The kids bowed, giggled and ran. The adults nodded approvingly.',
                {'karma': 2, 'happiness': 2},
                money: -100,
              ),
        c(
          'Help make the dumplings',
          'Yours were lopsided. Everyone ate them anyway.',
          {'happiness': 3},
          bond: 4,
          who: parent ?? p,
        ),
        c(
          'Watch the fireworks',
          'The sky cracked open in gold and red. A good omen.',
          {'happiness': 3},
        ),
      ],
    ),
    'spring' => _scene(
      'season:spring',
      kid
          ? 'Spring is here: blossom on the trees, chocolate in the shops, and an egg hunt in the park.'
          : 'Spring. Longer days, open windows, and a sudden urge to sort out your life.',
      kid
          ? [
              c(
                'Win the egg hunt',
                'You found nineteen eggs, including one nobody had hidden.',
                {'happiness': 4, 'athleticism': 1},
              ),
              c(
                'Share your eggs with a younger kid',
                'A toddler hugged your leg. You felt very grown up.',
                {'karma': 3, 'happiness': 2},
              ),
            ]
          : [
              c(
                'Spring clean everything',
                'You filled six bags for charity and found \$80 in an old coat.',
                {'happiness': 2},
                money: 80,
              ),
              c(
                'Plant a garden',
                'Tomatoes, herbs and one optimistic lemon tree.',
                {'happiness': 3, 'health': 1},
              ),
              c('Take a long walk in the blossom', 'You came home lighter.', {
                'happiness': 2,
                'health': 1,
              }),
            ],
    ),
    'summer' => _scene(
      'season:summer',
      'Midsummer: the longest days, warm nights and that holiday feeling.',
      [
        c(
          'Go to a music festival (\$300)',
          'Mud, sunburn, one perfect song at sunset. You will talk about it for years.',
          {'happiness': 5},
          money: -300,
        ),
        c(
          'Spend a day at the beach',
          'Sand in everything, a book you finished and a nap in the shade.',
          {'happiness': 3, 'health': 1},
        ),
        kid
            ? c(
                'Run a lemonade stand',
                'You made \$25 and drank most of your stock.',
                {'happiness': 2, 'charisma': 1},
                money: 25,
              )
            : c(
                'Work through it',
                'You stayed in the office while everyone posted holiday photos. Your inbox has never been emptier.',
                {'happiness': -1, 'discipline': 2},
              ),
      ],
    ),
    _ => null,
  };
}

// ---------------- Activities ----------------

String? _inSeason(String id) => currentSeason?.id == id
    ? null
    : 'Back around ${seasons.firstWhere((s) => s.id == id).name}';

final kinActions = <GameAction>[
  GameAction(
    id: 'foster',
    label: 'Become a foster carer',
    category: 'Family',
    priceNote: 'Carers get ${_m(fosterAllowance)} a year per child',
    keywords: ['foster', 'fostering', 'care', 'child', 'social worker'],
    minAge: 25,
    maxAge: 70,
    extraCheck: fosterLock,
    run: (l, rng) {
      l.sceneQueue.add('foster_offer');
      return ActionResult(
        'Training, checks and a home visit later, the social worker calls.',
      );
    },
  ),
  GameAction(
    id: 'surrogacy',
    label: 'Surrogacy',
    category: 'Family',
    priceNote: 'From ${_m(30000)} · depends on the country',
    keywords: ['surrogate', 'surrogacy', 'baby', 'family', 'ivf'],
    minAge: 23,
    maxAge: 60,
    extraCheck: (l) =>
        l.flags.containsKey('expecting') ? 'You are already expecting' : null,
    run: (l, rng) {
      l.sceneQueue.add('surrogacy');
      return ActionResult('You book a consultation with a fertility lawyer.');
    },
  ),
  GameAction(
    id: 'babysit',
    label: 'Babysit the grandchildren',
    category: 'Family',
    priceNote: 'Free · tiring and lovely',
    keywords: [
      'babysit',
      'grandchild',
      'grandchildren',
      'granddaughter',
      'grandson',
    ],
    minAge: 40,
    extraCheck: (l) =>
        grandchildrenOf(l).any((g) => g.alive && g.ageIn(l.year) < 13)
        ? null
        : 'Needs a grandchild under 13',
    run: (l, rng) {
      final kids = grandchildrenOf(l)
          .where((g) => g.alive && g.ageIn(l.year) < 13)
          .toList();
      for (final g in kids) {
        g.addFacets(affection: 5);
        g.lastContactAge = l.age;
      }
      final parent = l.npcs
          .where((n) => n.id == kids.first.info['parent'])
          .firstOrNull;
      parent?.addFacets(affection: 3, trust: 2);
      l.stats.add('happiness', 4);
      l.stats.add('health', -1);
      return ActionResult(
        kids.length == 1
            ? 'You and ${_first(kids.first)} built a den, ate too much cake and fell asleep on the sofa together.'
            : 'You had ${kids.length} grandchildren for the day. The house is wrecked. You have never been happier.',
        [
          'Happiness +4',
          'Health −1',
          for (final g in kids) 'Bond with ${_first(g)} +5',
        ],
      );
    },
  ),
  GameAction(
    id: 'carve_pumpkin',
    label: 'Carve a pumpkin',
    category: 'Seasonal',
    priceNote: 'Halloween · \$10',
    keywords: ['halloween', 'pumpkin', 'carve', 'spooky'],
    minAge: 4,
    cost: 10,
    extraCheck: (l) => _inSeason('halloween'),
    run: (l, rng) {
      l.money -= 10;
      l.stats.add('creativity', 2);
      l.stats.add('happiness', 2);
      return ActionResult(
        'Your pumpkin has one big tooth and a surprised face. It glows on the step.',
        ['Money −\$10', 'Creativity +2', 'Happiness +2'],
      );
    },
  ),
  GameAction(
    id: 'trick_or_treat',
    label: 'Go trick-or-treating',
    category: 'Seasonal',
    priceNote: 'Halloween · free',
    keywords: ['halloween', 'trick', 'treat', 'sweets', 'costume'],
    minAge: 4,
    maxAge: 15,
    extraCheck: (l) => _inSeason('halloween'),
    run: (l, rng) {
      final sick = rng.nextInt(100) < 25;
      l.stats.add('happiness', sick ? 1 : 4);
      if (sick) l.stats.add('health', -1);
      return ActionResult(
        sick
            ? 'You ate the whole bag before bed. Your stomach has filed a complaint.'
            : 'Two streets, forty doors, one pillowcase of sweets. A triumph.',
        [sick ? 'Happiness +1' : 'Happiness +4', if (sick) 'Health −1'],
      );
    },
  ),
  GameAction(
    id: 'holiday_lights',
    label: 'See the holiday lights',
    category: 'Seasonal',
    priceNote: 'Winter holidays · free',
    keywords: ['christmas', 'winter', 'holiday', 'lights', 'festive'],
    extraCheck: (l) => _inSeason('winter'),
    run: (l, rng) {
      l.stats.add('happiness', 3);
      return ActionResult(
        'You walked the lit-up streets with a hot drink. The whole town glowed.',
        ['Happiness +3'],
      );
    },
  ),
  GameAction(
    id: 'resolution',
    label: 'Make a New Year\'s resolution',
    category: 'Seasonal',
    priceNote: 'New Year · free',
    keywords: ['new year', 'resolution', 'goal'],
    minAge: 8,
    extraCheck: (l) => _inSeason('new_year'),
    run: (l, rng) {
      l.stats.add('discipline', 2);
      return ActionResult(
        'You wrote it on a sticky note and put it on the mirror. This year is different.',
        ['Discipline +2'],
      );
    },
  ),
  GameAction(
    id: 'valentine_card',
    label: 'Send a Valentine',
    category: 'Seasonal',
    priceNote: 'Valentine\'s Day · \$5',
    keywords: ['valentine', 'love', 'card', 'romance'],
    minAge: 12,
    cost: 5,
    extraCheck: (l) => _inSeason('valentines'),
    run: (l, rng) {
      l.money -= 5;
      final p = l.who('@partner');
      p?.addFacets(affection: 4);
      l.stats.add('happiness', 2);
      return ActionResult(
        p != null
            ? '${_first(p)} pinned your card to the fridge and pretended not to be pleased.'
            : 'You sent it unsigned. Somewhere, someone is smiling and confused.',
        [
          'Money −\$5',
          'Happiness +2',
          if (p != null) 'Bond with ${_first(p)} +4',
        ],
      );
    },
  ),
  GameAction(
    id: 'egg_hunt',
    label: 'Join the spring egg hunt',
    category: 'Seasonal',
    priceNote: 'Spring · free',
    keywords: ['easter', 'spring', 'egg', 'hunt', 'chocolate'],
    maxAge: 12,
    extraCheck: (l) => _inSeason('spring'),
    run: (l, rng) {
      l.stats.add('happiness', 3);
      return ActionResult('You found eleven eggs and a very surprised frog.', [
        'Happiness +3',
      ]);
    },
  ),
  GameAction(
    id: 'beach_day',
    label: 'Midsummer beach day',
    category: 'Seasonal',
    priceNote: 'Midsummer · free',
    keywords: ['summer', 'beach', 'sun', 'sea', 'holiday'],
    extraCheck: (l) => _inSeason('summer'),
    run: (l, rng) {
      l.stats.add('happiness', 3);
      l.stats.add('health', 1);
      return ActionResult('Sun, sea and a sandwich with actual sand in it.', [
        'Happiness +3',
        'Health +1',
      ]);
    },
  ),
  GameAction(
    id: 'lantern',
    label: 'Light a lantern for the New Year',
    category: 'Seasonal',
    priceNote: 'Lunar New Year · free',
    keywords: ['lunar', 'new year', 'lantern', 'red', 'dumplings'],
    extraCheck: (l) => _inSeason('lunar_new_year'),
    run: (l, rng) {
      l.stats.add('happiness', 2);
      l.stats.add('karma', 1);
      return ActionResult(
        'Your lantern floated up and joined a hundred others. Good luck for the year.',
        ['Happiness +2', 'Karma +1'],
      );
    },
  ),
];

/// Scenes in this file, dispatched from buildScene.
Storylet? kinScene(String id, List<String> args, Life l) => switch (id) {
  'foster_offer' => fosterLock(l) == null ? fosterOfferScene(l) : null,
  'foster_end' => fosterEndScene(args, l),
  'surrogacy' => surrogacyScene(l),
  'season' => seasonScene(args.join(':'), l),
  _ => null,
};

/// Each birthday: placements that end, and seasonal moments.
List<FeedEntry> kinYear(Life l, Random rng) {
  final out = <FeedEntry>[];
  for (final f in fostersOf(l)) {
    final placed = (f.info['placed'] as int?) ?? l.age;
    final stay = (f.info['stay'] as int?) ?? 2;
    if (l.age - placed >= stay) {
      l.sceneQueue.add('foster_end:${f.id}');
    } else if (rng.nextInt(100) < 40) {
      f.addFacets(affection: 4, trust: 3);
      out.add(
        FeedEntry(
          l.age,
          '${_first(f)} ${['laughed properly for the first time since they arrived', 'brought home a school certificate and pretended it was nothing', 'called you by your name instead of "you"', 'unpacked the last box in their room'][rng.nextInt(4)]}.',
          kind: 'npc',
        ),
      );
    }
  }
  out.addAll(grandchildrenYear(l, rng));
  seasonalYear(l, rng);
  return out;
}
