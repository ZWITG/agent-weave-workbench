import 'dart:math';

import 'homes.dart' show homeOf;
import 'jobs.dart' show leaveJob;
import 'models.dart';
import 'storylet.dart';
import 'world.dart';

// The news reaches your life. Stories published this year make one-off
// changes (pay, home values, tax) and, when they touch you, a choice about
// how to respond ("news_hit" scenes). Lasting effects (hiring, rent,
// prices, policing, health, mood) are read from Life.worldMods.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '−' : ''}\$$s';
}

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'world',
  scene: true,
  choices: choices,
);

/// Whether a story with [effect] would reach this life at all.
bool newsTouches(Life l, String effect) => switch (effect) {
  'hiring_down' || 'hiring_up' || 'pandemic' => l.job != null && l.salary > 0,
  'rent_up' => l.has('rental'),
  'crime_wave' || 'housing_boom' || 'housing_crash' => homeOf(l) != null,
  'tax_cut' || 'tax_rise' => l.salary > 0,
  'inflation' => l.age >= 18,
  'flu' => true,
  _ => false,
};

/// One-off changes from stories published this year, plus the scene for
/// the story that touches you most. Returns feed lines.
List<String> newsYear(Life l, List<WorldStory> fresh, Random rng) {
  final feed = <String>[];
  var queued = false;
  for (final s in fresh) {
    final e = s.effect;
    if (e == null || l.prison != null) continue;
    switch (e) {
      case 'hiring_up' when l.job != null && l.salary > 0:
        final raise = (l.salary * 0.04).round();
        l.salary += raise;
        feed.add('The boom reached your payslip: salary +${_m(raise)}.');
      case 'housing_boom' || 'housing_crash':
        final up = e == 'housing_boom';
        for (final a in l.assets.where((a) => a.kind == 'house')) {
          final d = (a.value * (up ? 0.15 : -0.2)).round();
          a.value += d;
          feed.add(
            'House prices ${up ? 'jumped' : 'fell'}: your ${a.name.toLowerCase()} is now worth ${_m(a.value)} (${d >= 0 ? '+' : ''}${_m(d)}).',
          );
          final owed = l.debts['Mortgage'] ?? 0;
          if (!up && owed > a.value) {
            l.stats.add('happiness', -4);
            feed.add(
              'You now owe more on the mortgage than the home is worth.',
            );
          }
        }
      case 'tax_cut' when l.salary > 0:
        final back = (l.salary * 0.03).round();
        l.money += back;
        feed.add('The tax cut put ${_m(back)} back in your pocket.');
      case 'tax_rise' when l.salary > 0:
        final more = (l.salary * 0.03).round();
        l.money -= more;
        feed.add('The new tax took an extra ${_m(more)} from your pay.');
      default:
        break;
    }
    // Not every company cuts staff in a downturn.
    final hits = e != 'hiring_down' || rng.nextInt(100) < 30;
    if (!queued && hits && newsTouches(l, e) && _hasScene(e)) {
      l.sceneQueue.add('news_hit:$e');
      queued = true;
    }
  }
  return feed;
}

bool _hasScene(String e) => const {
  'hiring_down',
  'hiring_up',
  'pandemic',
  'rent_up',
  'crime_wave',
  'inflation',
  'flu',
}.contains(e);

Storylet? newsScene(List<String> args, Life l) {
  if (args.isEmpty || l.prison != null || !newsTouches(l, args.first)) {
    return null;
  }
  return switch (args.first) {
    'hiring_down' => _cuts(l),
    'hiring_up' => _poached(l),
    'pandemic' => _pandemic(l),
    'rent_up' => _rent(l),
    'crime_wave' => _breakIns(l),
    'inflation' => _prices(l),
    'flu' => _flu(l),
    _ => null,
  };
}

Storylet _cuts(Life l) {
  final payout = (l.salary * 0.3).round();
  return _scene(
    'news_hit',
    'The downturn reached your work. Your manager calls everyone in: there will be cuts.',
    [
      Choice(
        label: 'Accept a pay cut to keep your job',
        outcome: '',
        risk: 'Salary down, job safe',
        run: (l, rng) {
          final cut = (l.salary * 0.1).round();
          l.salary -= cut;
          l.stats.add('happiness', -3);
          return 'You signed the new contract. Salary −${_m(cut)} a year, but you still have a desk.';
        },
      ),
      Choice(
        label: 'Work harder and hope',
        outcome: '',
        risk: 'Keep your pay, or lose everything',
        run: (l, rng) {
          l.performance = min(100, l.performance + 8);
          if (rng.nextInt(100) < 15 + (60 - l.performance).clamp(0, 30)) {
            leaveJob(l, fired: true);
            l.stats.add('happiness', -10);
            return 'You stayed late every night for a month. On Friday you were laid off anyway, with a box and a handshake.';
          }
          l.stats.add('health', -2);
          return 'You stayed late every night for a month. When the list came out, your name was not on it.';
        },
      ),
      Choice(
        label: 'Take voluntary redundancy',
        outcome: '',
        risk: 'A payout of ${_m(payout)} · no job',
        run: (l, rng) {
          leaveJob(l);
          l.money += payout;
          l.stats.add('happiness', -2);
          return 'You took the money and walked out into a bad job market. Payout +${_m(payout)}.';
        },
      ),
    ],
  );
}

Storylet _poached(Life l) => _scene(
  'news_hit',
  'Everyone is hiring. A recruiter calls with an offer from a rival firm.',
  [
    Choice(
      label: 'Use it to ask for a raise',
      outcome: '',
      risk: 'Charisma helps · your boss may not like it',
      run: (l, rng) {
        if (rng.nextInt(100) < 40 + (l.stats['charisma'] - 50) ~/ 2) {
          final raise = (l.salary * 0.1).round();
          l.salary += raise;
          return 'Your boss went quiet, then matched it. Salary +${_m(raise)} a year.';
        }
        l.performance = max(0, l.performance - 8);
        return 'Your boss said, "Then take it." You did not. Things are frosty now.';
      },
    ),
    Choice(
      label: 'Stay loyal',
      outcome: 'You thanked the recruiter and hung up. Your boss heard, and was quietly pleased.',
      run: (l, rng) {
        l.performance = min(100, l.performance + 4);
        return null;
      },
    ),
  ],
);

Storylet _pandemic(Life l) => _scene(
  'news_hit',
  'The outbreak has reached your city. Offices are emptying.',
  [
    Choice(
      label: 'Work from home',
      outcome: '',
      risk: 'Safer · lonelier',
      run: (l, rng) {
        l.stats.add('happiness', -3);
        return 'Your kitchen table became your office. You did not catch it, but you talked to the plants.';
      },
    ),
    Choice(
      label: 'Keep going in',
      outcome: '',
      risk: 'Your boss notices · you might catch it',
      run: (l, rng) {
        l.performance = min(100, l.performance + 6);
        if (rng.nextInt(100) < 45) {
          l.stats.add('health', -5);
          return 'You caught it. Two weeks in bed, and a cough that lasted until spring.';
        }
        return 'You kept the office running almost alone. Your boss will remember.';
      },
    ),
  ],
);

Storylet _rent(Life l) {
  final flat = l.assets.firstWhere((a) => a.kind == 'rental');
  final rise = (flat.yearlyCost * 0.15).round();
  return _scene(
    'news_hit',
    'Rents are soaring. A letter from your landlord: the rent goes up by ${_m(rise)} a year.',
    [
      Choice(
        label: 'Pay it',
        outcome: '',
        run: (l, rng) {
          flat.yearlyCost += rise;
          return 'You signed. Rent +${_m(rise)} a year.';
        },
      ),
      Choice(
        label: 'Negotiate',
        outcome: '',
        risk: 'Charisma helps',
        run: (l, rng) {
          if (rng.nextInt(100) < 40 + (l.stats['charisma'] - 50) ~/ 2) {
            return 'You reminded them you always pay on time. They backed down.';
          }
          flat.yearlyCost += rise * 2;
          return 'They did not like being argued with. Rent +${_m(rise * 2)} a year.';
        },
      ),
      Choice(
        label: 'Move back in with family',
        outcome: '',
        run: (l, rng) {
          l.assets.remove(flat);
          l.flags.remove('own_flat');
          l.stats.add('happiness', -4);
          return 'You packed up and moved back into your old room. It is smaller than you remember.';
        },
      ),
    ],
  );
}

Storylet _breakIns(Life l) => _scene(
  'news_hit',
  'There have been break-ins on your street. A neighbour lost everything.',
  [
    Choice(
      label: 'Fit an alarm (\$800)',
      outcome: '',
      lock: (l) => l.money < 800 ? 'Needs \$800' : null,
      run: (l, rng) {
        l.money -= 800;
        return 'A man spent a day drilling holes. Now a small red light blinks in your hallway.';
      },
    ),
    Choice(
      label: 'Hope for the best',
      outcome: '',
      run: (l, rng) {
        if (rng.nextInt(100) < 35) {
          final lost = min(5000, max(300, l.money ~/ 20));
          l.money -= lost;
          l.stats.add('happiness', -6);
          return 'You came home to a broken back door. Money −${_m(lost)} in things you will never see again.';
        }
        return 'Nothing happened. You still check the locks twice.';
      },
    ),
  ],
);

Storylet _prices(Life l) => _scene(
  'news_hit',
  'Prices are soaring. Your weekly shop costs a lot more than last year.',
  [
    Choice(
      label: 'Cut back hard',
      outcome: '',
      risk: 'Saves money · less fun',
      run: (l, rng) {
        final saved = 1500 + rng.nextInt(1500);
        l.money += saved;
        l.stats.add('happiness', -3);
        return 'Own-brand everything and no takeaways. You saved ${_m(saved)}.';
      },
    ),
    Choice(
      label: 'Carry on as normal',
      outcome: '',
      run: (l, rng) {
        final extra = 1000 + rng.nextInt(1500);
        l.money -= extra;
        return 'You winced at every receipt. Money −${_m(extra)}.';
      },
    ),
  ],
);

Storylet _flu(
  Life l,
) => _scene('news_hit', 'The flu is everywhere. The clinic is offering jabs.', [
  Choice(
    label: 'Get the jab',
    outcome: '',
    run: (l, rng) {
      l.stats.add('health', 2);
      return 'A sore arm for a day, and you sailed through the season.';
    },
  ),
  Choice(
    label: 'Skip it',
    outcome: '',
    run: (l, rng) {
      if (rng.nextInt(100) < 40) {
        l.stats.add('health', -4);
        return 'You caught it. A week in bed with a temperature and a box of tissues.';
      }
      return 'You dodged it, this time.';
    },
  ),
]);
