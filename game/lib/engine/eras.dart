/// Era rules (Legends plan §5), loaded from `assets/eras/<era>.json`:
/// regions, money, wages and prices, jobs, school, justice, health and the
/// news format of a historical era. Timeline lives use these instead of
/// the modern systems, so nothing from 2026 leaks into 1450.
library;

import 'dart:math';

import 'currency.dart';
import 'models.dart';
import 'storylet.dart';
import 'timeline.dart';

/// Every era file in assets/eras, in load order.
const eraFiles = ['renaissance.json'];

/// Loaded eras by id; filled by the game controller (and tests).
final Map<String, EraRules> eraRegistry = {};

/// Adds an era to the registry and its regions' money to currency.dart.
EraRules registerEra(EraRules era) {
  eraRegistry[era.id] = era;
  for (final r in era.regions) {
    eraCurrencies[r.name] = (1, era.symbol);
  }
  return era;
}

class EraRegion {
  EraRegion({
    required this.id,
    required this.name,
    required this.cities,
    this.male = const [],
    this.female = const [],
    this.surnames = const [],
  });
  final String id;
  final String name;
  final List<String> cities;
  final List<String> male;
  final List<String> female;
  final List<String> surnames;

  factory EraRegion.fromJson(Map<String, dynamic> j) => EraRegion(
    id: j['id'],
    name: j['name'],
    cities: List<String>.from(j['cities'] ?? const []),
    male: List<String>.from(j['male'] ?? const []),
    female: List<String>.from(j['female'] ?? const []),
    surnames: List<String>.from(j['surnames'] ?? const []),
  );
}

class EraJob {
  EraJob(this.title, this.pay, {this.minAge = 14, this.needs = const {}});
  final String title;

  /// Yearly pay in the era currency.
  final int pay;
  final int minAge;
  final Map<String, String> needs;

  factory EraJob.fromJson(Map<String, dynamic> j) => EraJob(
    j['title'],
    j['pay'] ?? 0,
    minAge: j['minAge'] ?? 14,
    needs: Map<String, String>.from(j['needs'] ?? const {}),
  );
}

class EraRules {
  EraRules({
    required this.id,
    required this.name,
    required this.from,
    required this.to,
    required this.currency,
    required this.symbol,
    required this.regions,
    this.prices = const {},
    this.jobs = const [],
    this.school = const [],
    this.crimes = const {},
    this.lifeExpectancy = 48,
    this.plagueChance = 0.02,
    this.newsName = 'Avvisi',
    this.headlines = const {},
    this.quietYears = const [],
    this.anachronisms = const [],
    this.storylets = const [],
  });

  /// Everyday events of the era, for every timeline life in it.
  final List<Storylet> storylets;

  final String id;
  final String name;
  final int from;
  final int to;

  /// "florin" and "ƒ".
  final String currency;
  final String symbol;
  final List<EraRegion> regions;

  /// Item -> price in the era currency ("bread_year", "horse", "house").
  final Map<String, int> prices;
  final List<EraJob> jobs;

  /// School stages open to a child ("abacus school", "workshop").
  final List<String> school;

  /// Crime -> sentence ("theft" -> "the Stinche, 1 year").
  final Map<String, String> crimes;
  final int lifeExpectancy;
  final double plagueChance;

  /// The era's newsletter ("Avvisi") and its headlines by year.
  final String newsName;
  final Map<int, List<String>> headlines;
  final List<String> quietYears;

  /// Words that must never appear in this era (tests check the feed).
  final List<String> anachronisms;

  EraRegion region(String id) =>
      regions.firstWhere((r) => r.id == id, orElse: () => regions.first);

  /// The region a city belongs to.
  EraRegion regionOfCity(String city) => regions.firstWhere(
    (r) => r.cities.contains(city),
    orElse: () => regions.first,
  );

  factory EraRules.fromJson(Map<String, dynamic> j) {
    final years = List<int>.from(j['years']);
    final health = Map<String, dynamic>.from(j['health'] ?? const {});
    final news = Map<String, dynamic>.from(j['news'] ?? const {});
    final money = Map<String, dynamic>.from(j['money'] ?? const {});
    return EraRules(
      id: j['id'],
      name: j['name'],
      from: years.first,
      to: years.last,
      currency: money['name'] ?? 'florin',
      symbol: money['symbol'] ?? 'ƒ',
      prices: Map<String, int>.from(money['prices'] ?? const {}),
      regions: [
        for (final r in j['regions'] as List)
          EraRegion.fromJson(Map<String, dynamic>.from(r)),
      ],
      jobs: [
        for (final r in (j['jobs'] as List?) ?? const [])
          EraJob.fromJson(Map<String, dynamic>.from(r)),
      ],
      school: List<String>.from(j['school'] ?? const []),
      crimes: Map<String, String>.from(j['justice'] ?? const {}),
      lifeExpectancy: health['lifeExpectancy'] ?? 48,
      plagueChance: ((health['plague'] as num?) ?? 0.02).toDouble(),
      newsName: news['name'] ?? 'Avvisi',
      headlines: {
        for (final e in Map<String, dynamic>.from(
          news['headlines'] ?? const {},
        ).entries)
          int.parse(e.key): List<String>.from(e.value),
      },
      quietYears: List<String>.from(news['quiet'] ?? const []),
      anachronisms: List<String>.from(j['anachronisms'] ?? const []),
      storylets: [
        for (final s in (j['events'] as List?) ?? const [])
          Storylet.fromJson({'era': j['id'], ...Map<String, dynamic>.from(s)}),
      ],
    );
  }
}

/// The era's money, e.g. "ƒ 1,200".
String eraMoney(EraRules era, int amount) {
  final s = amount.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${amount < 0 ? '−' : ''}${era.symbol} $s';
}

/// One year of the era world for a timeline life: pay, the year's news and
/// plague. Returns feed lines. Modern systems never run here.
List<String> eraYear(Life life, EraRules era, Timeline t, Random rng) {
  final out = <String>[];
  t.advanceTo(life.year);
  if (life.job != null && life.salary > 0) {
    life.money += life.salary;
    life.lastYear = [(life.job!, life.salary)];
  } else {
    life.lastYear = [];
  }
  // A modest cost of living from 16, scaled by the era's prices.
  if (life.age >= 16) {
    final bread = era.prices['living_year'] ?? 0;
    if (bread > 0) {
      final paid = min(bread, max(0, life.money));
      life.money -= paid;
      if (paid > 0) life.lastYear.add(('Living', -paid));
    }
  }
  final news = era.headlines[life.year];
  if (news != null && news.isNotEmpty && life.age >= 6) {
    out.add('${era.newsName}: ${news[rng.nextInt(news.length)]}');
  }
  if (rng.nextDouble() < era.plagueChance) {
    life.reason = 'Plague year';
    life.stats.add('health', -(8 + rng.nextInt(12)));
    life.stats.add('happiness', -6);
    out.add('Plague came to ${life.city}. Shops closed and carts went past at night.');
  }
  return out;
}

/// Chance of dying this year in the era: harsher than today, and worse
/// with poor health.
double eraDeathChance(Life life, EraRules era) {
  final a = life.age;
  final shift = (era.lifeExpectancy - 48) / 2;
  double base;
  if (a < 5) {
    base = 0.015;
  } else if (a < 40 + shift) {
    base = 0.006;
  } else if (a < 55 + shift) {
    base = 0.018;
  } else if (a < 70 + shift) {
    base = 0.05;
  } else {
    base = 0.12 + (a - 70 - shift) * 0.01;
  }
  final h = life.stats['health'];
  if (h < 30) base *= 2.2;
  if (h > 75) base *= 0.6;
  return base.clamp(0.0, 0.6);
}
