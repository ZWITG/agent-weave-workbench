import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../engine/actions.dart' show ActionResult;
import '../engine/family.dart' show childrenOf;
import '../engine/lifespan.dart';
import '../engine/love.dart' show partnerOf;
import '../engine/models.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'result_popup.dart';
import 'widgets.dart';

String _cap(String s) => s[0].toUpperCase() + s.substring(1);

// ---------------- "Why did this change?" (plan ST-002) ----------------

void showStatHistory(BuildContext context, Life life, String stat) {
  final changes = life.statLog
      .where((c) => c.stat == stat)
      .toList()
      .reversed
      .take(12)
      .toList();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: NF.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_cap(stat)} ${life.stats[stat]}',
              style: NF.sora(20, weight: FontWeight.w700),
            ),
            Text('Why did this change?', style: NF.sora(13, color: NF.muted)),
            const SizedBox(height: 12),
            if (changes.isEmpty)
              Text('No changes yet.', style: NF.sora(14, color: NF.soft)),
            for (final c in changes)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    SizedBox(
                      width: 56,
                      child: Text(
                        'Age ${c.age}',
                        style: NF.sora(12, color: NF.muted),
                      ),
                    ),
                    Expanded(
                      child: Text(c.why, style: NF.sora(14, color: NF.soft)),
                    ),
                    Text(
                      c.delta > 0 ? '+${c.delta}' : '−${c.delta.abs()}',
                      style: NF.sora(
                        14,
                        weight: FontWeight.w700,
                        color: c.delta > 0
                            ? const Color(0xFF5EE6A8)
                            : NF.danger,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

// ---------------- Hidden stats as bands (plan ST-003) ----------------

String band(int v) => v >= 80
    ? 'Excellent'
    : v >= 60
    ? 'Good'
    : v >= 40
    ? 'Fair'
    : v >= 20
    ? 'Low'
    : 'Very low';

class HiddenStats extends StatelessWidget {
  const HiddenStats({super.key, required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final k in Stats.hidden)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: life.discovered.contains(k)
                  ? () => showStatHistory(context, life, k)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: NF.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _cap(k),
                        style: NF.sora(14, weight: FontWeight.w600),
                      ),
                    ),
                    life.discovered.contains(k)
                        ? Text(
                            band(life.stats[k]),
                            style: NF.sora(
                              14,
                              weight: FontWeight.w600,
                              color: NF.orange,
                            ),
                          )
                        : Text(
                            'Not discovered yet',
                            style: NF.sora(13, color: NF.muted),
                          ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------- Rewind (plan CL-021) ----------------

Future<void> showRewind(BuildContext context, GameController c) async {
  final lock = c.rewindLock;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: NF.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.history_toggle_off_rounded, color: NF.blue),
                const SizedBox(width: 8),
                Text('Rewind', style: NF.sora(20, weight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Go back to the start of an earlier year. One free Rewind per life; '
              'Plus makes it unlimited; Ironman lives cannot rewind.',
              style: NF.sora(13, color: NF.muted),
            ),
            const SizedBox(height: 12),
            if (lock != null)
              Text(lock, style: NF.sora(14, color: NF.orange))
            else
              for (final age in c.rewindAges)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.replay_rounded, color: NF.blue),
                  title: Text(
                    'Back to age $age',
                    style: NF.sora(15, weight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    c.rewindTo(age);
                  },
                ),
          ],
        ),
      ),
    ),
  );
}

// ---------------- Settings (plan SOC-SE) ----------------

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final p = controller.profile;
        final life = controller.life;
        Widget sw(String title, String sub, bool v, void Function(bool) f) =>
            SwitchListTile(
              title: Text(title, style: NF.sora(15, weight: FontWeight.w600)),
              subtitle: Text(sub, style: NF.sora(12, color: NF.muted)),
              value: v,
              onChanged: f,
            );
        return Scaffold(
          backgroundColor: NF.bg,
          appBar: AppBar(
            backgroundColor: NF.bg,
            title: Text(
              'Settings',
              style: NF.sora(18, weight: FontWeight.w700),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            children: [
              const _Head('Play'),
              sw(
                'Classic mode',
                'No energy limit on activities (otherwise 10 a year)',
                p.classic,
                (v) => controller.updateProfile((p) => p.classic = v),
              ),
              ListTile(
                title: Text(
                  'Difficulty for new lives',
                  style: NF.sora(15, weight: FontWeight.w600),
                ),
                subtitle: Wrap(
                  spacing: 8,
                  children: [
                    for (final e in difficulties.entries)
                      ChoiceChip(
                        label: Text(e.value.label),
                        selected: p.difficulty == e.key,
                        onSelected: (_) => controller.updateProfile(
                          (p) => p.difficulty = e.key,
                        ),
                      ),
                  ],
                ),
              ),
              sw(
                'Ironman for new lives',
                'No Rewind. Every choice stands.',
                p.ironman,
                (v) => controller.updateProfile((p) => p.ironman = v),
              ),
              const _Head('Content'),
              sw(
                'Show crime',
                'Crime activities and storylines',
                !p.hidden.contains('crime'),
                (v) => controller.updateProfile(
                  (p) => v ? p.hidden.remove('crime') : p.hidden.add('crime'),
                ),
              ),
              sw(
                'Show gambling',
                'Casino and lottery (in-game money only, true odds)',
                !p.hidden.contains('gambling'),
                (v) => controller.updateProfile(
                  (p) => v
                      ? p.hidden.remove('gambling')
                      : p.hidden.add('gambling'),
                ),
              ),
              sw(
                'Show violent crime',
                'Assault and armed robbery',
                !p.hidden.contains('violence'),
                (v) => controller.updateProfile(
                  (p) => v
                      ? p.hidden.remove('violence')
                      : p.hidden.add('violence'),
                ),
              ),
              const _Head('Accessibility'),
              sw(
                'Reduce motion',
                'Fewer animations and no bouncing',
                p.reduceMotion,
                (v) => controller.updateProfile((p) => p.reduceMotion = v),
              ),
              ListTile(
                title: Text(
                  'Text size',
                  style: NF.sora(15, weight: FontWeight.w600),
                ),
                subtitle: Wrap(
                  spacing: 8,
                  children: [
                    for (final (label, v) in const [
                      ('Normal', 1.0),
                      ('Large', 1.15),
                      ('Larger', 1.3),
                      ('Largest', 1.5),
                    ])
                      ChoiceChip(
                        label: Text(label),
                        selected: p.textScale == v,
                        onSelected: (_) =>
                            controller.updateProfile((p) => p.textScale = v),
                      ),
                  ],
                ),
              ),
              const _Head('Relivable Plus (test switch)'),
              sw(
                'Plus features on',
                'Unlimited Rewind, 8 generations, Destiny Mode. Real purchases arrive with the store version.',
                p.plusTest,
                (v) => controller.updateProfile((p) => p.plusTest = v),
              ),
              if (life != null) ...[
                const _Head('This life'),
                ListTile(
                  title: Text(
                    'Seed code',
                    style: NF.sora(15, weight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${seedCode(life.seed)} · share it to let someone live the same start',
                    style: NF.sora(12, color: NF.muted),
                  ),
                  trailing: IconButton(
                    tooltip: 'Copy seed code',
                    icon: const Icon(Icons.copy_rounded),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: seedCode(life.seed)),
                      );
                      showResultPopup(
                        context,
                        ActionResult(
                          'Copied ${seedCode(life.seed)}. Anyone who enters it on the New Life screen starts the same life.',
                        ),
                        title: 'Seed code copied',
                        icon: Icons.copy_rounded,
                      );
                    },
                  ),
                ),
                ListTile(
                  title: Text(
                    'Difficulty',
                    style: NF.sora(15, weight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${difficulties[life.difficulty]!.label}${life.ironman ? ' · Ironman' : ''}',
                    style: NF.sora(12, color: NF.muted),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Head extends StatelessWidget {
  const _Head(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: SectionLabel(text),
  );
}

// ---------------- Family tree (plan Social §4) ----------------

/// Me tab: earlier generations of this family, then your parents and
/// siblings, you and your partner, and your children.
class FamilyTree extends StatelessWidget {
  const FamilyTree({super.key, required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    final elders = life.npcs.where((n) => n.circle == 'Family').toList();
    final partner = partnerOf(life);
    final kids = childrenOf(life);
    return NFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_rounded, color: NF.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'The ${life.surname} family',
                  style: NF.sora(15, weight: FontWeight.w700),
                ),
              ),
              Text(
                'Generation ${life.generation}',
                style: NF.sora(12, color: NF.muted),
              ),
            ],
          ),
          for (final g in life.lineage) ...[
            _row(
              '${g['name']}',
              '${g['born']}–${g['died']} · ${g['title']}'
                  '${(g['job'] ?? '') != '' ? ' · ${g['job']}' : ''}',
              dim: true,
            ),
            _link(),
          ],
          if (elders.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final n in elders) _chip(n)],
            ),
            _link(),
          ],
          _row(
            '${life.fullName} (you)',
            [
              'Age ${life.age}',
              if (partner != null) '${partner.role}: ${partner.name}',
            ].join(' · '),
          ),
          if (kids.isNotEmpty) ...[
            _link(),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final n in kids) _chip(n)],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'No children yet. Children can carry the family on.',
                style: NF.sora(12, color: NF.muted),
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(String name, String sub, {bool dim = false}) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: NF.sora(
            14,
            weight: FontWeight.w600,
            color: dim ? NF.soft : NF.text,
          ),
        ),
        Text(sub, style: NF.sora(12, color: NF.muted)),
      ],
    ),
  );

  Widget _link() => const Padding(
    padding: EdgeInsets.only(left: 12, top: 2),
    child: SizedBox(
      height: 10,
      child: VerticalDivider(width: 2, thickness: 2, color: NF.surface2),
    ),
  );

  Widget _chip(Npc n) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: NF.surface2,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      '${n.role} · ${n.name.split(' ').first}'
      '${n.alive ? ', ${n.ageIn(life.year)}' : ' †'}',
      style: NF.sora(
        12,
        weight: FontWeight.w600,
        color: n.alive ? NF.text : NF.muted,
      ),
    ),
  );
}
