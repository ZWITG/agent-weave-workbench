import 'dart:math';

import 'actions.dart';
import 'justice.dart' show caughtInTheAct;
import 'models.dart';

/// Outcomes for activities played as mini-games. [score] runs 0..1; the
/// "Skip" button in every mini-game resolves at 0.6 (no penalty, per the
/// plan's accessibility rule).

String _signed(int v) => v > 0 ? '+$v' : '−${v.abs()}';

ActionResult gymScored(Life life, Random rng, double score) {
  final h = 1 + (score * 5).round();
  final text = score >= 0.8
      ? 'Personal best! Everyone at the gym noticed.'
      : score >= 0.4
      ? 'A solid session. You will feel it tomorrow.'
      : 'You ran out of steam fast. Still counts.';
  return statChange(life, text, {
    'health': h,
    'looks': score >= 0.7 ? 1 : 0,
    'athleticism': (score * 3).round(),
  });
}

ActionResult studyScored(Life life, Random rng, double score) {
  life.school.effort = score >= 0.5 ? 100 : 75;
  final s = 1 + (score * 5).round();
  final text = score >= 0.99
      ? 'Full marks on your practice quiz. It is starting to click.'
      : score >= 0.5
      ? 'You got most of it. A bit more practice and you have it.'
      : 'Rough going, but you learned where the gaps are.';
  return statChange(life, text, {
    'smarts': s,
    'discipline': 1,
    'happiness': score >= 0.5 ? 0 : -1,
  });
}

ActionResult _caughtOrNot(
  Life life,
  Random rng,
  double score, {
  required String what,
  required int minTake,
  required int maxTake,
  required String flag,
  required String flagLabel,
  required String crime,
}) {
  // Extra police patrols (world news) make a clean getaway harder.
  if (score >= 0.5 + (life.worldMods['policing'] ?? 0) / 100) {
    final take = minTake + rng.nextInt(maxTake - minTake + 1);
    life.money += take;
    return statChange(
      life,
      'Clean getaway: you got away with the $what, worth \$$take.',
      {'karma': -3, 'happiness': 1},
    );
  }
  life.flags[flag] = Memory(life.age, flagLabel);
  caughtInTheAct(life, crime);
  return statChange(life, 'Your timing was off and you were caught.', {
    'happiness': -6,
    'karma': -4,
  });
}

ActionResult shopliftScored(Life life, Random rng, double score) =>
    _caughtOrNot(
      life,
      rng,
      score,
      what: 'goods',
      minTake: 20,
      maxTake: 80,
      flag: 'caught_shoplifting',
      flagLabel: 'caught shoplifting',
      crime: 'shoplifting',
    );

ActionResult pickpocketScored(Life life, Random rng, double score) =>
    _caughtOrNot(
      life,
      rng,
      score,
      what: 'wallet',
      minTake: 20,
      maxTake: 140,
      flag: 'arrested',
      flagLabel: 'being arrested for pickpocketing',
      crime: 'pickpocketing',
    );

ActionResult casinoScored(Life life, Random rng, double score) {
  final change = ((score * 2 - 1) * 100).round();
  life.money += change;
  final r = statChange(
    life,
    change > 0
        ? 'You read the cards well and walked away up.'
        : (change == 0
              ? 'You broke even.'
              : 'The cards were not on your side tonight.'),
    {'happiness': change > 0 ? 3 : (change < 0 ? -3 : 0)},
  );
  return ActionResult(r.text, ['Money ${_signed(change)}', ...r.notes]);
}

ActionResult drivingScored(Life life, Random rng, double score) {
  life.money -= 400;
  if (score >= 0.5) {
    life.flags['licence'] = Memory(life.age, 'your driving licence');
    return ActionResult('Sharp reactions. You passed your driving test!', [
      'Money −\$400',
      'Driving licence',
    ]);
  }
  return ActionResult('You braked too late on the test. Try again next year.', [
    'Money −\$400',
    'Why: slow reaction',
  ]);
}

ActionResult instrumentScored(Life life, Random rng, double score) {
  final text = score >= 0.99
      ? 'You played the whole piece without a mistake.'
      : score >= 0.5
      ? 'You stumbled once, then found the groove.'
      : 'It sounded like a cat on the keys. Practice makes progress.';
  return statChange(life, text, {
    'creativity': 1 + (score * 4).round(),
    'discipline': 1,
    'happiness': score >= 0.5 ? 2 : 0,
  });
}

// ---------------- Hobbies and calm, played as mini-games ----------------

int _by(double score, int top) => (score * top).round();

ActionResult yogaScored(Life life, Random rng, double score) {
  life.money -= 15;
  life.fitness = min(100, life.fitness + 2 + _by(score, 4));
  final r = statChange(
    life,
    score >= 0.7
        ? 'You held the tree pose so long the teacher used you as the example.'
        : score >= 0.4
        ? 'You wobbled, found your balance again, and left feeling taller.'
        : 'You fell out of every pose. Everyone does at first.',
    {
      'health': 1 + _by(score, 2),
      'happiness': 1 + _by(score, 2),
      'discipline': 1,
    },
  );
  return ActionResult(r.text, ['Money −\$15', ...r.notes]);
}

ActionResult gamesScored(Life life, Random rng, double score) => statChange(
  life,
  score >= 0.7
      ? 'Top of the leaderboard. Your friends are demanding a rematch.'
      : score >= 0.4
      ? 'A decent run. You will get that boss next time.'
      : 'You got destroyed by a twelve-year-old online. Character building.',
  {
    'happiness': 1 + _by(score, 3),
    'discipline': -1,
    'smarts': score >= 0.8 ? 1 : 0,
  },
);

ActionResult storyScored(Life life, Random rng, double score) => statChange(
  life,
  score >= 0.7
      ? 'The plot clicked into place. You wrote until 2am and it is genuinely good.'
      : score >= 0.4
      ? 'A solid draft, with one twist you are particularly proud of.'
      : 'You lost the thread halfway, but kept the best paragraph.',
  {'creativity': 1 + _by(score, 4), 'smarts': score >= 0.5 ? 1 : 0},
);

ActionResult reflectScored(Life life, Random rng, double score) {
  life.stress = life.stress - (3 + _by(score, 5));
  return statChange(
    life,
    score >= 0.7
        ? 'Your breathing slowed and the noise in your head went quiet.'
        : 'It took a while to settle, but you found a moment of stillness.',
    {'happiness': 1 + _by(score, 3), 'willpower': 1 + _by(score, 1)},
  );
}
