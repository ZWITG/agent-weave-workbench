import 'dart:math';

import 'actions.dart';
import 'careers.dart' show careerById;
import 'family.dart' show childrenOf;
import 'friends.dart';
import 'models.dart';
import 'social.dart' show maxFollowers, followersLabel;
import 'storylet.dart';

// Fame, reworked. Fame is how many people know you; public image is how
// they feel about you. Tiers bring perks and costs, fame comes from what
// you actually do (a career, followers, money, crimes, good deeds), and
// famous people get their own activities and yearly happenings.

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
  category: 'fame',
  scene: true,
  choices: choices,
);

void addImage(Life l, int d) => l.image = (l.image + d).clamp(-100, 100);
void addFame(Life l, int d) => l.fame = (l.fame + d).clamp(0, 100);

// ---------------- Tiers ----------------

typedef FameTier = ({String name, int from, String perks, String costs});

const fameTiers = <FameTier>[
  (
    name: 'Unknown',
    from: 0,
    perks: 'Total privacy',
    costs: 'Nobody calls back',
  ),
  (
    name: 'Local name',
    from: 10,
    perks: 'Recognised in town · free coffee',
    costs: 'Neighbours gossip',
  ),
  (
    name: 'Known',
    from: 25,
    perks: 'Interviews and appearance fees',
    costs: 'Strangers have opinions about you',
  ),
  (
    name: 'Celebrity',
    from: 45,
    perks: 'Red carpets, gifts, a memoir deal',
    costs: 'Paparazzi and tabloid rumours',
  ),
  (
    name: 'Superstar',
    from: 70,
    perks: 'Your own product line, award shows',
    costs: 'Stalkers, and your family loses its privacy',
  ),
  (
    name: 'Legend',
    from: 90,
    perks: 'A name that outlives you',
    costs: 'You can never go to the shops again',
  ),
];

FameTier fameTierOf(Life l) =>
    fameTiers.lastWhere((t) => l.fame >= t.from, orElse: () => fameTiers.first);

String imageLabel(int image) => image >= 60
    ? 'Adored'
    : image >= 25
    ? 'Liked'
    : image > -25
    ? 'Mixed'
    : image > -60
    ? 'Disliked'
    : 'Hated';

/// What the public knows you for, strongest first.
List<String> knownFor(Life l) {
  final c = careerById(l.careerId);
  return [
    if (c != null && c.special && l.careerRank > 0) l.job ?? c.id,
    if (maxFollowers(l) >= 10000)
      '${followersLabel(maxFollowers(l))} followers',
    if (l.netWorth >= 5000000) 'your fortune',
    if (l.business != null && l.netWorth >= 1000000) 'your business',
    if (l.record.any((r) => r['band'] == 'severe' || r['band'] == 'serious'))
      'your criminal past',
    if (l.marks.contains('memoir')) 'your memoir',
    if (l.marks.any((m) => m.startsWith('feud:'))) 'your feuds',
    if (l.stats['karma'] >= 85 && l.fame >= 20) 'your charity work',
  ];
}

// ---------------- Each birthday ----------------

/// Fame that comes from money and notoriety, plus tier events. Returns
/// feed lines and queues scenes that need a decision.
List<String> celebrityYear(Life l, Random rng) {
  final feed = <String>[];
  if (l.age < 13) return feed;
  // Big fortunes and big crimes make you known, whether you like it or not.
  if (l.netWorth >= 10000000 && l.fame < 30) addFame(l, 4);
  if (l.record.any((r) => r['band'] == 'severe') && l.fame < 25) {
    addFame(l, 3);
    addImage(l, -2);
  }
  // Image drifts back towards neutral as people forget.
  if (l.image != 0) l.image += l.image > 0 ? -1 : 1;
  final publicist = l.marks.contains('publicist');
  final guard = l.marks.contains('bodyguard');
  if (publicist && l.fame > 5) addFame(l, 1);
  final tier = fameTierOf(l).name;
  if (l.marks.contains('off_grid:${l.age - 1}')) {
    l.stats.add('happiness', 4);
    feed.add('A year away from it all. Nobody took your picture once.');
  }
  switch (tier) {
    case 'Unknown':
      break;
    case 'Local name':
      if (rng.nextInt(100) < 25) {
        feed.add(
          'Someone recognised you in the queue at the bakery and paid for your coffee.',
        );
        l.stats.add('happiness', 1);
      }
    default:
      // Gifts from brands and fans.
      if (rng.nextInt(100) < 30) {
        final gift = 200 + rng.nextInt(1800) * (l.fame ~/ 25);
        l.money += gift;
        feed.add(
          'Brands sent you free things you did not ask for: trainers, a blender, a very large hamper. Worth about ${_m(gift)}.',
        );
      }
      final queued = l.sceneQueue.any((s) => s.startsWith('fame_'));
      if (!queued && l.fame >= 45 && rng.nextInt(100) < 18 && !publicist) {
        l.sceneQueue.add('fame_rumour');
      } else if (!queued && l.fame >= 70 && !guard && rng.nextInt(100) < 12) {
        l.sceneQueue.add('fame_stalker');
      } else if (!queued && l.fame >= 40 && rng.nextInt(100) < 15) {
        l.sceneQueue.add('fame_award');
      } else if (l.fame >= 35 && rng.nextInt(100) < 15) {
        final f = meetFriend(l, rng, role: 'Celebrity friend', bond: 55);
        feed.add(
          'You hit it off with ${f.name} at a party full of famous faces. They have joined your friends.',
        );
      }
      // Fame is hard on the people you love.
      if (l.fame >= 70 && !guard) {
        final kids = childrenOf(l)
            .where((c) => c.alive && c.ageIn(l.year) < 18)
            .toList();
        if (kids.isNotEmpty) {
          for (final k in kids) {
            k.addFacets(affection: -2);
          }
          feed.add(
            'Photographers waited outside the school gates again. Your kids hate it.',
          );
        }
      }
  }
  return feed;
}

/// Yearly costs of a famous life (cash-flow lines).
List<(String, int)> celebrityCosts(Life l) => [
  if (l.marks.contains('publicist')) ('Publicist', -publicistFee),
  if (l.marks.contains('bodyguard')) ('Bodyguard', -bodyguardFee),
  if (l.marks.contains('product_line')) ('Your product line', productIncome(l)),
];

const publicistFee = 30000;
const bodyguardFee = 60000;

int productIncome(Life l) =>
    max(0, (l.fame * 1500 * (1 + l.image / 100)).round());

// ---------------- Scenes ----------------

Storylet? celebrityScene(String id, List<String> args, Life l) {
  switch (id) {
    case 'fame_rumour':
      return _scene(
        id,
        'A tabloid runs a story that you secretly had a "meltdown" in a hotel lobby. None of it is true. It is everywhere anyway.',
        [
          Choice(
            label: 'Sue them (\$40,000 in legal fees)',
            outcome: '',
            needsMoney: 40000,
            risk: 'You might win damages, or lose and look petty',
            run: (l, rng) {
              l.money -= 40000;
              if (rng.nextInt(100) < 60) {
                final damages = 80000 + rng.nextInt(120000);
                l.money += damages;
                addImage(l, 8);
                return 'The judge sided with you. The paper printed an apology on page 12 and paid ${_m(damages)} in damages.';
              }
              addImage(l, -5);
              return 'The case collapsed on a technicality. The paper ran a smug follow-up.';
            },
          ),
          Choice(
            label: 'Laugh it off in public',
            outcome: '',
            risk: 'Charisma helps',
            run: (l, rng) {
              if (l.stats['charisma'] >= 55 || rng.nextBool()) {
                addImage(l, 6);
                addFame(l, 2);
                return 'You re-enacted the "meltdown" on a talk show. It was the funniest clip of the week.';
              }
              addImage(l, -3);
              return 'Your joke fell flat. Now people think there might be something in it.';
            },
          ),
          Choice(
            label: 'Ignore it',
            outcome: '',
            run: (l, rng) {
              addImage(l, -4);
              return 'You said nothing. In a week it was gone, but some people still believe it.';
            },
          ),
        ],
      );
    case 'fame_stalker':
      return _scene(
        id,
        'The same person has been outside your home every night for a week. They left a letter in your car. You never gave them a key.',
        [
          Choice(
            label: 'Call the police and get a restraining order',
            outcome: '',
            run: (l, rng) {
              l.stats.add('happiness', -3);
              return 'The order came through. You still check the window before bed.';
            },
          ),
          Choice(
            label: 'Hire a bodyguard (${_m(bodyguardFee)} a year)',
            outcome: '',
            run: (l, rng) {
              l.marks.add('bodyguard');
              return 'A very large, very calm man named Dev now goes everywhere you go.';
            },
          ),
          Choice(
            label: 'Move house quietly',
            outcome: '',
            run: (l, rng) {
              l.money -= 15000;
              l.stats.add('happiness', -2);
              return 'Movers at 4am, a new address nobody knows. Money −${_m(15000)}.';
            },
          ),
        ],
      );
    case 'fame_award':
      final c = careerById(l.careerId);
      final what = c != null && c.special
          ? 'Best newcomer for your work as ${l.job ?? 'an artist'}'
          : maxFollowers(l) >= 100000
          ? 'Creator of the Year'
          : 'Personality of the Year';
      return _scene(
        id,
        'You have been nominated: $what. The ceremony is black tie and on live television.',
        [
          Choice(
            label: 'Go and hope',
            outcome: '',
            risk: 'Looks and charisma help on the night',
            run: (l, rng) {
              final odds =
                  25 + (l.stats['charisma'] + l.stats['looks'] - 100) ~/ 4;
              if (rng.nextInt(100) < odds.clamp(10, 60)) {
                addFame(l, 8);
                addImage(l, 6);
                l.stats.add('happiness', 8);
                l.flags['award_winner'] = Memory(l.age, 'winning $what');
                return 'They read your name. You forgot your speech and thanked your dentist. It went viral for the right reasons.';
              }
              addFame(l, 2);
              return 'Someone else won. You clapped like a good sport for the cameras.';
            },
          ),
          Choice(
            label: 'Skip it',
            outcome: '',
            run: (l, rng) {
              addImage(l, -2);
              return 'You stayed home in pyjamas. The papers called it "a snub".';
            },
          ),
        ],
      );
    case 'fame_feud':
      final rival = args.isEmpty ? 'a rival' : args.join(':');
      return _scene(
        id,
        '$rival has answered your jab with a long post about you. Everyone is waiting to see what you do.',
        [
          Choice(
            label: 'Escalate',
            outcome: '',
            risk: 'Fame up, image down',
            run: (l, rng) {
              addFame(l, 6);
              addImage(l, -10);
              return 'You went for the jugular. It trended for a week. Half the internet is on your side; the other half wants you gone.';
            },
          ),
          Choice(
            label: 'Make peace in public',
            outcome: '',
            run: (l, rng) {
              addImage(l, 6);
              return 'You posted a photo of the two of you having lunch. Everyone was a little disappointed, and liked you more.';
            },
          ),
        ],
      );
  }
  return null;
}

// ---------------- Activities ----------------

String? _famous(Life l, int need) => l.fame < need
    ? 'Needs ${fameTiers.lastWhere((t) => t.from <= need).name} fame or more'
    : null;

ActionResult _did(Life l, String text, List<String> notes) =>
    ActionResult(text, notes);

final celebrityActions = <GameAction>[
  GameAction(
    id: 'talk_show',
    label: 'Go on a talk show',
    category: 'Fame',
    keywords: ['talk show', 'interview', 'tv', 'television', 'chat show'],
    minAge: 16,
    extraCheck: (l) => _famous(l, 25),
    priceNote: 'An appearance fee · charisma matters',
    run: (l, rng) {
      final fee = 2000 + l.fame * 150;
      l.money += fee;
      if (l.stats['charisma'] >= 50 || rng.nextInt(100) < 50) {
        addFame(l, 3);
        addImage(l, 4);
        return _did(
          l,
          'You were charming, a little self-deprecating, and told a story about your mum that made the host cry laughing.',
          ['Fee +${_m(fee)}', 'Fame up', 'Image up'],
        );
      }
      addFame(l, 1);
      addImage(l, -3);
      return _did(
        l,
        'You froze on a simple question and answered with a long silence. The clip did numbers, sadly.',
        ['Fee +${_m(fee)}', 'Image down'],
      );
    },
  ),
  GameAction(
    id: 'red_carpet',
    label: 'Walk a red carpet',
    category: 'Fame',
    keywords: ['red carpet', 'premiere', 'gala', 'outfit', 'paparazzi'],
    minAge: 16,
    extraCheck: (l) => _famous(l, 45),
    priceNote: 'Looks matter · the outfit is on you (\$3,000)',
    run: (l, rng) {
      l.money -= 3000;
      final hit = l.stats['looks'] + rng.nextInt(40) >= 75;
      addFame(l, hit ? 4 : 1);
      addImage(l, hit ? 3 : -2);
      return _did(
        l,
        hit
            ? 'Your outfit made every best-dressed list. Designers are already calling.'
            : 'A fashion critic called your outfit "a cry for help". You thought it was nice.',
        ['Money −${_m(3000)}', hit ? 'Best dressed' : 'Worst dressed'],
      );
    },
  ),
  GameAction(
    id: 'write_memoir',
    label: 'Write your memoir',
    category: 'Fame',
    keywords: ['memoir', 'book', 'autobiography', 'publish', 'write'],
    minAge: 18,
    extraCheck: (l) =>
        l.marks.contains('memoir') ? 'You already wrote one' : _famous(l, 30),
    priceNote: 'An advance from a publisher',
    run: (l, rng) {
      final advance = 20000 + l.fame * 3000;
      l.money += advance;
      l.marks.add('memoir');
      addFame(l, 4);
      final honest = l.stats['karma'] >= 50;
      addImage(l, honest ? 6 : -4);
      return _did(
        l,
        honest
            ? 'You told the truth, including the embarrassing bits. Readers loved you for it.'
            : 'You settled a few scores in chapter nine. The reviews were brutal; the sales were not.',
        ['Advance +${_m(advance)}', 'Fame up'],
      );
    },
  ),
  GameAction(
    id: 'product_line',
    label: 'Launch your own product line',
    category: 'Fame',
    keywords: ['product', 'brand', 'merch', 'perfume', 'clothing line'],
    minAge: 18,
    extraCheck: (l) => l.marks.contains('product_line')
        ? 'Your line is already selling'
        : _famous(l, 70) ??
              (l.money < 100000 ? 'Needs \$100,000 to launch' : null),
    priceNote: '\$100,000 to launch · sells better when you are liked',
    run: (l, rng) {
      l.money -= 100000;
      l.marks.add('product_line');
      return _did(
        l,
        'Your name is on bottles, hoodies and a frankly unnecessary candle. It earns every year, more when people like you.',
        [
          'Money −${_m(100000)}',
          'About ${_m(productIncome(l))} a year while your image holds',
        ],
      );
    },
  ),
  GameAction(
    id: 'charity_gala',
    label: 'Host a charity gala',
    category: 'Fame',
    keywords: ['charity', 'gala', 'fundraiser', 'donate', 'good cause'],
    minAge: 18,
    extraCheck: (l) =>
        _famous(l, 25) ?? (l.money < 20000 ? 'Needs \$20,000' : null),
    priceNote: '\$20,000 · image and karma up',
    run: (l, rng) {
      l.money -= 20000;
      addImage(l, 10);
      addFame(l, 2);
      l.stats.add('karma', 4);
      return _did(
        l,
        'You raised a small fortune for a children\'s hospital and danced badly with a minister.',
        ['Money −${_m(20000)}', 'Image up', 'Karma up'],
      );
    },
  ),
  GameAction(
    id: 'meet_fans',
    label: 'Meet your fans',
    category: 'Fame',
    keywords: ['fans', 'meet and greet', 'signing', 'autographs'],
    minAge: 13,
    extraCheck: (l) => _famous(l, 10),
    repeatable: true,
    priceNote: 'Free · happiness and image up',
    run: (l, rng) {
      addImage(l, 3);
      l.stats.add('happiness', 3);
      return _did(
        l,
        'Four hours of selfies and signatures. A girl told you that you got her through a hard year.',
        ['Image up', 'Happiness up'],
      );
    },
  ),
  GameAction(
    id: 'start_feud',
    label: 'Start a celebrity feud',
    category: 'Fame',
    keywords: ['feud', 'beef', 'drama', 'rival', 'diss'],
    minAge: 16,
    extraCheck: (l) => _famous(l, 25),
    priceNote: 'Fame up · image probably down',
    run: (l, rng) {
      const rivals = [
        'pop star Kaia Moon',
        'chef Bruno Vale',
        'influencer Tash Rivers',
        'actor Leo Marchetti',
        'footballer Dani Okafor',
      ];
      final r = rivals[rng.nextInt(rivals.length)];
      l.marks.add('feud:$r');
      addFame(l, 4);
      addImage(l, -6);
      l.sceneQueue.add('fame_feud:$r');
      return _did(
        l,
        'You posted a sly dig at $r. Their fans noticed within minutes.',
        ['Fame up', 'Image down'],
      );
    },
  ),
  GameAction(
    id: 'hire_publicist',
    label: 'Hire a publicist',
    category: 'Fame',
    keywords: ['publicist', 'pr', 'press', 'agent', 'image'],
    minAge: 16,
    extraCheck: (l) =>
        l.marks.contains('publicist') ? 'You already have one' : _famous(l, 25),
    priceNote:
        '${_m(publicistFee)} a year · keeps you in the news, kills rumours',
    run: (l, rng) {
      l.marks.add('publicist');
      return _did(
        l,
        'Your new publicist speaks only in bullet points and has three phones.',
        ['${_m(publicistFee)} a year', 'Fame stays up · rumours handled'],
      );
    },
  ),
  GameAction(
    id: 'fire_staff',
    label: 'Let your publicist or bodyguard go',
    category: 'Fame',
    keywords: ['fire', 'publicist', 'bodyguard', 'staff', 'save money'],
    minAge: 16,
    extraCheck: (l) =>
        !l.marks.contains('publicist') && !l.marks.contains('bodyguard')
        ? 'You have no staff'
        : null,
    run: (l, rng) {
      l.marks.removeWhere((m) => m == 'publicist' || m == 'bodyguard');
      return _did(l, 'You thanked them and let them go. It is just you now.', [
        'No more staff costs',
      ]);
    },
  ),
  GameAction(
    id: 'go_off_grid',
    label: 'Go off-grid for a year',
    category: 'Fame',
    keywords: ['off grid', 'break', 'privacy', 'disappear', 'rest'],
    minAge: 16,
    extraCheck: (l) => _famous(l, 25),
    priceNote: 'Fame fades · happiness up next year',
    run: (l, rng) {
      l.marks.add('off_grid:${l.age}');
      addFame(l, -8);
      return _did(
        l,
        'You deleted the apps, turned off your phone and went somewhere with goats.',
        ['Fame down', 'A calmer year ahead'],
      );
    },
  ),
];
