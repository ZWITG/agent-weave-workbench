import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/currency.dart';
import '../engine/era_path.dart';
import '../engine/eras.dart';
import '../engine/legends.dart';
import '../engine/models.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'legend_look.dart';
import 'result_popup.dart';
import 'widgets.dart';

/// The Path tab of an era life (Legends plan, Phase 2B): your trade and its
/// guild ladder, your schooling and reading, and the work of your city this
/// year, with every closed door saying why. Worn in the Legend's own look.
class EraPathTab extends StatefulWidget {
  const EraPathTab({super.key, required this.controller});
  final GameController controller;

  @override
  State<EraPathTab> createState() => _EraPathTabState();
}

class _EraPathTabState extends State<EraPathTab> {
  bool _showClosedJobs = false;
  bool _showClosedSchools = false;

  GameController get c => widget.controller;

  void _run(
    String title,
    String Function(Life, EraRules, Random) act, {
    IconData icon = Icons.work_outline,
  }) {
    final nav = Navigator.of(context);
    final r = c.eraAct(act);
    showResultPopup(nav.context, r, title: title, icon: icon);
  }

  @override
  Widget build(BuildContext context) {
    final life = c.life!;
    final era = eraRegistry[life.era];
    if (era == null) return const SizedBox.shrink();
    syncEraJob(life, era);
    final look = legendLookFor(life);
    final legend = legendRegistry[life.legendId];
    TextStyle hand(double s) => look == null
        ? NF.sora(s - 4, weight: FontWeight.w700, color: NF.orange)
        : legendHand(look, s);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        _workCard(life, era, legend, hand),
        const SizedBox(height: 12),
        _schoolCard(life, era, hand),
        if (legend != null) ...[
          const SizedBox(height: 12),
          NFCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your calling', style: hand(22)),
                const SizedBox(height: 6),
                Text(
                  "This is ${legend.firstName}'s life: the work follows the "
                  'story. The turning points ahead decide where it leads.',
                  style: NF.sora(13, color: NF.muted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _jobsCard(life, era, legend, hand),
      ],
    );
  }

  Widget _button(String label, VoidCallback? onTap, {bool filled = true}) =>
      Padding(
        padding: const EdgeInsets.only(top: 8, right: 8),
        child: filled
            ? FilledButton(
                style: primaryButton().copyWith(
                  minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
                ),
                onPressed: onTap,
                child: Text(label),
              )
            : OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  foregroundColor: NF.orange,
                  side: BorderSide(color: NF.orange),
                ),
                onPressed: onTap,
                child: Text(label),
              ),
      );

  Widget _workCard(
    Life life,
    EraRules era,
    Legend? legend,
    TextStyle Function(double) hand,
  ) {
    final j = eraJobOf(life, era);
    final step = eraStep(life);
    final title = legend?.chapterFor(life.year) ?? 'Your work';
    final status = [
      'Born ${eraStatusName(era, life).toLowerCase()}',
      if (eraIllegit(life)) 'outside marriage',
    ].join(', ');
    final riseLock = eraRiseLock(life, era);
    return NFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: hand(24)),
          const SizedBox(height: 6),
          if (life.job == null)
            Text(
              life.age < 10
                  ? 'Too young for work. Children of ${life.city} help at home until a master or a school takes them.'
                  : 'No work yet. The work of ${life.city} is listed below.',
              style: NF.sora(15, color: NF.soft, height: 1.35),
            )
          else
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: life.job),
                  if (life.salary > 0)
                    TextSpan(
                      text: ' · ${moneyIn(life.salary, life.country)} a year',
                      style: TextStyle(color: NF.orange),
                    ),
                ],
              ),
              style: NF.sora(15, color: NF.soft, height: 1.35),
            ),
          if (j != null) ...[
            const SizedBox(height: 10),
            _Ladder(job: j, step: step),
            const SizedBox(height: 6),
            Text(
              [
                if (j.guild != null) 'Guild: ${j.guild}.',
                '${eraYearsInTrade(life)} ${eraYearsInTrade(life) == 1 ? 'year' : 'years'} in the trade.',
                if (step < j.ladder.length - 1)
                  'Next: ${j.ladder[step + 1].title}. ${riseLock ?? 'You can try now.'}',
                if (j.note != null) j.note!,
              ].join(' '),
              style: NF.sora(13, color: NF.muted, height: 1.4),
            ),
          ],
          const SizedBox(height: 4),
          Text(status, style: NF.sora(12, color: NF.muted)),
          if (life.alive && j != null)
            Wrap(
              children: [
                if (j.extra != null)
                  _button(
                    j.extra!,
                    life.usedActions.contains('era_extra')
                        ? null
                        : () => _run(j.extra!, eraExtraWork),
                  ),
                if (step < j.ladder.length - 1)
                  _button(
                    eraRiseLabel(j, step),
                    riseLock == null
                        ? () => _run(
                            eraRiseLabel(j, step),
                            riseInEraTrade,
                            icon: Icons.workspace_premium_outlined,
                          )
                        : null,
                    filled: false,
                  ),
                if (legend == null)
                  _button(
                    'Leave',
                    () => _run('Leaving', (l, e, _) => leaveEraJob(l, e)),
                    filled: false,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String _readsLine(Life life, EraRules era) {
    final r = eraReads(life);
    final lang = era.regionOf(life).language.split(' and ').first;
    if (r.isEmpty) {
      return life.age < 6
          ? 'Too young for letters yet.'
          : 'You cannot read or write. Most people here cannot.';
    }
    final parts = [
      if (r.contains('read'))
        'read and write ${r.contains('arabic') ? 'Arabic' : lang}',
      if (r.contains('reckon')) 'reckon accounts',
      if (r.contains('latin')) 'read Latin',
    ];
    var s = 'You can ${parts.join(', ')}.';
    if (r.contains('degree')) s += ' You hold a degree.';
    if (r.contains('read') && !r.contains('latin') && !r.contains('arabic')) {
      s += ' Without Latin, the notaries and universities are closed to you.';
    }
    return s;
  }

  Widget _schoolCard(Life life, EraRules era, TextStyle Function(double) hand) {
    final s = eraSchoolOf(life, era);
    final done = [
      for (final id in eraSchoolsDone(life)) era.schoolById(id)?.name ?? id,
    ];
    final schools = eraSchoolsHere(life, era);
    final open = [
      for (final x in schools)
        if (eraSchoolLock(life, era, x) == null) x,
    ];
    // Closed schools here, and universities a journey away in this part
    // of the world.
    final closed = [
      for (final x in era.school)
        if (x != s &&
            !eraSchoolsDone(life).contains(x.id) &&
            eraSchoolLock(life, era, x) != null &&
            (eraSchoolHere(life, era, x) || _sameGroup(era, life, x)))
          x,
    ];
    final latin = eraLatinLock(life);
    final j = eraJobOf(life, era);
    return NFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Schooling', style: hand(22)),
          const SizedBox(height: 6),
          if (s != null)
            Text(
              '${s.name}: ${eraSchoolYears(life)} of ${s.years} years.',
              style: NF.sora(15, color: NF.soft, height: 1.35),
            ),
          if (done.isNotEmpty)
            Text(
              'Finished: ${done.join(', ')}.',
              style: NF.sora(15, color: NF.soft, height: 1.35),
            ),
          if (j != null && eraStep(life) == 0 && j.years.isNotEmpty)
            Text(
              'Apprenticed: ${eraYearsInStep(life)} of about ${j.years.first} years with your master.',
              style: NF.sora(15, color: NF.soft, height: 1.35),
            ),
          const SizedBox(height: 4),
          Text(
            _readsLine(life, era),
            style: NF.sora(13, color: NF.muted, height: 1.4),
          ),
          if (eraLatin(life) > 0 && !eraReads(life).contains('latin'))
            Text(
              'Teaching yourself Latin: ${eraLatin(life)}%.',
              style: NF.sora(13, color: NF.muted),
            ),
          if (life.alive)
            Wrap(
              children: [
                if (s != null) ...[
                  _button(
                    'Study hard',
                    life.usedActions.contains('era_study')
                        ? null
                        : () => _run(
                            'Study',
                            eraStudy,
                            icon: Icons.menu_book_outlined,
                          ),
                  ),
                  _button(
                    'Leave school',
                    () => _run(
                      'School',
                      (l, e, _) => leaveEraSchool(l, e),
                      icon: Icons.menu_book_outlined,
                    ),
                    filled: false,
                  ),
                ],
                if (s == null)
                  for (final x in open)
                    _button(
                      'Go to ${x.name.startsWith('A ') ? x.name.toLowerCase() : x.name}',
                      () => _run(
                        x.name,
                        (l, e, _) => enrolEraSchool(l, e, x),
                        icon: Icons.menu_book_outlined,
                      ),
                    ),
                if (latin == null ||
                    (eraLatin(life) > 0 && latin == 'Next year.'))
                  _button(
                    'Teach yourself Latin (slow)',
                    latin == null
                        ? () => _run(
                            'Latin',
                            (l, e, rng) => teachYourselfLatin(l, rng),
                            icon: Icons.menu_book_outlined,
                          )
                        : null,
                    filled: false,
                  ),
              ],
            ),
          if (closed.isNotEmpty) ...[
            const SizedBox(height: 6),
            _Fold(
              label:
                  '${closed.length} ${closed.length == 1 ? 'school' : 'schools'} closed to you',
              open: _showClosedSchools,
              onTap: () =>
                  setState(() => _showClosedSchools = !_showClosedSchools),
            ),
            if (_showClosedSchools)
              for (final x in closed)
                _Row(
                  title: x.name,
                  sub: eraSchoolLock(life, era, x)!,
                  closed: true,
                ),
          ],
        ],
      ),
    );
  }

  bool _sameGroup(EraRules era, Life life, EraSchool x) {
    final g = era.regionOf(life).group;
    return x.cities.any((c) => era.regionOfCity(c).group == g);
  }

  Widget _jobsCard(
    Life life,
    EraRules era,
    Legend? legend,
    TextStyle Function(double) hand,
  ) {
    final here = eraJobsHere(life, era);
    final current = eraJobOf(life, era);
    final open = <EraJob>[], closed = <EraJob>[];
    for (final j in here) {
      if (j == current) continue;
      (eraJobLock(life, era, j) == null ? open : closed).add(j);
    }
    // Work not found here at all is left out: it is a journey away.
    final family = era.job(life.eraPath['family'] as String? ?? '');
    Widget row(EraJob j, {required bool locked}) {
      final hub = j.hub == null ? null : (j.hubName ?? era.hubs[j.hub]);
      final lock = eraJobLock(life, era, j);
      final sub = locked
          ? lock!
          : [
              if (j.guild != null) _cap(j.guild!),
              if (j == family) 'Your family trade',
              if (j.reads.isNotEmpty)
                'Needs ${j.reads.map(eraReadName).join(' and ')}: you have it',
              if (j.entryFee > 0)
                '${moneyIn(j.entryFee, life.country)} for ${j.entryWhy ?? 'entry'}',
            ].join(' · ');
      return _Row(
        title: j.ladder.first.title,
        tag: hub == null ? null : '$hub · later',
        sub: sub.isEmpty ? '${j.ladder.length}-step ladder' : sub,
        pay: '${moneyIn(eraPay(life, era, j, 0), life.country)}/yr',
        closed: locked,
        onTap: locked || legend != null || !life.alive
            ? null
            : () =>
                  _run(j.ladder.first.title, (l, e, _) => takeEraJob(l, e, j)),
      );
    }

    return NFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Work in ${life.city}, ${life.year}', style: hand(22)),
          const SizedBox(height: 4),
          Text(
            legend != null
                ? 'What the guilds and shops of ${life.city} offer someone like you.'
                : 'Tap a trade to start at the bottom of its ladder.',
            style: NF.sora(13, color: NF.muted, height: 1.4),
          ),
          const SizedBox(height: 4),
          if (open.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                life.age < 8
                    ? 'Nothing yet: you are too young.'
                    : 'No work is open to you here this year.',
                style: NF.sora(14, color: NF.soft),
              ),
            ),
          for (final j in open) row(j, locked: false),
          if (closed.isNotEmpty) ...[
            const SizedBox(height: 4),
            _Fold(
              label:
                  '${closed.length} more closed ${closed.length == 1 ? 'job' : 'jobs'} (tap to see why)',
              open: _showClosedJobs,
              onTap: () => setState(() => _showClosedJobs = !_showClosedJobs),
            ),
            if (_showClosedJobs)
              for (final j in closed) row(j, locked: true),
          ],
        ],
      ),
    );
  }
}

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// The three steps of a guild ladder, with the current one lit.
class _Ladder extends StatelessWidget {
  const _Ladder({required this.job, required this.step});
  final EraJob job;
  final int step;

  @override
  Widget build(BuildContext context) {
    final ink = NF.text;
    final children = <Widget>[];
    for (var i = 0; i < job.ladder.length; i++) {
      if (i > 0) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: SizedBox(
              width: 22,
              child: Divider(
                thickness: 2,
                color: i <= step ? ink : ink.withValues(alpha: 0.35),
              ),
            ),
          ),
        );
      }
      final done = i < step, now = i == step;
      children.add(
        Expanded(
          child: Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: now ? NF.orange : (done ? ink : Colors.transparent),
                  border: Border.all(color: now ? NF.orange : ink, width: 2),
                  boxShadow: now
                      ? [
                          BoxShadow(
                            color: NF.orange.withValues(alpha: 0.3),
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                job.ladder[i].title,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: NF.sora(
                  11.5,
                  color: now ? NF.text : NF.muted,
                  weight: now ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _Fold extends StatelessWidget {
  const _Fold({required this.label, required this.open, required this.onTap});
  final String label;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            open ? Icons.expand_less : Icons.expand_more,
            size: 18,
            color: NF.muted,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(label, style: NF.sora(13, color: NF.muted)),
          ),
        ],
      ),
    ),
  );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.sub,
    this.tag,
    this.pay,
    this.closed = false,
    this.onTap,
  });
  final String title;
  final String sub;
  final String? tag;
  final String? pay;
  final bool closed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: closed ? 0.65 : 1,
    child: InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: NF.text.withValues(alpha: 0.18)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(title, style: NF.sora(15, weight: FontWeight.w700)),
                      if (tag != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: NF.orange),
                          ),
                          child: Text(
                            tag!,
                            style: NF.sora(11, color: NF.orange),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: closed
                        ? NF
                              .sora(12, color: NF.orange)
                              .copyWith(fontStyle: FontStyle.italic)
                        : NF.sora(12.5, color: NF.muted),
                  ),
                ],
              ),
            ),
            if (pay != null) ...[
              const SizedBox(width: 8),
              Text(pay!, style: NF.sora(13, color: NF.orange)),
            ],
            if (onTap != null)
              Icon(Icons.chevron_right, size: 20, color: NF.muted),
          ],
        ),
      ),
    ),
  );
}
