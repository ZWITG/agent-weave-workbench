import 'package:flutter/material.dart';

import '../engine/actions.dart';
import '../engine/careers.dart';
import '../engine/jobs.dart';
import '../engine/models.dart';
import '../engine/school.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'activities.dart';
import 'hub_kit.dart';
import 'result_popup.dart';
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

  String? _page;
  String _q = '';
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<GameAction> get _education => [
    ...educationActions,
    ...allActions.where((a) => _schoolIds.contains(a.id)),
  ];

  List<GameAction> get _work =>
      allActions.where((a) => _workIds.contains(a.id)).toList();

  bool get _hasRecord =>
      life.prison != null || life.record.any((r) => r['sealed'] != true);

  void _open(String? p) => setState(() {
    _page = p;
    _search.clear();
    _q = '';
  });

  static const _pages = <String, (String, IconData, String)>{
    'school': (
      'School',
      Icons.school_rounded,
      'Classes, exams, courses and degrees',
    ),
    'career': (
      'Career',
      Icons.trending_up_rounded,
      'Your job, the next step up, raises',
    ),
    'jobs': ('Job board', Icons.work_rounded, 'Every job, open ones first'),
    'justice': (
      'Record',
      Icons.gavel_rounded,
      'Prison, parole and your criminal record',
    ),
    'pathways': (
      'Pathways',
      Icons.route_rounded,
      'Which studies lead to which careers',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final page = _page;
    if (page != null) {
      final (title, _, sub) = _pages[page]!;
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          SectionBar(
            back: 'Path',
            title: title,
            sub: sub,
            onBack: () => _open(null),
          ),
          ..._pageBody(context, page),
        ],
      );
    }
    final searching = _q.trim().isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        _status(),
        const SizedBox(height: 12),
        HubSearch(
          controller: _search,
          hint: 'Search courses and jobs',
          onChanged: (v) => setState(() => _q = v),
        ),
        if (searching)
          ..._results(context)
        else ...[
          if (_suggested(context) case final rows when rows.isNotEmpty) ...[
            const HubHeading('Suggested for you', sub: 'Your next step'),
            for (final r in rows) ...[r, const SizedBox(height: 8)],
          ],
          const HubHeading('Browse'),
          BrowseGrid(items: _browse()),
        ],
      ],
    );
  }

  List<Widget> _pageBody(BuildContext context, String page) => switch (page) {
    'school' => [
      if (inSchool(life) || studying(life) || life.school.degrees.isNotEmpty)
        SchoolCard(controller: c),
      _section(
        'Education',
        'education',
        _education,
        (a) => actionRow(context, c, a, closeSheet: false),
        (a) => a.lockReason(life) == null,
      ),
    ],
    'career' => [
      if (careerById(life.careerId) != null)
        _ladder(careerById(life.careerId)!)
      else
        Text(
          life.age < 16
              ? 'Jobs open at 16. Full-time careers open at 18.'
              : 'No job yet. The Job board lists every job and what it needs.',
          style: NF.sora(14, color: NF.muted),
        ),
      _section(
        'Work',
        'work',
        _work,
        (a) => actionRow(context, c, a, closeSheet: false),
        (a) => a.lockReason(life) == null,
      ),
    ],
    'jobs' => [
      _jobFilters(),
      _section(
        'Jobs',
        'jobs',
        careers
            .where(
              (j) => switch (_jobFilter) {
                'open' => j.lockReason(life) == null,
                'special' => j.special,
                'second' =>
                  !recordChecked.contains(j.id) && j.lockReason(life) == null,
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
    ],
    'justice' => [JusticeCard(life: life)],
    _ => [const PathwaysCard()],
  };

  List<BrowseItem> _browse() {
    final openEdu = _education.where((a) => a.lockReason(life) == null).length;
    final openJobs = careers.where((j) => j.lockReason(life) == null).length;
    return [
      BrowseItem(
        icon: Icons.school_rounded,
        label: 'School',
        status: openEdu == 0 ? educationLabel(life) : '$openEdu open',
        dim: openEdu == 0 && !inSchool(life) && !studying(life),
        onTap: () => _open('school'),
      ),
      BrowseItem(
        icon: Icons.trending_up_rounded,
        label: 'Career',
        status: life.job ?? (life.retired ? 'Retired' : 'No job'),
        dim: life.age < 14,
        onTap: () => _open('career'),
      ),
      BrowseItem(
        icon: Icons.work_rounded,
        label: 'Job board',
        status: life.age < 16 ? 'From age 16' : '$openJobs open',
        dim: openJobs == 0,
        onTap: () => _open('jobs'),
      ),
      if (_hasRecord)
        BrowseItem(
          icon: Icons.gavel_rounded,
          label: 'Record',
          status: life.prison != null ? 'In prison' : 'On file',
          alert: life.prison != null,
          onTap: () => _open('justice'),
        ),
      BrowseItem(
        icon: Icons.route_rounded,
        label: 'Pathways',
        status: 'Study to career',
        onTap: () => _open('pathways'),
      ),
    ];
  }

  /// The next step: an open course or school action, a raise or
  /// promotion, or the best-paid jobs open right now.
  List<Widget> _suggested(BuildContext context) {
    final byId = {
      for (final a in [..._education, ..._work]) a.id: a,
    };
    final ids = [
      if (inSchool(life) || studying(life)) 'study',
      if (life.age >= 17 && life.education == 'high school graduate')
        'apply_uni',
      if (life.job != null) ...['ask_promotion', 'ask_raise'],
      if (life.age >= 14 && life.age < 18 && life.job == null) 'part_time',
    ];
    final rows = <Widget>[
      for (final id in ids)
        if (byId[id] case final a? when a.lockReason(life) == null)
          actionRow(context, c, a, closeSheet: false),
    ];
    if (life.age >= 18 && life.job == null && life.prison == null) {
      final open = careers.where((j) => j.lockReason(life) == null).toList()
        ..sort((a, b) => b.salaryAt(0).compareTo(a.salaryAt(0)));
      rows.addAll(open.take(2).map(_jobRow));
    }
    return rows.take(3).toList();
  }

  List<Widget> _results(BuildContext context) {
    final actions = [
      ..._education,
      ..._work,
    ].where((a) => a.matches(_q)).toList();
    final jobs =
        careers.where((j) => matchesQuery(_q, [j.title, j.field])).toList()
          ..sort(
            (a, b) => (a.lockReason(life) == null ? 0 : 1).compareTo(
              b.lockReason(life) == null ? 0 : 1,
            ),
          );
    if (actions.isEmpty && jobs.isEmpty) {
      return [
        const SizedBox(height: 14),
        Text(
          'Nothing matches "$_q". Try "university", "nurse" or "law".',
          style: NF.sora(14, color: NF.muted),
        ),
      ];
    }
    return [
      const SizedBox(height: 14),
      for (final a in actions) ...[
        actionRow(context, c, a, closeSheet: false),
        const SizedBox(height: 8),
      ],
      for (final j in jobs.take(12)) ...[_jobRow(j), const SizedBox(height: 8)],
    ];
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
      onTap: () {
        final busy = c.busyReason;
        if (busy != null) {
          showBusyNotice(context, c, busy);
          return;
        }
        final r = c.applyForJob(j);
        if (c.pendingEvent != null) {
          showEvent(context, c);
        } else {
          showResultPopup(context, r, title: j.title, icon: Icons.work_rounded);
        }
      },
    );
  }

  Widget _jobFilters() => Wrap(
    spacing: 8,
    children: [
      for (final (k, label) in const [
        ('all', 'All jobs'),
        ('open', 'Open to me'),
        ('special', 'Special careers'),
        ('second', 'Second chance'),
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
