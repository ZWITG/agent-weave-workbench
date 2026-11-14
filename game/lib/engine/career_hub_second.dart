part of 'career_hub.dart';

// "Calling", spec 6.1 Exit: when a special career ends (retiring, quitting
// or being let go, but not a conviction), a scene offers a second act that
// grows out of it: the athlete who coaches, the model who designs, the
// actor who directs. A second act is a job without a ladder; its line goes
// on the career's Life Recap page.

typedef SecondAct = (
  String role,
  int pay,
  String line,
  String? Function(Life)? lock,
);

String? _famous(Life l, int fame) =>
    l.fame >= fame ? null : 'Needs Fame $fame (you have ${l.fame})';

final Map<String, List<SecondAct>> secondActs = {
  'actor': [
    (
      'Film director',
      90000,
      'You moved behind the camera.',
      (l) => _famous(l, 15),
    ),
    (
      'Drama teacher',
      42000,
      'You teach teenagers to project from the diaphragm.',
      null,
    ),
  ],
  'musician': [
    ('Record producer', 80000, 'You produce other people\'s albums now.', null),
    (
      'Music teacher',
      38000,
      'Scales, recitals and one student who might be the real thing.',
      null,
    ),
  ],
  'athlete': [
    ('Head coach', 70000, 'You took a whistle and a clipboard.', null),
    (
      'TV pundit',
      85000,
      'You talk about the game in a sharp suit.',
      (l) => _famous(l, 20),
    ),
  ],
  'model': [
    ('Fashion designer', 60000, 'Your own label, your own sketches.', null),
    ('Agency owner', 75000, 'You book the next faces now.', null),
  ],
  'politician': [
    ('Lobbyist', 120000, 'You know which doors to knock on.', null),
    (
      'Charity director',
      55000,
      'You run a charity you once voted to fund.',
      null,
    ),
  ],
  'military': [
    ('Security consultant', 85000, 'You advise companies on risk.', null),
    (
      'Veterans\' charity worker',
      38000,
      'You help people who came home like you did.',
      null,
    ),
  ],
  'lawyer': [
    ('Law lecturer', 65000, 'You teach the next generation to object.', null),
    ('Mediator', 70000, 'You settle what used to go to court.', null),
  ],
  'doctor': [
    (
      'Medical school lecturer',
      80000,
      'Ward rounds with forty students behind you.',
      null,
    ),
    ('Health columnist', 50000, 'Readers write in; you answer kindly.', null),
  ],
  'pilot': [
    ('Flight instructor', 60000, 'Your students\' first solo flights.', null),
    (
      'Air accident investigator',
      75000,
      'You find out why things go wrong.',
      null,
    ),
  ],
  'vet': [
    ('Animal charity director', 50000, 'You run the rescue centre.', null),
    ('Farm adviser', 45000, 'Farmers call you before they call the vet.', null),
  ],
  'hustler': [
    (
      'Market stall owner',
      35000,
      'A licensed pitch with your name on it.',
      null,
    ),
    ('Street theatre director', 40000, 'You teach the tricks, legally.', null),
  ],
  'police': [
    (
      'Private investigator',
      55000,
      'You take the cases the police will not.',
      null,
    ),
    ('Crime novelist', 30000, 'Your cases, lightly fictionalised.', null),
  ],
  'astronaut': [
    ('Space agency director', 130000, 'You decide who flies next.', null),
    (
      'Science presenter',
      90000,
      'You explain the universe on prime-time TV.',
      (l) => _famous(l, 15),
    ),
  ],
  'fighter': [
    ('Gym owner', 60000, 'Your name over the door, kids on the bags.', null),
    (
      'Fight commentator',
      75000,
      'Ringside, with a microphone.',
      (l) => _famous(l, 15),
    ),
  ],
};

/// Queued by leaveJob when a special career ends.
void queueSecondAct(Life l, String careerId) {
  if (!secondActs.containsKey(careerId) || l.age >= 80) return;
  l.sceneQueue.removeWhere((q) => q.startsWith('hub:second:'));
  l.sceneQueue.add('hub:second:$careerId');
}

/// The second act you took, if any.
String? secondAct(Life l) => l.flags['second_act']?.label;

Storylet? _secondActScene(String careerId, Life l) {
  final acts = secondActs[careerId];
  // Moved on already, retired for good, or the career ended in court.
  if (acts == null ||
      l.job != null ||
      l.retired ||
      !l.alive ||
      l.prison != null ||
      l.flags['career_ended_by_crime']?.age == l.age) {
    return null;
  }
  final field = careerById(careerId)?.field ?? 'working';
  return _scene(
    'second_$careerId',
    'The ${field.toLowerCase().replaceFirst('the ', '')} years are behind you, but the phone still rings. People want what you know. What comes next?',
    [
      for (final (role, pay, line, lock) in acts)
        Choice(
          label: 'Become a ${role.toLowerCase()}',
          outcome: '',
          risk: '${_m(pay)} a year',
          lock: lock,
          run: (l, rng) {
            l.job = role;
            l.salary = pay;
            l.careerId = null;
            l.careerRank = 0;
            l.jobSince = l.age;
            l.performance = 60;
            l.flags['second_act'] = Memory(l.age, 'a second act as $role');
            _log(l, 'went on to become a ${role.toLowerCase()}');
            l.stats.add('happiness', 4);
            return '$line You are now a ${role.toLowerCase()} (${_m(pay)} a year).';
          },
        ),
      Choice(
        label: 'Step away from it all',
        outcome: '',
        run: (l, rng) {
          l.stats.add('happiness', 2);
          return 'You let the phone ring. The job board will be there when you want it.';
        },
      ),
    ],
  );
}
