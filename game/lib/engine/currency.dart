/// Money in the local currency. The game counts in dollars of the United
/// States' price level (pay and prices are already scaled per country in
/// world_data.dart); this turns those amounts into what a local would see,
/// at approximate exchange rates (2025-26).
library;

/// Local currency per US dollar, and its symbol. Countries that also call
/// their currency "dollar" get a distinct symbol so amounts are never
/// converted twice.
const currencies = <String, (double, String)>{
  'United States': (1, '\$'),
  'Portugal': (0.92, '€'),
  'Ireland': (0.92, '€'),
  'Netherlands': (0.92, '€'),
  'Germany': (0.92, '€'),
  'France': (0.92, '€'),
  'Spain': (0.92, '€'),
  'Italy': (0.92, '€'),
  'United Kingdom': (0.79, '£'),
  'Canada': (1.37, 'C\$'),
  'Australia': (1.52, 'A\$'),
  'Mexico': (18.5, 'MX\$'),
  'Argentina': (1000, 'AR\$'),
  'Brazil': (5.6, 'R\$'),
  'Japan': (150, '¥'),
  'China': (7.2, 'CN¥'),
  'South Korea': (1380, '₩'),
  'India': (85, '₹'),
  'Philippines': (57, '₱'),
  'Nigeria': (1550, '₦'),
  'South Africa': (18, 'R'),
  'Egypt': (49, 'E£'),
  'Kenya': (129, 'KSh'),
  'Sweden': (10.5, 'kr'),
};

/// The currency's name, for the move-abroad screen and moving day.
const currencyNames = <String, String>{
  'United States': 'US dollar',
  'United Kingdom': 'pound sterling',
  'Canada': 'Canadian dollar',
  'Australia': 'Australian dollar',
  'Mexico': 'Mexican peso',
  'Argentina': 'Argentine peso',
  'Brazil': 'Brazilian real',
  'Japan': 'Japanese yen',
  'China': 'Chinese yuan',
  'South Korea': 'South Korean won',
  'India': 'Indian rupee',
  'Philippines': 'Philippine peso',
  'Nigeria': 'Nigerian naira',
  'South Africa': 'South African rand',
  'Egypt': 'Egyptian pound',
  'Kenya': 'Kenyan shilling',
  'Sweden': 'Swedish krona',
};

/// "Japanese yen (¥)", or "euro (€)".
String currencyLabel(String country) =>
    '${currencyNames[country] ?? 'euro'} (${currencyOf(country).$2})';

/// The country whose currency is shown; set by the game as you play.
String activeCountry = 'United States';

/// Currencies of historical regions (eras.dart), e.g. the florin of the
/// Republic of Florence; registered when an era loads.
final Map<String, (double, String)> eraCurrencies = {};

/// Regions whose money is not written as symbol and number: English
/// pounds, shillings and pence. The formatter gets the local amount.
final Map<String, String Function(int local, {bool short})> eraFormats = {};

/// Pence as English money: "£3 6s 8d", short "£3 7s".
String lsdMoney(int pence, {bool short = false}) {
  final p = pence.abs();
  final l = p ~/ 240, s = (p % 240) ~/ 12, d = p % 12;
  final sign = pence < 0 ? '−' : '';
  if (short) {
    if (l >= 1000) return '$sign£${_digits(l)}';
    if (l > 0) return '$sign£$l${s > 0 ? ' ${s}s' : ''}';
    return '$sign${s > 0 ? '${s}s' : ''}${s > 0 && d > 0 ? ' ' : ''}${d > 0 || s == 0 ? '${d}d' : ''}';
  }
  return [
    if (l > 0) '£${_digits(l)}',
    if (s > 0) '${s}s',
    if (d > 0 || (l == 0 && s == 0)) '${d}d',
  ].join(' ').replaceFirst(RegExp('^'), sign);
}

(double, String) currencyOf(String country) =>
    eraCurrencies[country] ?? currencies[country] ?? (1, '\$');

String _digits(int v) {
  final s = v.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// A game amount in [country]'s currency ("¥1,500,000", "−€920").
/// A balance in the active currency, short: $950, $25K, $1.2M, $3.4B.
String shortMoney(int amount, [String? country]) {
  final (rate, symbol) = currencyOf(country ?? activeCountry);
  final fmt = eraFormats[country ?? activeCountry];
  if (fmt != null) return fmt((amount * rate).round(), short: true);
  final a = amount.abs() * rate;
  String f(double x, String u) =>
      '${x >= 100 ? x.toStringAsFixed(0) : x.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}$u';
  final n = a >= 1e12
      ? f(a / 1e12, 'T')
      : a >= 1e9
      ? f(a / 1e9, 'B')
      : a >= 1e6
      ? f(a / 1e6, 'M')
      : a >= 1e3
      ? f(a / 1e3, 'K')
      : a.round().toString();
  final space = symbol.length > 2 && !symbol.endsWith('\$') ? ' ' : '';
  return '${amount < 0 ? '−' : ''}$symbol$space$n';
}

String moneyIn(int amount, String country) {
  final (rate, symbol) = currencyOf(country);
  final local = (amount * rate).round();
  final fmt = eraFormats[country];
  if (fmt != null) return fmt(local);
  final space = symbol.length > 2 && !symbol.endsWith('\$') ? ' ' : '';
  return '${local < 0 ? '−' : ''}$symbol$space${_digits(local)}';
}

/// Rewrites every "$1,234" in [text] into the active currency. Symbols
/// with a letter or sign before the "$" (C$, MX$, R$...) are already local
/// and left alone.
String localizeMoney(String text, [String? country]) {
  final c = country ?? activeCountry;
  if (c == 'United States' || !text.contains('\$')) return text;
  return text.replaceAllMapped(
    RegExp(r'([−-])?(?<![A-Za-z€£¥₦₹₱₩$])\$([\d,]+)'),
    (m) {
      final v = int.tryParse(m[2]!.replaceAll(',', ''));
      if (v == null) return m[0]!;
      return moneyIn(m[1] == null ? v : -v, c);
    },
  );
}
