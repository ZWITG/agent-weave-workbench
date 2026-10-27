import 'dart:math';

import 'actions.dart';
import 'careers.dart';
import 'models.dart';
import 'relationships.dart';
import 'storylet.dart';
import 'world_data.dart';

/// School as a real part of life (plan Module 4): explained grades and
/// report cards, popularity, cliques, teachers, discipline, lessons,
/// electives, teams, exams, university admissions, scholarships, majors,
/// graduate schools and the Pathways table.

bool inSchool(Life l) => l.education == 'primary' || l.education == 'secondary';

String letter(int g) => g >= 85
    ? 'A'
    : g >= 70
    ? 'B'
    : g >= 55
    ? 'C'
    : g >= 40
    ? 'D'
    : 'F';

double _points(int g) => g >= 85
    ? 4.0
    : g >= 70
    ? 3.0
    : g >= 55
    ? 2.0
    : g >= 40
    ? 1.0
    : 0.0;

const primarySubjects = ['Reading', 'Maths', 'Science', 'Art', 'PE', 'Music'];
const secondarySubjects = [
  'English',
  'Maths',
  'Science',
  'History',
  'Languages',
];

List<Npc> teachers(Life l) =>
    l.npcs.where((n) => n.circle == 'School').toList();

int _teacherRel(Life l) {
  final t = teachers(l);
  if (t.isEmpty) return 50;
  return t.fold(0, (a, n) => a + n.bond) ~/ t.length;
}

// ---------------- Grades and report cards ----------------

/// Plan formula: 0.45·Smarts + 0.25·effort + 0.10·teacher + 0.10·Discipline
/// − 0.10·Stress + noise(±8), with a small subject bias from talents.
int gradeFor(Life l, String subject, Random rng) {
  final s = l.stats;
  final bias = switch (subject) {
    'Maths' || 'Science' => (s['smarts'] - 50) ~/ 8,
    'Art' || 'Music' || 'Drama' => (s['creativity'] - 50) ~/ 8,
    'PE' => (s['athleticism'] - 50) ~/ 8,
    'Debate' || 'Journalism' => (s['charisma'] - 50) ~/ 8,
    _ => 0,
  };
  final base =
      0.45 * s['smarts'] +
      0.25 * l.school.effort +
      0.10 * _teacherRel(l) +
      0.10 * s['discipline'] -
      0.10 * l.school.stress;
  return (base + bias + rng.nextInt(17) - 8 + 22).round().clamp(0, 100);
}

/// The yearly report card (school, college and university). Returns the
/// feed line, or null when not in education.
String? reportCard(Life l, Random rng) {
  final edu = l.education;
  final List<String> subjects;
  if (edu == 'primary') {
    subjects = primarySubjects;
  } else if (edu == 'secondary') {
    subjects = [...secondarySubjects, ...l.school.electives];
  } else if (studying(l)) {
    subjects = [l.school.major ?? 'Core course', 'Seminars', 'Exams'];
  } else {
    return null;
  }
  l.school.grades = {for (final s in subjects) s: gradeFor(l, s, rng)};
  if (edu != 'primary') {
    final pts =
        l.school.grades.values.fold(0.0, (a, g) => a + _points(g)) /
        subjects.length;
    l.school.gpa =
        (l.school.gpa * l.school.gpaYears + pts) / (l.school.gpaYears + 1);
    l.school.gpaYears++;
  }
  l.school.effort = 50;
  final comment = _comment(l, rng);
  final top = l.school.grades.entries
      .map((e) => '${e.key} ${letter(e.value)}')
      .join(' · ');
  return 'Report card: $top. Teacher\'s note: "$comment"';
}

/// Teacher comments hint at hidden stats and reveal them (plan ED-002).
String _comment(Life l, Random rng) {
  final s = l.stats;
  final options = <(String, String)>[
    if (s['discipline'] < 40)
      ('discipline', 'Bright, but easily distracted. Must try to sit still.'),
    if (s['discipline'] >= 70)
      ('discipline', 'Hard-working and reliable. A pleasure to teach.'),
    if (s['charisma'] >= 70)
      ('charisma', 'A natural leader; the class listens when they speak.'),
    if (s['creativity'] >= 70)
      ('creativity', 'Full of original ideas, some of them even on topic.'),
    if (s['impulsivity'] >= 70)
      ('impulsivity', 'Acts first and thinks later. We are working on it.'),
    if (s['karma'] >= 75) ('karma', 'Always the first to help a classmate.'),
    if (s['athleticism'] >= 75) ('athleticism', 'Unstoppable in PE.'),
    if (s['willpower'] < 35)
      ('willpower', 'Gives up a little too quickly when things get hard.'),
  ];
  if (options.isEmpty) return 'A steady year. Keep going.';
  final (stat, text) = options[rng.nextInt(options.length)];
  l.discovered.add(stat);
  return text;
}

// ---------------- Popularity, cliques, lessons and teams ----------------

class Clique {
  const Clique(
    this.id,
    this.name,
    this.rule,
    this.test,
    this.perks, {
    this.pop = 2,
  });
  final String id;
  final String name;
  final String rule;
  final bool Function(Life l) test;
  final Map<String, int> perks;
  final int pop;
}

bool _club(Life l, String c) => l.school.clubs.contains(c);

final cliques = <Clique>[
  Clique(
    'bookworms',
    'Bookworms',
    'Smarts 65+',
    (l) => l.stats['smarts'] >= 65,
    {'smarts': 1},
  ),
  Clique(
    'varsity',
    'Varsity Crew',
    'A sports team or Athleticism 60+',
    (l) =>
        l.stats['athleticism'] >= 60 ||
        const [
          'Football',
          'Basketball',
          'Swimming',
          'Athletics',
        ].any((t) => _club(l, t)),
    {'athleticism': 1},
    pop: 4,
  ),
  Clique(
    'stage',
    'Stage Kids',
    'Drama club or Creativity 60+',
    (l) => _club(l, 'Drama club') || l.stats['creativity'] >= 60,
    {'charisma': 1},
  ),
  Clique(
    'gamers',
    'Gamers\' Table',
    'Smarts 50+',
    (l) => l.stats['smarts'] >= 50,
    {'smarts': 1, 'happiness': 1},
    pop: 0,
  ),
  Clique(
    'trend',
    'Trendsetters',
    'Popularity 65+ and Looks or Charisma 60+',
    (l) =>
        l.school.popularity >= 65 &&
        (l.stats['looks'] >= 60 || l.stats['charisma'] >= 60),
    {'looks': 1},
    pop: 5,
  ),
  Clique(
    'skate',
    'Skate Lot',
    'Athleticism 45+',
    (l) => l.stats['athleticism'] >= 45,
    {'happiness': 1, 'athleticism': 1},
  ),
  Clique('activists', 'Activists', 'Karma 60+', (l) => l.stats['karma'] >= 60, {
    'karma': 1,
  }),
  Clique(
    'band',
    'Band Room',
    'In the band, choir or Music elective',
    (l) =>
        _club(l, 'Choir') ||
        _club(l, 'Band') ||
        l.school.electives.contains('Music'),
    {'creativity': 1},
  ),
  Clique(
    'art',
    'Art Corner',
    'Creativity 55+',
    (l) => l.stats['creativity'] >= 55,
    {'creativity': 1},
  ),
  Clique('outsiders', 'Outsiders', 'Anyone. Looks after its own', (l) => true, {
    'happiness': 1,
  }, pop: 0),
];

Clique? cliqueById(String? id) => cliques.where((c) => c.id == id).firstOrNull;

String? cliqueLock(Life l, Clique c) {
  if (!inSchool(l) || l.age < 11) return 'Only in secondary school';
  if (l.school.clique == c.id) return 'Your group';
  if (!c.test(l)) return 'Needs: ${c.rule}';
  return null;
}

ActionResult joinClique(Life l, Clique c) {
  final old = cliqueById(l.school.clique);
  l.school.clique = c.id;
  l.reason = 'Joined ${c.name}';
  l.flags['clique_${c.id}'] = Memory(l.age, 'joining the ${c.name}');
  l.stats.add('happiness', 2);
  return ActionResult(
    old == null
        ? 'You found your people: the ${c.name}.'
        : 'You left the ${old.name} and joined the ${c.name}. Some old friends noticed.',
    ['Happiness +2', 'Perks every year while in school'],
  );
}

const electiveOptions = <String, Map<String, int>>{
  'Music': {'creativity': 1},
  'Art': {'creativity': 1},
  'Drama': {'charisma': 1},
  'Coding': {'smarts': 1},
  'Woodwork': {'discipline': 1},
  'Home economics': {'health': 1},
  'Spanish': {'smarts': 1},
  'Debate': {'charisma': 1},
  'Journalism': {'creativity': 1},
  'Business': {'smarts': 1},
};

const lessonOptions = <String, Map<String, int>>{
  'Piano': {'creativity': 2, 'discipline': 1},
  'Football': {'athleticism': 2},
  'Swimming': {'athleticism': 2, 'health': 1},
  'Art classes': {'creativity': 2},
  'Coding club': {'smarts': 2},
  'Languages': {'smarts': 2},
  'Dance': {'athleticism': 1, 'looks': 1},
  'Martial arts': {'discipline': 2, 'athleticism': 1},
};

/// Yearly school life: popularity, clique and elective perks, lessons, team
/// seasons and stress. Returns feed lines.
List<String> schoolYear(Life l, Random rng) {
  final lines = <String>[];
  if (!inSchool(l)) return lines;
  final sc = l.school;
  l.reason = 'School life';
  final c = cliqueById(sc.clique);
  if (c != null) c.perks.forEach(l.stats.add);
  for (final e in sc.electives) {
    electiveOptions[e]?.forEach(l.stats.add);
  }
  final lesson = lessonOptions[sc.lessons];
  if (lesson != null) {
    lesson.forEach(l.stats.add);
    sc.extracurricular = min(100, sc.extracurricular + 5);
  }
  const teams = ['Football', 'Basketball', 'Swimming', 'Athletics'];
  final myTeams = sc.clubs.where(teams.contains).toList();
  for (final t in myTeams) {
    sc.seasons++;
    sc.extracurricular = min(100, sc.extracurricular + 8);
    final place = 1 + rng.nextInt(6);
    if (l.stats['athleticism'] >= 80 &&
        sc.seasons >= 2 &&
        !l.flags.containsKey('captain')) {
      l.flags['captain'] = Memory(l.age, 'being made captain of the $t team');
      lines.add('You were made captain of the $t team!');
    }
    lines.add(
      place == 1
          ? 'Your $t team won the league! You were carried around the pitch.'
          : 'Your $t team finished ${_ord(place)} this season.',
    );
  }
  for (final club in sc.clubs.where((x) => !teams.contains(x))) {
    sc.extracurricular = min(100, sc.extracurricular + 4);
    if (rng.nextInt(5) == 0) {
      lines.add('The $club had a great year. You were a big part of it.');
    }
  }
  // Popularity: clique and teams, looks and charisma, then a drift toward 40.
  final delta =
      (c?.pop ?? 0) +
      myTeams.length * 2 +
      (l.stats['looks'] - 50) ~/ 25 +
      (l.stats['charisma'] - 50) ~/ 20 -
      ((sc.popularity - 40) * 0.1).round();
  sc.popularity = (sc.popularity + delta).clamp(0, 100);
  // Stress follows workload.
  sc.stress =
      (sc.stress + (sc.clubs.length > 2 ? 6 : -4) + (l.job != null ? 8 : 0))
          .clamp(0, 100);
  return lines;
}

String _ord(int n) => switch (n) {
  1 => '1st',
  2 => '2nd',
  3 => '3rd',
  _ => '${n}th',
};

// ---------------- Teachers ----------------

/// New teachers when a school stage starts (primary at 5, secondary at 12,
/// or a new school after an expulsion).
void newTeachers(Life l, Random rng) {
  l.npcs.removeWhere((n) => n.circle == 'School');
  final c = countryNamed(l.country);
  final subjects = l.education == 'primary'
      ? ['Class teacher', 'PE']
      : ['Maths', 'English', 'Science', 'History'];
  for (final s in subjects) {
    final female = rng.nextBool();
    final pool = female ? c.female : c.male;
    final title = female ? 'Ms' : 'Mr';
    final surname = c.surnames[rng.nextInt(c.surnames.length)];
    l.npcs.add(
      Npc(
        id: 'teacher_${s.toLowerCase().replaceAll(' ', '_')}',
        role: 'Teacher · $s',
        name: '$title $surname',
        birthYear: l.year - 28 - rng.nextInt(30),
        circle: 'School',
        bond: 45 + rng.nextInt(15),
      )..lastContactAge = l.age,
    );
    // Keep the first name pool referenced for variety in later modules.
    if (pool.isEmpty) break;
  }
}

/// School stage changes: teachers arrive and leave.
void schoolStage(Life l, Random rng) {
  if (l.age == 5 || l.age == 12) newTeachers(l, rng);
  if (l.age == 18) {
    l.npcs.removeWhere((n) => n.circle == 'School');
    l.school.clique = null;
    l.school.clubs.clear();
    l.school.electives.clear();
    l.school.lessons = null;
  }
}

final schoolInteractions = <Interaction>[
  Interaction(
    id: 'ask_help',
    label: 'Ask for help with work',
    group: 'School',
    positive: true,
    keywords: ['help', 'homework', 'teacher', 'explain'],
    only: (n) => n.circle == 'School',
    run: (life, n, k, rng) {
      final gain = (3 * k).round();
      life.stats.add('smarts', gain);
      life.school.effort = min(100, life.school.effort + 20);
      return bondResult(
        life,
        n,
        '${n.name} went through it again, slowly, until it made sense.',
        respect: (2 * k).round(),
        familiarity: 2,
        extra: ['Smarts +$gain'],
      );
    },
  ),
  Interaction(
    id: 'ask_extension',
    label: 'Ask for an extension',
    group: 'School',
    keywords: ['extension', 'deadline', 'late', 'homework'],
    only: (n) => n.circle == 'School',
    run: (life, n, k, rng) {
      if (rng.nextInt(100) < n.trust) {
        life.school.stress = max(0, life.school.stress - 10);
        return bondResult(
          life,
          n,
          '${n.name} sighed and gave you until Monday.',
          extra: ['Stress down'],
        );
      }
      return bondResult(
        life,
        n,
        '${n.name} said no. Deadlines are deadlines.',
        respect: -1,
        extra: ['Why: Trust is ${n.trust < 50 ? 'low' : 'not high enough'}'],
      );
    },
  ),
  Interaction(
    id: 'class_clown',
    label: 'Make the class laugh',
    group: 'School',
    keywords: ['joke', 'clown', 'funny', 'laugh'],
    only: (n) => n.circle == 'School',
    run: (life, n, k, rng) {
      life.school.popularity = min(100, life.school.popularity + 4);
      return bondResult(
        life,
        n,
        'The whole class cracked up. ${n.name} did not.',
        respect: -3,
        extra: ['Popularity +4'],
      );
    },
  ),
  Interaction(
    id: 'ask_recommendation',
    label: 'Ask for a recommendation letter',
    group: 'School',
    minAge: 16,
    maxAge: 18,
    keywords: ['recommendation', 'reference', 'letter', 'university'],
    only: (n) => n.circle == 'School',
    check: (life, n) => life.flags.containsKey('recommendation')
        ? 'You already have one'
        : null,
    run: (life, n, k, rng) {
      if (n.bond >= 70) {
        life.flags['recommendation'] = Memory(
          life.age,
          'a recommendation letter from ${n.name}',
        );
        return bondResult(
          life,
          n,
          '${n.name} smiled. "I was hoping you would ask." The letter was glowing.',
          extra: ['University admission +4'],
        );
      }
      return bondResult(
        life,
        n,
        '${n.name} said they did not know you well enough to write one.',
        extra: [
          'Why: Bond ${n.bond}% (needs 70%)',
          'Tip: ask for help with work during the year',
        ],
      );
    },
  ),
];

// ---------------- Discipline ----------------

/// Detention → suspension → expulsion, with parents' reactions.
String punish(Life l, String what) {
  final sc = l.school;
  sc.detentions++;
  l.reason = what;
  for (final t in teachers(l)) {
    t.remember(
      NpcMemory(
        age: l.age,
        text: what,
        valence: -1,
        intensity: 2,
        tags: ['trust'],
      ),
    );
  }
  if (sc.detentions >= 3) {
    sc.detentions = 0;
    sc.suspensions++;
    l.npc('mother')?.addFacets(trust: -6);
    l.npc('father')?.addFacets(trust: -6);
    if (sc.suspensions >= 2) {
      l.flags['expelled'] = Memory(l.age, 'being expelled from school');
      sc.suspensions = 0;
      sc.clique = null;
      sc.popularity = 35;
      if (l.age < 16) {
        newTeachers(l, Random(l.seed + l.age));
        return 'You were expelled. Your parents moved you to a new school, where nobody knows you. Yet.';
      }
      l.education = 'dropout';
      l.npcs.removeWhere((n) => n.circle == 'School');
      return 'You were expelled. At ${l.age}, that was the end of school for you.';
    }
    l.flags['suspended'] = Memory(l.age, 'being suspended');
    return 'That was one detention too many: you were suspended for a week. Your parents were furious.';
  }
  return 'You got a detention (${sc.detentions} of 3 before a suspension).';
}

// ---------------- University admissions ----------------

const tiers = <String, ({int bar, int fees})>{
  'Elite': (bar: 85, fees: 55000),
  'Strong': (bar: 70, fees: 25000),
  'Open': (bar: 50, fees: 9000),
};

const majors = [
  'Biology',
  'Nursing',
  'Psychology',
  'Politics',
  'Economics',
  'Computer Science',
  'Engineering',
  'Education',
  'Fine Arts',
  'Journalism',
];

/// Plan formula: 0.40·GPA + 0.25·Smarts + 0.15·test + 0.10·extracurricular
/// + 0.10·essay (Charisma, Creativity), +4 for a recommendation letter.
({int score, List<String> weakest}) admissionScore(Life l) {
  final f = <String, double>{
    'GPA': l.school.gpa / 4 * 100,
    'Smarts': l.stats['smarts'].toDouble(),
    'Test score': (l.school.testScore ?? 50).toDouble(),
    'Activities': l.school.extracurricular.toDouble(),
    'Essay': (l.stats['charisma'] + l.stats['creativity']) / 2,
  };
  final score =
      0.40 * f['GPA']! +
      0.25 * f['Smarts']! +
      0.15 * f['Test score']! +
      0.10 * f['Activities']! +
      0.10 * f['Essay']! +
      (l.flags.containsKey('recommendation') ? 4 : 0);
  final weakest =
      (f.entries.toList()..sort((a, b) => a.value.compareTo(b.value)))
          .take(2)
          .map((e) => e.key)
          .toList();
  return (score: score.round(), weakest: weakest);
}

/// Best scholarship the player qualifies for: (name, share of fees).
(String, double)? scholarshipFor(Life l, int score) {
  if (l.school.gpa >= 3.7 && score >= 80) return ('Merit scholarship', 0.75);
  if (l.flags.containsKey('captain') || l.stats['athleticism'] >= 85) {
    return ('Athletic scholarship', 0.5);
  }
  if (l.stats['creativity'] >= 85) return ('Arts scholarship', 0.5);
  if (l.money < 2000 && l.netWorth < 5000) return ('Need-based grant', 0.5);
  if (l.stats['karma'] >= 75) return ('Community award', 0.15);
  return null;
}

Storylet? applyUniScene(Life l) {
  final a = admissionScore(l);
  final transfer = l.education == 'associate degree' && l.school.gpa >= 3.0;
  final choices = <Choice>[
    for (final t in tiers.entries)
      Choice(
        label: '${t.key} university (\$${t.value.fees ~/ 1000}k a year)',
        outcome: '',
        risk: a.score >= t.value.bar + 5
            ? 'Likely'
            : a.score >= t.value.bar
            ? 'Possible'
            : 'Unlikely',
        run: (life, rng) {
          final s = admissionScore(life);
          final odds = (50 + (s.score - t.value.bar) * 6).clamp(3, 97);
          if (rng.nextInt(100) < odds) {
            final sch = scholarshipFor(life, s.score);
            life.school.tier = t.key;
            life.school.tuition = (t.value.fees * (1 - (sch?.$2 ?? 0))).round();
            life.school.scholarship = sch?.$1;
            life.education = 'university';
            life.eduSince = life.age - (transfer ? 2 : 0);
            life.flags['went_uni'] = Memory(
              life.age,
              'getting into a ${t.key.toLowerCase()} university',
            );
            life.sceneQueue.add('choose_major');
            return 'The email arrived at 6 a.m.: you got in! ${sch == null ? 'Fees are \$${life.school.tuition} a year (student loan if short).' : 'You also won a ${sch.$1}: fees drop to \$${life.school.tuition} a year.'}${transfer ? ' Your college credits count, so you start in year 3.' : ''}';
          }
          life.stats.add('happiness', -4);
          return 'A polite rejection. "Many strong applicants this year." Your admission score was ${s.score} (they look for about ${t.value.bar}). Weakest: ${s.weakest.join(' and ')}.';
        },
      ),
    Choice(
      label: 'Not this year',
      outcome:
          'You closed the laptop. University will still be there next year.',
    ),
  ];
  return Storylet(
    id: 'scene:apply_uni',
    text:
        'Application season. Your admission score is about ${a.score} (Elite universities look for 85, Strong 70, Open 50). ${a.weakest.isNotEmpty ? 'Your weakest areas: ${a.weakest.join(' and ')}.' : ''}${transfer ? ' With your associate degree and GPA, you can transfer straight into year 3.' : ''} Where do you apply?',
    choices: choices,
    category: 'school',
    scene: true,
  );
}

Storylet chooseMajorScene() => Storylet(
  id: 'scene:choose_major',
  text: 'Welcome week. Between free pizza and society stalls, you have to sign up for a major. It shapes which graduate schools and careers open up later (see Pathways on the Path tab).',
  category: 'school',
  scene: true,
  choices: [
    for (final m in majors)
      Choice(
        label: m,
        outcome:
            'You signed up for $m. The reading list arrived the same afternoon.',
        run: (life, rng) {
          life.school.major = m;
          life.flags['major_${m.toLowerCase().replaceAll(' ', '_')}'] = Memory(
            life.age,
            'studying $m',
          );
          return null;
        },
      ),
  ],
);

// ---------------- Graduate schools (plan table) ----------------

typedef GradSchool = ({
  String name,
  double gpa,
  int smarts,
  int years,
  List<String> majors,
  String degree,
});

const gradSchools = <GradSchool>[
  (
    name: 'Medical school',
    gpa: 3.6,
    smarts: 80,
    years: 4,
    majors: ['Biology', 'Nursing', 'Psychology'],
    degree: 'Medicine',
  ),
  (
    name: 'Law school',
    gpa: 3.4,
    smarts: 78,
    years: 3,
    majors: [],
    degree: 'Law',
  ),
  (
    name: 'Business school (MBA)',
    gpa: 3.0,
    smarts: 65,
    years: 2,
    majors: [],
    degree: 'MBA',
  ),
  (
    name: 'Nursing (advanced)',
    gpa: 3.2,
    smarts: 65,
    years: 2,
    majors: ['Nursing'],
    degree: 'Advanced Nursing',
  ),
  (
    name: 'Veterinary school',
    gpa: 3.5,
    smarts: 75,
    years: 4,
    majors: ['Biology'],
    degree: 'Veterinary Medicine',
  ),
  (
    name: 'Engineering / CS master\'s',
    gpa: 3.0,
    smarts: 70,
    years: 2,
    majors: ['Computer Science', 'Engineering'],
    degree: 'Engineering Masters',
  ),
  (name: 'PhD', gpa: 3.5, smarts: 82, years: 5, majors: [], degree: 'PhD'),
  (
    name: 'Film school / Conservatory',
    gpa: 2.5,
    smarts: 0,
    years: 2,
    majors: ['Fine Arts', 'Journalism'],
    degree: 'Fine Arts Masters',
  ),
  (
    name: 'Teaching certificate',
    gpa: 2.5,
    smarts: 0,
    years: 1,
    majors: [],
    degree: 'Teaching',
  ),
];

String? gradLock(Life l, GradSchool g) {
  if (l.education != 'graduate') return 'Needs a university degree';
  if (l.school.degrees.contains(g.degree)) return 'You already have this';
  if (g.majors.isNotEmpty && !g.majors.contains(l.school.major)) {
    return 'Needs a ${g.majors.join(' / ')} major';
  }
  if (l.school.gpa < g.gpa) {
    return 'Needs GPA ${g.gpa} (yours ${l.school.gpa.toStringAsFixed(1)})';
  }
  if (l.stats['smarts'] < g.smarts) return 'Needs Smarts ${g.smarts}+';
  return null;
}

Storylet applyGradScene() => Storylet(
  id: 'scene:apply_grad',
  text: 'You are thinking about more study. Each programme lists exactly what it needs, so there is no guessing.',
  category: 'school',
  scene: true,
  choices: [
    for (final g in gradSchools)
      Choice(
        label: '${g.name} · ${g.years} yr${g.years > 1 ? 's' : ''}',
        outcome: '',
        lock: (l) => gradLock(l, g),
        run: (life, rng) {
          life.education = 'grad school';
          life.eduSince = life.age;
          life.school.gradProgramme = g.degree;
          life.school.gradYears = g.years;
          life.school.tuition = 15000;
          return 'You were accepted to ${g.name.toLowerCase()}. ${g.years} more years of study, and a new kind of tired.';
        },
      ),
    Choice(
      label: 'Not now',
      outcome: 'You decided you had studied enough for now.',
    ),
  ],
);

/// Majors → graduate schools → careers (plan "Pathways" view).
const pathways = <(String, String, String)>[
  ('Biology', 'Medical, Veterinary, PhD', 'Doctor, Vet, Researcher'),
  ('Nursing', 'Nursing (advanced), Medical', 'Nurse, Nurse manager'),
  ('Psychology', 'Medical, PhD', 'Psychologist, Therapist'),
  ('Politics', 'Law, PhD', 'Lawyer, Politician'),
  ('Economics', 'MBA, Law', 'Analyst, Banker, CEO track'),
  (
    'Computer Science',
    'Engineering/CS master\'s, MBA',
    'Developer, Data scientist',
  ),
  ('Engineering', 'Engineering master\'s, MBA', 'Engineer, Pilot (advantage)'),
  ('Education', 'Teaching certificate', 'Teacher, Principal'),
  ('Fine Arts', 'Film school / Conservatory', 'Actor, Musician, Artist'),
  ('Journalism', 'Film school, MBA', 'Journalist, Influencer'),
  ('Any major', 'Law, MBA, PhD, Teaching', 'Most office careers'),
];

// ---------------- Exams, lessons and tryouts (scenes) ----------------

int _gradeAvg(Life l) => l.school.grades.isEmpty
    ? l.stats['smarts']
    : l.school.grades.values.fold(0, (a, g) => a + g) ~/ l.school.grades.length;

Storylet examScene(Life l) => Storylet(
  id: 'scene:exams',
  text: l.age >= 18
      ? 'Final exams start in two weeks. Every past paper you own is spread across the bedroom floor, and the group chat is pure panic.'
      : 'Big national exams start in two weeks. Teachers keep saying they "matter for your future", which is not helping anyone sleep.',
  category: 'school',
  scene: true,
  choices: [
    Choice(
      label: 'Revise every evening',
      outcome: '',
      risk: 'Best results',
      run: (life, rng) {
        final score = (_gradeAvg(life) + 8 + rng.nextInt(10)).clamp(0, 100);
        life.school.testScore = score;
        life.stats.add('discipline', 2);
        life.school.stress = min(100, life.school.stress + 10);
        return 'You turned your bedroom into a library. It paid off: you scored $score/100.';
      },
    ),
    Choice(
      label: 'Join a study group',
      outcome: '',
      risk: 'Good, and social',
      run: (life, rng) {
        final score =
            (_gradeAvg(life) +
                    3 +
                    rng.nextInt(10) +
                    (life.stats['charisma'] - 50) ~/ 10)
                .clamp(0, 100);
        life.school.testScore = score;
        life.stats.add('happiness', 2);
        return 'Half revision, half snacks and gossip. You scored $score/100 and made two new friends.';
      },
    ),
    Choice(
      label: 'Wing it',
      outcome: '',
      risk: 'Risky',
      run: (life, rng) {
        final score = (_gradeAvg(life) - 8 + rng.nextInt(16)).clamp(0, 100);
        life.school.testScore = score;
        return 'You trusted your instincts. Your instincts scored $score/100.';
      },
    ),
  ],
);

Storylet lessonsScene() => Storylet(
  id: 'scene:lessons',
  text: 'Your parents say you can do one after-school activity this year, and they will pay for it. The leaflets are spread across the kitchen table.',
  category: 'school',
  scene: true,
  choices: [
    for (final e in lessonOptions.entries)
      Choice(
        label: e.key,
        outcome:
            'You started ${e.key.toLowerCase()} lessons. Tuesdays and Thursdays are spoken for now.',
        run: (life, rng) {
          life.school.lessons = e.key;
          return null;
        },
      ),
    Choice(
      label: 'Stop lessons',
      outcome: 'You decided you needed your evenings back.',
      run: (life, rng) {
        life.school.lessons = null;
        return null;
      },
    ),
  ],
);

const _tryoutStat = {
  'Football': 'athleticism',
  'Basketball': 'athleticism',
  'Swimming': 'athleticism',
  'Athletics': 'athleticism',
  'Choir': 'creativity',
  'Band': 'creativity',
  'Debate': 'charisma',
  'Drama club': 'charisma',
  'Science club': 'smarts',
};

Storylet tryoutsScene(Life l) => Storylet(
  id: 'scene:tryouts',
  text: 'Tryouts week. Sign-up sheets cover the noticeboard outside the gym, and everyone is pretending not to be nervous.',
  category: 'school',
  scene: true,
  choices: [
    for (final e in _tryoutStat.entries)
      Choice(
        label: e.key,
        outcome: '',
        risk: l.stats[e.value] >= 60 ? 'Good chance' : 'Hard',
        lock: (life) => life.school.clubs.contains(e.key) ? 'Already in' : null,
        run: (life, rng) {
          final roll = life.stats[e.value] + rng.nextInt(30);
          if (roll >= 65) {
            life.school.clubs.add(e.key);
            life.school.popularity = min(100, life.school.popularity + 3);
            return 'You made it into ${e.key == 'Choir' || e.key == 'Band' || e.key.endsWith('club') ? 'the ${e.key.toLowerCase()}' : 'the ${e.key.toLowerCase()} team'}! Practice starts Monday.';
          }
          life.stats.add('happiness', -2);
          return 'You gave it everything, but your name was not on the list. Why: ${e.value[0].toUpperCase()}${e.value.substring(1)} ${life.stats[e.value]}. Try again next year.';
        },
      ),
  ],
);

Storylet cheatScene() => Storylet(
  id: 'scene:cheat',
  text: 'There is a test tomorrow and you are not ready. Three bad ideas come to mind.',
  category: 'school',
  scene: true,
  choices: [
    for (final (label, base, cost) in const [
      ('Copy a neighbour', 40, 0),
      ('Write crib notes', 30, 0),
      ('Buy the answers (\$50)', 20, 50),
    ])
      Choice(
        label: label,
        outcome: '',
        risk: 'Detection about ${cheatOdds(base, null)}%',
        needsMoney: cost,
        run: (life, rng) {
          life.money -= cost;
          final odds = cheatOdds(base, life);
          life.stats.add('karma', -2);
          if (rng.nextInt(100) < odds) {
            final p = punish(life, 'being caught cheating');
            return 'Caught. The teacher held your paper up for the whole class to see. $p Why: detection was $odds% (teacher vigilance minus your cunning).';
          }
          life.school.effort = 100;
          return 'Nobody noticed. Your grades will look better than you deserve, and you know it.';
        },
      ),
    Choice(
      label: 'Actually study',
      outcome: 'You sighed, opened the book and studied until midnight. Honest work.',
      effects: Effects(stats: {'discipline': 2, 'karma': 1}),
    ),
  ],
);

/// Teacher vigilance minus cunning (Smarts and Charisma), clamped.
int cheatOdds(int base, Life? l) {
  if (l == null) return base;
  final cunning = (l.stats['smarts'] + l.stats['charisma']) ~/ 2;
  return (base + (_teacherRel(l) - 50) ~/ 4 - (cunning - 50) ~/ 3).clamp(5, 90);
}

// ---------------- Activities added by this module ----------------

final schoolActions = <GameAction>[
  GameAction(
    id: 'cheat',
    label: 'Cheat on a test',
    category: 'School',
    keywords: ['cheat', 'copy', 'crib', 'test', 'exam'],
    minAge: 9,
    extraCheck: (l) =>
        inSchool(l) || studying(l) ? null : 'Only while in school',
    run: (l, rng) {
      l.sceneQueue.add('cheat');
      return ActionResult('You look around the classroom...');
    },
  ),
  GameAction(
    id: 'lessons',
    label: 'After-school lessons',
    category: 'School',
    keywords: [
      'lessons',
      'piano',
      'swimming',
      'dance',
      'karate',
      'after school',
    ],
    minAge: 6,
    maxAge: 17,
    extraCheck: (l) => inSchool(l) ? null : 'Only while in school',
    run: (l, rng) {
      l.sceneQueue.add('lessons');
      return ActionResult('You pick up the leaflets.');
    },
  ),
  GameAction(
    id: 'tryouts',
    label: 'Try out for a team or club',
    category: 'School',
    keywords: [
      'tryouts',
      'team',
      'sport',
      'club',
      'football',
      'choir',
      'debate',
    ],
    minAge: 8,
    maxAge: 17,
    extraCheck: (l) => inSchool(l) ? null : 'Only while in school',
    run: (l, rng) {
      l.sceneQueue.add('tryouts');
      return ActionResult('You head to the noticeboard.');
    },
  ),
  GameAction(
    id: 'apply_uni',
    label: 'Apply to university',
    category: 'School',
    keywords: ['university', 'college', 'apply', 'admission', 'degree'],
    minAge: 17,
    extraCheck: (l) {
      if (studying(l)) return 'Already studying';
      if (l.education == 'graduate') return 'You already have a degree';
      if (!finishedSchool(l) && !(l.education == 'secondary' && l.age >= 17)) {
        return 'Finish secondary school first';
      }
      return null;
    },
    run: (l, rng) {
      l.sceneQueue.add('apply_uni');
      return ActionResult('You open the application portal.');
    },
  ),
  GameAction(
    id: 'apply_grad',
    label: 'Apply to graduate school',
    category: 'School',
    keywords: ['graduate', 'masters', 'phd', 'medical', 'law school', 'mba'],
    minAge: 20,
    extraCheck: (l) =>
        l.education == 'graduate' ? null : 'Needs a university degree',
    run: (l, rng) {
      l.sceneQueue.add('apply_grad');
      return ActionResult('You compare programmes.');
    },
  ),
  GameAction(
    id: 'apprenticeship',
    label: 'Start an apprenticeship',
    category: 'School',
    keywords: ['apprentice', 'apprenticeship', 'trade', 'paid training'],
    minAge: 16,
    maxAge: 30,
    extraCheck: (l) {
      if (studying(l)) return 'Already training';
      if (l.education == 'trade certificate') return 'You already have a trade';
      if (inSchool(l) && l.age < 16) return 'From 16';
      return null;
    },
    run: (l, rng) {
      l.education = 'apprenticeship';
      l.eduSince = l.age;
      l.job = 'Apprentice';
      l.salary = 12000;
      l.careerId = null;
      return ActionResult(
        'You signed on as an apprentice: three years of learning on the job, and you get paid.',
        ['Salary \$12000/year', 'Year 1 of 3'],
      );
    },
  ),
  GameAction(
    id: 'gap_year',
    label: 'Take a gap year',
    category: 'Travel',
    keywords: ['gap year', 'travel', 'backpack', 'volunteer abroad'],
    minAge: 18,
    maxAge: 30,
    cost: 1500,
    extraCheck: (l) => studying(l)
        ? 'Not while studying'
        : l.job != null
        ? 'You have a job'
        : l.flags.containsKey('gap_year')
        ? 'You already took one'
        : null,
    run: (l, rng) {
      l.money -= 1500;
      l.flags['gap_year'] = Memory(l.age, 'a gap year backpacking');
      l.flags['wanderer'] = Memory(l.age, 'seeing the world');
      final r = statChange(
        l,
        'You spent a year with a backpack: night buses, odd jobs, sunsets and one memorable bout of food poisoning.',
        {'happiness': 8, 'charisma': 2, 'creativity': 2},
      );
      return ActionResult(r.text, ['Money −\$1,500', ...r.notes]);
    },
  ),
];
