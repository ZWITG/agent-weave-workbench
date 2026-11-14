part of 'career_hub.dart';

// "Calling", spec 6.1 Exit: when a special career ends (retiring, quitting
// or being let go, but not a conviction), a scene offers a second act that
// grows out of it: the athlete who coaches, the model who designs, the
// actor who directs. A second act is a job without a ladder; its line goes
// on the career's Life Recap page.
//
// A second act can end into a third: leaving one of the roles in
// [thirdActs] (below) offers one more step, keyed off the second act's
// own title rather than the original career. Third acts have no fourth
// act of their own, so the chain ends there on its own.

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

/// Keyed by the second act's own title, so a third act grows out of the
/// second regardless of which career led to it.
final Map<String, SecondAct> thirdActs = {
  'Film director': (
    'Studio executive',
    150000,
    'You green-light other people\'s dreams now.',
    null,
  ),
  'Drama teacher': (
    'School principal',
    70000,
    'You run the whole building now, not just the stage.',
    null,
  ),
  'Record producer': (
    'Label owner',
    130000,
    'Your name is on the building now.',
    null,
  ),
  'Music teacher': (
    'Conservatory dean',
    75000,
    'You set the whole curriculum now.',
    null,
  ),
  'Head coach': (
    'General manager',
    140000,
    'You build the roster now, not just the game plan.',
    null,
  ),
  'TV pundit': (
    'Network anchor',
    150000,
    'You lead the whole broadcast now.',
    (l) => _famous(l, 30),
  ),
  'Fashion designer': (
    'Creative director',
    160000,
    'You answer to no one but the board.',
    null,
  ),
  'Agency owner': (
    'Fashion week organiser',
    120000,
    'You decide who gets seen this season.',
    null,
  ),
  'Lobbyist': (
    'Party strategist',
    180000,
    'You write the playbook now, not just the pitch.',
    null,
  ),
  'Charity director': (
    'Foundation chair',
    90000,
    'You decide which causes get the money.',
    null,
  ),
  'Security consultant': (
    'Risk firm partner',
    160000,
    'Your name is on the letterhead now.',
    null,
  ),
  'Veterans\' charity worker': (
    'National charity director',
    80000,
    'You run the whole organisation now.',
    null,
  ),
  'Law lecturer': (
    'Dean of law',
    110000,
    'You shape every lawyer the school turns out.',
    null,
  ),
  'Mediator': (
    'Arbitration chair',
    130000,
    'The biggest disputes come to you first.',
    null,
  ),
  'Medical school lecturer': (
    'Dean of medicine',
    150000,
    'You run the whole faculty now.',
    null,
  ),
  'Health columnist': (
    'Medical correspondent',
    110000,
    'You are the face health news turns to.',
    (l) => _famous(l, 15),
  ),
  'Flight instructor': (
    'Chief flight examiner',
    95000,
    'You decide who else gets to teach.',
    null,
  ),
  'Air accident investigator': (
    'Head of the investigation board',
    120000,
    'You sign off on every finding now.',
    null,
  ),
  'Animal charity director': (
    'National charity chair',
    90000,
    'You run the whole network of shelters now.',
    null,
  ),
  'Farm adviser': (
    'Agricultural board member',
    85000,
    'Policy now, for every farm like the ones you advised.',
    null,
  ),
  'Market stall owner': (
    'Market hall manager',
    60000,
    'You hand out the pitches now.',
    null,
  ),
  'Street theatre director': (
    'Festival director',
    70000,
    'You book every act in town.',
    null,
  ),
  'Private investigator': (
    'Detective agency owner',
    90000,
    'Your name is on the door now.',
    null,
  ),
  'Crime novelist': (
    'Bestselling author',
    120000,
    'Your books are the ones airports stock.',
    (l) => _famous(l, 10),
  ),
  'Space agency director': (
    'Agency administrator',
    180000,
    'You answer to the government now, for the whole program.',
    null,
  ),
  'Science presenter': (
    'Documentary host',
    140000,
    'Your own series now, not just the studio segment.',
    (l) => _famous(l, 25),
  ),
  'Gym owner': (
    'Gym franchise owner',
    110000,
    'Your name is over doors in three cities now.',
    null,
  ),
  'Fight commentator': (
    'Lead broadcaster',
    140000,
    'You call the main event now, every time.',
    (l) => _famous(l, 25),
  ),
};

/// Queued by leaveJob when a special career ends.
void queueSecondAct(Life l, String careerId) {
  if (!secondActs.containsKey(careerId) || l.age >= 80) return;
  l.sceneQueue.removeWhere((q) => q.startsWith('hub:second:'));
  l.sceneQueue.add('hub:second:$careerId');
}

/// Queued by leaveJob when a second act itself ends.
void queueThirdAct(Life l, String role) {
  if (!thirdActs.containsKey(role) || l.age >= 80) return;
  l.sceneQueue.removeWhere((q) => q.startsWith('hub:third:'));
  l.sceneQueue.add('hub:third:$role');
}

/// The second act you took, if any.
String? secondAct(Life l) => l.flags['second_act']?.label;

/// The third act you took, if any.
String? thirdAct(Life l) => l.flags['third_act']?.label;

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

Storylet? _thirdActScene(String role, Life l) {
  final act = thirdActs[role];
  // Moved on to something else already, retired for good, in prison, or dead.
  if (act == null || l.job != null || l.retired || !l.alive || l.prison != null) {
    return null;
  }
  final (newRole, pay, line, lock) = act;
  return _scene(
    'third_${role.hashCode}',
    'The ${role.toLowerCase()} years are behind you too, but one more door is open. What now?',
    [
      Choice(
        label: 'Become a ${newRole.toLowerCase()}',
        outcome: '',
        risk: '${_m(pay)} a year',
        lock: lock,
        run: (l, rng) {
          l.job = newRole;
          l.salary = pay;
          l.careerId = null;
          l.careerRank = 0;
          l.jobSince = l.age;
          l.performance = 60;
          l.flags['third_act'] = Memory(l.age, 'a third act as $newRole');
          _log(l, 'went on to become a ${newRole.toLowerCase()}');
          l.stats.add('happiness', 4);
          return '$line You are now a ${newRole.toLowerCase()} (${_m(pay)} a year).';
        },
      ),
      Choice(
        label: 'Step away from it all',
        outcome: '',
        run: (l, rng) {
          l.stats.add('happiness', 2);
          return 'You let the phone ring. Some doors only open once.';
        },
      ),
    ],
  );
}
