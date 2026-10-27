import 'dart:math';

import 'actions.dart';
import 'models.dart';

/// The Path tab: education routes, the job board and career ladders.
/// Every option stays visible with the reason it is locked (plan pillar 2,
/// "no silent failure"); the ladder always names the next requirement.

// ---------------- Education ----------------

/// How long each course lasts and what finishing it gives you.
const courses = <String, (int years, String done, String label)>{
  'university': (4, 'graduate', 'university'),
  'community college': (2, 'associate degree', 'community college'),
  'trade school': (2, 'trade certificate', 'trade school'),
};

const _finishedSchool = {
  'high school graduate',
  'graduate',
  'associate degree',
  'trade certificate',
  ...['university', 'community college', 'trade school'],
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
  final year = (life.age - life.eduSince + 1).clamp(1, c.$1);
  return 'Year $year of ${c.$1}';
}

/// Called each birthday: finishes a course once its years are done.
String? graduateIfDone(Life life) {
  final c = courses[life.education];
  if (c == null || life.age - life.eduSince < c.$1) return null;
  life.education = c.$2;
  life.eduSince = life.age;
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
    id: 'enrol_university',
    label: 'Enrol at university',
    category: 'School',
    keywords: ['university', 'college', 'degree', 'enrol', 'study'],
    minAge: 18,
    priceNote: 'Fee \$3,000 · loan if short',
    extraCheck: (life) => life.education == 'graduate'
        ? 'You already have a degree'
        : _needsSchoolDone(life),
    run: (life, rng) => _enrol(
      life,
      'university',
      3000,
      'You enrolled at university. Four years to a degree.',
    ),
  ),
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

/// Ladder salary multipliers per step.
const _rankPay = [1.0, 1.3, 1.7, 2.4];

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
  });

  final String id;
  final String field;
  final List<String> ladder;
  final int baseSalary;

  /// 'any', 'school', 'trade', 'associate' or 'degree'.
  final String needs;
  final int minAge;
  final int minSmarts;

  String get title => ladder.first;
  int salaryAt(int rank) => (baseSalary * _rankPay[rank]).round();

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
    if (life.usedActions.contains('apply:$id')) return 'Applied this year';
    if (studying(life) && needs != 'any') return 'Finish your course first';
    if (!_meetsEducation(life)) return 'Needs: $needsLabel';
    if (life.stats['smarts'] < minSmarts) return 'Needs Smarts $minSmarts+';
    return null;
  }

  /// Hiring chance in percent (shown on the job board).
  /// Better-paid jobs are more competitive.
  int chance(Life life) =>
      (49 +
              life.stats['smarts'] ~/ 3 +
              life.stats['charisma'] ~/ 5 -
              baseSalary ~/ 2000)
          .clamp(5, 95);
}

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
  ),
  Career(
    id: 'cook',
    field: 'Food',
    ladder: ['Line cook', 'Sous-chef', 'Head chef', 'Restaurant owner'],
    baseSalary: 21000,
    needs: 'any',
    minAge: 16,
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
  ),
  Career(
    id: 'police',
    field: 'Public service',
    ladder: ['Police cadet', 'Police officer', 'Detective', 'Police chief'],
    baseSalary: 30000,
    needs: 'school',
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
  ),
  Career(
    id: 'nurse',
    field: 'Healthcare',
    ladder: ['Junior nurse', 'Staff nurse', 'Charge nurse', 'Nurse manager'],
    baseSalary: 35000,
    needs: 'degree',
    minSmarts: 55,
  ),
  Career(
    id: 'teacher',
    field: 'Education',
    ladder: ['Trainee teacher', 'Teacher', 'Head of department', 'Principal'],
    baseSalary: 33000,
    needs: 'degree',
    minSmarts: 50,
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
  ),
];

Career? careerById(String? id) {
  for (final c in careers) {
    if (c.id == id) return c;
  }
  return null;
}

/// Puts the player into [c] at its first step.
void startCareer(Life life, Career c) {
  life.careerId = c.id;
  life.careerRank = 0;
  life.jobSince = life.age;
  life.job = c.title;
  life.salary = c.salaryAt(0);
}

/// Applies for a job on the board. Rejections list the main reasons.
ActionResult applyForCareer(Life life, Career c, Random rng) {
  life.usedActions.add('apply:${c.id}');
  if (rng.nextInt(100) < c.chance(life)) {
    final had = life.job;
    startCareer(life, c);
    return ActionResult(
      had == null
          ? 'You were hired as a ${c.title}!'
          : 'You left your job as $had and were hired as a ${c.title}!',
      ['Salary \$${life.salary}/year'],
    );
  }
  return ActionResult(
    'The ${c.field.toLowerCase()} job went to someone else.',
    [
      'Why: Smarts ${life.stats['smarts']}, Charisma ${life.stats['charisma']}',
      'Try again next year',
    ],
  );
}

/// What the next ladder step needs, or null at the top / with no career.
String? promotionLock(Life life) {
  final c = careerById(life.careerId);
  if (c == null) return 'Needs a job from the job board';
  if (life.careerRank >= c.ladder.length - 1) return 'Top of the ladder';
  final left = yearsPerPromotion - (life.age - life.jobSince);
  if (left > 0) return 'Needs $left more year${left == 1 ? '' : 's'} in role';
  return null;
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
      final worked = life.usedActions.contains('work_harder');
      final chance =
          30 +
          life.stats['discipline'] ~/ 3 +
          life.stats['smarts'] ~/ 6 +
          (worked ? 15 : 0);
      if (rng.nextInt(100) < chance) {
        life.careerRank++;
        life.jobSince = life.age;
        life.job = c.ladder[life.careerRank];
        final raise = c.salaryAt(life.careerRank) - life.salary;
        life.salary = c.salaryAt(life.careerRank);
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
          'Why: Discipline ${life.stats['discipline']}',
          if (!worked) 'Tip: work harder this year first',
        ]);
    },
  ),
];
