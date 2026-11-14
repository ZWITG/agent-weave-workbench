import 'dart:math';

import 'actions.dart';
import 'friends.dart' show meetFriend;
import 'identity.dart' show outlookOf;
import 'minigame_rules.dart' show reflectScored;
import 'models.dart';
import 'storylet.dart';

// Faith: a personal path, not a doctrine. The game never names a specific
// religion — "a faith", "services", "a community" stays deliberately
// non-denominational, matching how the existing Faith actions (reflect,
// community_service) were already written. What matters here is whether
// faith plays a part in this life, how the family you were raised by
// feels about where you land, and whether it connects you to anyone.

const faithPaths = [
  'Devout',
  'Culturally connected',
  'Searching',
  'Not religious',
];

String faithPathOf(Life l) => l.faithPath.isEmpty ? 'Undecided' : l.faithPath;

/// Whether this life was raised with a faith around it, decided once per
/// life from its seed, the same way identity.dart seeds family outlook.
bool raisedInFaith(Life l) => Random(l.seed ^ 0x5A17).nextInt(100) < 55;

/// How far a chosen path sits from the faith (or lack of one) this life
/// was raised in: 0 close, 1 a step away, 2 a real break.
int _distance(bool raised, String path) {
  if (raised) {
    return switch (path) {
      'Not religious' => 2,
      'Searching' => 1,
      _ => 0,
    };
  }
  return switch (path) {
    'Devout' => 2,
    'Searching' => 1,
    _ => 0,
  };
}

/// Sets the path and plays out family reactions; shared by the formative
/// scene and the "change your faith path" action.
String setFaithPath(Life l, String path, String line) {
  l.faithPath = path;
  l.flags['faith_path'] = Memory(l.age, 'choosing ${path.toLowerCase()}');
  final raised = raisedInFaith(l);
  final distance = _distance(raised, path);
  final family = l.npcs.where(
    (n) => n.alive && (n.circle == 'Family' || n.circle == 'Partner'),
  );
  final reactions = <String>[];
  for (final n in family) {
    final first = n.name.split(' ').first;
    switch (outlookOf(l, n)) {
      case 'traditional' when distance == 2:
        n.addFacets(affection: -6, resentment: 4);
        n.remember(
          NpcMemory(
            age: l.age,
            text: raised
                ? 'you walking away from the faith they raised you in'
                : 'you choosing a faith they do not share',
            valence: -2,
            intensity: 2,
            tags: ['faith'],
          ),
        );
        l.marks.add('faith_reconcile:${n.id}:${l.age + 3}');
        reactions.add('$first did not hide their disappointment.');
      case 'mixed' when distance == 2:
        n.addFacets(affection: -2);
        l.marks.add('faith_reconcile:${n.id}:${l.age + 2}');
        reactions.add('$first went quiet about it.');
      case 'supportive' when distance > 0:
        n.addFacets(affection: 3, trust: 2);
        reactions.add('$first said it was your path to walk, not theirs.');
      default:
        if (distance == 0) n.addFacets(affection: 1);
    }
  }
  l.stats.add('happiness', distance == 0 ? 3 : 1);
  return reactions.isEmpty ? line : '$line ${reactions.join(' ')}';
}

Storylet? faithScene(String id, List<String> args, Life l) {
  if (id != 'faith_path') return null;
  final raised = raisedInFaith(l);
  return Storylet(
    id: 'scene:faith_path',
    text: raised
        ? 'You were raised with a faith around you: services, holidays, a community that expected to see you there. Lately you have been asking yourself what you actually believe, not just what you were taught.'
        : 'Faith was never really part of your house growing up. Friends talk about it sometimes, and you have started to wonder what, if anything, you believe.',
    category: 'identity',
    scene: true,
    choices: [
      Choice(
        label: raised
            ? 'Keep walking the path you were raised in'
            : 'Look for a faith of your own',
        outcome: '',
        run: (l, rng) => setFaithPath(
          l,
          'Devout',
          raised
              ? 'You decided the faith you grew up with is yours too, not just your family\'s.'
              : 'You started looking, properly, for the first time.',
        ),
      ),
      Choice(
        label: 'Keep some of it, in your own way',
        outcome: '',
        run: (l, rng) => setFaithPath(
          l,
          'Culturally connected',
          'Not every rule, not every service — but the holidays, the food, the people. That part you keep.',
        ),
      ),
      Choice(
        label: 'Still figuring it out',
        outcome: '',
        run: (l, rng) => setFaithPath(
          l,
          'Searching',
          'You are not ready to say yes or no to anything. That is honest, and it is enough for now.',
        ),
      ),
      Choice(
        label: raised ? 'This was never really yours' : 'Stay as you are',
        outcome: '',
        run: (l, rng) => setFaithPath(
          l,
          'Not religious',
          raised
              ? 'You decided the faith you were raised in was never really yours.'
              : 'You decided you are fine without it.',
        ),
      ),
    ],
  );
}

/// Queues the formative scene once, at 14, and resolves family
/// reconciliations the same way identityYear does for coming out.
List<String> faithYear(Life l, Random rng) {
  if (l.faithPath.isEmpty &&
      l.age == 14 &&
      l.alive &&
      !l.sceneQueue.contains('faith_path')) {
    l.sceneQueue.add('faith_path');
  }
  final feed = <String>[];
  for (final m in l.marks.where((m) => m.startsWith('faith_reconcile:')).toList()) {
    final parts = m.split(':');
    if (int.tryParse(parts[2]) != l.age) continue;
    l.marks.remove(m);
    final n = l.npc(parts[1]);
    if (n == null || !n.alive) continue;
    n.addFacets(affection: 8, trust: 6, resentment: -8);
    feed.add(
      '${n.name.split(' ').first} said they have had time to think, and your faith is your own to walk. "I just want you to be well."',
    );
  }
  return feed;
}

final faithActions = <GameAction>[
  GameAction(
    id: 'reflect',
    miniGame: 'timing',
    scored: reflectScored,
    label: 'Pray or reflect',
    category: 'Faith',
    keywords: [
      'pray',
      'prayer',
      'reflect',
      'faith',
      'quiet',
      'church',
      'mosque',
      'temple',
    ],
    minAge: 4,
    run: (l, rng) {
      final connected = const {
        'Devout',
        'Culturally connected',
      }.contains(l.faithPath);
      l.stress = l.stress - (connected ? 8 : 5);
      return statChange(
        l,
        connected
            ? 'You took a quiet moment the way you were taught, or the way you have made your own. It still works.'
            : 'You took a quiet moment to pray or simply be still. Whatever you believe, it helped you breathe.',
        {'happiness': connected ? 3 : 2, 'willpower': 1},
      );
    },
  ),
  GameAction(
    id: 'community_service',
    label: 'Join a community gathering',
    category: 'Faith',
    keywords: [
      'community',
      'service',
      'gathering',
      'congregation',
      'faith',
      'festival',
    ],
    minAge: 4,
    run: (l, rng) {
      for (final n in l.npcs.where((n) => n.alive && n.circle == 'Family')) {
        n.addFacets(affection: 1);
      }
      final connected = const {
        'Devout',
        'Culturally connected',
      }.contains(l.faithPath);
      String text =
          'You joined a community gathering: shared food, old songs and people who asked how you were and meant it.';
      if (connected && rng.nextInt(100) < 25) {
        final n = meetFriend(l, rng, role: 'Friend from your community');
        text =
            'You joined a community gathering and got talking to ${n.name.split(' ').first} over the washing-up. You exchanged numbers.';
      }
      return statChange(l, text, {'happiness': 3, 'karma': 1});
    },
  ),
  GameAction(
    id: 'faith_change',
    label: 'Sit with where you stand on faith',
    category: 'Faith',
    keywords: ['faith', 'religion', 'belief', 'change faith', 'deconvert', 'convert'],
    minAge: 16,
    extraCheck: (l) =>
        l.faithPath.isEmpty ? 'This finds you on its own around 14' : null,
    run: (l, rng) {
      l.sceneQueue.add('faith_path');
      return ActionResult('You give yourself the evening to actually think it through.');
    },
  ),
];
