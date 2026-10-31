import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/actions.dart';
import '../engine/currency.dart' show localizeMoney;
import '../engine/gangs.dart';
import '../engine/justice.dart' show crimeById;
import '../engine/prison_life.dart';
import '../engine/variants.dart' show variantsFor;
import '../game_controller.dart';
import '../theme.dart';
import 'activities.dart';
import 'health_screen.dart';
import 'hub_kit.dart';
import 'me_screens.dart';
import 'meta_screens.dart';
import 'widgets.dart';
import 'yard_time.dart';

// Inside: while you are in prison the four tabs beside Life become prison
// places. People is the Visiting room (your cellmate, your crew and who
// might still come), Path is your Case file (sentence, parole, prison job,
// courses and the ways out), Wealth is the Commissary (your stash, the yard
// price board and the money held at reception) and Me is your Inmate file
// (an ID card with a mugshot and your number). Outside life comes back the
// moment you are released.

/// The tabs while inside: icon, selected icon and stencilled name.
const insideDestinations = [
  (Icons.door_sliding_outlined, Icons.door_sliding, 'Cell'),
  (Icons.meeting_room_outlined, Icons.meeting_room, 'Visits'),
  (Icons.folder_outlined, Icons.folder, 'File'),
  (Icons.storefront_outlined, Icons.storefront, 'Canteen'),
  (Icons.badge_outlined, Icons.badge, 'ID'),
];

GameAction? _action(GameController c, String id) {
  for (final a in c.engine!.actions) {
    if (a.id == id) return a;
  }
  return null;
}

/// Action rows for [ids]; [always] ones show even when locked, so you can
/// see what it takes.
List<Widget> _rows(
  BuildContext context,
  GameController c,
  List<String> ids, {
  Set<String> always = const {},
}) {
  final life = c.life!;
  return [
    for (final id in ids)
      if (_action(c, id) case final a?)
        if (a.lockReason(life) == null || always.contains(id)) ...[
          actionRow(context, c, a, closeSheet: false),
          const SizedBox(height: 8),
        ],
  ];
}

/// A painted sign at the top of each inside tab: a stencilled name on a
/// metal plate, with a chalk line beside it.
class InsideSign extends StatelessWidget {
  const InsideSign(this.title, {super.key, required this.chalk});
  final String title;
  final String chalk;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 4),
    child: Row(
      children: [
        Flexible(
          flex: 3,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Transform.rotate(
              angle: -0.03,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 3),
                decoration: BoxDecoration(
                  color: NF.orange,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      offset: const Offset(2, 3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _rivet(),
                    const SizedBox(width: 8),
                    Text(title, style: NF.stencil(15, color: NF.bg)),
                    const SizedBox(width: 8),
                    _rivet(),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            chalk,
            style: NF.chalk(20, color: NF.soft),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  Widget _rivet() => Container(
    width: 5,
    height: 5,
    decoration: BoxDecoration(
      color: NF.bg.withValues(alpha: 0.5),
      shape: BoxShape.circle,
    ),
  );
}

/// A card with a stencilled corner label, like a form in a file.
class _Form extends StatelessWidget {
  const _Form({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
    decoration: BoxDecoration(
      color: NF.surface.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: NF.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: NF.stencil(11, color: NF.muted)),
        const SizedBox(height: 8),
        child,
      ],
    ),
  );
}

Widget _meter(String label, int v, {Color? color}) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(
    children: [
      SizedBox(
        width: 84,
        child: Text(label, style: NF.sora(12, color: NF.muted)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: v.clamp(0, 100) / 100,
            minHeight: 6,
            backgroundColor: NF.surface2,
            color: color ?? NF.orange,
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 38,
        child: Text(
          '$v%',
          textAlign: TextAlign.right,
          style: NF.sora(12, weight: FontWeight.w600),
        ),
      ),
    ],
  ),
);

Widget _line(String label, String value) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 84,
        child: Text(label, style: NF.sora(12, color: NF.muted)),
      ),
      Expanded(
        child: Text(value, style: NF.sora(13, weight: FontWeight.w600)),
      ),
    ],
  ),
);

String _years(int n) => '$n ${n == 1 ? 'year' : 'years'}';

String _initials(String name) {
  final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts.length == 1
      ? parts.first[0]
      : '${parts.first[0]}${parts.last[0]}';
}

// ---------------- Visits (People) ----------------

class VisitsTab extends StatelessWidget {
  const VisitsTab({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final l = c.life!;
    final p = l.prison!;
    final mate = l.npc('cellmate');
    final gang = p.gangId == null ? null : gangById(p.gangId!);
    final list = visitors(l)..sort((a, b) => b.bond.compareTo(a.bond));
    final banned = [for (final id in p.banned) ?l.npc(id)];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      children: [
        InsideSign(
          'VISITING ROOM',
          chalk: p.solitary > 0
              ? 'No visits in solitary'
              : 'Sundays, two till four',
        ),
        const HubHeading('Inside', sub: 'The people you share the walls with'),
        if (mate != null)
          _person(
            mate.name,
            'Cellmate · ${mate.bondLabel.toLowerCase()}',
            mate.bond,
          ),
        if (gang != null)
          _Form(
            label: 'YOUR CREW',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gang.name, style: NF.chalk(24)),
                Text(
                  '${gangRanks[p.gangRank]} · ${gang.perk}',
                  style: NF.sora(12, color: NF.soft),
                ),
                const SizedBox(height: 8),
                _meter('Standing', p.gangStanding),
                for (final r in p.rivalry.entries)
                  if (r.key != p.gangId)
                    _meter(
                      'vs ${gangById(r.key).name.replaceFirst('The ', '')}',
                      r.value,
                      color: NF.danger,
                    ),
              ],
            ),
          ),
        if (p.snitch)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                const PrisonStamp('SNITCH'),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Every crew knows. Watch your back in the yard.',
                    style: NF.sora(12, color: NF.danger),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        ..._rows(
          context,
          c,
          [
            'talk_cellmate',
            'join_gang',
            'gang_time',
            'gang_truce',
            'leave_gang',
          ],
          always: {if (gang == null) 'join_gang'},
        ),
        const HubHeading('Outside', sub: 'Who might still come'),
        ..._rows(
          context,
          c,
          ['prison_visit', 'write_letters'],
          always: {'prison_visit', 'write_letters'},
        ),
        _Form(
          label: 'VISITING LIST',
          child: list.isEmpty
              ? Text(
                  'Nobody on the list. Letters can change that.',
                  style: NF.chalk(20, color: NF.muted),
                )
              : Column(
                  children: [
                    for (final n in list.take(12))
                      _listed(n.name, n.role, n.bond >= 25),
                  ],
                ),
        ),
        if (banned.isNotEmpty)
          _Form(
            label: 'BANNED FROM VISITING',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final n in banned)
                  Text(
                    n.name,
                    style: NF
                        .sora(13, color: NF.muted)
                        .copyWith(decoration: TextDecoration.lineThrough),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _person(String name, String note, int bond) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: NF.surface2,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Avatar(initials: _initials(name), size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: NF.sora(15, weight: FontWeight.w700)),
              Text(note, style: NF.sora(12, color: NF.muted)),
            ],
          ),
        ),
        Text('$bond%', style: NF.chalk(24, color: NF.orange)),
      ],
    ),
  );

  Widget _listed(String name, String role, bool likely) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(
          likely ? Icons.check_box_outlined : Icons.check_box_outline_blank,
          size: 18,
          color: likely ? NF.orange : NF.muted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$name · $role',
            style: NF.sora(13, color: likely ? NF.text : NF.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            likely ? 'might come' : 'won\'t come',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NF.chalk(18, color: likely ? NF.soft : NF.muted),
          ),
        ),
      ],
    ),
  );
}

// ---------------- Case file (Path) ----------------

class CaseFileTab extends StatelessWidget {
  const CaseFileTab({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final l = c.life!;
    final p = l.prison!;
    final crime = crimeById(p.crime).label;
    final parole = p.youth
        ? (p.served < p.paroleAt
              ? 'Early release possible in ${_years(p.paroleAt - p.served)}'
              : 'Early release possible now')
        : p.served < p.paroleAt
        ? 'First hearing in ${_years(p.paroleAt - p.served)}'
        : 'A hearing every year';
    final past = l.record.where((r) => r['sealed'] != true).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      children: [
        InsideSign('CASE FILE', chalk: crime),
        _Form(
          label: 'SENTENCE',
          child: Column(
            children: [
              _line('Charge', crime),
              _line('Sentence', '${_years(p.years)} · ${p.security} security'),
              _line('Served', '${_years(p.served)}, ${p.left} to go'),
              _line('Out in', '${l.year + p.left}'),
              _line('Parole', parole),
              if (p.solitary > 0)
                _line('Solitary', '${_years(p.solitary)} left'),
              const SizedBox(height: 6),
              _meter('Behaviour', p.behaviour),
              _meter('Respect', p.respect),
            ],
          ),
        ),
        const HubHeading('Your days', sub: 'Work and classes count at parole'),
        if (p.job != null || p.trustee)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              [
                if (p.job != null) 'Working: ${p.job}',
                if (p.trustee) 'Trustee',
              ].join(' · '),
              style: NF.chalk(21, color: NF.soft),
            ),
          ),
        ..._rows(context, c, ['prison_job', 'prison_study']),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final course in prisonCourses)
              Container(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 3),
                decoration: BoxDecoration(
                  color: p.courses.contains(course.id)
                      ? NF.orange.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: p.courses.contains(course.id)
                        ? NF.orange
                        : NF.border,
                  ),
                ),
                child: Text(
                  '${p.courses.contains(course.id) ? '✓ ' : ''}${course.name}',
                  style: NF.sora(
                    11,
                    color: p.courses.contains(course.id) ? NF.text : NF.muted,
                  ),
                ),
              ),
          ],
        ),
        const HubHeading('Ways out', sub: 'Every one of them has a price'),
        ..._rows(
          context,
          c,
          ['appeal', 'bribe_guard', 'escape_prison'],
          always: {'appeal', 'escape_prison'},
        ),
        if (past.length > 1)
          _Form(
            label: 'PREVIOUS CONVICTIONS',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final r in past.take(past.length - 1))
                  Text(
                    '${crimeById(r['crime']).label} at ${r['age']} · ${r['sentence']}',
                    style: NF.sora(12, color: NF.soft),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------- Canteen (Wealth) ----------------

class CanteenTab extends StatelessWidget {
  const CanteenTab({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final l = c.life!;
    final p = l.prison!;
    final board = variantsFor('prison_trade');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      children: [
        const InsideSign('COMMISSARY', chalk: 'Soap, phone cards, chocolate'),
        const SizedBox(height: 12),
        // The stash: prison money, in chalk.
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: NF.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: NF.borderStrong),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STASH', style: NF.stencil(12, color: NF.muted)),
                  Text('${p.stash}', style: NF.chalk(56, color: NF.orange)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final i in [
                          Icons.soap_rounded,
                          Icons.sim_card_rounded,
                          Icons.cookie_rounded,
                          Icons.smoking_rooms_rounded,
                        ])
                          Icon(i, size: 20, color: NF.soft),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.stash >= 6 ? 'A big stash draws cell searches.' : 'Prison money. Earned in the yard, spent in the yard.',
                      style: NF.sora(12, color: NF.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // The yard's going rates, chalked on a board.
        if (board.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF16231F),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF5B4632), width: 6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Going rates', style: NF.chalk(26)),
                const SizedBox(height: 4),
                for (final v in board)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('· ', style: NF.chalk(20, color: NF.soft)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.label, style: NF.chalk(21)),
                              Text(
                                localizeMoney(v.detail),
                                style: NF.sora(11, color: NF.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        ..._rows(context, c, ['prison_trade'], always: {'prison_trade'}),
        // Outside money waits at reception.
        _Form(
          label: 'PROPERTY · HELD AT RECEPTION',
          child: Row(
            children: [
              Icon(Icons.lock_rounded, color: NF.muted, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      money(l.money),
                      style: NF.sora(18, weight: FontWeight.w700),
                    ),
                    Text(
                      'Your outside money, sealed in an envelope until you are out. Bribes still come out of it.',
                      style: NF.sora(12, color: NF.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------- ID (Me) ----------------

class InmateIdTab extends StatelessWidget {
  const InmateIdTab({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final l = c.life!;
    final p = l.prison!;
    final tags = <String>[
      p.youth ? 'YOUTH UNIT' : '${p.security.toUpperCase()} SECURITY',
      if (p.gangId != null) gangRanks[p.gangRank].toUpperCase(),
      if (p.trustee) 'TRUSTEE',
      if (p.solitary > 0) 'SOLITARY',
      if (p.snitch) 'SNITCH',
    ];
    void open(Widget screen) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      children: [
        const InsideSign('INMATE ID', chalk: 'Carry it at all times'),
        const SizedBox(height: 12),
        Semantics(
          label:
              'Inmate ${inmateNumber(l)}, ${l.fullName}, age ${l.age}, ${crimeById(p.crime).label}',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: NF.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: NF.borderStrong, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Mugshot(initials: l.initials, number: inmateNumber(l)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${inmateNumber(l)}',
                        style: NF.stencil(20, color: NF.orange),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.fullName,
                        style: NF.sora(16, weight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Age ${l.age} · in since ${l.year - p.served}',
                        style: NF.sora(12, color: NF.muted),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        crimeById(p.crime).label,
                        style: NF.chalk(22, color: NF.soft),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [for (final t in tags) _Tag(t)],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const HubHeading('Your file'),
        BrowseGrid(
          items: [
            BrowseItem(
              icon: Icons.local_hospital_rounded,
              label: 'Infirmary',
              status: 'Health ${l.stats['health']}',
              alert: l.stats['health'] < 40,
              onTap: () => open(HealthScreen(controller: c)),
            ),
            BrowseItem(
              icon: Icons.account_tree_rounded,
              label: 'Family',
              status: 'On the outside',
              onTap: () => open(
                Scaffold(
                  backgroundColor: NF.bg,
                  appBar: AppBar(
                    backgroundColor: NF.bg,
                    title: Text('Family', style: NF.stencil(16)),
                  ),
                  body: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [FamilyTree(life: l)],
                  ),
                ),
              ),
            ),
            BrowseItem(
              icon: Icons.bolt_rounded,
              label: 'Goals',
              status: 'Daily',
              onTap: () => open(GoalsScreen(controller: c)),
            ),
            BrowseItem(
              icon: Icons.emoji_events_rounded,
              label: 'Achievements',
              status: '${c.profile.achievements.length}',
              onTap: () => open(AchievementsScreen(controller: c)),
            ),
            BrowseItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              status: 'Sound, display',
              onTap: () => open(SettingsScreen(controller: c)),
            ),
          ],
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final bad = text == 'SNITCH' || text == 'SOLITARY';
    final color = bad ? NF.danger : NF.orange;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 6, 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color, width: 1.3),
      ),
      child: Text(text, style: NF.stencil(10, color: color)),
    );
  }
}

/// A mugshot: your initials against a height chart, holding a number board.
class _Mugshot extends StatelessWidget {
  const _Mugshot({required this.initials, required this.number});
  final String initials;
  final String number;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 92,
        height: 116,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _HeightChart(NF.surface2, NF.muted)),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 14,
              child: Center(child: Avatar(initials: initials, size: 52)),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3),
                color: Colors.black,
                alignment: Alignment.center,
                child: Text(number, style: NF.stencil(12, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HeightChart extends CustomPainter {
  _HeightChart(this.bg, this.line);
  final Color bg;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    final p = Paint()
      ..color = line.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 0; i * 9.0 < size.height; i++) {
      final y = i * 9.0;
      final long = i % 3 == 0;
      canvas.drawLine(
        Offset(0, y),
        Offset(long ? size.width : min(18, size.width), y),
        p..color = line.withValues(alpha: long ? 0.35 : 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_HeightChart old) => old.bg != bg || old.line != line;
}
