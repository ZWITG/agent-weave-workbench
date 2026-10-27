import 'dart:math';

import 'careers.dart';
import 'economy.dart';
import 'minigame_rules.dart';
import 'models.dart';
import 'more_actions.dart';

class ActionResult {
  ActionResult(this.text, [this.notes = const []]);
  final String text;
  final List<String> notes;
}

/// Something the player can choose to do, found through the action search.
/// A locked action stays visible and says why ("no silent failure").
class GameAction {
  const GameAction({
    required this.id,
    required this.label,
    required this.category,
    required this.keywords,
    required this.run,
    this.minAge = 0,
    this.maxAge = 120,
    this.cost = 0,
    this.extraCheck,
    this.miniGame,
    this.scored,
    this.priceNote,
    this.repeatable = false,
    this.screen,
  });

  final String id;
  final String label;
  final String category;
  final List<String> keywords;
  final int minAge;
  final int maxAge;
  final int cost;
  final ActionResult Function(Life life, Random rng) run;

  /// Returns a reason when the action is locked for another reason.
  final String? Function(Life life)? extraCheck;

  /// Optional mini-game id (reps, quiz, timing, cards, reaction, memory).
  final String? miniGame;

  /// Outcome when played as a mini-game; [score] is 0..1.
  final ActionResult Function(Life life, Random rng, double score)? scored;

  /// Shown instead of "Free" when the price is paid inside [run]
  /// (for example course fees that may go on a loan).
  final String? priceNote;

  /// Can be used again in the same year (e.g. re-reading the newspaper).
  final bool repeatable;

  /// A screen to open after running instead of a result pop-up.
  final String? screen;

  /// Null when the action can be used now, otherwise the reason it can't.
  String? lockReason(Life life) {
    if (life.age < minAge) return 'Unlocks at $minAge';
    if (life.age > maxAge) return 'Only up to age $maxAge';
    if (!repeatable && life.usedActions.contains(id)) return 'Done this year';
    if (cost > 0 && life.money < cost) return 'Needs \$$cost';
    return extraCheck?.call(life);
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return label.toLowerCase().contains(q) ||
        category.toLowerCase().contains(q) ||
        keywords.any((k) => k.contains(q) || q.contains(k));
  }
}

String _signed(int v) => v > 0 ? '+$v' : '−${v.abs()}';

ActionResult statChange(Life life, String text, Map<String, int> deltas) {
  final notes = <String>[];
  deltas.forEach((k, v) {
    life.stats.add(k, v);
    if (Stats.visible.contains(k) && v != 0) {
      notes.add('${k[0].toUpperCase()}${k.substring(1)} ${_signed(v)}');
    }
  });
  return ActionResult(text, notes);
}

String? _inSchool(Life life) =>
    life.education == 'primary' ||
        life.education == 'secondary' ||
        studying(life)
    ? null
    : 'Only while in school';

final _baseActions = <GameAction>[
  GameAction(
    id: 'study',
    miniGame: 'quiz',
    scored: studyScored,
    label: 'Study harder',
    category: 'School',
    keywords: ['study', 'homework', 'school', 'grades', 'learn'],
    minAge: 6,
    extraCheck: _inSchool,
    run: (life, rng) => statChange(
      life,
      'You buried yourself in books for a while.',
      {'smarts': 2 + rng.nextInt(4), 'happiness': -1, 'discipline': 2},
    ),
  ),
  GameAction(
    id: 'read',
    label: 'Read a book',
    category: 'Wellbeing',
    keywords: ['read', 'book', 'library'],
    minAge: 4,
    run: (life, rng) => statChange(
      life,
      'You read a book you could not put down.',
      {'smarts': 1 + rng.nextInt(3), 'happiness': 1},
    ),
  ),
  GameAction(
    id: 'gym',
    miniGame: 'reps',
    scored: gymScored,
    label: 'Work out',
    category: 'Wellbeing',
    keywords: ['gym', 'exercise', 'run', 'sport', 'fitness', 'workout'],
    minAge: 12,
    run: (life, rng) => statChange(
      life,
      'You worked out until everything ached.',
      {'health': 2 + rng.nextInt(3), 'looks': rng.nextInt(2), 'athleticism': 2},
    ),
  ),
  GameAction(
    id: 'meditate',
    label: 'Meditate',
    category: 'Wellbeing',
    keywords: ['meditate', 'calm', 'relax', 'stress', 'mindful'],
    minAge: 10,
    run: (life, rng) => statChange(
      life,
      'You sat in silence and felt a little lighter.',
      {'happiness': 2 + rng.nextInt(3), 'willpower': 1},
    ),
  ),
  GameAction(
    id: 'doctor',
    label: 'See a doctor',
    category: 'Health',
    keywords: ['doctor', 'sick', 'health', 'hospital', 'checkup'],
    run: (life, rng) {
      if (life.age >= 18) life.money -= 80;
      return statChange(
        life,
        life.age >= 18
            ? 'A check-up cost you \$80. The doctor says to sleep more.'
            : 'Your parents took you for a check-up.',
        {'health': 3 + rng.nextInt(4)},
      );
    },
  ),
  GameAction(
    id: 'part_time',
    label: 'Get a part-time job',
    category: 'Work',
    keywords: ['job', 'work', 'part-time', 'money', 'earn'],
    minAge: 14,
    maxAge: 17,
    extraCheck: (life) => life.job != null ? 'You already have a job' : null,
    run: (life, rng) {
      const jobs = [
        'café server',
        'newspaper delivery',
        'shop assistant',
        'dog walker',
      ];
      final job = jobs[rng.nextInt(jobs.length)];
      life.job = 'Part-time $job';
      life.salary = 1500 + rng.nextInt(1500);
      return ActionResult('You got a job as a $job.', [
        'Income +\$${life.salary}/year',
      ]);
    },
  ),
  GameAction(
    id: 'apply_job',
    label: 'Apply for a full-time job',
    category: 'Work',
    keywords: ['job', 'work', 'career', 'apply', 'employment', 'hire'],
    minAge: 18,
    extraCheck: (life) => studying(life) ? 'Finish your course first' : null,
    run: (life, rng) {
      final open = careers.where((c) => c.lockReason(life) == null).toList();
      if (open.isEmpty) {
        return ActionResult('There were no openings you qualify for.', [
          'See the job board on the Path tab',
        ]);
      }
      return applyForCareer(life, open[rng.nextInt(open.length)], rng);
    },
  ),
  GameAction(
    id: 'quit_job',
    label: 'Quit your job',
    category: 'Work',
    keywords: ['quit', 'resign', 'job', 'leave'],
    minAge: 14,
    extraCheck: (life) => life.job == null ? 'You don\'t have a job' : null,
    run: (life, rng) {
      final old = life.job;
      life.job = null;
      life.salary = 0;
      life.careerId = null;
      life.careerRank = 0;
      return statChange(life, 'You quit your job as $old.', {'happiness': 3});
    },
  ),
  GameAction(
    id: 'party',
    label: 'Throw a party',
    category: 'Social',
    keywords: ['party', 'friends', 'celebrate', 'guests'],
    minAge: 18,
    cost: 200,
    run: (life, rng) {
      life.money -= 200;
      final great = rng.nextInt(100) < 40 + life.stats['charisma'] ~/ 2;
      return statChange(
        life,
        great
            ? 'Your party was the talk of {city} for a week.'
            : 'Three people came. One left early.',
        {'happiness': great ? 6 : -2, 'charisma': great ? 2 : 0},
      );
    },
  ),
  GameAction(
    id: 'shoplift',
    miniGame: 'timing',
    scored: shopliftScored,
    label: 'Shoplift',
    category: 'Crime',
    keywords: ['steal', 'shoplift', 'crime', 'theft'],
    minAge: 12,
    run: (life, rng) {
      final caught = rng.nextInt(100) < 30;
      if (caught) {
        life.flags['caught_shoplifting'] = Memory(
          life.age,
          'caught shoplifting',
        );
        return statChange(
          life,
          'Security caught you at the door. Your parents had to come and get you.',
          {'happiness': -6, 'karma': -4},
        );
      }
      life.money += 20 + rng.nextInt(60);
      return statChange(
        life,
        'You walked out with a pocketful of things you didn\'t need.',
        {'karma': -3, 'happiness': 1},
      );
    },
  ),
  GameAction(
    id: 'volunteer',
    label: 'Volunteer',
    category: 'Social',
    keywords: ['volunteer', 'charity', 'help', 'kind'],
    minAge: 13,
    run: (life, rng) => statChange(
      life,
      'You volunteered at a food bank in {city}.',
      {'happiness': 3, 'karma': 4},
    ),
  ),
  GameAction(
    id: 'buy_car',
    label: 'Buy a used car',
    category: 'Assets',
    keywords: ['car', 'buy', 'drive', 'vehicle'],
    minAge: 18,
    cost: 4000,
    extraCheck: (life) => life.has('car') ? 'You already own a car' : null,
    run: (life, rng) {
      life.money -= 4000;
      life.flags['owns_car'] = Memory(life.age, 'your first car');
      addCar(life);
      return ActionResult('You bought a dented but lovable used car.', [
        'Money −\$4,000',
        'Tip: insurance and fuel cost \$1,200 a year',
      ]);
    },
  ),
];

/// Every action in the game: the starter set plus the expanded activities.
final allActions = <GameAction>[
  ..._baseActions,
  ...moreActions,
  ...educationActions,
  ...careerActions,
];
