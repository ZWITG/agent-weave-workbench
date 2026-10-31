import 'package:flutter/material.dart';

import '../engine/celebrity.dart';
import '../engine/social.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'result_popup.dart';
import 'widgets.dart';

/// The Social screen (plan Social §5): Fame and Followers as separate
/// meters, platform cards, a post composer that shows reach and risk
/// before you post, the verification card and your brand deal.
class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final l = controller.life;
        if (l == null) return const SizedBox.shrink();
        final (tp, tt) = trendFor(l.year);
        final income = socialIncome(l).fold(0, (a, b) => a + b.$2);
        return Scaffold(
          backgroundColor: NF.bg,
          appBar: AppBar(
            backgroundColor: NF.bg,
            title: Text('Social', style: NF.sora(18, weight: FontWeight.w700)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              NFCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: NF.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Fame ${l.fame}',
                          style: NF.sora(18, weight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Pill(fameTierOf(l).name),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: l.fame / 100,
                        minHeight: 8,
                        backgroundColor: NF.surface2,
                        color: NF.orange,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Public image: how people feel, not how many know you.
                    Row(
                      children: [
                        Icon(
                          l.image >= 0
                              ? Icons.favorite_rounded
                              : Icons.heart_broken_rounded,
                          color: l.image >= 0 ? NF.blue : NF.danger,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Public image: ${imageLabel(l.image)}',
                          style: NF.sora(15, weight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (l.image + 100) / 200,
                        minHeight: 6,
                        backgroundColor: NF.surface2,
                        color: l.image >= 0 ? NF.blue : NF.danger,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (knownFor(l).isNotEmpty)
                      Text(
                        'Known for: ${knownFor(l).join(', ')}',
                        style: NF.sora(13, color: NF.soft),
                      ),
                    Text(
                      '${fameTierOf(l).name}: ${fameTierOf(l).perks} · ${fameTierOf(l).costs}',
                      style: NF.sora(12, color: NF.muted),
                    ),
                    if (fameTiers.indexOf(fameTierOf(l)) < fameTiers.length - 1)
                      Text(
                        'Next: ${fameTiers[fameTiers.indexOf(fameTierOf(l)) + 1].name} at fame ${fameTiers[fameTiers.indexOf(fameTierOf(l)) + 1].from}',
                        style: NF.sora(12, color: NF.muted),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      'Fame is how many people know you; image is how they feel about you. Fame activities are in the Fame category of Activities.',
                      style: NF.sora(12, color: NF.muted),
                    ),
                    if (l.marks.contains('publicist') ||
                        l.marks.contains('bodyguard'))
                      Text(
                        'Staff: ${[if (l.marks.contains('publicist')) 'publicist', if (l.marks.contains('bodyguard')) 'bodyguard'].join(', ')}',
                        style: NF.sora(12, color: NF.soft),
                      ),
                    if ((l.cancelledUntil ?? 0) > l.age)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Cancelled: a comeback opens at ${l.cancelledUntil}.',
                          style: NF.sora(13, color: NF.danger),
                        ),
                      ),
                    if (l.deal != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Brand deal: ${l.deal!['brand']} · ${money(l.deal!['fee'] as int)} a year until ${l.deal!['until']} · morality clause',
                          style: NF.sora(13, color: NF.soft),
                        ),
                      ),
                    if (income > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Income from social media: about ${money(income)} a year',
                          style: NF.sora(13, color: const Color(0xFF5EE6A8)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (!l.verified) _verify(context),
              const SizedBox(height: 10),
              Text(
                'Trending this year: ${postTypeById(tt).label.toLowerCase()} posts on ${platformById(tp).name}',
                style: NF.sora(13, color: NF.blue),
              ),
              const SizedBox(height: 10),
              for (final p in platforms) ...[
                _platform(context, p),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _verify(BuildContext context) {
    final l = controller.life!;
    final reqs = verifyRequirements(l);
    final ready = reqs.every((r) => r.$2);
    return NFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Get verified', style: NF.sora(15, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          for (final (text, ok) in reqs)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    ok
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: ok ? const Color(0xFF5EE6A8) : NF.muted,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(text, style: NF.sora(13, color: NF.soft)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          FilledButton(
            style: primaryButton(),
            onPressed: ready
                ? () {
                    final r = controller.wealth(applyVerification);
                    showResultPopup(
                      context,
                      r,
                      title: 'Verified',
                      icon: Icons.verified_rounded,
                    );
                  }
                : null,
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _platform(BuildContext context, Platform p) {
    final l = controller.life!;
    final f = l.followers[p.id] ?? 0;
    final open = l.age >= p.minAge;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: open ? NF.surface : NF.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: NF.sora(16, weight: FontWeight.w700)),
                Text(
                  '${p.kind} · ${p.best}',
                  style: NF.sora(12, color: NF.muted),
                ),
                const SizedBox(height: 4),
                Text(
                  open
                      ? '${followersLabel(f)} followers · ${postsThisYear(l, p.id)} posts this year'
                      : 'Opens at ${p.minAge}',
                  style: NF.sora(13, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
          FilledButton(
            style: primaryButton(),
            onPressed: open ? () => _compose(context, p) : null,
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  void _compose(BuildContext context, Platform p) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NF.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final l = controller.life!;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          builder: (ctx, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              Text(
                'Post on ${p.name}',
                style: NF.sora(20, weight: FontWeight.w700),
              ),
              Text(
                'Each card shows its reach and risk before you post. Posting uses 1 energy.',
                style: NF.sora(13, color: NF.muted),
              ),
              const SizedBox(height: 12),
              for (final t in postTypes)
                Builder(
                  builder: (_) {
                    final lock = postLock(l, p.id, t.id);
                    final (viral, _) = viralChance(l, p.id, t.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: lock == null
                            ? NF.surface2
                            : NF.surface2.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: lock != null
                              ? null
                              : () {
                                  Navigator.pop(ctx);
                                  final r = controller.wealth(
                                    (l) => post(
                                      l,
                                      p.id,
                                      t.id,
                                      controller.engine!.rngFor(
                                        l,
                                        p.id.hashCode + t.id.hashCode,
                                      ),
                                    ),
                                  );
                                  controller.trackEvent('post');
                                  showResultPopup(
                                    context,
                                    r,
                                    title: '${p.name}: ${t.label}',
                                    icon: Icons.campaign_rounded,
                                  );
                                },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.label,
                                        style: NF.sora(
                                          14,
                                          weight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        lock ??
                                            'Reach ${reachBand(viral)} · ${t.blurb}',
                                        style: NF.sora(12, color: NF.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  lock == null
                                      ? Icons.send_rounded
                                      : Icons.lock_outline_rounded,
                                  color: NF.muted,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
