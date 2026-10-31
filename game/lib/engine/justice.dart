import 'dart:math';

import 'crime_jobs.dart';
import 'gangs.dart';
import 'prison_life.dart';
import 'actions.dart';
import 'jobs.dart' show leaveJob;
import 'love.dart' show partnerOf, recircle;
import 'models.dart';
import 'storylet.dart';
import 'world_data.dart';

/// Crime and justice (plan Module 8): every crime shows its risk and the
/// reasons behind it, leaves evidence the police may follow for years, and
/// runs through a real pipeline: arrest → charge and plea → lawyer → trial
/// → sentence → prison → parole or appeal → release with a record.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '−' : ''}\$$s';
}

typedef Crime = ({
  String id,
  String label,
  int minAge,
  int risk,
  int evidence,
  String band,
  int gainMin,
  int gainMax,
  int karma,
  bool violent,
  int since,
  String done,
  String caught,
});

const crimes = <Crime>[
  (
    id: 'shoplifting',
    label: 'Shoplifting',
    minAge: 10,
    risk: 30,
    evidence: 30,
    band: 'minor',
    gainMin: 20,
    gainMax: 80,
    karma: -3,
    violent: false,
    since: 0,
    done: '',
    caught: '',
  ),
  (
    id: 'vandalism',
    label: 'Vandalism',
    minAge: 10,
    risk: 25,
    evidence: 20,
    band: 'minor',
    gainMin: 0,
    gainMax: 0,
    karma: -2,
    violent: false,
    since: 0,
    done: '',
    caught: '',
  ),
  (
    id: 'pickpocketing',
    label: 'Pickpocketing',
    minAge: 12,
    risk: 35,
    evidence: 25,
    band: 'minor',
    gainMin: 20,
    gainMax: 140,
    karma: -5,
    violent: false,
    since: 0,
    done: '',
    caught: '',
  ),
  (
    id: 'porch_theft',
    label: 'Porch-parcel theft',
    minAge: 12,
    risk: 20,
    evidence: 25,
    band: 'minor',
    gainMin: 30,
    gainMax: 200,
    karma: -3,
    violent: false,
    since: 0,
    done: 'You strolled up a garden path, picked up a parcel and strolled away. Inside: {gain} worth of something.',
    caught: 'The parcel was a decoy, the doorbell was a camera and the neighbour was a retired detective.',
  ),
  (
    id: 'burglary',
    label: 'Burglary',
    minAge: 16,
    risk: 35,
    evidence: 45,
    band: 'moderate',
    gainMin: 500,
    gainMax: 6000,
    karma: -8,
    violent: false,
    since: 0,
    done: 'A back window, a dark house and twelve terrifying minutes. You got away with {gain} in cash and valuables.',
    caught: 'A motion light snapped on, a dog started barking and a police car was already turning into the street.',
  ),
  (
    id: 'car_theft',
    label: 'Car theft',
    minAge: 16,
    risk: 40,
    evidence: 50,
    band: 'moderate',
    gainMin: 2000,
    gainMax: 9000,
    karma: -8,
    violent: false,
    since: 0,
    done: 'You drove a stranger\'s car to a garage with no sign and no questions. They paid {gain}.',
    caught:
        'The car had a tracker. Police were waiting at the end of the road.',
  ),
  (
    id: 'fraud',
    label: 'Fraud',
    minAge: 18,
    risk: 30,
    evidence: 40,
    band: 'moderate',
    gainMin: 3000,
    gainMax: 25000,
    karma: -10,
    violent: false,
    since: 0,
    done: 'A fake investment, a confident smile and a lot of trusting people. {gain} landed in your account.',
    caught: 'One of your "investors" was an undercover fraud officer.',
  ),
  (
    id: 'hacking',
    label: 'Hacking',
    minAge: 16,
    risk: 30,
    evidence: 35,
    band: 'moderate',
    gainMin: 2000,
    gainMax: 20000,
    karma: -6,
    violent: false,
    since: 1990,
    done: 'Three nights, nine energy drinks and one forgotten password later, {gain} moved quietly into your wallet.',
    caught: 'You forgot to hide your address. Officers knocked before the download finished.',
  ),
  (
    id: 'embezzlement',
    label: 'Embezzlement',
    minAge: 18,
    risk: 15,
    evidence: 30,
    band: 'moderate',
    gainMin: 0,
    gainMax: 0,
    karma: -10,
    violent: false,
    since: 0,
    done: 'A few invoices from a company that does not exist. Your employer paid {gain} and nobody noticed. Yet.',
    caught: 'An auditor asked one question you could not answer.',
  ),
  (
    id: 'tax_evasion',
    label: 'Tax evasion',
    minAge: 18,
    risk: 10,
    evidence: 25,
    band: 'moderate',
    gainMin: 0,
    gainMax: 0,
    karma: -5,
    violent: false,
    since: 0,
    done: 'You "forgot" to declare a chunk of income and kept {gain} the tax office should have had.',
    caught: 'A tax audit letter arrived. Then a second, angrier one.',
  ),
  (
    id: 'assault',
    label: 'Assault',
    minAge: 14,
    risk: 60,
    evidence: 70,
    band: 'serious',
    gainMin: 0,
    gainMax: 0,
    karma: -15,
    violent: true,
    since: 0,
    done: 'An argument turned into a fight and you threw the first punch. You walked away; they did not, for a while.',
    caught: 'There were witnesses, and one of them was filming.',
  ),
  (
    id: 'armed_robbery',
    label: 'Armed robbery',
    minAge: 18,
    risk: 55,
    evidence: 65,
    band: 'serious',
    gainMin: 3000,
    gainMax: 40000,
    karma: -20,
    violent: true,
    since: 0,
    done: 'Masks, a getaway car and ninety seconds you will dream about for years. You got away with {gain}.',
    caught: 'The getaway driver panicked and drove into a bollard. Sirens everywhere.',
  ),
  (
    id: 'murder',
    label: 'Murder',
    minAge: 18,
    risk: 55,
    evidence: 80,
    band: 'severe',
    gainMin: 0,
    gainMax: 0,
    karma: -40,
    violent: true,
    since: 0,
    done: '',
    caught:
        'Detectives found what you missed. A neighbour remembered your car.',
  ),
  (
    id: 'heist',
    label: 'Heist',
    minAge: 18,
    risk: 0,
    evidence: 55,
    band: 'serious',
    gainMin: 0,
    gainMax: 0,
    karma: -8,
    violent: false,
    since: 0,
    done: '',
    caught: '',
  ),
  (
    id: 'black_market',
    label: 'Buying stolen goods',
    minAge: 18,
    risk: 15,
    evidence: 40,
    band: 'minor',
    gainMin: 0,
    gainMax: 0,
    karma: -3,
    violent: false,
    since: 0,
    done: '',
    caught: '',
  ),
  (
    id: 'extortion',
    label: "Extortion",
    minAge: 18,
    risk: 30,
    evidence: 45,
    band: 'serious',
    gainMin: 2000,
    gainMax: 15000,
    karma: -12,
    violent: false,
    since: 0,
    done: "You explained to a shop owner how unlucky their windows might be. They paid {gain} and will keep paying.",
    caught: "The shop owner had a panic button and a cousin in the police.",
  ),
  (
    id: 'counterfeiting',
    label: "Counterfeiting",
    minAge: 18,
    risk: 25,
    evidence: 45,
    band: 'moderate',
    gainMin: 1000,
    gainMax: 12000,
    karma: -6,
    violent: false,
    since: 0,
    done: "A back-room printer, good paper and nerves of steel. You passed {gain} of fakes before anyone looked closely.",
    caught:
        "A cashier held your note up to the light, then picked up the phone.",
  ),
  (
    id: 'smuggling',
    label: "Smuggling",
    minAge: 18,
    risk: 30,
    evidence: 50,
    band: 'serious',
    gainMin: 5000,
    gainMax: 40000,
    karma: -8,
    violent: false,
    since: 0,
    done: "Crates that were not what the paperwork said, through a port that asked no questions. Your cut: {gain}.",
    caught: "A sniffer dog sat down next to your crate and would not move.",
  ),
  (
    id: 'identity_theft',
    label: "Identity theft",
    minAge: 16,
    risk: 25,
    evidence: 35,
    band: 'moderate',
    gainMin: 1000,
    gainMax: 10000,
    karma: -8,
    violent: false,
    since: 1995,
    done: "A stolen identity, three new credit cards and a shopping spree. {gain} in goods, in someone else's name.",
    caught: "The real owner of the name reported the cards the same afternoon.",
  ),
  (
    id: 'insider_trading',
    label: "Insider trading",
    minAge: 21,
    risk: 15,
    evidence: 40,
    band: 'moderate',
    gainMin: 3000,
    gainMax: 60000,
    karma: -6,
    violent: false,
    since: 1934,
    done: "A friend at a company mentioned a takeover, and you bought shares the day before. Profit: {gain}.",
    caught: "The regulator's computer noticed your perfect timing.",
  ),
  (
    id: 'insurance_fraud',
    label: "Insurance fraud",
    minAge: 18,
    risk: 25,
    evidence: 45,
    band: 'moderate',
    gainMin: 2000,
    gainMax: 20000,
    karma: -8,
    violent: false,
    since: 0,
    done: "A convenient 'accident', a dramatic claim and a sympathetic adjuster. The insurer paid {gain}.",
    caught: "The adjuster had seen your exact 'accident' before. Twice.",
  ),
  (
    id: 'street_racing',
    label: "Street racing",
    minAge: 17,
    risk: 30,
    evidence: 25,
    band: 'minor',
    gainMin: 300,
    gainMax: 3000,
    karma: -2,
    violent: false,
    since: 1950,
    done: "Engines screaming down an empty industrial road at 2am. You won the race and {gain} in bets.",
    caught: "A police car was parked at the finish line with its lights off.",
  ),
  (
    id: 'money_laundering',
    label: "Money laundering",
    minAge: 18,
    risk: 0,
    evidence: 50,
    band: 'serious',
    gainMin: 0,
    gainMax: 0,
    karma: -6,
    violent: false,
    since: 0,
    done: "",
    caught: "",
  ),
  (
    id: 'racketeering',
    label: "Racketeering",
    minAge: 18,
    risk: 0,
    evidence: 60,
    band: 'serious',
    gainMin: 0,
    gainMax: 0,
    karma: -10,
    violent: false,
    since: 0,
    done: "",
    caught: "",
  ),
  (
    id: 'escape',
    label: 'Escaping custody',
    minAge: 10,
    risk: 0,
    evidence: 95,
    band: 'serious',
    gainMin: 0,
    gainMax: 0,
    karma: -5,
    violent: false,
    since: 0,
    done: '',
    caught: '',
  ),
];

Crime crimeById(String id) =>
    crimes.firstWhere((c) => c.id == id, orElse: () => crimes.first);

const violentCrimes = {'assault', 'armed_robbery', 'murder'};

/// Street smarts: plan "Cunning", from Smarts and Charisma.
int cunning(Life l) => (l.stats['smarts'] + l.stats['charisma']) ~/ 2;

int convictions(Life l) => l.record.where((r) => r['sealed'] != true).length;

bool hasSeriousRecord(Life l) => l.record.any(
  (r) =>
      r['sealed'] != true && (r['band'] == 'serious' || r['band'] == 'severe'),
);

bool onParole(Life l) {
  for (final m in l.marks) {
    if (m.startsWith('parole_until:') &&
        l.age < (int.tryParse(m.substring(13)) ?? 0)) {
      return true;
    }
  }
  return false;
}

/// Chance of being caught in the act, with the reasons.
(int, List<String>) caughtOdds(Life l, Crime c) {
  final why = <String>[];
  var p = c.risk;
  if (c.id == 'porch_theft' && l.year >= 2015) {
    p += 15;
    why.add('Doorbell cameras +15');
  }
  final police = l.worldMods['policing'] ?? 0;
  if (police != 0) {
    p += police;
    why.add('Police patrols in the news ${police > 0 ? '+' : ''}$police');
  }
  final skill = (cunning(l) - 50) ~/ 3;
  if (skill != 0) {
    p -= skill;
    why.add('Smarts and Charisma ${skill > 0 ? '−$skill' : '+${-skill}'}');
  }
  if (l.notoriety >= 10) {
    p += l.notoriety ~/ 10;
    why.add('Known to police +${l.notoriety ~/ 10}');
  }
  if (convictions(l) > 0) {
    p += 5;
    why.add('Criminal record +5');
  }
  if (c.id == 'embezzlement') {
    final open = l.cases.where((x) => x['crime'] == 'embezzlement').length;
    if (open > 0) {
      p += open * 10;
      why.add('Auditors notice patterns +${open * 10}');
    }
  }
  return (p.clamp(3, 90), why);
}

/// Crimes show how serious they are, never the odds (see odds.dart).
String riskHint(int p, String band) => '${_cap(band)} offence';

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String riskBand(int p) => p < 20
    ? 'Low'
    : p < 40
    ? 'Medium'
    : p < 60
    ? 'High'
    : 'Very high';

int _gain(Life l, Crime c, Random rng) => switch (c.id) {
  'embezzlement' => (l.salary * (0.08 + rng.nextDouble() * 0.07)).round(),
  'tax_evasion' => (l.salary * 0.15).round(),
  _ => c.gainMax <= 0 ? 0 : c.gainMin + rng.nextInt(c.gainMax - c.gainMin + 1),
};

/// Commits [c]: caught now (arrest scene), or away with it and a case the
/// police may solve later.
ActionResult commitCrime(
  Life l,
  Crime c,
  Random rng, {
  int riskAdj = 0,
  double gainMul = 1,
  String? text,
}) {
  final (base, why) = caughtOdds(l, c);
  final odds = (base + riskAdj).clamp(3, 90);
  l.reason = c.label;
  l.stats.add('karma', c.karma);
  if (rng.nextInt(100) < odds) {
    l.notoriety += 2;
    l.sceneQueue.add('arrest:${c.id}:${min(95, c.evidence + 25)}');
    return ActionResult(c.caught, ['Caught (risk was $odds%)', ...why.take(3)]);
  }
  final gain = (_gain(l, c, rng) * gainMul).round();
  l.money += gain;
  addDirty(l, gain);
  l.notoriety += c.band == 'minor' ? 0 : 2;
  final ev = c.evidence + rng.nextInt(15) - 5;
  final open = l.cases.where((x) => x['crime'] == c.id).firstOrNull;
  if (open != null && (c.id == 'embezzlement' || c.id == 'tax_evasion')) {
    open['evidence'] = min(95, (open['evidence'] as int) + 15);
  } else {
    l.cases.add({'crime': c.id, 'age': l.age, 'evidence': ev});
  }
  return ActionResult((text ?? c.done).replaceAll('{gain}', _m(gain)), [
    if (gain > 0) 'Money +${_m(gain)}',
    'Evidence left behind: $ev/100',
    'Risk was $odds%',
  ]);
}

/// Big takes are dirty money: until it is laundered, unexplained wealth
/// draws attention (underworld.dart). Small change does not count.
void addDirty(Life l, int gain) {
  if (gain >= 1000) l.dirty += gain;
}

/// The older crime actions (shoplifting, pickpocketing, graffiti) call this
/// when you are caught in the act.
void caughtInTheAct(Life l, String crimeId) {
  final c = crimeById(crimeId);
  l.notoriety += 1;
  l.sceneQueue.add('arrest:$crimeId:${min(95, c.evidence + 30)}');
}

// ---------------- Yearly: investigations, records, parole ----------------

List<String> justiceYear(Life l, Random rng) {
  final feed = <String>[];
  if (l.prison != null) return feed;
  final police = 1 + (l.worldMods['policing'] ?? 0) / 100;
  for (final c in l.cases.toList()) {
    final ev = c['evidence'] as int;
    final chance = ev / 100 * 0.5 * police * (1 - cunning(l) / 200);
    if (rng.nextDouble() < chance) {
      l.cases.remove(c);
      final crime = crimeById(c['crime']);
      l.sceneQueue.add('arrest:${crime.id}:$ev');
      feed.add(
        'Detectives knocked on your door about the ${crime.label.toLowerCase()} ${l.age - (c['age'] as int) <= 0 ? 'this year' : '${l.age - (c['age'] as int)} years ago'}.',
      );
      break;
    }
    if (c['crime'] == 'murder') {
      // No statute of limitations: the file stays open.
      c['evidence'] = max(15, ev - 3);
      continue;
    }
    c['evidence'] = ev - 8;
    if (ev - 8 < 5) l.cases.remove(c);
  }
  for (final r in l.record) {
    if (r['sealed'] == true) continue;
    final age = r['age'] as int;
    if (r['youth'] == true && l.age >= 18) {
      r['sealed'] = true;
      feed.add('Your youth record was sealed when you turned 18.');
    } else if ((r['band'] == 'minor' || r['band'] == 'moderate') &&
        l.age - age >= 10 &&
        !l.record.any((x) => (x['age'] as int) > age && x['sealed'] != true)) {
      r['sealed'] = true;
      feed.add(
        'Ten clean years: your conviction for ${crimeById(r['crime']).label.toLowerCase()} has been expunged.',
      );
    }
  }
  l.notoriety = max(0, l.notoriety - 1);
  return feed;
}

// ---------------- Scenes: arrest, charge, lawyer, trial ----------------

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'crime',
  scene: true,
  choices: choices,
);

/// Sentence in years for a guilty verdict (plan bands, "standard" country).
int sentenceYears(Life l, Crime c, int evidence, Random rng) {
  final priors = convictions(l);
  final f = evidence / 100;
  return switch (c.band) {
    'minor' => 0,
    'moderate' => (1 + f * 3 + priors * 0.5 + rng.nextDouble()).round().clamp(
      1,
      5,
    ),
    'serious' => (4 + f * 8 + priors + rng.nextDouble() * 2).round().clamp(
      4,
      15,
    ),
    _ => (10 + f * 15 + priors * 2).round().clamp(10, 30),
  };
}

double _modifier(Life l) {
  var f = 1.0;
  if (l.marks.contains('complied')) f *= 0.9;
  if (l.marks.contains('resisted')) f *= 1.25;
  if (l.marks.contains('surrendered')) f *= 0.7;
  return f;
}

void _clearMods(Life l) =>
    l.marks.removeAll(['complied', 'resisted', 'surrendered', 'truthful']);

String _bail(Life l, Crime c) {
  final bail = switch (c.band) {
    'minor' => 0,
    'moderate' => 5000,
    'serious' => 25000,
    _ => 100000,
  };
  if (bail == 0) return '';
  if (l.money >= bail) {
    return ' You paid ${_m(bail)} bail and waited at home; you got it back after.';
  }
  l.stats.add('happiness', -4);
  return ' You could not pay ${_m(bail)} bail, so you waited weeks on remand.';
}

/// Records the conviction and sends you to prison (or not).
String convict(Life l, Crime c, int years, String how) {
  final youth = l.age < 18;
  if (youth && years > 0) years = max(1, min(3, years ~/ 2));
  final violated = onParole(l);
  if (violated) years += 1;
  l.record.add({
    'crime': c.id,
    'age': l.age,
    'band': c.band,
    'sentence': years == 0 ? how : '$years years',
    'youth': youth,
    'sealed': false,
  });
  l.flags['convicted'] = Memory(
    l.age,
    'your conviction for ${c.label.toLowerCase()}',
  );
  _clearMods(l);
  final seized =
      c.id == 'car_theft' && l.assets.any((a) => a.info['stolen'] == true);
  if (seized) {
    l.assets.removeWhere((a) => a.info['stolen'] == true);
    if (!l.has('car')) l.flags.remove('owns_car');
  }
  final lost = seized ? ' Police took back the stolen car.' : '';
  if (years == 0) return lost;
  enterPrison(l, c, years);
  return '$lost ${youth ? 'Youth detention' : 'Prison'}: $years ${years == 1 ? 'year' : 'years'}${violated ? ' (including time for breaking parole)' : ''}.';
}

void enterPrison(Life l, Crime c, int years) {
  final youth = l.age < 18;
  if (l.job != null) leaveJob(l, fired: true);
  l.assets.removeWhere((a) => a.kind == 'rental');
  l.marks.removeWhere((m) => m.startsWith('parole_until:'));
  l.prison = Prison(
    crime: c.id,
    years: years,
    since: l.age,
    youth: youth,
    security: youth
        ? 'youth'
        : c.band == 'severe'
        ? 'maximum'
        : c.band == 'serious'
        ? 'medium'
        : 'minimum',
  );
  final p = partnerOf(l);
  if (p != null) {
    p.addFacets(affection: -10, trust: -10);
    p.remember(
      NpcMemory(
        age: l.age,
        text: 'you going to prison',
        valence: -2,
        intensity: 4,
        tags: ['crime'],
      ),
    );
  }
  l.npcs.removeWhere((n) => n.id == 'cellmate');
  final country = countryNamed(l.country);
  final rng = Random(l.seed + l.age * 3);
  final pool = l.gender == 'female' ? country.female : country.male;
  l.npcs.add(
    Npc(
      id: 'cellmate',
      role: 'Cellmate',
      name:
          '${pool[rng.nextInt(pool.length)]} ${country.surnames[rng.nextInt(country.surnames.length)]}',
      birthYear: l.year - max(16, l.age - 6 + rng.nextInt(16)),
      circle: 'Prison',
      bond: 30,
    )..lastContactAge = l.age,
  );
  l.flags['prison'] = Memory(l.age, 'going to prison');
  l.stats.add('happiness', -12);
  l.feed.add(
    FeedEntry(
      l.age,
      'You were sent to ${youth ? 'a youth detention centre' : 'a ${l.prison!.security}-security prison'} for $years years. Your cellmate is ${l.npc('cellmate')!.name}.',
      kind: 'milestone',
    ),
  );
}

String release(Life l, {bool parole = false}) {
  final p = l.prison!;
  final left = p.left;
  if (p.gangId != null) {
    l.marks.add('ex_gang:${p.gangId}');
    l.flags['prison_gang'] ??= Memory(
      l.age,
      'running with ${gangById(p.gangId!).name}',
    );
  }
  l.prison = null;
  final mate = l.npc('cellmate');
  if (mate != null) {
    if (mate.bond >= 50) {
      recircle(l, mate, circle: 'Friends', role: 'Friend from prison');
    } else {
      l.npcs.remove(mate);
    }
  }
  if (parole && left > 0) l.marks.add('parole_until:${l.age + left}');
  l.flags['released'] = Memory(l.age, 'walking out of prison');
  l.stats.add('happiness', 10);
  final home = offerHalfwayHouse(l);
  final text = parole
      ? 'You walked out on parole after ${p.served} years. For the next $left years: check-ins, a curfew and no more crime, or you go back.'
      : 'You served your full ${p.years} years and walked out with a plastic bag of belongings and a criminal record.';
  return home == null ? text : '$text $home';
}

Storylet? justiceScene(String id, List<String> args, Life l) {
  switch (id) {
    case 'arrest':
      final c = crimeById(args.first);
      final ev = args.length > 1
          ? int.tryParse(args[1]) ?? c.evidence
          : c.evidence;
      final run = (25 + (l.stats['athleticism'] - 50) ~/ 2 + l.fitness ~/ 5)
          .clamp(5, 70);
      return _scene(
        id,
        'Blue lights fill the street. "${l.firstName} ${l.surname}? You are under arrest on suspicion of ${c.label.toLowerCase()}." The handcuffs are colder than you expected.',
        [
          Choice(
            label: 'Go quietly',
            outcome: '',
            risk: 'Cooperation helps later',
            run: (l, rng) {
              l.marks.add('complied');
              l.sceneQueue.add('charge:${c.id}:$ev');
              return 'You kept your mouth shut and your hands where they could see them.';
            },
          ),
          Choice(
            label: 'Run for it',
            outcome: '',
            risk: '$run% chance to get away (Athleticism, fitness)',
            run: (l, rng) {
              if (rng.nextInt(100) < run) {
                l.notoriety += 5;
                l.cases.add({'crime': c.id, 'age': l.age, 'evidence': 85});
                return 'You vaulted a fence, cut through three gardens and lost them. But they know your name now, and they will be back.';
              }
              l.marks.add('resisted');
              l.sceneQueue.add('charge:${c.id}:${min(95, ev + 10)}');
              return 'You made it eleven steps before an officer tackled you into a hedge. Resisting arrest will not help your case.';
            },
          ),
        ],
      );
    case 'charge':
      final c = crimeById(args.first);
      final ev = args.length > 1
          ? int.tryParse(args[1]) ?? c.evidence
          : c.evidence;
      if (l.age < 14 && c.band == 'minor') {
        return _scene(
          id,
          'At the station, an officer gives you the longest lecture of your life while your parents stare at the floor. Because you are under 14, it ends with a formal warning.',
          [
            Choice(
              label: 'Promise never to do it again',
              outcome: '',
              run: (l, rng) {
                _clearMods(l);
                l.stats.add('happiness', -4);
                l.flags['police_warning'] = Memory(l.age, 'a police warning');
                return 'No record, just a warning, and a month without your phone.';
              },
            ),
          ],
        );
      }
      if (c.band == 'minor') {
        final fine = 300 + ev * 7;
        return _scene(
          id,
          'You are charged with ${c.label.toLowerCase()}. For a minor offence the magistrate offers a choice.',
          [
            Choice(
              label: 'Plead guilty and pay a ${_m(fine)} fine',
              outcome: '',
              needsMoney: fine,
              run: (l, rng) {
                l.money -= fine;
                final text = convict(l, c, 0, 'fine');
                return 'You paid ${_m(fine)} and got a criminal record for ${c.label.toLowerCase()}.$text';
              },
            ),
            Choice(
              label: 'Plead guilty: 100 hours of community service',
              outcome: '',
              run: (l, rng) {
                l.stats.add('happiness', -3);
                l.stats.add('karma', 2);
                final text = convict(l, c, 0, 'community service');
                return 'You spent your weekends picking up litter in a hi-vis vest. A criminal record for ${c.label.toLowerCase()}, but no prison.$text';
              },
            ),
            Choice(
              label: 'Plead not guilty',
              outcome: '',
              risk: 'Go to trial',
              run: (l, rng) {
                l.sceneQueue.add('lawyer:${c.id}:$ev');
                return 'You looked the magistrate in the eye and said, "Not guilty."';
              },
            ),
          ],
        );
      }
      final rng0 = Random(l.seed + l.age * 11);
      final full = sentenceYears(l, c, ev, rng0);
      final plea = max(1, (full * 0.6 * _modifier(l)).round());
      return _scene(
        id,
        'You are charged with ${c.label.toLowerCase()}. The evidence against you is rated $ev/100. The prosecutor offers a deal: plead guilty and serve $plea years. At trial, a guilty verdict could mean around $full years.',
        [
          Choice(
            label: 'Accept the plea deal ($plea years)',
            outcome: '',
            run: (l, rng) {
              final text = convict(l, c, plea, 'plea');
              return 'You pleaded guilty.$text';
            },
          ),
          Choice(
            label: 'Go to trial',
            outcome: '',
            risk: 'Risky: all or nothing',
            run: (l, rng) {
              final bail = _bail(l, c);
              l.sceneQueue.add('lawyer:${c.id}:$ev');
              return 'You turned the deal down.$bail';
            },
          ),
        ],
      );
    case 'lawyer':
      final c = crimeById(args.first);
      final ev = args.length > 1
          ? int.tryParse(args[1]) ?? c.evidence
          : c.evidence;
      final pd = 35 + Random(l.seed + l.age).nextInt(21);
      Choice hire(String label, int cost, int skill, String risk) => Choice(
        label: label,
        outcome: '',
        needsMoney: cost,
        risk: risk,
        run: (l, rng) {
          l.money -= cost;
          l.sceneQueue.add('trial:${c.id}:$ev:$skill');
          return cost > 0
              ? 'You hired a lawyer with a firm handshake and a ${cost >= 100000 ? 'very' : 'fairly'} expensive suit.'
              : 'You met your lawyer ten minutes before the hearing.';
        },
      );
      final self = ((l.stats['charisma'] + l.stats['smarts']) ~/ 2 - 10).clamp(
        5,
        80,
      );
      return _scene(
        id,
        'Who will stand next to you in court? A better lawyer can pick holes in the evidence ($ev/100).',
        [
          hire(
            'Represent yourself',
            0,
            self,
            'Skill $self (your Charisma and Smarts)',
          ),
          hire('Public defender (free)', 0, pd, 'Skill $pd · overworked'),
          hire('Mid-tier lawyer (\$15,000)', 15000, 65, 'Skill 65'),
          hire('Elite lawyer (\$100,000)', 100000, 88, 'Skill 88'),
        ],
      );
    case 'trial':
      final c = crimeById(args.first);
      final ev = args.length > 1
          ? int.tryParse(args[1]) ?? c.evidence
          : c.evidence;
      final skill = args.length > 2 ? int.tryParse(args[2]) ?? 45 : 45;
      String verdict(Life l, Random rng, String testimony) {
        final why = <(double, String)>[
          (ev / 100 * 0.8, 'Evidence $ev/100'),
          (0.1, 'Witnesses'),
          (-(skill - 50) / 150, 'Your lawyer (skill $skill)'),
          (-(l.stats['charisma'] - 50) / 400, 'Your Charisma'),
          (convictions(l) * 0.05, 'Your record'),
          ((50 - l.stats['karma']) / 500, 'How the jury sees you (Karma)'),
        ];
        var perjury = false;
        switch (testimony) {
          case 'truth':
            why.add((0.1, 'You admitted parts of it'));
            l.marks.add('truthful');
          case 'lie':
            if (rng.nextInt(100) < (40 - l.stats['smarts'] ~/ 3).clamp(5, 40)) {
              perjury = true;
              why.add((0.15, 'Caught lying on the stand'));
            } else {
              why.add((-0.12, 'A convincing story'));
            }
        }
        final p = why.fold(0.0, (a, b) => a + b.$1).clamp(0.03, 0.97);
        why.sort((a, b) => b.$1.abs().compareTo(a.$1.abs()));
        final reasons = why
            .take(3)
            .map(
              (r) =>
                  '${r.$2} (${r.$1 >= 0 ? '+' : '−'}${(r.$1.abs() * 100).round()}%)',
            )
            .join(', ');
        if (rng.nextDouble() >= p) {
          _clearMods(l);
          l.flags['acquitted'] = Memory(l.age, 'walking free from court');
          l.notoriety += 3;
          l.stats.add('happiness', 10);
          return 'The foreman stood up: "Not guilty." Your knees nearly gave way. Conviction chance was ${(p * 100).round()}%: $reasons.';
        }
        var years = sentenceYears(l, c, ev, rng);
        if (l.marks.contains('truthful')) years = (years * 0.8).round();
        years = (years * _modifier(l)).round();
        if (perjury) years += 1;
        if (c.band == 'minor') {
          final text = convict(l, c, 0, 'fine');
          l.money -= 1000;
          return 'Guilty. A \$1,000 fine and a criminal record.$text Conviction chance was ${(p * 100).round()}%: $reasons.';
        }
        years = max(1, years);
        final text = convict(l, c, years, 'trial');
        return 'Guilty.$text Conviction chance was ${(p * 100).round()}%: $reasons.';
      }

      return _scene(
        id,
        'The courtroom smells of floor polish and nerves. The prosecution lays out its case. Then your lawyer turns to you: you will have to take the stand.',
        [
          Choice(
            label: 'Tell the truth',
            outcome: '',
            risk: 'Jury trusts you; a lighter sentence if guilty',
            run: (l, rng) => verdict(l, rng, 'truth'),
          ),
          Choice(
            label: 'Lie on the stand',
            outcome: '',
            risk: 'Perjury risk (Smarts helps)',
            run: (l, rng) => verdict(l, rng, 'lie'),
          ),
          Choice(
            label: 'Stay silent',
            outcome: '',
            run: (l, rng) => verdict(l, rng, 'silent'),
          ),
        ],
      );
    case 'parole':
      final p = l.prison;
      if (p == null) return null;
      final support = l.npcs
          .where(
            (n) =>
                n.alive &&
                (n.circle == 'Family' || n.circle == 'Partner') &&
                n.bond > 0,
          )
          .fold(0, (a, n) => max(a, n.bond));
      final base =
          0.2 +
          p.behaviour / 200 +
          p.programmes * 0.05 +
          support / 400 -
          l.notoriety / 300 -
          gangParolePenalty(p);
      String hearing(Life l, Random rng, double bonus, String how) {
        p.lastHearing = l.age;
        final chance = (base + bonus).clamp(0.02, 0.9);
        final reasons =
            'behaviour ${p.behaviour}%, ${p.programmes} programmes, family support $support%${p.gang ? ', ${gangRanks[p.gangRank].toLowerCase()} in a gang' : ''}${l.notoriety > 20 ? ', notoriety' : ''}';
        if (rng.nextDouble() < chance) {
          return '$how ${release(l, parole: true)} (Chance was ${(chance * 100).round()}%: $reasons.)';
        }
        l.stats.add('happiness', -5);
        return '$how The board denied parole. Chance was ${(chance * 100).round()}%: $reasons. Next hearing in a year.';
      }

      return _scene(
        id,
        'Three people behind a long table read your file in silence. You have served ${p.served} of ${p.years} years. One of them looks up: "Tell us why you should be released."',
        [
          Choice(
            label: 'Speak honestly about what you did',
            outcome: '',
            risk: '+5%',
            run: (l, rng) => hearing(
              l,
              rng,
              0.05,
              'You talked about what you did and who it hurt.',
            ),
          ),
          Choice(
            label: 'Say what they want to hear',
            outcome: '',
            risk: 'Smarts and Charisma',
            run: (l, rng) => hearing(
              l,
              rng,
              (cunning(l) - 55) / 200,
              'You gave a polished speech.',
            ),
          ),
          Choice(
            label: 'Let your record speak',
            outcome: '',
            run: (l, rng) => hearing(l, rng, 0, 'You kept it short.'),
          ),
        ],
      );
    case 'escape':
      final p = l.prison;
      if (p == null) return null;
      Choice route(String label, String key, int base, String risk) => Choice(
        label: label,
        outcome: '',
        risk: risk,
        run: (l, rng) {
          l.sceneQueue.add('escape_tool:$key:$base');
          return 'You start planning, quietly.';
        },
      );
      final bribe = switch (p.security) {
        'maximum' => 12000,
        'medium' => 6000,
        _ => 3000,
      };
      final crew =
          30 +
          switch (p.gangId) {
            'owls' => 10,
            'iron' => 5,
            _ => 0,
          } +
          p.gangRank * 3;
      return _scene(
        id,
        'At night you lie awake mapping the ${p.security == 'youth' ? 'centre' : 'prison'}: the cell block, the yard, the laundry, the wall. Patrols pass every twenty minutes. Which way out?',
        [
          route(
            'Hide in the laundry truck',
            'laundry',
            p.job == 'Laundry' ? 40 : 30,
            p.job == 'Laundry' ? 'Base 40% (you work there)' : 'Base 30%',
          ),
          route(
            'Over the wall at night',
            'wall',
            15 + l.stats['athleticism'] ~/ 4,
            'Base ${15 + l.stats['athleticism'] ~/ 4}% (Athleticism)',
          ),
          route('Dig a tunnel', 'tunnel', 20, 'Base 20% · slow'),
          Choice(
            label: 'Bribe a guard to leave a door open',
            outcome: '',
            needsMoney: bribe,
            risk: 'Costs \$${bribe ~/ 1000},000 · base 45%',
            run: (l, rng) {
              l.money -= bribe;
              l.sceneQueue.add('escape_tool:bribe:45');
              return 'An envelope changes hands in the visiting room. The guard will not look at you.';
            },
          ),
          route(
            'Fake an illness for a hospital transfer',
            'hospital',
            10 + l.stats['smarts'] ~/ 4,
            'Base ${10 + l.stats['smarts'] ~/ 4}% (Smarts)',
          ),
          Choice(
            label: 'Get your crew to break you out',
            outcome: '',
            risk: 'Needs a gang · base $crew%',
            lock: (l) => p.gang ? null : 'Needs a gang inside',
            run: (l, rng) {
              l.sceneQueue.add('escape_tool:crew:$crew');
              return 'Word goes out through the crew. Someone outside is booking a van.';
            },
          ),
          Choice(
            label: 'Hide in a delivery',
            outcome: '',
            risk: 'Needs the kitchen or laundry job · base 35%',
            lock: (l) => const {'Kitchen', 'Laundry'}.contains(p.job)
                ? null
                : 'Needs the kitchen or laundry job',
            run: (l, rng) {
              l.sceneQueue.add('escape_tool:delivery:35');
              return 'You learn the delivery schedule by heart.';
            },
          ),
          Choice(
            label: 'Forget it',
            outcome: 'You decided freedom could wait for the legal way.',
          ),
        ],
      );
    case 'escape_tool':
      final p = l.prison;
      if (p == null || args.length < 2) return null;
      final base = int.tryParse(args[1]) ?? 20;
      final security = switch (p.security) {
        'maximum' => 20,
        'medium' => 10,
        _ => 0,
      };
      final mate = l.npc('cellmate');
      Choice tool(String label, int bonus, {int cost = 0}) {
        final odds = (base + bonus - security).clamp(3, 85);
        return Choice(
          label: label,
          outcome: '',
          needsMoney: cost,
          risk: '$odds% chance · security −$security',
          run: (l, rng) {
            l.money -= cost;
            if (rng.nextInt(100) < odds) {
              l.prison = null;
              l.npcs.removeWhere((n) => n.id == 'cellmate');
              l.notoriety += 15;
              l.cases.add({'crime': 'escape', 'age': l.age, 'evidence': 95});
              l.flags['escaped'] = Memory(l.age, 'escaping from prison');
              l.marks.add('fugitive');
              return 'You were out before the morning count. Free, for now, but every police officer in the country has your photo.';
            }
            final extra = 1 + rng.nextInt(4);
            p.years += extra;
            p.behaviour = max(0, p.behaviour - 20);
            if (p.security == 'minimum') p.security = 'medium';
            p.solitary = max(p.solitary, 1);
            return 'A guard\'s torch found you halfway there. $extra years were added to your sentence, and the first one is in solitary.';
          },
        );
      }

      return _scene(id, 'The plan needs one more thing.', [
        tool('A stolen key (\$500 to a contact)', 15, cost: 500),
        tool('A guard\'s uniform', 10),
        if (mate != null)
          tool(
            'A distraction from ${mate.name.split(' ').first}',
            5 + mate.bond ~/ 10,
          ),
        tool('Nothing but nerve', 0),
      ]);
    case 'appeal':
      final p = l.prison;
      if (p == null) return null;
      Choice lawyer(String label, int cost, int odds) => Choice(
        label: label,
        outcome: '',
        needsMoney: cost,
        risk: '$odds% chance',
        run: (l, rng) {
          l.money -= cost;
          p.appealed = true;
          if (rng.nextInt(100) < odds) {
            l.record.removeWhere(
              (r) => r['crime'] == p.crime && r['age'] == p.since,
            );
            final text = release(l);
            return 'The appeal court found a mistake in your trial and overturned the conviction. ${text.split('.').first}. Your record for this is gone.';
          }
          return 'The appeal court upheld your conviction. There is only one appeal.';
        },
      );
      return _scene(
        id,
        'You can appeal your conviction once. Appeals win on mistakes in the trial or new evidence, and good lawyers find more of both.',
        [
          lawyer('Public defender (free)', 0, 8),
          lawyer('Mid-tier appeal lawyer (\$15,000)', 15000, 18),
          lawyer('Elite appeal lawyer (\$100,000)', 100000, 32),
          Choice(
            label: 'Don\'t appeal',
            outcome: 'You decided to serve your time.',
          ),
        ],
      );
    case 'prison_job':
      final p = l.prison;
      if (p == null) return null;
      Choice job(String name, String text, Map<String, int> stats) => Choice(
        label: name,
        outcome: '',
        run: (l, rng) {
          p.job = name;
          p.behaviour = min(100, p.behaviour + 5);
          stats.forEach(l.stats.add);
          return text;
        },
      );
      return _scene(
        id,
        'Prison jobs pay pennies, but they fill the days and the parole board notices.',
        [
          job(
            'Kitchen',
            'You peel four hundred potatoes a day. You are now very good at peeling potatoes.',
            {'health': 1},
          ),
          job('Laundry', 'Hot, loud and endless. But it is warm in winter.', {
            'discipline': 2,
          }),
          job('Library', 'You stack books and read most of them.', {
            'smarts': 3,
          }),
          job(
            'Workshop',
            'You learn to build furniture. Your first chair wobbles.',
            {'creativity': 3},
          ),
        ],
      );
  }
  return null;
}

// ---------------- Actions ----------------

String? _prisonOnly(Life l) => l.prison == null ? 'Only in prison' : null;

GameAction _crimeAction(
  Crime c,
  List<String> keywords, {
  String? Function(Life)? extra,
}) => GameAction(
  id: c.id,
  label: c.label,
  category: 'Crime',
  keywords: keywords,
  minAge: c.minAge,
  extraCheck: (l) {
    if (l.year < c.since) return 'Not possible in ${l.year}';
    return extra?.call(l);
  },
  hint: (l) =>
      '${riskHint(caughtOdds(l, c).$1, c.band)}${c.gainMax > 0 ? ' · usually ${_m(c.gainMin)} to ${_m(c.gainMax)}' : switch (c.id) {
              'embezzlement' || 'tax_evasion' => ' · pays from your salary',
              'assault' => ' · no money, just trouble',
              _ => '',
            }}${plannedCrimes.contains(c.id) ? ' · you plan it step by step' : ''}',
  run: (l, rng) {
    if (!plannedCrimes.contains(c.id)) return commitCrime(l, c, rng);
    l.sceneQueue.add('crime_plan:${c.id}');
    return ActionResult('You start thinking it through.');
  },
);

final justiceActions = <GameAction>[
  _crimeAction(crimeById('porch_theft'), ['parcel', 'porch', 'steal', 'theft']),
  _crimeAction(crimeById('burglary'), [
    'burglary',
    'burgle',
    'break in',
    'rob house',
  ]),
  _crimeAction(crimeById('car_theft'), ['car theft', 'steal car', 'joyride']),
  _crimeAction(crimeById('fraud'), [
    'fraud',
    'scam',
    'con',
  ], extra: (l) => l.stats['charisma'] < 40 ? 'Needs Charisma 40+' : null),
  _crimeAction(crimeById('hacking'), [
    'hack',
    'hacking',
    'cyber',
    'computer',
  ], extra: (l) => l.stats['smarts'] < 60 ? 'Needs Smarts 60+' : null),
  _crimeAction(crimeById('embezzlement'), [
    'embezzle',
    'steal from work',
    'skim',
  ], extra: (l) => l.job == null ? 'Needs a job' : null),
  _crimeAction(crimeById('tax_evasion'), [
    'tax',
    'evade',
    'evasion',
    'hide income',
  ], extra: (l) => l.salary < 30000 ? 'Needs a salary of \$30,000+' : null),
  _crimeAction(crimeById('assault'), ['assault', 'fight', 'attack', 'punch']),
  _crimeAction(
    crimeById('extortion'),
    ['extort', 'extortion', 'protection money', 'shakedown'],
    extra: (l) => l.stats['athleticism'] < 40 && l.stats['charisma'] < 50
        ? 'Needs Fitness 40+ or Charisma 50+'
        : null,
  ),
  _crimeAction(crimeById('counterfeiting'), [
    'counterfeit',
    'fake money',
    'forgery',
    'print money',
  ], extra: (l) => l.stats['creativity'] < 50 ? 'Needs Creativity 50+' : null),
  _crimeAction(crimeById('smuggling'), [
    'smuggle',
    'smuggling',
    'contraband',
    'border',
  ]),
  _crimeAction(crimeById('identity_theft'), [
    'identity theft',
    'steal identity',
    'credit card fraud',
  ], extra: (l) => l.stats['smarts'] < 45 ? 'Needs Smarts 45+' : null),
  _crimeAction(
    crimeById('insider_trading'),
    ['insider trading', 'tip', 'stocks', 'shares'],
    extra: (l) => l.job == null && l.businesses.isEmpty
        ? 'Needs a job or business to hear tips'
        : l.money < 10000
        ? 'Needs \$10,000 to invest'
        : null,
  ),
  _crimeAction(
    crimeById('insurance_fraud'),
    ['insurance fraud', 'fake claim', 'arson', 'staged accident'],
    extra: (l) => l.has('car') || l.has('house') || l.businesses.isNotEmpty
        ? null
        : 'Needs a car, home or business to claim on',
  ),
  _crimeAction(crimeById('street_racing'), [
    'street race',
    'racing',
    'drag race',
  ], extra: (l) => l.has('car') ? null : 'Needs a car'),
  GameAction(
    id: 'murder',
    label: 'Murder',
    category: 'Crime',
    keywords: ['murder', 'kill', 'homicide'],
    minAge: 18,
    extraCheck: (l) => l.prison != null
        ? 'Not possible in prison'
        : murderTargets(l).isEmpty
        ? 'There is nobody you know well enough'
        : null,
    hint: (l) => riskHint(caughtOdds(l, crimeById('murder')).$1, 'severe'),
    run: (l, rng) {
      l.sceneQueue.add('murder_pick');
      return ActionResult('A dark thought you cannot shake.');
    },
  ),
  _crimeAction(crimeById('armed_robbery'), [
    'rob',
    'robbery',
    'bank',
    'heist',
    'hold up',
  ]),
  GameAction(
    id: 'turn_in',
    label: 'Turn yourself in',
    category: 'Crime',
    keywords: ['confess', 'turn in', 'surrender', 'police'],
    minAge: 10,
    extraCheck: (l) => l.cases.isEmpty ? 'No open cases against you' : null,
    run: (l, rng) {
      final worst =
          (l.cases.toList()..sort(
                (a, b) =>
                    (b['evidence'] as int).compareTo(a['evidence'] as int),
              ))
              .first;
      l.cases.remove(worst);
      l.marks.add('surrendered');
      l.stats.add('karma', 5);
      final c = crimeById(worst['crime']);
      l.sceneQueue.add('charge:${c.id}:${worst['evidence']}');
      return ActionResult(
        'You walked into the station and said, "I need to tell you about the ${c.label.toLowerCase()}."',
        ['Karma up', 'Turning yourself in cuts any sentence by 30%'],
      );
    },
  ),
  // ---------- Prison life ----------
  GameAction(
    id: 'prison_job',
    label: 'Get a prison job',
    category: 'Prison',
    keywords: ['prison job', 'work', 'kitchen', 'laundry', 'library'],
    extraCheck: _prisonOnly,
    run: (l, rng) {
      l.sceneQueue.add('prison_job');
      return ActionResult('You put your name down for a job.');
    },
  ),
  GameAction(
    id: 'prison_study',
    label: 'Take a prison course',
    category: 'Prison',
    keywords: ['study', 'course', 'education', 'class', 'exam', 'degree'],
    hint: (l) => l.prison == null
        ? 'Only in prison'
        : l.prison!.courses.isEmpty
        ? 'Diploma, trade, anger, addiction or a degree'
        : 'Done: ${l.prison!.courses.length} of ${prisonCourses.length}',
    extraCheck: _prisonOnly,
    run: (l, rng) {
      l.sceneQueue.add('prison_course');
      return ActionResult('You look at the education noticeboard.');
    },
  ),
  GameAction(
    id: 'prison_gym',
    label: 'Work out in the yard',
    category: 'Prison',
    keywords: ['gym', 'yard', 'workout', 'exercise'],
    extraCheck: _prisonOnly,
    run: (l, rng) {
      final p = l.prison!;
      p.respect = min(100, p.respect + 6);
      l.fitness = min(100, l.fitness + 8);
      final r = statChange(
        l,
        'Push-ups, pull-ups and a lot of staring contests.',
        {'health': 2, 'athleticism': 2},
      );
      return ActionResult(r.text, [...r.notes, 'Respect ${p.respect}%']);
    },
  ),
  GameAction(
    id: 'write_letters',
    label: 'Write letters home',
    category: 'Prison',
    keywords: ['letter', 'write', 'family', 'home'],
    extraCheck: _prisonOnly,
    run: (l, rng) {
      final close = l.npcs.where(
        (n) => n.alive && (n.circle == 'Family' || n.circle == 'Partner'),
      );
      for (final n in close) {
        n.addFacets(affection: 3);
        n.lastContactAge = l.age;
      }
      final r = statChange(
        l,
        'You wrote ${close.length} letters. Some of them got replies.',
        {'happiness': 3},
      );
      return ActionResult(r.text, [...r.notes, 'Family bonds up']);
    },
  ),
  GameAction(
    id: 'talk_cellmate',
    label: 'Talk to your cellmate',
    category: 'Prison',
    keywords: ['cellmate', 'talk', 'friend'],
    extraCheck: (l) =>
        _prisonOnly(l) ?? (l.npc('cellmate') == null ? 'No cellmate' : null),
    run: (l, rng) {
      final m = l.npc('cellmate')!;
      m.addFacets(affection: 6, trust: 4);
      m.lastContactAge = l.age;
      if (m.bond >= 70 && !m.done.contains('prison_story')) {
        m.done.add('prison_story');
        m.remember(
          NpcMemory(
            age: l.age,
            text: 'surviving prison together',
            valence: 2,
            intensity: 4,
            tags: ['crime'],
          ),
        );
        return ActionResult(
          '${m.name.split(' ').first} told you the whole story of how they ended up here. You told them yours. Something like friendship.',
          ['${m.name.split(' ').first} ${m.bond}%'],
        );
      }
      return ActionResult(
        'You and ${m.name.split(' ').first} argued about football until lights out.',
        ['${m.name.split(' ').first} ${m.bond}%'],
      );
    },
  ),
  GameAction(
    id: 'bribe_guard',
    label: 'Bribe a guard',
    category: 'Prison',
    keywords: ['bribe', 'guard'],
    cost: 500,
    extraCheck: _prisonOnly,
    hint: (l) =>
        'Costs \$500 · ${(30 + (cunning(l) - 50) ~/ 2).clamp(5, 80)}% chance (Smarts, Charisma)',
    run: (l, rng) {
      final p = l.prison!;
      l.money -= 500;
      final odds = (30 + (cunning(l) - 50) ~/ 2).clamp(5, 80);
      if (rng.nextInt(100) < odds) {
        p.behaviour = min(100, p.behaviour + 15);
        return ActionResult(
          'The guard pocketed the envelope and your file got a glowing behaviour report.',
          ['Money −\$500', 'Behaviour ${p.behaviour}%'],
        );
      }
      p.years += 1;
      p.behaviour = max(0, p.behaviour - 10);
      return ActionResult(
        'The guard reported you. A year was added to your sentence.',
        ['Money −\$500', 'Sentence +1 year', 'Chance was $odds%'],
      );
    },
  ),
  GameAction(
    id: 'escape_prison',
    label: 'Plan an escape',
    category: 'Prison',
    keywords: ['escape', 'break out', 'tunnel'],
    extraCheck: _prisonOnly,
    run: (l, rng) {
      l.sceneQueue.add('escape');
      return ActionResult('You start watching the guards.');
    },
  ),
  GameAction(
    id: 'appeal',
    label: 'Appeal your conviction',
    category: 'Prison',
    keywords: ['appeal', 'lawyer', 'court'],
    extraCheck: (l) =>
        _prisonOnly(l) ?? (l.prison!.appealed ? 'You already appealed' : null),
    run: (l, rng) {
      l.sceneQueue.add('appeal');
      return ActionResult('You ask for the appeal forms.');
    },
  ),
];

/// While in prison, only prison activities (and a few quiet ones) work.
const prisonAllowed = {'meditate', 'read'};

/// In solitary confinement only these are possible.
const solitaryAllowed = {'meditate', 'read', 'write_letters', 'cell_exercise'};

/// Each birthday in prison (plan Prison chapter): time served, respect,
/// safety, parole hearings and release.
List<String> prisonYear(Life l, Random rng) {
  final p = l.prison;
  if (p == null) return prisonLifeYear(l, rng);
  final feed = <String>[];
  p.served++;
  l.reason = 'Prison';
  l.stats.add('happiness', -3);
  if (p.respect < 40 && !p.gang && rng.nextInt(100) < 20) {
    l.stats.add('health', -5);
    p.behaviour = max(0, p.behaviour - 5);
    feed.add(
      'Someone picked a fight with you in the yard. You lost. (Respect ${p.respect}%: working out or friends inside would help.)',
    );
  }
  if (p.solitary == 0) feed.addAll(gangYear(l, rng));
  feed.addAll(prisonLifeYear(l, rng));
  if (l.prison == null) return feed;
  p.behaviour = min(100, p.behaviour + (p.job != null ? 3 : 0));
  if (rng.nextInt(100) < (p.security == 'maximum' ? 12 : 6)) {
    l.sceneQueue.add('riot');
  }
  final mate = l.npc('cellmate');
  if (mate != null && rng.nextInt(100) < 20) {
    feed.add(
      mate.bond >= 60
          ? '${mate.name.split(' ').first} shared their contraband chocolate with you. Prison friendships are real.'
          : '${mate.name.split(' ').first} snores like a lawnmower.',
    );
  }
  if (p.served >= p.years) {
    feed.add(release(l));
  } else if (p.served >= p.paroleAt && p.lastHearing != l.age && !p.youth) {
    l.sceneQueue.add('parole');
  } else if (p.youth && p.served >= p.paroleAt && rng.nextBool()) {
    feed.add(release(l, parole: true));
  }
  return feed;
}
