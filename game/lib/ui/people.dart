import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../engine/relationships.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'widgets.dart';

/// People tab (04 Social, Module 1): circles as chips, one card per person
/// with Bond % and its label, and a Person sheet with interactions.
class PeopleTab extends StatefulWidget {
  const PeopleTab({super.key, required this.controller});
  final GameController controller;

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  String _circle = 'All';

  @override
  Widget build(BuildContext context) {
    final life = widget.controller.life!;
    final circles = [
      'All',
      ...{for (final n in life.npcs) n.circle},
    ];
    final people =
        life.npcs.where((n) => _circle == 'All' || n.circle == _circle).toList()
          ..sort((a, b) => (b.alive ? 1 : 0).compareTo(a.alive ? 1 : 0));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      children: [
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final c in circles)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: _circle == c,
                    onSelected: (_) => setState(() => _circle = c),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
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
                  const Spacer(),
                  Text(
                    '${npc.bond}% · ${npc.bondLabel}',
                    style: NF.sora(
                      16,
                      weight: FontWeight.w700,
                      color: bondColor(npc.bond),
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
    final items = interactions.where((i) => i.group == group).toList();
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
            : () {
                final r = controller.interact(npc, i);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      r.notes.isEmpty
                          ? r.text
                          : '${r.text}\n${r.notes.join(' · ')}',
                    ),
                  ),
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
      if (life.age <= i.maxAge && i.matches(q, n)) (n, i),
];
