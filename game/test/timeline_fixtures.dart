import 'dart:convert';
import 'dart:io';

import 'package:relivable/engine/engine.dart';
import 'package:relivable/engine/eras.dart';
import 'package:relivable/engine/legends.dart';
import 'package:relivable/engine/models.dart';
import 'package:relivable/engine/storylet.dart';
import 'package:relivable/engine/timeline.dart';
import 'package:relivable/engine/world.dart';

Map<String, dynamic> readJson(String path) =>
    Map<String, dynamic>.from(jsonDecode(File(path).readAsStringSync()));

List<Storylet> modernStorylets() => [
  for (final file in storyletFiles)
    ...(jsonDecode(File('assets/storylets/$file').readAsStringSync()) as List)
        .map((e) => Storylet.fromJson(Map<String, dynamic>.from(e))),
];

/// Loads the era files and Legends the way the game controller does.
void loadTimelineContent() {
  for (final f in eraFiles) {
    registerEra(EraRules.fromJson(readJson('assets/eras/$f')));
  }
  for (final f in legendFiles) {
    registerLegend(Legend.fromJson(readJson('assets/legends/$f')));
  }
}

GameEngine timelineEngine({World? world}) {
  loadTimelineContent();
  return GameEngine([...modernStorylets(), ...timelineStorylets()], world: world);
}

/// Plays a life to its end. [pick] chooses the choice index for each event
/// (it sees only the choices the card would show).
Life playOut(
  GameEngine e,
  Life life,
  int Function(Storylet s, List<Choice> shown) pick,
) {
  var guard = 0;
  while (life.alive && guard++ < 130) {
    final s = e.ageUp(life);
    if (s == null) continue;
    final shown = visibleChoices(life, s);
    if (shown.isEmpty) continue;
    final c = shown[pick(s, shown).clamp(0, shown.length - 1)];
    if (c.lockReason(life) != null) continue;
    e.choose(life, s, c);
  }
  return life;
}

Timeline newTimeline(String era, int start, {String? legend, int seed = 7}) =>
    Timeline(id: 'tl_$seed', era: era, startYear: start, seed: seed, legendId: legend);

/// A grown-up nobody of the era, living in [city] in [year].
Life blankEraLife({required String city, required int year}) {
  final era = eraRegistry['renaissance']!;
  final r = era.regionOfCity(city);
  return Life(
    seed: 1,
    firstName: 'Test',
    surname: 'Case',
    gender: 'male',
    country: r.nameIn(year),
    city: city,
    birthYear: year - 30,
    stats: Stats({}),
    npcs: [],
  )
    ..age = 30
    ..era = 'renaissance';
}
