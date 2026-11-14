import 'dart:math';

import 'actions.dart' show ActionResult, GameAction, statChange;
import 'careers.dart' show careerById;
import 'jobs.dart' show leaveJob;
import 'love.dart' show candidate, freshNpcId, loverOf, partnerOf;
import 'models.dart';
import 'music.dart' show listenersOf, songwritingOf;
import 'pets.dart' show petHealth, petsOf;
import 'policing.dart'
    show academyDone, casesClosed, casesLost, dirtyFile, isCop;
import 'storylet.dart';
import 'justice.dart' show commitCrime, crimeById, crimes;
import 'underworld.dart' show crewOf;
import 'world_data.dart' show countryNamed;

part 'career_hub_wave2.dart';
part 'career_hub_people.dart';
part 'career_hub_wave3.dart';
part 'career_hub_links.dart';
part 'career_hub_second.dart';

// The Career Hub ("Calling", docs/phase-2/03): every special career gets
// the same shape, filled with its own data.
//
// - A signature meter (0–100) that moves because of what you do: Buzz for
//   actors, Following for musicians, Form for athletes, Approval for
//   politicians, Closed cases for the police.
// - Career activities (category 'Career'), each once a year, some played
//   as mini-games.
// - A season: the career's year in four beats, each with its scene.
// - Promotion from the meter (instead of random big breaks), shown on the
//   ladder like police ranks.
//
// State lives in Life.hub, reset when a career starts.

String _m(int v) =>
    '\$${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

class HubSpec {
  const HubSpec({
    required this.id,
    required this.meter,
    required this.meterBlurb,
    required this.seasons,
    this.meterOf,
    this.details,
  });

  final String id;

  /// The signature meter's name and what moves it.
  final String meter, meterBlurb;

  /// The career's year in four beats (shown as a strip).
  final List<String> seasons;

  /// A meter worked out from other systems (musicians, police).
  final int Function(Life l)? meterOf;

  /// Extra lines for the Hub screen: (label, value).
  final List<(String, String)> Function(Life l)? details;
}

const _actor = HubSpec(
  id: 'actor',
  meter: 'Buzz',
  meterBlurb: 'Auditions, roles, reviews and the press move it. Quiet years let it fade.',
  seasons: ['Pilot season', 'On set', 'Premiere', 'Awards'],
  details: _actorDetails,
);
const _musician = HubSpec(
  id: 'musician',
  meter: 'Following',
  meterBlurb: 'How many people listen to you. Releases and tours grow it; fans drift away in quiet years.',
  seasons: ['Write', 'Record', 'Release', 'Tour'],
  meterOf: _following,
  details: _musicianDetails,
);
const _athlete = HubSpec(
  id: 'athlete',
  meter: 'Form',
  meterBlurb: 'Training, rest and results move it. Overtraining risks injury.',
  seasons: ['Pre-season', 'Season', 'Play-offs', 'Contracts'],
  details: _athleteDetails,
);
const _politician = HubSpec(
  id: 'politician',
  meter: 'Approval',
  meterBlurb:
      'Speeches, votes and time with voters move it. It decides elections.',
  seasons: ['Session', 'Budget', 'Recess', 'Campaign'],
  details: _politicianDetails,
);
const _police = HubSpec(
  id: 'police',
  meter: 'Record',
  meterBlurb: 'Closed cases build it; Internal Affairs can take it all away.',
  seasons: ['The beat', 'Casework', 'Court', 'Review'],
  meterOf: _copRecord,
  details: _policeDetails,
);

/// Every special career with a Hub (wave 1 here, wave 2 in
/// career_hub_wave2.dart).
const hubSpecs = <String, HubSpec>{
  'actor': _actor,
  'musician': _musician,
  'athlete': _athlete,
  'politician': _politician,
  'police': _police,
  ..._wave2Specs,
};

/// The Hub for the career you are in, or null.
HubSpec? hubFor(Life l) {
  if (l.job == null || l.prison != null || l.retired) return null;
  return hubSpecs[l.careerId];
}

int hubMeter(Life l) {
  final s = hubSpecs[l.careerId];
  if (s?.meterOf != null) return s!.meterOf!(l);
  return (l.hub['meter'] as int?) ?? 0;
}

void _bump(Life l, int by) {
  l.hub['meter'] = (hubMeter(l) + by).clamp(0, 100);
  l.hub['active'] = l.age;
  _notePeak(l);
}

/// Keeps the best the career has reached, for the Life Recap.
void _notePeak(Life l) {
  final m = hubMeter(l);
  if (m > ((l.hub['peak'] as int?) ?? 0)) l.hub['peak'] = m;
  if (l.job != null && l.careerRank >= ((l.hub['bestRank'] as int?) ?? -1)) {
    l.hub['bestRank'] = l.careerRank;
    l.hub['best'] = l.job;
  }
}

/// This career's page for the Life Recap: what it was, how far you got.
Map<String, dynamic>? _summary(Life l) {
  final id = l.hub['id'] as String?;
  if (id == null || !hubSpecs.containsKey(id)) return null;
  final best = l.hub['best'] as String?;
  if (best == null) return null;
  return {
    'id': id,
    'best': best,
    'years': max(1, l.age - ((l.hub['since'] as int?) ?? l.age)),
    'peak': (l.hub['peak'] as int?) ?? hubMeter(l),
    'log': hubLog(l).take(3).toList(),
  };
}

/// Every special career this life had a Hub for, oldest first, with the
/// one under way (or just ended) last.
List<Map<String, dynamic>> hubHistory(Life l) {
  if (hubSpecs.containsKey(l.hub['id'])) _notePeak(l);
  return [
    for (final p in (l.hub['past'] as List?) ?? const [])
      Map<String, dynamic>.from(p as Map),
    ?_summary(l),
  ];
}

void _log(Life l, String line) {
  final log = List<String>.from(l.hub['log'] as List? ?? const []);
  log.insert(0, 'Age ${l.age}: $line');
  l.hub['log'] = log.take(8).toList();
}

List<String> hubLog(Life l) => List<String>.from(l.hub['log'] as List? ?? []);

/// The beat of the season this year.
int hubBeat(Life l) => ((l.hub['beat'] as int?) ?? 0) % 4;

/// Starts a career's Hub (called from startCareer).
void startHub(Life l, String careerId) {
  // The career before keeps a page for the Life Recap.
  final past = [...?(l.hub['past'] as List?), ?_summary(l)];
  l.hub
    ..clear()
    ..['id'] = careerId
    ..['since'] = l.age
    ..['past'] = past
    ..['meter'] = 20
    ..['beat'] = 0;
  // The workplace's people take on the career's roles.
  _castContacts(l, careerId);
  switch (careerId) {
    case 'athlete':
      l.sceneQueue.add('hub:athlete:sport');
    case 'musician':
      // The music system is the musician's toolkit.
      l.music['road'] ??= <String>[];
    case 'politician':
      l.hub['meter'] = 50;
  }
}

// ---------------- Promotion ----------------

/// Meter needed to move from rank r to r + 1 (non-elected Hub careers).
int hubThreshold(int rank) => 35 + rank * 15;

/// What the next step needs, for the ladder; null if not a Hub career.
String? hubRankNeeds(Life l) {
  final spec = hubFor(l);
  final c = careerById(l.careerId);
  if (spec == null || c == null || c.elected || spec.id == 'police') {
    return null;
  }
  if (l.careerRank >= c.ladder.length - 1) return null;
  final need = hubThreshold(l.careerRank);
  final have = hubMeter(l);
  if (spec.id == 'musician' && l.careerRank >= 1 && l.music['label'] == null) {
    return 'Sign with a record label and reach ${spec.meter} $need';
  }
  if (spec.id == 'actor' && l.careerRank >= 2 && l.hub['acclaimed'] == null) {
    return 'A well-reviewed release and ${spec.meter} $need';
  }
  if (_wave2Needs(l, spec.id, spec.meter, need) case final extra?) {
    return extra;
  }
  if (have < need) return 'Reach ${spec.meter} $need (now $have)';
  return 'Ready: promotion comes with a good year';
}

String _promote(Life l, String why) {
  final c = careerById(l.careerId)!;
  if (l.careerRank >= c.ladder.length - 1) return '';
  l.careerRank++;
  l.jobSince = l.age;
  l.job = c.ladder[l.careerRank];
  l.salary = c.payIn(l, l.careerRank);
  l.performance = max(l.performance, 60);
  if (l.careerRank == c.ladder.length - 1) {
    l.flags['top_of_career'] = Memory(l.age, 'becoming ${l.job}');
  }
  _log(l, 'promoted to ${l.job}');
  return '$why You are now ${l.job} (${_m(l.salary)} a year).';
}

// ---------------- The year ----------------

/// The Hub's year: the season beat, the meter's drift and promotion.
List<String> hubYear(Life l, Random rng) {
  final spec = hubFor(l);
  if (spec == null) return const [];
  // A career started before it had a Hub (an older save): set the Hub up,
  // with a meter that fits the rank already reached.
  if (l.hub['id'] != spec.id) {
    final rank = l.careerRank;
    startHub(l, spec.id);
    if (spec.id != 'politician') l.hub['meter'] = min(80, 20 + rank * 15);
  }
  _notePeak(l);
  final feed = <String>[..._peopleYear(l, rng)];
  final beat = hubBeat(l);
  switch (spec.id) {
    case 'actor':
      feed.addAll(_actorYear(l, rng, beat));
    case 'musician':
      if (l.music['label'] == null &&
          hubMeter(l) >= 30 &&
          rng.nextInt(100) < 30 &&
          !l.sceneQueue.contains('hub:musician:festival')) {
        l.sceneQueue.add('hub:musician:festival');
      }
    case 'athlete':
      feed.addAll(_athleteYear(l, rng, beat));
    case 'politician':
      if (rng.nextInt(100) < 55) {
        // Half the time, a bill written from this year's news.
        l.sceneQueue.add(
          newsBill(l) != null && rng.nextBool()
              ? 'hub:politician:bill:news'
              : 'hub:politician:bill',
        );
      }
      // Approval drifts back towards the middle.
      final a = hubMeter(l);
      l.hub['meter'] =
          a +
          (a > 50
              ? -3
              : a < 50
              ? 2
              : 0);
    default:
      feed.addAll(_wave2Year(l, rng, spec.id, beat));
  }
  feed.addAll(_linksYear(l, rng));
  // Quiet years: the meter fades (not for meters worked out elsewhere).
  if (spec.meterOf == null &&
      spec.id != 'politician' &&
      l.hub['active'] != l.age) {
    l.hub['meter'] = max(0, hubMeter(l) - 6);
    feed.add('A quiet year in your career: your ${spec.meter} slipped.');
  }
  // Promotion from the meter.
  final c = careerById(l.careerId)!;
  final needs = hubRankNeeds(l);
  if (!c.elected &&
      spec.id != 'police' &&
      needs != null &&
      needs.startsWith('Ready') &&
      l.age - l.jobSince >= 1 &&
      rng.nextInt(100) < 60) {
    feed.add(
      _promote(l, switch (spec.id) {
        'actor' => 'The phone has not stopped: the parts are getting bigger.',
        'musician' => 'The numbers do not lie: venues are getting bigger.',
        'athlete' => 'Your form earned you a step up.',
        _ => _wave2Promotion(spec.id),
      }),
    );
  }
  l.hub['beat'] = ((l.hub['beat'] as int?) ?? 0) + 1;
  return feed;
}

// ---------------- Scenes ----------------

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:hub_$id',
  text: text,
  category: 'work',
  scene: true,
  choices: choices,
);

Storylet? hubScene(List<String> args, Life l) {
  if (args.length >= 2 && args[0] == 'people' && hubFor(l) != null) {
    return _peopleScene(args, l);
  }
  if (args.length >= 2 && args[0] == 'second') {
    return _secondActScene(args[1], l);
  }
  if (args.length < 2 || l.careerId != args[0] || hubFor(l) == null) {
    return null;
  }
  final link = _linkScene(args, l);
  if (link != null) return link;
  return switch ('${args[0]}:${args[1]}') {
    'actor:agent' => _agentScene(l),
    'actor:offer' => _offerScene(l),
    'actor:awards' => _awardsScene(l),
    'musician:festival' => _festivalScene(l),
    'musician:band' => _bandScene(l),
    'athlete:sport' => _sportScene(l),
    'athlete:final' => _finalScene(l),
    'athlete:contract' => _contractScene(l),
    'politician:bill' => _billScene(l, args.length > 2 ? args[2] : null),
    _ => _wave2Scene(args, l),
  };
}

// ================= Actor =================

const _titles = [
  'The Long Night',
  'Paper Crowns',
  'Harbour Lights',
  'Small Hours',
  'The Understudy',
  'Glass Houses',
  'Northbound',
  'A Quiet Riot',
  'Second Spring',
  'The Last Ferry',
];

Map<String, dynamic>? actorProject(Life l) =>
    (l.hub['project'] as Map?)?.cast<String, dynamic>();

int actorAgent(Life l) => (l.hub['agent'] as int?) ?? 0;

List<(String, String)> _actorDetails(Life l) {
  final p = actorProject(l);
  return [
    (
      'Agent',
      const ['None', 'A small agency (10%)', 'A top agency (15%)'][actorAgent(
        l,
      )],
    ),
    (
      'Project',
      p == null
          ? 'Between jobs'
          : '"${p['title']}" (${p['kind']}) · ${switch (p['stage']) {
              'cast' => 'cast',
              'shot' => 'filmed, awaiting release',
              _ => 'released',
            }}',
    ),
    if (l.hub['awards'] != null) ('Awards', '${l.hub['awards']}'),
  ];
}

String _kindFor(Life l) => l.careerRank <= 1
    ? 'a TV series'
    : (l.careerRank == 2 ? 'a film' : 'a lead film role');

/// Audition odds, with an agent, Buzz and how the read went.
int auditionOdds(Life l, double score) =>
    (20 +
            l.stats['charisma'] ~/ 4 +
            l.stats['looks'] ~/ 8 +
            hubMeter(l) ~/ 5 +
            actorAgent(l) * 8 +
            (score * 25).round() -
            l.careerRank * 4)
        .clamp(5, 90);

ActionResult _audition(Life l, Random rng, double score) {
  final odds = auditionOdds(l, score);
  if (rng.nextInt(100) < odds) {
    final title = _titles[rng.nextInt(_titles.length)];
    final kind = _kindFor(l);
    l.hub['project'] = {
      'title': title,
      'kind': kind,
      'stage': 'cast',
      'read': (score * 100).round(),
      'age': l.age,
    };
    _bump(l, 8);
    _log(l, 'cast in "$title"');
    l.money += 2000 * (l.careerRank + 1);
    return ActionResult(
      'You got the part: $kind called "$title". Filming starts this year.',
      ['Buzz +8', 'Fee ${_m(2000 * (l.careerRank + 1))}'],
    );
  }
  _bump(l, 1);
  return ActionResult(
    score >= 0.7
        ? 'A great read, and they still went with someone taller. The casting director wrote your name down.'
        : 'You stumbled over the second page. They said "thank you" in the way that means no.',
    const ['Buzz +1'],
  );
}

List<String> _actorYear(Life l, Random rng, int beat) {
  final feed = <String>[];
  final p = actorProject(l);
  if (p != null && p['stage'] == 'cast') {
    p['stage'] = 'shot';
    l.hub['project'] = p;
    _bump(l, 3);
    feed.add(
      'You wrapped "${p['title']}". The crew gave you a cake shaped like a clapperboard.',
    );
  } else if (p != null && p['stage'] == 'shot') {
    final q =
        (25 +
                ((p['read'] as int?) ?? 50) * 0.35 +
                l.stats['charisma'] / 5 +
                rng.nextInt(25))
            .round()
            .clamp(0, 100);
    p['stage'] = 'released';
    p['quality'] = q;
    l.hub['project'] = p;
    l.fame = min(100, l.fame + 2 + l.careerRank * 2);
    if (q >= 70) {
      _bump(l, 12);
      l.hub['acclaimed'] = l.age;
      _log(l, '"${p['title']}" was a hit with critics ($q/100)');
      feed.add(
        '"${p['title']}" came out to rave reviews ($q/100). Your name was in every one of them.',
      );
      if (!l.sceneQueue.contains('hub:actor:awards')) {
        l.sceneQueue.add('hub:actor:awards');
      }
    } else if (q >= 45) {
      _bump(l, 4);
      feed.add(
        '"${p['title']}" came out to polite reviews ($q/100). Your mum loved it.',
      );
    } else {
      _bump(l, -6);
      _log(l, '"${p['title']}" flopped ($q/100)');
      feed.add(
        '"${p['title']}" flopped ($q/100). One critic called your performance "present".',
      );
    }
  } else if (rng.nextInt(100) < 40) {
    l.sceneQueue.add('hub:actor:offer');
  }
  return feed;
}

Storylet _agentScene(Life l) {
  final now = actorAgent(l);
  return _scene(
    'actor_agent',
    'Agents decide which rooms you get into. A small agency takes 10% and calls you back; a top agency takes 15% and has the scripts nobody else sees. ${now == 0 ? 'You have no agent.' : 'You already have one.'}',
    [
      Choice(
        label: 'Sign with a small agency',
        outcome: '',
        risk: 'Better auditions · 10% of your pay',
        lock: (l) => now == 1 ? 'Your agency now' : null,
        run: (l, rng) {
          l.hub['agent'] = 1;
          _bump(l, 2);
          return 'A woman with three phones signed you on the spot. "Do not cut your hair," she said.';
        },
      ),
      Choice(
        label: 'Try for a top agency',
        outcome: '',
        risk: 'Much better auditions · needs Buzz 40',
        lock: (l) => now == 2
            ? 'Your agency now'
            : hubMeter(l) < 40
            ? 'Needs Buzz 40'
            : null,
        run: (l, rng) {
          if (rng.nextInt(100) < 40 + hubMeter(l) ~/ 2) {
            l.hub['agent'] = 2;
            _bump(l, 5);
            _log(l, 'signed with a top agency');
            return 'The top agency took you on. Your first meeting was with someone whose name you had only seen in credits.';
          }
          return 'They were "very excited about you" and never called back.';
        },
      ),
      if (now > 0)
        Choice(
          label: 'Fire your agent',
          outcome: '',
          run: (l, rng) {
            l.hub['agent'] = 0;
            return 'You fired your agent by text. It felt better than it should have.';
          },
        ),
      Choice(label: 'Not now', outcome: 'You stayed as you are.'),
    ],
  );
}

Storylet? _offerScene(Life l) {
  if (actorProject(l)?['stage'] == 'cast') return null;
  return _scene(
    'actor_offer',
    'Your phone buzzes with three offers at once: an indie film that pays almost nothing, an advert for a car insurance company, and a reality show that wants "the real you".',
    [
      Choice(
        label: 'The indie film',
        outcome: '',
        risk: 'Little money · a chance at acclaim',
        run: (l, rng) {
          l.hub['project'] = {
            'title': _titles[rng.nextInt(_titles.length)],
            'kind': 'an indie film',
            'stage': 'cast',
            'read': 75,
            'age': l.age,
          };
          _bump(l, 4);
          return 'You took the indie. The director cried at the read-through. In a good way.';
        },
      ),
      Choice(
        label: 'The advert',
        outcome: '',
        risk: 'Good money · no Buzz',
        run: (l, rng) {
          final pay = 8000 + l.careerRank * 6000;
          l.money += pay;
          l.hub['active'] = l.age;
          return 'You smiled at a hatchback for two days and earned ${_m(pay)}.';
        },
      ),
      Choice(
        label: 'The reality show',
        outcome: '',
        risk: 'Fame up · public image at risk',
        run: (l, rng) {
          l.fame = min(100, l.fame + 6);
          l.image = (l.image - 6).clamp(-100, 100);
          _bump(l, 3);
          return 'Twelve weeks in a villa with cameras. People know your face now, and most of them have opinions.';
        },
      ),
    ],
  );
}

Storylet? _awardsScene(Life l) {
  final p = actorProject(l);
  if (p == null) return null;
  return _scene(
    'actor_awards',
    'You have been nominated at the Golden Reel awards for "${p['title']}". The studio asks how hard you want to campaign.',
    [
      Choice(
        label: 'Campaign hard (\$20,000)',
        outcome: '',
        needsMoney: 20000,
        risk: 'Better chance',
        run: (l, rng) => _award(l, rng, 20000, 15),
      ),
      Choice(
        label: 'Let the work speak',
        outcome: '',
        risk: 'Fair chance',
        run: (l, rng) => _award(l, rng, 0, 0),
      ),
    ],
  );
}

String _award(Life l, Random rng, int cost, int bonus) {
  l.money -= cost;
  final p = actorProject(l)!;
  final odds = (((p['quality'] as int?) ?? 60) - 45 + bonus + hubMeter(l) ~/ 5)
      .clamp(5, 75);
  if (rng.nextInt(100) < odds) {
    l.hub['awards'] = ((l.hub['awards'] as int?) ?? 0) + 1;
    l.flags['golden_reel'] = Memory(l.age, 'winning a Golden Reel');
    l.fame = min(100, l.fame + 8);
    _bump(l, 15);
    _log(l, 'won a Golden Reel');
    return 'They read your name. You forgot every word of your speech and thanked your landlord. Nobody minded.';
  }
  _bump(l, 3);
  return 'You lost to someone who played a real person. You clapped very convincingly. You are an actor, after all.';
}

final _actorActions = <GameAction>[
  GameAction(
    id: 'act_audition',
    label: 'Audition for a role',
    category: 'Career',
    keywords: ['audition', 'role', 'casting', 'acting'],
    miniGame: 'rhythm',
    extraCheck: (l) => l.careerId != 'actor'
        ? 'Only for actors'
        : actorProject(l)?['stage'] == 'cast'
        ? 'You are already cast in something'
        : null,
    hint: (l) => 'A cold read: hit your lines on the beat',
    run: (l, rng) => _audition(l, rng, 0.6),
    scored: _audition,
  ),
  GameAction(
    id: 'act_class',
    label: 'Take an acting class',
    category: 'Career',
    keywords: ['class', 'acting', 'drama', 'lesson'],
    cost: 1000,
    extraCheck: (l) => l.careerId != 'actor' ? 'Only for actors' : null,
    run: (l, rng) {
      l.money -= 1000;
      _bump(l, 3);
      return statChange(
        l,
        'A week of Meisner exercises. You cried on cue twice.',
        {'charisma': 2, 'creativity': 1},
      );
    },
  ),
  GameAction(
    id: 'act_network',
    label: 'Network at an industry party',
    category: 'Career',
    keywords: ['party', 'network', 'industry', 'contacts'],
    extraCheck: (l) => l.careerId != 'actor' ? 'Only for actors' : null,
    run: (l, rng) {
      if (rng.nextInt(100) < 40 + l.stats['charisma'] ~/ 3) {
        _bump(l, 5);
        return ActionResult(
          'You talked to a producer about dogs for twenty minutes. She wants to "find something" for you.',
          const ['Buzz +5'],
        );
      }
      _bump(l, -2);
      return ActionResult(
        'You told a famous director his last film was "brave". He did not take it well.',
        const ['Buzz −2'],
      );
    },
  ),
  GameAction(
    id: 'act_agent',
    label: 'Your agent',
    category: 'Career',
    keywords: ['agent', 'agency', 'representation'],
    extraCheck: (l) => l.careerId != 'actor' ? 'Only for actors' : null,
    run: (l, rng) {
      l.sceneQueue.insert(0, 'hub:actor:agent');
      return ActionResult('You looked at your options.');
    },
  ),
  GameAction(
    id: 'act_press',
    label: 'Do a press tour',
    category: 'Career',
    keywords: ['press', 'interview', 'talk show', 'promote'],
    extraCheck: (l) => l.careerId != 'actor'
        ? 'Only for actors'
        : actorProject(l)?['stage'] != 'released'
        ? 'Needs a released project'
        : null,
    run: (l, rng) {
      l.fame = min(100, l.fame + 3);
      _bump(l, 5);
      return ActionResult(
        'Nine talk shows in a week. You told the same story about the dog every time and it got better every time.',
        const ['Buzz +5', 'Fame +3'],
      );
    },
  ),
];

// ================= Musician =================

int _following(Life l) {
  final fans = listenersOf(l);
  if (fans <= 0) return 0;
  return (log(fans + 1) / ln10 * 15).round().clamp(0, 100);
}

List<(String, String)> _musicianDetails(Life l) => [
  ('Listeners', '${listenersOf(l)}'),
  ('Label', (l.music['label'] as String?) ?? 'Independent'),
  ('Act', (l.hub['band'] as String?) ?? 'Solo'),
  ('Songwriting', '${songwritingOf(l)}/100'),
];

Storylet _festivalScene(Life l) => _scene(
  'musician_festival',
  'A summer festival has a slot on its smallest stage at four in the afternoon. Nobody gets paid much, but label scouts walk past.',
  [
    Choice(
      label: 'Play the slot',
      outcome: '',
      miniGame: 'rhythm',
      risk: 'Play well and a scout may notice',
      run: (l, rng) => _festival(l, rng, 0.6),
      scored: _festival,
    ),
    Choice(
      label: 'Turn it down',
      outcome: 'You stayed home and wrote instead.',
    ),
  ],
);

String _festival(Life l, Random rng, double score) {
  final gain = (200 + score * 1800 + hubMeter(l) * 30).round();
  l.music['fans'] = listenersOf(l) + gain;
  l.hub['active'] = l.age;
  if (score >= 0.7 && rng.nextInt(100) < 35 && l.music['label'] == null) {
    l.sceneQueue.add('label_offer');
    return 'The tent filled up by the second song. A scout in a borrowed wristband asked for your number. ($gain new listeners)';
  }
  return 'Half a tent, one very drunk superfan and $gain new listeners. A good day.';
}

Storylet _bandScene(Life l) => _scene(
  'musician_band',
  'Solo or a band? A band shares the money and the decisions; solo keeps both, and the blame.',
  [
    Choice(
      label: 'Form a band',
      outcome: '',
      run: (l, rng) {
        const names = [
          'The Night Feeds',
          'Low Tide',
          'Paper Lanterns',
          'Velvet Static',
        ];
        final n = names[rng.nextInt(names.length)];
        l.hub['band'] = n;
        return 'You formed $n with a drummer you met at a bus stop and a bassist who owns a van. The van is the important part.';
      },
    ),
    Choice(
      label: 'Stay solo',
      outcome: '',
      run: (l, rng) {
        l.hub.remove('band');
        return 'Just your name on the poster. Just your name on the bill.';
      },
    ),
  ],
);

final _musicianActions = <GameAction>[
  GameAction(
    id: 'mus_rehearse',
    label: 'Rehearse',
    category: 'Career',
    keywords: ['rehearse', 'practice', 'band', 'set'],
    miniGame: 'rhythm',
    extraCheck: (l) => l.careerId != 'musician' ? 'Only for musicians' : null,
    run: (l, rng) => _rehearse(l, rng, 0.6),
    scored: _rehearse,
  ),
  GameAction(
    id: 'mus_collab',
    label: 'Collaborate with another artist',
    category: 'Career',
    keywords: ['collab', 'feature', 'duet', 'collaborate'],
    miniGame: 'memory',
    extraCheck: (l) => l.careerId != 'musician'
        ? 'Only for musicians'
        : _following(l) < 20
        ? 'Needs Following 20'
        : null,
    run: (l, rng) => _collab(l, rng, 0.6),
    scored: _collab,
  ),
  GameAction(
    id: 'mus_produce',
    label: 'Produce for another artist',
    category: 'Career',
    keywords: ['produce', 'producer', 'studio', 'mix'],
    extraCheck: (l) => l.careerId != 'musician'
        ? 'Only for musicians'
        : songwritingOf(l) < 40
        ? 'Needs songwriting 40'
        : null,
    run: (l, rng) {
      final pay = 1500 + songwritingOf(l) * 120 + rng.nextInt(3000);
      l.money += pay;
      l.music['skill'] = min(100, songwritingOf(l) + 2);
      l.hub['active'] = l.age;
      return ActionResult(
        'You produced a record for a younger act. They argued about every snare hit, then thanked you in the liner notes.',
        ['Money +${_m(pay)}', 'Songwriting +2'],
      );
    },
  ),
  GameAction(
    id: 'mus_band',
    label: 'Band or solo',
    category: 'Career',
    keywords: ['band', 'solo', 'members'],
    extraCheck: (l) => l.careerId != 'musician' ? 'Only for musicians' : null,
    run: (l, rng) {
      l.sceneQueue.insert(0, 'hub:musician:band');
      return ActionResult('You thought about who you want on stage with you.');
    },
  ),
];

ActionResult _rehearse(Life l, Random rng, double score) {
  final gain = 1 + (score * 4).round();
  l.music['skill'] = min(100, songwritingOf(l) + gain);
  l.hub['active'] = l.age;
  return statChange(
    l,
    score >= 0.7
        ? 'The set is tight. You could play it in your sleep, and some nights you do.'
        : 'Ragged in places. That is what rehearsal is for.',
    {'creativity': 1},
  );
}

ActionResult _collab(Life l, Random rng, double score) {
  final gain = (500 + score * 4000 + listenersOf(l) * 0.05).round();
  l.music['fans'] = listenersOf(l) + gain;
  l.hub['active'] = l.age;
  _log(l, 'a collaboration (+$gain listeners)');
  return ActionResult(
    score >= 0.7
        ? 'The feature landed: their fans became your fans overnight.'
        : 'It was fine. A song you both like and nobody else remembers.',
    ['Listeners +$gain'],
  );
}

// ================= Athlete =================

const sports = ['Football', 'Basketball', 'Tennis', 'Athletics'];

String? athleteSport(Life l) => l.hub['sport'] as String?;
int _load(Life l) => (l.hub['load'] as int?) ?? 0;

List<(String, String)> _athleteDetails(Life l) => [
  ('Sport', athleteSport(l) ?? 'Not chosen yet'),
  if (l.hub['record'] != null) ('Last season', '${l.hub['record']}'),
  if (l.hub['place'] != null) ('League place', '${l.hub['place']} of 12'),
  (
    'Training load',
    switch (_load(l)) {
      0 || 1 => 'Fresh',
      2 => 'Working hard',
      _ => 'Overtrained: injury risk',
    },
  ),
  if (l.hub['titles'] != null) ('Titles', '${l.hub['titles']}'),
];

Storylet _sportScene(Life l) => _scene(
  'athlete_sport',
  'Which sport is yours? You will play it in the National League, where everyone was the best at school.',
  [
    for (final s in sports)
      Choice(
        label: s,
        outcome: '',
        run: (l, rng) {
          l.hub['sport'] = s;
          return 'You signed your first contract to play $s. Your name is on a locker now.';
        },
      ),
  ],
);

List<String> _athleteYear(Life l, Random rng, int beat) {
  final ban = dopingBan(l);
  if (ban > 0) {
    return [
      'Banned: you watched the season from the stands. $ban season${ban == 1 ? '' : 's'} left.',
    ];
  }
  final feed = <String>[];
  // The season: ten games, won on form, athleticism and rank.
  final p = ((hubMeter(l) + l.stats['athleticism']) / 220 + l.careerRank * 0.03)
      .clamp(0.15, 0.85);
  var wins = 0;
  for (var i = 0; i < 10; i++) {
    if (rng.nextDouble() < p) wins++;
  }
  final place = (13 - wins - rng.nextInt(3)).clamp(1, 12);
  l.hub['record'] = '$wins won, ${10 - wins} lost';
  l.hub['place'] = place;
  _bump(l, (wins - 5) * 3);
  feed.add(
    'Season over: $wins wins from 10, ${_ordinal(place)} in the National League.',
  );
  if (place <= 4) l.sceneQueue.add('hub:athlete:final');
  // Overtraining catches up.
  final load = _load(l);
  if (load >= 3 && rng.nextInt(100) < 20 + load * 10) {
    l.stats.add('health', -6);
    _bump(l, -10);
    feed.add('You pushed too hard and tore a muscle. Months on the bench.');
  }
  l.hub['load'] = max(0, load - 2);
  if ((l.age - l.jobSince) % 3 == 2) l.sceneQueue.add('hub:athlete:contract');
  return feed;
}

String _ordinal(int n) => switch (n) {
  1 => '1st',
  2 => '2nd',
  3 => '3rd',
  _ => '${n}th',
};

Storylet _finalScene(Life l) => _scene(
  'athlete_final',
  'Play-offs. Your team made it, and the final is tonight. The stadium is full and your phone is on silent.',
  [
    Choice(
      label: 'Play the final',
      outcome: '',
      miniGame: 'reaction',
      risk: 'React fast at the big moments',
      run: (l, rng) => _final(l, rng, 0.6),
      scored: _final,
    ),
  ],
);

String _final(Life l, Random rng, double score) {
  final odds = (25 + score * 40 + hubMeter(l) / 4).round().clamp(10, 85);
  if (rng.nextInt(100) < odds) {
    l.hub['titles'] = ((l.hub['titles'] as int?) ?? 0) + 1;
    l.flags['champion'] = Memory(l.age, 'winning a championship');
    l.fame = min(100, l.fame + 6);
    _bump(l, 12);
    _log(l, 'won the National League title');
    return 'Champions. You lifted the trophy and a bottle of something cold landed on your head.';
  }
  _bump(l, 2);
  return 'You lost the final by a whisker. The silence in the dressing room was the loudest thing you have ever heard.';
}

Storylet _contractScene(Life l) => _scene(
  'athlete_contract',
  'Your contract is up. Your club wants you back; a rival club has been asking about you.',
  [
    Choice(
      label: 'Re-sign',
      outcome: '',
      run: (l, rng) {
        l.money += 5000 * (l.careerRank + 1);
        return 'You re-signed with a signing bonus of ${_m(5000 * (l.careerRank + 1))}. The fans sang your name.';
      },
    ),
    Choice(
      label: 'Ask for a bigger deal',
      outcome: '',
      risk: 'Form decides it',
      run: (l, rng) {
        if (rng.nextInt(100) < 30 + hubMeter(l) ~/ 2) {
          l.salary = (l.salary * 1.25).round();
          return 'They paid up: 25% more a year (${_m(l.salary)}).';
        }
        _bump(l, -3);
        return 'They said no, and the story leaked. Some fans think you are greedy now.';
      },
    ),
    Choice(
      label: 'Move to the rival club',
      outcome: '',
      run: (l, rng) {
        l.salary = (l.salary * 1.15).round();
        l.image = (l.image - 4).clamp(-100, 100);
        _bump(l, 2);
        return 'You moved for 15% more. Your old fans burned your shirt in a car park.';
      },
    ),
  ],
);

final _athleteActions = <GameAction>[
  GameAction(
    id: 'ath_train',
    label: 'Train hard',
    category: 'Career',
    keywords: ['train', 'training', 'practice', 'drills'],
    miniGame: 'whack',
    extraCheck: (l) => l.careerId != 'athlete' ? 'Only for athletes' : null,
    run: (l, rng) => _train(l, rng, 0.6),
    scored: _train,
  ),
  GameAction(
    id: 'ath_rest',
    label: 'Rest and see the physio',
    category: 'Career',
    keywords: ['rest', 'physio', 'recover', 'massage'],
    extraCheck: (l) => l.careerId != 'athlete' ? 'Only for athletes' : null,
    run: (l, rng) {
      l.hub['load'] = 0;
      _bump(l, 1);
      return statChange(
        l,
        'Ice baths, sleep and a physio with very strong thumbs. Your legs feel new.',
        {'health': 3, 'happiness': 1},
      );
    },
  ),
  GameAction(
    id: 'ath_film',
    label: 'Study match footage',
    category: 'Career',
    keywords: ['film', 'footage', 'tactics', 'study'],
    extraCheck: (l) => l.careerId != 'athlete' ? 'Only for athletes' : null,
    run: (l, rng) {
      _bump(l, 2 + l.stats['smarts'] ~/ 30);
      return statChange(
        l,
        'You spotted that their left side drifts late in games.',
        {'smarts': 1},
      );
    },
  ),
  GameAction(
    id: 'ath_sponsor',
    label: 'Sign a sponsorship deal',
    category: 'Career',
    keywords: ['sponsor', 'boots', 'brand', 'deal'],
    extraCheck: (l) => l.careerId != 'athlete'
        ? 'Only for athletes'
        : l.careerRank < 2
        ? 'Needs Professional rank'
        : null,
    run: (l, rng) {
      final pay = 5000 * (l.careerRank + 1) * (l.careerRank + 1);
      l.money += pay;
      l.fame = min(100, l.fame + 2);
      return ActionResult(
        'A sportswear brand put your face on a billboard and ${_m(pay)} in your account.',
        ['Money +${_m(pay)}', 'Fame +2'],
      );
    },
  ),
];

ActionResult _train(Life l, Random rng, double score) {
  final gain = 3 + (score * 6).round();
  _bump(l, gain);
  l.hub['load'] = _load(l) + 1;
  return statChange(
    l,
    _load(l) >= 3
        ? 'Another brutal session. Your body is starting to complain.'
        : score >= 0.7
        ? 'The coach stopped the drill to point at you. "Like that."'
        : 'A grind of a session. It counts.',
    {'athleticism': 1 + (score * 2).round()},
  );
}

// ================= Politician =================

const _bills = <(String, String, int, int)>[
  // (title, what it does, approval if you vote yes, karma if yes)
  ('the Clean Rivers Bill', 'fines factories that pollute', 4, 3),
  ('the Fuel Duty Cut', 'cuts tax on petrol for two years', 6, -1),
  ('the Housing Bill', 'builds homes on green fields', -2, 2),
  ('the Free School Meals Bill', 'feeds every child at school', 3, 4),
  (
    'the Surveillance Bill',
    'lets police read messages without a warrant',
    -4,
    -4,
  ),
  ('the Pay Rise for Nurses', 'raises nurses\' pay, funded by a new tax', 2, 3),
  ('the Gambling Ads Ban', 'bans betting adverts on TV', 3, 2),
  ('the Members\' Pay Rise', 'raises politicians\' own pay', -8, -3),
];

int warChest(Life l) => (l.hub['chest'] as int?) ?? 0;

List<(String, String)> _politicianDetails(Life l) => [
  ('Campaign fund', _m(warChest(l))),
  ('Next election', 'In ${4 - ((l.age - l.jobSince) % 4)} years'),
  if (l.hub['votes'] != null) ('Bills voted on', '${l.hub['votes']}'),
];

/// Election odds from approval and the campaign fund (jobs.dart).
(int, String) hubElectionBonus(Life l) {
  if (l.careerId != 'politician') return (0, '');
  final a = (hubMeter(l) - 50) ~/ 2;
  final chest = min(10, warChest(l) ~/ 10000);
  final coalition = coalitionBonus(l);
  return (
    a + chest + coalition,
    'approval ${hubMeter(l)} and a ${_m(warChest(l))} campaign fund${coalition > 0 ? ', with your coalition partners' : ''}',
  );
}

/// Spends the campaign fund at an election.
void spendWarChest(Life l) => l.hub['chest'] = 0;

Storylet? _billScene(Life l, String? which) {
  final news = which == 'news' ? newsBill(l) : null;
  final i = int.tryParse(which ?? '') ?? (l.age + l.seed) % _bills.length;
  final (title, what, pop, karma) = news == null
      ? _bills[i % _bills.length]
      : (news.$1, news.$2, news.$3, news.$4);
  String vote(Life l, int approval, int k, String how) {
    l.hub['meter'] = (hubMeter(l) + approval).clamp(0, 100);
    l.hub['active'] = l.age;
    l.hub['votes'] = ((l.hub['votes'] as int?) ?? 0) + 1;
    l.stats.add('karma', k);
    return '$how Approval ${approval >= 0 ? '+' : ''}$approval.';
  }

  return _scene(
    'politician_bill',
    '${news == null ? '' : 'After this year\'s headline ("${news.$5}"), '}${news == null ? 'The' : 'the'} vote on $title is tonight. It $what. ${pop > 0 ? 'Voters like it.' : 'Voters are not keen.'} Your party whips are watching${l.hub['coalition'] != null ? ', and so are your coalition partners' : ''}.',
    [
      Choice(
        label: 'Vote for it',
        outcome: '',
        risk: pop >= 0 ? 'Popular' : 'Unpopular',
        run: (l, rng) => vote(l, pop, karma, 'You voted for $title.'),
      ),
      Choice(
        label: 'Vote against it',
        outcome: '',
        risk: pop >= 0 ? 'Unpopular' : 'Popular',
        run: (l, rng) => vote(l, -pop, -karma, 'You voted against $title.'),
      ),
      Choice(
        label: 'Abstain',
        outcome: '',
        run: (l, rng) =>
            vote(l, -1, 0, 'You found an urgent dentist appointment.'),
      ),
    ],
  );
}

final _politicianActions = <GameAction>[
  GameAction(
    id: 'pol_speech',
    label: 'Give a speech',
    category: 'Career',
    keywords: ['speech', 'address', 'talk'],
    miniGame: 'timing',
    extraCheck: (l) =>
        l.careerId != 'politician' ? 'Only for politicians' : null,
    run: (l, rng) => _speech(l, rng, 0.6),
    scored: _speech,
  ),
  GameAction(
    id: 'pol_rally',
    label: 'Hold a rally',
    category: 'Career',
    keywords: ['rally', 'crowd', 'campaign'],
    cost: 2000,
    extraCheck: (l) =>
        l.careerId != 'politician' ? 'Only for politicians' : null,
    run: (l, rng) {
      l.money -= 2000;
      final up = 2 + l.stats['charisma'] ~/ 25;
      l.hub['meter'] = (hubMeter(l) + up).clamp(0, 100);
      l.fame = min(100, l.fame + 1);
      return ActionResult(
        'Flags, a sound system that kept cutting out and a crowd that cheered anyway.',
        ['Approval +$up'],
      );
    },
  ),
  GameAction(
    id: 'pol_surgery',
    label: 'Meet constituents',
    category: 'Career',
    keywords: ['constituents', 'surgery', 'voters', 'town hall'],
    extraCheck: (l) =>
        l.careerId != 'politician' ? 'Only for politicians' : null,
    run: (l, rng) {
      l.hub['meter'] = (hubMeter(l) + 3).clamp(0, 100);
      return statChange(
        l,
        'Four hours in a church hall: potholes, bin collections and a man who wants to talk about pigeons. You fixed two of them.',
        {'karma': 1, 'happiness': -1},
      );
    },
  ),
  GameAction(
    id: 'pol_fundraise',
    label: 'Fundraise',
    category: 'Career',
    keywords: ['fundraise', 'donors', 'money', 'dinner'],
    extraCheck: (l) =>
        l.careerId != 'politician' ? 'Only for politicians' : null,
    run: (l, rng) {
      final raised = 5000 * (l.careerRank + 1) + rng.nextInt(5000);
      l.hub['chest'] = warChest(l) + raised;
      if (rng.nextInt(100) < 10) {
        l.hub['meter'] = (hubMeter(l) - 8).clamp(0, 100);
        l.marks.add('scandal:donor:${l.age}');
        return ActionResult(
          'You raised ${_m(raised)}, and a newspaper found out who one of the donors was.',
          ['Campaign fund +${_m(raised)}', 'Approval −8'],
        );
      }
      l.hub['meter'] = (hubMeter(l) - 1).clamp(0, 100);
      return ActionResult(
        'A dinner with people who own several houses each. You raised ${_m(raised)}.',
        ['Campaign fund +${_m(raised)}', 'Approval −1'],
      );
    },
  ),
  GameAction(
    id: 'pol_bill',
    label: 'Vote on a bill',
    category: 'Career',
    keywords: ['bill', 'vote', 'law', 'parliament'],
    extraCheck: (l) =>
        l.careerId != 'politician' ? 'Only for politicians' : null,
    run: (l, rng) {
      l.sceneQueue.insert(
        0,
        'hub:politician:bill:${rng.nextInt(_bills.length)}',
      );
      return ActionResult('The division bell rang.');
    },
  ),
];

ActionResult _speech(Life l, Random rng, double score) {
  final up = ((score - 0.4) * 15).round();
  l.hub['meter'] = (hubMeter(l) + up).clamp(0, 100);
  l.hub['active'] = l.age;
  return ActionResult(
    score >= 0.7
        ? 'You hit every line. A clip of the speech went round the internet with a lot of flag emojis.'
        : score >= 0.4
        ? 'A solid speech. Nobody will remember it, which is sometimes the point.'
        : 'You lost your place, then your thread, then the room.',
    ['Approval ${up >= 0 ? '+' : ''}$up'],
  );
}

// ================= Police =================

int _copRecord(Life l) => min(100, casesClosed(l) * 8);

List<(String, String)> _policeDetails(Life l) => [
  if (!academyDone(l) && l.careerRank == 0)
    ('Academy', 'Fitness, law exam, the range')
  else ...[
    ('Cases closed', '${casesClosed(l)}'),
    ('Cases lost', '${casesLost(l)}'),
  ],
  (
    'Internal Affairs',
    dirtyFile(l) == 0
        ? 'Clean file'
        : dirtyFile(l) <= 2
        ? 'Rumours'
        : 'Watching you',
  ),
];

final _policeActions = <GameAction>[
  GameAction(
    id: 'cop_patrol',
    label: 'Walk the beat',
    category: 'Career',
    keywords: ['patrol', 'beat', 'police', 'case'],
    extraCheck: (l) => !isCop(l)
        ? 'Only for police officers'
        : l.careerRank < 1
        ? 'Pass the academy first'
        : null,
    run: (l, rng) {
      const pool = [
        'shoplifting',
        'burglary',
        'car_theft',
        'vandalism',
        'assault',
      ];
      l.sceneQueue.insert(
        0,
        'beat_case:${pool[rng.nextInt(pool.length)]}:${25 + rng.nextInt(20)}',
      );
      return ActionResult('A call came over the radio.');
    },
  ),
  GameAction(
    id: 'cop_cold',
    label: 'Reopen a cold case',
    category: 'Career',
    keywords: ['cold case', 'detective', 'file'],
    extraCheck: (l) => !isCop(l)
        ? 'Only for police officers'
        : l.careerRank < 3
        ? 'Detectives only'
        : null,
    run: (l, rng) {
      const pool = ['murder', 'armed_robbery', 'fraud', 'extortion'];
      l.sceneQueue.insert(
        0,
        'beat_case:${pool[rng.nextInt(pool.length)]}:${10 + rng.nextInt(15)}',
      );
      return ActionResult('You pulled a dusty box from the archive.');
    },
  ),
];

/// Every Hub activity.
final hubActions = <GameAction>[
  ..._actorActions,
  ..._musicianActions,
  ..._athleteActions,
  ..._politicianActions,
  ..._policeActions,
  ..._wave2Actions,
];

const _prefixes = {
  'act_': 'actor',
  'mus_': 'musician',
  'ath_': 'athlete',
  'pol_': 'politician',
  'cop_': 'police',
  ..._wave2Prefixes,
};

/// The career a Hub activity belongs to.
String? hubActionCareer(String actionId) {
  for (final e in _prefixes.entries) {
    if (actionId.startsWith(e.key)) return e.value;
  }
  return null;
}

/// Hub activities show only to the career they belong to.
bool hubActionFits(Life l, String actionId) =>
    hubFor(l) != null && hubActionCareer(actionId) == l.careerId;
