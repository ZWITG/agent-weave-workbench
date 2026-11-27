/// A Timeline world (Legends plan §8): a history that starts in the past
/// (1450 for the Renaissance) and runs forward one year at a time. It is
/// kept apart from the modern 2026 [World], which it never touches; only
/// a linked timeline is read by the modern world (past.dart).
library;

import 'dart:math';

class Timeline {
  Timeline({
    required this.id,
    required this.era,
    required this.startYear,
    int? year,
    int? seed,
    this.legendId,
    Map<String, int>? facts,
    Map<String, int>? currents,
    List<String>? log,
  }) : year = year ?? startYear,
       seed = seed ?? Random().nextInt(1 << 30),
       facts = facts ?? {},
       currents = currents ?? {},
       log = log ?? [];

  final String id;

  /// The era whose rules apply (eras.dart), e.g. "renaissance".
  final String era;
  final int startYear;

  /// The furthest year this timeline has reached.
  int year;
  final int seed;

  /// The Legend this timeline was started with, if any.
  final String? legendId;

  /// World facts: what is true in this history and since when
  /// ("milan_holds_1499" -> 1499). Rewritten turning points write here.
  final Map<String, int> facts;

  /// Long-running currents (Science, Faith, Arts, Mercantile...) 0-100.
  final Map<String, int> currents;

  /// One line per notable thing that happened, oldest first.
  final List<String> log;

  bool has(String fact) => facts.containsKey(fact);

  /// Writes a world fact once; returns false if it was already true.
  bool write(String fact, int inYear, [String? line]) {
    if (facts.containsKey(fact)) return false;
    facts[fact] = inYear;
    if (line != null) log.add('$inYear: $line');
    return true;
  }

  void advanceTo(int y) => year = max(year, y);

  void addCurrent(String name, int amount) =>
      currents[name] = ((currents[name] ?? 0) + amount).clamp(0, 100);

  Map<String, dynamic> toJson() => {
    'id': id,
    'era': era,
    'startYear': startYear,
    'year': year,
    'seed': seed,
    if (legendId != null) 'legendId': legendId,
    'facts': facts,
    'currents': currents,
    'log': log,
  };

  factory Timeline.fromJson(Map<String, dynamic> j) => Timeline(
    id: j['id'],
    era: j['era'],
    startYear: j['startYear'],
    year: j['year'],
    seed: j['seed'],
    legendId: j['legendId'],
    facts: Map<String, int>.from(j['facts'] ?? const {}),
    currents: Map<String, int>.from(j['currents'] ?? const {}),
    log: List<String>.from(j['log'] ?? const []),
  );
}
