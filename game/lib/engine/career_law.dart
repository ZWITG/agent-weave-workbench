import 'dart:math';

import 'careers.dart' show careerById, recordChecked;
import 'jobs.dart' show leaveJob;
import 'justice.dart' show Crime, crimeById, violentCrimes;
import 'manhunt.dart' show mostWanted;
import 'models.dart';
import 'policing.dart' show addDirtyFile, isCop;
import 'storylet.dart';
import 'underworld.dart' show crewOf, inCrew;

// Where crime meets work: the links between the crime and justice systems
// (justice.dart, underworld.dart, manhunt.dart) and the careers
// (careers.dart, jobs.dart, policing.dart).
//
// - A conviction ends careers that cannot carry one: the police, the law,
//   politics, and (for serious or violent crimes) the record-checked jobs.
// - Your job changes your odds: a police officer knows the patrol routes, a
//   lawyer knows how cases are built, a politician has a face people know.
// - A police officer's crimes go on the Internal Affairs file; a cop on the
//   Most Wanted list is suspended; a cop in a crew is asked for favours;
//   and a case you committed can land on your own desk.
// - A lawyer can defend themselves with their courtroom skill.
// - A criminal record costs votes.

String _m(int v) =>
    '\$${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

/// The odds of being caught, moved by your work, with the reasons shown.
List<(int, String)> careerCrimeOdds(Life l) {
  if (l.job == null) return const [];
  return switch (l.careerId) {
    'police' => const [(-8, 'You know the patrol routes −8')],
    'lawyer' => const [(-4, 'You know how cases are built −4')],
    'politician' when l.careerRank >= 1 => const [
      (6, 'A face people recognise +6'),
    ],
    'actor' ||
    'model' ||
    'musician' ||
    'athlete' when l.careerRank >= 2 => const [(4, 'Fans recognise you +4')],
    _ => const [],
  };
}

/// After a crime you got away with: a police officer's crimes go on the
/// Internal Affairs file (policing.dart).
void careerAfterCrime(Life l, Crime c) {
  if (isCop(l) && c.band != 'minor') addDirtyFile(l, 1);
}

/// A conviction ends the careers that cannot carry one. Returns the line
/// for the verdict, or ''.
String careerAfterConviction(Life l, Crime c) {
  final job = l.job;
  final id = l.careerId;
  if (job == null || id == null) return '';
  final serious =
      c.band == 'serious' || c.band == 'severe' || violentCrimes.contains(c.id);
  final line = switch (id) {
    'police' =>
      'You were dismissed from the force and handed in your badge as $job.',
    'lawyer' when l.careerRank >= careerById('lawyer')!.ladder.length - 1 => 'You were removed from the bench. A judge with a conviction cannot judge.',
    'lawyer' => 'You were struck off: you can no longer practise law.',
    'politician' =>
      'You resigned your seat as $job before your party could ask.',
    'military' when serious =>
      'You were dishonourably discharged from the armed forces.',
    'doctor' ||
    'nurse' when serious => 'The medical council struck you off the register.',
    'pilot' when serious => 'Your pilot\'s licence was revoked.',
    'teacher' when serious =>
      'The school let you go and barred you from teaching.',
    _ when recordChecked.contains(id) && serious =>
      'Your employer let you go after the conviction.',
    _ => '',
  };
  if (line.isEmpty) return '';
  leaveJob(l, fired: true);
  l.flags['career_ended_by_crime'] = Memory(
    l.age,
    'losing your job as $job over a conviction',
  );
  return ' $line';
}

/// A lawyer standing up for themselves: their courtroom skill, not just
/// Charisma and Smarts. Null for everyone else.
int? lawyerSelfSkill(Life l) {
  if (l.careerId != 'lawyer' || l.job == null) return null;
  return 62 + l.careerRank * 7;
}

/// Points off an election for a criminal record (shown in the result).
int recordVotePenalty(int convictions) => min(24, convictions * 8);

/// The police year's links to your own crimes, called from policeYear.
List<String> copCrimeYear(Life l, Random rng) {
  final feed = <String>[];
  if (!isCop(l)) return feed;
  // Your own face on the briefing-room wall.
  if (mostWanted(l)) {
    final old = l.job;
    leaveJob(l, fired: true);
    feed.add(
      'Your own photo went up on the briefing-room wall. You were suspended as $old, then dismissed.',
    );
    return feed;
  }
  if (l.careerRank < 1) return feed;
  // A case you committed lands on your desk.
  if (l.cases.isNotEmpty &&
      rng.nextInt(100) < 20 &&
      !l.sceneQueue.any((q) => q.startsWith('own_case'))) {
    final c = l.cases[rng.nextInt(l.cases.length)];
    l.sceneQueue.add('own_case:${c['crime']}:${c['age']}');
  }
  // Your crew knows you carry a badge.
  final crew = crewOf(l);
  if (inCrew(l) &&
      crew != null &&
      rng.nextInt(100) < 35 &&
      !l.sceneQueue.any((q) => q.startsWith('bribe_offer'))) {
    l.sceneQueue.add('bribe_offer:${crew.id}');
  }
  return feed;
}

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'work',
  scene: true,
  choices: choices,
);

/// "The file on your desk is your own": bury it, pin it on someone, or
/// leave it alone.
Storylet? ownCaseScene(List<String> args, Life l) {
  if (!isCop(l) || args.length < 2) return null;
  final crime = args[0];
  final age = int.tryParse(args[1]);
  Map<String, dynamic>? find(Life l) {
    for (final c in l.cases) {
      if (c['crime'] == crime && c['age'] == age) return c;
    }
    return null;
  }

  final open = find(l);
  if (open == null) return null;
  final label = crimeById(crime).label.toLowerCase();
  final ev = open['evidence'] as int;
  return _scene(
    'own_case',
    'Your sergeant drops a file on your desk: a $label, ${l.age - (age ?? l.age) <= 0 ? 'this year' : '${l.age - age!} years ago'}. Evidence $ev/100. You know exactly who did it. You did.',
    [
      Choice(
        label: 'Lose the file',
        outcome: '',
        risk: 'The case goes away · goes on your Internal Affairs file',
        run: (l, rng) {
          final c = find(l);
          if (c != null) l.cases.remove(c);
          addDirtyFile(l, 1);
          l.stats.add('karma', -4);
          return 'The file went into a box, and the box went into the basement. Nobody will look there for years.';
        },
      ),
      Choice(
        label: 'Pin it on someone with a record',
        outcome: '',
        risk: 'The case closes · a stranger goes down for it · two marks on your file',
        run: (l, rng) {
          final c = find(l);
          if (c != null) l.cases.remove(c);
          addDirtyFile(l, 2);
          l.stats.add('karma', -12);
          l.performance = min(100, l.performance + 6);
          return 'A man with three priors went down for your $label. The station called it good police work. You did not sleep well.';
        },
      ),
      Choice(
        label: 'Work it honestly',
        outcome: '',
        risk: 'The evidence grows · you may end up arresting yourself',
        run: (l, rng) {
          final c = find(l);
          if (c != null) c['evidence'] = min(95, (c['evidence'] as int) + 15);
          l.stats.add('karma', 4);
          return 'You followed the evidence. It pointed where you knew it would. You wrote it all down anyway (evidence ${min(95, ev + 15)}/100).';
        },
      ),
    ],
  );
}

/// Shown on the badge card: why the next envelope might be from your own
/// crew.
String? copCrewNote(Life l) {
  final crew = crewOf(l);
  if (!isCop(l) || crew == null) return null;
  return '${crew.name} knows you carry a badge. Expect favours to be asked (${_m(5000 * (l.careerRank + 1))} envelopes).';
}
