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

/// A person in the character's life. [bond] is the Bond % shown in the UI.
class Npc {
  Npc({
    required this.id,
    required this.role,
    required this.name,
    required this.birthYear,
    this.bond = 60,
    List<String>? memories,
  }) : memories = memories ?? [];

  final String id;
  final String role;
  final String name;
  final int birthYear;
  int bond;
  final List<String> memories;
  bool alive = true;

  int ageIn(int year) => year - birthYear;

  void addBond(int delta) => bond = (bond + delta).clamp(0, 100);

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'name': name,
        'birthYear': birthYear,
        'bond': bond,
        'memories': memories,
        'alive': alive,
      };

  factory Npc.fromJson(Map<String, dynamic> j) => Npc(
        id: j['id'],
        role: j['role'],
        name: j['name'],
        birthYear: j['birthYear'],
        bond: j['bond'],
        memories: List<String>.from(j['memories'] ?? []),
      )..alive = j['alive'] ?? true;
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
  factory Memory.fromJson(Map<String, dynamic> j) => Memory(j['age'], j['label']);
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
    List<FeedEntry>? feed,
    Map<String, Memory>? flags,
    Map<String, int>? lastSeen,
    Set<String>? usedActions,
    this.alive = true,
    this.causeOfDeath,
  })  : feed = feed ?? [],
        flags = flags ?? {},
        lastSeen = lastSeen ?? {},
        usedActions = usedActions ?? {};

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
  final List<FeedEntry> feed;
  final Map<String, Memory> flags;

  /// Storylet id -> age it last fired (for cooldowns and once-only events).
  final Map<String, int> lastSeen;

  /// Actions already used this year (each action once per year).
  final Set<String> usedActions;
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
        'feed': feed.map((f) => f.toJson()).toList(),
        'flags': flags.map((k, v) => MapEntry(k, v.toJson())),
        'lastSeen': lastSeen,
        'usedActions': usedActions.toList(),
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
        feed: (j['feed'] as List)
            .map((f) => FeedEntry.fromJson(Map<String, dynamic>.from(f)))
            .toList(),
        flags: (j['flags'] as Map).map((k, v) =>
            MapEntry(k as String, Memory.fromJson(Map<String, dynamic>.from(v)))),
        lastSeen: Map<String, int>.from(j['lastSeen'] ?? {}),
        usedActions: Set<String>.from(j['usedActions'] ?? []),
        alive: j['alive'] ?? true,
        causeOfDeath: j['causeOfDeath'],
      );
}
