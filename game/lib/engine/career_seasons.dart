part of 'career_hub.dart';

// The season tabs on every Career Hub (Training · Exercises · Deployment ·
// Leave for the armed forces, Write · Record · Release · Tour for
// musicians, and so on) are a choice, not decoration.
//
// Once a year you pick one tab as the year's focus. Each tab is one of
// four kinds:
//
// - prep  steady work: the meter always rises a little.
// - push  real work with a fair chance of a good result.
// - big   the career's big moment: odds grow with the meter. A win moves
//         the meter a lot, lifts performance (promotion) and pays; a loss
//         costs meter and a little health.
// - rest  time off: happiness and health come back, the meter slips.
//
// The tab that matches this year's season (the highlighted one) counts
// for more: "in season".

enum _K { prep, push, big, rest }

class _Move {
  const _Move(
    this.kind,
    this.win, {
    this.lose = '',
    this.stats = const {},
    this.pay = 0,
    this.count,
    this.hurt = 2,
  });

  final _K kind;

  /// What happened (a good result, or the only result for prep and rest).
  final String win;

  /// What happened when a push or a big moment did not go your way.
  final String lose;

  /// Stats that change whatever the result.
  final Map<String, int> stats;

  /// Money for a good result (times rank + 1 for a big moment).
  final int pay;

  /// A Hub counter a big win adds to (medals, awards...).
  final String? count;

  /// Health lost when a big moment goes wrong.
  final int hurt;
}

const _seasonMoves = <String, List<_Move>>{
  'actor': [
    _Move(
      _K.prep,
      'Pilot season: a self-tape a day and three rooms full of people who looked exactly like you.',
      stats: {'charisma': 2},
    ),
    _Move(
      _K.push,
      'Twelve-hour days on set, and the director started giving you the close-ups.',
      lose: 'You spent most of the shoot in a trailer waiting to be called.',
      pay: 3000,
    ),
    _Move(
      _K.big,
      'Premiere night: the flashbulbs found you and the first reviews named you.',
      lose: 'The premiere was polite. Nobody wrote about you.',
      stats: {'looks': 1},
      pay: 4000,
      count: 'premieres',
    ),
    _Move(
      _K.push,
      'Awards season: the right parties, the right people, and your name on a few lists.',
      lose: 'Lots of canapés, no nominations.',
      stats: {'happiness': 2},
    ),
  ],
  'musician': [
    _Move(
      _K.prep,
      'You wrote every morning. Most of it was bad; two songs were not.',
      stats: {'creativity': 3},
    ),
    _Move(
      _K.push,
      'Weeks in the studio, and the takes finally sounded like the songs in your head.',
      lose: 'The sessions ran over and the mixes came back flat.',
      stats: {'creativity': 1},
    ),
    _Move(
      _K.big,
      'Release day: the single caught on and the streams kept climbing.',
      lose: 'The release came and went. The algorithm did not notice.',
      pay: 3000,
      count: 'hits',
    ),
    _Move(
      _K.push,
      'On the road: a van, small stages and rooms that sang the words back.',
      lose: 'Half-empty rooms and a van that broke down twice.',
      stats: {'health': -2},
      pay: 2500,
    ),
  ],
  'athlete': [
    _Move(
      _K.prep,
      'Pre-season: hill sprints, the weights room and an early night every night.',
      stats: {'athleticism': 3, 'discipline': 1},
    ),
    _Move(
      _K.push,
      'A run of good games, and the coach stopped rotating you out.',
      lose: 'A patchy season: you kept the shirt, but only just.',
    ),
    _Move(
      _K.big,
      'The play-offs: you played the game of your life when it mattered.',
      lose: 'Knocked out in the play-offs, and you felt every minute of it.',
      pay: 5000,
      count: 'titles',
      hurt: 4,
    ),
    _Move(
      _K.rest,
      'Contract talks and a long summer off. Your body thanked you.',
      pay: 2000,
    ),
  ],
  'politician': [
    _Move(
      _K.prep,
      'You sat through every session and read every paper. The whips noticed.',
      stats: {'smarts': 1},
    ),
    _Move(
      _K.push,
      'Budget season: you won your constituency a new bypass.',
      lose: 'The budget went through without a penny for your patch.',
    ),
    _Move(
      _K.rest,
      'Recess: a summer of village fêtes, and a week where nobody rang you.',
    ),
    _Move(
      _K.big,
      'You campaigned door to door, and the town came out for you.',
      lose: 'The campaign stalled: wrong message, wrong week.',
      stats: {'charisma': 1},
    ),
  ],
  'police': [
    _Move(
      _K.prep,
      'You walked the beat every day and learned every shopkeeper\'s name.',
      stats: {'discipline': 2},
    ),
    _Move(
      _K.push,
      'Long nights on the casework, and the pieces started to fit.',
      lose: 'Every lead went cold.',
      stats: {'smarts': 1},
    ),
    _Move(
      _K.big,
      'Your evidence stood up in court and the jury agreed. Case closed.',
      lose: 'The defence picked your notes apart. The case collapsed.',
    ),
    _Move(
      _K.rest,
      'A quiet review year: your paperwork, your leave and your sleep caught up.',
    ),
  ],
  'model': [
    _Move(
      _K.prep,
      'Castings all week: walk, turn, smile, next.',
      stats: {'looks': 1},
    ),
    _Move(
      _K.big,
      'Fashion week: you opened a show and closed another.',
      lose: 'Fashion week came and went with one small show.',
      pay: 5000,
      count: 'shows',
    ),
    _Move(
      _K.push,
      'You landed a campaign, and your face went up on bus stops.',
      lose: 'The brands went with someone newer.',
      pay: 6000,
    ),
    _Move(_K.rest, 'The off-season: no fittings, no diets, no flights.'),
  ],
  'doctor': [
    _Move(
      _K.prep,
      'Rotations: a new ward every few months and a lot of learning on your feet.',
      stats: {'smarts': 2},
    ),
    _Move(
      _K.big,
      'The winter crisis: corridors full, and you held your ward together.',
      lose: 'The winter crisis broke the rota and very nearly you.',
      stats: {'health': -2},
      pay: 3000,
      count: 'lives',
    ),
    _Move(
      _K.push,
      'Your research paper got through peer review.',
      lose: 'The paper came back with "major revisions".',
      stats: {'smarts': 2},
    ),
    _Move(_K.rest, 'Review year: a lighter rota and a real holiday.'),
  ],
  'vet': [
    _Move(
      _K.push,
      'Lambing: nights in cold barns, and a lot of new lambs on their feet.',
      lose: 'A hard lambing: you lost more than you would like.',
      stats: {'health': -1},
    ),
    _Move(
      _K.prep,
      'Summer clinics: jabs, check-ups and a lot of grateful dogs.',
      stats: {'karma': 2},
    ),
    _Move(
      _K.push,
      'Harvest: you kept the working animals going all season.',
      lose: 'A long harvest of small jobs that nobody remembers.',
      pay: 2000,
    ),
    _Move(
      _K.big,
      'Winter calls: a horse in a ditch at midnight, and you saved it.',
      lose: 'A night call went wrong. The farmer was kind about it.',
      count: 'rescues',
    ),
  ],
  'pilot': [
    _Move(
      _K.prep,
      'You took every roster slot going and logged the hours.',
      stats: {'discipline': 1},
    ),
    _Move(
      _K.big,
      'The check ride: engine out on take-off in the simulator, and you flew it by the book.',
      lose: 'You failed a section of the check ride and have to resit.',
      count: 'checks',
    ),
    _Move(
      _K.push,
      'Peak season: full flights, tight turnarounds and every one on time.',
      lose: 'Delays all summer, and the complaints that come with them.',
      pay: 4000,
    ),
    _Move(
      _K.push,
      'Winter ops: de-icing, crosswinds and some very smooth landings.',
      lose: 'A winter of diversions and cancelled legs.',
      stats: {'health': -1},
    ),
  ],
  'military': [
    _Move(
      _K.prep,
      'Training: drills at dawn, kit inspections and a run before breakfast.',
      stats: {'discipline': 2, 'athleticism': 2},
    ),
    _Move(
      _K.push,
      'Field exercises: your section hit every objective on time.',
      lose: 'A wet, muddy exercise where nothing went to plan.',
      stats: {'health': -1},
    ),
    _Move(
      _K.big,
      'Deployment: a long tour overseas, and you came home with a medal.',
      lose: 'A hard tour. You came home, but it took a lot out of you.',
      pay: 4000,
      count: 'medals',
      hurt: 4,
    ),
    _Move(_K.rest, 'Long leave at home: your own bed, real food and no 5 a.m. starts.'),
  ],
  'lawyer': [
    _Move(
      _K.prep,
      'You worked through the caseload: every file read, every deadline met.',
      stats: {'smarts': 1, 'discipline': 1},
    ),
    _Move(
      _K.big,
      'Trial: your closing speech turned the jury. Verdict in your favour.',
      lose: 'You lost the trial. The other side had the better witness.',
      pay: 5000,
      count: 'wins',
    ),
    _Move(
      _K.push,
      'Appeals: you found the flaw in the ruling and the higher court agreed.',
      lose: 'The appeal was thrown out in an afternoon.',
      stats: {'smarts': 1},
    ),
    _Move(_K.rest, 'Review year: fewer billable hours and a lot more sleep.'),
  ],
  'hustler': [
    _Move(
      _K.prep,
      'Market days: up at four, a good pitch and a regular crowd.',
      pay: 300,
    ),
    _Move(
      _K.big,
      'Festival season: you sold out by Saturday afternoon.',
      lose: 'Rain all weekend. You went home with most of your stock.',
      pay: 2500,
      count: 'sellouts',
    ),
    _Move(
      _K.push,
      'Autumn: new stock, new contacts and a few good deals.',
      lose: 'A slow autumn: the deals fell through.',
      pay: 800,
    ),
    _Move(_K.rest, 'Winter: you stayed in and let the pitch go quiet.'),
  ],
  'astronaut': [
    _Move(
      _K.prep,
      'Selection: centrifuge, cold water and a lot of exams.',
      stats: {'smarts': 1, 'athleticism': 1},
    ),
    _Move(
      _K.push,
      'Mission training: you could do the docking sequence with your eyes shut.',
      lose: 'You washed out of a simulator run and had to start again.',
      stats: {'discipline': 2},
    ),
    _Move(
      _K.big,
      'The launch window opened and you were on the crew.',
      lose: 'The launch slipped, and the seat went to someone else.',
      pay: 5000,
      count: 'flights',
    ),
    _Move(_K.rest, 'Return: relearning gravity, slowly, at home.'),
  ],
  'fighter': [
    _Move(
      _K.prep,
      'Fight camp: two sessions a day and a strict diet.',
      stats: {'athleticism': 3, 'discipline': 2},
    ),
    _Move(
      _K.push,
      'You made weight with half a pound to spare and stared your opponent down.',
      lose: 'A bad weight cut left you drained.',
      stats: {'health': -1},
    ),
    _Move(
      _K.big,
      'Fight night: you won it, and the crowd was on its feet.',
      lose: 'You lost on points and felt every round the next day.',
      pay: 6000,
      count: 'wins',
      hurt: 6,
    ),
    _Move(_K.rest, 'Recovery: physio, sleep and nothing harder than a walk.'),
  ],
};

_Move? _seasonMove(String? careerId, int i) {
  final moves = _seasonMoves[careerId];
  if (moves == null || i < 0 || i >= moves.length) return null;
  return moves[i];
}

/// Which season tab this year's focus went to, or null.
int? hubSeasonChosen(Life l) =>
    l.hub['focusAge'] == l.age ? l.hub['focus'] as int? : null;

/// What the tab does, in a line, before you pick it.
String hubSeasonHint(Life l, int i) {
  final spec = hubFor(l);
  final mv = _seasonMove(l.careerId, i);
  if (spec == null || mv == null) return '';
  final now = i == hubBeat(l) ? ' In season: counts for more.' : '';
  return switch (mv.kind) {
        _K.prep => 'Steady work. ${spec.meter} goes up.',
        _K.push => 'Real work. ${spec.meter} goes up, more if it goes well.',
        _K.big =>
          'The big moment. Win and ${spec.meter} jumps and you move towards promotion; lose and it drops. The higher your ${spec.meter}, the better your chances.',
        _K.rest => 'Time off. Happiness and Health come back; ${spec.meter} slips.',
      } +
      now;
}

/// The odds that a push or a big moment goes well.
int _seasonOdds(Life l, _K k) => switch (k) {
  _K.push => (55 + hubMeter(l) ~/ 4).clamp(30, 90),
  _K.big => (35 + hubMeter(l) ~/ 2).clamp(15, 85),
  _ => 100,
};

/// Moves the career's meter for a season move. Musicians grow listeners
/// and police close cases, because their meters are worked out from those.
String? _seasonMeter(Life l, int by) {
  l.hub['active'] = l.age;
  switch (l.careerId) {
    case 'musician':
      final fans = listenersOf(l);
      final change = by >= 0
          ? max(40 * by, fans * by ~/ 40)
          : -(fans * by.abs() ~/ 60);
      l.music['fans'] = max(0, fans + change);
      _notePeak(l);
      return change == 0
          ? null
          : 'Listeners ${change > 0 ? '+' : '−'}${change.abs()}';
    case 'police':
      if (by < 10) return null;
      final closed = casesClosed(l) + 1;
      l.marks
        ..removeWhere((m) => m.startsWith('cop_closed:'))
        ..add('cop_closed:$closed');
      _notePeak(l);
      return 'Cases closed +1';
    default:
      return _meterNote(l, by);
  }
}

/// The year's focus: one season tab, once a year.
ActionResult hubSeason(Life l, Random rng, int i) {
  final spec = hubFor(l);
  final mv = _seasonMove(l.careerId, i);
  if (spec == null || mv == null) {
    return ActionResult('There is nothing to focus on here.');
  }
  final inSeason = i == hubBeat(l);
  final bonus = inSeason ? 3 : 0;
  l.hub
    ..['focus'] = i
    ..['focusAge'] = l.age;
  final notes = <String>[];
  final deltas = Map<String, int>.of(mv.stats);
  var text = mv.win;
  var pay = mv.pay;
  int by;
  switch (mv.kind) {
    case _K.prep:
      by = 5 + bonus;
      l.performance = min(100, l.performance + 3);
    case _K.push:
      if (rng.nextInt(100) < _seasonOdds(l, _K.push)) {
        by = 7 + bonus;
        l.performance = min(100, l.performance + 4);
      } else {
        by = 2 + bonus;
        text = mv.lose;
        pay = 0;
      }
    case _K.big:
      if (rng.nextInt(100) < _seasonOdds(l, _K.big)) {
        by = 12 + bonus;
        l.performance = min(100, l.performance + 8);
        pay *= l.careerRank + 1;
        if (mv.count != null) _add(l, mv.count!);
        _log(l, '${spec.seasons[i].toLowerCase()}: a big year');
      } else {
        by = -5;
        text = mv.lose;
        pay = 0;
        deltas['happiness'] = (deltas['happiness'] ?? 0) - 3;
        deltas['health'] = (deltas['health'] ?? 0) - mv.hurt;
      }
    case _K.rest:
      by = -4;
      deltas['happiness'] = (deltas['happiness'] ?? 0) + 6 + (inSeason ? 2 : 0);
      deltas['health'] = (deltas['health'] ?? 0) + 3;
  }
  if (spec.id == 'military' && i == 0) l.fitness = min(100, l.fitness + 3);
  final r = statChange(l, text, deltas);
  notes.addAll(r.notes);
  if (_seasonMeter(l, by) case final n?) notes.add(n);
  if (pay > 0) {
    l.money += pay;
    notes.add('Money +${_m(pay)}');
  }
  if (inSeason) notes.add('In season');
  return ActionResult(text, notes);
}

/// The season tab as an activity, so it costs energy, goes in the feed and
/// saves like any other.
GameAction hubSeasonAction(Life l, int i) {
  final spec = hubFor(l);
  final name = spec == null || i >= spec.seasons.length
      ? 'Season'
      : spec.seasons[i];
  return GameAction(
    id: 'hub_season_$i',
    label: name,
    category: 'Career',
    keywords: const ['season', 'focus'],
    extraCheck: (l) {
      final s = hubFor(l);
      if (s == null || _seasonMove(l.careerId, i) == null) {
        return 'Only in a special career';
      }
      final chosen = hubSeasonChosen(l);
      if (chosen != null) {
        return 'This year\'s focus: ${s.seasons[chosen]}. Pick again next year.';
      }
      return null;
    },
    run: (l, rng) => hubSeason(l, rng, i),
  );
}
