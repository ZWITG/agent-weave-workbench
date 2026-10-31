import 'package:flutter/material.dart';

import '../engine/life_events.dart' show activeAftermaths, aftermaths;

import '../engine/health.dart';
import '../engine/gangs.dart';
import '../engine/crime_jobs.dart' show crimeSkill, skillName;
import '../engine/justice.dart';
import '../engine/underworld.dart';
import '../engine/models.dart';
import '../engine/prison_life.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'activities.dart' show showBusyNotice, showEvent;
import 'widgets.dart';

/// "Need support in real life?" (plan Module 9 and Compliance): shown in
/// every mental-health context, never blocks play.
class HelplinePanel extends StatelessWidget {
  const HelplinePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final region = WidgetsBinding.instance.platformDispatcher.locale.countryCode
        ?.toUpperCase();
    final lines = <String>[
      if (region == 'US' || region == 'CA')
        '988 Suicide and Crisis Lifeline: call or text 988',
      if (region == 'GB' || region == 'IE')
        'Samaritans: call 116 123 (free, any time)',
      if (region == 'AU') 'Lifeline: call 13 11 14',
      if (region == 'NZ') 'Need to talk? Call or text 1737',
      if (region == null ||
          !{'US', 'CA', 'GB', 'IE', 'AU', 'NZ'}.contains(region)) ...[
        'US and Canada: call or text 988',
        'UK and Ireland: Samaritans 116 123',
      ],
      'Anywhere: findahelpline.com lists free, confidential lines',
    ];
    return Semantics(
      container: true,
      label: 'Need support in real life? ${lines.join('. ')}',
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: NF.blue.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: NF.blue.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.volunteer_activism_rounded, color: NF.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Need support in real life?',
                    style: NF.sora(14, weight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(l, style: NF.sora(13, color: NF.soft)),
              ),
            const SizedBox(height: 4),
            Text(
              'If you are in danger right now, call your local emergency number.',
              style: NF.sora(12, color: NF.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Health screen (plan: Body · Mind · Care).
class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final life = controller.life;
        if (life == null) return SizedBox.shrink();
        final body = life.conditions
            .where((c) => conditionInfo[c.id]?.kind != 'mind')
            .toList();
        final mind = life.conditions
            .where((c) => conditionInfo[c.id]?.kind == 'mind')
            .toList();
        return Scaffold(
          backgroundColor: NF.bg,
          appBar: AppBar(
            backgroundColor: NF.bg,
            title: Text('Health', style: NF.sora(18, weight: FontWeight.w700)),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              const SectionLabel('Body'),
              const SizedBox(height: 10),
              NFCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _bar('Health', life.stats['health']),
                    const SizedBox(height: 10),
                    _bar('Fitness', life.fitness),
                    const SizedBox(height: 6),
                    Text(
                      'Fitness falls a little every year. Workouts, walks and yoga build it; 70%+ protects your health.',
                      style: NF.sora(12, color: NF.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (body.where((c) => c.known).isEmpty)
                Text(
                  'No known conditions. A check-up can catch things early.',
                  style: NF.sora(14, color: NF.muted),
                ),
              for (final c in body.where((c) => c.known))
                _condition(context, c),
              const SizedBox(height: 18),
              SectionLabel('Mind', color: NF.blue),
              const SizedBox(height: 10),
              // What recent big moments are still doing to you.
              for (final (kind, left, who) in activeAftermaths(life))
                if (aftermaths[kind] case final a?)
                  _row(
                    context,
                    icon: a.heavy
                        ? Icons.cloud_rounded
                        : Icons.wb_sunny_rounded,
                    title: '${a.label}${who.isEmpty ? '' : ': $who'}',
                    sub:
                        '${left <= 1 ? 'Fading by your next birthday' : 'About $left more years'}${a.heavy ? ' · therapy helps it pass sooner' : ''}',
                  ),
              if (mind.isEmpty &&
                  life.addictions.isEmpty &&
                  activeAftermaths(life).isEmpty)
                Text(
                  'Nothing weighing on you right now. Stress ${life.stress}%.',
                  style: NF.sora(14, color: NF.muted),
                ),
              for (final c in mind) _condition(context, c),
              for (final e in life.addictions.entries)
                _row(
                  context,
                  icon: Icons.local_bar_rounded,
                  title: '${addictionNames[e.key]} addiction',
                  sub:
                      '${e.value} ${e.value == 1 ? 'year' : 'years'} · help is available',
                  action: 'Get help',
                  onTap: () => _open(context, 'rehab:${e.key}'),
                ),
              for (final e in life.recovery.entries)
                _row(
                  context,
                  icon: Icons.spa_rounded,
                  title: 'In recovery: ${addictionNames[e.key]!.toLowerCase()}',
                  sub: '${e.value} ${e.value == 1 ? 'year' : 'years'} clean',
                ),
              const HelplinePanel(),
              const SizedBox(height: 18),
              SectionLabel('Care', color: NF.orange),
              const SizedBox(height: 10),
              NFCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${life.country}: ${healthSystem(life)} healthcare',
                      style: NF.sora(15, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(careNote(life), style: NF.sora(13, color: NF.soft)),
                    if (healthSystem(life) != 'universal' &&
                        life.age >= 18) ...[
                      const SizedBox(height: 10),
                      PickList<String>(
                        label: 'Health insurance',
                        value: life.insurance,
                        options: [
                          for (final e in insurancePlans.entries)
                            (
                              e.key,
                              e.key == 'none'
                                  ? 'None'
                                  : '${e.value.label} · ${money(life.insurance == e.key ? insurancePremium(life) : (healthSystem(life) == 'out of pocket' ? (e.value.premium * 0.3).round() : e.value.premium))}/yr',
                            ),
                        ],
                        onPick: (v) =>
                            controller.wealth((l) => l.insurance = v),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Insurance is paid each birthday and cuts what treatment costs you.',
                        style: NF.sora(12, color: NF.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _open(BuildContext context, String scene) {
    final busy = controller.busyReason;
    if (busy != null) {
      showBusyNotice(context, controller, busy);
      return;
    }
    controller.openScene(scene);
    showEvent(context, controller);
  }

  Widget _condition(BuildContext context, Condition c) {
    final info = conditionInfo[c.id]!;
    final mind = info.kind == 'mind';
    final status = c.treated
        ? (mind ? 'Getting support' : 'Managed')
        : (mind ? 'No support yet' : 'Untreated');
    return _row(
      context,
      icon: mind ? Icons.psychology_rounded : Icons.monitor_heart_rounded,
      title: info.name,
      sub:
          '$status${info.kind == 'serious' ? ' · stage ${c.stage} of 4' : ''} · since age ${c.since}',
      action: c.treated ? null : (mind ? 'Get support' : 'Treatment'),
      onTap: () => _open(context, '${mind ? 'mind' : 'treat'}:${c.id}'),
    );
  }

  Widget _row(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String sub,
    String? action,
    VoidCallback? onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: NF.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: NF.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: NF.sora(14, weight: FontWeight.w600)),
                Text(sub, style: NF.sora(12, color: NF.muted)),
              ],
            ),
          ),
          if (action != null) TextButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    ),
  );

  Widget _bar(String label, int v) => Row(
    children: [
      SizedBox(
        width: 70,
        child: Text(label, style: NF.sora(13, color: NF.muted)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: v / 100,
            minHeight: 8,
            backgroundColor: NF.surface2,
            color: v >= 60
                ? const Color(0xFF5EE6A8)
                : v >= 30
                ? NF.orange
                : NF.danger,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text('$v%', style: NF.sora(13, weight: FontWeight.w600)),
    ],
  );
}

/// Path tab card during a sentence (plan: Prison hub) and the record.
class JusticeCard extends StatelessWidget {
  const JusticeCard({super.key, required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    final p = life.prison;
    final record = life.record.where((r) => r['sealed'] != true).toList();
    if (p == null && record.isEmpty && !onParole(life) && !isFugitive(life)) {
      return const SizedBox.shrink();
    }
    final mate = life.npc('cellmate');
    return NFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                p != null ? Icons.door_sliding_rounded : Icons.gavel_rounded,
                color: NF.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                p != null
                    ? (p.youth ? 'Youth detention' : 'Prison')
                    : 'Criminal record',
                style: NF.sora(16, weight: FontWeight.w700),
              ),
            ],
          ),
          if (p != null) ...[
            const SizedBox(height: 10),
            Text(
              '${crimeById(p.crime).label} · served ${p.served} of ${p.years} years · ${p.security} security',
              style: NF.sora(13, color: NF.soft),
            ),
            const SizedBox(height: 10),
            _meter('Behaviour', p.behaviour),
            _meter('Respect', p.respect),
            const SizedBox(height: 6),
            Text(
              [
                if (p.solitary > 0)
                  'In solitary: ${p.solitary} year${p.solitary == 1 ? '' : 's'} left',
                if (p.job != null)
                  'Job: ${p.job}${p.trustee ? ' (trustee)' : ''}',
                'Programmes: ${p.programmes}',
                if (p.courses.isNotEmpty)
                  'Courses: ${[for (final c in prisonCourses)
                    if (p.courses.contains(c.id)) c.name].join(', ')}',
                if (p.degreeYears > 0 && !p.courses.contains('degree'))
                  'Degree: year ${p.degreeYears} of 3',
                'Stash: ${p.stash}',
                if (p.gangId != null)
                  '${gangRanks[p.gangRank]} of ${gangById(p.gangId!).name} (standing ${p.gangStanding}%)',
                if (p.snitch) 'Known as a snitch',
                if (mate != null) 'Cellmate: ${mate.name} (${mate.bond}%)',
              ].join(' · '),
              style: NF.sora(12, color: NF.muted),
            ),
            const SizedBox(height: 6),
            Text(
              p.youth
                  ? 'Early release is possible after ${p.paroleAt} years with good behaviour.'
                  : p.served >= p.paroleAt
                  ? 'Parole hearings every year. Behaviour, programmes and family support help.'
                  : 'First parole hearing after ${p.paroleAt} years.',
              style: NF.sora(12, color: NF.muted),
            ),
            const SizedBox(height: 6),
            Text(
              p.solitary > 0
                  ? 'In solitary you can only read, meditate, write letters and exercise in your cell.'
                  : 'Prison activities are in the Prison category of Activities.',
              style: NF.sora(12, color: NF.blue),
            ),
          ],
          if (p == null && isFugitive(life))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'You are on the run. Working in your own name or being famous makes it easier to find you.',
                style: NF.sora(12, color: NF.muted),
              ),
            ),
          if (p == null && onParole(life))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'On parole: any new crime sends you back.',
                style: NF.sora(13, color: NF.orange),
              ),
            ),
          if (record.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final r in record)
              Text(
                '• ${crimeById(r['crime']).label} at ${r['age']} (${r['sentence']})',
                style: NF.sora(13, color: NF.soft),
              ),
            const SizedBox(height: 6),
            Text(
              'Records close some careers (police, law, teaching, medicine) and count in interviews. Minor and moderate records are expunged after ten clean years; youth records are sealed at 18.',
              style: NF.sora(12, color: NF.muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _meter(String label, int v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: NF.sora(12, color: NF.muted)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v / 100,
              minHeight: 6,
              backgroundColor: NF.surface2,
              color: NF.orange,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$v%', style: NF.sora(12, weight: FontWeight.w600)),
      ],
    ),
  );
}

/// Your criminal profile: heat with what feeds it, street skill, dirty
/// money and your crew. Shown once you have any criminal life at all.
class CrimeProfileCard extends StatefulWidget {
  const CrimeProfileCard({
    super.key,
    required this.life,
    this.startOpen = false,
  });
  final Life life;

  /// Show everything at once (the Path tab), or a one-line summary that
  /// opens on tap (the Crime category).
  final bool startOpen;

  @override
  State<CrimeProfileCard> createState() => _CrimeProfileCardState();
}

class _CrimeProfileCardState extends State<CrimeProfileCard> {
  late bool _open = widget.startOpen;
  Life get life => widget.life;

  Widget _bar(String label, int v) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: NF.sora(12, color: NF.muted)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v / 100,
              minHeight: 6,
              backgroundColor: NF.surface2,
              color: NF.orange,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final h = heat(life);
    final crew = crewOf(life);
    final skill = crimeSkill(life);
    if (h == 0 && crew == null && life.dirty <= 0 && skill == 0) {
      return const SizedBox.shrink();
    }
    Widget line(String k, String v) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(k, style: NF.sora(13, color: NF.muted)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              v,
              textAlign: TextAlign.right,
              style: NF.sora(13, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    final summary = [
      'Heat: ${heatLabel(h)}',
      skillName(skill),
      if (life.dirty > 0) '${money(life.dirty)} dirty',
      if (crew != null) crewRanks[crewRank(life)],
    ].join(' · ');
    return NFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: h >= 45 ? NF.danger : NF.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your criminal profile',
                        style: NF.sora(15, weight: FontWeight.w700),
                      ),
                      if (!_open)
                        Text(summary, style: NF.sora(12, color: NF.muted)),
                    ],
                  ),
                ),
                Icon(
                  _open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: NF.muted,
                ),
              ],
            ),
          ),
          if (_open) ...[
            const SizedBox(height: 8),
            _bar('Heat · ${heatLabel(h)}', h),
            line('Street skill', skillName(skill)),
            line('Open investigations', '${life.cases.length}'),
            if (life.dirty > 0) line('Dirty money', money(life.dirty)),
            if (crew != null) ...[
              line('Crew', crew.name),
              line('Rank', crewRanks[crewRank(life)]),
              _bar('Respect', crewRespect(life)),
              _bar('Loyalty', crewLoyalty(life)),
              if (rivalry(life) > 0) _bar('Rival crews', rivalry(life)),
              if (informant(life))
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'You are secretly informing for the police.',
                    style: NF.sora(12, color: NF.danger),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Text(
              h == 0 ? 'The police are not looking at you.' : 'Heat comes from being known to police, open cases and money you cannot explain. Lie low, change your look, launder money or let time pass to cool it.',
              style: NF.sora(12, color: NF.muted),
            ),
          ],
        ],
      ),
    );
  }
}
