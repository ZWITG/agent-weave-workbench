import 'package:flutter/material.dart';

import '../engine/era_news.dart';
import '../engine/eras.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'era_kit.dart';

/// Opens the era news sheet for [year] (this year by default).
Future<void> openEraNews(
  BuildContext context,
  GameController c, {
  int? year,
}) => Navigator.of(context).push(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => EraNewsScreen(controller: c, year: year),
  ),
);

/// The news in an era life (Phase 2C), as the place had it that year: a
/// crier's proclamation, handwritten avvisi, a printed coranto, or word
/// from the caravans. Opened by tapping the year's news line on the Life
/// tab. Back issues are the years of this life that had news.
class EraNewsScreen extends StatefulWidget {
  const EraNewsScreen({super.key, required this.controller, this.year});
  final GameController controller;
  final int? year;

  @override
  State<EraNewsScreen> createState() => _EraNewsScreenState();
}

class _EraNewsScreenState extends State<EraNewsScreen> {
  late int? _year = widget.year;

  @override
  Widget build(BuildContext context) {
    final life = widget.controller.life!;
    final era = eraRegistry[life.era]!;
    final issue = eraIssue(life, era, year: _year);
    final back = eraBackIssues(life, era).where((y) => y != issue.year);
    final italic = TextStyle(
      fontFamily: 'IMFellDWPica',
      fontStyle: FontStyle.italic,
      color: NF.text,
    );
    return Scaffold(
      backgroundColor: NF.bg,
      appBar: AppBar(
        backgroundColor: NF.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
              children: [
                Center(child: eraKicker('The news · ${issue.kind == 'word' ? 'heard' : issue.kind == 'crier' ? 'cried' : 'written'}')),
                const SizedBox(height: 6),
                Text(
                  issue.title,
                  textAlign: TextAlign.center,
                  style: italic.copyWith(fontSize: 44, height: 1.05),
                ),
                const SizedBox(height: 6),
                Text(
                  '${issue.line} · ${life.city} · ${issue.year}',
                  textAlign: TextAlign.center,
                  style: NF.sora(14, color: NF.soft),
                ),
                const SizedBox(height: 10),
                Container(height: 2.5, color: NF.text),
                if (issue.stories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'A quiet year. Nothing the criers would cry.',
                      style: NF.sora(16, color: NF.soft),
                    ),
                  ),
                for (final s in issue.stories) _story(s, italic),
                if (back.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  eraKicker('Back issues'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final y in back.take(24))
                        InkWell(
                          onTap: () => setState(() => _year = y),
                          child: EraPill('$y'),
                        ),
                      if (_year != null && _year != life.year)
                        InkWell(
                          onTap: () => setState(() => _year = null),
                          child: EraPill('This year', filled: true),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _story(EraStory s, TextStyle italic) {
    // The first sentence is the lead, in italic red chalk.
    final cut = s.text.indexOf('. ');
    final lead = cut > 0 && cut < 60 ? s.text.substring(0, cut + 1) : null;
    final rest = lead == null ? s.text : s.text.substring(cut + 2);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: NF.text.withValues(alpha: 0.25)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                if (lead != null)
                  TextSpan(
                    text: '$lead ',
                    style: italic.copyWith(color: NF.orange, fontSize: 18),
                  ),
                TextSpan(text: rest),
              ],
            ),
            style: NF.sora(17, color: NF.text, height: 1.35),
          ),
          if (s.effect != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: NF.orange,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                s.effect!,
                style: TextStyle(
                  fontFamily: 'Sora',
                  fontSize: 12,
                  color: NF.surface,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
