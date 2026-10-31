import 'dart:math';

import 'family.dart' show childrenOf;
import 'lifespan.dart';
import 'models.dart';
import 'recap.dart';
import 'pets.dart' show petsOf;
import 'profile.dart';

/// The meta loop (plan Social §9 and §10): achievements with visible
/// rules, collections across every life, three daily goals that earn
/// Sparks (earn-only, never sold), a forgiving streak with a weekly
/// freeze, and a weekly challenge whose past weeks stay free to replay.

// ---------------- Achievements ----------------

typedef Achievement = ({
  String id,
  String name,
  String tier,
  String category,
  String rule,
  bool secret,
  bool Function(Life l, Profile p) test,
});

const tierSparks = {'Common': 10, 'Uncommon': 25, 'Rare': 50, 'Legendary': 100};

bool _f(Life l, String flag) => l.flags.containsKey(flag);
bool _fp(Life l, String prefix) =>
    l.flags.keys.any((k) => k.startsWith(prefix));
int _maxFollowers(Life l) => l.followers.values.fold(0, max);

Achievement _a(
  String id,
  String name,
  String tier,
  String category,
  String rule,
  bool Function(Life l, Profile p) test, {
  bool secret = false,
}) => (
  id: id,
  name: name,
  tier: tier,
  category: category,
  rule: rule,
  secret: secret,
  test: test,
);

final achievements = <Achievement>[
  // Life stages
  _a(
    'first_steps',
    'First Steps',
    'Common',
    'Life stages',
    'Reach age 1',
    (l, p) => l.age >= 1,
  ),
  _a(
    'sweet_sixteen',
    'Sweet Sixteen',
    'Common',
    'Life stages',
    'Reach 16',
    (l, p) => l.age >= 16,
  ),
  _a(
    'adulting',
    'Adulting',
    'Common',
    'Life stages',
    'Reach 18',
    (l, p) => l.age >= 18,
  ),
  _a(
    'over_the_hill',
    'Over the Hill',
    'Uncommon',
    'Life stages',
    'Reach 50',
    (l, p) => l.age >= 50,
  ),
  _a(
    'golden',
    'Golden Years',
    'Uncommon',
    'Life stages',
    'Reach 80',
    (l, p) => l.age >= 80,
  ),
  _a(
    'century',
    'One Hundred',
    'Legendary',
    'Life stages',
    'Reach 100',
    (l, p) => l.age >= 100,
  ),
  // Education
  _a(
    'bookworm',
    'Bookworm',
    'Common',
    'Education',
    'Get a library card',
    (l, p) => _f(l, 'library_card'),
  ),
  _a(
    'honour_roll',
    'Honour Roll',
    'Uncommon',
    'Education',
    'GPA 3.5+ over three school years',
    (l, p) => l.school.gpaYears >= 3 && l.school.gpa >= 3.5,
  ),
  _a(
    'graduate',
    'Graduate',
    'Uncommon',
    'Education',
    'Earn a degree',
    (l, p) => l.school.degrees.isNotEmpty,
  ),
  _a(
    'doctorate',
    'Lifelong Learner',
    'Rare',
    'Education',
    'Earn two degrees',
    (l, p) => l.school.degrees.length >= 2,
  ),
  // Careers
  _a(
    'first_job',
    'First Paycheque',
    'Common',
    'Careers',
    'Get a job',
    (l, p) => l.job != null,
  ),
  _a(
    'moving_up',
    'Moving Up',
    'Uncommon',
    'Careers',
    'Get promoted twice',
    (l, p) => l.careerRank >= 2,
  ),
  _a(
    'top_ladder',
    'Top of the Ladder',
    'Rare',
    'Careers',
    'Reach the top of a career ladder',
    (l, p) => l.careerRank >= 3 || _f(l, 'top_of_career'),
  ),
  _a(
    'gold_watch',
    'Gold Watch',
    'Uncommon',
    'Careers',
    'Retire',
    (l, p) => l.retired,
  ),
  _a(
    'fired',
    'You\'re Fired',
    'Common',
    'Careers',
    'Get fired',
    (l, p) => _f(l, 'fired'),
  ),
  // Money
  _a(
    'rainy_day',
    'Rainy Day Fund',
    'Common',
    'Money',
    '\$10,000 in savings',
    (l, p) => l.savings >= 10000,
  ),
  _a(
    'shareholder',
    'Shareholder',
    'Common',
    'Money',
    'Own shares, bonds, gold or coins',
    (l, p) => l.shares.isNotEmpty,
  ),
  _a(
    'keys',
    'Keys in Hand',
    'Uncommon',
    'Money',
    'Buy a home',
    (l, p) => l.has('house'),
  ),
  _a(
    'founder',
    'Founder',
    'Uncommon',
    'Money',
    'Start a business',
    (l, p) => _f(l, 'founded_business'),
  ),
  _a(
    'excellent_credit',
    'Excellent Credit',
    'Uncommon',
    'Money',
    'Credit score 800+',
    (l, p) => (l.credit ?? 0) >= 800,
  ),
  _a(
    'landlord',
    'Landlord',
    'Rare',
    'Money',
    'Let a home to tenants',
    (l, p) => l.assets.any((a) => a.info['let'] == true),
  ),
  _a(
    'big_business',
    'Big Business',
    'Rare',
    'Money',
    'A business making \$100,000 in a year',
    (l, p) => (l.business?.profit ?? 0) >= 100000,
  ),
  _a(
    'millionaire',
    'Millionaire',
    'Rare',
    'Money',
    'Net worth of \$1,000,000',
    (l, p) => l.netWorth >= 1000000,
  ),
  _a(
    'upper_echelon',
    'Upper Echelon',
    'Legendary',
    'Money',
    'Join the richest people alive',
    (l, p) => _f(l, 'upper_echelon'),
    secret: true,
  ),
  _a(
    'three_commas',
    'Three Commas',
    'Legendary',
    'Money',
    'Become a billionaire',
    (l, p) => _f(l, 'billionaire'),
    secret: true,
  ),
  _a(
    'space_tourist',
    'Space Tourist',
    'Rare',
    'Money',
    'See the Earth from space',
    (l, p) => _f(l, 'astronaut'),
    secret: true,
  ),
  _a(
    'island_life',
    'Island Life',
    'Rare',
    'Money',
    'Own a private island',
    (l, p) => l.has('island'),
    secret: true,
  ),
  _a(
    'philanthropist',
    'Philanthropist',
    'Rare',
    'Money',
    'Start a foundation',
    (l, p) => l.marks.contains('foundation'),
    secret: true,
  ),
  _a(
    'clean_slate',
    'Clean Slate',
    'Uncommon',
    'Money',
    'Declare bankruptcy',
    (l, p) => _f(l, 'bankrupt'),
  ),
  // Love and family
  _a(
    'first_date',
    'First Date',
    'Common',
    'Love',
    'Start dating someone',
    (l, p) => _f(l, 'partner') || l.npcs.any((n) => n.circle == 'Partner'),
  ),
  _a(
    'knot',
    'Tied the Knot',
    'Uncommon',
    'Love',
    'Get married',
    (l, p) => _f(l, 'married'),
  ),
  _a(
    'again',
    'Again and Again',
    'Rare',
    'Love',
    'Renew your vows',
    (l, p) => _f(l, 'renewed_vows'),
  ),
  _a(
    'parent',
    'Parent',
    'Uncommon',
    'Family',
    'Have or adopt a child',
    (l, p) => childrenOf(l).isNotEmpty,
  ),
  _a(
    'full_house',
    'Full House',
    'Rare',
    'Family',
    'Four or more children',
    (l, p) => childrenOf(l).length >= 4,
  ),
  _a(
    'grandparent',
    'Grandparent',
    'Rare',
    'Family',
    'Become a grandparent',
    (l, p) => _f(l, 'grandparent'),
  ),
  _a(
    'next_gen',
    'Next Generation',
    'Rare',
    'Dynasty',
    'Continue as your child',
    (l, p) => l.generation >= 2,
  ),
  _a(
    'dynasty',
    'Dynasty',
    'Legendary',
    'Dynasty',
    'Reach Generation 4',
    (l, p) => l.generation >= 4,
  ),
  // Fame
  _a(
    'rising',
    'Rising',
    'Uncommon',
    'Fame',
    '10,000 followers on one platform',
    (l, p) => _maxFollowers(l) >= 10000,
  ),
  _a(
    'blue_tick',
    'Blue Tick',
    'Rare',
    'Fame',
    'Get verified',
    (l, p) => l.verified,
  ),
  _a(
    'million',
    'A Million Followers',
    'Legendary',
    'Fame',
    '1,000,000 followers on one platform',
    (l, p) => _maxFollowers(l) >= 1000000,
  ),
  _a(
    'cancelled',
    'Cancelled',
    'Uncommon',
    'Fame',
    'Survive a scandal',
    (l, p) => l.marks.any((m) => m.startsWith('scandal:')),
  ),
  // Crime
  _a(
    'sticky',
    'Sticky Fingers',
    'Common',
    'Crime',
    'Commit a crime',
    (l, p) =>
        l.cases.isNotEmpty ||
        l.record.isNotEmpty ||
        _f(l, 'caught_shoplifting'),
  ),
  _a(
    'jailbird',
    'Jailbird',
    'Uncommon',
    'Crime',
    'Go to prison',
    (l, p) => _f(l, 'prison'),
  ),
  _a(
    'not_guilty',
    'Not Guilty',
    'Rare',
    'Crime',
    'Win a trial',
    (l, p) => _f(l, 'acquitted'),
  ),
  _a(
    'parole',
    'Early Release',
    'Uncommon',
    'Crime',
    'Get parole',
    (l, p) => l.marks.any((m) => m.startsWith('parole_until:')),
  ),
  _a(
    'great_escape',
    'The Great Escape',
    'Legendary',
    'Crime',
    'Escape from prison',
    (l, p) => _f(l, 'escaped'),
  ),
  // Health
  _a(
    'brave',
    'Brave Enough to Ask',
    'Common',
    'Health',
    'Get support for your mental health',
    (l, p) =>
        l.conditions.any(
              (c) =>
                  c.id == 'depression' ||
                  c.id == 'anxiety' ||
                  c.id == 'grief' ||
                  c.id == 'insomnia',
            ) &&
            l.conditions.any((c) => c.treated) ||
        l.marks.any((m) => m.startsWith('recovered:')),
  ),
  _a(
    'fit',
    'Peak Fitness',
    'Uncommon',
    'Health',
    'Fitness 90+',
    (l, p) => l.fitness >= 90,
  ),
  _a(
    'marathon',
    'Marathoner',
    'Uncommon',
    'Health',
    'Run a marathon',
    (l, p) => _f(l, 'marathon'),
  ),
  _a(
    'recovery',
    'One Day at a Time',
    'Rare',
    'Health',
    'Recover from an addiction',
    (l, p) => _fp(l, 'recovery_'),
  ),
  _a(
    'survivor',
    'Survivor',
    'Rare',
    'Health',
    'Beat a serious illness',
    (l, p) => _fp(l, 'survived_'),
  ),
  // Pets
  _a(
    'best_friend',
    'Best Friend',
    'Common',
    'Pets',
    'Have a pet',
    (l, p) => l.npcs.any((n) => n.circle == 'Pets'),
  ),
  _a(
    'good_boy',
    'Good Boy',
    'Common',
    'Pets',
    'Teach a pet a trick',
    (l, p) => l.npcs.any(
      (n) =>
          n.circle == 'Pets' && (n.info['tricks'] as List?)?.isNotEmpty == true,
    ),
  ),
  _a(
    'saddle',
    'Saddle Up',
    'Uncommon',
    'Pets',
    'Own a horse',
    (l, p) =>
        l.npcs.any((n) => n.circle == 'Pets' && n.info['species'] == 'horse'),
  ),
  _a(
    'menagerie',
    'Menagerie',
    'Rare',
    'Pets',
    'Three kinds of pet at once',
    (l, p) => {for (final n in petsOf(l)) n.info['species']}.length >= 3,
  ),
  // Travel
  _a(
    'stamps',
    'Passport Stamps',
    'Common',
    'Travel',
    'Go on holiday abroad',
    (l, p) => _fp(l, 'visited_'),
  ),
  _a(
    'new_home',
    'New Home',
    'Uncommon',
    'Travel',
    'Move abroad',
    (l, p) => _f(l, 'emigrated'),
  ),
  _a(
    'citizen',
    'Citizen of the World',
    'Rare',
    'Travel',
    'Live in 3 countries',
    (l, p) => countriesLived(l) >= 3,
  ),
  // Community and identity
  _a(
    'neighbour',
    'Good Neighbour',
    'Common',
    'Community',
    'Welcome new neighbours',
    (l, p) => _f(l, 'good_neighbour'),
  ),
  _a(
    'pillar',
    'Pillar of the Community',
    'Rare',
    'Community',
    'Karma 90+',
    (l, p) => l.stats['karma'] >= 90,
  ),
  _a(
    'proud',
    'Proud',
    'Uncommon',
    'Identity',
    'Tell your family who you are',
    (l, p) => _f(l, 'came_out'),
  ),
  _a(
    'own_name',
    'A Name of My Own',
    'Uncommon',
    'Identity',
    'Change your legal name',
    (l, p) => _f(l, 'name_change'),
  ),
  // Oddities and challenges
  _a(
    'party',
    'Party of the Year',
    'Uncommon',
    'Oddities',
    'Throw a legendary party',
    (l, p) => _f(l, 'party_of_the_year'),
  ),
  _a(
    'idler',
    'Professional Idler',
    'Uncommon',
    'Oddities',
    '20 birthdays in a row doing nothing',
    (l, p) => l.idleYears >= 20,
  ),
  _a(
    'jackpot',
    'Jackpot',
    'Legendary',
    'Oddities',
    'Win the lottery',
    (l, p) => _f(l, 'jackpot'),
  ),
  _a(
    'front_page',
    'Front Page',
    'Legendary',
    'Oddities',
    'Something special happens at 100',
    (l, p) => _f(l, 'hundred'),
    secret: true,
  ),
  _a(
    'daily_habit',
    'Daily Habit',
    'Common',
    'Challenges',
    'Finish all three daily goals in a day',
    (l, p) => p.dailyBonusDays > 0,
  ),
  _a(
    'week_streak',
    'Week Streak',
    'Uncommon',
    'Challenges',
    'A 7-day streak',
    (l, p) => p.bestStreak >= 7,
  ),
  _a(
    'challenger',
    'Challenge Accepted',
    'Rare',
    'Challenges',
    'Finish a weekly challenge',
    (l, p) => p.challengesDone.isNotEmpty,
  ),
];

// ---------------- Collections ----------------

const collectionNames = {
  'careers': 'Careers worked',
  'countries': 'Countries lived in',
  'titles': 'Life Titles earned',
  'pets': 'Pets I\'ve loved',
  'causes': 'How lives ended',
  'stories': 'Stories seen',
  'challenges': 'Challenges finished',
};

void _collect(Profile p, String key, String value) {
  final list = p.collections.putIfAbsent(key, () => []);
  if (!list.contains(value)) list.add(value);
}

/// Checks a life against achievements and collections. Returns newly
/// earned achievement names (for the toast) and adds their Sparks.
List<String> checkMeta(Life l, Profile p, {Set<String> storyIds = const {}}) {
  final fresh = <String>[];
  for (final a in achievements) {
    if (p.achievements.containsKey(a.id)) continue;
    if (!a.test(l, p)) continue;
    p.achievements[a.id] = DateTime.now().toIso8601String().substring(0, 10);
    p.sparks += tierSparks[a.tier] ?? 10;
    fresh.add('${a.name} · +${tierSparks[a.tier]} Sparks');
  }
  if (l.job != null) _collect(p, 'careers', l.job!);
  for (final m in l.marks.where((m) => m.startsWith('lived:'))) {
    _collect(p, 'countries', m.substring(6));
  }
  for (final n in l.npcs.where(
    (n) => n.circle == 'Pets' && !n.alive && n.info['diedAge'] != null,
  )) {
    _collect(
      p,
      'pets',
      '${n.name} the ${n.role.toLowerCase()} (${n.info['diedAge']})',
    );
  }
  for (final id in l.lastSeen.keys) {
    if (storyIds.contains(id)) _collect(p, 'stories', id);
  }
  return fresh;
}

/// At the end of a life: its title, minor titles and how it ended.
void recordLifeEnd(Life l, Profile p) {
  if (l.marks.contains('meta_recorded')) return;
  l.marks.add('meta_recorded');
  _collect(p, 'titles', titleFor(l).name);
  for (final t in minorTitles(l)) {
    _collect(p, 'titles', t.name);
  }
  if (l.causeOfDeath != null && !l.endedEarly) {
    _collect(p, 'causes', l.causeOfDeath!);
  }
  final chaos = chaosIndex(l);
  l.marks.add('chaos_past:${p.chaosHistory.join(',')}');
  p.chaosHistory.add(chaos);
  if (p.chaosHistory.length > 200) p.chaosHistory.removeAt(0);
}

// ---------------- Daily goals, Sparks and streaks ----------------

typedef DailyGoal = ({String id, String text, int need, Set<String> events});

/// Events are counted by the controller: 'age', 'choice', 'crime',
/// 'post', `action:ID`, `category:NAME` and `interaction:CIRCLE`.
const dailyGoals = <DailyGoal>[
  (id: 'age5', text: 'Live 5 years', need: 5, events: {'age'}),
  (
    id: 'friend',
    text: 'Spend time with a friend',
    need: 1,
    events: {'interaction:Friends'},
  ),
  (
    id: 'family',
    text: 'Do something for your family',
    need: 1,
    events: {'interaction:Family', 'interaction:Children'},
  ),
  (
    id: 'love',
    text: 'Do something for someone you love',
    need: 1,
    events: {'interaction:Partner', 'action:go_out', 'action:kindling'},
  ),
  (
    id: 'exercise',
    text: 'Work out, walk or do yoga',
    need: 1,
    events: {'action:gym', 'action:walk', 'action:yoga'},
  ),
  (id: 'read', text: 'Read a book', need: 1, events: {'action:read'}),
  (id: 'post', text: 'Post on social media', need: 1, events: {'post'}),
  (
    id: 'pet',
    text: 'Look after a pet',
    need: 1,
    events: {'interaction:Pets', 'action:adopt_pet'},
  ),
  (
    id: 'choices',
    text: 'Make 3 choices in events',
    need: 3,
    events: {'choice'},
  ),
  (
    id: 'clean',
    text: 'Live 5 years without committing a crime',
    need: 5,
    events: {'age'},
  ),
  (id: 'shop', text: 'Go shopping', need: 1, events: {'action:shopping'}),
  (id: 'travel', text: 'Take a trip', need: 1, events: {'category:Travel'}),
  (
    id: 'learn',
    text: 'Study or practise a skill',
    need: 1,
    events: {
      'action:study',
      'action:instrument',
      'action:paint',
      'action:write_story',
    },
  ),
  (
    id: 'calm',
    text: 'Take a quiet moment',
    need: 1,
    events: {'action:meditate', 'action:reflect'},
  ),
];

String dayKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Three goals a day, the same for everyone on that date.
List<DailyGoal> goalsFor(DateTime d) {
  final r = Random(d.year * 1000 + d.month * 40 + d.day);
  final pool = dailyGoals.toList()..shuffle(r);
  return pool.take(3).toList();
}

void _ensureDay(Profile p, DateTime now) {
  final key = dayKey(now);
  if (p.daily['date'] == key) return;
  p.daily
    ..clear()
    ..addAll({'date': key, 'progress': <String, int>{}, 'done': <String>[]});
}

/// Counts an event toward today's goals. Returns finished goal texts.
List<String> trackGoal(Profile p, String event, DateTime now) {
  _ensureDay(p, now);
  final progress = Map<String, int>.from(p.daily['progress'] as Map);
  final done = List<String>.from(p.daily['done'] as List);
  final out = <String>[];
  for (final g in goalsFor(now)) {
    if (done.contains(g.id)) continue;
    if (g.id == 'clean' && event == 'crime') {
      progress[g.id] = 0;
      continue;
    }
    if (!g.events.contains(event)) continue;
    progress[g.id] = (progress[g.id] ?? 0) + 1;
    if (progress[g.id]! >= g.need) {
      done.add(g.id);
      p.sparks += 20;
      out.add('Goal done: ${g.text} · +20 Sparks');
      if (done.length == 3) {
        p.sparks += 50;
        p.dailyBonusDays++;
        out.add('All three goals today · +50 Sparks');
      }
    }
  }
  p.daily['progress'] = progress;
  p.daily['done'] = done;
  return out;
}

int goalProgress(Profile p, String id, DateTime now) {
  if (p.daily['date'] != dayKey(now)) return 0;
  return (Map<String, int>.from(p.daily['progress'] as Map))[id] ?? 0;
}

bool goalDone(Profile p, String id, DateTime now) =>
    p.daily['date'] == dayKey(now) &&
    List<String>.from(p.daily['done'] as List).contains(id);

String _weekKey(DateTime d) {
  // ISO-ish week: Monday-based, keyed by the Monday's date.
  final monday = d.subtract(Duration(days: d.weekday - 1));
  return dayKey(monday);
}

/// A day counts when you live at least one year. One free streak freeze
/// a week covers a missed day automatically (plan: forgiving streaks).
String? recordPlayDay(Profile p, DateTime now) {
  final today = dayKey(now);
  if (p.lastPlayDay == today) return null;
  final yesterday = dayKey(now.subtract(const Duration(days: 1)));
  final twoAgo = dayKey(now.subtract(const Duration(days: 2)));
  String? note;
  if (p.lastPlayDay == yesterday) {
    p.streak++;
  } else if (p.lastPlayDay == twoAgo && p.freezeWeek != _weekKey(now)) {
    p.freezeWeek = _weekKey(now);
    p.streak++;
    note = 'Streak freeze used: you missed a day, so your weekly freeze kept your streak alive.';
  } else {
    p.streak = 1;
  }
  p.lastPlayDay = today;
  p.bestStreak = max(p.bestStreak, p.streak);
  return note;
}

// ---------------- Weekly challenges ----------------

typedef ChallengeTask = ({String id, String text, bool Function(Life l) test});

final challengeTasks = <ChallengeTask>[
  (id: 'nurse', text: 'Become a nurse', test: (l) => l.careerId == 'nurse'),
  (
    id: 'teacher',
    text: 'Become a teacher',
    test: (l) => l.careerId == 'teacher',
  ),
  (
    id: 'adopt',
    text: 'Adopt a child',
    test: (l) => childrenOf(l).any((c) => c.info['adopted'] == true),
  ),
  (
    id: 'kids3',
    text: 'Have three children',
    test: (l) => childrenOf(l).length >= 3,
  ),
  (id: 'married', text: 'Get married', test: (l) => _f(l, 'married')),
  (
    id: 'degree',
    text: 'Earn a degree',
    test: (l) => l.school.degrees.isNotEmpty,
  ),
  (id: 'home', text: 'Buy a home', test: (l) => l.has('house')),
  (
    id: 'business',
    text: 'Run a profitable business',
    test: (l) => (l.business?.profit ?? 0) > 0,
  ),
  (
    id: 'verified',
    text: 'Get verified on social media',
    test: (l) => l.verified,
  ),
  (id: 'abroad', text: 'Move abroad', test: (l) => _f(l, 'emigrated')),
  (
    id: 'trick',
    text: 'Teach a pet a trick',
    test: (l) => l.npcs.any(
      (n) =>
          n.circle == 'Pets' && (n.info['tricks'] as List?)?.isNotEmpty == true,
    ),
  ),
  (id: 'acquitted', text: 'Win a trial', test: (l) => _f(l, 'acquitted')),
  (
    id: 'millionaire',
    text: 'Reach \$1,000,000 net worth',
    test: (l) => l.netWorth >= 1000000,
  ),
  (
    id: 'grandparent',
    text: 'Become a grandparent',
    test: (l) => _f(l, 'grandparent'),
  ),
  (id: 'marathon', text: 'Run a marathon', test: (l) => _f(l, 'marathon')),
  (
    id: 'top',
    text: 'Reach the top of a career ladder',
    test: (l) => l.careerRank >= 3,
  ),
  (id: 'live90', text: 'Live to 90', test: (l) => l.age >= 90),
  (
    id: 'saint',
    text: 'Die with Karma 80+',
    test: (l) => !l.alive && l.stats['karma'] >= 80,
  ),
  (
    id: 'neighbour',
    text: 'Be a good neighbour',
    test: (l) => _f(l, 'good_neighbour'),
  ),
  (
    id: 'volunteer',
    text: 'Help build the community garden',
    test: (l) => _f(l, 'garden_volunteer'),
  ),
];

String currentWeek(DateTime now) => _weekKey(now);

/// Four tasks a week, the same for everyone that week.
List<ChallengeTask> challengeFor(String week) {
  final r = Random(week.hashCode);
  return (challengeTasks.toList()..shuffle(r)).take(4).toList();
}

String challengeName(String week) {
  const names = [
    'Small Town Saint',
    'The Long Way Home',
    'Family First',
    'Big Dreams',
    'Second Chances',
    'Against the Odds',
    'Quiet Achiever',
    'The Full Life',
  ];
  return names[week.hashCode.abs() % names.length];
}

/// The last 8 weeks, newest first (the Archive is free).
List<String> archiveWeeks(DateTime now) => [
  for (var i = 1; i <= 8; i++) _weekKey(now.subtract(Duration(days: 7 * i))),
];

/// Counts tasks for the active challenge. Returns messages for new ticks.
List<String> trackChallenge(Profile p, Life l, DateTime now) {
  final week = p.activeWeek ?? currentWeek(now);
  final done = p.weeklyDone.putIfAbsent(week, () => []);
  final out = <String>[];
  for (final t in challengeFor(week)) {
    if (done.contains(t.id) || !t.test(l)) continue;
    done.add(t.id);
    out.add('Challenge task: ${t.text}');
    if (done.length == 4 && !p.challengesDone.contains(week)) {
      p.challengesDone.add(week);
      p.sparks += 100;
      _collect(p, 'challenges', challengeName(week));
      out.add('Challenge complete: ${challengeName(week)} · +100 Sparks');
    }
  }
  return out;
}
