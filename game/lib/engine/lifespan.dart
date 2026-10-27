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
    this.test,
    this.epitaph,
  );
  final String id;
  final String name;

  /// Common, Uncommon, Rare or Legendary.
  final String rarity;

  /// Transparent scoring: the rule, shown to the player.
  final String why;
  final bool Function(Life life) test;
  final String epitaph;
}

bool _flag(Life l, String f) => l.flags.containsKey(f);
int _people(Life l, String circle) =>
    l.npcs.where((n) => n.circle == circle).length;

/// 25 titles, checked in order; the first that matches is awarded.
final lifeTitles = <LifeTitle>[
  LifeTitle(
    'centenarian',
    'The Centenarian',
    'Legendary',
    'Lived to 100 or more',
    (l) => l.age >= 100,
    'A hundred candles, and every one earned.',
  ),
  LifeTitle(
    'tycoon',
    'The Tycoon',
    'Rare',
    'Net worth of \$1,000,000 or more',
    (l) => l.netWorth >= 1000000,
    'Built a fortune. Spent some of it wisely.',
  ),
  LifeTitle(
    'saint',
    'The Saint',
    'Rare',
    'Karma 90 or more',
    (l) => l.stats['karma'] >= 90,
    'Kind to everyone, even on Mondays.',
  ),
  LifeTitle(
    'outlaw',
    'The Outlaw',
    'Rare',
    'Arrested and Karma under 20',
    (l) => _flag(l, 'arrested') && l.stats['karma'] < 20,
    'Lived by their own rules. The police had others.',
  ),
  LifeTitle(
    'mogul',
    'The Restaurateur',
    'Uncommon',
    'Owned a restaurant',
    (l) => l.job == 'Restaurant owner' || _flag(l, 'owned_restaurant'),
    'Fed a city, one plate at a time.',
  ),
  LifeTitle(
    'chief',
    'The Chief',
    'Rare',
    'Reached the top of a career ladder',
    (l) => l.careerRank >= 3 || _flag(l, 'top_of_career'),
    'Started at the bottom. Did not stay there.',
  ),
  LifeTitle(
    'scholar',
    'The Scholar',
    'Uncommon',
    'University degree and Smarts 85+',
    (l) => l.education == 'graduate' && l.stats['smarts'] >= 85,
    'Never stopped asking why.',
  ),
  LifeTitle(
    'family',
    'The Family Rock',
    'Uncommon',
    '3+ children and a partner',
    (l) => _people(l, 'Children') >= 3 && _people(l, 'Partner') >= 1,
    'Held everyone together. Usually with snacks.',
  ),
  LifeTitle(
    'romantic',
    'The Romantic',
    'Uncommon',
    'Married for love',
    (l) => _flag(l, 'married'),
    'Said yes, and meant it.',
  ),
  LifeTitle(
    'heartbreaker',
    'The Heartbreaker',
    'Uncommon',
    '3 or more exes',
    (l) => _people(l, 'Exes') >= 3,
    'Loved often. Left a trail of playlists.',
  ),
  LifeTitle(
    'star',
    'The Star',
    'Rare',
    'Fame 80 or more',
    (l) => (l.stats.values['fame'] ?? 0) >= 80,
    'The world knew their name.',
  ),
  LifeTitle(
    'lucky',
    'The Lucky One',
    'Rare',
    'Won the lottery jackpot',
    (l) => _flag(l, 'jackpot'),
    'The odds were 1 in 10,000. So what?',
  ),
  LifeTitle(
    'athlete',
    'The Athlete',
    'Uncommon',
    'Athleticism 90 or more',
    (l) => l.stats['athleticism'] >= 90,
    'Ran further than anyone expected.',
  ),
  LifeTitle(
    'artist',
    'The Artist',
    'Uncommon',
    'Creativity 90 or more',
    (l) => l.stats['creativity'] >= 90,
    'Made the world a little more interesting.',
  ),
  LifeTitle(
    'wanderer',
    'The Wanderer',
    'Uncommon',
    'Travelled 3 or more times',
    (l) =>
        l.lastSeen.keys.where((k) => k.startsWith('travel')).length >= 3 ||
        _flag(l, 'wanderer'),
    'Home was wherever the bags were.',
  ),
  LifeTitle(
    'healer',
    'The Healer',
    'Uncommon',
    'Worked in healthcare',
    (l) => l.careerId == 'nurse' || _flag(l, 'healthcare_career'),
    'Spent a life looking after others.',
  ),
  LifeTitle(
    'teacher',
    'The Teacher',
    'Uncommon',
    'Worked in education',
    (l) => l.careerId == 'teacher' || _flag(l, 'teaching_career'),
    'Somewhere, someone still remembers the lesson.',
  ),
  LifeTitle(
    'loyal',
    'The Loyal Friend',
    'Uncommon',
    'A friend at Bond 85% or more',
    (l) => l.npcs.any((n) => n.circle == 'Friends' && n.bond >= 85),
    'Showed up. Every time.',
  ),
  LifeTitle(
    'rebel',
    'The Rebel',
    'Common',
    'Got into trouble at school or with the law',
    (l) =>
        _flag(l, 'caught_shoplifting') ||
        _flag(l, 'expelled') ||
        _flag(l, 'snuck_out'),
    'Asked forgiveness, never permission.',
  ),
  LifeTitle(
    'saver',
    'The Saver',
    'Common',
    '\$50,000+ in savings and investments',
    (l) => l.savings + l.invested >= 50000,
    'Put something aside for a rainy day. It rained.',
  ),
  LifeTitle(
    'debtor',
    'The Borrower',
    'Common',
    'Died owing \$50,000 or more',
    (l) => l.totalDebt >= 50000,
    'Lived for today. The bank lived for tomorrow.',
  ),
  LifeTitle(
    'happy',
    'The Content One',
    'Common',
    'Happiness 85 or more at the end',
    (l) => l.stats['happiness'] >= 85,
    'Happy, and knew it.',
  ),
  LifeTitle(
    'brief',
    'The Brief Flame',
    'Common',
    'Died before 30',
    (l) => !l.alive && l.age < 30,
    'Gone too soon, remembered long.',
  ),
  LifeTitle(
    'survivor',
    'The Survivor',
    'Common',
    'Lived past 80',
    (l) => l.age >= 80,
    'Outlasted the doubters.',
  ),
  LifeTitle(
    'quiet',
    'The Quiet Life',
    'Common',
    'Every life earns at least this',
    (l) => true,
    'A good life, quietly lived.',
  ),
];

LifeTitle titleFor(Life life) => lifeTitles.firstWhere((t) => t.test(life));

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
