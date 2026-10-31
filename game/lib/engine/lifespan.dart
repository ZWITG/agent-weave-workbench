import 'dart:math';

import 'careers.dart';
import 'jobs.dart' show leaveJob;
import 'health.dart' show conditionCause, healthRiskFactor;
import 'models.dart';

/// A whole life, birth to death (plan Modules 3 and 9): aging, a
/// Gompertz-style death check, frailty, retirement and pensions, life
/// chapters, Life Titles and seed codes.

// ---------------- Difficulty ----------------

const difficulties = <String, ({String label, String blurb, double death})>{
  'easy': (label: 'Easy', blurb: 'Gentler health and luck', death: 0.6),
  'normal': (label: 'Normal', blurb: 'The game as designed', death: 1.0),
  'hard': (label: 'Hard', blurb: 'Life is tougher', death: 1.5),
};

// ---------------- Aging and death ----------------

/// Yearly chance of dying of natural causes. Doubles about every 8 years
/// (Gompertz), scaled by health and difficulty.
double deathChance(Life life) {
  final base = 0.00002 * exp(0.085 * life.age);
  final health = life.stats['health'];
  final healthMult = (1 + (50 - health) / 25).clamp(0.3, 4.0);
  final diff = difficulties[life.difficulty]?.death ?? 1.0;
  return (base * healthMult * diff * healthRiskFactor(life)).clamp(0.0, 0.95);
}

/// Shown on the header and Me tab when the yearly risk gets serious.
bool isFrail(Life life) => life.age >= 60 && deathChance(life) >= 0.03;

String frailtyLabel(Life life) {
  final p = deathChance(life);
  if (p >= 0.15) return 'Very frail';
  if (p >= 0.06) return 'Frail';
  return 'Slowing down';
}

String causeOfDeath(Life life, Random rng) {
  // Serious illnesses always showed symptoms first (plan HE acceptance).
  final illness = conditionCause(life);
  if (illness != null) return illness;
  if (life.age < 40) {
    return const [
      'A road accident',
      'A sudden illness',
      'A swimming accident',
    ][rng.nextInt(3)];
  }
  const causes = [
    'Natural causes',
    'Heart failure',
    'A stroke',
    'Pneumonia',
    'A fall at home',
  ];
  return life.age >= 85
      ? causes[rng.nextInt(2)]
      : causes[rng.nextInt(causes.length)];
}

/// The body changes with age. Returns a feed line when something notable
/// happens.
String? ageBody(Life life, Random rng) {
  life.reason = 'Getting older';
  final a = life.age;
  if (a > 25 && a <= 40) life.stats.add('health', -rng.nextInt(2));
  if (a > 40) life.stats.add('health', -rng.nextInt(2) - (a > 60 ? 1 : 0));
  if (a > 75) life.stats.add('health', -rng.nextInt(2));
  if (a > 40) life.stats.add('looks', -rng.nextInt(2));
  if (a > 45) life.stats.add('fertility', -2);
  if (a > 30) life.stats.add('athleticism', -rng.nextInt(2));
  if (a == 40) return 'You turned 40. Your knees have started making noises.';
  if (a == 60) return 'Sixty. You have opinions about the weather now.';
  if (a == 80) return 'Eighty years. Every birthday cake is a fire hazard.';
  return null;
}

// ---------------- Work later in life ----------------

const statePensionAge = 67;
const statePension = 8000;

/// Retiring turns part of your salary into a yearly pension (at least the
/// state pension, more after 10+ working years).
/// Employer pension = 0.015 × years worked × final salary (plan), at least
/// the state pension.
String retire(Life life) {
  final years = life.yearsWorked;
  final earned = (0.015 * years * life.salary).round();
  life.pension = max(statePension, earned);
  final old = life.job;
  leaveJob(life);
  life.jobLostAge = null;
  life.retired = true;
  life.flags['retired'] = Memory(life.age, 'retiring');
  return 'You retired${old == null ? '' : ' from your job as $old'} after $years working years.';
}

// ---------------- Chapters ----------------

String chapterFor(Life life) {
  final a = life.age;
  if (a < 5) return 'First Steps';
  if (a < 12) return 'Small Adventures';
  if (a < 18) return 'Growing Up';
  if (a < 25) return studying(life) ? 'The Student Years' : 'Finding Your Way';
  if (a < 40) {
    if (life.job != null) return 'The ${life.job} Years';
    return 'Building a Life';
  }
  if (a < 60) return life.retired ? 'Early Freedom' : 'The Middle Years';
  if (a < 80) return 'The Golden Years';
  return 'The Long View';
}

// ---------------- Life Titles ----------------

class LifeTitle {
  const LifeTitle(
    this.id,
    this.name,
    this.rarity,
    this.why,
    this.progress,
    this.epitaph,
  );
  final String id;
  final String name;

  /// Common, Uncommon, Rare or Legendary.
  final String rarity;

  /// Transparent scoring: the rule, shown to the player.
  final String why;

  /// 0..1 toward the rule; 1 means earned (plan: scores, "Almost").
  final double Function(Life life) progress;
  final String epitaph;

  bool test(Life life) => progress(life) >= 1;
}

bool _flag(Life l, String f) => l.flags.containsKey(f);
int _people(Life l, String circle) =>
    l.npcs.where((n) => n.circle == circle).length;
double _p(num have, num need) => need <= 0 ? 1 : (have / need).clamp(0, 1);
double _b(bool v) => v ? 1 : 0;

int countriesLived(Life l) =>
    l.marks.where((m) => m.startsWith('lived:')).length;

int prisonYears(Life l) => l.record.fold(0, (a, r) {
  final m = RegExp(r'^(\d+) years?$').firstMatch('${r['sentence']}');
  return a + (m == null ? 0 : int.parse(m.group(1)!));
});

int speciesOwned(Life l) =>
    {for (final n in l.npcs.where((n) => n.circle == 'Pets')) n.info['species']}
        .length;

int maxFollowersOf(Life l) => l.followers.values.fold(0, max);

/// The titles, with their rules. Ties go to the rarer title, then to the
/// earlier one in this list.
final lifeTitles = <LifeTitle>[
  LifeTitle(
    'centenarian',
    'The Centenarian',
    'Legendary',
    'Lived to 100 or more',
    (l) => _p(l.age, 100),
    'A hundred candles, and every one earned.',
  ),
  LifeTitle(
    'legend',
    'The Legend',
    'Legendary',
    'Fame 90 or more',
    (l) => _p(l.fame, 90),
    'The world will not forget this one.',
  ),
  LifeTitle(
    'escape',
    'The Escape Artist',
    'Legendary',
    'Escaped from prison',
    (l) => _b(_flag(l, 'escaped')),
    'No walls could hold them. Literally.',
  ),
  LifeTitle(
    'tycoon',
    'The Tycoon',
    'Rare',
    'Net worth of \$1,000,000 or more',
    (l) => _p(l.netWorth, 1000000),
    'Built a fortune. Spent some of it wisely.',
  ),
  LifeTitle(
    'saint',
    'The Saint',
    'Rare',
    'Karma 90 or more',
    (l) => _p(l.stats['karma'], 90),
    'Kind to everyone, even on Mondays.',
  ),
  LifeTitle(
    'comeback',
    'The Comeback',
    'Rare',
    'From prison or bankruptcy to \$250,000 net worth',
    (l) =>
        _flag(l, 'prison') || _flag(l, 'bankrupt') ? _p(l.netWorth, 250000) : 0,
    'Fell all the way down. Climbed all the way back.',
  ),
  LifeTitle(
    'star',
    'The Star',
    'Rare',
    'Fame 80 or more',
    (l) => _p(l.fame, 80),
    'The world knew their name.',
  ),
  LifeTitle(
    'influencer',
    'The Influencer',
    'Rare',
    '1,000,000 followers on one platform',
    (l) => _p(maxFollowersOf(l), 1000000),
    'Posted it. Millions saw it.',
  ),
  LifeTitle(
    'shooting_star',
    'The Shooting Star',
    'Rare',
    'Died before 30 with Fame 50+',
    (l) => !l.alive && l.age < 30 ? _p(l.fame, 50) : 0,
    'Burned bright, burned fast.',
  ),
  LifeTitle(
    'outlaw',
    'The Outlaw',
    'Rare',
    'Arrested and Karma under 20',
    (l) => _b(_flag(l, 'arrested') && l.stats['karma'] < 20),
    'Lived by their own rules. The police had others.',
  ),
  LifeTitle(
    'inmate',
    'The Inmate',
    'Rare',
    '10 or more years in prison',
    (l) => _p(prisonYears(l), 10),
    'Did the time. Every day of it.',
  ),
  LifeTitle(
    'wanderer',
    'The Wanderer',
    'Rare',
    'Lived in 3 or more countries',
    (l) => _p(countriesLived(l), 3),
    'Home was wherever the bags were.',
  ),
  LifeTitle(
    'founder',
    'The Founder',
    'Rare',
    'A business making \$100,000 a year, or sold one',
    (l) => _flag(l, 'sold_business')
        ? 1
        : _p(l.businesses.fold(0, (s, b) => s + b.profit), 100000),
    'Started with a napkin sketch.',
  ),
  LifeTitle(
    'lucky',
    'The Lucky One',
    'Rare',
    'Won the lottery jackpot',
    (l) => _b(_flag(l, 'jackpot')),
    'The odds were 1 in 10,000. So what?',
  ),
  LifeTitle(
    'chief',
    'The Chief',
    'Rare',
    'Reached the top of a career ladder',
    (l) => _flag(l, 'top_of_career') ? 1 : _p(l.careerRank, 3),
    'Started at the bottom. Did not stay there.',
  ),
  LifeTitle(
    'menagerie',
    'The Menagerie',
    'Uncommon',
    'Owned 4 or more kinds of animal',
    (l) => _p(speciesOwned(l), 4),
    'Never knowingly under-petted.',
  ),
  LifeTitle(
    'mogul',
    'The Restaurateur',
    'Uncommon',
    'Owned a restaurant',
    (l) => _b(
      l.job == 'Restaurant owner' ||
          _flag(l, 'owned_restaurant') ||
          l.businesses.any((b) => b.industry == 'restaurant'),
    ),
    'Fed a city, one plate at a time.',
  ),
  LifeTitle(
    'scholar',
    'The Scholar',
    'Uncommon',
    'A degree and Smarts 85+',
    (l) => l.school.degrees.isNotEmpty || l.education == 'graduate'
        ? _p(l.stats['smarts'], 85)
        : 0,
    'Never stopped asking why.',
  ),
  LifeTitle(
    'family',
    'The Family Rock',
    'Uncommon',
    '3+ children and a partner',
    (l) => _people(l, 'Partner') >= 1 ? _p(_people(l, 'Children'), 3) : 0,
    'Held everyone together. Usually with snacks.',
  ),
  LifeTitle(
    'romantic',
    'The Romantic',
    'Uncommon',
    'Married for love',
    (l) => _b(_flag(l, 'married')),
    'Said yes, and meant it.',
  ),
  LifeTitle(
    'heartbreaker',
    'The Heartbreaker',
    'Uncommon',
    '3 or more exes',
    (l) => _p(_people(l, 'Exes'), 3),
    'Loved often. Left a trail of playlists.',
  ),
  LifeTitle(
    'gambler',
    'The Gambler',
    'Uncommon',
    'Lived with a gambling habit',
    (l) => _b(_flag(l, 'addiction_gambling')),
    'Always one more hand.',
  ),
  LifeTitle(
    'athlete',
    'The Athlete',
    'Uncommon',
    'Athleticism 90 or more',
    (l) => _p(l.stats['athleticism'], 90),
    'Ran further than anyone expected.',
  ),
  LifeTitle(
    'artist',
    'The Artist',
    'Uncommon',
    'Creativity 90 or more',
    (l) => _p(l.stats['creativity'], 90),
    'Made the world a little more interesting.',
  ),
  LifeTitle(
    'traveller',
    'The Traveller',
    'Uncommon',
    'Travelled abroad 3 or more times',
    (l) => _p(l.flags.keys.where((k) => k.startsWith('visited_')).length, 3),
    'Collected stamps and stories.',
  ),
  LifeTitle(
    'healer',
    'The Healer',
    'Uncommon',
    'Worked in healthcare',
    (l) => _b(
      const {'nurse', 'doctor', 'vet'}.contains(l.careerId) ||
          _flag(l, 'healthcare_career'),
    ),
    'Spent a life looking after others.',
  ),
  LifeTitle(
    'teacher',
    'The Teacher',
    'Uncommon',
    'Worked in education',
    (l) => _b(l.careerId == 'teacher' || _flag(l, 'teaching_career')),
    'Somewhere, someone still remembers the lesson.',
  ),
  LifeTitle(
    'loyal',
    'The Loyal Friend',
    'Uncommon',
    'A friend at Bond 85% or more',
    (l) => _p(
      l.npcs
          .where((n) => n.circle == 'Friends')
          .fold(0, (a, n) => max(a, n.bond)),
      85,
    ),
    'Showed up. Every time.',
  ),
  LifeTitle(
    'idler',
    'The Idler',
    'Uncommon',
    '20 years in a row without doing anything',
    (l) => _p(l.idleYears, 20),
    'Watched the world go by. The world waved back.',
  ),
  LifeTitle(
    'rebel',
    'The Rebel',
    'Common',
    'Got into trouble at school or with the law',
    (l) => _b(
      _flag(l, 'caught_shoplifting') ||
          _flag(l, 'expelled') ||
          _flag(l, 'snuck_out') ||
          l.record.isNotEmpty,
    ),
    'Asked forgiveness, never permission.',
  ),
  LifeTitle(
    'saver',
    'The Saver',
    'Common',
    '\$50,000+ in savings and investments',
    (l) => _p(l.savings + l.invested + l.portfolioValue, 50000),
    'Put something aside for a rainy day. It rained.',
  ),
  LifeTitle(
    'debtor',
    'The Borrower',
    'Common',
    'Died owing \$50,000 or more',
    (l) => _p(l.totalDebt, 50000),
    'Lived for today. The bank lived for tomorrow.',
  ),
  LifeTitle(
    'happy',
    'The Content One',
    'Common',
    'Happiness 85 or more at the end',
    (l) => _p(l.stats['happiness'], 85),
    'Happy, and knew it.',
  ),
  LifeTitle(
    'brief',
    'The Brief Flame',
    'Common',
    'Died before 30',
    (l) => _b(!l.alive && l.age < 30 && !l.endedEarly),
    'Gone too soon, remembered long.',
  ),
  LifeTitle(
    'survivor',
    'The Survivor',
    'Common',
    'Lived past 80',
    (l) => _p(l.age, 80),
    'Outlasted the doubters.',
  ),
  LifeTitle(
    'quiet',
    'The Quiet Life',
    'Common',
    'Every life earns at least this',
    (l) => 1,
    'A good life, quietly lived.',
  ),
];

const _rarityRank = {'Legendary': 0, 'Rare': 1, 'Uncommon': 2, 'Common': 3};

/// Earned titles, best first (rarer first, then list order).
List<LifeTitle> earnedTitles(Life life) {
  final earned = [
    for (final t in lifeTitles)
      if (t.test(life)) t,
  ];
  earned.sort((a, b) {
    final r = _rarityRank[a.rarity]!.compareTo(_rarityRank[b.rarity]!);
    return r != 0 ? r : lifeTitles.indexOf(a).compareTo(lifeTitles.indexOf(b));
  });
  return earned;
}

/// The main Life Title (plan: one main title).
LifeTitle titleFor(Life life) => earnedTitles(life).first;

/// Up to two minor titles after the main one (never The Quiet Life).
List<LifeTitle> minorTitles(Life life) =>
    earnedTitles(life).skip(1).where((t) => t.id != 'quiet').take(2).toList();

/// The best title not yet earned at 60%+ ("Almost: The Saint 54/60"
/// teaches the system).
(LifeTitle, double)? almostTitle(Life life) {
  (LifeTitle, double)? best;
  for (final t in lifeTitles) {
    final p = t.progress(life);
    if (p >= 0.6 && p < 1 && (best == null || p > best.$2)) best = (t, p);
  }
  return best;
}

// ---------------- Seed codes ----------------

/// "#RL-1A2B3C": share it and someone else can live the same start.
String seedCode(int seed) =>
    '#RL-${seed.toRadixString(36).toUpperCase().padLeft(6, '0')}';

int? parseSeedCode(String code) {
  final c = code
      .trim()
      .toUpperCase()
      .replaceFirst('#', '')
      .replaceFirst('RL-', '');
  if (c.isEmpty || !RegExp(r'^[0-9A-Z]+$').hasMatch(c)) return null;
  return int.tryParse(c.toLowerCase(), radix: 36);
}

/// The same seed for every player today.
int dailySeed(DateTime d) =>
    (d.year * 10000 + d.month * 100 + d.day) * 7919 % 0x7fffffff;
