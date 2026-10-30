import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../engine/relationships.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'activities.dart' show OptionRow, showBusyNotice, showEvent;
import 'hub_kit.dart';
import 'result_popup.dart';
import 'widgets.dart';

/// People tab (04 Social, Module 1), shaped like the Activities panel: a
/// search box, "Suggested for you" (people who need you), and each circle
/// as a Browse tile that opens the cards with Bond % and its label.
class PeopleTab extends StatefulWidget {
  const PeopleTab({super.key, required this.controller});
  final GameController controller;

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  String? _circle;
  String _q = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  static const _icons = <String, IconData>{
    'Everyone': Icons.groups_rounded,
    'Family': Icons.family_restroom_rounded,
    'Friends': Icons.diversity_3_rounded,
    'Partner': Icons.favorite_rounded,
    'Children': Icons.child_care_rounded,
    'Exes': Icons.heart_broken_rounded,
    'Pets': Icons.pets_rounded,
    'Work': Icons.work_rounded,
    'School': Icons.school_rounded,
    'Prison': Icons.door_sliding_rounded,
    'Foster': Icons.volunteer_activism_rounded,
    'Grandchildren': Icons.child_friendly_rounded,
  };

  /// Why someone needs you, or null.
  String? _need(Life life, Npc n) {
    if (!n.alive || n.circle == 'Prison') return null;
    if (n.grudge != null) return 'Holds a grudge: ${n.grudge!.text}';
    final gap = life.age - n.lastContactAge;
    if (gap >= 3 && !n.contactCut && n.bond >= 30) {
      return 'No contact for $gap years';
    }
    if (n.bond < 30 && !n.contactCut) {
      return 'Your bond is ${n.bondLabel.toLowerCase()}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final life = widget.controller.life!;
    final circle = _circle;
    if (circle != null) {
      final people =
          life.npcs
              .where((n) => circle == 'Everyone' || n.circle == circle)
              .toList()
            ..sort((a, b) => (b.alive ? 1 : 0).compareTo(a.alive ? 1 : 0));
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        children: [
          SectionBar(
            back: 'People',
            title: circle,
            sub: people.length == 1 ? '1 person' : '${people.length} people',
            onBack: () => setState(() => _circle = null),
          ),
          for (final n in people) ...[
            _PersonCard(controller: widget.controller, npc: n),
            const SizedBox(height: 10),
          ],
          if (people.isEmpty)
            Text(
              'Nobody here yet. New people arrive through school, work, love and events.',
              style: NF.sora(14, color: NF.muted),
            ),
        ],
      );
    }
    final circles = [
      'Everyone',
      ...{for (final n in life.npcs) n.circle},
    ];
    final searching = _q.trim().isNotEmpty;
    final needs = [
      for (final n in life.npcs)
        if (_need(life, n) case final why?) (n, why),
    ]..sort((a, b) => b.$1.bond.compareTo(a.$1.bond));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      children: [
        HubSearch(
          controller: _search,
          hint: 'Find someone by name or role',
          onChanged: (v) => setState(() => _q = v),
        ),
        if (searching) ...[
          const SizedBox(height: 14),
          for (final n in life.npcs.where(
            (n) => matchesQuery(_q, [n.name, n.role, n.circle]),
          )) ...[
            _PersonCard(controller: widget.controller, npc: n),
            const SizedBox(height: 10),
          ],
          if (!life.npcs.any(
            (n) => matchesQuery(_q, [n.name, n.role, n.circle]),
          ))
            Text(
              'Nobody matches "$_q". Try a first name, "mother" or "friend".',
              style: NF.sora(14, color: NF.muted),
            ),
        ] else ...[
          if (needs.isNotEmpty) ...[
            const HubHeading('Suggested for you', sub: 'People who need you'),
            for (final (n, why) in needs.take(3)) ...[
              OptionRow(
                icon: _icons[n.circle] ?? Icons.person_rounded,
                title: '${n.name.split(' ').first} · ${n.role}',
                detail: '$why · Bond ${n.bond}%',
                onTap: () => openPersonSheet(context, widget.controller, n),
              ),
              const SizedBox(height: 8),
            ],
          ],
          const HubHeading('Browse'),
          BrowseGrid(
            items: [
              for (final c in circles)
                BrowseItem(
                  icon: _icons[c] ?? Icons.person_rounded,
                  label: c,
                  status: _status(life, c),
                  alert: needs.any((e) => c == 'Everyone' || e.$1.circle == c),
                  onTap: () => setState(() => _circle = c),
                ),
            ],
          ),
          if (life.npcs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Nobody here yet. New people arrive through school, work, love and events.',
                style: NF.sora(14, color: NF.muted),
              ),
            ),
        ],
      ],
    );
  }

  String _status(Life life, String c) {
    final people = life.npcs
        .where((n) => n.alive && (c == 'Everyone' || n.circle == c))
        .toList();
    if (people.isEmpty) return 'In memory';
    if (people.length == 1) {
      return '${people.first.name.split(' ').first} · ${people.first.bond}%';
    }
    return '${people.length} people';
  }
}

Color bondColor(int b) => b >= 65
    ? const Color(0xFF5EE6A8)
    : b >= 45
    ? NF.blue
    : b >= 30
    ? NF.orange
    : NF.danger;

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.controller, required this.npc});
  final GameController controller;
  final Npc npc;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final gap = life.age - npc.lastContactAge;
    final grudge = npc.grudge;
    return Material(
      color: NF.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => openPersonSheet(context, controller, npc),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: bondColor(npc.bond).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Avatar(initials: npc.name.substring(0, 1), size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          npc.name,
                          style: NF.sora(16, weight: FontWeight.w700),
                        ),
                        Text(
                          '${npc.role} · ${npc.alive ? npc.ageIn(life.year) : 'died'}',
                          style: NF.sora(12, color: NF.muted),
                        ),
                      ],
                    ),
                  ),
                  Semantics(
                    label: 'Bond ${npc.bond} percent, ${npc.bondLabel}',
                    excludeSemantics: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${npc.bond}%',
                          style: NF.sora(
                            18,
                            weight: FontWeight.w700,
                            color: bondColor(npc.bond),
                          ),
                        ),
                        Text(
                          npc.bondLabel,
                          style: NF.sora(12, color: NF.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: npc.bond / 100,
                  minHeight: 7,
                  backgroundColor: NF.surface2,
                  valueColor: AlwaysStoppedAnimation(bondColor(npc.bond)),
                ),
              ),
              if (grudge != null ||
                  npc.contactCut ||
                  (gap >= 3 && npc.alive) ||
                  npc.debt > 0) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (grudge != null)
                      _tag(
                        Icons.local_fire_department_rounded,
                        'Grudge: ${grudge.text}',
                        NF.danger,
                      ),
                    if (npc.contactCut)
                      _tag(Icons.block_rounded, 'Contact cut', NF.danger),
                    if (gap >= 3 && npc.alive && !npc.contactCut)
                      _tag(
                        Icons.schedule_rounded,
                        'No contact for $gap years',
                        NF.orange,
                      ),
                    if (npc.debt > 0)
                      _tag(
                        Icons.payments_rounded,
                        'Owes you ${money(npc.debt)}',
                        NF.blue,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Widget _tag(IconData icon, String text, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: color.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(999),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: color),
      const SizedBox(width: 4),
      Flexible(
        child: Text(
          text,
          style: NF.sora(12, color: color),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  ),
);

void openPersonSheet(BuildContext context, GameController controller, Npc npc) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: NF.surface,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) =>
            _PersonSheet(controller: controller, npc: npc, scroll: scroll),
      ),
    ),
  );
}

class _PersonSheet extends StatelessWidget {
  const _PersonSheet({
    required this.controller,
    required this.npc,
    required this.scroll,
  });
  final GameController controller;
  final Npc npc;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final mems = [...npc.memories]..sort((a, b) => b.age.compareTo(a.age));
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        Row(
          children: [
            Avatar(initials: npc.name.substring(0, 1), size: 52),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(npc.name, style: NF.sora(22, weight: FontWeight.w700)),
                  Text(
                    '${npc.role} · ${npc.circle} · ${npc.alive ? 'age ${npc.ageIn(life.year)}' : 'died'}',
                    style: NF.sora(13, color: NF.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        NFCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Bond', style: NF.sora(14, color: NF.muted)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${npc.bond}% · ${npc.bondLabel}',
                      textAlign: TextAlign.right,
                      style: NF.sora(
                        16,
                        weight: FontWeight.w700,
                        color: bondColor(npc.bond),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: npc.bond / 100,
                  minHeight: 8,
                  backgroundColor: NF.surface2,
                  valueColor: AlwaysStoppedAnimation(bondColor(npc.bond)),
                ),
              ),
              const SizedBox(height: 10),
              Text('Why?', style: NF.sora(13, weight: FontWeight.w700)),
              for (final w in npc.why())
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• $w', style: NF.sora(13, color: NF.soft)),
                ),
            ],
          ),
        ),
        if (npc.news.isNotEmpty) ...[
          const SizedBox(height: 16),
          SectionLabel('What ${npc.name} has been up to'),
          const SizedBox(height: 8),
          for (final line in npc.news.reversed)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $line', style: NF.sora(14, color: NF.soft)),
            ),
        ],
        const SizedBox(height: 16),
        SectionLabel('Things ${npc.name} remembers', color: NF.blue),
        const SizedBox(height: 8),
        if (mems.isEmpty)
          Text('Nothing important yet.', style: NF.sora(14, color: NF.muted)),
        for (final m in mems.take(8))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  m.negative
                      ? Icons.remove_circle_rounded
                      : Icons.add_circle_rounded,
                  size: 16,
                  color: m.negative ? NF.danger : const Color(0xFF5EE6A8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Age ${m.age} · ${controller.engine!.fill(m.text, life)}',
                    style: NF.sora(13, color: NF.soft),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        for (final g in interactionGroups) ..._group(context, g),
      ],
    );
  }

  List<Widget> _group(BuildContext context, String group) {
    final life = controller.life!;
    final items = interactions
        .where((i) => i.group == group && i.appliesTo(npc))
        .toList();
    final visible = items.where((i) => life.age <= i.maxAge).toList();
    if (visible.isEmpty) return [];
    return [
      const SizedBox(height: 8),
      SectionLabel(group),
      const SizedBox(height: 8),
      LayoutBuilder(
        builder: (context, box) {
          final w = (box.maxWidth - 10) / 2;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final i in visible)
                SizedBox(width: w, child: _card(context, i)),
            ],
          );
        },
      ),
      const SizedBox(height: 8),
    ];
  }

  Widget _card(BuildContext context, Interaction i) {
    final life = controller.life!;
    final lock = i.lockReason(life, npc);
    final faded = i.multiplier(life, npc) == 0;
    return Material(
      color: lock == null ? NF.surface2 : NF.surface2.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: lock != null
            ? null
            : () async {
                const big = {
                  'divorce',
                  'break_up',
                  'pet_rehome',
                  'cut_contact',
                };
                if (controller.profile.confirmBig && big.contains(i.id)) {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: NF.surface,
                      title: Text(
                        '${i.label}: ${npc.name}?',
                        style: NF.sora(18, weight: FontWeight.w700),
                      ),
                      content: Text(
                        'This is a big decision, and ${npc.name.split(' ').first} will remember it.',
                        style: NF.sora(14, color: NF.soft),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Not now'),
                        ),
                        FilledButton(
                          style: primaryButton(),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Yes'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true || !context.mounted) return;
                }
                final busy = controller.busyReason;
                if (busy != null) {
                  await showBusyNotice(context, controller, busy);
                  return;
                }
                final r = controller.interact(npc, i);
                // An interaction that opens a scene (a proposal, a fight...)
                // closes this sheet and shows it.
                if (controller.pendingEvent != null) {
                  showEvent(context, controller);
                  return;
                }
                showResultPopup(
                  context,
                  r,
                  title: '${i.label} · ${npc.name}',
                  icon: Icons.favorite_rounded,
                );
              },
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: lock == null ? NF.borderStrong : NF.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      i.label,
                      style: NF.sora(
                        13,
                        weight: FontWeight.w600,
                        color: lock == null ? NF.text : NF.muted,
                      ),
                    ),
                  ),
                  if (lock != null)
                    const Icon(Icons.lock_outline, size: 14, color: NF.muted),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                lock ?? i.hint(life, npc),
                style: NF.sora(
                  11,
                  color: lock != null
                      ? NF.orange
                      : (faded ? NF.orange : NF.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Person interactions that match a search ("apologize Leo", "talk to mum").
List<(Npc, Interaction)> searchInteractions(Life life, String q) => [
  for (final n in life.npcs.where((n) => n.alive))
    for (final i in interactions)
      if (life.age <= i.maxAge && i.appliesTo(n) && i.matches(q, n)) (n, i),
];
