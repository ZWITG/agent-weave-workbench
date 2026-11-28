/// Activities in an era life (Legends plan §5.8, Phase 2D): carnival, the
/// feast of San Giovanni, calcio, jousts, pallacorda, cards and dice, the
/// tavern, the bathhouse or hammam, music, riding out, the market, the
/// pilgrimage and the hajj, the London playhouse, court dances in Kongo,
/// the night streets and journeys. Each place and year has its own, and
/// each plays on an existing mini-game in an era skin. Where custom barred
/// someone, the activity says so plainly. Only timeline lives reach here.
library;

import 'dart:math';

import 'era_faith.dart' show eraFaithOf, eraStanding;
import 'era_justice.dart' show eraInside;
import 'era_market.dart';
import 'era_path.dart' show eraStatus;
import 'era_wealth.dart';
import 'eras.dart';
import 'models.dart';

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

/// The activities of this place and year (one per id: the place's
/// version), for someone of this life's age.
List<Map<String, dynamic>> eraActivitiesHere(Life l, EraRules era) {
  final seen = <String>{};
  final out = <Map<String, dynamic>>[];
  for (final a in era.activityData) {
    if (!eraScoped(a, l, era)) continue;
    final faith = a['faith'] as List?;
    if (faith != null && !faith.contains(eraFaithOf(l))) continue;
    if (!seen.add(a['id'] as String)) continue;
    out.add(a);
  }
  return out;
}

/// The mini-game an activity plays (null: none, it just happens).
String? eraActivityGame(Map a) => a['game'] as String?;

bool _done(Life l, String id) => l.usedActions.contains('era_act_$id');

/// Why an activity can't be done now, or null.
String? eraActivityLock(Life l, EraRules era, Map a) {
  if (!l.alive) return 'This life is over.';
  if (eraInside(l)) return 'Not while you are held.';
  final id = a['id'] as String;
  final minAge = _int(a['minAge']);
  if (l.age < max(5, minAge)) return 'When you are older.';
  final maxAge = a['maxAge'] as int?;
  if (maxAge != null && l.age > maxAge) return 'Past the age for it.';
  if (a['market'] == true || a['law'] == true || a['journey'] == true) {
    return null;
  }
  if (a['once'] == true && l.eraWorld['did_$id'] == true) {
    return a['title'] == 'hajji' ? 'You are a hajji.' : 'Done once in this life.';
  }
  if (_done(l, id)) return 'Done this year.';
  if (a['men'] == true && l.gender != 'male') {
    return 'Custom keeps women out of it here. You can watch.';
  }
  final status = a['status'] as int?;
  if (status != null && eraStatus(l) < status) return 'Only for men of rank.';
  final needs = a['needs'] as String?;
  if (needs != null && !eraOwns(l, needs)) {
    return 'Needs a ${needs == 'horse' ? 'horse' : needs} (the market).';
  }
  final cost = eraCost(l, era, _int(a['cost']));
  if (l.money < cost) return 'Needs ${eraM(l, cost)}.';
  return null;
}

/// The cost shown on an activity's pill.
int eraActivityCost(Life l, EraRules era, Map a) => eraCost(l, era, _int(a['cost']));

/// Does an activity, after its mini-game: [score] is 0 to 1 (0.6 when
/// skipped). Pays, adds its effects, and records it in the feed.
String doEraActivity(
  Life l,
  EraRules era,
  String id,
  double score,
  Random rng,
) {
  final a = eraActivitiesHere(l, era).where((a) => a['id'] == id).firstOrNull;
  if (a == null) return 'Not here, not now.';
  final lock = eraActivityLock(l, era, a);
  if (lock != null) return lock;
  l.usedActions.add('era_act_$id');
  if (a['once'] == true) l.eraWorld['did_$id'] = true;
  final cost = eraActivityCost(l, era, a);
  l.money -= cost;
  final good = score >= 0.5;
  l.stats.add('happiness', (_int(a['happiness']) * (0.4 + score)).round());
  for (final s in ['health', 'smarts', 'creativity']) {
    if (a[s] != null) l.stats.add(s, _int(a[s]));
  }
  if (a['standing'] != null && good) {
    l.eraWorld['standing'] = min(5, eraStanding(l) + _int(a['standing']));
  }
  if (a['title'] == 'hajji') {
    l.flags['hajji'] = Memory(l.age, 'the hajj');
  }
  var text = (good ? a['good'] : a['bad']) as String? ?? '${a['label']}: done.';
  // Cards and dice: win or lose a little, and the dice are forbidden in
  // the Italian cities.
  if (a['gamble'] == true) {
    final stake = max(1, cost);
    final delta = good ? stake * (1 + rng.nextInt(3)) : -stake * (1 + rng.nextInt(2));
    l.money += delta;
    text += delta > 0
        ? ' (+${eraM(l, delta)})'
        : ' (−${eraM(l, -delta)})';
    final heat = ((a['heat'] as num?) ?? 0).toDouble();
    if (era.regionOf(l).group == 'italy' && rng.nextDouble() < heat) {
      l.eraWorld['heat'] = min(5, _int(l.eraWorld['heat']) + 1);
      text += ' Someone saw the dice come out. Your name may go in the drum.';
    }
  }
  l.feed.add(FeedEntry(l.age, '${a['label']}: $text', kind: 'action'));
  l.reason = a['label'] as String;
  return text;
}
