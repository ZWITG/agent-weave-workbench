import 'dart:math';

import 'lifespan.dart';
import 'models.dart';
import 'storylet.dart';

/// Code-driven events ("scenes"): the same event card as storylets, but
/// their choices run Dart code (interviews, trials, illnesses, births...).
/// A scene is queued by id ("illness:flu") on life.sceneQueue and rebuilt
/// from that id, so a pending scene survives saving.

Storylet? buildScene(String id, Life life) {
  final parts = id.split(':');
  final arg = parts.length > 1 ? parts.sublist(1).join(':') : '';
  return switch (parts.first) {
    'illness' => _illness(id, arg, life),
    'retire_offer' => _retireOffer(id, life),
    _ => null,
  };
}

Storylet _scene(
  String id,
  String text,
  List<Choice> choices, {
  String category = 'life',
}) => Storylet(
  id: 'scene:$id',
  text: text,
  choices: choices,
  category: category,
  scene: true,
);

String _m(int v) =>
    '\$${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

// ---------------- Everyday illness (plan HE-001: GP and ER) ----------------

typedef Illness = ({
  String name,
  String text,
  int severity,
  int minAge,
  int maxAge,
});

const illnesses = <String, Illness>{
  'flu': (
    name: 'the flu',
    text: 'You wake up shivering under three blankets. Everything aches, even your hair. The thermometer says you are not going anywhere today.',
    severity: 6,
    minAge: 3,
    maxAge: 120,
  ),
  'chickenpox': (
    name: 'chickenpox',
    text: 'You are covered in itchy red spots from head to toe. {mother} has hidden the scratchy jumpers and bought a bottle of pink lotion.',
    severity: 4,
    minAge: 2,
    maxAge: 11,
  ),
  'ear': (
    name: 'an ear infection',
    text: 'Your ear throbs like there is a tiny drummer inside it. You can barely hear the TV, and you have cried twice since breakfast.',
    severity: 4,
    minAge: 1,
    maxAge: 12,
  ),
  'food': (
    name: 'food poisoning',
    text: 'That reheated takeaway was a mistake. You have spent the night on the bathroom floor, promising the universe you will never eat prawns again.',
    severity: 5,
    minAge: 10,
    maxAge: 120,
  ),
  'ankle': (
    name: 'a sprained ankle',
    text: 'You stepped off a kerb wrong and heard a pop. Your ankle has swollen to the size of a grapefruit and turned an interesting purple.',
    severity: 5,
    minAge: 8,
    maxAge: 120,
  ),
  'migraine': (
    name: 'migraines',
    text: 'For a week, blinding headaches have come out of nowhere. Bright light feels like knives, and you have had to lie down in the dark twice.',
    severity: 5,
    minAge: 14,
    maxAge: 120,
  ),
  'back': (
    name: 'back pain',
    text: 'Your lower back has seized up. Putting on socks has become a twenty-minute project involving a lot of swearing.',
    severity: 5,
    minAge: 30,
    maxAge: 120,
  ),
  'chest': (
    name: 'a chest infection',
    text: 'A cough that started as a tickle has moved into your chest. You wheeze on the stairs and sleep propped up on four pillows.',
    severity: 7,
    minAge: 50,
    maxAge: 120,
  ),
};

/// Picks an illness that fits the age, or null.
String? pickIllness(Life life, Random rng) {
  final fits = illnesses.entries
      .where((e) => life.age >= e.value.minAge && life.age <= e.value.maxAge)
      .toList();
  if (fits.isEmpty) return null;
  return fits[rng.nextInt(fits.length)].key;
}

Storylet? _illness(String id, String key, Life life) {
  final ill = illnesses[key];
  if (ill == null) return null;
  final adult = life.age >= 18;
  final gpCost = adult ? 80 : 0;
  final erCost = adult ? 400 : 0;
  final sev = ill.severity;
  return _scene(id, ill.text, category: 'health', [
    Choice(
      label: adult ? 'See a GP (${_m(gpCost)})' : 'Go to the doctor',
      outcome: '',
      risk: 'Likely to help',
      lock: (l) => adult && l.money < gpCost ? 'Needs ${_m(gpCost)}' : null,
      run: (l, rng) {
        l.reason = 'Treated ${ill.name}';
        l.money -= gpCost;
        l.stats.add('health', sev ~/ 2 + 2);
        return 'The doctor listened, prodded and diagnosed ${ill.name}. A prescription and a few days of rest later, you felt like yourself again.';
      },
    ),
    Choice(
      label: adult
          ? 'Go to the emergency room (${_m(erCost)})'
          : 'Go to the emergency room',
      outcome: '',
      risk: 'Fast, costly',
      lock: (l) => adult && l.money < erCost ? 'Needs ${_m(erCost)}' : null,
      run: (l, rng) {
        l.reason = 'Emergency care';
        l.money -= erCost;
        l.stats.add('health', sev);
        l.stats.add('happiness', -1);
        return 'Four hours in a plastic chair, then a brisk young doctor sorted you out in ten minutes. Expensive, but you walked out feeling much better.';
      },
    ),
    Choice(
      label: 'Rest at home',
      outcome: '',
      risk: 'Usually fine',
      run: (l, rng) {
        l.reason = 'Resting off ${ill.name}';
        if (rng.nextInt(100) < 70) {
          l.stats.add('health', 1);
          return 'You stayed in bed with tea and terrible daytime TV. It took a week, but it passed.';
        }
        l.stats.add('health', -sev ~/ 2);
        return 'You rested, but it dragged on and got worse before it got better. A doctor might have sped things up.';
      },
    ),
    Choice(
      label: 'Ignore it',
      outcome: '',
      risk: 'Risky',
      run: (l, rng) {
        l.reason = 'Ignored ${ill.name}';
        l.stats.add('health', -sev);
        l.stats.add('willpower', 1);
        return 'You carried on as if nothing was wrong. Your body disagreed, loudly, for weeks.';
      },
    ),
  ]);
}

// ---------------- Retirement (plan CA-010) ----------------

Storylet? _retireOffer(String id, Life life) {
  if (life.job == null || life.retired) return null;
  return _scene(
    id,
    'Your manager calls you in for a chat. "You have given this place ${life.yearsWorked} years," she says. "If you ever want to retire, there is a lovely leaving do in it for you. No pressure."',
    [
      Choice(
        label: 'Retire now',
        outcome: '',
        run: (l, rng) {
          l.reason = 'Retiring';
          final text = retire(l);
          l.stats.add('happiness', 6);
          return '$text There was cake, a card signed by people you had never met and a speech that made you cry. Your pension is ${_m(l.pension)} a year.';
        },
      ),
      Choice(
        label: 'Keep working',
        outcome: 'You said you had a few good years left in you. Your manager looked relieved; nobody else knows where anything is kept.',
        effects: Effects(stats: {'discipline': 2}),
      ),
    ],
  );
}
