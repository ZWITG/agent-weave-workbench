/// Era rules (Legends plan §5), loaded from `assets/eras/<era>.json`:
/// regions, money, wages and prices, jobs, school, justice, health and the
/// news format of a historical era. Timeline lives use these instead of
/// the modern systems, so nothing from 2026 leaks into 1450.
library;

import 'dart:math';

import 'currency.dart';
import 'era_faith.dart';
import 'era_health.dart';
import 'era_homes.dart';
import 'era_houses.dart';
import 'era_justice.dart';
import 'era_news.dart';
import 'era_path.dart';
import 'era_people.dart';
import 'era_wealth.dart';
import 'models.dart';
import 'storylet.dart';
import 'timeline.dart';

/// Every era file in assets/eras, in load order.
const eraFiles = ['renaissance.json'];

/// Loaded eras by id; filled by the game controller (and tests).
final Map<String, EraRules> eraRegistry = {};

/// Adds an era to the registry and its regions' money to currency.dart,
/// under every name a region has had.
EraRules registerEra(EraRules era) {
  eraRegistry[era.id] = era;
  for (final r in era.regions) {
    for (final name in {r.name, ...r.names.values}) {
      final c = era.currencies[r.currency];
      eraCurrencies[name] = (c?.rate ?? 1, c?.symbol ?? era.symbol);
      if (c?.format == 'lsd') eraFormats[name] = lsdMoney;
    }
  }
  return era;
}

/// One of the era's moneys. Amounts are always kept in gold florins;
/// [rate] is how many of this money make a florin.
class EraCurrency {
  const EraCurrency(this.id, this.symbol, this.rate, this.name, [this.format]);
  final String id;
  final String symbol;
  final double rate;
  final String name;

  /// 'lsd' for English pounds, shillings and pence.
  final String? format;
}

/// A city, with the years it exists in this world (Valletta from 1566).
class EraCity {
  const EraCity(this.name, {this.from, this.to});
  final String name;
  final int? from;
  final int? to;
  bool openIn(int year) =>
      (from == null || year >= from!) && (to == null || year <= to!);

  factory EraCity.fromJson(Object j) => j is String
      ? EraCity(j)
      : EraCity(
          (j as Map)['name'],
          from: j['from'] as int?,
          to: j['to'] as int?,
        );
}

/// Who ruled a region from one year to another.
class EraRuler {
  const EraRuler(this.from, this.to, this.ruler);
  final int from;
  final int to;
  final String ruler;
}

class EraRegion {
  EraRegion({
    required this.id,
    required this.name,
    required this.cityList,
    this.names = const {},
    this.male = const [],
    this.female = const [],
    this.surnames = const [],
    this.namesFrom = const {},
    this.group = '',
    this.lat = 0,
    this.lon = 0,
    this.currency = 'florin',
    this.currencies = const {},
    this.priceScale = 1,
    this.wageScale = 1,
    this.faiths = const {},
    this.language = '',
    this.rulers = const [],
    this.from,
  });
  final String id;

  /// The region's first name ("Republic of Florence").
  final String name;

  /// Its name from a year on ("Grand Duchy of Tuscany" from 1569).
  final Map<int, String> names;
  final List<EraCity> cityList;
  final List<String> male;
  final List<String> female;
  final List<String> surnames;

  /// Extra given names from a year on (baptismal names in Kongo from 1491).
  final Map<int, ({List<String> male, List<String> female})> namesFrom;

  /// Neighbourhood for journeys: 'italy', 'england', 'maghreb', 'sahel'...
  final String group;
  final double lat;
  final double lon;

  /// The money used, and changes of money by year.
  final String currency;
  final Map<int, String> currencies;

  /// Prices and wages against Florence.
  final double priceScale;
  final double wageScale;
  final Map<int, String> faiths;
  final String language;
  final List<EraRuler> rulers;

  /// The first year the region exists (Portuguese Luanda from 1576).
  final int? from;

  /// Every city ever in the region.
  List<String> get cities => [for (final c in cityList) c.name];

  /// The cities that exist in [year].
  List<String> citiesIn(int year) => [
    for (final c in cityList)
      if (c.openIn(year)) c.name,
  ];

  bool openIn(int year) => from == null || year >= from!;

  static T? _byYear<T>(Map<int, T> m, int year) {
    T? out;
    for (final k in m.keys.toList()..sort()) {
      if (k <= year) out = m[k];
    }
    return out;
  }

  String nameIn(int year) => _byYear(names, year) ?? name;
  String currencyIn(int year) => _byYear(currencies, year) ?? currency;
  String faithIn(int year) => _byYear(faiths, year) ?? '';

  /// Who ruled in [year]: the latest reign that had begun.
  String? rulerIn(int year) {
    EraRuler? out;
    for (final r in rulers) {
      if (r.from <= year && year <= r.to) out = r;
    }
    return out?.ruler;
  }

  List<String> maleIn(int year) => [
    ...male,
    for (final e in namesFrom.entries)
      if (year >= e.key) ...e.value.male,
  ];
  List<String> femaleIn(int year) => [
    ...female,
    for (final e in namesFrom.entries)
      if (year >= e.key) ...e.value.female,
  ];

  factory EraRegion.fromJson(Map<String, dynamic> j) {
    Map<int, String> years(Object? m) => {
      for (final e in Map<String, dynamic>.from(
        (m as Map?) ?? const {},
      ).entries)
        int.parse(e.key): e.value as String,
    };
    final names = years(j['names']);
    final at = List<num>.from(j['at'] ?? const [0, 0]);
    return EraRegion(
      id: j['id'],
      name:
          j['name'] ??
          (names.isEmpty ? j['id'] : names[names.keys.reduce(min)]!),
      names: names,
      cityList: [
        for (final c in (j['cities'] as List? ?? const [])) EraCity.fromJson(c),
      ],
      male: List<String>.from(j['male'] ?? const []),
      female: List<String>.from(j['female'] ?? const []),
      surnames: List<String>.from(j['surnames'] ?? const []),
      namesFrom: {
        for (final e in Map<String, dynamic>.from(
          j['namesFrom'] ?? const {},
        ).entries)
          int.parse(e.key): (
            male: List<String>.from(e.value['male'] ?? const []),
            female: List<String>.from(e.value['female'] ?? const []),
          ),
      },
      group: j['group'] ?? '',
      lat: at[0].toDouble(),
      lon: at[1].toDouble(),
      currency: j['currency'] ?? 'florin',
      currencies: years(j['currencies']),
      priceScale: ((j['prices'] as num?) ?? 1).toDouble(),
      wageScale: ((j['wages'] as num?) ?? 1).toDouble(),
      faiths: years(j['faiths']),
      language: j['language'] ?? '',
      rulers: [
        for (final r in (j['rulers'] as List? ?? const []))
          EraRuler(r['from'], r['to'], r['ruler']),
      ],
      from: j['from'] as int?,
    );
  }
}

/// One step of an era job's ladder ("Journeyman painter", 20 florins).
typedef EraRank = ({String title, int pay});

/// An era job on a guild ladder (Legends plan, Phase 2B): apprentice,
/// journeyman, master, with who it is open to, where and when.
class EraJob {
  EraJob({
    required this.id,
    required this.name,
    required this.ladder,
    this.guild,
    this.groups = const [],
    this.regions = const [],
    this.cities = const [],
    this.fromBy = const {},
    this.toBy = const {},
    this.minAge = 14,
    this.sex,
    this.minStatus = 0,
    this.legit = false,
    this.reads = const [],
    this.needsSchool,
    this.faith,
    this.years = const [],
    this.fees = const [],
    this.rise = const [],
    this.riseSchool = const {},
    this.extra,
    this.hub,
    this.hubName,
    this.entryFee = 0,
    this.entryWhy,
    this.closedLegit,
    this.note,
    this.aliases = const {},
  });
  final String id;

  /// The trade ("Painter", "Banking").
  final String name;
  final List<EraRank> ladder;
  final String? guild;

  /// Where it exists: region groups ("italy"), regions ("venice") or
  /// cities ("London"). Empty lists don't limit.
  final List<String> groups;
  final List<String> regions;
  final List<String> cities;

  /// First and last years by region group (printing: italy 1465).
  final Map<String, int> fromBy;
  final Map<String, int> toBy;
  final int minAge;

  /// 'male' or 'female' when history closed it to the other.
  final String? sex;

  /// Birth status needed: 0 peasant, 1 working people, 2 citizen, 3 noble.
  final int minStatus;

  /// Closed to children born outside marriage (the notaries' guild).
  final bool legit;

  /// Reading needed: 'read', 'reckon', 'latin', 'arabic'.
  final List<String> reads;

  /// A school kind that must be finished first ('university').
  final String? needsSchool;

  /// Only where this faith is held ("Catholic").
  final String? faith;

  /// Years in each step before rising, and the fee to rise.
  final List<int> years;
  final List<int> fees;

  /// The button to rise from each step ("Join the guild").
  final List<String> rise;

  /// A school kind needed to rise from a step ({0: 'university'}).
  final Map<int, String> riseSchool;

  /// The yearly extra work ("Take on a commission").
  final String? extra;

  /// The special career this becomes in Phase 3 (a modern hub id).
  final String? hub;

  /// The special career's name here, when the era's general name (the
  /// Italian "Condottiere") doesn't fit the place.
  final String? hubName;

  /// Paid to start ("a dowry for the convent").
  final int entryFee;
  final String? entryWhy;

  /// Why it is closed to the illegitimate, in history's words.
  final String? closedLegit;
  final String? note;

  /// Job titles set by events that sit on this ladder, with their step.
  final Map<String, int> aliases;

  /// The step of [title] on this ladder, or null.
  int? stepOf(String title) {
    final i = ladder.indexWhere((r) => r.title == title);
    return i >= 0 ? i : aliases[title];
  }

  factory EraJob.fromJson(Map<String, dynamic> j) {
    List<String> strs(Object? o) => List<String>.from((o as List?) ?? const []);
    List<int> ints(Object? o) => List<int>.from((o as List?) ?? const []);
    Map<String, int> years(Object? o) =>
        Map<String, int>.from((o as Map?) ?? const {});
    return EraJob(
      id: j['id'],
      name: j['name'] ?? j['id'],
      ladder: [
        for (final r in j['ladder'] as List)
          (title: r['title'] as String, pay: (r['pay'] as num).toInt()),
      ],
      guild: j['guild'],
      groups: strs(j['groups']),
      regions: strs(j['regions']),
      cities: strs(j['cities']),
      fromBy: years(j['fromBy']),
      toBy: years(j['toBy']),
      minAge: j['minAge'] ?? 14,
      sex: j['sex'],
      minStatus: j['minStatus'] ?? 0,
      legit: j['legit'] == true,
      reads: strs(j['reads']),
      needsSchool: j['needsSchool'],
      faith: j['faith'],
      years: ints(j['years']),
      fees: ints(j['fees']),
      rise: strs(j['rise']),
      riseSchool: {
        for (final e in Map<String, dynamic>.from(
          j['riseSchool'] ?? const {},
        ).entries)
          int.parse(e.key): e.value as String,
      },
      extra: j['extra'],
      hub: j['hub'],
      hubName: j['hubName'],
      entryFee: j['entryFee'] ?? 0,
      entryWhy: j['entryWhy'],
      closedLegit: j['closedLegit'],
      note: j['note'],
      aliases: years(j['aliases']),
    );
  }
}

/// A school of the era: abacus school, Latin grammar school, a tutor,
/// the Qur'an school, a university or a madrasa.
class EraSchool {
  EraSchool({
    required this.id,
    required this.name,
    this.kind = 'basic',
    this.groups = const [],
    this.cities = const [],
    this.fromBy = const {},
    this.toBy = const {},
    this.minAge = 6,
    this.maxAge = 14,
    this.years = 4,
    this.cost = 0,
    this.gives = const [],
    this.minStatus = 0,
    this.sex,
    this.needs,
  });
  final String id;
  final String name;

  /// 'basic' or 'university'.
  final String kind;
  final List<String> groups;
  final List<String> cities;
  final Map<String, int> fromBy;
  final Map<String, int> toBy;
  final int minAge;
  final int maxAge;
  final int years;

  /// Florins a year.
  final int cost;

  /// What it teaches: 'read', 'reckon', 'latin', 'arabic', 'degree'.
  final List<String> gives;
  final int minStatus;
  final String? sex;

  /// Reading needed to enter ('latin').
  final String? needs;

  factory EraSchool.fromJson(Map<String, dynamic> j) {
    final ages = List<int>.from(j['ages'] ?? const [6, 14]);
    return EraSchool(
      id: j['id'],
      name: j['name'],
      kind: j['kind'] ?? 'basic',
      groups: List<String>.from(j['groups'] ?? const []),
      cities: List<String>.from(j['cities'] ?? const []),
      fromBy: Map<String, int>.from(j['fromBy'] ?? const {}),
      toBy: Map<String, int>.from(j['toBy'] ?? const {}),
      minAge: ages.first,
      maxAge: ages.last,
      years: j['years'] ?? 4,
      cost: j['cost'] ?? 0,
      gives: List<String>.from(j['gives'] ?? const []),
      minStatus: j['minStatus'] ?? 0,
      sex: j['sex'],
      needs: j['needs'],
    );
  }
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
    this.statusNames = const {},
    this.hubs = const {},
    this.crimes = const {},
    this.lifeExpectancy = 48,
    this.plagueChance = 0.02,
    this.newsName = 'Avvisi',
    this.headlines = const {},
    this.quietYears = const [],
    this.anachronisms = const [],
    this.storylets = const [],
    this.currencies = const {},
    this.inflation = const [],
    this.healthData = const {},
    this.lawData = const {},
    this.faithData = const {},
    this.newsData = const {},
    this.wealthData = const {},
    this.homesData = const {},
    this.marketData = const {},
    this.activityData = const [],
    this.housesData = const {},
    this.peopleData = const {},
  });

  /// Phase 2C data, read by era_health, era_justice, era_faith and
  /// era_news: plague years, ailments and healers; courts, crimes and
  /// prisons; faiths and practices; news-sheets and dated stories.
  final Map<String, dynamic> healthData;
  final Map<String, dynamic> lawData;
  final Map<String, dynamic> faithData;
  final Map<String, dynamic> newsData;

  /// Phase 2D: banks, lenders and ventures; homes; the market; activities;
  /// the Great Houses; and people's natures and moments.
  final Map<String, dynamic> wealthData;
  final Map<String, dynamic> homesData;
  final Map<String, dynamic> marketData;
  final List<Map<String, dynamic>> activityData;
  final Map<String, dynamic> housesData;
  final Map<String, dynamic> peopleData;

  /// The era's moneys by id ("florin", "lsd", "nzimbu").
  final Map<String, EraCurrency> currencies;

  /// (year, price level against 1450): the price revolution after 1550.
  final List<(int, double)> inflation;

  /// The price level in [year], between the points of [inflation].
  double priceLevel(int year) {
    if (inflation.isEmpty) return 1;
    if (year <= inflation.first.$1) return inflation.first.$2;
    for (var i = 1; i < inflation.length; i++) {
      final (y1, p1) = inflation[i];
      if (year <= y1) {
        final (y0, p0) = inflation[i - 1];
        return p0 + (p1 - p0) * (year - y0) / (y1 - y0);
      }
    }
    return inflation.last.$2;
  }

  /// A price from the era table, in florins, for [region] in [year].
  int price(String item, EraRegion region, int year) =>
      ((prices[item] ?? 0) * region.priceScale * priceLevel(year)).round();

  /// A wage (florins a year in Florence, 1450) for [region] in [year].
  /// Wages lag behind prices, so real pay falls after 1550, as it did.
  int wage(int base, EraRegion region, int year) =>
      (base * region.wageScale * (1 + (priceLevel(year) - 1) * 0.6)).round();

  /// The regions that exist in [year].
  List<EraRegion> regionsIn(int year) => [
    for (final r in regions)
      if (r.openIn(year)) r,
  ];

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

  /// The era's schools and universities.
  final List<EraSchool> school;

  /// Birth status names by region group, from peasant (0) to noble (3).
  final Map<String, List<String>> statusNames;

  /// The era names of the 14 special careers (plan §7.2), by modern hub id.
  /// Data only until their Legends bring the full careers (Phase 3).
  final Map<String, String> hubs;

  EraJob? job(String id) => jobs.where((j) => j.id == id).firstOrNull;
  EraSchool? schoolById(String id) =>
      school.where((s) => s.id == id).firstOrNull;

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

  /// The region of a life: by its city.
  EraRegion regionOf(Life life) => regionOfCity(life.city);

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
      school: [
        for (final r in (j['school'] as List?) ?? const [])
          EraSchool.fromJson(Map<String, dynamic>.from(r)),
      ],
      statusNames: {
        for (final e in Map<String, dynamic>.from(
          j['status'] ?? const {},
        ).entries)
          e.key: List<String>.from(e.value),
      },
      hubs: Map<String, String>.from(j['hubs'] ?? const {}),
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
      currencies: {
        for (final e in Map<String, dynamic>.from(
          money['currencies'] ?? const {},
        ).entries)
          e.key: EraCurrency(
            e.key,
            e.value['symbol'],
            (e.value['rate'] as num).toDouble(),
            e.value['name'] ?? e.key,
            e.value['format'],
          ),
      },
      inflation: [
        for (final p in (money['inflation'] as List?) ?? const [])
          ((p as List)[0] as int, (p[1] as num).toDouble()),
      ],
      healthData: health,
      lawData: Map<String, dynamic>.from(j['law'] ?? const {}),
      faithData: Map<String, dynamic>.from(j['faith'] ?? const {}),
      newsData: news,
      wealthData: Map<String, dynamic>.from(j['wealth'] ?? const {}),
      homesData: Map<String, dynamic>.from(j['homes'] ?? const {}),
      marketData: Map<String, dynamic>.from(j['market'] ?? const {}),
      activityData: [
        for (final a in (j['activities'] as List?) ?? const [])
          Map<String, dynamic>.from(a as Map),
      ],
      housesData: Map<String, dynamic>.from(j['houses'] ?? const {}),
      peopleData: Map<String, dynamic>.from(j['people'] ?? const {}),
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
  final region = era.regionOf(life);
  // The region's name follows history (Florence becomes a duchy in 1532).
  final name = region.nameIn(life.year);
  if (name != life.country) {
    if (life.age > 0) {
      out.add('Proclaimed in ${life.city}: from now on this is the $name.');
    }
    life.country = name;
  }
  // A new ruler is cried in the streets.
  final ruler = region.rulerIn(life.year);
  if (life.age >= 6 &&
      ruler != null &&
      ruler != region.rulerIn(life.year - 1)) {
    out.add('Criers in ${life.city} announce a new ruler: $ruler.');
  }
  // In prison or on the galleys (era_justice.dart), work, school and pay
  // stop until you are out.
  final inside = eraInside(life);
  if (!inside) {
    // Work and school (era_path.dart): years in the trade, fees, finishing.
    out.addAll(eraPathYear(life, era, rng));
  }
  if (life.job != null && life.salary > 0 && !inside) {
    life.money += life.salary;
    life.lastYear = [(life.job!, life.salary)];
  } else {
    life.lastYear = [];
  }
  // The year's news (era_news.dart): its small effects apply this year.
  final issue = eraIssue(life, era);
  life.eraWorld['news'] = {'year': life.year, ...issue.effects};
  final headline = eraHeadline(life, era);
  if (headline != null && life.age >= 6) {
    life.feed.add(FeedEntry(life.age, headline, kind: 'world'));
  }
  // A modest cost of living from 16, at the place's prices, the year's
  // price level and this year's news ("Prices +4%").
  if (life.age >= 16 && !inside) {
    final bread =
        (era.price('living_year', region, life.year) *
                (100 + (issue.effects['prices'] ?? 0)) /
                100)
            .round();
    final paid = min(bread, max(0, life.money));
    life.money -= paid;
    if (paid > 0) life.lastYear.add(('Living', -paid));
  }
  // Faith (era_faith.dart), the law and prison (era_justice.dart), and
  // health and plague (era_health.dart).
  out.addAll(eraFaithYear(life, era, rng));
  out.addAll(eraLawYear(life, era, rng));
  out.addAll(eraHealthYear(life, era, rng));
  // Money, homes, the Great Houses and people (Phase 2D).
  if (!eraInside(life)) out.addAll(eraWealthYear(life, era, rng));
  out.addAll(eraHomesYear(life, era, rng));
  out.addAll(eraHousesYear(life, era));
  out.addAll(eraPeopleYear(life, era, rng));
  return out;
}

// ---------------- Journeys ----------------

/// How a journey goes: on foot or by mule, by ship, or with a caravan
/// across the Sahara.
enum JourneyBy { road, sea, caravan }

/// A journey from a life's city to [to]: how, how long, what it costs (in
/// florins) and the risk on the way.
typedef Journey = ({
  String to,
  EraRegion region,
  JourneyBy by,
  int days,
  int cost,
  double risk,
});

/// Groups that reach each other by road (the rest need a ship, or a
/// caravan for the Sahel).
const _overland = {
  'italy': {'italy'},
  'kongo': {'kongo'},
  'maghreb': {'maghreb'},
  'sahel': {'sahel'},
  'egypt': {'egypt'},
  'england': {'england'},
  'iberia': {'iberia'},
  'islands': {'islands'},
};

double _km(EraRegion a, EraRegion b) {
  const r = 6371.0;
  double rad(double d) => d * pi / 180;
  final dLat = rad(b.lat - a.lat), dLon = rad(b.lon - a.lon);
  final h =
      pow(sin(dLat / 2), 2) +
      cos(rad(a.lat)) * cos(rad(b.lat)) * pow(sin(dLon / 2), 2);
  return 2 * r * asin(sqrt(h));
}

/// Every city a life can travel to this year, with the journey there.
List<Journey> journeysFrom(Life life, EraRules era) {
  final here = era.regionOf(life);
  final out = <Journey>[];
  for (final r in era.regionsIn(life.year)) {
    for (final c in r.citiesIn(life.year)) {
      if (c == life.city) continue;
      final km = r == here ? 60.0 : max(80.0, _km(here, r));
      final by =
          r == here || (_overland[here.group]?.contains(r.group) ?? false)
          ? JourneyBy.road
          : ((here.group == 'sahel') != (r.group == 'sahel')
                ? JourneyBy.caravan
                : JourneyBy.sea);
      // About 30 km a day by road, 100 by sea, 25 with a caravan.
      final perDay = switch (by) {
        JourneyBy.road => 30.0,
        JourneyBy.sea => 100.0,
        JourneyBy.caravan => 25.0,
      };
      final days = max(
        1,
        (km * (by == JourneyBy.sea ? 1.3 : 1.2) / perDay).round(),
      );
      final cost = max(
        1,
        ((days * (by == JourneyBy.sea ? 0.35 : 0.2) + (r == here ? 0 : 2)) *
                era.priceLevel(life.year))
            .round(),
      );
      final risk = switch (by) {
        JourneyBy.road => min(0.08, 0.01 + days * 0.002),
        JourneyBy.sea => 0.05,
        JourneyBy.caravan => 0.07,
      };
      out.add((to: c, region: r, by: by, days: days, cost: cost, risk: risk));
    }
  }
  out.sort((a, b) => a.days.compareTo(b.days));
  return out;
}

/// Makes a journey: pays for it, may meet trouble on the way, and settles
/// the life in the new city. Returns what happened, for the feed.
String makeJourney(Life life, EraRules era, Journey j, Random rng) {
  final from = life.city;
  life.money -= j.cost;
  life.city = j.to;
  life.country = j.region.nameIn(life.year);
  final how = switch (j.by) {
    JourneyBy.road => 'by road',
    JourneyBy.sea => 'by sea',
    JourneyBy.caravan => 'with a caravan across the desert',
  };
  final took = j.days == 1 ? 'a day' : '${j.days} days';
  var text = 'You travelled from $from to ${j.to} $how. It took $took.';
  if (rng.nextDouble() < j.risk) {
    switch (j.by) {
      case JourneyBy.road:
        final lost = max(0, life.money) ~/ 4;
        life.money -= lost;
        life.stats.add('health', -5);
        text +=
            ' Bandits stopped you on the way and took what they could find.';
      case JourneyBy.sea:
        life.stats.add('health', -10);
        life.stats.add('happiness', -6);
        text += ' A storm nearly sank the ship. You arrived soaked, sick and shaken.';
      case JourneyBy.caravan:
        life.stats.add('health', -12);
        text += ' A well was dry, and the caravan went thirsty for three days.';
    }
  } else {
    life.stats.add('happiness', 3);
  }
  life.flags['journey_${life.year}'] = Memory(
    life.age,
    'travelling to ${j.to}',
  );
  return text;
}

/// Chance of dying this year in the era: harsher than today, and worse
/// with poor health.
double eraDeathChance(Life life, EraRules era) {
  final a = life.age;
  final shift = (era.lifeExpectancy - 48) / 2;
  double base;
  if (a < 2) {
    base = 0.035;
  } else if (a < 5) {
    base = 0.018;
  } else if (a < 40 + shift) {
    base = 0.005;
  } else if (a < 55 + shift) {
    base = 0.016;
  } else if (a < 70 + shift) {
    base = 0.045;
  } else {
    base = 0.12 + (a - 70 - shift) * 0.01;
  }
  final h = life.stats['health'];
  if (h < 30) base *= 2.2;
  if (h > 75) base *= 0.6;
  // This year's plague, ailments and childbirth (era_health.dart).
  base += ((life.eraWorld['risk'] as num?) ?? 0).toDouble();
  return base.clamp(0.0, 0.6);
}

/// Whether an era data entry applies to this life now: its `groups`,
/// `regions` and `cities` (any match; none means everywhere), its `from`
/// and `to` years, and its exact `years` if it has them.
bool eraScoped(Map j, Life l, EraRules era, {int? year}) {
  final y = year ?? l.year;
  final region = era.regionOf(l);
  final groups = (j['groups'] as List?) ?? const [];
  final regions = (j['regions'] as List?) ?? const [];
  final cities = (j['cities'] as List?) ?? const [];
  if (groups.isNotEmpty || regions.isNotEmpty || cities.isNotEmpty) {
    if (!groups.contains(region.group) &&
        !regions.contains(region.id) &&
        !cities.contains(l.city)) {
      return false;
    }
  }
  final from = j['from'] as int?, to = j['to'] as int?;
  if (from != null && y < from) return false;
  if (to != null && y > to) return false;
  final years = j['years'] as List?;
  if (years != null && !years.contains(y)) return false;
  return true;
}

/// The first entry of [list] that applies to this life now.
Map<String, dynamic>? eraFirst(List? list, Life l, EraRules era) {
  for (final e in list ?? const []) {
    if (eraScoped(e as Map, l, era)) return Map<String, dynamic>.from(e);
  }
  return null;
}

/// Spends a once-a-year era action; false if it was already used.
bool eraOnce(Life l, String id) {
  if (l.usedActions.contains(id)) return false;
  l.usedActions.add(id);
  return true;
}
