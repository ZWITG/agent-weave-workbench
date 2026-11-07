import 'dart:math';

import 'actions.dart';
import 'currency.dart' show currencyLabel;
import 'jobs.dart' show leaveJob;
import 'justice.dart' show convictions;
import 'models.dart';
import 'storylet.dart';
import 'underworld.dart' show leaveCrewForMove;
import 'world_data.dart';

// Moving abroad without a visa: three ways across, life without papers
// (cash-in-hand work only, no bank loans, immigration checks), and the
// roads back to legal status or a deportation home.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '\$$s';
}

bool _roll(Random rng, int pct) => rng.nextInt(100) < pct;

bool undocumented(Life l) => l.marks.contains('undocumented');

bool wasDeported(Life l) => l.flags.containsKey('deported');

/// Jobs that pay cash and do not check papers.
const cashFields = {'Food', 'Retail', 'Trades', 'Animal care', 'The street'};

/// Pay for work without papers.
const undocumentedPay = 0.7;

typedef Route = ({
  String id,
  String label,
  String blurb,
  int cost,
  String risk,
});

const routes = <Route>[
  (
    id: 'overstay',
    label: 'Visit as a tourist and stay',
    blurb: 'Fly in on a holiday and never fly home',
    cost: 1500,
    risk: 'Safest · border officers may turn you back',
  ),
  (
    id: 'smuggler',
    label: 'Pay a smuggler',
    blurb: 'A man who knows a man, and a lot of cash up front',
    cost: 8000,
    risk: 'Expensive · could be a scam or a trap',
  ),
  (
    id: 'hidden',
    label: 'Hide in a lorry or a boat',
    blurb: 'Cheap, cramped and dangerous',
    cost: 800,
    risk: 'Cheapest · the most dangerous way',
  ),
];

Route routeById(String id) => routes.firstWhere((r) => r.id == id);

String? migrateLock(Life l, String route) {
  if (l.age < 16) return 'From age 16';
  if (l.prison != null) return 'Not from prison';
  final r = routeById(route);
  if (l.money < r.cost) return 'Needs ${_m(r.cost)}';
  return null;
}

void _arrive(Life l, CountryData c, String from) {
  if (l.job != null) leaveJob(l);
  final crewLine = leaveCrewForMove(l);
  if (crewLine != null) l.feed.add(FeedEntry(l.age, crewLine, kind: 'nudge'));
  l.assets.removeWhere((a) => a.kind == 'rental');
  l.marks
    ..removeWhere(
      (m) => m.startsWith('origin:') || m.startsWith('papers_since:'),
    )
    ..add('origin:$from')
    ..add('undocumented')
    ..add('papers_since:${l.age}')
    ..add('lived:${c.name}');
  l.country = c.name;
  l.city = c.cities[Random(l.seed + l.age).nextInt(c.cities.length)];
  l.flags['crossed_border'] = Memory(
    l.age,
    'crossing into ${c.name} without papers',
  );
  for (final n in l.npcs.where(
    (n) => n.circle == 'Family' || n.circle == 'Friends',
  )) {
    n.addFacets(affection: -4);
  }
}

/// Tries to reach [to] without a visa by [route]. Returns what happened.
String migrateIllegally(Life l, String to, String route, Random rng) {
  final c = countryNamed(to);
  final r = routeById(route);
  final from = l.country;
  l.money -= r.cost;
  l.reason = 'Crossing a border without papers';
  // A deportation on file, and a border crackdown in the news, both make
  // getting caught likelier.
  final known =
      (wasDeported(l) ? 10 : 0) + (l.worldMods['immigration'] ?? 0) ~/ 2;
  final roll = rng.nextInt(100);
  switch (route) {
    case 'overstay':
      if (roll < 15 + known) {
        l.stats.add('happiness', -5);
        return 'The border officer looked at your return ticket, then at you, and stamped "entry refused". You flew home the same night. ${_m(r.cost)} gone.';
      }
    case 'smuggler':
      if (roll < 15) {
        l.stats.add('happiness', -8);
        return 'The smuggler took the ${_m(r.cost)} and disappeared. His phone number no longer exists.';
      }
      if (roll < 30 + known) {
        _detain(l, from);
        return 'The van was stopped at the border. Two days in a detention centre, then a flight back to $from with "deported" in your file.';
      }
      if (roll < 36) {
        l.stats.add('health', -20);
        l.stats.add('happiness', -10);
      }
    default: // hidden
      if (roll < 30 + known) {
        _detain(l, from);
        return 'Dogs found the lorry at the border. A week in detention, then a flight back to $from. You will not forget the smell of that trailer.';
      }
      if (roll < 50) {
        l.stats.add('health', -30);
        l.stats.add('happiness', -12);
        if (_roll(rng, 50)) {
          return 'The journey went badly wrong: no water, no air, and you were lucky to be found alive. You woke up in a hospital in $from.';
        }
      }
  }
  _arrive(l, c, from);
  l.stats.add('happiness', 3);
  l.stress = l.stress + 15;
  return 'You made it to ${l.city}. No papers, no bank account and a lot of hope. You can only take cash-in-hand work, and every police car makes your heart jump. Money is now counted in the ${currencyLabel(c.name)}.';
}

void _detain(Life l, String from) {
  l.flags['deported'] = Memory(l.age, 'being deported back to $from');
  l.stats.add('happiness', -10);
}

/// Sent home: papers gone, job gone, a deportation on file.
String deport(Life l) {
  final origin = l.marks
      .where((m) => m.startsWith('origin:'))
      .map((m) => m.substring(7))
      .firstOrNull;
  final home = countryNamed(origin ?? l.country);
  final from = l.country;
  if (l.job != null) leaveJob(l, fired: true);
  leaveCrewForMove(l);
  l.assets.removeWhere((a) => a.kind == 'rental');
  l.marks.removeWhere(
    (m) =>
        m == 'undocumented' ||
        m.startsWith('origin:') ||
        m.startsWith('papers_since:'),
  );
  l.country = home.name;
  l.city = home.cities[Random(l.seed + l.age * 3).nextInt(home.cities.length)];
  l.flags['deported'] = Memory(l.age, 'being deported from $from');
  l.stats.add('happiness', -15);
  return 'You were put on a plane back to ${home.name} with one bag. Everything else you built in $from stayed behind.';
}

int _yearsWithout(Life l) {
  for (final m in l.marks) {
    if (m.startsWith('papers_since:')) {
      return l.age - (int.tryParse(m.substring(13)) ?? l.age);
    }
  }
  return 0;
}

void _legalise(Life l, String how) {
  l.marks.removeWhere(
    (m) => m == 'undocumented' || m.startsWith('papers_since:'),
  );
  l.flags['legal_status'] = Memory(l.age, how);
  l.stats.add('happiness', 12);
  l.stress = l.stress - 10;
}

/// Each birthday without papers: immigration checks, amnesties, and
/// deportation after a criminal conviction.
List<String> migrationYear(Life l, Random rng) {
  if (!undocumented(l) || l.prison != null) return const [];
  final since = l.age - _yearsWithout(l);
  if (l.record.any((r) => (r['age'] as int) >= since)) {
    return [deport(l)];
  }
  // A national amnesty in the news: everyone without papers can apply.
  if ((l.worldMods['amnesty'] ?? 0) > 0) {
    _legalise(l, 'the national amnesty');
    return [
      'The amnesty in the news covered you. You queued from before dawn and walked out with papers.',
    ];
  }
  final queued = l.sceneQueue.any((s) => s == 'immigration_check');
  if (!queued &&
      _roll(
        rng,
        6 +
            (convictions(l) > 0 ? 5 : 0) +
            min<int>(10, l.notoriety) +
            (l.worldMods['immigration'] ?? 0) ~/ 2 +
            (l.worldMods['policing'] ?? 0) ~/ 4,
      )) {
    l.sceneQueue.add('immigration_check');
    return const [];
  }
  if (_yearsWithout(l) >= 5 && _roll(rng, 6)) {
    _legalise(l, 'an amnesty for long-term residents');
    return [
      'The government announced an amnesty for people who have lived here five years or more. You queued for nine hours and walked out with papers.',
    ];
  }
  return [
    if (_roll(rng, 30)) 'Another year without papers: cash jobs, no bank account, and you cross the street when you see police.',
  ];
}

// ---------------- Scenes ----------------

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'travel',
  scene: true,
  choices: choices,
);

Storylet? migrationScene(String id, List<String> args, Life l) {
  switch (id) {
    case 'immigration_check':
      if (!undocumented(l)) return null;
      final home = countryProfile(
        l.marks
                .where((m) => m.startsWith('origin:'))
                .map((m) => m.substring(7))
                .firstOrNull ??
            l.country,
      );
      return _scene(
        id,
        'Immigration officers are checking papers at your workplace. Someone points in your direction.',
        [
          Choice(
            label: 'Slip out the back',
            outcome: '',
            risk: 'Fitness helps',
            run: (l, rng) {
              if (_roll(rng, 40 + l.stats['athleticism'] ~/ 3)) {
                if (l.job != null) leaveJob(l);
                return 'You ran through the kitchen and did not stop for three streets. You cannot go back to that job.';
              }
              return deport(l);
            },
          ),
          Choice(
            label: 'Claim asylum',
            outcome: '',
            risk: home.safety.toLowerCase().contains('high')
                ? 'Hard to win from a safe country'
                : 'A fair chance from where you came from',
            run: (l, rng) {
              final odds = home.safety.toLowerCase().contains('high') ? 15 : 45;
              if (_roll(rng, odds)) {
                _legalise(l, 'being granted asylum');
                return 'A long interview, a longer wait, then a letter: asylum granted. You can work and live here legally.';
              }
              return 'Your claim was refused. ${deport(l)}';
            },
          ),
          Choice(
            label: 'Accept it and go home',
            outcome: '',
            run: (l, rng) => deport(l),
          ),
        ],
      );
  }
  return null;
}

// ---------------- Activities ----------------

final migrationActions = <GameAction>[
  GameAction(
    id: 'apply_papers',
    label: 'Apply for legal status',
    category: 'Travel',
    keywords: [
      'papers',
      'legal status',
      'residency',
      'visa',
      'asylum',
      'immigration',
    ],
    minAge: 16,
    priceNote: '\$2,000 for an immigration lawyer',
    cost: 2000,
    extraCheck: (l) => undocumented(l)
        ? (l.money < 2000 ? 'Needs \$2,000' : null)
        : 'Only without papers',
    hint: (l) {
      final married = l.flags.containsKey('married');
      final years = _yearsWithout(l);
      return married
          ? 'Married to a resident: a strong case'
          : l.job != null && years >= 3
          ? '$years years working here: a fair case'
          : 'A weak case for now: marriage or years of work help';
    },
    run: (l, rng) {
      l.money -= 2000;
      final married = l.flags.containsKey('married');
      final years = _yearsWithout(l);
      final odds = married
          ? 75
          : l.job != null && years >= 3
          ? 25 + years * 3
          : 8;
      if (_roll(rng, odds)) {
        _legalise(
          l,
          married
              ? 'getting papers through marriage'
              : 'getting papers through work',
        );
        return ActionResult(
          'The letter came on a Tuesday: you are legal. You read it eleven times, then went and opened a bank account just because you could.',
          ['Money −\$2,000', 'Legal status'],
        );
      }
      if (_roll(rng, 10)) {
        l.sceneQueue.add('immigration_check');
        return ActionResult(
          'The application was refused, and now immigration knows your address.',
          ['Money −\$2,000'],
        );
      }
      return ActionResult(
        'Refused, for now. Your lawyer says a marriage, or more years of work, would make the case.',
        ['Money −\$2,000'],
      );
    },
  ),
];
