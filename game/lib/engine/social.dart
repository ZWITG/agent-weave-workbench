import 'dart:math';

import 'actions.dart';
import 'careers.dart' show careerById;
import 'family.dart' show childrenOf;
import 'justice.dart' show crimeById;
import 'models.dart';
import 'storylet.dart';

/// Fame and social media (plan Social §5): Fame (how widely known you are)
/// and Followers (per platform) are separate. Every post shows its reach
/// and risk first, and explains why it did or did not go viral. Scandals
/// only ever come from things you actually did.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '−' : ''}\$$s';
}

String followersLabel(int n) => n >= 1000000
    ? '${(n / 1000000).toStringAsFixed(n >= 10000000 ? 0 : 1)}M'
    : n >= 1000
    ? '${(n / 1000).toStringAsFixed(n >= 10000 ? 0 : 1)}k'
    : '$n';

typedef Platform = ({
  String id,
  String name,
  String kind,
  int minAge,
  String best,
  double payPer1k,
  Set<String> fits,
});

/// Original fictional platforms (plan: trademark check needed).
const platforms = <Platform>[
  (
    id: 'vybe',
    name: 'Vybe',
    kind: 'Short videos',
    minAge: 13,
    best: 'Viral reach and trends',
    payPer1k: 2,
    fits: {'talent', 'trend'},
  ),
  (
    id: 'lenso',
    name: 'Lenso',
    kind: 'Photos and stories',
    minAge: 13,
    best: 'Looks, lifestyle and brands',
    payPer1k: 3,
    fits: {'selfie', 'daily', 'sponsored'},
  ),
  (
    id: 'murmur',
    name: 'Murmur',
    kind: 'Short text posts',
    minAge: 13,
    best: 'Opinions and news; the most controversy',
    payPer1k: 1,
    fits: {'opinion', 'charity'},
  ),
  (
    id: 'hearthcast',
    name: 'Hearthcast',
    kind: 'Long videos and live streams',
    minAge: 16,
    best: 'Steady income: gaming, education, talent',
    payPer1k: 6,
    fits: {'talent', 'daily', 'collab'},
  ),
  (
    id: 'inkwell',
    name: 'Inkwell',
    kind: 'Newsletters',
    minAge: 16,
    best: 'Writers and experts with paying readers',
    payPer1k: 5,
    fits: {'opinion', 'daily'},
  ),
];

Platform platformById(String id) =>
    platforms.firstWhere((p) => p.id == id, orElse: () => platforms.first);

typedef PostType = ({String id, String label, int risk, String blurb});

const postTypes = <PostType>[
  (id: 'selfie', label: 'Selfie', risk: 0, blurb: 'Looks'),
  (id: 'daily', label: 'Daily life', risk: 0, blurb: 'Charisma'),
  (id: 'talent', label: 'Talent clip', risk: 0, blurb: 'Your best skill'),
  (id: 'trend', label: 'Join a trend', risk: 1, blurb: 'Charisma + the trend'),
  (id: 'opinion', label: 'Hot take', risk: 2, blurb: 'Smarts; can backfire'),
  (id: 'charity', label: 'Charity appeal', risk: 0, blurb: 'Karma'),
  (
    id: 'collab',
    label: 'Collab with a friend',
    risk: 0,
    blurb: 'Two audiences',
  ),
  (id: 'family', label: 'Family vlog', risk: 1, blurb: 'Your kids remember'),
  (
    id: 'sponsored',
    label: 'Sponsored review',
    risk: 1,
    blurb: 'Your brand deal',
  ),
];

PostType postTypeById(String id) =>
    postTypes.firstWhere((p) => p.id == id, orElse: () => postTypes.first);

int _skill(Life l, String type) => switch (type) {
  'selfie' => l.stats['looks'],
  'talent' => [
    l.stats['creativity'],
    l.stats['athleticism'],
    l.stats['charisma'],
  ].reduce(max),
  'opinion' => l.stats['smarts'],
  'charity' => l.stats['karma'],
  _ => l.stats['charisma'],
};

/// This year's trend, the same for everyone in the world that year.
(String, String) trendFor(int year) {
  final r = Random(year * 31);
  final p = platforms[r.nextInt(3)].id;
  const types = ['talent', 'trend', 'selfie', 'daily', 'opinion'];
  return (p, types[r.nextInt(types.length)]);
}

int postsThisYear(Life l, String platform) =>
    l.usedActions.where((a) => a.startsWith('post:$platform:')).length;

Npc? _collabFriend(Life l) => l.npcs
    .where((n) => n.alive && n.circle == 'Friends' && n.bond >= 60)
    .firstOrNull;

/// Null when this post type can be used now, otherwise why not.
String? postLock(Life l, String platform, String type) {
  final p = platformById(platform);
  if (l.age < p.minAge) return '${p.name} opens at ${p.minAge}';
  if (l.prison != null) return 'Not possible in prison';
  if (!l.classic && l.energy <= 0) return 'No energy left this year';
  return switch (type) {
    'collab' => _collabFriend(l) == null ? 'Needs a friend at Bond 60%+' : null,
    'family' =>
      childrenOf(l).any((c) => c.alive && c.ageIn(l.year) < 13)
          ? null
          : 'Needs a child under 13',
    'sponsored' => l.deal == null ? 'Needs a brand deal' : null,
    _ => null,
  };
}

/// Viral chance (plan): 1% + 0.1% × skill + trend + collab + fit −
/// fatigue, capped at 25%. Returns the chance and its parts.
(double, List<String>) viralChance(Life l, String platform, String type) {
  final parts = <String>[];
  var p = 1.0 + _skill(l, type) * 0.1;
  parts.add('skill ${_skill(l, type)}');
  final (tp, tt) = trendFor(l.year);
  if (tt == type) {
    p += tp == platform ? 8 : 4;
    parts.add('this year\'s trend +${tp == platform ? 8 : 4}%');
  }
  if (platformById(platform).fits.contains(type)) {
    p += 3;
    parts.add('fits ${platformById(platform).name} +3%');
  }
  if (type == 'collab') {
    p += 5;
    parts.add('collab +5%');
  }
  final extra = postsThisYear(l, platform) - 3;
  if (extra > 0) {
    p -= extra * 3;
    parts.add('posting too often −${extra * 3}%');
  }
  if ((l.cancelledUntil ?? 0) > l.age) {
    p -= 5;
    parts.add('cancelled −5%');
  }
  return (p.clamp(0.5, 25), parts);
}

String reachBand(double viral) => viral >= 15
    ? 'High'
    : viral >= 8
    ? 'Medium'
    : 'Low';

String riskLabel(int risk) => switch (risk) {
  0 => 'None',
  1 => 'Low',
  _ => 'Hot take',
};

int maxFollowers(Life l) => l.followers.values.fold(0, max);

/// Posts something and explains the result.
ActionResult post(Life l, String platform, String type, Random rng) {
  final p = platformById(platform);
  final n = postsThisYear(l, platform);
  l.usedActions.add('post:$platform:$n');
  l.marks.add('posted:${l.age}');
  if (!l.classic) l.energy = max(0, l.energy - 1);
  l.reason = 'Posting on ${p.name}';
  final before = l.followers[platform] ?? 0;
  final (chance, parts) = viralChance(l, platform, type);
  final viral = rng.nextDouble() * 100 < chance;
  final fit = p.fits.contains(type) ? 1.5 : 1.0;
  var gain =
      ((20 + _skill(l, type) * 2) * fit +
              before * (0.02 + rng.nextDouble() * 0.04))
          .round();
  if (viral) {
    gain += (5000 + rng.nextInt(55000) + before * 0.5).round();
    l.fame = min(100, l.fame + 3 + rng.nextInt(6));
  }
  final notes = <String>[];
  var text = viral
      ? 'It went viral. Your phone would not stop buzzing for three days.'
      : gain > 500
      ? 'Solid numbers. People shared it and new followers trickled in.'
      : 'A few likes, mostly from people who already love you.';
  if (type == 'opinion' &&
      rng.nextInt(100) < (platform == 'murmur' ? 35 : 22)) {
    final lost = (before * (0.05 + rng.nextDouble() * 0.1)).round();
    gain = -lost;
    text = 'Your hot take started a pile-on. You lost followers and gained a few dedicated haters.';
    l.stats.add('happiness', -3);
    l.posts.add({'platform': platform, 'age': l.age, 'hot': true});
  } else if (type == 'opinion') {
    l.posts.add({'platform': platform, 'age': l.age, 'hot': true});
  }
  switch (type) {
    case 'charity':
      l.stats.add('karma', 2);
    case 'collab':
      final f = _collabFriend(l)!;
      f.addFacets(affection: 4);
      text += ' ${f.name.split(' ').first} loved making it with you.';
    case 'family':
      for (final c in childrenOf(l).where((c) => c.ageIn(l.year) < 13)) {
        c.remember(
          NpcMemory(
            age: l.age,
            text: 'being filmed for your channel',
            valence: -1,
            intensity: 2,
            tags: ['privacy'],
          ),
        );
      }
      notes.add('Your children will remember being on camera');
    case 'sponsored':
      final d = l.deal!;
      d['posts'] = (d['posts'] as int? ?? 0) + 1;
      text += ' ${d['brand']} were happy.';
  }
  l.followers[platform] = max(0, before + gain);
  if (l.followers[platform]! >= 10000 && l.fame < 5) l.fame = 5;
  final after = l.followers[platform]!;
  final why =
      '${viral ? 'Viral' : 'Not viral'} (${chance.toStringAsFixed(1)}% chance: ${parts.join(', ')})';
  return ActionResult(text, [
    '${p.name}: ${gain >= 0 ? '+' : '−'}${followersLabel(gain.abs())} followers (${followersLabel(after)})',
    why,
    ...notes,
    if (viral) 'Fame ${l.fame}',
  ]);
}

// ---------------- Tiers and verification ----------------

String tierOf(Life l) {
  final f = maxFollowers(l);
  if (f >= 10000000) return 'Icon';
  if (f >= 1000000) return 'Star';
  if (l.verified) return 'Verified';
  if (f >= 10000) return 'Rising';
  return 'Newcomer';
}

bool notableCareer(Life l) {
  final c = careerById(l.careerId);
  return c != null && c.special && l.careerRank >= 2;
}

/// The Apply card: requirements and progress, no hidden thresholds.
List<(String, bool)> verifyRequirements(Life l) => [
  (
    '100k followers on one platform (${followersLabel(maxFollowers(l))})',
    maxFollowers(l) >= 100000,
  ),
  (
    'Fame 20+ (${l.fame}) or a notable career',
    l.fame >= 20 || notableCareer(l),
  ),
];

ActionResult applyVerification(Life l) {
  if (verifyRequirements(l).any((r) => !r.$2)) {
    return ActionResult('Not yet: the requirements are on the card.');
  }
  l.verified = true;
  l.fame = min(100, l.fame + 3);
  l.flags['verified'] = Memory(l.age, 'getting verified');
  return ActionResult(
    'You got the blue tick. Brands and press can find you now.',
    ['Verified', 'Brand deals can be offered each birthday'],
  );
}

// ---------------- Yearly ----------------

const _brands = [
  ('Peak Sportswear', 'Sporty', 'athleticism'),
  ('Little Acorn Toys', 'Family-friendly', 'karma'),
  ('Gilded Watches', 'Luxury', 'looks'),
  ('Neon Rush Energy', 'Edgy', 'charisma'),
  ('Greenleaf Kitchen', 'Healthy', 'smarts'),
];

/// Income, fame decay, paparazzi, brand offers, scandals and comebacks.
List<String> fameYear(Life l, Random rng) {
  final feed = <String>[];
  final posted = l.marks.contains('posted:${l.age - 1}');
  // Fame from careers and followers (plan: two separate meters).
  final c = careerById(l.careerId);
  if (c != null && c.special && l.careerRank > 0) {
    l.fame = min(20 + l.careerRank * 18, l.fame + l.careerRank * 3);
  }
  final floor = switch (maxFollowers(l)) {
    >= 10000000 => 60,
    >= 1000000 => 35,
    >= 100000 => 15,
    >= 10000 => 5,
    _ => 0,
  };
  final cancelled = (l.cancelledUntil ?? 0) > l.age;
  final decay = cancelled
      ? 6
      : posted || (c?.special ?? false)
      ? 0
      : tierOf(l) == 'Icon'
      ? 1
      : 3;
  l.fame = max(floor, l.fame - decay).clamp(0, 100);
  if (l.fame >= 50 && rng.nextInt(100) < 20) {
    l.stats.add('happiness', -1);
    feed.add(
      'Paparazzi followed you to the supermarket. A photo of you buying toilet roll made the gossip pages.',
    );
  }
  // Brand deals.
  final d = l.deal;
  if (d != null && (d['until'] as int) <= l.age) {
    feed.add('Your deal with ${d['brand']} ended.');
    l.deal = null;
  }
  if (l.deal == null && l.verified && !cancelled && rng.nextInt(100) < 50) {
    l.sceneQueue.add('brand_deal');
  }
  // Scandals come only from recorded events (plan acceptance).
  if (l.fame >= 30 && !l.sceneQueue.any((s) => s.startsWith('scandal'))) {
    final sources = <String>[
      if (l.flags.containsKey('affair_found')) 'affair',
      for (final r in l.record)
        if (r['sealed'] != true) 'record:${r['crime']}:${r['age']}',
      for (final p in l.posts)
        if (p['hot'] == true && l.age - (p['age'] as int) >= 3)
          'post:${p['platform']}:${p['age']}',
      if (l.cases.any((c) => c['crime'] == 'tax_evasion')) 'tax',
    ].where((s) => !l.marks.contains('scandal:$s')).toList();
    if (sources.isNotEmpty && rng.nextInt(100) < 25) {
      l.sceneQueue.add('scandal:${sources.first}');
    }
  }
  if (l.cancelledUntil != null && l.cancelledUntil == l.age) {
    l.sceneQueue.add('comeback');
  }
  return feed;
}

/// Yearly social income (18+): ad share and subscribers, plus the deal.
List<(String, int)> socialIncome(Life l) {
  if (l.age < 18) return const [];
  var ads = 0.0;
  for (final e in l.followers.entries) {
    ads += e.value / 1000 * platformById(e.key).payPer1k;
  }
  return [
    if (ads >= 1) ('Social media income', ads.round()),
    if (l.deal != null)
      ('Brand deal: ${l.deal!['brand']}', l.deal!['fee'] as int),
  ];
}

// ---------------- Scenes ----------------

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'fame',
  scene: true,
  choices: choices,
);

Storylet? socialScene(String id, List<String> args, Life l) {
  switch (id) {
    case 'brand_deal':
      if (l.deal != null) return null;
      final b = _brands[Random(l.seed + l.age).nextInt(_brands.length)];
      final fee = min(
        500000,
        (maxFollowers(l) * 0.02 + l.fame * 500).round() ~/ 100 * 100,
      );
      final years = 2 + Random(l.seed * 3 + l.age).nextInt(2);
      final conflict = l.stats[b.$3] < 30;
      void sign(Life l, int f) {
        l.deal = {
          'brand': b.$1,
          'image': b.$2,
          'fee': f,
          'until': l.age + years,
          'posts': 0,
        };
        if (conflict) {
          for (final k in l.followers.keys.toList()) {
            l.followers[k] = (l.followers[k]! * 0.95).round();
          }
        }
      }

      return _scene(
        id,
        '${b.$1} (${b.$2}) wants you as the face of their next campaign: ${_m(fee)} a year for $years years. The contract has a morality clause: a scandal and the deal ends, and you pay back this year\'s fee.${conflict ? ' Fans may not buy it: the brand does not fit your image.' : ''}',
        [
          Choice(
            label: 'Sign it',
            outcome: '',
            run: (l, rng) {
              sign(l, fee);
              return 'You signed with ${b.$1}. ${conflict ? 'Some fans called it fake and unfollowed.' : 'Your fans think it suits you.'}';
            },
          ),
          Choice(
            label: 'Negotiate for 30% more',
            outcome: '',
            risk: '50% they walk away',
            run: (l, rng) {
              if (rng.nextBool()) {
                sign(l, (fee * 1.3).round());
                return 'Your agent played hardball and won: ${_m((fee * 1.3).round())} a year.';
              }
              return '${b.$1} said thanks, but no thanks, and signed someone else.';
            },
          ),
          Choice(
            label: 'Turn it down',
            outcome: 'You decided your feed is not for sale.',
          ),
        ],
      );
    case 'scandal':
      final key = args.join(':');
      if (key.isEmpty || l.marks.contains('scandal:$key')) return null;
      final what = switch (args.first) {
        'affair' => 'your affair',
        'record' =>
          'your old conviction for ${crimeById(args.length > 1 ? args[1] : '').label.toLowerCase()}',
        'post' => 'a hot take you posted years ago',
        _ => 'questions about your taxes',
      };
      final severe = args.first == 'record' || args.first == 'affair';
      void land(Life l, int fameHit, double followersKept, int cancelYears) {
        l.marks.add('scandal:$key');
        l.fame = max(0, l.fame - fameHit);
        for (final k in l.followers.keys.toList()) {
          l.followers[k] = (l.followers[k]! * followersKept).round();
        }
        if (cancelYears > 0) {
          l.cancelledUntil = l.age + cancelYears;
          if (l.deal != null) {
            l.money -= l.deal!['fee'] as int;
            l.deal = null;
          }
        }
      }

      return _scene(
        id,
        'Your phone explodes at 6am. A gossip site has a story about $what, and it is trending. Your name is everywhere, and not in a good way.',
        [
          Choice(
            label: 'Apologise, sincerely',
            outcome: '',
            risk: 'It is true, so honesty helps',
            run: (l, rng) {
              land(l, 5, 0.92, severe ? 1 : 0);
              return 'You owned it, without excuses. Most people respected that. ${severe ? 'You stepped back for a year.' : 'It blew over in a week.'}';
            },
          ),
          Choice(
            label: 'Deny everything',
            outcome: '',
            risk: 'It is on record',
            run: (l, rng) {
              land(l, 15, 0.75, severe ? 3 : 1);
              return 'The receipts came out the next day. Denying it made it much worse. You are cancelled for a while.';
            },
          ),
          Choice(
            label: 'Go quiet',
            outcome: '',
            run: (l, rng) {
              land(l, 8, 0.85, severe ? 2 : 0);
              return 'You stayed off every platform until the internet found someone else to talk about.';
            },
          ),
          Choice(
            label: 'Hire a crisis PR firm (\$25,000)',
            outcome: '',
            needsMoney: 25000,
            risk: 'The softest landing',
            run: (l, rng) {
              l.money -= 25000;
              land(l, 3, 0.95, 0);
              return 'The PR team wrote a statement, booked a sympathetic interview and buried the story under a charity announcement. Expensive, and it worked.';
            },
          ),
          Choice(
            label: 'Double down',
            outcome: '',
            risk: 'Some fans love it; most do not',
            run: (l, rng) {
              land(l, 0, 0.7, severe ? 4 : 2);
              l.fame = min(100, l.fame + 5);
              l.stats.add('karma', -4);
              return 'You doubled down. Your name is louder than ever, and so are the people who cannot stand you.';
            },
          ),
        ],
      );
    case 'comeback':
      l.cancelledUntil = null;
      return _scene(
        id,
        'It has been quiet for a while. A producer calls: people are ready to hear from you again, if you have something real to say.',
        [
          Choice(
            label: 'A redemption interview',
            outcome: '',
            run: (l, rng) {
              l.fame = min(100, l.fame + 10);
              return 'You talked honestly for an hour. Clips went everywhere, and this time people were kind.';
            },
          ),
          Choice(
            label: 'A charity campaign',
            outcome: '',
            run: (l, rng) {
              l.fame = min(100, l.fame + 6);
              l.stats.add('karma', 5);
              return 'You raised money for something that matters and let the work speak for itself.';
            },
          ),
          Choice(
            label: 'A documentary about your life',
            outcome: '',
            run: (l, rng) {
              l.fame = min(100, l.fame + 12);
              l.money += 20000;
              return 'The documentary did well. Strangers stop you now to say they understand you better.';
            },
          ),
        ],
      );
  }
  return null;
}

final socialActions = <GameAction>[
  GameAction(
    id: 'post_online',
    label: 'Post on social media',
    category: 'Social',
    keywords: [
      'post',
      'social media',
      'online',
      'photo',
      'viral',
      'followers',
      'vybe',
      'lenso',
      'murmur',
    ],
    minAge: 13,
    screen: 'social',
    repeatable: true,
    priceNote: 'Opens your Social screen',
    run: (l, rng) => ActionResult('You open your apps.'),
  ),
];
