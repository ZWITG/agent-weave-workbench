import 'package:flutter/material.dart';

import '../engine/actions.dart';
import '../engine/careers.dart';
import '../engine/jobs.dart';
import '../engine/models.dart';
import '../engine/school.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'activities.dart';
import 'health_screen.dart' show JusticeCard;
import 'school_card.dart';
import 'widgets.dart';

/// The Path tab: where you are (school or job), the career ladder with the
/// next requirement, and every education and work option you can take.
/// Locked options fold away but always say why (plan: "no silent failure").
class PathTab extends StatefulWidget {
  const PathTab({super.key, required this.controller});
  final GameController controller;

  @override
  State<PathTab> createState() => _PathTabState();
}

class _PathTabState extends State<PathTab> {
  final _showLocked = <String>{};

  /// Job board filter: all, open or special (plan CA-007).
  String _jobFilter = 'all';

  GameController get c => widget.controller;
  Life get life => c.life!;

  static const _schoolIds = {
    'apply_uni',
    'apply_grad',
    'apprenticeship',
    'study',
    'ask_teacher',
    'tryouts',
    'lessons',
    'join_club',
    'cheat',
    'skip_class',
  };
  static const _workIds = {
    'ask_promotion',
    'work_harder',
    'slack_off',
    'chores',
    'retire',
    'bar_exam',
    'flight_school',
    'ask_raise',
    'part_time',
    'freelance',
    'quit_job',
  };

  @override
  Widget build(BuildContext context) {
    final education = [
      ...educationActions,
      ...allActions.where((a) => _schoolIds.contains(a.id)),
    ];
    final work = allActions.where((a) => _workIds.contains(a.id)).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        const SectionLabel('Your path'),
        const SizedBox(height: 10),
        if (life.prison != null ||
            life.record.any((r) => r['sealed'] != true)) ...[
          JusticeCard(life: life),
          const SizedBox(height: 10),
        ],
        _status(),
        if (careerById(life.careerId) != null) ...[
          const SizedBox(height: 10),
          _ladder(careerById(life.careerId)!),
        ],
        if (inSchool(life) ||
            studying(life) ||
            life.school.degrees.isNotEmpty) ...[
          const SizedBox(height: 10),
          SchoolCard(controller: c),
        ],
        _section(
          'Education',
          'education',
          education,
          (a) => actionRow(context, c, a, closeSheet: false),
          (a) => a.lockReason(life) == null,
        ),
        _section(
          'Work',
          'work',
          work,
          (a) => actionRow(context, c, a, closeSheet: false),
          (a) => a.lockReason(life) == null,
        ),
        const SizedBox(height: 18),
        _jobFilters(),
        _section(
          'Job board',
          'jobs',
          careers
              .where(
                (j) => switch (_jobFilter) {
                  'open' => j.lockReason(life) == null,
                  'special' => j.special,
                  _ => true,
                },
              )
              .toList(),
          _jobRow,
          (j) => j.lockReason(life) == null,
          empty: life.age < 16
              ? 'Jobs open at 16. Full-time careers open at 18.'
              : null,
        ),
        const SizedBox(height: 18),
        const PathwaysCard(),
      ],
    );
  }

  Widget _status() {
    final progress = courseProgress(life);
    final rows = <(String, String)>[
      ('Life stage', life.stage),
      (
        'Education',
        educationLabel(life) + (progress == null ? '' : ' · $progress'),
      ),
      ('Job', life.job ?? 'None'),
      ('Salary', life.salary > 0 ? '${money(life.salary)}/year' : '—'),
    ];
    return NFCard(
      child: Column(
        children: [
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(r.$1, style: NF.sora(14, color: NF.muted)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      r.$2,
                      textAlign: TextAlign.right,
                      style: NF.sora(14, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Career ladder: done steps, "you", and the next step's requirement.
  Widget _ladder(Career career) {
    final next = promotionLock(life);
    final boss = bossOf(life);
    return NFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${career.field} ladder',
            style: NF.sora(15, weight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('Performance', style: NF.sora(12, color: NF.muted)),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: life.performance / 100,
                    minHeight: 7,
                    backgroundColor: NF.surface2,
                    color: life.performance >= 60
                        ? const Color(0xFF5EE6A8)
                        : life.performance >= 30
                        ? NF.orange
                        : NF.danger,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${life.performance}%',
                style: NF.sora(12, weight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Moves with effort, ${career.keyStat}, your boss and stress.${next == null ? ' Promotion odds now: ${promotionOdds(life)}%.' : ''}${life.stress > 70 ? ' Stress is high.' : ''}',
            style: NF.sora(11, color: NF.muted),
          ),
          if (boss != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Boss: ${boss.name} (${boss.bond}%)',
                style: NF.sora(12, color: NF.soft),
              ),
            ),
          const SizedBox(height: 10),
          for (var i = 0; i < career.ladder.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    i < life.careerRank
                        ? Icons.check_circle_rounded
                        : i == life.careerRank
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: i <= life.careerRank ? NF.blue : NF.muted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          career.ladder[i],
                          style: NF.sora(
                            14,
                            weight: i == life.careerRank
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: i <= life.careerRank ? NF.text : NF.muted,
                          ),
                        ),
                        Text(
                          i == life.careerRank
                              ? 'You · ${money(career.salaryAt(i))}/year'
                              : i == life.careerRank + 1
                              ? '${money(career.salaryAt(i))}/year · ${next ?? 'Ready: ask for a promotion'}'
                              : '${money(career.salaryAt(i))}/year',
                          style: NF.sora(
                            12,
                            color: i == life.careerRank + 1 && next != null
                                ? NF.orange
                                : NF.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _jobRow(Career j) {
    final lock = j.lockReason(life);
    return OptionRow(
      icon: Icons.work_outline_rounded,
      title: j.title,
      detail:
          lock ??
          '${j.field} · ${money(j.salaryAt(0))}/year${j.special ? ' · ${j.blurb ?? 'Special career'}' : ''}',
      locked: lock != null,
      trailing: Icons.send_rounded,
      // Applying opens a 3-question interview on the Life tab.
      onTap: () => c.applyForJob(j),
    );
  }

  Widget _jobFilters() => Wrap(
    spacing: 8,
    children: [
      for (final (k, label) in const [
        ('all', 'All jobs'),
        ('open', 'Open to me'),
        ('special', 'Special careers'),
      ])
        ChoiceChip(
          label: Text(label),
          selected: _jobFilter == k,
          onSelected: (_) => setState(() => _jobFilter = k),
        ),
    ],
  );

  /// Open options first; locked ones fold under "Show n locked".
  Widget _section<T>(
    String title,
    String key,
    List<T> items,
    Widget Function(T) row,
    bool Function(T) isOpen, {
    String? empty,
  }) {
    final open = items.where(isOpen).toList();
    final locked = items.where((i) => !isOpen(i)).toList();
    final showing = _showLocked.contains(key);
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: NF.sora(17, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          if (open.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                empty ?? 'Nothing open right now. See below for why.',
                style: NF.sora(13, color: NF.muted),
              ),
            ),
          for (final i in open) ...[row(i), const SizedBox(height: 8)],
          if (locked.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(
                () => showing ? _showLocked.remove(key) : _showLocked.add(key),
              ),
              icon: Icon(
                showing ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              ),
              label: Text(
                '${showing ? 'Hide' : 'Show'} ${locked.length} locked',
              ),
            ),
          if (showing)
            for (final i in locked) ...[row(i), const SizedBox(height: 8)],
        ],
      ),
    );
  }
}
