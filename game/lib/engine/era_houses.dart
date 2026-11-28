/// The Great Houses (Legends plan §5.9, Phase 2D): the era's rich list.
/// The great merchant-banking families (the Medici, Strozzi, Fugger,
/// Welser, Chigi...) with fortunes estimated by historians that rise and
/// fall with history: the Pazzi ruined in 1478, the Medici bank in 1494,
/// the Welser bankrupt in 1614. In Fez, Cairo, Timbuktu and Kongo the
/// leading local houses are listed too. Your house joins the list once it
/// is rich enough. The modern Echelon (echelon.dart) never runs here.
library;

import 'era_wealth.dart';
import 'eras.dart';
import 'models.dart';

/// One line of the list.
typedef EraGreatHouse = ({
  String id,
  String name,
  String city,
  String trade,
  int worth,
  int trend,
  String? note,
  bool fallen,
  bool local,
  bool you,
});

int? _worthIn(Map h, int year) {
  final pts = [
    for (final p in (h['worth'] as List?) ?? const [])
      ((p as List)[0] as int, (p[1] as num).toDouble()),
  ];
  if (pts.isEmpty) return null;
  if (year <= pts.first.$1) return pts.first.$2.round();
  for (var i = 1; i < pts.length; i++) {
    final (y1, w1) = pts[i];
    if (year <= y1) {
      final (y0, w0) = pts[i - 1];
      return (w0 + (w1 - w0) * (year - y0) / (y1 - y0)).round();
    }
  }
  return pts.last.$2.round();
}

String? _noteIn(Map h, int year) {
  String? out;
  final notes = (h['notes'] as Map?) ?? const {};
  final keys = [for (final k in notes.keys) int.parse(k as String)]..sort();
  for (final k in keys) {
    if (k <= year) out = notes['$k'] as String;
  }
  return out;
}

/// The worth your house needs to join the list, in florins of the day.
int eraHousesJoin(Life l, EraRules era) =>
    eraCost(l, era, (era.housesData['join'] as int?) ?? 5000);

/// "The house of da Vinci".
String eraYourHouse(Life l) =>
    'The house of ${l.surname.isNotEmpty ? l.surname : l.firstName}';

bool eraOnTheList(Life l, EraRules era) =>
    eraNetWorth(l, era) >= eraHousesJoin(l, era);

/// The list this year, richest first: the great houses of Europe, the
/// local houses of your part of the world, houses fallen in the last ten
/// years, and yours if it has joined.
List<EraGreatHouse> eraGreatHouses(Life l, EraRules era) {
  final group = era.regionOf(l).group;
  final y = l.year;
  final out = <EraGreatHouse>[];
  for (final raw in (era.housesData['list'] as List?) ?? const []) {
    final h = raw as Map;
    final groups = (h['groups'] as List?) ?? const [];
    final local = groups.isNotEmpty;
    if (local && !groups.contains(group)) continue;
    final from = h['from'] as int?;
    if (from != null && y < from) continue;
    final fell = h['fell'] as int?;
    if (fell != null && y >= fell) {
      if (y - fell > 10) continue;
      out.add((
        id: h['id'] as String,
        name: h['name'] as String,
        city: h['city'] as String,
        trade: h['trade'] as String,
        worth: 0,
        trend: 0,
        note: h['fallen'] as String?,
        fallen: true,
        local: local,
        you: false,
      ));
      continue;
    }
    final w = _worthIn(h, y) ?? 0;
    final before = _worthIn(h, y - 5) ?? w;
    out.add((
      id: h['id'] as String,
      name: h['name'] as String,
      city: h['city'] as String,
      trade: h['trade'] as String,
      worth: w,
      trend: w > before * 1.08 ? 1 : (w < before * 0.92 ? -1 : 0),
      note: _noteIn(h, y),
      fallen: false,
      local: local,
      you: false,
    ));
  }
  final mine = eraNetWorth(l, era);
  if (mine >= eraHousesJoin(l, era)) {
    out.add((
      id: 'you',
      name: eraYourHouse(l),
      city: l.city,
      trade: l.job ?? 'your fortune',
      worth: mine,
      trend: 0,
      note: null,
      fallen: false,
      local: false,
      you: true,
    ));
  }
  out.sort((a, b) {
    if (a.fallen != b.fallen) return a.fallen ? 1 : -1;
    return b.worth.compareTo(a.worth);
  });
  return out;
}

/// Your place on the list (1 is the richest), or null if not on it.
int? eraHouseRank(Life l, EraRules era) {
  final list = eraGreatHouses(l, era).where((h) => !h.fallen).toList();
  final i = list.indexWhere((h) => h.you);
  return i < 0 ? null : i + 1;
}

/// One year of the list: your house joins it (or drops off), and the
/// great falls of the age are cried in the streets.
List<String> eraHousesYear(Life l, EraRules era) {
  final out = <String>[];
  final on = eraOnTheList(l, era);
  final was = l.eraWorld['onList'] == true;
  if (on && !was) {
    out.add(
      '${eraYourHouse(l)} is spoken of with the great houses now. Bankers bow when you pass.',
    );
    l.stats.add('happiness', 8);
    l.flags['great_house'] = Memory(l.age, 'joining the Great Houses');
  } else if (!on && was) {
    out.add('${eraYourHouse(l)} has fallen from the list of great houses.');
    l.stats.add('happiness', -6);
  }
  l.eraWorld['onList'] = on;
  if (l.age >= 12) {
    for (final h in eraGreatHouses(l, era)) {
      if (h.fallen && (era.housesData['list'] as List).any(
        (r) => (r as Map)['id'] == h.id && r['fell'] == l.year,
      )) {
        out.add('${h.name} of ${h.city}: ${eraLower(h.note ?? 'fallen')}.');
      }
    }
  }
  return out;
}
