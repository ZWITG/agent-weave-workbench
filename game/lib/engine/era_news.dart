/// The news in an era life (Legends plan §5.8, Phase 2C): a town crier's
/// proclamations, handwritten avvisi, printed corantos, or word from the
/// caravans, as each place really had it. Each year's issue carries a few
/// small, capped effects ("Prices +4%"). Only timeline lives reach this
/// file; the modern newspaper (world.dart, newspaper.dart) never runs in
/// them.
library;

import 'dart:math';

import 'era_health.dart' show eraPlagueHere;
import 'era_justice.dart' show eraCourt;
import 'eras.dart';
import 'models.dart';

/// One story in an issue, with its effect line if it has one.
typedef EraStory = ({String text, String? effect});

/// One year's news where a life lives.
typedef EraIssue = ({
  String title,
  String line,
  String kind,
  int year,
  List<EraStory> stories,
  Map<String, int> effects,
});

/// The kind of news-sheet here and now, and its masthead.
({String title, String line, String kind}) eraPaper(Life l, EraRules era) {
  final p = eraFirst(era.newsData['papers'] as List?, l, era);
  if (p == null) {
    return (title: 'Proclamation', line: 'Cried in the square', kind: 'crier');
  }
  return (
    // "Avvisi di Venezia": the city's own name on the masthead.
    title: (p['title'] as String).replaceAll(
      '{city}',
      ((era.newsData['cityNames'] as Map?)?[l.city] as String?) ?? l.city,
    ),
    line: p['line'] as String? ?? '',
    kind: p['kind'] as String? ?? 'crier',
  );
}

String _effectLine(String k, int v) => switch (k) {
  'prices' => 'Prices ${v >= 0 ? '+' : '−'}${v.abs()}% this year',
  'plague' => 'Plague risk up',
  'watch' => 'The watch is doubled',
  _ => '',
};

/// The issue for [year] (this year by default) where [l] lives: dated
/// stories for this place, the plague if it is here, and a little local
/// news. Effects are capped so news nudges a life and never decides it.
EraIssue eraIssue(Life l, EraRules era, {int? year}) {
  final y = year ?? l.year;
  final paper = eraPaper(l, era);
  final stories = <EraStory>[];
  final effects = <String, int>{};
  for (final raw in (era.newsData['stories'] as List?) ?? const []) {
    final s = raw as Map;
    if (s['year'] != y) continue;
    if (!eraScoped({...s, 'from': null, 'to': null}, l, era, year: y)) continue;
    final e = Map<String, dynamic>.from((s['effect'] as Map?) ?? const {});
    String? line;
    e.forEach((k, v) {
      effects[k] = (effects[k] ?? 0) + (v as int);
      line ??= _effectLine(k, v);
    });
    stories.add((text: s['text'] as String, effect: line));
  }
  // The plague, when it is here.
  if (eraPlagueHere(l, era, year: y)) {
    effects['plague'] = 1;
    stories.insert(0, (
      text: 'Plague in ${l.city}. The health office shuts the houses of the sick.',
      effect: _effectLine('plague', 1),
    ));
  }
  // Caps: news nudges, it never decides.
  if (effects.containsKey('prices')) {
    effects['prices'] = effects['prices']!.clamp(-10, 10).toInt();
  }
  if (effects.containsKey('watch')) effects['watch'] = 1;
  if (effects.containsKey('plague')) effects['plague'] = 1;
  // Local news, the same each time this year is read.
  final group = era.regionOf(l).group;
  final local = List<String>.from(
    ((era.newsData['local'] as Map?) ?? const {})[group] as List? ?? const [],
  );
  if (local.isNotEmpty) {
    final rng = Random(l.seed ^ (y * 131));
    final court = eraCourt(l, era);
    final pick = local[rng.nextInt(local.length)]
        .replaceAll('{court}', _cap(court['court'] as String))
        .replaceAll('{Drum}', _cap(court['drum'] as String))
        .replaceAll('{drum}', court['drum'] as String)
        .replaceAll('{n}', '${3 + rng.nextInt(9)}');
    stories.add((text: pick, effect: null));
  }
  return (
    title: paper.title,
    line: paper.line,
    kind: paper.kind,
    year: y,
    stories: stories,
    effects: effects,
  );
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// The first dated story this year, for the Life feed, or null in a
/// quiet year.
String? eraHeadline(Life l, EraRules era) {
  final issue = eraIssue(l, era);
  final dated = issue.stories.length > 1 || _isDated(l, era, issue.year)
      ? issue.stories.first.text
      : null;
  return dated == null ? null : '${issue.title}: $dated';
}

bool _isDated(Life l, EraRules era, int y) {
  for (final raw in (era.newsData['stories'] as List?) ?? const []) {
    final s = raw as Map;
    if (s['year'] == y && eraScoped({...s, 'from': null, 'to': null}, l, era, year: y)) {
      return true;
    }
  }
  return false;
}

/// The years of this life that had dated news here, newest first.
List<int> eraBackIssues(Life l, EraRules era) {
  final out = <int>{};
  for (final raw in (era.newsData['stories'] as List?) ?? const []) {
    final y = (raw as Map)['year'] as int;
    if (y >= l.birthYear + 6 && y <= l.year) {
      if (eraScoped({...raw, 'from': null, 'to': null}, l, era, year: y)) {
        out.add(y);
      }
    }
  }
  return out.toList()..sort((a, b) => b.compareTo(a));
}
