import 'dart:math';

import 'careers.dart' show careers, startCareer;
import 'models.dart';

/// Every storylet file in assets/storylets, in load order.
const storyletFiles = ['core.json', 'more.json'];

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
    this.conditions = const {},
    this.remembers,
    this.scene = false,
  });

  /// True for code-driven events built by scenes.dart.
  final bool scene;

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

  /// Life conditions: job (bool), retired (bool), money (">=5000"),
  /// owns (["house"]), childAge (">=16" or "13-17", oldest child),
  /// prison (bool).
  final Map<String, dynamic> conditions;

  /// Flag whose memory is shown on the card ("Remembers: …").
  final String? remembers;
  final List<Choice> choices;

  factory Storylet.fromJson(Map<String, dynamic> j) {
    final req = Map<String, dynamic>.from(j['requires'] ?? {});
    // Text that names a parent only fits families that have that parent
    // (single parents, two mums, two dads).
    final words = [
      j['text'],
      for (final c in j['choices'] as List) ...[c['label'], c['outcome']],
    ].join(' ');
    final npcs = List<String>.from(req['npcs'] ?? []);
    for (final p in const ['mother', 'father']) {
      if (words.contains('{$p}') && !npcs.contains(p)) npcs.add(p);
    }
    req['npcs'] = npcs;
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
      conditions: {
        for (final k in const [
          'job',
          'retired',
          'money',
          'owns',
          'childAge',
          'prison',
        ])
          if (req.containsKey(k)) k: req[k],
      },
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
      final npc = life.who(n);
      if (npc == null || !npc.alive) return false;
    }
    for (final e in statRules.entries) {
      if (!_compare(life.stats[e.key], e.value)) return false;
    }
    final job = conditions['job'];
    if (job is bool && (life.job != null) != job) return false;
    final retired = conditions['retired'];
    if (retired is bool && life.retired != retired) return false;
    final money = conditions['money'];
    if (money is String && !_compare(life.money, money)) return false;
    for (final kind in List<String>.from(conditions['owns'] ?? const [])) {
      if (!life.has(kind)) return false;
    }
    final childAge = conditions['childAge'];
    if (childAge is String) {
      final c = life.who('@child');
      if (c == null) return false;
      final age = c.ageIn(life.year);
      final range = RegExp(r'^(\d+)-(\d+)$').firstMatch(childAge);
      if (range != null) {
        if (age < int.parse(range.group(1)!) ||
            age > int.parse(range.group(2)!)) {
          return false;
        }
      } else if (!_compare(age, childAge)) {
        return false;
      }
    }
    if (conditions['prison'] != true && life.prison != null) return false;
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
  Choice({
    required this.label,
    required this.outcome,
    Effects? effects,
    this.run,
    this.needs = const {},
    this.needsMoney = 0,
    this.lock,
    this.risk,
  }) : effects = effects ?? Effects();

  final String label;
  final String outcome;
  final Effects effects;

  /// Scenes (scenes.dart): code that runs when chosen. It may return an
  /// outcome text that replaces [outcome].
  final String? Function(Life life, Random rng)? run;

  /// Requirements shown as a lock reason when unmet (plan: locked choices
  /// stay visible with the reason). Stats as rules, e.g. {"smarts": ">=60"}.
  final Map<String, String> needs;
  final int needsMoney;

  /// Code lock for scenes: returns a reason when the choice is unavailable.
  final String? Function(Life life)? lock;

  /// Odds hint shown on the button for risky choices ("Risky", "Likely").
  final String? risk;

  /// Null when the choice can be taken, otherwise why not.
  String? lockReason(Life life) {
    for (final e in needs.entries) {
      if (!Storylet._compare(life.stats[e.key], e.value)) {
        return 'Needs ${e.key[0].toUpperCase()}${e.key.substring(1)} ${e.value.replaceAll('>=', '')}+';
      }
    }
    if (needsMoney > 0 && life.money < needsMoney) return 'Needs \$$needsMoney';
    return lock?.call(life);
  }

  factory Choice.fromJson(Map<String, dynamic> j) => Choice(
    label: j['label'],
    outcome: j['outcome'] ?? '',
    effects: Effects.fromJson(Map<String, dynamic>.from(j['effects'] ?? {})),
    needs: Map<String, String>.from(j['needs'] ?? {}),
    needsMoney: j['needsMoney'] ?? 0,
    risk: j['risk'],
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
      final npc = life.who(id);
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
      final npc = life.who(id);
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
    if (education != null) {
      life.education = education!;
      life.eduSince = life.age;
    }
    if (job != null) {
      // A job title on a career ladder joins that career properly (ladder,
      // boss, performance); anything else is a one-off job.
      final career = careers.where((c) => c.ladder.contains(job)).firstOrNull;
      if (career != null) {
        startCareer(life, career);
        life.careerRank = career.ladder.indexOf(job!);
        life.job = job;
        life.salary = salary ?? career.salaryAt(life.careerRank);
      } else {
        life.job = job == 'none' ? null : job;
        life.salary = salary ?? 0;
        life.careerId = null;
        life.careerRank = 0;
        life.jobSince = life.age;
      }
    }
    return notes;
  }
}

String _cap(String s) => s[0].toUpperCase() + s.substring(1);
String _signed(int v) => v > 0 ? '+$v' : '−${v.abs()}';
