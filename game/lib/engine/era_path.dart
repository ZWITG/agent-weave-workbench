/// Work and schooling in an era life (Legends plan, Phase 2B): guild
/// ladders from apprentice to master, birth status, legitimacy, reading and
/// the era's schools. Only timeline lives reach this file; the modern job,
/// career and school systems never run in them, and this never runs in a
/// modern life.
library;

import 'dart:math';

import 'currency.dart';
import 'eras.dart';
import 'models.dart';

/// Birth status: 0 peasant, 1 working people, 2 citizen, 3 noble.
int eraStatus(Life l) => (l.eraPath['status'] as int?) ?? 1;

/// Born outside marriage (Leonardo).
bool eraIllegit(Life l) => l.eraPath['illegit'] == true;

/// What this life can read: 'read', 'reckon', 'latin', 'arabic', 'degree'.
Set<String> eraReads(Life l) =>
    Set<String>.from((l.eraPath['reads'] as List?) ?? const []);

/// Schools finished, by id.
List<String> eraSchoolsDone(Life l) =>
    List<String>.from((l.eraPath['done'] as List?) ?? const []);

/// The era job held now, and its step on the ladder.
EraJob? eraJobOf(Life l, EraRules era) {
  final id = l.eraPath['job'] as String?;
  return id == null ? null : era.job(id);
}

int eraStep(Life l) => (l.eraPath['rank'] as int?) ?? 0;

/// Years in the current step, and in the trade.
int eraYearsInStep(Life l) => (l.eraPath['years'] as int?) ?? 0;
int eraYearsInTrade(Life l) => (l.eraPath['trade'] as int?) ?? 0;

/// The school being attended, and years done there.
EraSchool? eraSchoolOf(Life l, EraRules era) {
  final id = l.eraPath['school'] as String?;
  return id == null ? null : era.schoolById(id);
}

int eraSchoolYears(Life l) => (l.eraPath['schoolYears'] as int?) ?? 0;

/// Progress (0-100) in teaching yourself Latin.
int eraLatin(Life l) => (l.eraPath['latin'] as int?) ?? 0;

/// The status name for [status] where this life lives.
String eraStatusName(EraRules era, Life l, [int? status]) {
  final names =
      era.statusNames[era.regionOf(l).group] ??
      const ['Peasant', 'Working people', 'Citizen', 'Noble'];
  return names[(status ?? eraStatus(l)).clamp(0, names.length - 1)];
}

const _readNames = {
  'read': 'reading',
  'reckon': 'reckoning',
  'latin': 'Latin',
  'arabic': 'Arabic',
  'degree': 'a degree',
};

String eraReadName(String r) => _readNames[r] ?? r;

bool _here(
  Life l,
  EraRules era,
  List<String> groups,
  List<String> regions,
  List<String> cities,
  Map<String, int> fromBy,
  Map<String, int> toBy,
) {
  final region = era.regionOf(l);
  final open =
      (groups.isEmpty && regions.isEmpty && cities.isEmpty) ||
      groups.contains(region.group) ||
      regions.contains(region.id) ||
      cities.contains(l.city);
  if (!open) return false;
  final from = fromBy[region.group], to = toBy[region.group];
  if (from != null && l.year < from) return false;
  if (to != null && l.year > to) return false;
  return true;
}

/// Whether [j] exists in this life's city this year.
bool eraJobHere(Life l, EraRules era, EraJob j) {
  if (!_here(l, era, j.groups, j.regions, j.cities, j.fromBy, j.toBy)) {
    return false;
  }
  if (j.faith != null && !era.regionOf(l).faithIn(l.year).contains(j.faith!)) {
    return false;
  }
  return true;
}

bool eraSchoolHere(Life l, EraRules era, EraSchool s) =>
    _here(l, era, s.groups, const [], s.cities, s.fromBy, s.toBy);

/// The era jobs found in this life's city this year.
List<EraJob> eraJobsHere(Life l, EraRules era) => [
  for (final j in era.jobs)
    if (eraJobHere(l, era, j)) j,
];

/// The schools found here this year.
List<EraSchool> eraSchoolsHere(Life l, EraRules era) => [
  for (final s in era.school)
    if (eraSchoolHere(l, era, s)) s,
];

/// Pay for a step of [j] here this year, in florins.
int eraPay(Life l, EraRules era, EraJob j, int step) =>
    era.wage(j.ladder[step].pay, era.regionOf(l), l.year);

String _money(Life l, int florins) => moneyIn(florins, l.country);

/// Why [j] is closed to this life, or null if it can start it.
String? eraJobLock(Life l, EraRules era, EraJob j) {
  if (!eraJobHere(l, era, j)) return 'Not found in ${l.city} in ${l.year}.';
  if (l.age < j.minAge) return 'From age ${j.minAge}.';
  if (j.sex != null && j.sex != l.gender) {
    return j.sex == 'male'
        ? 'Closed: in this time it is closed to women.'
        : 'Closed: in this time only women do this work.';
  }
  if (j.legit && eraIllegit(l)) {
    return 'Closed: ${j.closedLegit ?? 'it does not take children born outside marriage'}.';
  }
  if (eraStatus(l) < j.minStatus) {
    return 'Closed: born ${eraStatusName(era, l).toLowerCase()}, '
        'not ${eraStatusName(era, l, j.minStatus).toLowerCase()}.';
  }
  final reads = eraReads(l);
  final missing = [
    for (final r in j.reads)
      if (!reads.contains(r)) eraReadName(r),
  ];
  if (missing.isNotEmpty) return 'Needs ${missing.join(' and ')}.';
  if (j.needsSchool == 'university' && !reads.contains('degree')) {
    return 'Needs a university degree.';
  }
  if (j.entryFee > 0 && l.money < j.entryFee) {
    return 'Needs ${_money(l, j.entryFee)} for ${j.entryWhy ?? 'the entry fee'}.';
  }
  return null;
}

/// Why [s] is closed to this life, or null if it can enrol.
String? eraSchoolLock(Life l, EraRules era, EraSchool s) {
  if (!eraSchoolHere(l, era, s)) {
    return s.cities.isNotEmpty
        ? 'In ${s.cities.join(', ')}: make a journey there first.'
        : 'Not found in ${l.city} in ${l.year}.';
  }
  if (eraSchoolsDone(l).contains(s.id)) return 'Finished.';
  if (l.age < s.minAge) return 'From age ${s.minAge}.';
  if (l.age > s.maxAge) return 'For ages ${s.minAge} to ${s.maxAge}.';
  if (s.sex != null && s.sex != l.gender) {
    return s.sex == 'male'
        ? 'Closed: in this time it does not take girls.'
        : 'For girls only.';
  }
  if (eraStatus(l) < s.minStatus) {
    return 'Closed: for ${eraStatusName(era, l, s.minStatus).toLowerCase()} '
        'families.';
  }
  if (s.needs != null && !eraReads(l).contains(s.needs)) {
    return 'Needs ${eraReadName(s.needs!)} first.';
  }
  if (s.cost > 0 && l.money < s.cost && l.age >= 16) {
    return 'Needs ${_money(l, s.cost)} a year.';
  }
  return null;
}

/// Why this life can't rise to the next step now, or null.
String? eraRiseLock(Life l, EraRules era) {
  final j = eraJobOf(l, era);
  if (j == null) return 'No trade.';
  final step = eraStep(l);
  if (step >= j.ladder.length - 1) return 'You are at the top of the trade.';
  final need = step < j.years.length ? j.years[step] : 3;
  if (eraYearsInStep(l) < need) {
    final left = need - eraYearsInStep(l);
    return 'After $left more ${left == 1 ? 'year' : 'years'}.';
  }
  final school = j.riseSchool[step];
  if (school == 'university' && !eraReads(l).contains('degree')) {
    return 'Needs a university degree.';
  }
  final fee = step < j.fees.length ? j.fees[step] : 0;
  if (fee > 0 && l.money < fee) return 'Needs ${_money(l, fee)}.';
  if (l.usedActions.contains('era_rise')) return 'Next year.';
  return null;
}

String eraRiseLabel(EraJob j, int step) =>
    step < j.rise.length ? j.rise[step] : 'Ask to rise';

/// Matches the job title set by an event (a Legend's "Garzone in
/// Verrocchio's workshop") to its ladder, or clears the era job.
void syncEraJob(Life l, EraRules era) {
  final title = l.job;
  if (title == null) {
    for (final k in const ['job', 'rank', 'years', 'title']) {
      l.eraPath.remove(k);
    }
    return;
  }
  if (l.eraPath['title'] == title) return;
  final current = eraJobOf(l, era);
  EraJob? found;
  int? step;
  if (current != null && current.stepOf(title) != null) {
    found = current;
    step = current.stepOf(title);
  } else {
    for (final j in era.jobs) {
      final s = j.stepOf(title);
      if (s != null) {
        found = j;
        step = s;
        break;
      }
    }
  }
  if (found == null) {
    l.eraPath
      ..remove('job')
      ..remove('rank')
      ..['title'] = title
      ..['years'] = 0;
    return;
  }
  if (found.id != l.eraPath['job'] || step != eraStep(l)) {
    l.eraPath['years'] = 0;
  }
  l.eraPath
    ..['job'] = found.id
    ..['rank'] = step
    ..['title'] = title;
}

void _setStep(Life l, EraRules era, EraJob j, int step) {
  l.job = j.ladder[step].title;
  l.salary = eraPay(l, era, j, step);
  l.eraPath
    ..['job'] = j.id
    ..['rank'] = step
    ..['years'] = 0
    ..['title'] = l.job;
}

void _enrol(Life l, EraSchool s) => l.eraPath
  ..['school'] = s.id
  ..['schoolName'] = s.name.startsWith('A ') ? 'Taught by a tutor' : s.name
  ..['schoolYears'] = 0;

void _unenrol(Life l) => l.eraPath
  ..remove('school')
  ..remove('schoolName')
  ..remove('schoolYears');

void _say(Life l, String text) =>
    l.feed.add(FeedEntry(l.age, text, kind: 'milestone'));

/// Starts [j] at its first step. A Legend's work follows their story, so
/// only ordinary lives can change trade.
String takeEraJob(Life l, EraRules era, EraJob j) {
  if (l.legendId != null) return 'Your work follows your story.';
  final lock = eraJobLock(l, era, j);
  if (lock != null) return lock;
  if (j.entryFee > 0) l.money -= j.entryFee;
  final hadSchool = eraSchoolOf(l, era);
  if (hadSchool != null && hadSchool.kind == 'university') {
    _unenrol(l);
  }
  _setStep(l, era, j, 0);
  l.eraPath['trade'] = 0;
  l.reason = 'New work';
  l.stats.add('happiness', 3);
  final text = j.guild == null
      ? 'You started as a ${j.ladder[0].title.toLowerCase()} in ${l.city}.'
      : 'You started as a ${j.ladder[0].title.toLowerCase()} in ${l.city}, '
            'under ${j.guild}.';
  _say(l, text);
  return text;
}

/// Leaves the current work.
String leaveEraJob(Life l, EraRules era) {
  if (l.legendId != null) return 'Your work follows your story.';
  final was = l.job;
  if (was == null) return 'You have no work to leave.';
  l.job = null;
  l.salary = 0;
  syncEraJob(l, era);
  final text = 'You left your place as $was.';
  _say(l, text);
  return text;
}

/// Tries to rise a step: the guild, the masterpiece, the patron.
String riseInEraTrade(Life l, EraRules era, Random rng) {
  final lock = eraRiseLock(l, era);
  if (lock != null) return lock;
  final j = eraJobOf(l, era)!;
  final step = eraStep(l);
  final fee = step < j.fees.length ? j.fees[step] : 0;
  final need = step < j.years.length ? j.years[step] : 3;
  l.usedActions.add('era_rise');
  final odds =
      (0.45 + l.stats['smarts'] / 250 + (eraYearsInStep(l) - need) * 0.06)
          .clamp(0.2, 0.95);
  if (rng.nextDouble() < odds) {
    l.money -= fee;
    final from = l.job;
    _setStep(l, era, j, step + 1);
    l.reason = 'Rose in the trade';
    l.stats.add('happiness', 8);
    final text =
        '${eraRiseLabel(j, step)}: done. You went from $from to '
        '${l.job}.';
    _say(l, text);
    return text;
  }
  l.money -= fee ~/ 3;
  l.reason = 'Turned down';
  l.stats.add('happiness', -4);
  return 'The masters said not yet. Try again next year.';
}

/// The yearly extra work of a trade ("Take on a commission").
String eraExtraWork(Life l, EraRules era, Random rng) {
  final j = eraJobOf(l, era);
  if (j == null || l.usedActions.contains('era_extra')) return 'Next year.';
  l.usedActions.add('era_extra');
  final pay = max(1, (l.salary * (0.15 + rng.nextDouble() * 0.2)).round());
  l.money += pay;
  l.reason = j.extra ?? 'Extra work';
  l.stats.add('health', -1);
  l.stats.add('happiness', 1);
  l.eraPath['years'] = eraYearsInStep(l);
  return 'Hard work, and it earned you ${_money(l, pay)}.';
}

/// Goes to [s] (the family pays while you are young).
String enrolEraSchool(Life l, EraRules era, EraSchool s) {
  final lock = eraSchoolLock(l, era, s);
  if (lock != null) return lock;
  _enrol(l, s);
  l.reason = 'School';
  final text =
      'You started at ${s.name.startsWith('A ') ? s.name.toLowerCase() : s.name} '
      'in ${l.city}.';
  _say(l, text);
  return text;
}

/// Leaves school before the end.
String leaveEraSchool(Life l, EraRules era) {
  final s = eraSchoolOf(l, era);
  if (s == null) return 'You are not at school.';
  _unenrol(l);
  return 'You left ${s.name.toLowerCase()}.';
}

/// Studies hard this year.
String eraStudy(Life l, EraRules era, Random rng) {
  if (eraSchoolOf(l, era) == null || l.usedActions.contains('era_study')) {
    return 'Next year.';
  }
  l.usedActions.add('era_study');
  l.reason = 'Study';
  l.stats.add('smarts', 2 + rng.nextInt(3));
  return 'You studied by candlelight and your teachers noticed.';
}

/// Why this life can't teach itself Latin, or null.
String? eraLatinLock(Life l) {
  final r = eraReads(l);
  if (r.contains('latin')) return 'You read Latin.';
  if (!r.contains('read')) return 'Needs reading first.';
  if (l.age < 12) return 'From age 12.';
  if (l.usedActions.contains('era_latin')) return 'Next year.';
  return null;
}

/// A year of teaching yourself Latin from borrowed books (slow).
String teachYourselfLatin(Life l, Random rng) {
  final lock = eraLatinLock(l);
  if (lock != null) return lock;
  l.usedActions.add('era_latin');
  final now = min(
    100,
    eraLatin(l) + 12 + rng.nextInt(10) + l.stats['smarts'] ~/ 12,
  );
  l.eraPath['latin'] = now;
  l.stats.add('smarts', 1);
  l.reason = 'Latin';
  if (now >= 100) {
    _gainReads(l, const ['latin']);
    const text = 'After years of borrowed grammars you can read Latin.';
    _say(l, text);
    return text;
  }
  return 'You worked through another grammar. Latin: $now%.';
}

void _gainReads(Life l, List<String> gives) {
  final r = eraReads(l)..addAll(gives);
  l.eraPath['reads'] = r.toList()..sort();
}

/// Sets birth status, legitimacy and a family trade for an ordinary life.
void eraBirth(Life l, EraRules era, Random rng) {
  final roll = rng.nextDouble();
  final status = roll < 0.3 ? 0 : (roll < 0.7 ? 1 : (roll < 0.94 ? 2 : 3));
  l.eraPath
    ..['status'] = status
    ..['illegit'] = rng.nextDouble() < 0.04;
  // The father's trade, from the work of the place at the time.
  final father =
      Life(
          seed: 0,
          firstName: '',
          surname: '',
          gender: 'male',
          country: l.country,
          city: l.city,
          birthYear: l.birthYear - 30,
          stats: l.stats,
          npcs: [],
        )
        ..age = 30
        ..eraPath['status'] = status
        ..eraPath['reads'] = const ['read', 'reckon', 'latin', 'arabic'];
  final trades = [
    for (final j in era.jobs)
      if (eraJobHere(l, era, j) &&
          j.minStatus <= status &&
          j.sex != 'female' &&
          j.faith == null &&
          j.needsSchool == null &&
          eraJobLock(father, era, j) == null)
        j,
  ];
  if (trades.isEmpty) return;
  final farm = trades.where((j) => j.id == 'farm').firstOrNull;
  final pick = status == 0 && farm != null && rng.nextDouble() < 0.7
      ? farm
      : trades[rng.nextInt(trades.length)];
  l.eraPath['family'] = pick.id;
  final dad = l.who('father');
  if (dad != null) {
    final step = status >= 2 ? pick.ladder.length - 1 : 1;
    dad.info['job'] = pick.ladder[min(step, pick.ladder.length - 1)].title;
  }
}

/// One year of work and school for an era life: years in the trade,
/// school fees and finishing, and (in an ordinary life) the family
/// sending a child to school or to a master, as families did.
List<String> eraPathYear(Life l, EraRules era, Random rng) {
  final out = <String>[];
  syncEraJob(l, era);
  if (l.job != null) {
    l.eraPath['years'] = eraYearsInStep(l) + 1;
    l.eraPath['trade'] = eraYearsInTrade(l) + 1;
    // Pay follows the place and the price level.
    final j = eraJobOf(l, era);
    if (j != null && l.legendId == null) {
      l.salary = eraPay(l, era, j, eraStep(l));
    }
  }
  // The abacus school event sends a child there.
  if (l.flags.containsKey('abacus') && l.eraPath['abacusEvent'] != true) {
    l.eraPath['abacusEvent'] = true;
    final abacus = era.schoolById('abacus');
    if (abacus != null &&
        eraSchoolOf(l, era) == null &&
        eraSchoolLock(l, era, abacus) == null) {
      _enrol(l, abacus);
    }
  }
  final s = eraSchoolOf(l, era);
  if (s != null) {
    final cost = l.age >= 16 ? s.cost : 0;
    if (cost > 0 && l.money < cost) {
      _unenrol(l);
      out.add('There was no money for ${s.name.toLowerCase()}, so you left.');
    } else {
      l.money -= cost;
      final y = eraSchoolYears(l) + 1;
      l.eraPath['schoolYears'] = y;
      if (y >= s.years) {
        _gainReads(l, s.gives);
        _unenrol(l);
        l.eraPath['done'] = [...eraSchoolsDone(l), s.id];
        l.stats.add('smarts', 3);
        final what = s.gives.contains('degree')
            ? 'You took your degree.'
            : 'You can now ${[for (final g in s.gives)
                if (g != 'degree') _verb(g)].join(' and ')}.';
        out.add('You finished at ${s.name}. $what');
      }
    }
  }
  out.addAll(_family(l, era, rng));
  return out;
}

String _verb(String g) => switch (g) {
  'read' => 'read and write',
  'reckon' => 'reckon accounts',
  'latin' => 'read Latin',
  'arabic' => 'read Arabic',
  _ => g,
};

List<String> _family(Life l, EraRules era, Random rng) {
  final out = <String>[];
  final status = eraStatus(l);
  // Between 5 and 8, the family may send a child to school.
  if (l.age >= 5 &&
      l.age <= 8 &&
      l.eraPath['placedSchool'] != true &&
      eraSchoolOf(l, era) == null) {
    // A Legend goes where history says ("sendTo": abacus school).
    final sendTo = era.schoolById(l.eraPath['sendTo'] as String? ?? '');
    final chance = sendTo != null ? 1.0 : const [0.05, 0.3, 0.7, 1.0][status];
    final open = [
      for (final s in eraSchoolsHere(l, era))
        if (s.kind == 'basic' && eraSchoolLock(l, era, s) == null) s,
    ]..sort((a, b) => b.minStatus.compareTo(a.minStatus));
    if (sendTo != null && open.contains(sendTo)) {
      open
        ..remove(sendTo)
        ..insert(0, sendTo);
    }
    if (open.isNotEmpty) {
      l.eraPath['placedSchool'] = true;
      if (rng.nextDouble() < chance) {
        final s = open.first;
        _enrol(l, s);
        out.add(
          'Your family sent you to ${s.name.startsWith('A ') ? s.name.toLowerCase() : s.name}.',
        );
      }
    }
  }
  // From 12, a child with no school and no work is placed with a master,
  // in the family trade if it can be.
  if (l.legendId == null &&
      l.age >= 12 &&
      l.age <= 16 &&
      l.job == null &&
      eraSchoolOf(l, era) == null &&
      l.eraPath['placedJob'] != true &&
      status < 3) {
    l.eraPath['placedJob'] = true;
    final open = [
      for (final j in eraJobsHere(l, era))
        if (eraJobLock(l, era, j) == null && j.entryFee == 0) j,
    ];
    final family = era.job(l.eraPath['family'] as String? ?? '');
    final pick = family != null && open.contains(family)
        ? family
        : (open.isEmpty ? null : open[rng.nextInt(open.length)]);
    if (pick != null) {
      _setStep(l, era, pick, 0);
      l.eraPath['trade'] = 0;
      out.add(
        pick == family
            ? 'You were placed in the family trade, as a '
                  '${pick.ladder[0].title.toLowerCase()}.'
            : 'You were placed as a ${pick.ladder[0].title.toLowerCase()}.',
      );
    }
  }
  return out;
}
