import 'package:flutter/material.dart';

import '../engine/models.dart';
import '../engine/past.dart' show historyColumn;
import '../engine/world.dart';
import '../game_controller.dart';
import '../theme.dart';

/// The newspaper you can buy (Activities → News, or tap a headline in the
/// Life feed): this year's world, national and local stories, what they
/// mean for you, announcements from people you know and the archive.
/// [year] opens a back issue instead of today's paper.
Future<void> openNewspaper(
  BuildContext context,
  GameController c, {
  int? year,
}) => Navigator.of(context).push(
  MaterialPageRoute(
    fullscreenDialog: year == null,
    builder: (_) => NewspaperScreen(controller: c, year: year),
  ),
);

/// Back issues: every year this world has printed, searchable by year or
/// by words in its stories.
Future<void> _pickBackIssue(BuildContext context, GameController c) async {
  final life = c.life!;
  final world = c.engine!.world;
  final years = world.backIssueYears(life.year);
  final picked = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _paper,
    builder: (_) => _BackIssues(
      years: years,
      storiesFor: (y) => world.storiesFor(y, life.country, life.city),
      birthYear: life.birthYear,
    ),
  );
  if (picked != null && context.mounted) {
    await openNewspaper(context, c, year: picked);
  }
}

class _BackIssues extends StatefulWidget {
  const _BackIssues({
    required this.years,
    required this.storiesFor,
    required this.birthYear,
  });
  final List<int> years;
  final List<WorldStory> Function(int) storiesFor;
  final int birthYear;

  @override
  State<_BackIssues> createState() => _BackIssuesState();
}

class _BackIssuesState extends State<_BackIssues> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final rows = <(int, WorldStory)>[
      for (final y in widget.years)
        if (widget.storiesFor(y) case final s when s.isNotEmpty)
          if (q.isEmpty ||
              '$y'.contains(q) ||
              s.any(
                (x) =>
                    x.headline.toLowerCase().contains(q) ||
                    x.body.toLowerCase().contains(q),
              ))
            (
              y,
              s.firstWhere(
                (x) =>
                    q.isNotEmpty &&
                    !'$y'.contains(q) &&
                    (x.headline.toLowerCase().contains(q) ||
                        x.body.toLowerCase().contains(q)),
                orElse: () => s.first,
              ),
            ),
    ];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TextField(
                  autofocus: false,
                  style: NF.sora(15, color: _ink),
                  cursorColor: _accent,
                  decoration: InputDecoration(
                    hintText: 'Search back issues by year or word',
                    hintStyle: NF.sora(14, color: _inkSoft),
                    prefixIcon: const Icon(Icons.search, color: _inkSoft),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: _rule),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: _accent, width: 2),
                    ),
                  ),
                  onChanged: (v) => setState(() => _q = v),
                ),
              ),
              Flexible(
                child: rows.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          widget.years.isEmpty
                              ? 'No back issues yet. Every year you live adds one.'
                              : 'No back issue mentions that.',
                          style: NF.sora(14, color: _inkSoft),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                        itemCount: rows.length,
                        itemBuilder: (_, i) {
                          final (y, s) = rows[i];
                          return ListTile(
                            onTap: () => Navigator.of(context).pop(y),
                            title: Text(
                              y < widget.birthYear
                                  ? '$y · before you were born'
                                  : '$y · age ${y - widget.birthYear}',
                              style: NF.sora(
                                11,
                                weight: FontWeight.w700,
                                color: _accent,
                              ),
                            ),
                            subtitle: Text(
                              s.headline,
                              style: NF.sora(
                                15,
                                weight: FontWeight.w700,
                                color: _ink,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Newsprint palette: a light page on purpose, so the paper feels like an
// object you picked up. Ink tokens keep text at AA contrast on the page.
const _paper = Color(0xFFF3EEE3);
const _ink = Color(0xFF1C1B19);
const _inkSoft = Color(0xFF4A4740);
const _rule = Color(0xFFCFC6B4);
const _accent = Color(0xFF9C3D2E);

class NewspaperScreen extends StatelessWidget {
  const NewspaperScreen({super.key, required this.controller, this.year});
  final GameController controller;

  /// A back issue's year; null for today's paper.
  final int? year;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final world = controller.engine!.world;
    final back = year != null && year! < life.year;
    final y = back ? year! : life.year;
    if (!back) world.ensureYear(y, life.country, life.city);
    final stories = world.storiesFor(y, life.country, life.city);
    if (stories.isEmpty) {
      return Scaffold(
        backgroundColor: _paper,
        appBar: AppBar(backgroundColor: _paper, foregroundColor: _ink),
        body: Center(
          child: Text(
            'No paper was printed here in $y.',
            style: NF.sora(14, color: _inkSoft),
          ),
        ),
      );
    }
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
    for (final e
        in back
            ? const <(WorldStory, int)>[]
            : world.activeEffects(y, life.country, life.city)) {
      final prev = effects[e.$1.effect!];
      if (prev == null || e.$2 > prev.$2) effects[e.$1.effect!] = e;
    }
    final notices = [
      for (final n in life.npcs)
        for (final line in n.news)
          if (line.startsWith('Age ${life.age - (life.year - y)}:') &&
              RegExp(r'engaged|married|retired|moved|first job').hasMatch(line))
            line.substring(line.indexOf(':') + 2),
    ];
    final archive = <(int, WorldStory)>[
      if (!back) ...[
        for (final ago in const [5, 10, 20, 30])
          for (final s
              in world.storiesFor(y - ago, life.country, life.city).take(1))
            (ago, s),
        for (final s in world.ledger)
          if (s.year < y - 1 && s.person != '${life.firstName} ${life.surname}')
            (y - s.year, s),
      ],
    ];
    final name = back ? null : world.reputation(life.surname);

    return Scaffold(
      backgroundColor: _paper,
      appBar: AppBar(
        backgroundColor: _paper,
        foregroundColor: _ink,
        elevation: 0,
        title: Text(
          back ? 'Back issue · $y' : 'Today\'s paper',
          style: NF.sora(15, weight: FontWeight.w600, color: _ink),
        ),
        actions: [
          IconButton(
            tooltip: 'Back issues',
            icon: const Icon(Icons.history_edu_rounded),
            onPressed: () => _pickBackIssue(context, controller),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            children: [
              _masthead(life, y),
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
                for (final (ago, s) in archive.take(5))
                  InkWell(
                    onTap: () =>
                        openNewspaper(context, controller, year: s.year),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$ago years ago · ${s.year}',
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
                  ),
              ],
              // A linked past (past.dart): anniversaries of your history.
              if (historyColumn(y).isNotEmpty) ...[
                _section('From history'),
                for (final h in historyColumn(y))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      h,
                      style: NF.sora(14, color: _inkSoft, height: 1.5),
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
                  '— ${life.city} Chronicle · $y —',
                  style: NF.sora(12, color: _inkSoft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _masthead(Life life, int y) => Column(
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
        y < life.year
            ? '$y · ${life.country} edition · back issue'
            : '$y · ${life.country} edition · \$2',
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
