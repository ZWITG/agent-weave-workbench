part of 'career_hub.dart';

// "Calling", spec 6.2: special careers reaching into the rest of the game.
// - Actor: a co-star romance (love.dart), or an affair if you are taken.
// - Athlete: a doping offer, tests every season, and a ban if caught.
// - Politician: coalition offers when no one has a majority, and bills
//   written from this year's news (world.dart, via engine.dart).
// - Doctor: malpractice claims after a bad night on the ward.
// - Pilot: an investigation after an incident or a failed check ride.

const _linkKinds = {
  'actor:costar',
  'athlete:doping',
  'athlete:test',
  'politician:coalition',
  'doctor:malpractice',
  'pilot:investigation',
};

bool _recent(Life l, String key, int years) {
  final at = l.hub[key] as int?;
  return at != null && l.age - at <= years;
}

void _queueOnce(Life l, String scene) {
  if (!l.sceneQueue.contains(scene)) l.sceneQueue.add(scene);
}

/// This year's links for the career you are in.
List<String> _linksYear(Life l, Random rng) {
  final feed = <String>[];
  switch (l.careerId) {
    case 'actor':
      if (actorProject(l) != null &&
          !_recent(l, 'costar', 4) &&
          rng.nextInt(100) < 18) {
        _queueOnce(l, 'hub:actor:costar');
      }
    case 'athlete':
      if (_recent(l, 'doping', 99) && l.hub['dopingStopped'] == null) {
        _bump(l, 4);
        if (rng.nextInt(100) < 30) _queueOnce(l, 'hub:athlete:test');
      } else if (l.hub['doping'] == null &&
          hubMeter(l) < 60 &&
          rng.nextInt(100) < 12) {
        _queueOnce(l, 'hub:athlete:doping');
      }
    case 'politician':
      if (l.hub['coalition'] != null) {
        if (rng.nextInt(100) < 15) {
          l.hub.remove('coalition');
          _bump(l, -5);
          _log(l, 'the coalition collapsed');
          feed.add(
            'Your coalition partners walked out over a budget row. The papers called it chaos. Approval −5.',
          );
        }
      } else if (hubMeter(l) >= 38 &&
          hubMeter(l) <= 62 &&
          rng.nextInt(100) < 20) {
        _queueOnce(l, 'hub:politician:coalition');
      }
    case 'doctor':
      if (_recent(l, 'slip', 1) && rng.nextInt(100) < 35 ||
          rng.nextInt(100) < 3) {
        _queueOnce(l, 'hub:doctor:malpractice');
      }
    case 'pilot':
      if (_recent(l, 'incident', 1) && !_recent(l, 'investigated', 2)) {
        _queueOnce(l, 'hub:pilot:investigation');
      }
  }
  return feed;
}

Storylet? _linkScene(List<String> args, Life l) {
  final kind = '${args[0]}:${args[1]}';
  if (!_linkKinds.contains(kind)) return null;
  return switch (kind) {
    'actor:costar' => _costarScene(l),
    'athlete:doping' => _dopingScene(l),
    'athlete:test' => _testScene(l),
    'politician:coalition' => _coalitionScene(l),
    'doctor:malpractice' => _malpracticeScene(l),
    'pilot:investigation' => _investigationScene(l),
    _ => null,
  };
}

// ---------------- Actor: the co-star ----------------

Storylet _costarScene(Life l) {
  l.hub['costar'] = l.age;
  final rng = Random(l.seed + l.age * 31);
  final star = candidate(l, rng, id: freshNpcId(l, 'costar'));
  final first = star.name.split(' ').first;
  final taken = partnerOf(l) != null;
  final title = actorProject(l)?['title'] ?? 'the shoot';
  return _scene(
    'actor_costar',
    'On "$title", your co-star $first keeps running lines with you long after wrap. The crew has started to notice${taken ? ', and so has your phone, which stays face down' : ''}.',
    [
      if (!taken)
        Choice(
          label: 'Ask $first to dinner',
          outcome: '',
          risk: 'The press loves an on-set romance',
          run: (l, rng) {
            star.info['job'] = 'actor';
            l.npcs.add(star);
            l.flags['partner'] = Memory(
              l.age,
              'falling for your co-star ${star.name}',
            );
            l.fame = min(100, l.fame + 3);
            _bump(l, 4);
            _log(l, 'started dating co-star ${star.name}');
            return 'Dinner became breakfast. Within a week the photographers knew. You are dating $first. Buzz +4.';
          },
        )
      else
        Choice(
          label: 'Let it happen',
          outcome: '',
          risk: 'An affair, and the set leaks',
          lock: (l) => loverOf(l) != null ? 'You already have a secret' : null,
          run: (l, rng) {
            final n = Npc(
              id: freshNpcId(l, 'lover'),
              role: 'Secret lover',
              name: star.name,
              birthYear: star.birthYear,
              circle: 'Lover',
              bond: 62,
            )..lastContactAge = l.age;
            n.info.addAll(star.info..remove('stage'));
            n.info['job'] = 'actor';
            n.info['risk'] = 10;
            l.npcs.add(n);
            l.flags['affair'] = Memory(l.age, 'an affair with ${n.name}');
            l.stats.add('karma', -6);
            return 'It started in a trailer between takes, and then it was not just between takes. You and $first are having an affair. Film sets talk. Karma −6.';
          },
        ),
      Choice(
        label: 'Keep it professional',
        outcome: '',
        run: (l, rng) {
          l.stats.add('karma', 1);
          _bump(l, 1);
          return 'You kept it to the scene. The scene, as it happens, was electric. Buzz +1.';
        },
      ),
    ],
  );
}

// ---------------- Athlete: doping ----------------

Storylet _dopingScene(Life l) => _scene(
  'athlete_doping',
  'A man in a club tracksuit you do not recognise finds you in the car park. "Recovery supplements," he says. "Half the league uses them. The testers are years behind." They are not years behind.',
  [
    Choice(
      label: 'Take them',
      outcome: '',
      risk: 'Form up every season · random tests',
      run: (l, rng) {
        l.hub['doping'] = l.age;
        l.stats.add('karma', -5);
        _bump(l, 8);
        return 'Your legs stopped hurting. Your times dropped. You stopped looking people in the eye. Form +8, Karma −5.';
      },
    ),
    Choice(
      label: 'Walk away',
      outcome: '',
      run: (l, rng) {
        l.hub['doping'] = -1;
        l.stats.add('karma', 2);
        return 'You got in your car and drove off. Your form is your own. Karma +2.';
      },
    ),
    Choice(
      label: 'Report him to the league',
      outcome: '',
      risk: 'Some teammates will not thank you',
      run: (l, rng) {
        l.hub['doping'] = -1;
        l.stats.add('karma', 4);
        _log(l, 'reported a doping supplier');
        return 'The league thanked you quietly. Two teammates stopped sitting with you at lunch. Karma +4.';
      },
    ),
  ],
);

Storylet _testScene(Life l) => _scene(
  'athlete_test',
  'A tester is waiting by the changing-room door with a clipboard and a sealed kit. "Random test," she says. Your sample is going to say what you have been taking.',
  [
    Choice(
      label: 'Own up',
      outcome: '',
      risk: 'A two-season ban, fully served',
      run: (l, rng) {
        _ban(l, 2);
        l.stats.add('karma', 3);
        return 'You told them before the result came back. Two seasons out, and a statement you wrote yourself. Form fell to nothing; some of the respect stayed.';
      },
    ),
    Choice(
      label: 'Deny it and appeal',
      outcome: '',
      risk: 'A long shot · or a four-season ban',
      run: (l, rng) {
        if (rng.nextInt(100) < 25) {
          l.hub['dopingStopped'] = l.age;
          return 'A chain-of-custody error. The case collapsed on a technicality. You stopped taking them that night.';
        }
        _ban(l, 4);
        l.stats.add('karma', -4);
        l.fame = max(0, l.fame - 8);
        return 'The appeal failed, loudly. Four seasons out, and your name on every back page for the wrong reasons.';
      },
    ),
  ],
);

void _ban(Life l, int seasons) {
  l.hub['dopingStopped'] = l.age;
  l.hub['meter'] = 0;
  l.hub['banned'] = l.age + seasons;
  l.marks.add('doping_ban:${l.age}');
  _log(l, 'banned for $seasons seasons for doping');
}

/// Seasons left on a doping ban, or 0.
int dopingBan(Life l) => max(0, ((l.hub['banned'] as int?) ?? 0) - l.age);

// ---------------- Politician: coalitions and the news ----------------

Storylet _coalitionScene(Life l) => _scene(
  'politician_coalition',
  'Nobody has a majority. The leader of the Heartland Party, a small party with eleven seats and strong opinions about farming, asks for a meeting. Their votes for your bills, one of their policies in return.',
  [
    Choice(
      label: 'Shake on it',
      outcome: '',
      risk: 'Approval +4 · election odds +3 · it may collapse',
      run: (l, rng) {
        l.hub['coalition'] = l.age;
        _bump(l, 4);
        _log(l, 'formed a coalition with the Heartland Party');
        return 'A handshake for the cameras and a forty-page agreement nobody will read. You govern together. Approval +4.';
      },
    ),
    Choice(
      label: 'Hold out for more',
      outcome: '',
      risk: 'A better deal, or they walk',
      run: (l, rng) {
        if (rng.nextInt(100) < 50) {
          l.hub['coalition'] = l.age;
          _bump(l, 6);
          _log(l, 'formed a coalition on your terms');
          return 'They blinked first. The policy they get is small; the photo is big. Approval +6.';
        }
        _bump(l, -3);
        return 'They walked out and did a deal with your rivals instead. Approval −3.';
      },
    ),
    Choice(
      label: 'Go it alone',
      outcome: '',
      run: (l, rng) {
        _bump(l, -2);
        return 'You will win every vote the hard way. Some you will lose. Approval −2.';
      },
    ),
  ],
);

/// Election odds from being in a coalition (added in hubElectionBonus).
int coalitionBonus(Life l) =>
    l.careerId == 'politician' && l.hub['coalition'] != null ? 3 : 0;

const _newsBills = <String, (String, String, int, int)>{
  'economy': (
    'the Cost of Living Relief Bill',
    'caps energy bills for a year',
    5,
    1,
  ),
  'health': (
    'the Emergency Health Funding Bill',
    'pays for more hospital beds',
    4,
    3,
  ),
  'weather': (
    'the Flood Defences Bill',
    'pays for sea walls and drainage',
    3,
    2,
  ),
  'crime': ('the Safer Streets Bill', 'puts more police on the beat', 3, 0),
  'science': (
    'the Research Investment Bill',
    'funds labs and universities',
    1,
    2,
  ),
  'politics': (
    'the Election Reform Bill',
    'changes how votes are counted',
    -1,
    1,
  ),
  'sport': (
    'the Grassroots Sport Bill',
    'funds pitches and pools in every town',
    2,
    1,
  ),
  'culture': (
    'the Arts Funding Bill',
    'keeps small theatres and galleries open',
    1,
    2,
  ),
};

/// A bill written from this year's news, if the news has one in it.
(String, String, int, int, String)? newsBill(Life l) {
  final news = l.hub['news'];
  if (news is! Map) return null;
  final bill = _newsBills[news['cat']];
  if (bill == null) return null;
  return (bill.$1, bill.$2, bill.$3, bill.$4, '${news['headline']}');
}

// ---------------- Doctor: malpractice ----------------

Storylet _malpracticeScene(Life l) {
  final trust = hubMeter(l);
  final odds = (35 + trust ~/ 2).clamp(20, 85);
  final settle = 20000 + l.careerRank * 10000;
  return _scene(
    'doctor_malpractice',
    'A letter from a law firm: a patient you saw on a busy night says you missed something. The hospital\'s lawyers want to know how you would like to play it.',
    [
      Choice(
        label: 'Settle quietly',
        outcome: '',
        risk: 'Your share: ${_m(settle ~/ 2)} · Ward trust −4',
        run: (l, rng) {
          l.money -= settle ~/ 2;
          _bump(l, -4);
          return 'It went away with a payment and a clause nobody may talk about. Ward trust −4.';
        },
      ),
      Choice(
        label: 'Fight it in court',
        outcome: '',
        risk:
            '${odds >= 60
                ? 'Good chances'
                : odds >= 40
                ? 'Even chances'
                : 'Poor chances'} (your Ward trust counts)',
        run: (l, rng) {
          if (rng.nextInt(100) < odds) {
            _bump(l, 5);
            _log(l, 'won a malpractice case');
            return 'Your notes were careful and the expert agreed with you. Case dismissed. Ward trust +5.';
          }
          l.money -= settle;
          _bump(l, -12);
          l.marks.add('malpractice:${l.age}');
          _log(l, 'lost a malpractice case');
          return 'The judge found you had fallen below the standard of care. Damages ${_m(settle)}, and a review of your practice. Ward trust −12.';
        },
      ),
      Choice(
        label: 'Meet the family and apologise',
        outcome: '',
        risk: 'They may drop it',
        run: (l, rng) {
          l.stats.add('karma', 3);
          if (rng.nextInt(100) < 60) {
            return 'You listened for an hour. At the end, they said they just wanted someone to say sorry. They dropped the claim. Karma +3.';
          }
          l.money -= settle ~/ 2;
          return 'They were grateful, and they still went ahead. The hospital settled. Karma +3.';
        },
      ),
    ],
  );
}

// ---------------- Pilot: the investigation ----------------

Storylet _investigationScene(Life l) {
  l.hub['investigated'] = l.age;
  return _scene(
    'pilot_investigation',
    'Two investigators from the air accident branch, a recorder and a box of tissues nobody touches. They want your account of the flight, from the start.',
    [
      Choice(
        label: 'Tell them everything',
        outcome: '',
        risk: 'Maybe a short suspension',
        run: (l, rng) {
          l.stats.add('karma', 2);
          if (rng.nextInt(100) < 20) {
            _bump(l, -10);
            return 'They found you honest and a little late with the call. Two months on the ground and a retraining course. Flight hours −10.';
          }
          _bump(l, 2);
          return 'Their report praised the crew\'s honesty and changed a checklist across the industry. Flight hours +2.';
        },
      ),
      Choice(
        label: 'Blame the maintenance crew',
        outcome: '',
        risk: 'Cleared, or your licence',
        run: (l, rng) {
          l.stats.add('karma', -4);
          if (rng.nextInt(100) < 50) {
            return 'The engineers took the blame and you took the next flight. Nobody in the hangar talks to you now. Karma −4.';
          }
          l.marks.add('licence_revoked:${l.age}');
          _log(l, 'lost their licence after an investigation');
          leaveJob(l, fired: true);
          return 'The flight data said otherwise. Your licence was revoked, and the airline let you go.';
        },
      ),
    ],
  );
}
