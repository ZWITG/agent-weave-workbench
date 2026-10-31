import 'dart:math';

import 'models.dart';
import 'storylet.dart';
import 'world_data.dart';

// Living in a country (docs/country-research.md): its local moments each
// year, how often everyday crime touches you, and military service where
// the country has it. Pay, prices, fees, legal ages and the retirement age
// are applied where they are used (careers, economy, school, actions).

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '\$$s';
}

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'life',
  scene: true,
  choices: choices,
);

/// Whether this life is called up for military service this birthday.
bool _calledUp(Life l, CountryProfile p, Random rng) {
  if (l.age != 18 || l.prison != null) return false;
  if (l.marks.any((m) => m.startsWith('draft:'))) return false;
  return switch (p.draft) {
    'universal' => l.gender == 'male',
    'lottery' => l.gender == 'male' && rng.nextInt(100) < 25,
    'selective' => rng.nextInt(100) < 15,
    _ => false,
  };
}

/// The country's side of a birthday. Returns feed lines.
List<String> countryYear(Life l, Random rng) {
  final feed = <String>[];
  final p = countryProfile(l.country);
  if (_calledUp(l, p, rng)) {
    l.sceneQueue.add('draft');
  }
  // Deferred service comes due after studying.
  if (l.marks.contains('draft:deferred') &&
      l.education != 'university' &&
      l.age >= 22 &&
      l.age <= 28) {
    l.marks.remove('draft:deferred');
    l.sceneQueue.add('draft');
  }
  // A local moment, about one year in three.
  if (l.age >= 6 && p.local.isNotEmpty && rng.nextInt(100) < 35) {
    final (text, stat, d) = p.local[rng.nextInt(p.local.length)];
    l.reason = 'Life in ${l.country}';
    if (d != 0) l.stats.add(stat, d);
    feed.add(text);
  }
  // Everyday crime, by how safe the country is.
  final risk = switch (p.safety) {
    'low' => 10,
    'high' => 2,
    _ => 5,
  };
  if (l.age >= 14 && l.prison == null && rng.nextInt(100) < risk) {
    final lost = min(l.money ~/ 10, 200 + rng.nextInt(800)).clamp(0, 1000);
    l.money -= lost;
    l.reason = 'Crime in ${l.city}';
    l.stats.add('happiness', -2);
    feed.add(switch (rng.nextInt(3)) {
      0 =>
        'Someone snatched your phone on the street in ${l.city}.${lost > 0 ? ' Money −${_m(lost)} to replace it.' : ''}',
      1 =>
        'A scam text emptied part of your account before the bank froze it.${lost > 0 ? ' Money −${_m(lost)}.' : ''}',
      _ =>
        'Your bag was stolen from a café table while you looked away.${lost > 0 ? ' Money −${_m(lost)}.' : ''}',
    });
  }
  return feed;
}

Storylet? countryScene(String id, List<String> args, Life l) {
  if (id != 'draft') return null;
  final p = countryProfile(l.country);
  final months = p.draftMonths <= 0 ? 12 : p.draftMonths;
  final studying = l.education == 'university';
  final how = switch (p.draft) {
    'universal' => 'Every man in ${l.country} serves.',
    'lottery' => 'Your number came up in the draft lottery.',
    _ => 'You were one of the few chosen this year.',
  };
  return _scene(
    'draft',
    'Your call-up papers arrived: $months months of military service. $how',
    [
      Choice(
        label: 'Serve',
        outcome: '',
        run: (l, rng) {
          l.marks.add('draft:served');
          l.flags['served'] = Memory(
            l.age,
            'your military service in ${l.country}',
          );
          l.stats.add('athleticism', 6);
          l.stats.add('discipline', 6);
          l.stats.add('health', 2);
          l.stats.add('happiness', -4);
          return '$months months of early mornings, shouting and friendships you will keep for life. You came back fitter and more disciplined.';
        },
      ),
      if (studying)
        Choice(
          label: 'Defer until you graduate',
          outcome: '',
          run: (l, rng) {
            l.marks.add('draft:deferred');
            return 'Your service is postponed until your studies end.';
          },
        ),
      Choice(
        label: 'Ask for alternative civilian service',
        outcome: '',
        risk: 'Longer, but no weapons',
        run: (l, rng) {
          l.marks.add('draft:civilian');
          l.stats.add('karma', 3);
          l.stats.add('happiness', -3);
          return 'You spent ${months * 2} months working in a care home and a hospital kitchen instead. Hard work, and some of the people there changed you.';
        },
      ),
      if (p.draft == 'universal')
        Choice(
          label: 'Dodge it',
          outcome: '',
          risk: 'It is a crime here',
          run: (l, rng) {
            l.marks.add('draft:dodged');
            l.stats.add('karma', -4);
            if (rng.nextInt(100) < 50) {
              l.money -= 5000;
              l.stats.add('happiness', -6);
              return 'They found you. A fine of ${_m(5000)}, a record, and you served anyway.';
            }
            return 'You kept your head down and a doctor friend signed a note. It worked, for now.';
          },
        ),
    ],
  );
}
