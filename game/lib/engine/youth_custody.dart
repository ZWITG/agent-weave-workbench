import 'dart:math';

import 'actions.dart' show ActionResult, GameAction;
import 'models.dart';
import 'storylet.dart';

// Youth custody (crime doc option 4): under-18s serve their time on a
// youth unit, not in an adult prison. No gangs, riots, yard fights or
// contraband; instead lessons that count, a key worker, and a restorative
// meeting with the person you harmed that can shorten the stay. The
// record is sealed at 18 (justice.dart).

bool onYouthUnit(Life l) => l.prison?.youth == true;

String? _onUnit(Life l) => onYouthUnit(l) ? null : 'Only on a youth unit';

int youthLessons(Life l) =>
    l.marks.where((m) => m.startsWith('yc_lesson:')).length;

bool _sawKeyWorker(Life l) => l.marks.any((m) => m.startsWith('yc_key:'));

bool _hadMeeting(Life l) =>
    l.prison != null && l.marks.contains('yc_meeting:${l.prison!.since}');

/// The youth unit's year, in place of gangs, riots and the yard.
List<String> youthYear(Life l, Random rng) {
  final p = l.prison;
  if (p == null || !p.youth) return const [];
  final feed = <String>[];
  if (rng.nextInt(100) < 30) {
    feed.add(
      const [
        'A youth worker started a football league on the unit. You are in goal.',
        'Lights out at nine, and someone down the corridor cried most nights.',
        'Your mum sent a letter with a photo of the dog. You kept it under the pillow.',
        'Lessons in the morning, a job skills course in the afternoon, the same grey corridor in between.',
      ][rng.nextInt(4)],
    );
  }
  if (rng.nextInt(100) < 15) {
    l.stats.add('happiness', -3);
    p.behaviour = max(0, p.behaviour - 4);
    feed.add(
      'An argument over the TV remote turned into a scuffle. Staff split it up in seconds, but it went on your file.',
    );
  }
  return feed;
}

final youthActions = <GameAction>[
  GameAction(
    id: 'youth_lessons',
    label: 'Go to lessons',
    category: 'Prison',
    keywords: ['school', 'lessons', 'class', 'study', 'education'],
    hint: (l) => onYouthUnit(l)
        ? '${youthLessons(l)} of 2 years towards your school diploma'
        : 'Only on a youth unit',
    extraCheck: _onUnit,
    run: (l, rng) {
      l.marks.add('yc_lesson:${l.age}');
      l.stats.add('smarts', 3);
      l.prison!.behaviour = min(100, l.prison!.behaviour + 4);
      if (youthLessons(l) >= 2 &&
          const {'primary', 'secondary', 'dropout'}.contains(l.education)) {
        l.education = 'high school graduate';
        return ActionResult(
          'Two years of lessons in a room with bars on the window, and you passed your exams. The certificate says the name of a school, not a unit.',
          ['Smarts +3', 'School diploma'],
        );
      }
      return ActionResult(
        'Maths, English and a teacher who refuses to give up on anyone. You learned more than you would admit.',
        ['Smarts +3', 'Behaviour up'],
      );
    },
  ),
  GameAction(
    id: 'key_worker',
    label: 'Talk to your key worker',
    category: 'Prison',
    keywords: ['key worker', 'talk', 'support', 'counsellor', 'help'],
    hint: (l) => onYouthUnit(l)
        ? 'Someone whose job is to be on your side'
        : 'Only on a youth unit',
    extraCheck: _onUnit,
    run: (l, rng) {
      l.marks.add('yc_key:${l.age}');
      l.stats.add('happiness', 4);
      l.stats.add('willpower', 2);
      l.prison!.behaviour = min(100, l.prison!.behaviour + 3);
      return ActionResult(
        'Your key worker, a tired man called Desmond with a terrible tie, asked what you wanted your life to look like at 25. Nobody had asked before.',
        ['Happiness +4', 'Willpower +2', 'Behaviour up'],
      );
    },
  ),
  GameAction(
    id: 'restorative',
    label: 'Meet the person you harmed',
    category: 'Prison',
    keywords: ['restorative', 'apologise', 'meet', 'victim', 'sorry'],
    hint: (l) => 'A restorative meeting, with your key worker there',
    extraCheck: (l) =>
        _onUnit(l) ??
        (!_sawKeyWorker(l)
            ? 'Talk to your key worker first'
            : _hadMeeting(l)
            ? 'You have had your meeting'
            : null),
    run: (l, rng) {
      l.sceneQueue.add('youth:meeting');
      return ActionResult('Your key worker sets up a time.');
    },
  ),
];

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'crime',
  scene: true,
  choices: choices,
);

Storylet? youthScene(List<String> args, Life l) {
  if (args.isEmpty || args.first != 'meeting' || !onYouthUnit(l)) return null;
  final p = l.prison!;
  l.marks.add('yc_meeting:${p.since}');
  return _scene(
    'youth_meeting',
    'A small room with a box of tissues and three chairs. The person whose life you made worse is in one of them. Your key worker is in another. They are waiting for you to speak.',
    [
      Choice(
        label: 'Listen, then say sorry and mean it',
        outcome: '',
        risk: 'Can shorten your stay',
        run: (l, rng) {
          l.stats.add('karma', 5);
          l.stats.add('happiness', 3);
          p.behaviour = min(100, p.behaviour + 10);
          final cut = p.years - p.served > 1;
          if (cut) p.years -= 1;
          return 'They told you what it had been like. You did not look away. At the end they shook your hand, which you had not expected.${cut ? ' The panel took a year off your time.' : ''}';
        },
      ),
      Choice(
        label: 'Say as little as you can',
        outcome: '',
        run: (l, rng) => 'You mumbled an apology to the table. Everyone was polite. Nothing changed.',
      ),
      Choice(
        label: 'Walk out',
        outcome: '',
        run: (l, rng) {
          p.behaviour = max(0, p.behaviour - 6);
          l.stats.add('karma', -2);
          return 'You stood up halfway through their first sentence. The door was heavier than you thought.';
        },
      ),
    ],
  );
}
