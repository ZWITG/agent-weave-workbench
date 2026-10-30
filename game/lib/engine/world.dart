import 'dart:math';

import 'economy.dart' show nextEconomy, fundReturns;
import 'finance.dart' show stepPrices;
import 'models.dart';
import 'world_data.dart';

/// One persistent world per player (plan Module 11, "Echoes"). Every life
/// happens in it and writes to one continuous history that is never reset:
/// - each year's headlines are generated once and then fixed, so every life
///   that lives through that year reads the same news;
/// - the economy belongs to the world, not to a life;
/// - news can carry small, bounded effects that fade (hiring, rent,
///   policing, health, mood);
/// - notable things players do are written into the history (the Ledger)
///   and feed a family-name reputation;
/// - later lives meet earlier ones through Echo events and the archive.

class WorldStory {
  WorldStory({
    required this.year,
    required this.category,
    required this.headline,
    required this.body,
    this.scope = 'global',
    this.effect,
    this.effectYears = 1,
    this.person,
  });

  final int year;

  /// economy, politics, science, culture, sport, weather, health, local,
  /// crime or people.
  final String category;
  final String headline;
  final String body;

  /// 'global', a country name or a city name.
  final String scope;

  /// Key into [worldEffects], if this story changes anything for players.
  final String? effect;
  final int effectYears;

  /// Set when a player's life made this story (Ledger entries).
  final String? person;

  bool get mine => person != null;

  Map<String, dynamic> toJson() => {
    'year': year,
    'category': category,
    'headline': headline,
    'body': body,
    'scope': scope,
    if (effect != null) 'effect': effect,
    'effectYears': effectYears,
    if (person != null) 'person': person,
  };

  factory WorldStory.fromJson(Map<String, dynamic> j) => WorldStory(
    year: j['year'],
    category: j['category'],
    headline: j['headline'],
    body: j['body'],
    scope: j['scope'] ?? 'global',
    effect: j['effect'],
    effectYears: j['effectYears'] ?? 1,
    person: j['person'],
  );
}

typedef WorldEffect = ({Map<String, int> mods, String you});

/// What news can change. Mods are summed per place and capped at ±20.
const worldEffects = <String, WorldEffect>{
  'hiring_up': (
    mods: {'hiring': 10},
    you: 'Jobs are easier to get, and pay is rising',
  ),
  'hiring_down': (
    mods: {'hiring': -12},
    you: 'Jobs are harder to get, and companies are cutting staff',
  ),
  'rent_up': (mods: {'rent': 20}, you: 'Rent costs 20% more'),
  'policing': (
    mods: {'policing': 20},
    you: 'More police on the streets: crime is riskier',
  ),
  'heatwave': (mods: {'health': -1}, you: 'A hot, tiring year: Health −1'),
  'flu': (mods: {'health': -2}, you: 'Bad flu season: Health −2'),
  'festival': (
    mods: {'happiness': 3},
    you: 'A good mood in town: Happiness +3',
  ),
  'fourday': (
    mods: {'happiness': 4},
    you: 'Shorter working weeks: Happiness +4',
  ),
  'pandemic': (
    mods: {'health': -2, 'happiness': -5, 'hiring': -8},
    you: 'A pandemic: Health −2, Happiness −5, fewer jobs',
  ),
  'inflation': (
    mods: {'prices': 15, 'happiness': -2},
    you: 'Living costs 15% more',
  ),
  'crime_wave': (
    mods: {'happiness': -2},
    you: 'Break-ins near you: homes are at risk',
  ),
  'housing_boom': (mods: {'rent': 10}, you: 'Home values up 15%, rents up 10%'),
  'housing_crash': (mods: {'happiness': -2}, you: 'Home values down 20%'),
  'tax_cut': (mods: {'happiness': 2}, you: 'A tax rebate for workers'),
  'tax_rise': (mods: {'happiness': -2}, you: 'Workers pay more tax this year'),
};

/// Family-name reputation axes (plan: Fame, Infamy, Wealth, Philanthropy,
/// Power), 0–100.
const nameAxes = ['fame', 'infamy', 'wealth', 'philanthropy', 'power'];

class World {
  World({
    int? seed,
    this.year = 2026,
    Map<int, String>? economy,
    Map<int, List<WorldStory>>? stories,
    Set<String>? generated,
    List<WorldStory>? ledger,
    Map<String, Map<String, int>>? names,
    List<String>? lives,
    Set<String>? deeds,
    Map<int, Map<String, double>>? prices,
    Map<int, List<String>>? market,
  }) : prices = prices ?? {},
       market = market ?? {},
       seed = seed ?? Random().nextInt(1 << 30),
       economy = economy ?? {},
       stories = stories ?? {},
       generated = generated ?? {},
       ledger = ledger ?? [],
       names = names ?? {},
       lives = lives ?? [],
       deeds = deeds ?? {};

  final int seed;

  /// The furthest year any life has reached; new lives start here, so the
  /// history only ever moves forward.
  int year;
  final Map<int, String> economy;
  final Map<int, List<WorldStory>> stories;
  final Set<String> generated;

  /// Notable things players did, kept forever.
  final List<WorldStory> ledger;
  final Map<String, Map<String, int>> names;

  /// One line per notable finished life.
  final List<String> lives;
  final Set<String> deeds;

  /// Market prices by year (stocks, bonds, gold, coins) and the news
  /// behind big moves: the same for every life in that year.
  final Map<int, Map<String, double>> prices;
  final Map<int, List<String>> market;

  Map<String, double> pricesFor(int y) {
    final known = prices[y];
    if (known != null) return known;
    // Walk back to the last known year (if any), then step forward.
    var from = y - 1;
    final first = prices.isEmpty ? y : prices.keys.reduce(min);
    while (from >= first && !prices.containsKey(from)) {
      from--;
    }
    var prev = prices[from] ?? <String, double>{};
    for (
      var year = prices.containsKey(from) ? from + 1 : y;
      year <= y;
      year++
    ) {
      final news = <String>[];
      prev = stepPrices(
        prev,
        economyFor(year),
        year,
        Random(seed * 17 + year * 977),
        news,
      );
      market[year] = news;
      prices[year] = prev;
    }
    return prices[y]!;
  }

  // ---------------- Economy and news ----------------

  String economyFor(int y) {
    final known = economy[y];
    if (known != null) return known;
    final prev = economy[y - 1] ?? 'Normal';
    return economy[y] = nextEconomy(prev, Random(seed * 7 + y));
  }

  /// Writes the year's world, national and local news the first time any
  /// life reaches that year in that place.
  void ensureYear(int y, String country, String city) {
    final rng = Random(seed + y * 7919 + country.hashCode + city.hashCode);
    final list = stories.putIfAbsent(y, () => []);
    if (generated.add('g:$y')) {
      list.add(_economyStory(y, Random(seed + y)));
      list.add(_pick(_globalTemplates, y, 'global', Random(seed + y * 31)));
    }
    if (generated.add('c:$country:$y')) {
      list.add(_pick(_nationalTemplates, y, country, rng, country: country));
    }
    if (generated.add('l:$city:$y')) {
      list.add(
        _pick(_localTemplates, y, city, rng, country: country, city: city),
      );
    }
  }

  /// Everything a paper in [city] would print for [y], biggest first.
  List<WorldStory> storiesFor(int y, String country, String city) {
    final all = (stories[y] ?? const <WorldStory>[])
        .where(
          (s) => s.scope == 'global' || s.scope == country || s.scope == city,
        )
        .toList();
    int rank(WorldStory s) => s.mine
        ? 0
        : s.scope == 'global'
        ? 1
        : s.scope == country
        ? 2
        : 3;
    all.sort((a, b) => rank(a).compareTo(rank(b)));
    return all;
  }

  /// The single headline shown in the Life feed for the year.
  WorldStory? headlineFor(int y, String country, String city) {
    final s = storiesFor(y, country, city);
    if (s.isEmpty) return null;
    // Prefer something that affects the player, then the world story.
    return s.firstWhere(
      (x) => x.effect != null && !x.mine,
      orElse: () => s.first,
    );
  }

  /// Active story effects in a place, with the year they end.
  List<(WorldStory, int)> activeEffects(int y, String country, String city) => [
    for (var from = y - 5; from <= y; from++)
      for (final s in stories[from] ?? const <WorldStory>[])
        if (s.effect != null &&
            from + s.effectYears > y &&
            (s.scope == 'global' || s.scope == country || s.scope == city))
          (s, from + s.effectYears - 1),
  ];

  /// Summed, capped modifiers the engine reads (hiring, rent, policing,
  /// health, happiness, name).
  Map<String, int> modsFor(int y, String country, String city, String surname) {
    final out = <String, int>{};
    for (final (s, _) in activeEffects(y, country, city)) {
      for (final e in worldEffects[s.effect]!.mods.entries) {
        out[e.key] = (out[e.key] ?? 0) + e.value;
      }
    }
    final rep = names[surname];
    if (rep != null) {
      final n =
          ((rep['fame'] ?? 0) +
              (rep['philanthropy'] ?? 0) -
              (rep['infamy'] ?? 0)) ~/
          10;
      if (n != 0) out['name'] = n.clamp(-8, 8);
    }
    return out.map((k, v) => MapEntry(k, v.clamp(-20, 20)));
  }

  // ---------------- Player deeds and family names ----------------

  /// Writes a notable deed into the history once per life.
  bool recordDeed(
    Life life,
    String key, {
    required String headline,
    required String body,
    String category = 'local',
    bool national = false,
    Map<String, int> axes = const {},
  }) {
    if (!deeds.add('${life.seed}:$key')) return false;
    final story = WorldStory(
      year: life.year,
      category: category,
      headline: headline,
      body: body,
      scope: national ? life.country : life.city,
      person: '${life.firstName} ${life.surname}',
    );
    stories.putIfAbsent(life.year, () => []).add(story);
    ledger.add(story);
    final rep = names.putIfAbsent(life.surname, () => {});
    axes.forEach((k, v) => rep[k] = ((rep[k] ?? 0) + v).clamp(0, 100));
    return true;
  }

  /// Short description of a family name, or null if nobody has heard of it.
  String? reputation(String surname) {
    final rep = names[surname];
    if (rep == null || rep.values.every((v) => v < 5)) return null;
    final top = rep.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final words = {
      'fame': 'well known',
      'infamy': 'notorious',
      'wealth': 'wealthy',
      'philanthropy': 'generous',
      'power': 'powerful',
    };
    final traits = [
      for (final e in top.take(2))
        if (e.value >= 5) words[e.key]!,
    ];
    return 'The $surname name: ${traits.join(', ')}';
  }

  /// Called when a life ends: notable lives join the world's memory.
  void recordLife(Life life) {
    final mine = ledger
        .where((s) => s.person == '${life.firstName} ${life.surname}')
        .toList();
    year = max(year, life.year);
    if (mine.isEmpty && life.netWorth < 100000) return;
    final what =
        life.job ?? (life.education == 'graduate' ? 'graduate' : 'citizen');
    lives.add(
      '${life.firstName} ${life.surname} (${life.birthYear}–${life.year}), '
      '${what.toLowerCase()} in ${life.city}',
    );
  }

  /// Picks an earlier notable life a new character can run into: the same
  /// surname first, then the same city, then the same country.
  Map<String, String>? echoFor(Life life) {
    if (ledger.isEmpty) return null;
    WorldStory? find(bool Function(WorldStory s) test) {
      for (final s in ledger.reversed) {
        if (s.year < life.birthYear + 1 && test(s)) return s;
      }
      return null;
    }

    String? relation;
    var s = find((s) => s.person!.endsWith(' ${life.surname}'));
    if (s != null) {
      relation = 'surname';
    } else if ((s = find((s) => s.scope == life.city)) != null) {
      relation = 'city';
    } else if ((s = find(
          (s) => s.scope == life.country || s.scope == life.city,
        )) !=
        null) {
      relation = 'country';
    }
    if (s == null || relation == null) return null;
    return {
      'relation': relation,
      'person': s.person!,
      'deed': s.headline,
      'year': '${s.year}',
      'scope': s.scope,
    };
  }

  // ---------------- Persistence ----------------

  Map<String, dynamic> toJson() => {
    'seed': seed,
    'year': year,
    'economy': economy.map((k, v) => MapEntry('$k', v)),
    'stories': stories.map(
      (k, v) => MapEntry('$k', [for (final s in v) s.toJson()]),
    ),
    'generated': generated.toList(),
    'ledger': [for (final s in ledger) s.toJson()],
    'names': names,
    'lives': lives,
    'deeds': deeds.toList(),
    // Only recent years are needed (lives move forward; Rewind goes back
    // at most a few years).
    'prices': {
      for (final e in prices.entries)
        if (e.key >= year - 130) '${e.key}': e.value,
    },
    'market': {
      for (final e in market.entries)
        if (e.key >= year - 130) '${e.key}': e.value,
    },
  };

  factory World.fromJson(Map<String, dynamic> j) => World(
    seed: j['seed'],
    year: j['year'] ?? 2026,
    economy: {
      for (final e in Map<String, dynamic>.from(j['economy'] ?? {}).entries)
        int.parse(e.key): e.value as String,
    },
    stories: {
      for (final e in Map<String, dynamic>.from(j['stories'] ?? {}).entries)
        int.parse(e.key): [
          for (final s in e.value as List)
            WorldStory.fromJson(Map<String, dynamic>.from(s)),
        ],
    },
    generated: Set<String>.from(j['generated'] ?? []),
    ledger: [
      for (final s in (j['ledger'] as List?) ?? const [])
        WorldStory.fromJson(Map<String, dynamic>.from(s)),
    ],
    names: {
      for (final e in Map<String, dynamic>.from(j['names'] ?? {}).entries)
        e.key: Map<String, int>.from(e.value),
    },
    lives: List<String>.from(j['lives'] ?? []),
    deeds: Set<String>.from(j['deeds'] ?? []),
    prices: {
      for (final e in Map<String, dynamic>.from(j['prices'] ?? {}).entries)
        int.parse(e.key): {
          for (final p in Map<String, dynamic>.from(e.value).entries)
            p.key: (p.value as num).toDouble(),
        },
    },
    market: {
      for (final e in Map<String, dynamic>.from(j['market'] ?? {}).entries)
        int.parse(e.key): List<String>.from(e.value),
    },
  );

  // ---------------- Writing the news ----------------

  WorldStory _economyStory(int y, Random rng) {
    final e = economyFor(y);
    final (mean, _) = fundReturns[e]!;
    final t = _economyTemplates[e]!;
    final pick = t[rng.nextInt(t.length)];
    return WorldStory(
      year: y,
      category: 'economy',
      headline: pick.$1,
      body:
          '${pick.$2} Analysts expect index funds to return around '
          '${mean >= 0 ? '+' : ''}$mean% this year.',
      effect: pick.$3,
      effectYears: 2,
    );
  }

  WorldStory _pick(
    List<_Template> list,
    int y,
    String scope,
    Random rng, {
    String? country,
    String? city,
  }) {
    var t = list[rng.nextInt(list.length)];
    // Rare stories come up about once in 30 years, not once in a dozen.
    while (t.rare && rng.nextInt(100) < 85) {
      t = list[rng.nextInt(list.length)];
    }
    final c = country == null
        ? countries[rng.nextInt(countries.length)]
        : countryNamed(country);
    final other = countries[rng.nextInt(countries.length)];
    final first = rng.nextBool() ? c.female : c.male;
    final person =
        '${first[rng.nextInt(first.length)]} '
        '${c.surnames[rng.nextInt(c.surnames.length)]}';
    String fill(String s) => s
        .replaceAll('{country}', c.name)
        .replaceAll('{other}', other.name == c.name ? 'Japan' : other.name)
        .replaceAll('{city}', city ?? c.cities[rng.nextInt(c.cities.length)])
        .replaceAll('{person}', person)
        .replaceAll('{company}', _companies[rng.nextInt(_companies.length)])
        .replaceAll('{title}', _titles[rng.nextInt(_titles.length)])
        .replaceAll('{n}', '${2 + rng.nextInt(9)}');
    return WorldStory(
      year: y,
      category: t.category,
      headline: fill(t.headline),
      body: fill(t.body),
      scope: scope,
      effect: t.effect,
      effectYears: t.years,
    );
  }
}

class _Template {
  const _Template(
    this.category,
    this.headline,
    this.body, {
    this.effect,
    this.years = 1,
    this.rare = false,
  });
  final String category;
  final String headline;
  final String body;
  final String? effect;
  final int years;

  /// Once-in-a-generation stories (pandemics, oil shocks).
  final bool rare;
}

const _companies = [
  'Lumen Labs',
  'Northwind Foods',
  'Kestrel Motors',
  'Bluefin Energy',
  'Paperkite Games',
  'Tidewater Bank',
  'Quill & Co',
  'Orchard Health',
  'Halcyon Air',
  'Brightloom',
];

const _titles = [
  'The Quiet Year',
  'Paper Moons',
  'Saltwater',
  'Neon Orchard',
  'The Long Way Home',
  'Glasshouse',
];

const _economyTemplates = <String, List<(String, String, String?)>>{
  'Boom': [
    (
      'Markets hit record highs as hiring surges',
      'Companies are expanding and struggling to find staff. Wages are rising faster than they have in a decade.',
      'hiring_up',
    ),
    (
      'Boom times: shops report their best year ever',
      'Shoppers are spending, factories are running extra shifts and recruiters are back on campus.',
      'hiring_up',
    ),
  ],
  'Normal': [
    (
      'Steady growth, says the central bank',
      'The economy is ticking along nicely. Prices are stable and unemployment is low, if not spectacular.',
      null,
    ),
    (
      'A quiet year for the markets',
      'No crash, no bubble. Economists admitted they had very little to say this year.',
      null,
    ),
  ],
  'Slowdown': [
    (
      'Growth stalls as shoppers tighten their belts',
      'Businesses are cautious and some have paused hiring. Experts say it is a wobble, not a crisis, for now.',
      null,
    ),
    (
      'Prices soar as inflation hits a 30-year high',
      'Food, fuel and energy bills have jumped. Families are cutting back and the central bank is under pressure.',
      'inflation',
    ),
  ],
  'Recession': [
    (
      'Recession confirmed: companies freeze hiring',
      'Two quarters of shrinking output. Job adverts have dropped sharply and many firms are cutting costs.',
      'hiring_down',
    ),
    (
      'Layoffs spread as the downturn deepens',
      'From factories to tech firms, companies are letting staff go. Savers are being told to keep calm.',
      'hiring_down',
    ),
  ],
  'Crash': [
    (
      'Markets crash: worst week in a generation',
      'Share prices have collapsed after a run on several banks. Investors watched years of gains vanish in days.',
      'hiring_down',
    ),
    (
      'House prices plunge as the banks stop lending',
      'Homeowners have watched their biggest asset shrink overnight. Estate agents report empty viewings.',
      'housing_crash',
    ),
  ],
};

const _globalTemplates = [
  _Template(
    'science',
    'Scientists unveil a battery that charges in 90 seconds',
    'A team in {country} says the new cell could make electric cars as quick to refuel as petrol ones. Car makers are already queuing up.',
  ),
  _Template(
    'science',
    'New vaccine approved for malaria',
    'Health agencies call it one of the most important medical advances of the century. Roll-out starts this year.',
  ),
  _Template(
    'science',
    'Telescope spots an ocean world 40 light years away',
    'Astronomers say the planet is the best candidate yet for life beyond Earth. Schoolchildren have been asked to suggest a name.',
  ),
  _Template(
    'culture',
    '"{title}" breaks box-office records worldwide',
    'The film, made on a tiny budget in {country}, has become the most-watched release of the year.',
  ),
  _Template(
    'culture',
    'Pop star {person} announces a surprise retirement',
    'Fans are in mourning after the singer posted a one-line message: "Thank you. That\'s enough now."',
  ),
  _Template(
    'sport',
    '{country} win the World Cup on penalties',
    'After a goalless final, the goalkeeper became a national hero. Celebrations went on until sunrise.',
  ),
  _Template(
    'sport',
    'Marathon world record falls by 40 seconds',
    'Runners had thought the old record might stand for decades. It lasted three years.',
  ),
  _Template(
    'weather',
    'Record heatwave grips half the planet',
    'Temperatures broke records on four continents. Doctors urged people to stay inside at midday and drink water.',
    effect: 'heatwave',
  ),
  _Template(
    'health',
    'Worst flu season in a decade',
    'Hospitals are under pressure and schools are emptying. A vaccine update is being rushed out.',
    effect: 'flu',
  ),
  _Template(
    'politics',
    'World leaders sign a deal to protect the oceans',
    'After a decade of talks, 140 countries agreed to protect a third of the world\'s seas.',
  ),
  _Template(
    'health',
    'A new virus spreads around the world',
    'Borders are closing, offices are emptying and hospitals are filling up. Scientists say a vaccine is at least a year away.',
    effect: 'pandemic',
    years: 2,
    rare: true,
  ),
  _Template(
    'economy',
    'Oil price shock sends prices soaring everywhere',
    'A conflict far away has doubled the price of fuel. Everything that travels by lorry now costs more.',
    effect: 'inflation',
    years: 2,
    rare: true,
  ),
  _Template(
    'culture',
    'A dance called "the Wobble" takes over the internet',
    'Nobody knows who started it. Everybody, including several prime ministers, has now done it.',
  ),
];

const _nationalTemplates = [
  _Template(
    'politics',
    '{person} elected to lead {country}',
    'The new leader promised "fewer speeches and more trains". Turnout was the highest in twenty years.',
  ),
  _Template(
    'politics',
    '{country} trials a four-day working week',
    'Thousands of workers will work four days for the same pay. Early surveys show people are happier and no less productive.',
    effect: 'fourday',
    years: 2,
  ),
  _Template(
    'economy',
    '{company} opens a giant new campus in {country}',
    'The firm says it will hire thousands of people over the next few years, from engineers to cooks.',
    effect: 'hiring_up',
    years: 3,
  ),
  _Template(
    'economy',
    'Housing shortage pushes rents to record highs across {country}',
    'Young people are staying at home longer as rents climb. The government promises more homes.',
    effect: 'rent_up',
    years: 3,
  ),
  _Template(
    'sport',
    '{country}\'s national team reaches its first ever final',
    'Flags hung from every window. The team lost the final, but nobody seemed to mind.',
    effect: 'festival',
  ),
  _Template(
    'politics',
    '{country} cuts income tax for workers',
    'The government says it wants to "put money back in people\'s pockets". Workers will see a rebate this year.',
    effect: 'tax_cut',
  ),
  _Template(
    'politics',
    '{country} raises taxes to pay for its debts',
    'The finance minister apologised in advance. Workers will pay more this year.',
    effect: 'tax_rise',
  ),
  _Template(
    'economy',
    'House prices boom across {country}',
    'Homeowners are celebrating and first-time buyers are despairing. Some homes sold within an hour of being listed.',
    effect: 'housing_boom',
    years: 2,
  ),
  _Template(
    'health',
    'Free health check-ups for everyone in {country}',
    'A new scheme lets anyone visit a doctor once a year for free. Waiting rooms are busy.',
  ),
];

const _localTemplates = [
  _Template(
    'local',
    'New tram line opens in {city}',
    'Commuters cheered as the first tram left on time. Locals say the city finally feels connected.',
    effect: 'festival',
  ),
  _Template(
    'local',
    'Factory closes in {city}, 800 jobs lost',
    'Workers were told on Monday morning. The council is promising retraining and new investment.',
    effect: 'hiring_down',
    years: 2,
  ),
  _Template(
    'local',
    'Tech firm {company} moves its headquarters to {city}',
    'The company is hiring hundreds of people. Coffee shops near the new office have already raised their prices.',
    effect: 'hiring_up',
    years: 3,
  ),
  _Template(
    'crime',
    'Police step up patrols in {city} after a wave of thefts',
    'Officers will be on foot in the city centre every evening. Pickpockets have been warned.',
    effect: 'policing',
    years: 2,
  ),
  _Template(
    'crime',
    'Wave of break-ins hits {city} homes',
    'Police say a gang is targeting houses while owners are at work. Locksmiths have a waiting list.',
    effect: 'crime_wave',
  ),
  _Template(
    'local',
    '{city} food festival draws record crowds',
    'Two hundred stalls, one giant paella and a queue for dumplings that stretched round the block.',
    effect: 'festival',
  ),
  _Template(
    'local',
    'Rents in {city} jump as newcomers move in',
    'Estate agents say demand has never been higher. Long-time residents are less thrilled.',
    effect: 'rent_up',
    years: 2,
  ),
  _Template(
    'local',
    'Old cinema in {city} saved by locals',
    'Neighbours raised the money in six weeks. The first film shown will be a classic chosen by public vote.',
  ),
];
