import 'models.dart';

/// A data-driven event. Storylets live in assets/storylets/*.json so new
/// content ships without code changes (see 08 Technical Architecture).
class Storylet {
  Storylet({
    required this.id,
    required this.text,
    required this.choices,
    this.category = 'life',
    this.minAge = 0,
    this.maxAge = 120,
    this.weight = 10,
    this.once = true,
    this.cooldown = 0,
    this.requiresFlags = const [],
    this.forbidsFlags = const [],
    this.requiresNpcs = const [],
    this.statRules = const {},
    this.remembers,
  });

  final String id;
  final String text;
  final String category;
  final int minAge;
  final int maxAge;
  final int weight;
  final bool once;
  final int cooldown;
  final List<String> requiresFlags;
  final List<String> forbidsFlags;
  final List<String> requiresNpcs;

  /// e.g. {"smarts": ">=60"}.
  final Map<String, String> statRules;

  /// Flag whose memory is shown on the card ("Remembers: …").
  final String? remembers;
  final List<Choice> choices;

  factory Storylet.fromJson(Map<String, dynamic> j) {
    final req = Map<String, dynamic>.from(j['requires'] ?? {});
    return Storylet(
      id: j['id'],
      text: j['text'],
      category: j['category'] ?? 'life',
      minAge: j['minAge'] ?? 0,
      maxAge: j['maxAge'] ?? 120,
      weight: j['weight'] ?? 10,
      once: j['once'] ?? true,
      cooldown: j['cooldown'] ?? 0,
      requiresFlags: List<String>.from(req['flags'] ?? []),
      forbidsFlags: List<String>.from(req['notFlags'] ?? []),
      requiresNpcs: List<String>.from(req['npcs'] ?? []),
      statRules: Map<String, String>.from(req['stats'] ?? {}),
      remembers: j['remembers'],
      choices: (j['choices'] as List)
          .map((c) => Choice.fromJson(Map<String, dynamic>.from(c)))
          .toList(),
    );
  }

  bool isEligible(Life life) {
    if (life.age < minAge || life.age > maxAge) return false;
    final seen = life.lastSeen[id];
    if (seen != null) {
      if (once) return false;
      if (life.age - seen < cooldown) return false;
    }
    for (final f in requiresFlags) {
      if (!life.flags.containsKey(f)) return false;
    }
    for (final f in forbidsFlags) {
      if (life.flags.containsKey(f)) return false;
    }
    for (final n in requiresNpcs) {
      final npc = life.npc(n);
      if (npc == null || !npc.alive) return false;
    }
    for (final e in statRules.entries) {
      if (!_compare(life.stats[e.key], e.value)) return false;
    }
    return true;
  }

  static bool _compare(int value, String rule) {
    final m = RegExp(r'^(>=|<=|>|<|==)\s*(\d+)$').firstMatch(rule.trim());
    if (m == null) return true;
    final n = int.parse(m.group(2)!);
    switch (m.group(1)) {
      case '>=':
        return value >= n;
      case '<=':
        return value <= n;
      case '>':
        return value > n;
      case '<':
        return value < n;
      default:
        return value == n;
    }
  }
}

class Choice {
  Choice({required this.label, required this.outcome, required this.effects});

  final String label;
  final String outcome;
  final Effects effects;

  factory Choice.fromJson(Map<String, dynamic> j) => Choice(
    label: j['label'],
    outcome: j['outcome'] ?? '',
    effects: Effects.fromJson(Map<String, dynamic>.from(j['effects'] ?? {})),
  );
}

class Effects {
  Effects({
    this.stats = const {},
    this.bond = const {},
    this.money = 0,
    this.setFlags = const {},
    this.clearFlags = const [],
    this.npcMemory = const {},
    this.addNpcs = const [],
    this.resolveGrudges = const [],
    this.education,
    this.job,
    this.salary,
  });

  final Map<String, int> stats;
  final Map<String, int> bond;
  final int money;

  /// flag id -> human label shown later as "Remembers: <label>".
  final Map<String, String> setFlags;
  final List<String> clearFlags;

  /// npc id -> memory the NPC keeps: a string, or
  /// {"text", "valence" (-3..3), "intensity" (1..5), "tags": [...]}.
  final Map<String, dynamic> npcMemory;

  /// New people entering the life: {"id", "role", "name", "circle", "bond", "ageOffset"}.
  final List<Map<String, dynamic>> addNpcs;

  /// NPC ids whose negative memories fade and resentment drops (reconciliation).
  final List<String> resolveGrudges;
  final String? education;
  final String? job;
  final int? salary;

  factory Effects.fromJson(Map<String, dynamic> j) => Effects(
    stats: Map<String, int>.from(j['stats'] ?? {}),
    bond: Map<String, int>.from(j['bond'] ?? {}),
    money: j['money'] ?? 0,
    setFlags: Map<String, String>.from(j['flags'] ?? {}),
    clearFlags: List<String>.from(j['clearFlags'] ?? []),
    npcMemory: Map<String, dynamic>.from(j['npcMemory'] ?? {}),
    addNpcs: ((j['addNpcs'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e))
        .toList(),
    resolveGrudges: List<String>.from(j['resolveGrudges'] ?? []),
    education: j['education'],
    job: j['job'],
    salary: j['salary'],
  );

  /// Applies the effects and returns short change notes for the outcome
  /// screen ("Happiness +5", "Bond with Leo −10").
  List<String> apply(Life life) {
    final notes = <String>[];
    stats.forEach((k, v) {
      life.stats.add(k, v);
      if (v != 0 && Stats.visible.contains(k)) {
        notes.add('${_cap(k)} ${_signed(v)}');
      }
    });
    bond.forEach((id, v) {
      final npc = life.npc(id);
      if (npc != null && v != 0) {
        final before = npc.bond;
        npc.addBond(v);
        npc.lastContactAge = life.age;
        final d = npc.bond - before;
        if (d != 0) notes.add('Bond with ${npc.name} ${_signed(d)}');
      }
    });
    if (money != 0) {
      life.money += money;
      notes.add('Money ${money > 0 ? '+' : '−'}\$${money.abs()}');
    }
    setFlags.forEach((k, label) => life.flags[k] = Memory(life.age, label));
    for (final f in clearFlags) {
      life.flags.remove(f);
    }
    for (final a in addNpcs) {
      if (life.npc(a['id']) != null) continue;
      final n = Npc(
        id: a['id'],
        role: a['role'],
        name: a['name'],
        circle: a['circle'] ?? 'Friends',
        birthYear: life.year - life.age + ((a['ageOffset'] as int?) ?? 0),
        bond: (a['bond'] as int?) ?? 60,
      )..lastContactAge = life.age;
      life.npcs.add(n);
      notes.add('${n.name} joined your ${n.circle.toLowerCase()}');
    }
    for (final id in resolveGrudges) {
      final npc = life.npc(id);
      if (npc == null) continue;
      for (final m in npc.memories.where((m) => m.negative)) {
        m.intensity = 0;
      }
      npc.addFacets(resentment: -40);
    }
    npcMemory.forEach((id, m) {
      final npc = life.npc(id);
      if (npc == null) return;
      final mem = m is String
          ? NpcMemory(
              age: life.age,
              text: m,
              valence: -2,
              intensity: 4,
              tags: ['story'],
            )
          : NpcMemory(
              age: life.age,
              text: m['text'],
              valence: m['valence'] ?? -1,
              intensity: ((m['intensity'] as num?) ?? 2).toDouble(),
              tags: List<String>.from(m['tags'] ?? []),
            );
      npc.remember(mem);
    });
    if (education != null) life.education = education!;
    if (job != null) {
      life.job = job == 'none' ? null : job;
      life.salary = salary ?? 0;
    }
    return notes;
  }
}

String _cap(String s) => s[0].toUpperCase() + s.substring(1);
String _signed(int v) => v > 0 ? '+$v' : '−${v.abs()}';
