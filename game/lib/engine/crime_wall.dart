import 'dart:math';

import 'justice.dart' show crimeById, convictions, onParole;
import 'models.dart';
import 'underworld.dart';

// The alley remembers (Back Alley, ui/back_alley.dart): every kind of crime
// you commit leaves a tag on the wall, a chalk tally counts them all, and
// the police scanner talks about you in the radio voice of your city.

/// Crime-category actions that are not crimes in themselves.
const _notCrimes = {'lie_low', 'launder', 'turn_in', 'leave_crew', 'join_crew'};

/// Notes a crime for the wall. Called by the engine after any Crime
/// activity; kept for the whole life (marks are saved).
void noteCrime(Life l, String actionId) {
  if (_notCrimes.contains(actionId)) return;
  l.marks.add('wall:$actionId');
  final n = crimesCommitted(l) + 1;
  l.marks
    ..removeWhere((m) => m.startsWith('wall_n:'))
    ..add('wall_n:$n');
}

/// Every kind of crime you have done, in the order you first did it.
List<String> crimeTags(Life l) => [
  for (final m in l.marks)
    if (m.startsWith('wall:')) m.substring(5),
];

/// How many crimes you have committed in this life.
int crimesCommitted(Life l) {
  for (final m in l.marks) {
    if (m.startsWith('wall_n:')) return int.tryParse(m.substring(7)) ?? 0;
  }
  return 0;
}

/// The reward on your head: nothing until the police are interested,
/// then it climbs steeply with heat and open cases.
int bountyOf(Life l) {
  final h = heat(l);
  if (h < 45) return 0;
  final raw = h * h * 25 + l.cases.length * 15000;
  return (raw / 5000).round() * 5000;
}

/// The neon over the back door: your crew's front once you are in one,
/// otherwise the dive bar every alley has.
String neonSign(Life l) => switch (crewOf(l)?.id) {
  'harbour' => 'DOCK 9',
  'velvet' => 'VELVET',
  'southside' => 'SOUTHSIDE',
  _ => l.city.length <= 9 ? l.city.toUpperCase() : 'OPEN LATE',
};

/// Radio chatter about you, newest worries first. Changes each birthday.
List<String> scannerLines(Life l) {
  final r = Random(l.seed ^ (l.age * 7919));
  String unit() => '${r.nextInt(40) + 2}';
  final who = '${l.firstName[0]}. ${l.surname}';
  final h = heat(l);
  final crew = crewOf(l);
  final lines = <String>[];
  if (h >= 70) {
    lines.add(
      'All units, be on the lookout: ${l.fullName}, ${l.age}, last seen in ${l.city}. Approach with caution.',
    );
  }
  for (final c in l.cases.take(2)) {
    final label = crimeById(c['crime'] as String).label.toLowerCase();
    final ev = (c['evidence'] as int?) ?? 0;
    lines.add(
      ev >= 50
          ? 'Detectives say the $label file is nearly ready for charges. Suspect: $who.'
          : 'Still canvassing on the $label. Nobody saw anything. Yet.',
    );
  }
  if (l.dirty > 0) {
    lines.add(
      l.dirty >= 250000
          ? 'Financial crimes flagged large cash movements in ${l.city}. Following the money.'
          : 'Bank reported a cash deposit nobody can explain. Low priority.',
    );
  }
  if (crew != null) {
    lines.add(
      informant(l)
          ? 'Confidential informant "Nightingale" checked in. ${crew.name} suspect nothing.'
          : 'Surveillance van on ${crew.name}. Known associate: $who.',
    );
  }
  if (onParole(l)) {
    lines.add('Parole office: $who checked in on time. Keep an eye out.');
  }
  if (convictions(l) > 0 && h < 45) {
    lines.add(
      'Records check on $who: ${convictions(l)} prior. Nothing current.',
    );
  }
  // The city goes on without you.
  const filler = [
    'Noise complaint, unit {u}. Somebody playing the saxophone again.',
    'Car alarm on the high street. Probably the wind.',
    'Unit {u}, coffee run, over.',
    'Cat stuck on a fire escape. Fire service notified.',
    'Shoplifter caught at the corner store. Not our suspect.',
    'Quiet night downtown. Rain keeping everyone inside.',
    'Unit {u}, slow down on the bypass. That is an order.',
  ];
  final pool = [...filler]..shuffle(r);
  final want = max(3, lines.length + 1);
  for (final f in pool) {
    if (lines.length >= want) break;
    lines.add(f.replaceAll('{u}', unit()));
  }
  if (h == 0 && l.cases.isEmpty) {
    lines.insert(0, 'Dispatch: nothing on $who. Clean as a whistle.');
  }
  return lines;
}
