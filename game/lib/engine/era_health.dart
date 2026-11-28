/// Health in an era life (Legends plan §5.2 and §5.6, Phase 2C): the
/// plague in the real plague years of each place, the ailments of the
/// time, childhood and childbirth, and the healers you could send for:
/// barber-surgeons, apothecaries, physicians of the four humours,
/// hospitals and the nganga. As in history, setting a bone or resting
/// works; bleeding mostly doesn't. No modern medicine exists here. Only
/// timeline lives reach this file; modern health (health.dart, lifespan.dart)
/// never runs in them.
library;

import 'dart:math';

import 'currency.dart';
import 'era_faith.dart' show eraStanding;
import 'era_homes.dart' show eraCountryHome;
import 'era_justice.dart' show eraInside;
import 'eras.dart';
import 'legends.dart' show legendRegistry;
import 'models.dart';

/// Whether the plague is in this life's city in [year] (the data's plague
/// years, or a local outbreak that struck this year).
bool eraPlagueHere(Life l, EraRules era, {int? year}) {
  final y = year ?? l.year;
  if (l.eraWorld['outbreak'] == y) return true;
  for (final raw in (era.healthData['plagues'] as List?) ?? const []) {
    if (eraScoped(raw as Map, l, era, year: y)) return true;
  }
  return false;
}

/// The ailments this life has now, by id.
List<String> eraIllnesses(Life l) =>
    List<String>.from((l.eraWorld['ill'] as List?) ?? const []);

Map<String, dynamic>? eraAilment(EraRules era, String id) {
  for (final raw in (era.healthData['ailments'] as List?) ?? const []) {
    if ((raw as Map)['id'] == id) return Map<String, dynamic>.from(raw);
  }
  return null;
}

/// One healer you can send for here.
typedef EraHealer = ({String id, String name, String about, int fee});

/// The healers of this place and year, cheapest first, with the hospital
/// if the city has one.
List<EraHealer> eraHealers(Life l, EraRules era) {
  final out = <EraHealer>[];
  final seen = <String>{};
  final level = era.priceLevel(l.year) * era.regionOf(l).priceScale;
  for (final raw in (era.healthData['healers'] as List?) ?? const []) {
    final h = raw as Map;
    if (!eraScoped(h, l, era) || seen.contains(h['id'])) continue;
    seen.add(h['id'] as String);
    final fee = (h['fee'] as int? ?? 0) == 0
        ? 0
        : max(1, ((h['fee'] as int) * level).round());
    out.add((
      id: h['id'] as String,
      name: h['name'] as String,
      about: h['about'] as String? ?? '',
      fee: fee,
    ));
  }
  final hospital = eraHospital(l, era);
  if (hospital != null) {
    out.add((
      id: 'hospital',
      name: hospital,
      about: 'The hospital, for those with nothing',
      fee: 0,
    ));
  }
  out.sort((a, b) => a.fee.compareTo(b.fee));
  return out;
}

/// The city's hospital, if it has one this year.
String? eraHospital(Life l, EraRules era) {
  final h = ((era.healthData['hospitals'] as Map?) ?? const {})[l.city];
  final from =
      ((era.healthData['hospitalsFrom'] as Map?) ?? const {})[l.city] as int?;
  if (h == null || (from != null && l.year < from)) return null;
  return _cap(h as String);
}

/// The city's pest house (lazaretto), if it has one this year.
String? eraLazaretto(Life l, EraRules era) {
  final h = ((era.healthData['lazaretto'] as Map?) ?? const {})[l.city];
  final from =
      ((era.healthData['lazarettoFrom'] as Map?) ?? const {})[l.city] as int?;
  if (h == null || (from != null && l.year < from)) return null;
  return h as String;
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// The humour your body leans to, by the medicine of the time (Galen and
/// Avicenna). Flavour only: it changes nothing.
String eraHumour(Life l) {
  const humours = ['sanguine', 'choleric', 'melancholic', 'phlegmatic'];
  final h = l.stats['health'], s = l.stats['smarts'];
  if (h >= 70) return humours[0];
  if (s >= 70) return humours[2];
  return humours[(l.seed + l.age ~/ 10) % 4];
}

/// Why this life can't send for [h] about [ailment] now, or null.
String? eraHealLock(Life l, EraHealer h, String ailment) {
  if (!l.alive) return 'This life is over.';
  if (eraInside(l) && h.id != 'rest') return 'Not while you are held.';
  if (l.usedActions.contains('era_heal_$ailment')) return 'Tried this year.';
  if (h.fee > 0 && l.money < h.fee) return 'Needs ${moneyIn(h.fee, l.country)}.';
  return null;
}

/// Sends for a healer (or rests) about one ailment. Returns what happened.
String treatEraAilment(
  Life l,
  EraRules era,
  String ailment,
  String healerId,
  Random rng,
) {
  final a = eraAilment(era, ailment);
  if (a == null || !eraIllnesses(l).contains(ailment)) {
    return 'You are not ill with that.';
  }
  final healer = healerId == 'rest'
      ? (id: 'rest', name: 'Rest', about: '', fee: 0)
      : eraHealers(l, era).where((h) => h.id == healerId).firstOrNull;
  if (healer == null) return 'There is no one like that here.';
  final lock = eraHealLock(l, healer, ailment);
  if (lock != null) return lock;
  l.usedActions.add('era_heal_$ailment');
  l.money -= healer.fee;
  l.reason = a['name'] as String;
  final heal = Map<String, dynamic>.from((a['heal'] as Map?) ?? const {});
  // Bleeding and purging: what a healer does when the cure isn't known.
  final odds = ((heal[healer.id] as num?) ?? 0.12).toDouble();
  final risk = ((a['risk'] as Map?)?[healer.id] as num?)?.toDouble() ?? 0;
  final name = (a['name'] as String).toLowerCase();
  if (risk > 0 && rng.nextDouble() < risk) {
    l.stats.add('health', -25);
    return 'The cutting went badly. You lay in bed for weeks, weaker than before.';
  }
  if (rng.nextDouble() < odds) {
    _cure(l, ailment);
    l.stats.add('health', ((a['harm'] as int? ?? 6) ~/ 2) + 2);
    l.stats.add('happiness', 3);
    return switch (healer.id) {
      'rest' => 'You rested, kept warm and drank broth. $_up of $name.',
      'barber' when ailment == 'bone' =>
        'The barber-surgeon pulled the bone straight and bound it with splints. It healed well.',
      'barber' when ailment == 'stone' =>
        'The barber cut for the stone and you lived. It was over in minutes. You will never forget them.',
      'physician' =>
        'The physician studied your urine, bled you and gave a syrup. Whether it was the syrup or time, you got better.',
      'hospital' =>
        'The brothers and sisters of the hospital fed you and kept you clean. You walked out well.',
      'nganga' =>
        'The nganga gave you leaves to boil and spoke to the ancestors. You got better.',
      _ => '${healer.name}: it worked. $_up of $name.',
    };
  }
  return switch (healer.id) {
    'rest' => 'You rested, but $name would not lift this year.',
    'physician' =>
      'The physician bled you twice, to balance your humours. It did nothing.',
    'barber' => 'The barber let blood from your arm. It did nothing.',
    _ => '${healer.name} tried. It did not help this time.',
  };
}

const _up = 'You were up and about, clear';

void _cure(Life l, String ailment) =>
    l.eraWorld['ill'] = [...eraIllnesses(l)]..remove(ailment);

/// How you meet the plague this year: flee to the countryside, shut
/// yourself in, or stay and help the sick.
typedef EraPlagueChoice = ({String id, String label, String about, int cost});

List<EraPlagueChoice> eraPlagueChoices(Life l, EraRules era) {
  // A house in the country (Phase 2D) is free to go to.
  final villa = eraCountryHome(l, era);
  final away = villa != null
      ? 'your ${villa.label.replaceFirst(RegExp('^(A|An|The) '), '').toLowerCase()}'
      : (l.legendId == 'leonardo' && l.city == 'Florence'
            ? 'Vinci'
            : 'the countryside');
  final cost = villa != null
      ? 0
      : max(2, era.price('living_year', era.regionOf(l), l.year) ~/ 3);
  final pest = eraLazaretto(l, era);
  return [
    (
      id: 'flee',
      label: 'Flee to $away',
      about: 'The safest way, for those who can pay',
      cost: cost,
    ),
    (
      id: 'shut',
      label: 'Shut yourself in',
      about: 'Bar the door and wait for it to pass',
      cost: 0,
    ),
    (
      id: 'help',
      label: pest == null ? 'Stay and help the sick' : 'Help at $pest',
      about: 'Dangerous, and not forgotten by your neighbours',
      cost: 0,
    ),
  ];
}

/// The choice made for this year's plague, if any.
String? eraPlagueChoice(Life l) {
  final m = l.eraWorld['plagueChoice'] as Map?;
  return m != null && m['year'] == l.year ? m['id'] as String : null;
}

String chooseEraPlague(Life l, EraRules era, String id) {
  if (!eraPlagueHere(l, era)) return 'There is no plague here this year.';
  if (eraInside(l)) return 'Not while you are held.';
  if (eraPlagueChoice(l) != null) return 'You have chosen for this year.';
  final c = eraPlagueChoices(l, era).where((c) => c.id == id).firstOrNull;
  if (c == null) return 'Not here.';
  if (l.money < c.cost) return 'Needs ${moneyIn(c.cost, l.country)}.';
  l.money -= c.cost;
  l.eraWorld['plagueChoice'] = {'year': l.year, 'id': id};
  return switch (id) {
    'flee' =>
      'You packed what you could and left the city with the carts at dawn.',
    'shut' => 'You barred the door. Bread came in on a rope through the window.',
    _ => 'You went where the sick were. The gravediggers know your face now.',
  };
}

/// One year of health at a birthday: last year's plague is settled, a new
/// plague may come, ailments linger or pass, and new ones arrive. Sets
/// this year's extra death risk and its cause for eraDeathChance.
List<String> eraHealthYear(Life l, EraRules era, Random rng) {
  final out = <String>[];
  // A Legend is sheltered until their turning points have come, as the
  // death roll is (engine.dart).
  final legend = legendRegistry[l.legendId];
  final shelter =
      legend != null &&
          legend.turningPoints.any((p) => !l.pivots.containsKey(p.id))
      ? 0.3
      : 1.0;
  var risk = 0.0;
  String? cause;
  void add(double r, String c) {
    if (r > risk) cause = c;
    risk += r;
  }

  // Last year's plague: did it find you?
  final last = l.year - 1;
  if (eraPlagueHere(l, era, year: last)) {
    final choice = (l.eraWorld['plagueChoice'] as Map?)?['year'] == last
        ? (l.eraWorld['plagueChoice'] as Map)['id'] as String
        : null;
    final news = ((l.eraWorld['news'] as Map?)?['plague'] as int?) ?? 0;
    final odds =
        (0.13 + news * 0.03) *
        switch (choice) {
          'flee' => 0.15,
          'shut' => 0.6,
          'help' => 1.6,
          _ => 1.0,
        } *
        (eraInside(l) ? 1.5 : 1) *
        shelter;
    if (choice == 'help') {
      l.eraWorld['standing'] = min(5, eraStanding(l) + 1);
      l.stats.add('happiness', 3);
    }
    if (choice == 'flee') out.add('You came home when the plague had passed.');
    if (rng.nextDouble() < odds) {
      l.stats.add('health', -25);
      add(0.35, 'Plague');
      out.add('The plague found you. For days no one knew if you would live.');
      l.eraWorld['hadPlague'] = true;
    }
  }
  // A local outbreak in a year with no plague on record.
  final outbreak = Map<String, dynamic>.from(
    (era.healthData['outbreak'] as Map?) ?? const {},
  );
  if (!eraPlagueHere(l, era) &&
      eraScoped(outbreak, l, era) &&
      rng.nextDouble() < ((outbreak['chance'] as num?) ?? 0).toDouble()) {
    l.eraWorld['outbreak'] = l.year;
  }
  if (eraPlagueHere(l, era) && l.age >= 1) {
    l.reason = 'Plague year';
    l.stats.add('happiness', -6);
    out.add(
      'Plague has come to ${l.city}. Shops are shut, and carts go past at night.',
    );
  }
  // Ailments you carry.
  for (final id in eraIllnesses(l)) {
    final a = eraAilment(era, id);
    if (a == null) {
      _cure(l, id);
      continue;
    }
    final harm = a['harm'] as int? ?? 6;
    if (a['chronic'] == true) l.stats.add('health', -(harm ~/ 3));
    add(harm / 500, a['name'] as String);
    final rest = ((a['heal'] as Map?)?['rest'] as num?)?.toDouble() ?? 0.2;
    if (a['chronic'] != true && rng.nextDouble() < rest * 0.7) {
      _cure(l, id);
      out.add('${a['name']} passed with time.');
    }
  }
  // New ailments: at most two at once.
  for (final raw in (era.healthData['ailments'] as List?) ?? const []) {
    if (eraIllnesses(l).length >= 2) break;
    final a = raw as Map;
    if (eraIllnesses(l).contains(a['id'])) continue;
    if (!eraScoped(a, l, era)) continue;
    if (l.age < ((a['minAge'] as int?) ?? 0)) continue;
    if (l.age > ((a['maxAge'] as int?) ?? 120)) continue;
    if (a['sex'] != null && a['sex'] != l.gender) continue;
    final weak = l.stats['health'] < 40 ? 1.5 : 1.0;
    if (rng.nextDouble() <
        ((a['chance'] as num).toDouble()) * weak * 0.4 * shelter) {
      final harm = a['harm'] as int? ?? 6;
      l.stats.add('health', -(harm * 0.6).round());
      l.eraWorld['ill'] = [...eraIllnesses(l), a['id']];
      add(harm / 400, a['name'] as String);
      out.add('You fell ill: ${(a['name'] as String).toLowerCase()}.');
    }
  }
  // Childbirth: a child born this past year.
  if (l.gender == 'female') {
    for (final n in l.npcs) {
      if ((n.role == 'Son' || n.role == 'Daughter') &&
          n.birthYear == last &&
          l.eraWorld['birth_$last'] != true) {
        l.eraWorld['birth_$last'] = true;
        add(0.012, 'Childbirth');
      }
    }
  }
  l.eraWorld['risk'] = risk;
  // Only a serious illness is named as the cause; otherwise age is.
  l.eraWorld['cause'] = risk >= 0.03 ? cause : null;
  return out;
}

/// The cause of an era death this year, for the end of the story.
String eraDeathCause(Life l, {required bool frail}) {
  final c = l.eraWorld['cause'] as String?;
  if (c != null) return c;
  if (frail) return 'Illness';
  if (l.age > 60) return 'Old age';
  if (l.age < 5) return 'A childhood fever';
  return 'Fever';
}
