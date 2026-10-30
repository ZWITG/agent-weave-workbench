/// Hidden odds: the player never sees the chance of anything. Hints,
/// choice buttons, results and the feed all pass through [hideOdds], which
/// takes out percentages that are chances ("risk about 40%", "55% chance
/// you win", "(Risk was 40%.)") and keeps the rest. Prices and rates
/// ("20% off", "3% agent fee", "2% a year") are not chances and stay.
library;

final _pct = RegExp(r'\d+(?:\.\d+)?%');

/// A clause whose percentage is a chance rather than a price or rate.
final _chance = RegExp(
  r'chance|risk|odds|success|\bwin\b|you win|accept|caught|catch|find|'
  r'detection|walk away|solitary|viral|strength|\bbase\b|^\W*\d',
  caseSensitive: false,
);

/// A clause about money: its percentage stays.
final _money = RegExp(
  r'\boff\b|a year|/yr|fee|interest|\bapr\b|\brate\b|loses|drops|deposit|'
  r'tax|return|growth|raise|instead of|value|worth|commission|cut|split|'
  r'royalt|down payment|stake|share',
  caseSensitive: false,
);

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String _clause(String p) {
  if (!_pct.hasMatch(p)) return p;
  final t = p.trimLeft();
  if (t.startsWith('Needs ') || RegExp(r'^Bond \d+%$').hasMatch(t)) return p;
  if (_money.hasMatch(p) || !_chance.hasMatch(p)) return p;
  final lead = p.length - p.trimLeft().length;
  var s = p
      .trimLeft()
      .replaceAllMapped(
        RegExp(
          r'(?:[Aa]bout |[Bb]ase )?\d+(?:\.\d+)?% (chance|success|to win|you win|they)\b',
        ),
        (m) => switch (m[1]) {
          'chance' => 'a chance',
          'success' => 'a chance of success',
          'to win' => 'a chance to win',
          'you win' => 'a chance you win',
          _ => 'a chance they',
        },
      )
      .replaceAllMapped(
        RegExp(r'^(?:[Aa]bout )?\d+(?:\.\d+)?% (\w)'),
        (m) => 'a chance of ${m[1]}',
      )
      .replaceAll(
        RegExp(
          r'\(?\b(?:[Rr]isk|[Dd]etection|[Cc]ase strength)\b(?: (?:about|was|is))? [+−-]?\d+(?:\.\d+)?%\)?',
        ),
        '',
      )
      .replaceAll(
        RegExp(r'\(?(?:[Aa]bout |[Bb]ase |[+−-])?\d+(?:\.\d+)?%\)?'),
        '',
      )
      .replaceAll(RegExp(r'\s{2,}'), ' ')
      .trim();
  if (s.isEmpty || RegExp(r'^[\W_]*$').hasMatch(s)) return '';
  return ' ' * lead + (lead == 0 ? _cap(s) : s);
}

/// The text with every chance taken out.
String hideOdds(String text) {
  if (!text.contains('%') && !text.contains('/100')) return text;
  var s = text
      // "(Risk was 40%.)", "(chance 30%)"
      .replaceAll(
        RegExp(r' ?\((?:[Rr]isk|[Oo]dds|[Cc]hance)[^()]*?\d+%[^()]*\)\.?'),
        '',
      )
      // "Conviction chance was 62%: your record, your lawyer."
      .replaceAll(RegExp(r' ?[A-Z][a-z]* chance was \d+%[^.]*\.'), '')
      // "Odds were about 40% (compatibility, Charisma, Looks)."
      .replaceAll(
        RegExp(
          r' ?(?:Why: |Your |The )?[Oo]dds were (?:about )?\d+%[^.;]*[.;]?',
        ),
        '',
      )
      // "evidence behind: 45/100", "Evidence 45/100"
      .replaceAll(RegExp(r':? ?\b\d+/100\b'), '');
  if (!s.contains('%')) return s.trim();
  final parts = s.split(' · ').map(_clause).where((p) => p.isNotEmpty);
  return parts.join(' · ').trim();
}

String? hideOddsOrNull(String? text) {
  if (text == null) return null;
  final s = hideOdds(text);
  return s.isEmpty ? null : s;
}
