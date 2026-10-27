import 'package:flutter/material.dart';

import '../engine/meta.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'widgets.dart';

/// Goals and challenges (plan Social §10): three daily goals, the streak,
/// Sparks, this week's challenge and the free Archive.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final p = controller.profile;
        final now = DateTime.now();
        final week = p.activeWeek ?? currentWeek(now);
        final done = p.weeklyDone[week] ?? const [];
        return Scaffold(
          backgroundColor: NF.bg,
          appBar: AppBar(
            backgroundColor: NF.bg,
            title: Text(
              'Goals and challenges',
              style: NF.sora(18, weight: FontWeight.w700),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _stat(
                      Icons.bolt_rounded,
                      '${p.sparks}',
                      'Sparks',
                      NF.orange,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _stat(
                      Icons.local_fire_department_rounded,
                      '${p.streak}',
                      p.streak == 1 ? 'day streak' : 'day streak',
                      NF.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'A day counts when you live at least one year. One free freeze a week covers a missed day. Sparks are earned, never sold.',
                style: NF.sora(12, color: NF.muted),
              ),
              const SizedBox(height: 18),
              const SectionLabel('Today'),
              const SizedBox(height: 10),
              for (final g in goalsFor(now))
                _goal(
                  g.text,
                  goalProgress(p, g.id, now),
                  g.need,
                  goalDone(p, g.id, now),
                ),
              Text(
                '+20 Sparks each, +50 for all three. New goals every day.',
                style: NF.sora(12, color: NF.muted),
              ),
              const SizedBox(height: 18),
              SectionLabel(
                week == currentWeek(now) ? 'This week' : 'Archive challenge',
                color: NF.blue,
              ),
              const SizedBox(height: 10),
              NFCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challengeName(week),
                      style: NF.sora(17, weight: FontWeight.w700),
                    ),
                    Text(
                      'Week of $week · ${done.length} of 4 · any life counts',
                      style: NF.sora(12, color: NF.muted),
                    ),
                    const SizedBox(height: 8),
                    for (final t in challengeFor(week))
                      _goal(
                        t.text,
                        done.contains(t.id) ? 1 : 0,
                        1,
                        done.contains(t.id),
                      ),
                    Text(
                      p.challengesDone.contains(week)
                          ? 'Complete! +100 Sparks and a collection entry.'
                          : 'Finish all four for 100 Sparks. Every task can be done with free content.',
                      style: NF.sora(12, color: NF.muted),
                    ),
                    if (week != currentWeek(now))
                      TextButton(
                        onPressed: () => controller.playChallenge(null),
                        child: const Text('Back to this week'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionLabel('Archive (free)', color: NF.blue),
              const SizedBox(height: 10),
              for (final w in archiveWeeks(now))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    challengeName(w),
                    style: NF.sora(14, weight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Week of $w · ${(p.weeklyDone[w] ?? const []).length} of 4${p.challengesDone.contains(w) ? ' · done' : ''}',
                    style: NF.sora(12, color: NF.muted),
                  ),
                  trailing: TextButton(
                    onPressed: () => controller.playChallenge(w),
                    child: Text(p.activeWeek == w ? 'Playing' : 'Play'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color) =>
      NFCard(
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(value, style: NF.sora(20, weight: FontWeight.w700)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(label, style: NF.sora(12, color: NF.muted)),
            ),
          ],
        ),
      );

  Widget _goal(String text, int have, int need, bool done) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(
          done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          color: done ? const Color(0xFF5EE6A8) : NF.muted,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: NF.sora(14, color: NF.soft)),
        ),
        if (need > 1)
          Text(
            '${have.clamp(0, need)}/$need',
            style: NF.sora(13, weight: FontWeight.w600),
          ),
      ],
    ),
  );
}

/// Achievements with tiers, rules shown in-game, secrets with a hint.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final p = controller.profile;
    final cats = <String>{for (final a in achievements) a.category};
    final got = achievements.where((a) => p.achievements.containsKey(a.id));
    return Scaffold(
      backgroundColor: NF.bg,
      appBar: AppBar(
        backgroundColor: NF.bg,
        title: Text(
          'Achievements ${got.length}/${achievements.length}',
          style: NF.sora(18, weight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          for (final c in cats) ...[
            const SizedBox(height: 10),
            SectionLabel(c),
            const SizedBox(height: 6),
            for (final a in achievements.where((a) => a.category == c))
              Builder(
                builder: (_) {
                  final has = p.achievements.containsKey(a.id);
                  final hidden = a.secret && !has;
                  final color = switch (a.tier) {
                    'Legendary' => NF.orange,
                    'Rare' => NF.blue,
                    'Uncommon' => const Color(0xFF5EE6A8),
                    _ => NF.soft,
                  };
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      has ? Icons.emoji_events_rounded : Icons.lock_outline,
                      color: has ? color : NF.muted,
                    ),
                    title: Text(
                      hidden ? 'Secret' : a.name,
                      style: NF.sora(
                        14,
                        weight: FontWeight.w600,
                        color: has ? NF.text : NF.soft,
                      ),
                    ),
                    subtitle: Text(
                      hidden
                          ? 'Hint: something rare, very late in life'
                          : '${a.rule} · ${a.tier}${has ? ' · ${p.achievements[a.id]}' : ''}',
                      style: NF.sora(12, color: NF.muted),
                    ),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}

/// Collections across every life (plan Social §9).
class CollectionsScreen extends StatelessWidget {
  const CollectionsScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final p = controller.profile;
    final storyTotal = controller.engine!.storylets.length;
    return Scaffold(
      backgroundColor: NF.bg,
      appBar: AppBar(
        backgroundColor: NF.bg,
        title: Text('Collections', style: NF.sora(18, weight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          for (final e in collectionNames.entries) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: SectionLabel(e.value)),
                Text(
                  e.key == 'stories'
                      ? '${(p.collections[e.key] ?? const []).length}/$storyTotal'
                      : '${(p.collections[e.key] ?? const []).length}',
                  style: NF.sora(13, color: NF.muted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if ((p.collections[e.key] ?? const []).isEmpty)
              Text(switch (e.key) {
                'careers' => 'Get a job in any life.',
                'countries' => 'Be born somewhere, or move abroad.',
                'titles' => 'Finish a life.',
                'pets' => 'Pets you loved are remembered here.',
                'causes' => 'Finish a life.',
                'stories' => 'Live through events.',
                _ => 'Finish a weekly challenge.',
              }, style: NF.sora(13, color: NF.muted))
            else if (e.key == 'stories')
              Text(
                'You have seen ${(p.collections[e.key] ?? const []).length} of $storyTotal stories. The rest are waiting in other lives.',
                style: NF.sora(13, color: NF.soft),
              )
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final v in p.collections[e.key]!)
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
                        v,
                        style: NF.sora(12, weight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}
