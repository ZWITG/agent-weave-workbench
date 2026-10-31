import 'dart:math';

import 'odds.dart';

import 'careers.dart';
import 'dynasty.dart';
import 'family.dart';
import 'finance.dart';
import 'health.dart';
import 'homes.dart';
import 'heists.dart';
import 'crime_jobs.dart';
import 'gangs.dart';
import 'prison_life.dart';
import 'kin.dart';
import 'possessions.dart';
import 'property.dart';
import 'shopping.dart' show shopAction;
import 'recap.dart';
import 'community.dart';
import 'identity.dart';
import 'pets.dart';
import 'social.dart';
import 'celebrity.dart';
import 'jobs.dart';
import 'justice.dart';
import 'love.dart';
import 'lifespan.dart';
import 'school.dart';
import 'minigame_rules.dart';
import 'models.dart';
import 'world_data.dart';
import 'more_actions.dart';

class ActionResult {
  ActionResult(String text, [List<String> notes = const []])
    : text = hideOdds(text),
      notes = [
        for (final n in notes)
          if (hideOdds(n) case final h when h.isNotEmpty) h,
      ];
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
    this.hint,
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

  /// Live detail shown under the label instead of the price (for example
  /// the risk of a crime right now).
  final String? Function(Life life)? hint;

  /// The hint as the player sees it: never the odds.
  String? hintFor(Life l) => hideOddsOrNull(hint?.call(l));

  /// Null when the action can be used now, otherwise the reason it can't.
  String? lockReason(Life life) {
    if (life.prison != null &&
        category != 'Prison' &&
        !prisonAllowed.contains(id)) {
      return 'Not possible in prison';
    }
    if ((life.prison?.solitary ?? 0) > 0 && !solitaryAllowed.contains(id)) {
      return 'Not possible in solitary';
    }
    if (life.age < minAge) return 'Unlocks at $minAge';
    if (life.age > maxAge) return 'Only up to age $maxAge';
    if (!repeatable && life.usedActions.contains(id)) {
      if (!redoable.contains(id)) return 'Done this year';
      if (timesThisYear(life, id) >= maxRedo) {
        return 'Done $maxRedo times this year';
      }
    }
    if (!repeatable && !life.classic && life.energy <= 0) {
      return 'No energy left this year';
    }
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

/// Everyday activities you can do again in the same year (up to [maxRedo]
/// times). Each repeat costs energy and helps less than the last.
const redoable = {
  'read',
  'gym',
  'meditate',
  'walk',
  'yoga',
  'paint',
  'instrument',
  'write_story',
  'write_song',
  'video_games',
  'go_out',
  'nightlife',
  'family_dinner',
  'study',
  'volunteer',
  'party',
  'cell_exercise',
  'prison_gym',
};
const maxRedo = 3;

/// How many times [id] has been done this year.
int timesThisYear(Life life, String id) => !life.usedActions.contains(id)
    ? 0
    : 1 + life.usedActions.where((a) => a.startsWith('again:$id:')).length;

/// How much of a stat gain lands: repeats in one year help less, and the
/// higher a stat already is, the harder it is to push further.
double gainFactor(int timesBefore, int current) {
  final repeat = switch (timesBefore) {
    0 => 1.0,
    1 => 0.5,
    _ => 0.25,
  };
  final ceiling = current >= 85
      ? 0.25
      : current >= 70
      ? 0.5
      : current >= 55
      ? 0.75
      : 1.0;
  return repeat * ceiling;
}

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
    run: (life, rng) {
      life.school.effort = 100;
      return statChange(life, 'You buried yourself in books for a while.', {
        'smarts': 2 + rng.nextInt(4),
        'happiness': -1,
        'discipline': 2,
      });
    },
  ),
  GameAction(
    id: 'read',
    label: 'Read a book',
    category: 'Wellbeing',
    keywords: ['read', 'book', 'library'],
    minAge: 4,
    run: (life, rng) {
      final card = life.flags.containsKey('library_card');
      return statChange(
        life,
        card
            ? 'You borrowed three books from the library and finished them all.'
            : 'You read a book you could not put down.',
        {'smarts': 1 + rng.nextInt(3) + (card ? 1 : 0), 'happiness': 1},
      );
    },
  ),
  GameAction(
    id: 'gym',
    miniGame: 'reps',
    scored: gymScored,
    label: 'Work out',
    category: 'Wellbeing',
    keywords: ['gym', 'exercise', 'run', 'sport', 'fitness', 'workout'],
    minAge: 12,
    run: (life, rng) {
      life.fitness = min(100, life.fitness + 8);
      return statChange(life, 'You worked out until everything ached.', {
        'health': 2 + rng.nextInt(3),
        'looks': rng.nextInt(2),
        'athleticism': 2,
      });
    },
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
    label: 'Get a check-up',
    category: 'Health',
    keywords: ['doctor', 'sick', 'health', 'hospital', 'checkup', 'check-up'],
    hint: (life) => careCost(life, 120) > 0
        ? 'Costs \$${careCost(life, 120)} · finds hidden conditions 60% of the time'
        : 'Free · finds hidden conditions 60% of the time',
    run: (life, rng) {
      final cost = careCost(life, 120);
      life.money -= cost;
      life.discovered.add('fertility');
      final found = <String>[];
      for (final c in life.conditions.where((c) => !c.known)) {
        if (rng.nextInt(100) < 60) {
          c.known = true;
          found.add(conditionInfo[c.id]?.name.toLowerCase() ?? c.id);
          life.sceneQueue.add('treat:${c.id}');
        }
      }
      final r = statChange(
        life,
        found.isEmpty
            ? (life.age >= 18
                  ? 'The doctor checked everything twice and said to sleep more.'
                  : 'Your parents took you for a check-up. All good.')
            : 'The check-up caught something early: ${found.join(' and ')}. Early is the best time to find it.',
        {'health': 2 + rng.nextInt(3)},
      );
      return ActionResult(r.text, [
        if (cost > 0) 'Money −\$$cost',
        ...r.notes,
        'Fertility revealed on the Me tab',
      ]);
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
      life.salary =
          ((1500 + rng.nextInt(1500)) * countryProfile(life.country).wage)
              .round();
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
    // With no openings it stays locked, so it never costs energy for nothing.
    extraCheck: (life) => studying(life)
        ? 'Finish your course first'
        : careers.any((c) => c.lockReason(life) == null)
        ? null
        : 'No openings you qualify for yet · see the Path tab',
    run: (life, rng) {
      final open = careers.where((c) => c.lockReason(life) == null).toList();
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
      leaveJob(life);
      return statChange(life, 'You quit your job as $old.', {'happiness': 3});
    },
  ),
  GameAction(
    id: 'party',
    label: 'Throw a party',
    category: 'Social',
    keywords: ['party', 'friends', 'celebrate', 'guests', 'invite'],
    minAge: 16,
    priceNote: 'From \$150 · you pick the guest list',
    run: (life, rng) {
      life.sceneQueue.add('party');
      return ActionResult('You start writing a guest list.');
    },
  ),
  GameAction(
    id: 'shoplift',
    miniGame: 'timing',
    scored: shopliftScored,
    label: 'Shoplift',
    category: 'Crime',
    hint: (l) => riskHint(30, 'minor'),
    keywords: ['steal', 'shoplift', 'crime', 'theft'],
    minAge: 12,
    run: (life, rng) {
      final caught = rng.nextInt(100) < 30;
      if (caught) {
        life.flags['caught_shoplifting'] = Memory(
          life.age,
          'caught shoplifting',
        );
        caughtInTheAct(life, 'shoplifting');
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
];

/// Every action in the game: the starter set plus the expanded activities.
final _lifeActions = <GameAction>[
  GameAction(
    id: 'retire',
    label: 'Retire',
    category: 'Work',
    keywords: ['retire', 'pension', 'stop working', 'old'],
    minAge: 55,
    extraCheck: (life) => life.retired
        ? 'You are already retired'
        : life.job == null
        ? 'You don\'t have a job'
        : null,
    run: (life, rng) {
      final text = retire(life);
      final r = statChange(life, '$text Your pension starts next birthday.', {
        'happiness': 5,
      });
      return ActionResult(r.text, [
        ...r.notes,
        'Pension \$${life.pension}/year',
      ]);
    },
  ),
];

final allActions = <GameAction>[
  ..._lifeActions,
  ...schoolActions,
  ...jobActions,
  ...loveActions,
  ...familyActions,
  ...dynastyActions,
  ..._baseActions,
  ...moreActions,
  ...educationActions,
  ...careerActions,
  ...financeActions,
  ...homeActions,
  ...propertyActions,
  ...justiceActions,
  ...healthActions,
  ...identityActions,
  ...communityActions,
  ...socialActions,
  ...celebrityActions,
  ...petActions,
  ...heistActions,
  ...recapActions,
  ...possessionActions,
  ...kinActions,
  shopAction,
  ...gangActions,
  ...prisonLifeActions,
  ...crimeJobActions,
];
