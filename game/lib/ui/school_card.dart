import 'package:flutter/material.dart';

import '../engine/careers.dart';
import '../engine/models.dart';
import '../engine/school.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'people.dart';
import 'result_popup.dart';
import 'widgets.dart';

/// The School card on the Path tab (plan S30): grades with letters, GPA,
/// popularity, your group, teams and clubs, lessons, electives and
/// teachers you can talk to.
class SchoolCard extends StatelessWidget {
  const SchoolCard({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final sc = life.school;
    final clique = cliqueById(sc.clique);
    final teachersHere = teachers(life);
    return NFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.school_rounded, color: NF.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                inSchool(life)
                    ? (life.education == 'primary'
                          ? 'Primary school'
                          : 'Secondary school')
                    : studying(life)
                    ? '${educationLabel(life)}${sc.tier != null ? ' · ${sc.tier}' : ''}'
                    : 'Qualifications',
                style: NF.sora(16, weight: FontWeight.w700),
              ),
            ],
          ),
          if (sc.major != null &&
              (studying(life) || life.education == 'graduate'))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Major: ${sc.major}${sc.scholarship != null ? ' · ${sc.scholarship}' : ''}',
                style: NF.sora(13, color: NF.soft),
              ),
            ),
          if (sc.grades.isNotEmpty && (inSchool(life) || studying(life))) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in sc.grades.entries)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: NF.surface2,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${e.key} ${letter(e.value)}',
                      style: NF.sora(13, weight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Grades come from Smarts, effort, your teachers, Discipline and stress.',
                style: NF.sora(11, color: NF.muted),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _kv('GPA', sc.gpaYears == 0 ? '—' : sc.gpa.toStringAsFixed(2)),
          if (sc.testScore != null) _kv('Exam score', '${sc.testScore}/100'),
          if (inSchool(life)) ...[
            _kv('Popularity', '${sc.popularity}%'),
            _kv('Your group', clique?.name ?? 'None yet'),
            if (sc.clubs.isNotEmpty)
              _kv('Teams and clubs', sc.clubs.join(', ')),
            if (sc.lessons != null) _kv('Lessons', sc.lessons!),
            if (sc.electives.isNotEmpty)
              _kv('Electives', sc.electives.join(', ')),
            if (sc.detentions > 0) _kv('Detentions', '${sc.detentions} of 3'),
          ],
          if (sc.degrees.isNotEmpty) _kv('Degrees', sc.degrees.join(', ')),
          if (inSchool(life) && life.age >= 11) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  style: secondaryButton(),
                  onPressed: () => _cliques(context),
                  child: const Text('Groups'),
                ),
                if (life.education == 'secondary')
                  OutlinedButton(
                    style: secondaryButton(),
                    onPressed: () => _electives(context),
                    child: const Text('Electives'),
                  ),
              ],
            ),
          ],
          if (teachersHere.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Teachers', style: NF.sora(13, color: NF.muted)),
            const SizedBox(height: 6),
            for (final t in teachersHere)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => openPersonSheet(context, controller, t),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Avatar(
                        initials: t.name.split(' ').last.substring(0, 1),
                        size: 32,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${t.name} · ${t.role.replaceFirst('Teacher · ', '')}',
                          style: NF.sora(14, weight: FontWeight.w600),
                        ),
                      ),
                      Text('${t.bond}%', style: NF.sora(13, color: NF.soft)),
                      Icon(Icons.chevron_right_rounded, color: NF.muted),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: NF.sora(13, color: NF.muted)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: NF.sora(13, weight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );

  void _cliques(BuildContext context) {
    final life = controller.life!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NF.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            Text(
              'Groups at school',
              style: NF.sora(20, weight: FontWeight.w700),
            ),
            Text(
              'Each group has a rule to join and gives small perks every year.',
              style: NF.sora(13, color: NF.muted),
            ),
            const SizedBox(height: 12),
            for (final c in cliques)
              Builder(
                builder: (_) {
                  final lock = cliqueLock(life, c);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      c.name,
                      style: NF.sora(15, weight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      lock ??
                          'Rule: ${c.rule} · ${c.perks.entries.map((e) => '+${e.value} ${e.key}').join(', ')}',
                      style: NF.sora(
                        12,
                        color: lock == null ? NF.muted : NF.orange,
                      ),
                    ),
                    trailing: Icon(
                      lock == null
                          ? Icons.group_add_rounded
                          : Icons.lock_outline_rounded,
                      color: NF.muted,
                    ),
                    onTap: lock != null
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            final r = controller.wealth(
                              (l) => joinClique(l, c),
                            );
                            showResultPopup(
                              context,
                              r,
                              title: c.name,
                              icon: Icons.groups_rounded,
                            );
                          },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _electives(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NF.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ListenableBuilder(
        listenable: controller,
        builder: (ctx, _) {
          final picked = controller.life!.school.electives;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Electives',
                    style: NF.sora(20, weight: FontWeight.w700),
                  ),
                  Text(
                    'Pick two. Each adds a subject to your report card and a small yearly boost.',
                    style: NF.sora(13, color: NF.muted),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in electiveOptions.entries)
                        FilterChip(
                          label: Text(
                            '${e.key} (+${e.value.values.first} ${e.value.keys.first})',
                          ),
                          selected: picked.contains(e.key),
                          onSelected: (on) => controller.wealth((Life l) {
                            final list = l.school.electives;
                            if (on && list.length < 2) list.add(e.key);
                            if (!on) list.remove(e.key);
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Majors → graduate schools → careers (plan "Pathways" view).
class PathwaysCard extends StatelessWidget {
  const PathwaysCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NFCard(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text('Pathways', style: NF.sora(16, weight: FontWeight.w700)),
          subtitle: Text(
            'Which major leads where. No wiki needed.',
            style: NF.sora(12, color: NF.muted),
          ),
          children: [
            for (final (major, grad, jobs) in pathways)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(major, style: NF.sora(14, weight: FontWeight.w700)),
                    Text('Then: $grad', style: NF.sora(12, color: NF.soft)),
                    Text('Careers: $jobs', style: NF.sora(12, color: NF.muted)),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Text(
              'Graduate schools list exact entry rules (GPA, Smarts, major) when you apply.',
              style: NF.sora(11, color: NF.muted),
            ),
          ],
        ),
      ),
    );
  }
}
