import 'models.dart';

/// The pinned watchlist (Life hub): people and dated deadlines the player
/// pins so the year feed surfaces them the year they matter. Pins live in
/// `life.marks` as `pin:npc:<id>`, `pin:release` and `pin:parole`.

const _pin = 'pin:';

bool isPinned(Life l, String key) => l.marks.contains('$_pin$key');

void togglePin(Life l, String key) {
  if (!l.marks.remove('$_pin$key')) l.marks.add('$_pin$key');
}

int? _paroleUntil(Life l) {
  for (final m in l.marks) {
    if (m.startsWith('parole_until:')) return int.tryParse(m.substring(13));
  }
  return null;
}

/// Deadlines that exist right now and can be pinned.
List<String> pinnableDeadlines(Life l) => [
  if (l.prison != null) 'release',
  if (_paroleUntil(l) != null) 'parole',
];

String _years(int n) => n == 1 ? 'next year' : 'in $n years';

/// Every pin with a title and a status line for the Life hub strip.
List<({String key, String title, String status})> watchlist(Life l) {
  final out = <({String key, String title, String status})>[];
  for (final m in l.marks.where((m) => m.startsWith(_pin)).toList()..sort()) {
    final key = m.substring(_pin.length);
    if (key.startsWith('npc:')) {
      final n = l.who(key.substring(4));
      if (n == null) continue;
      final gap = l.age - n.lastContactAge;
      out.add((
        key: key,
        title: n.name,
        status: !n.alive
            ? 'Died'
            : '${n.role} · bond ${n.bond}% · ${gap <= 0 ? 'seen this year' : 'last seen ${gap == 1 ? 'a year' : '$gap years'} ago'}',
      ));
    } else if (key == 'release' && l.prison != null) {
      final p = l.prison!;
      final left = p.years - p.served;
      final hearing = p.youth ? 0 : p.paroleAt - p.served;
      out.add((
        key: key,
        title: 'Your release',
        status: [
          left <= 0 ? 'Due now' : 'At ${l.age + left} (${_years(left)})',
          if (hearing > 0 && hearing < left)
            'parole hearing ${_years(hearing)}',
        ].join(' · '),
      ));
    } else if (key == 'parole' && _paroleUntil(l) != null) {
      final until = _paroleUntil(l)!;
      final left = until - l.age;
      out.add((
        key: key,
        title: 'Your parole',
        status: left <= 0
            ? 'Ends this year'
            : 'Ends at $until (${_years(left)})',
      ));
    }
  }
  return out;
}

/// This year's feed lines for pinned items, called after the year has run.
/// Pins that no longer point at anything (a death already reported, a
/// sentence served) are reported once and then dropped.
List<String> watchYear(Life l) {
  final lines = <String>[];
  final drop = <String>[];
  for (final m in l.marks.where((m) => m.startsWith(_pin))) {
    final key = m.substring(_pin.length);
    if (key.startsWith('npc:')) {
      final n = l.who(key.substring(4));
      if (n == null) {
        drop.add(m);
        continue;
      }
      if (!n.alive) {
        lines.add('Pinned: ${n.name} has died.');
        drop.add(m);
        continue;
      }
      final news = [
        for (final line in n.news)
          if (line.startsWith('Age ${l.age}:'))
            line.substring(line.indexOf(':') + 2),
      ];
      final gap = l.age - n.lastContactAge;
      final turning = n.ageIn(l.year);
      if (news.isNotEmpty) {
        lines.add('Pinned: ${news.last}');
      } else if (turning > 0 && turning % 10 == 0) {
        lines.add('Pinned: ${n.name} turns $turning this year.');
      } else if (gap >= 3 && gap % 3 == 0) {
        lines.add(
          'Pinned: you haven\'t seen ${n.name} in $gap years. Bond ${n.bond}%.',
        );
      }
    } else if (key == 'release') {
      final p = l.prison;
      if (p == null) {
        lines.add('Pinned: you are out. Your release has come.');
        drop.add(m);
        continue;
      }
      final left = p.years - p.served;
      if (left == 1) {
        lines.add('Pinned: one year until your release.');
      } else if (!p.youth && p.paroleAt - p.served == 0 && left > 0) {
        lines.add('Pinned: your parole hearing is this year.');
      }
    } else if (key == 'parole') {
      final until = _paroleUntil(l);
      if (until == null) {
        lines.add('Pinned: your parole is over.');
        drop.add(m);
      } else if (until - l.age == 1) {
        lines.add('Pinned: one year of parole left.');
      }
    }
  }
  l.marks.removeAll(drop);
  return lines;
}
