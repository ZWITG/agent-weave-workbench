import 'dart:math';

import 'actions.dart';
import 'jobs.dart';
import 'justice.dart' show convictions, hasSeriousRecord;
import 'migration.dart' show cashFields, undocumented, undocumentedPay;
import 'models.dart';
import 'world_data.dart';

/// The Path tab: education routes, the job board and career ladders.
/// Every option stays visible with the reason it is locked (plan pillar 2,
/// "no silent failure"); the ladder always names the next requirement.

// ---------------- Education ----------------

/// How long each course lasts and what finishing it gives you.
/// Graduate school length varies by programme (school.gradYears).
const courses = <String, (int years, String done, String label)>{
  'university': (4, 'graduate', 'university'),
  'community college': (2, 'associate degree', 'community college'),
  'trade school': (2, 'trade certificate', 'trade school'),
  'apprenticeship': (3, 'trade certificate', 'apprenticeship'),
  'grad school': (2, 'graduate', 'graduate school'),
};

int courseYears(Life life) => life.education == 'grad school'
    ? max(1, life.school.gradYears)
    : courses[life.education]?.$1 ?? 0;

const _finishedSchool = {
  'high school graduate',
  'graduate',
  'associate degree',
  'trade certificate',
  ...[
    'university',
    'community college',
    'trade school',
    'apprenticeship',
    'grad school',
  ],
};

/// Player-facing name for an education level.
String educationLabel(Life life) => switch (life.education) {
  'none' => 'Not in school yet',
  'graduate' => 'University degree',
  'high school graduate' => 'School diploma',
  'dropout' => 'Left school early',
  final e => e[0].toUpperCase() + e.substring(1),
};

bool finishedSchool(Life life) => _finishedSchool.contains(life.education);
bool studying(Life life) => courses.containsKey(life.education);

/// "Year 2 of 4" while on a course, otherwise null.
String? courseProgress(Life life) {
  final c = courses[life.education];
  if (c == null) return null;
  final years = courseYears(life);
  final year = (life.age - life.eduSince + 1).clamp(1, years);
  return 'Year $year of $years';
}

/// Called each birthday: finishes a course once its years are done.
String? graduateIfDone(Life life) {
  final c = courses[life.education];
  if (c == null || life.age - life.eduSince < courseYears(life)) return null;
  final was = life.education;
  life.education = c.$2;
  life.eduSince = life.age;
  life.school.tuition = 0;
  if (was == 'university') {
    life.school.degrees.add(
      'Degree in ${life.school.major ?? 'General Studies'}',
    );
  }
  if (was == 'grad school' && life.school.gradProgramme != null) {
    life.school.degrees.add(life.school.gradProgramme!);
    final p = life.school.gradProgramme!;
    life.school.gradProgramme = null;
    return 'You finished graduate school: $p. Years of study, one very long handshake on stage.';
  }
  if (was == 'apprenticeship') {
    life.job = null;
    life.salary = 0;
    return 'Your apprenticeship is complete: you are a qualified tradesperson. Time to find a proper job.';
  }
  life.flags['finished_${c.$3.replaceAll(' ', '_')}'] = Memory(
    life.age,
    'finishing ${c.$3}',
  );
  return switch (c.$2) {
    'graduate' => 'You graduated from university!',
    'associate degree' => 'You earned your associate degree.',
    _ => 'You qualified from trade school.',
  };
}

String? _needsSchoolDone(Life life) {
  if (studying(life)) return 'Already studying';
  if (life.education == 'dropout') return 'Needs a school diploma';
  if (!finishedSchool(life)) return 'Finish secondary school first';
  return null;
}

ActionResult _enrol(Life life, String course, int fee, String text) {
  life.education = course;
  life.eduSince = life.age;
  final paid = fee.clamp(0, life.money < 0 ? 0 : life.money);
  final loan = fee - paid;
  life.money -= paid;
  if (loan > 0) {
    life.debts['Student loan'] = (life.debts['Student loan'] ?? 0) + loan;
  }
  return ActionResult(text, [
    if (paid > 0) 'Money −\$$paid',
    if (loan > 0) 'Student loan \$$loan at 5%',
    courseProgress(life)!,
  ]);
}

final educationActions = <GameAction>[
  GameAction(
    id: 'community_college',
    label: 'Go to community college',
    category: 'School',
    keywords: ['community college', 'associate', 'study', 'cheap'],
    minAge: 18,
    priceNote: 'Fee \$1,000 · loan if short',
    extraCheck: _needsSchoolDone,
    run: (life, rng) => _enrol(
      life,
      'community college',
      1000,
      'You signed up at community college. Cheaper, and open to everyone.',
    ),
  ),
  GameAction(
    id: 'trade_school',
    label: 'Learn a trade',
    category: 'School',
    keywords: ['trade', 'apprentice', 'electrician', 'plumber', 'mechanic'],
    minAge: 17,
    priceNote: 'Fee \$1,500 · loan if short',
    extraCheck: _needsSchoolDone,
    run: (life, rng) => _enrol(
      life,
      'trade school',
      1500,
      'You started trade school. Real skills, real wages.',
    ),
  ),
  GameAction(
    id: 'drop_out',
    label: 'Drop out of school',
    category: 'School',
    keywords: ['drop out', 'quit school', 'leave school'],
    minAge: 16,
    maxAge: 17,
    extraCheck: (life) =>
        life.education == 'secondary' ? null : 'Only in secondary school',
    run: (life, rng) {
      life.education = 'dropout';
      life.flags['dropped_out'] = Memory(life.age, 'dropping out of school');
      return statChange(
        life,
        'You walked out of school for the last time. Your parents are not happy.',
        {'happiness': 2, 'discipline': -3},
      );
    },
  ),
  GameAction(
    id: 'equivalency_exam',
    label: 'Take the equivalency exam',
    category: 'School',
    keywords: ['exam', 'diploma', 'equivalency', 'ged', 'second chance'],
    minAge: 16,
    cost: 100,
    extraCheck: (life) =>
        life.education == 'dropout' ? null : 'Only if you left school early',
    run: (life, rng) {
      life.money -= 100;
      final chance = 30 + life.stats['smarts'] ~/ 2;
      if (rng.nextInt(100) < chance) {
        life.education = 'high school graduate';
        return ActionResult('You passed! You now have a school diploma.', [
          'Money −\$100',
          'Diploma earned',
        ]);
      }
      return ActionResult('You did not pass this time. Retakes are allowed.', [
        'Money −\$100',
        'Why: Smarts ${life.stats['smarts']}',
      ]);
    },
  ),
  GameAction(
    id: 'leave_course',
    label: 'Leave your course',
    category: 'School',
    keywords: ['drop out', 'leave', 'quit', 'university', 'college'],
    minAge: 17,
    extraCheck: (life) => studying(life) ? null : 'Not on a course',
    run: (life, rng) {
      final was = life.education;
      life.education = 'high school graduate';
      return statChange(life, 'You left $was without finishing.', {
        'happiness': 2,
        'discipline': -2,
      });
    },
  ),
];

// ---------------- Careers ----------------

/// Ladder salary multipliers per step (up to 5 steps).
const _rankPay = [1.0, 1.3, 1.7, 2.4, 3.6];

/// Years in a role before the next promotion can be asked for.
const yearsPerPromotion = 2;

class Career {
  const Career({
    required this.id,
    required this.field,
    required this.ladder,
    required this.baseSalary,
    required this.needs,
    this.minAge = 18,
    this.minSmarts = 0,
    this.keyStat = 'smarts',
    this.special = false,
    this.extra,
    this.interview = 'office',
    this.elected = false,
    this.blurb,
  });

  final String id;
  final String field;
  final List<String> ladder;
  final int baseSalary;

  /// 'any', 'school', 'trade', 'associate' or 'degree'.
  final String needs;
  final int minAge;
  final int minSmarts;

  /// The stat that drives performance in this job (plan: 1–2 key stats).
  final String keyStat;

  /// Special careers (all free; plan Module 5) have their own entry rules
  /// and a signature mechanic (jobs.dart).
  final bool special;
  final String? Function(Life life)? extra;

  /// Interview question family: office, care, tech, service, uniform,
  /// creative.
  final String interview;

  /// Politicians move up by winning elections, not promotions.
  final bool elected;
  final String? blurb;

  String get title => ladder.first;
  int salaryAt(int rank) => (baseSalary * _rankPay[rank]).round();

  /// What this rank pays where you live (country wage level).
  int payIn(Life l, int rank) =>
      (salaryAt(rank) * countryProfile(l.country).wage / 100).round() * 100;

  String get needsLabel => switch (needs) {
    'school' => 'School diploma',
    'trade' => 'Trade certificate',
    'associate' => 'Associate degree or university degree',
    'degree' => 'University degree',
    _ => 'No qualifications',
  };

  bool _meetsEducation(Life life) => switch (needs) {
    'school' => finishedSchool(life),
    'trade' => life.education == 'trade certificate',
    'associate' =>
      life.education == 'associate degree' || life.education == 'graduate',
    'degree' => life.education == 'graduate',
    _ => true,
  };

  /// Null when you can apply, otherwise why not.
  String? lockReason(Life life) {
    if (life.age < minAge) return 'Unlocks at $minAge';
    if (life.careerId == id) return 'Your current job';
    if (life.retired) return 'You are retired';
    // Without papers, only cash-in-hand work (migration.dart).
    if (undocumented(life) && !cashFields.contains(field)) {
      return 'Needs legal work papers';
    }
    if (life.usedActions.contains('apply:$id')) return 'Applied this year';
    if (studying(life) && needs != 'any') return 'Finish your course first';
    if (!_meetsEducation(life)) return 'Needs: $needsLabel';
    if (life.stats['smarts'] < minSmarts) return 'Needs Smarts $minSmarts+';
    if (life.prison != null) return 'Not possible in prison';
    // A criminal record closes regulated jobs (plan Module 8).
    if (const {'police', 'lawyer'}.contains(id) && convictions(life) > 0) {
      return 'Blocked by a criminal record';
    }
    if (recordChecked.contains(id) && hasSeriousRecord(life)) {
      return 'Blocked by a serious criminal record';
    }
    return extra?.call(life);
  }

  /// Hiring chance in percent before the interview (shown on the job
  /// board). Better-paid jobs are more competitive.
  int chance(Life life) =>
      (49 +
              life.stats['smarts'] ~/ 3 +
              life.stats['charisma'] ~/ 5 -
              baseSalary ~/ 2000 +
              (special ? -10 : 0) +
              (life.worldMods['hiring'] ?? 0) +
              (life.worldMods['name'] ?? 0) +
              (life.difficulty == 'easy'
                  ? 10
                  : life.difficulty == 'hard'
                  ? -10
                  : 0))
          .clamp(5, 95);
}

bool _has(Life l, String degree) => l.school.degrees.contains(degree);
String? _stat(Life l, String s, int min) => l.stats[s] >= min
    ? null
    : 'Needs ${s[0].toUpperCase()}${s.substring(1)} $min+';

String? _actorReq(Life l) =>
    l.school.electives.contains('Drama') ||
        l.school.clubs.contains('Drama club') ||
        l.flags.containsKey('clique_stage') ||
        l.school.major == 'Fine Arts'
    ? null
    : _stat(l, 'charisma', 60) ?? _stat(l, 'looks', 55);
String? _musicianReq(Life l) =>
    _stat(l, 'creativity', 55) ??
    (l.school.lessons == 'Piano' ||
            l.school.clubs.contains('Band') ||
            l.school.clubs.contains('Choir') ||
            l.school.electives.contains('Music') ||
            l.flags.containsKey('instrument')
        ? null
        : 'Needs music lessons, band, choir or the Music elective');
String? _athleteReq(Life l) =>
    _stat(l, 'athleticism', 70) ??
    (l.school.seasons > 0 || l.flags.containsKey('captain')
        ? null
        : 'Needs a school team season');
String? _modelReq(Life l) => _stat(l, 'looks', 70);
String? _politicsReq(Life l) =>
    _stat(l, 'charisma', 55) ??
    (l.flags.containsKey('arrested')
        ? 'A criminal record rules this out'
        : null);
String? _militaryReq(Life l) =>
    _stat(l, 'health', 60) ?? _stat(l, 'athleticism', 50);
String? _lawyerReq(Life l) => !_has(l, 'Law')
    ? 'Needs a Law degree (graduate school)'
    : l.flags.containsKey('passed_bar')
    ? null
    : 'Needs to pass the bar exam';
String? _doctorReq(Life l) =>
    _has(l, 'Medicine') ? null : 'Needs a Medicine degree (graduate school)';
String? _pilotReq(Life l) => l.flags.containsKey('pilot_licence')
    ? null
    : 'Needs a commercial pilot licence (flight school)';
String? _hustlerReq(Life l) => null;
String? _vetReq(Life l) =>
    _has(l, 'Veterinary Medicine') ? null : 'Needs a Veterinary degree';

const careers = <Career>[
  Career(
    id: 'retail',
    field: 'Retail',
    ladder: [
      'Shop assistant',
      'Shift supervisor',
      'Store manager',
      'Area manager',
    ],
    baseSalary: 19000,
    needs: 'any',
    minAge: 16,
    keyStat: 'charisma',
    interview: 'service',
  ),
  Career(
    id: 'cook',
    field: 'Food',
    ladder: ['Line cook', 'Sous-chef', 'Head chef', 'Restaurant owner'],
    baseSalary: 21000,
    needs: 'any',
    minAge: 16,
    keyStat: 'creativity',
    interview: 'service',
  ),
  Career(
    id: 'office',
    field: 'Office',
    ladder: [
      'Receptionist',
      'Office administrator',
      'Office manager',
      'Operations director',
    ],
    baseSalary: 23000,
    needs: 'school',
    keyStat: 'discipline',
  ),
  Career(
    id: 'police',
    field: 'Public service',
    ladder: [
      'Police cadet',
      'Police officer',
      'Sergeant',
      'Detective',
      'Police chief',
    ],
    baseSalary: 30000,
    needs: 'school',
    keyStat: 'discipline',
    interview: 'uniform',
    extra: _noRecord,
  ),
  Career(
    id: 'electrician',
    field: 'Trades',
    ladder: [
      'Apprentice electrician',
      'Electrician',
      'Master electrician',
      'Contractor',
    ],
    baseSalary: 29000,
    needs: 'trade',
    keyStat: 'discipline',
    interview: 'tech',
  ),
  Career(
    id: 'lab',
    field: 'Science',
    ladder: [
      'Lab technician',
      'Senior technician',
      'Lab supervisor',
      'Lab director',
    ],
    baseSalary: 30000,
    needs: 'associate',
    minSmarts: 50,
    interview: 'tech',
  ),
  Career(
    id: 'nurse',
    field: 'Healthcare',
    ladder: ['Junior nurse', 'Staff nurse', 'Charge nurse', 'Nurse manager'],
    baseSalary: 35000,
    needs: 'degree',
    minSmarts: 55,
    keyStat: 'karma',
    interview: 'care',
  ),
  Career(
    id: 'teacher',
    field: 'Education',
    ladder: ['Trainee teacher', 'Teacher', 'Head of department', 'Principal'],
    baseSalary: 33000,
    needs: 'degree',
    minSmarts: 50,
    keyStat: 'charisma',
    interview: 'care',
  ),
  Career(
    id: 'analyst',
    field: 'Finance',
    ladder: ['Junior analyst', 'Analyst', 'Senior analyst', 'Finance director'],
    baseSalary: 40000,
    needs: 'degree',
    minSmarts: 60,
  ),
  Career(
    id: 'developer',
    field: 'Technology',
    ladder: [
      'Junior developer',
      'Developer',
      'Senior developer',
      'Engineering lead',
    ],
    baseSalary: 45000,
    needs: 'degree',
    minSmarts: 65,
    interview: 'tech',
  ),
  // ---- Special careers (all free) ----
  Career(
    id: 'actor',
    field: 'Acting',
    ladder: [
      'Extra',
      'Bit-part actor',
      'Supporting actor',
      'Lead actor',
      'Movie star',
    ],
    baseSalary: 14000,
    needs: 'any',
    keyStat: 'charisma',
    special: true,
    extra: _actorReq,
    interview: 'creative',
    blurb: 'Auditions decide every step; big breaks happen.',
  ),
  Career(
    id: 'musician',
    field: 'Music',
    ladder: [
      'Busker',
      'Open-mic regular',
      'Signed artist',
      'Touring headliner',
    ],
    baseSalary: 9000,
    needs: 'any',
    minAge: 16,
    keyStat: 'creativity',
    special: true,
    extra: _musicianReq,
    interview: 'creative',
    blurb: 'Write and release songs; a hit changes everything.',
  ),
  Career(
    id: 'athlete',
    field: 'Sport',
    ladder: ['Amateur', 'Semi-pro', 'Professional', 'All-star'],
    baseSalary: 15000,
    needs: 'any',
    keyStat: 'athleticism',
    special: true,
    extra: _athleteReq,
    interview: 'uniform',
    blurb: 'Seasons, injuries and an early retirement.',
  ),
  Career(
    id: 'model',
    field: 'Modelling',
    ladder: ['Catalogue model', 'Runway model', 'Campaign model', 'Supermodel'],
    baseSalary: 16000,
    needs: 'any',
    keyStat: 'looks',
    special: true,
    extra: _modelReq,
    interview: 'creative',
    blurb: 'Castings and campaigns; looks are everything here.',
  ),
  Career(
    id: 'politician',
    field: 'Politics',
    ladder: [
      'Council member',
      'Mayor',
      'Member of parliament',
      'Head of government',
    ],
    baseSalary: 26000,
    needs: 'school',
    minAge: 21,
    keyStat: 'charisma',
    special: true,
    extra: _politicsReq,
    elected: true,
    interview: 'office',
    blurb: 'Win elections to move up; scandals end careers.',
  ),
  Career(
    id: 'military',
    field: 'Armed forces',
    ladder: ['Private', 'Corporal', 'Sergeant', 'Lieutenant', 'Colonel'],
    baseSalary: 24000,
    needs: 'any',
    keyStat: 'athleticism',
    special: true,
    extra: _militaryReq,
    interview: 'uniform',
    blurb: 'Deployments bring risk, medals and respect.',
  ),
  Career(
    id: 'lawyer',
    field: 'Law',
    ladder: ['Associate', 'Senior associate', 'Partner', 'Judge'],
    baseSalary: 52000,
    needs: 'degree',
    keyStat: 'smarts',
    special: true,
    extra: _lawyerReq,
    blurb: 'Pass the bar exam, win cases, maybe take the bench.',
  ),
  Career(
    id: 'doctor',
    field: 'Medicine',
    ladder: [
      'Resident doctor',
      'Attending physician',
      'Surgeon',
      'Chief of medicine',
    ],
    baseSalary: 58000,
    needs: 'degree',
    keyStat: 'smarts',
    special: true,
    extra: _doctorReq,
    interview: 'care',
    blurb: 'Long shifts, life-and-death calls.',
  ),
  Career(
    id: 'pilot',
    field: 'Aviation',
    ladder: ['First officer', 'Captain', 'Senior captain', 'Chief pilot'],
    baseSalary: 48000,
    needs: 'school',
    keyStat: 'discipline',
    special: true,
    extra: _pilotReq,
    interview: 'uniform',
    blurb: 'Needs a licence from flight school.',
  ),
  Career(
    id: 'vet',
    field: 'Animal care',
    ladder: ['Junior vet', 'Veterinarian', 'Senior vet', 'Practice owner'],
    baseSalary: 46000,
    needs: 'degree',
    keyStat: 'karma',
    special: true,
    extra: _vetReq,
    interview: 'care',
  ),
  Career(
    id: 'hustler',
    field: 'The street',
    ladder: ['Busker', 'Street seller', 'Market regular', 'Street legend'],
    baseSalary: 6000,
    needs: 'any',
    minAge: 14,
    keyStat: 'charisma',
    special: true,
    extra: _hustlerReq,
    interview: 'service',
    blurb: 'Earnings vary every year. Legal hustles only here.',
  ),
];

String? _noRecord(Life l) =>
    l.flags.containsKey('arrested') ? 'Needs a clean record' : null;

/// Careers that check for a criminal record.
const recordChecked = {
  'teacher',
  'doctor',
  'nurse',
  'politician',
  'military',
  'pilot',
};

Career? careerById(String? id) {
  for (final c in careers) {
    if (c.id == id) return c;
  }
  return null;
}

/// Puts the player into [c] at its first step, with a new boss and
/// colleagues (jobs.dart).
void startCareer(Life life, Career c) {
  leaveWorkplace(life);
  life.careerId = c.id;
  life.careerRank = 0;
  life.jobSince = life.age;
  life.job = c.title;
  life.salary = c.payIn(life, 0);
  // Cash in hand pays less.
  if (undocumented(life)) {
    life.salary = (life.salary * undocumentedPay).round();
  }
  life.retired = false;
  life.performance = 55;
  life.lowPerfYears = 0;
  life.jobLostAge = null;
  newWorkplace(life, c);
}

/// Applying starts a 3-question interview (jobs.dart); the last answer
/// decides the job.
ActionResult applyForCareer(Life life, Career c, Random rng) {
  life.usedActions.add('apply:${c.id}');
  life.interview = InterviewState();
  life.sceneQueue.add('interview:${c.id}:0');
  return ActionResult('Your application for ${c.title} got you an interview.', [
    'Answer three questions',
  ]);
}

/// What the next ladder step needs, or null at the top / with no career.
String? promotionLock(Life life) {
  final c = careerById(life.careerId);
  if (c == null) return 'Needs a job from the job board';
  if (life.careerRank >= c.ladder.length - 1) return 'Top of the ladder';
  if (c.elected) return 'Politicians move up by winning elections';
  final left = yearsPerPromotion - (life.age - life.jobSince);
  if (left > 0) return 'Needs $left more year${left == 1 ? '' : 's'} in role';
  if (c.id == 'lawyer' && life.careerRank == 2 && life.stats['karma'] < 50) {
    return 'Judges need Karma 50+';
  }
  return null;
}

/// Plan formula: p = clamp(0.05 + (Perf − 60)/100 + tenure×0.03 +
/// bossRel/400, 0, 0.6), plus 10 points for working hard this year.
int promotionOdds(Life life) {
  final tenure = life.age - life.jobSince;
  final boss = bossOf(life)?.bond ?? 50;
  final p = (0.05 + (life.performance - 60) / 100 + tenure * 0.03 + boss / 400)
      .clamp(0.0, 0.6);
  return (p * 100).round() +
      (life.usedActions.contains('work_harder') ? 10 : 0);
}

final careerActions = <GameAction>[
  GameAction(
    id: 'ask_promotion',
    label: 'Ask for a promotion',
    category: 'Work',
    keywords: ['promotion', 'promote', 'career', 'ladder', 'boss'],
    minAge: 16,
    extraCheck: promotionLock,
    run: (life, rng) {
      final c = careerById(life.careerId)!;
      final odds = promotionOdds(life);
      if (rng.nextInt(100) < odds) {
        life.careerRank++;
        life.jobSince = life.age;
        life.job = c.ladder[life.careerRank];
        final raise = c.payIn(life, life.careerRank) - life.salary;
        life.salary = c.payIn(life, life.careerRank);
        if (life.careerRank == c.ladder.length - 1) {
          life.flags['top_of_career'] = Memory(
            life.age,
            'becoming ${life.job}',
          );
        }
        return ActionResult('You were promoted to ${life.job}!', [
          'Salary +\$$raise/year',
        ]);
      }
      return statChange(
          life,
          'Not this time. Your manager wants to see more from you.',
          {'happiness': -2},
        )
        ..notes.addAll([
          'Why: odds were $odds% (performance ${life.performance}%, ${life.age - life.jobSince} years in role, boss ${bossOf(life)?.bond ?? 50}%)',
          if (!life.usedActions.contains('work_harder'))
            'Tip: work harder this year first',
        ]);
    },
  ),
];
