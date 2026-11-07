import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../engine/world.dart';
import '../game_controller.dart';
import '../theme.dart';

/// The newspaper you can buy (Activities → News, or tap a headline in the
/// Life feed): this year's world, national and local stories, what they
/// mean for you, announcements from people you know and the archive.
Future<void> openNewspaper(BuildContext context, GameController c) =>
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => NewspaperScreen(controller: c),
      ),
    );

// Newsprint palette: a light page on purpose, so the paper feels like an
// object you picked up. Ink tokens keep text at AA contrast on the page.
const _paper = Color(0xFFF3EEE3);
const _ink = Color(0xFF1C1B19);
const _inkSoft = Color(0xFF4A4740);
const _rule = Color(0xFFCFC6B4);
const _accent = Color(0xFF9C3D2E);

class NewspaperScreen extends StatelessWidget {
  const NewspaperScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final world = controller.engine!.world;
    final y = life.year;
    world.ensureYear(y, life.country, life.city);
    final stories = world.storiesFor(y, life.country, life.city);
    final lead = stories.firstWhere(
      (s) => s.scope == 'global' && s.category != 'economy',
      orElse: () => stories.first,
    );
    final rest = stories.where((s) => s != lead).toList();
    final national = rest.where((s) => s.scope == life.country).toList();
    final local = rest.where((s) => s.scope == life.city).toList();
    final business = rest
        .where((s) => s.scope == 'global' && s.category == 'economy')
        .toList();
    final world2 = rest
        .where((s) => s.scope == 'global' && s.category != 'economy')
        .toList();
    // One line per kind of effect, with the latest end year.
    final effects = <String, (WorldStory, int)>{};
    for (final e in world.activeEffects(y, life.country, life.city)) {
      final prev = effects[e.$1.effect!];
      if (prev == null || e.$2 > prev.$2) effects[e.$1.effect!] = e;
    }
    final notices = [
      for (final n in life.npcs)
        for (final line in n.news)
          if (line.startsWith('Age ${life.age}:') &&
              RegExp(r'engaged|married|retired|moved|first job').hasMatch(line))
            line.substring(line.indexOf(':') + 2),
    ];
    final archive = <(int, WorldStory)>[
      for (final back in const [5, 10, 20, 30])
        for (final s
            in world.storiesFor(y - back, life.country, life.city).take(1))
          (back, s),
      for (final s in world.ledger)
        if (s.year < y - 1 && s.person != '${life.firstName} ${life.surname}')
          (y - s.year, s),
    ];
    final name = world.reputation(life.surname);

    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        foregroundColor: _ink,
        elevation: 0,
        title: Text(
          'Today\'s paper',
          style: NF.sora(15, weight: FontWeight.w600, color: _ink),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              _masthead(life),
              const SizedBox(height: 14),
              Text(
                lead.headline,
                style: NF.sora(
                  28,
                  weight: FontWeight.w800,
                  color: _ink,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                lead.body,
                style: NF.sora(16, color: _inkSoft, height: 1.55),
              ),
              if (effects.isNotEmpty) ...[
                const SizedBox(height: 18),
                _whatItMeans(effects.values.toList()),
              ],
              _section('Business'),
              for (final s in business) _story(s),
              if (world2.isNotEmpty) _section('World'),
              for (final s in world2) _story(s),
              if (national.isNotEmpty) _section(life.country),
              for (final s in national) _story(s),
              if (local.isNotEmpty) _section('Around ${life.city}'),
              for (final s in local) _story(s, highlight: s.mine),
              if (notices.isNotEmpty) ...[
                _section('Announcements'),
                for (final n in notices)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '• $n',
                      style: NF.sora(14, color: _inkSoft, height: 1.5),
                    ),
                  ),
              ],
              if (archive.isNotEmpty) ...[
                _section('From the archive'),
                for (final (back, s) in archive.take(5))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$back years ago · ${s.year}',
                          style: NF.sora(
                            11,
                            weight: FontWeight.w700,
                            color: _accent,
                          ),
                        ),
                        Text(
                          s.headline,
                          style: NF.sora(
                            15,
                            weight: FontWeight.w700,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (name != null) ...[
                _section('Names in the news'),
                Text(name, style: NF.sora(14, color: _inkSoft)),
              ],
              const SizedBox(height: 24),
              Center(
                child: Text(
                  '— ${life.city} Chronicle · ${life.year} —',
                  style: NF.sora(12, color: _inkSoft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _masthead(Life life) => Column(
    children: [
      const Divider(color: _ink, thickness: 2, height: 2),
      const SizedBox(height: 8),
      FittedBox(
        child: Text(
          'THE ${life.city.toUpperCase()} CHRONICLE',
          style: NF
              .sora(26, weight: FontWeight.w800, color: _ink)
              .copyWith(letterSpacing: 1.5),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        '${life.year} · ${life.country} edition · \$2',
        style: NF.sora(12, color: _inkSoft),
      ),
      const SizedBox(height: 8),
      const Divider(color: _ink, thickness: 1, height: 1),
    ],
  );

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Row(
      children: [
        Text(
          title.toUpperCase(),
          style: NF
              .sora(12, weight: FontWeight.w800, color: _accent)
              .copyWith(letterSpacing: 1.5),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: _rule, thickness: 1)),
      ],
    ),
  );

  Widget _story(WorldStory s, {bool highlight = false}) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: highlight ? const EdgeInsets.all(12) : EdgeInsets.zero,
    decoration: highlight
        ? BoxDecoration(
            border: Border.all(color: _accent, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          )
        : null,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (highlight)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'THAT\'S YOU',
              style: NF.sora(11, weight: FontWeight.w800, color: _accent),
            ),
          ),
        Text(
          s.headline,
          style: NF.sora(
            18,
            weight: FontWeight.w700,
            color: _ink,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 4),
        Text(s.body, style: NF.sora(14, color: _inkSoft, height: 1.5)),
      ],
    ),
  );

  Widget _whatItMeans(List<(WorldStory, int)> effects) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFE9E1D0),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHAT THIS MEANS FOR YOU',
          style: NF.sora(11, weight: FontWeight.w800, color: _accent),
        ),
        const SizedBox(height: 8),
        for (final (s, until) in effects)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '• ${worldEffects[s.effect]!.you}${until > s.year ? ' (until $until)' : ''}',
              style: NF.sora(14, color: _ink, height: 1.45),
            ),
          ),
      ],
    ),
  );
}
