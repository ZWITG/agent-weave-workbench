import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/actions.dart';
import '../engine/currency.dart' show localizeMoney;
import '../engine/echelon.dart';
import '../engine/elite.dart' show upperEchelon, richRank, foundationFund;
import '../engine/models.dart';
import '../game_controller.dart';
import '../sound.dart';
import 'activities.dart' show runActionFlow;

// The Echelon: its own room in the game. Obsidian and gold leaf with a
// serif display face, like a private bank's letterhead or the invitation
// to a dinner you were not supposed to know about. Everything the top
// of the world offers is here: your tier and the ladder above it, the
// List of rival tycoons, influence and the power moves it pays for, a
// moonshot, your heirs, a trophy cabinet and every way to spend it.

/// The Echelon's own colours, kept apart from the everyday palette.
abstract final class Gilt {
  static const bg = Color(0xFF0C0B09);
  static const panel = Color(0xFF16140F);
  static const panel2 = Color(0xFF1F1C15);
  static const line = Color(0xFF3A3324);
  static const gold = Color(0xFFD4AF5A);
  static const goldHi = Color(0xFFF6E3A1);
  static const goldLo = Color(0xFF8C6A2A);
  static const ivory = Color(0xFFEDE6D3);
  static const muted = Color(0xFF9A9078);
  static const feud = Color(0xFFE0705A);

  static TextStyle serif(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = ivory,
    double? spacing,
    double? height,
  }) => TextStyle(
    fontFamily: 'Playfair',
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
    color: color,
    letterSpacing: spacing,
    height: height,
  );

  static TextStyle sans(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = ivory,
    double? spacing,
  }) => TextStyle(
    fontFamily: 'Sora',
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
    color: color,
    letterSpacing: spacing,
  );

  /// Small capitals with air between them, for labels.
  static TextStyle label(double size, {Color color = gold}) =>
      sans(size, weight: FontWeight.w600, color: color, spacing: size * 0.22);
}

/// Text in gold leaf, with a slow sheen across it.
class GoldLeaf extends StatefulWidget {
  const GoldLeaf(this.text, {super.key, required this.style, this.align});
  final String text;
  final TextStyle style;
  final TextAlign? align;

  @override
  State<GoldLeaf> createState() => _GoldLeafState();
}

class _GoldLeafState extends State<GoldLeaf>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _sheen.stop();
      _sheen.value = 0.5;
    } else if (!_sheen.isAnimating) {
      _sheen.repeat();
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _sheen,
    builder: (context, child) {
      final x = _sheen.value * 3 - 1.5;
      return ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) => LinearGradient(
          begin: Alignment(x - 1, -0.4),
          end: Alignment(x + 1, 0.4),
          colors: const [
            Gilt.goldLo,
            Gilt.gold,
            Gilt.goldHi,
            Gilt.gold,
            Gilt.goldLo,
          ],
          stops: const [0, 0.35, 0.5, 0.65, 1],
        ).createShader(r),
        child: child,
      );
    },
    child: Text(widget.text, style: widget.style, textAlign: widget.align),
  );
}

/// The card that leads into the Echelon (Wealth tab, Activities).
class EchelonCard extends StatelessWidget {
  const EchelonCard({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final l = controller.life!;
    if (!upperEchelon(l)) return const SizedBox.shrink();
    ensureRivals(l);
    final t = max(0, echelonTier(l));
    return Semantics(
      button: true,
      label:
          'The Echelon: ${echelonTiers[t].name}, number ${rankOf(l)} on the List. Open',
      excludeSemantics: true,
      child: Material(
        color: Gilt.bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => openEchelon(context, controller),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Gilt.goldLo),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1C1810), Gilt.bg],
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.diamond_outlined, color: Gilt.gold, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('THE ECHELON', style: Gilt.label(10)),
                      const SizedBox(height: 2),
                      GoldLeaf(
                        echelonTiers[t].name,
                        style: Gilt.serif(22, weight: FontWeight.w700),
                      ),
                      Text(
                        'No. ${rankOf(l)} on the List · influence ${influence(l)}',
                        style: Gilt.sans(12, color: Gilt.muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Gilt.gold),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void openEchelon(BuildContext context, GameController c) {
  Sound.instance.whoosh();
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => EchelonScreen(controller: c)));
}

/// Groups for everything there is to buy and do up here.
const _groups = <(String, String, IconData, List<String>)>[
  (
    'Trophies',
    'What the very rich collect',
    Icons.emoji_events_outlined,
    [
      'buy_island',
      'superyacht',
      'buy_team',
      'art_auction',
      'space_flight',
      'buy_network',
      'found_city',
    ],
  ),
  (
    'Using what you own',
    'Islands, yachts, teams and papers',
    Icons.sailing_outlined,
    [
      'island_retreat',
      'island_resort',
      'yacht_party',
      'sign_star',
      'new_stadium',
      'paper_campaign',
      'lend_art',
    ],
  ),
  (
    'Giving and legacy',
    'What your name will mean',
    Icons.account_balance_outlined,
    [
      'start_foundation',
      'foundation_gala',
      'giving_pledge',
      'name_building',
      'private_museum',
      'trust_funds',
    ],
  ),
  (
    'Press and politics',
    'The quiet kind of power',
    Icons.campaign_outlined,
    ['buy_newspaper', 'political_influence'],
  ),
  (
    'Protection',
    'Bodyguards, bunkers and passports',
    Icons.shield_outlined,
    [
      'security_detail',
      'longevity_clinic',
      'bunker',
      'second_passport',
      'offshore',
      'family_office',
    ],
  ),
];

const _powerMoves = [
  'power_lobby',
  'power_bury',
  'power_summit',
  'power_takeover',
  'power_kingmaker',
];

class EchelonScreen extends StatelessWidget {
  const EchelonScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final l = controller.life;
      if (l == null || !l.alive || !upperEchelon(l)) {
        return const Scaffold(backgroundColor: Gilt.bg);
      }
      ensureRivals(l);
      return Scaffold(
        backgroundColor: Gilt.bg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        color: Gilt.gold,
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Text(
                          'THE ECHELON',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Gilt.label(12),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  _Hero(life: l),
                  const SizedBox(height: 22),
                  _Ladder(life: l),
                  _Heading('The List', 'Updated every birthday'),
                  _ListTable(life: l),
                  _Heading('Influence', influenceLabel(influence(l))),
                  _Influence(life: l),
                  const SizedBox(height: 12),
                  ..._actions(context, l, _powerMoves),
                  _Heading('Moonshot', 'Billions, years, and history'),
                  _Moonshot(life: l),
                  const SizedBox(height: 10),
                  ..._actions(context, l, ['moonshot']),
                  _Heading(
                    'Heirs',
                    'Most fortunes are lost by the third generation',
                  ),
                  _Heirs(life: l),
                  const SizedBox(height: 10),
                  ..._actions(context, l, ['groom_heir']),
                  _Heading('Trophy cabinet', 'What you own up here'),
                  _Trophies(life: l),
                  for (final (title, sub, icon, ids) in _groups) ...[
                    _Heading(title, sub, icon: icon),
                    ..._actions(context, l, ids),
                  ],
                  _Heading('Where you stand', ''),
                  ..._actions(context, l, ['rich_list']),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  List<Widget> _actions(BuildContext context, Life l, List<String> ids) {
    final byId = {for (final a in controller.engine!.actions) a.id: a};
    return [
      for (final id in ids)
        if (byId[id] case final a?) ...[
          _GiltAction(
            action: a,
            life: l,
            onTap: () =>
                runActionFlow(context, controller, a, closeSheet: false),
          ),
          const SizedBox(height: 8),
        ],
    ];
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title, this.sub, {this.icon});
  final String title;
  final String sub;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 18, height: 1, color: Gilt.goldLo),
            const SizedBox(width: 8),
            if (icon != null) ...[
              Icon(icon, size: 16, color: Gilt.gold),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                title,
                style: Gilt.serif(22, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (sub.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 26, top: 2),
            child: Text(sub, style: Gilt.sans(12, color: Gilt.muted)),
          ),
      ],
    ),
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    final t = max(0, echelonTier(life));
    final legacy = legacyScore(life);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Gilt.goldLo),
        gradient: const RadialGradient(
          center: Alignment(-0.6, -0.9),
          radius: 1.4,
          colors: [Color(0xFF2A2314), Gilt.bg],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            life.fullName.toUpperCase(),
            style: Gilt.label(11, color: Gilt.muted),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: GoldLeaf(
              echelonTiers[t].name,
              style: Gilt.serif(38, weight: FontWeight.w700, height: 1.05),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            bigMoney(life.netWorth),
            style: Gilt.serif(28, weight: FontWeight.w500),
          ),
          Text(
            'You are ${richRank(life)}.',
            style: Gilt.sans(13, color: Gilt.muted),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip('No. ${rankOf(life)} on the List'),
              _Chip('Influence ${influence(life)}'),
              _Chip('Legacy: ${legacyLabel(legacy)}'),
              if (life.flags.containsKey('richest_alive'))
                const _Chip('Once the richest alive'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Gilt.line),
      color: Gilt.panel,
    ),
    child: Text(text, style: Gilt.sans(12, color: Gilt.ivory)),
  );
}

/// The six tiers as a ladder of gold studs, with the way to the next.
class _Ladder extends StatelessWidget {
  const _Ladder({required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    final now = max(0, echelonTier(life));
    final next = now < 4 ? now + 1 : null;
    final toGo = next == null ? 0 : echelonTiers[next].floor - life.netWorth;
    final progress = next == null
        ? 1.0
        : ((life.netWorth - echelonTiers[now].floor) /
                  (echelonTiers[next].floor - echelonTiers[now].floor))
              .clamp(0.0, 1.0);
    return Semantics(
      label:
          'Tier ${now + 1} of ${echelonTiers.length}: ${echelonTiers[now].name}.${next == null ? '' : ' ${bigMoney(toGo)} to ${echelonTiers[next].name}.'}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 52,
            child: LayoutBuilder(
              builder: (context, box) {
                final n = echelonTiers.length;
                final step = box.maxWidth / n;
                return Stack(
                  children: [
                    Positioned(
                      left: step / 2,
                      right: step / 2,
                      top: 11,
                      child: Container(height: 1.5, color: Gilt.line),
                    ),
                    Positioned(
                      left: step / 2,
                      width: step * now,
                      top: 11,
                      child: Container(height: 1.5, color: Gilt.gold),
                    ),
                    for (var i = 0; i < n; i++)
                      Positioned(
                        left: step * i,
                        width: step,
                        top: 0,
                        child: Column(
                          children: [
                            Container(
                              width: i == now ? 24 : 14,
                              height: i == now ? 24 : 14,
                              margin: EdgeInsets.only(top: i == now ? 0 : 5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: i <= now ? Gilt.gold : Gilt.panel,
                                border: Border.all(
                                  color: i <= now ? Gilt.goldHi : Gilt.line,
                                  width: i == now ? 3 : 1.5,
                                ),
                                boxShadow: i == now
                                    ? [
                                        BoxShadow(
                                          color: Gilt.gold.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: 12,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                            SizedBox(height: i == now ? 4 : 9),
                            Text(
                              i == 5 ? '#1' : bigMoney(echelonTiers[i].floor),
                              style: Gilt.sans(
                                10,
                                weight: i == now
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: i <= now ? Gilt.gold : Gilt.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (next != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${bigMoney(toGo)} to ${echelonTiers[next].name}',
                    style: Gilt.sans(13, weight: FontWeight.w600),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: Gilt.sans(12, color: Gilt.muted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: Gilt.panel2,
                color: Gilt.gold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Unlocks: ${echelonTiers[next].unlocks}',
              style: Gilt.sans(12, color: Gilt.muted),
            ),
          ] else
            Text(
              rankOf(life) == 1
                  ? 'There is nowhere higher.'
                  : 'Only the top of the List is left.',
              style: Gilt.serif(16, color: Gilt.gold),
            ),
        ],
      ),
    );
  }
}

class _ListTable extends StatelessWidget {
  const _ListTable({required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    final rows = theList(life);
    return Container(
      decoration: BoxDecoration(
        color: Gilt.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Gilt.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: BoxDecoration(
                color: rows[i].you
                    ? Gilt.gold.withValues(alpha: 0.12)
                    : Colors.transparent,
                border: Border(
                  top: i == 0
                      ? BorderSide.none
                      : const BorderSide(color: Gilt.line, width: 0.6),
                  left: rows[i].you
                      ? const BorderSide(color: Gilt.gold, width: 3)
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${i + 1}',
                      style: Gilt.serif(
                        18,
                        weight: FontWeight.w700,
                        color: i == 0 ? Gilt.gold : Gilt.muted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rows[i].you ? '${rows[i].name} (you)' : rows[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Gilt.sans(
                            14,
                            weight: rows[i].you
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: rows[i].you ? Gilt.goldHi : Gilt.ivory,
                          ),
                        ),
                        Text(
                          rows[i].sector,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Gilt.sans(11, color: Gilt.muted),
                        ),
                      ],
                    ),
                  ),
                  if (rows[i].feud >= 25) ...[
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 16,
                      color: rows[i].feud >= 50 ? Gilt.feud : Gilt.muted,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    bigMoney(rows[i].worth),
                    style: Gilt.serif(15, weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Influence extends StatelessWidget {
  const _Influence({required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    final v = influence(life);
    return Row(
      children: [
        SizedBox(
          width: 120,
          height: 70,
          child: CustomPaint(
            painter: _Gauge(v / 100),
            child: Align(
              alignment: const Alignment(0, 0.9),
              child: Text('$v', style: Gilt.serif(26, weight: FontWeight.w700)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            'Earned by your newspaper, your foundation, your politics and your place on the List; it fades if you never use it. Spend it on the moves below.',
            style: Gilt.sans(12, color: Gilt.muted),
          ),
        ),
      ],
    );
  }
}

class _Gauge extends CustomPainter {
  _Gauge(this.value);
  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromCircle(
      center: Offset(size.width / 2, size.height),
      radius: size.width / 2 - 6,
    );
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..color = Gilt.panel2;
    canvas.drawArc(r, pi, pi, false, base);
    canvas.drawArc(
      r,
      pi,
      pi * value.clamp(0.0, 1.0),
      false,
      base
        ..shader = const SweepGradient(
          startAngle: pi,
          endAngle: 2 * pi,
          colors: [Gilt.goldLo, Gilt.goldHi],
        ).createShader(r),
    );
  }

  @override
  bool shouldRepaint(_Gauge old) => old.value != value;
}

class _Moonshot extends StatelessWidget {
  const _Moonshot({required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    final m = activeMoonshot(life);
    final done = moonshotsDone(life);
    if (m == null && done.isEmpty) {
      return Text(
        echelonTier(life) >= 3
            ? 'No project running. Pick one below: the odds are real.'
            : 'Opens at ${echelonTiers[3].name.toLowerCase()} (${bigMoney(echelonTiers[3].floor)}).',
        style: Gilt.sans(13, color: Gilt.muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (m != null)
          Builder(
            builder: (context) {
              final s = moonshotById(m['id'] as String);
              final year = m['year'] as int;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Gilt.panel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Gilt.goldLo),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.rocket_launch_outlined,
                          color: Gilt.gold,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s.name,
                            style: Gilt.serif(20, weight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          'Year $year of ${s.years}',
                          style: Gilt.sans(12, color: Gilt.muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: year / s.years,
                        minHeight: 6,
                        backgroundColor: Gilt.panel2,
                        color: Gilt.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${bigMoney(moonshotYearly(life))} a year until it is done',
                      style: Gilt.sans(12, color: Gilt.muted),
                    ),
                  ],
                ),
              );
            },
          ),
        if (done.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in done) _Chip('✦ ${moonshotById(id).name}'),
            ],
          ),
        ],
      ],
    );
  }
}

class _Heirs extends StatelessWidget {
  const _Heirs({required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    final heirs = adultHeirs(life);
    if (heirs.isEmpty) {
      return Text(
        'No heirs old enough to prepare yet. Without one, the fortune goes where your will says.',
        style: Gilt.sans(13, color: Gilt.muted),
      );
    }
    return Column(
      children: [
        for (final h in heirs)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    h.name.split(' ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Gilt.sans(14, weight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: readiness(life, h) / 100,
                      minHeight: 6,
                      backgroundColor: Gilt.panel2,
                      color: readiness(life, h) >= 70
                          ? Gilt.gold
                          : readiness(life, h) >= 30
                          ? Gilt.goldLo
                          : Gilt.feud,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 70,
                  child: Text(
                    readiness(life, h) >= 70
                        ? 'Ready'
                        : readiness(life, h) >= 30
                        ? 'Learning'
                        : 'Unprepared',
                    textAlign: TextAlign.right,
                    style: Gilt.sans(12, color: Gilt.muted),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Trophies extends StatelessWidget {
  const _Trophies({required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      for (final a in life.assets)
        if (const {
              'island',
              'team',
              'media',
              'bunker',
              'city',
            }.contains(a.kind) ||
            a.name == 'Superyacht' ||
            (a.kind == 'valuable' && a.value >= 10000000))
          (
            switch (a.kind) {
              'island' => Icons.beach_access_outlined,
              'team' => Icons.sports_soccer_outlined,
              'media' => Icons.newspaper_outlined,
              'bunker' => Icons.shield_outlined,
              'city' => Icons.location_city_outlined,
              'valuable' => Icons.palette_outlined,
              _ => Icons.sailing_outlined,
            },
            a.name,
            bigMoney(a.value),
          ),
      if (life.flags.containsKey('museum'))
        (Icons.museum_outlined, 'Your museum', 'Free on Sundays'),
      if (life.flags.containsKey('endowed'))
        (Icons.school_outlined, '${life.surname} Hall', 'Named for a century'),
      if (foundationFund(life) > 0)
        (
          Icons.volunteer_activism_outlined,
          'Your foundation',
          bigMoney(foundationFund(life)),
        ),
      for (final id in moonshotsDone(life))
        (
          Icons.auto_awesome_outlined,
          moonshotById(id).name,
          'In the history books',
        ),
    ];
    if (items.isEmpty) {
      return Text(
        'Empty glass shelves, waiting. Start with something below.',
        style: Gilt.sans(13, color: Gilt.muted),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth > 420 ? 3 : 2;
        final w = (box.maxWidth - (cols - 1) * 10) / cols;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (icon, name, note) in items)
              Container(
                width: w,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Gilt.line),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Gilt.panel2, Gilt.panel],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: Gilt.gold, size: 22),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Gilt.sans(13, weight: FontWeight.w600),
                    ),
                    Text(note, style: Gilt.sans(11, color: Gilt.muted)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GiltAction extends StatelessWidget {
  const _GiltAction({
    required this.action,
    required this.life,
    required this.onTap,
  });
  final GameAction action;
  final Life life;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final lock = action.lockReason(life);
    final detail = localizeMoney(
      lock ?? action.hintFor(life) ?? action.priceNote ?? '',
    );
    return Semantics(
      button: lock == null,
      label: '${action.label}. $detail',
      excludeSemantics: true,
      child: Material(
        color: lock == null ? Gilt.panel : Gilt.panel.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: lock == null
              ? () {
                  Sound.instance.tap();
                  onTap();
                }
              : null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: lock == null
                    ? Gilt.line
                    : Gilt.line.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  lock == null
                      ? Icons.diamond_outlined
                      : Icons.lock_outline_rounded,
                  size: 18,
                  color: lock == null ? Gilt.gold : Gilt.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.label,
                        style: Gilt.sans(
                          14,
                          weight: FontWeight.w600,
                          color: lock == null ? Gilt.ivory : Gilt.muted,
                        ),
                      ),
                      if (detail.isNotEmpty)
                        Text(detail, style: Gilt.sans(12, color: Gilt.muted)),
                    ],
                  ),
                ),
                if (lock == null)
                  const Icon(Icons.chevron_right_rounded, color: Gilt.goldLo),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The Gilded look's seam: a thin line of molten gold along the top of the
/// game, with a slow shine running along it and a few drips hanging off.
class GoldSeam extends StatefulWidget {
  const GoldSeam({super.key});

  @override
  State<GoldSeam> createState() => _GoldSeamState();
}

class _GoldSeamState extends State<GoldSeam>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shine = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _shine.stop();
      _shine.value = 0.3;
    } else if (!_shine.isAnimating) {
      _shine.repeat();
    }
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      height: 12,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _shine,
        builder: (context, _) =>
            CustomPaint(painter: _SeamPainter(_shine.value)),
      ),
    ),
  );
}

class _SeamPainter extends CustomPainter {
  _SeamPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final line = Rect.fromLTWH(0, 0, w, 2.5);
    canvas.drawRect(
      line,
      Paint()
        ..shader = LinearGradient(
          colors: const [
            Gilt.goldLo,
            Gilt.gold,
            Gilt.goldHi,
            Gilt.gold,
            Gilt.goldLo,
          ],
          stops: [
            0,
            (t - 0.12).clamp(0.0, 1.0),
            t,
            (t + 0.12).clamp(0.0, 1.0),
            1,
          ],
        ).createShader(line),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, 4),
      Paint()
        ..color = Gilt.gold.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Drips that have set where the gold ran over the edge.
    final rng = Random(5);
    for (var x = 18.0; x < w; x += 46 + rng.nextDouble() * 70) {
      final len = 3 + rng.nextDouble() * 6;
      final r = 1.4 + rng.nextDouble() * 1.4;
      final drip = RRect.fromRectAndCorners(
        Rect.fromLTWH(x - r, 1, r * 2, len),
        bottomLeft: Radius.circular(r),
        bottomRight: Radius.circular(r),
      );
      canvas.drawRRect(
        drip,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Gilt.gold, Gilt.goldHi],
          ).createShader(drip.outerRect),
      );
    }
  }

  @override
  bool shouldRepaint(_SeamPainter old) => old.t != t;
}
