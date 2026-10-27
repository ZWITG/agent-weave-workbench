import 'dart:math';

/// Visible and hidden stats. All values are clamped to 0–100.
class Stats {
  Stats(Map<String, int> values) : values = Map.of(values);

  static const visible = ['happiness', 'health', 'smarts', 'looks'];
  static const hidden = [
    'karma',
    'willpower',
    'discipline',
    'athleticism',
    'charisma',
    'creativity',
  ];

  final Map<String, int> values;

  int operator [](String key) => values[key] ?? 50;

  void add(String key, int delta) {
    values[key] = (this[key] + delta).clamp(0, 100);
  }

  static Stats random(Random rng) => Stats({
    for (final k in [...visible, ...hidden]) k: 25 + rng.nextInt(66),
  });

  Map<String, dynamic> toJson() => values;
  factory Stats.fromJson(Map<String, dynamic> j) =>
      Stats(j.map((k, v) => MapEntry(k, (v as num).toInt())));
}

/// Something a person remembers about the player (see 04 Social, Module 1).
/// [valence] runs -3..+3, [intensity] 1..5 and fades by 0.2 a year.
class NpcMemory {
  NpcMemory({
    required this.age,
    required this.text,
    this.valence = -1,
    this.intensity = 2,
    List<String>? tags,
  }) : tags = tags ?? [];

  final int age;
  final String text;
  final int valence;
  double intensity;
  final List<String> tags;

  bool get negative => valence < 0;

  Map<String, dynamic> toJson() => {
    'age': age,
    'text': text,
    'valence': valence,
    'intensity': intensity,
    'tags': tags,
  };

  factory NpcMemory.fromJson(dynamic j) {
    if (j is String) {
      return NpcMemory(
        age: 0,
        text: j,
        valence: -2,
        intensity: 4,
        tags: ['story'],
      );
    }
    final m = Map<String, dynamic>.from(j);
    return NpcMemory(
      age: m['age'] ?? 0,
      text: m['text'],
      valence: m['valence'] ?? -1,
      intensity: (m['intensity'] as num?)?.toDouble() ?? 2,
      tags: List<String>.from(m['tags'] ?? []),
    );
  }
}

/// A person in the character's life.
///
/// The visible Bond % is a blend of hidden facets (planning formula):
/// Bond = 0.35·Affection + 0.25·Trust + 0.20·Respect + 0.20·Familiarity
///        − 0.50·Resentment, clamped to 0–100.
class Npc {
  Npc({
    required this.id,
    required this.role,
    required this.name,
    required this.birthYear,
    this.circle = 'Family',
    int bond = 60,
    List<NpcMemory>? memories,
  }) : affection = bond,
       trust = bond,
       respect = bond,
       familiarity = bond,
       memories = memories ?? [];

  final String id;
  final String role;
  final String name;
  final int birthYear;

  /// Family, Partner, Friends, Work, School, Rivals, Exes, Community.
  final String circle;
  int affection;
  int trust;
  int respect;
  int familiarity;
  int resentment = 0;
  final List<NpcMemory> memories;
  bool alive = true;

  /// Player cut contact; only "Reconnect" is available.
  bool contactCut = false;

  /// Age at which the player last interacted with this person.
  int lastContactAge = 0;

  /// Times the player asked again after being refused.
  int refusals = 0;

  /// Money this person owes the player.
  int debt = 0;

  int ageIn(int year) => year - birthYear;

  int get bond =>
      (0.35 * affection +
              0.25 * trust +
              0.20 * respect +
              0.20 * familiarity -
              0.50 * resentment)
          .round()
          .clamp(0, 100);

  /// Estranged, Cold, Distant, Warm, Close, Devoted.
  String get bondLabel {
    final b = bond;
    if (b < 15) return 'Estranged';
    if (b < 30) return 'Cold';
    if (b < 45) return 'Distant';
    if (b < 65) return 'Warm';
    if (b < 85) return 'Close';
    return 'Devoted';
  }

  /// A grudge: a strong negative memory (intensity ≥ 4) or three negative
  /// memories with the same tag.
  NpcMemory? get grudge {
    for (final m in memories) {
      if (m.negative && m.intensity >= 4) return m;
    }
    final counts = <String, int>{};
    for (final m in memories.where((m) => m.negative && m.intensity >= 1)) {
      for (final t in m.tags) {
        counts[t] = (counts[t] ?? 0) + 1;
        if (counts[t]! >= 3) return m;
      }
    }
    return null;
  }

  int _c(int v) => v.clamp(0, 100);

  void addFacets({
    int affection = 0,
    int trust = 0,
    int respect = 0,
    int familiarity = 0,
    int resentment = 0,
  }) {
    this.affection = _c(this.affection + affection);
    this.trust = _c(this.trust + trust);
    this.respect = _c(this.respect + respect);
    this.familiarity = _c(this.familiarity + familiarity);
    this.resentment = _c(this.resentment + resentment);
  }

  /// Story effects that just say "bond +n / −n" map onto the facets.
  void addBond(int delta) {
    if (delta >= 0) {
      addFacets(
        affection: delta,
        trust: delta,
        respect: delta ~/ 2,
        familiarity: delta ~/ 2,
      );
    } else {
      addFacets(affection: delta ~/ 2, trust: delta ~/ 2, resentment: -delta);
    }
  }

  void remember(NpcMemory m) {
    memories.add(m);
    if (memories.length > 24) {
      memories.sort((a, b) => b.intensity.compareTo(a.intensity));
      memories.removeLast();
    }
  }

  /// The top two drivers of the Bond %, in plain language.
  List<String> why() {
    final reasons = <(double, String)>[
      (
        resentment * 0.5,
        'Resentment is ${_level(resentment)}${grudge != null ? ': ${grudge!.text}' : ''}',
      ),
      ((100 - trust) * 0.25, 'Trust is ${_level(trust)}'),
      ((100 - affection) * 0.35, 'Affection is ${_level(affection)}'),
      ((100 - respect) * 0.20, 'Respect is ${_level(respect)}'),
      (
        (100 - familiarity) * 0.20,
        'You ${familiarity < 40 ? 'rarely see each other' : 'know each other well'}',
      ),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    if (bond >= 65) {
      final good = <(int, String)>[
        (affection, 'Affection is ${_level(affection)}'),
        (trust, 'Trust is ${_level(trust)}'),
        (respect, 'Respect is ${_level(respect)}'),
        (familiarity, 'You know each other well'),
      ]..sort((a, b) => b.$1.compareTo(a.$1));
      return good.take(2).map((e) => e.$2).toList();
    }
    return reasons.take(2).map((e) => e.$2).toList();
  }

  static String _level(int v) => v >= 75
      ? 'high'
      : v >= 50
      ? 'good'
      : v >= 30
      ? 'low'
      : 'very low';

  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'name': name,
    'birthYear': birthYear,
    'circle': circle,
    'affection': affection,
    'trust': trust,
    'respect': respect,
    'familiarity': familiarity,
    'resentment': resentment,
    'memories': memories.map((m) => m.toJson()).toList(),
    'alive': alive,
    'contactCut': contactCut,
    'lastContactAge': lastContactAge,
    'refusals': refusals,
    'debt': debt,
  };

  factory Npc.fromJson(Map<String, dynamic> j) {
    final n = Npc(
      id: j['id'],
      role: j['role'],
      name: j['name'],
      birthYear: j['birthYear'],
      circle: j['circle'] ?? 'Family',
      bond: j['bond'] ?? 60,
      memories: ((j['memories'] as List?) ?? [])
          .map(NpcMemory.fromJson)
          .toList(),
    );
    if (j.containsKey('affection')) {
      n
        ..affection = j['affection']
        ..trust = j['trust']
        ..respect = j['respect']
        ..familiarity = j['familiarity']
        ..resentment = j['resentment'];
    }
    return n
      ..alive = j['alive'] ?? true
      ..contactCut = j['contactCut'] ?? false
      ..lastContactAge = j['lastContactAge'] ?? 0
      ..refusals = j['refusals'] ?? 0
      ..debt = j['debt'] ?? 0;
  }
}

/// One line of the life feed (a chat bubble in the Night Feed design).
class FeedEntry {
  FeedEntry(this.age, this.text, {this.kind = 'event'});
  final int age;
  final String text;
  final String kind;

  Map<String, dynamic> toJson() => {'age': age, 'text': text, 'kind': kind};
  factory FeedEntry.fromJson(Map<String, dynamic> j) =>
      FeedEntry(j['age'], j['text'], kind: j['kind'] ?? 'event');
}

/// A remembered fact that later storylets can read ("memory over randomness").
class Memory {
  Memory(this.age, this.label);
  final int age;
  final String label;
  Map<String, dynamic> toJson() => {'age': age, 'label': label};
  factory Memory.fromJson(Map<String, dynamic> j) =>
      Memory(j['age'], j['label']);
}

/// Something you own or rent, shown as a card on the Wealth tab.
class Asset {
  Asset({
    required this.id,
    required this.kind,
    required this.name,
    required this.value,
    required this.yearlyCost,
    required this.since,
    this.condition = 100,
  });

  final String id;

  /// 'car', 'house' or 'rental'.
  final String kind;
  final String name;
  int value;
  int yearlyCost;
  final int since;
  int condition;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'name': name,
    'value': value,
    'yearlyCost': yearlyCost,
    'since': since,
    'condition': condition,
  };

  factory Asset.fromJson(Map<String, dynamic> j) => Asset(
    id: j['id'],
    kind: j['kind'],
    name: j['name'],
    value: j['value'],
    yearlyCost: j['yearlyCost'],
    since: j['since'],
    condition: j['condition'] ?? 100,
  );
}

class Life {
  Life({
    required this.seed,
    required this.firstName,
    required this.surname,
    required this.gender,
    required this.country,
    required this.city,
    required this.birthYear,
    required this.stats,
    required this.npcs,
    this.age = 0,
    this.money = 0,
    this.education = 'none',
    this.job,
    this.salary = 0,
    this.careerId,
    this.careerRank = 0,
    this.jobSince = 0,
    this.eduSince = 0,
    this.savings = 0,
    this.invested = 0,
    this.lifestyle = 'comfortable',
    this.economy = 'Normal',
    Map<String, int>? debts,
    List<Asset>? assets,
    Map<int, int>? netWorthByAge,
    List<(String, int)>? lastYear,
    List<(String, int)>? lastGrowth,
    List<FeedEntry>? feed,
    Map<String, Memory>? flags,
    Map<String, int>? lastSeen,
    Set<String>? usedActions,
    Map<String, int>? interactionCounts,
    this.alive = true,
    this.causeOfDeath,
  }) : debts = debts ?? {},
       assets = assets ?? [],
       netWorthByAge = netWorthByAge ?? {},
       lastYear = lastYear ?? [],
       lastGrowth = lastGrowth ?? [],
       feed = feed ?? [],
       flags = flags ?? {},
       lastSeen = lastSeen ?? {},
       usedActions = usedActions ?? {},
       interactionCounts = interactionCounts ?? {};

  final int seed;
  final String firstName;
  final String surname;
  final String gender;
  final String country;
  final String city;
  final int birthYear;
  final Stats stats;
  final List<Npc> npcs;
  int age;
  int money;
  String education;
  String? job;
  int salary;

  /// Career on the job board (careers.dart) and the step on its ladder.
  String? careerId;
  int careerRank;

  /// Age the current role / course started (promotions and graduation).
  int jobSince;
  int eduSince;

  // ---- Wealth (economy.dart) ----
  int savings;
  int invested;

  /// 'frugal', 'comfortable' or 'lavish'.
  String lifestyle;

  /// Boom, Normal, Slowdown, Recession or Crash.
  String economy;

  /// Debt name ('Student loan', 'Mortgage'...) -> balance.
  final Map<String, int> debts;
  final List<Asset> assets;
  final Map<int, int> netWorthByAge;

  /// Last birthday's cash flow (adds up to the change in cash) and the
  /// growth that happened outside cash (savings interest, fund, home value).
  List<(String, int)> lastYear;
  List<(String, int)> lastGrowth;

  int get totalDebt => debts.values.fold(0, (a, b) => a + b);
  int get assetValue => assets.fold(0, (a, b) => a + b.value);
  int get netWorth => money + savings + invested + assetValue - totalDebt;
  bool has(String kind) => assets.any((a) => a.kind == kind);
  final List<FeedEntry> feed;
  final Map<String, Memory> flags;

  /// Storylet id -> age it last fired (for cooldowns and once-only events).
  final Map<String, int> lastSeen;

  /// Actions already used this year (each action once per year).
  final Set<String> usedActions;

  /// "interaction:npc" -> uses this year (diminishing returns).
  final Map<String, int> interactionCounts;
  bool alive;
  String? causeOfDeath;

  String get fullName => '$firstName $surname';
  int get year => birthYear + age;
  String get initials => '${firstName[0]}${surname[0]}';

  Npc? npc(String id) {
    for (final n in npcs) {
      if (n.id == id) return n;
    }
    return null;
  }

  String get stage {
    if (age < 5) return 'Early childhood';
    if (age < 12) return 'Primary school';
    if (age < 18) return 'Secondary school';
    if (age < 25) return 'Young adult';
    return 'Adult';
  }

  Map<String, dynamic> toJson() => {
    'v': 1,
    'seed': seed,
    'firstName': firstName,
    'surname': surname,
    'gender': gender,
    'country': country,
    'city': city,
    'birthYear': birthYear,
    'stats': stats.toJson(),
    'npcs': npcs.map((n) => n.toJson()).toList(),
    'age': age,
    'money': money,
    'education': education,
    'job': job,
    'salary': salary,
    'careerId': careerId,
    'careerRank': careerRank,
    'jobSince': jobSince,
    'eduSince': eduSince,
    'savings': savings,
    'invested': invested,
    'lifestyle': lifestyle,
    'economy': economy,
    'debts': debts,
    'assets': assets.map((a) => a.toJson()).toList(),
    'netWorthByAge': netWorthByAge.map((k, v) => MapEntry('$k', v)),
    'lastYear': [
      for (final l in lastYear) [l.$1, l.$2],
    ],
    'lastGrowth': [
      for (final l in lastGrowth) [l.$1, l.$2],
    ],
    'feed': feed.map((f) => f.toJson()).toList(),
    'flags': flags.map((k, v) => MapEntry(k, v.toJson())),
    'lastSeen': lastSeen,
    'usedActions': usedActions.toList(),
    'interactionCounts': interactionCounts,
    'alive': alive,
    'causeOfDeath': causeOfDeath,
  };

  factory Life.fromJson(Map<String, dynamic> j) => Life(
    seed: j['seed'],
    firstName: j['firstName'],
    surname: j['surname'],
    gender: j['gender'],
    country: j['country'],
    city: j['city'],
    birthYear: j['birthYear'],
    stats: Stats.fromJson(Map<String, dynamic>.from(j['stats'])),
    npcs: (j['npcs'] as List)
        .map((n) => Npc.fromJson(Map<String, dynamic>.from(n)))
        .toList(),
    age: j['age'],
    money: j['money'],
    education: j['education'],
    job: j['job'],
    salary: j['salary'] ?? 0,
    careerId: j['careerId'],
    careerRank: j['careerRank'] ?? 0,
    jobSince: j['jobSince'] ?? 0,
    eduSince: j['eduSince'] ?? 0,
    savings: j['savings'] ?? 0,
    invested: j['invested'] ?? 0,
    lifestyle: j['lifestyle'] ?? 'comfortable',
    economy: j['economy'] ?? 'Normal',
    debts: Map<String, int>.from(j['debts'] ?? {}),
    assets: j['assets'] == null
        ? _assetsFromFlags(j)
        : [
            for (final a in j['assets'] as List)
              Asset.fromJson(Map<String, dynamic>.from(a)),
          ],
    netWorthByAge: {
      for (final e in Map<String, dynamic>.from(
        j['netWorthByAge'] ?? {},
      ).entries)
        int.parse(e.key): e.value as int,
    },
    lastYear: _lines(j['lastYear']),
    lastGrowth: _lines(j['lastGrowth']),
    feed: (j['feed'] as List)
        .map((f) => FeedEntry.fromJson(Map<String, dynamic>.from(f)))
        .toList(),
    flags: (j['flags'] as Map).map(
      (k, v) =>
          MapEntry(k as String, Memory.fromJson(Map<String, dynamic>.from(v))),
    ),
    lastSeen: Map<String, int>.from(j['lastSeen'] ?? {}),
    usedActions: Set<String>.from(j['usedActions'] ?? []),
    interactionCounts: Map<String, int>.from(j['interactionCounts'] ?? {}),
    alive: j['alive'] ?? true,
    causeOfDeath: j['causeOfDeath'],
  );
}

List<(String, int)> _lines(dynamic raw) => [
  for (final l in (raw as List?) ?? const []) (l[0] as String, l[1] as int),
];

/// Saves from before the Wealth update kept assets as flags.
List<Asset> _assetsFromFlags(Map<String, dynamic> j) {
  final flags = Map<String, dynamic>.from(j['flags'] ?? {});
  final age = j['age'] as int;
  return [
    if (flags.containsKey('owns_car'))
      Asset(
        id: 'car',
        kind: 'car',
        name: 'Used car',
        value: 3000,
        yearlyCost: 1200,
        since: age,
      ),
    if (flags.containsKey('own_flat') && !flags.containsKey('owns_house'))
      Asset(
        id: 'flat',
        kind: 'rental',
        name: 'Rented flat',
        value: 0,
        yearlyCost: 9600,
        since: age,
      ),
    if (flags.containsKey('owns_house'))
      Asset(
        id: 'house',
        kind: 'house',
        name: 'House',
        value: 200000,
        yearlyCost: 2500,
        since: age,
      ),
  ];
}
