import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../engine/actions.dart';
import '../engine/models.dart';
import '../engine/recap.dart';
import '../game_controller.dart';
import '../share/share.dart';
import '../theme.dart';
import 'result_popup.dart';
import 'widgets.dart';

/// The Life Recap as swipeable story cards (plan Social §9): birth,
/// childhood, school, work, the biggest risk, your people, the grudge, the
/// Life Archetype, the Chaos Index, the title and the seed. Privacy chips
/// hide names, crimes, money or cause of death before saving or sharing.
class LifeRecapScreen extends StatefulWidget {
  const LifeRecapScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<LifeRecapScreen> createState() => _LifeRecapScreenState();
}

class _LifeRecapScreenState extends State<LifeRecapScreen> {
  final _pages = PageController();
  final _card = GlobalKey();
  var _page = 0;
  var _hide = shareSafe;
  var _busy = false;

  static const _accent = <String, Color>{
    'birth': Color(0xFF5EE6A8),
    'childhood': Color(0xFFFFD166),
    'school': NF.blue,
    'career': Color(0xFF5EE6A8),
    'risk': NF.danger,
    'people': Color(0xFFFF8FC7),
    'grudge': NF.danger,
    'archetype': NF.orange,
    'chaos': Color(0xFFFF8FC7),
    'title': NF.orange,
    'seed': NF.blue,
  };

  static const _icons = <String, IconData>{
    'birth': Icons.child_friendly_rounded,
    'childhood': Icons.toys_rounded,
    'school': Icons.school_rounded,
    'career': Icons.work_rounded,
    'risk': Icons.casino_rounded,
    'people': Icons.favorite_rounded,
    'grudge': Icons.mood_bad_rounded,
    'archetype': Icons.psychology_alt_rounded,
    'chaos': Icons.bolt_rounded,
    'title': Icons.workspace_premium_rounded,
    'seed': Icons.key_rounded,
  };

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final life = widget.controller.life!;
    final cards = recapCards(life, hide: _hide, pastChaos: pastChaosOf(life));
    final page = _page.clamp(0, cards.length - 1);
    return Scaffold(
      backgroundColor: NF.bg,
      appBar: AppBar(
        backgroundColor: NF.bg,
        title: Text('Life Recap', style: NF.sora(18, weight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
                    child: PageView.builder(
                      controller: _pages,
                      itemCount: cards.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (_, i) {
                        final card = _storyCard(cards[i], i, cards.length);
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                          child: LayoutBuilder(
                            builder: (context, box) => GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (d) => _turn(
                                d.localPosition.dx < box.maxWidth / 3 ? -1 : 1,
                                cards.length,
                              ),
                              child: i == page
                                  ? RepaintBoundary(key: _card, child: card)
                                  : card,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _chip(
                        'Hide names',
                        _hide.names,
                        (v) => (
                          names: v,
                          crimes: _hide.crimes,
                          money: _hide.money,
                          cause: _hide.cause,
                        ),
                      ),
                      _chip(
                        'Hide crimes',
                        _hide.crimes,
                        (v) => (
                          names: _hide.names,
                          crimes: v,
                          money: _hide.money,
                          cause: _hide.cause,
                        ),
                      ),
                      _chip(
                        'Hide money',
                        _hide.money,
                        (v) => (
                          names: _hide.names,
                          crimes: _hide.crimes,
                          money: v,
                          cause: _hide.cause,
                        ),
                      ),
                      _chip(
                        'Hide cause of death',
                        _hide.cause,
                        (v) => (
                          names: _hide.names,
                          crimes: _hide.crimes,
                          money: _hide.money,
                          cause: v,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: secondaryButton(),
                          icon: const Icon(Icons.copy_rounded),
                          label: const Text('Copy as text'),
                          onPressed: () => _copy(life, cards),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          style: orangeButton(),
                          icon: Icon(
                            _isAndroid
                                ? Icons.share_rounded
                                : Icons.download_rounded,
                          ),
                          label: Text(_isAndroid ? 'Share card' : 'Save card'),
                          onPressed: _busy
                              ? null
                              : () => _save(life, cards, page),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Tap the right of a card for the next one, the left to go back.
  void _turn(int by, int total) {
    final next = (_page + by).clamp(0, total - 1);
    if (next == _page) return;
    _pages.animateToPage(
      next,
      duration: motion(context, const Duration(milliseconds: 280)),
      curve: Curves.easeOutCubic,
    );
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Widget _chip(String label, bool on, RecapPrivacy Function(bool) next) =>
      FilterChip(
        label: Text(label, style: NF.sora(12, weight: FontWeight.w600)),
        selected: on,
        showCheckmark: true,
        backgroundColor: NF.surface2,
        selectedColor: NF.blue.withValues(alpha: 0.28),
        side: const BorderSide(color: NF.border),
        onSelected: (v) => setState(() => _hide = next(v)),
      );

  Widget _storyCard(RecapCard c, int i, int total) {
    final accent = _accent[c.kind] ?? NF.blue;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: NF.borderStrong),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(accent.withValues(alpha: 0.22), NF.surface),
            NF.bg,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var d = 0; d < total; d++)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: d <= i ? accent : NF.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Icon(_icons[c.kind] ?? Icons.auto_awesome_rounded, color: accent),
          const SizedBox(height: 12),
          Text(
            c.title.toUpperCase(),
            style: NF.sora(12, weight: FontWeight.w700, color: accent),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(c.big, style: NF.sora(34, weight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),
          Text(c.body, style: NF.sora(16, color: NF.soft, height: 1.5)),
          const Spacer(flex: 2),
          Row(
            children: [
              const Icon(Icons.spa_rounded, size: 16, color: NF.muted),
              const SizedBox(width: 6),
              Text(
                'Relivable',
                style: NF.sora(12, weight: FontWeight.w700, color: NF.muted),
              ),
              const Spacer(),
              Text('${i + 1}/$total', style: NF.sora(12, color: NF.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copy(Life life, List<RecapCard> cards) async {
    await Clipboard.setData(
      ClipboardData(text: recapText(life, cards, names: !_hide.names)),
    );
    if (!mounted) return;
    await showResultPopup(
      context,
      ActionResult('Your Life Recap is on the clipboard. Paste it anywhere.'),
      title: 'Copied',
      icon: Icons.copy_rounded,
    );
  }

  Future<void> _save(Life life, List<RecapCard> cards, int page) async {
    final boundary =
        _card.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    setState(() => _busy = true);
    String? msg;
    try {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;
      final name =
          'relivable-${cards[page].kind}-${DateTime.now().millisecondsSinceEpoch}.png';
      msg = await shareImage(
        data.buffer.asUint8List(),
        name,
        recapText(life, cards, names: !_hide.names),
      );
    } catch (_) {
      msg = 'Could not save the card. Copy it as text instead.';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (msg == null || !mounted) return;
    await showResultPopup(
      context,
      ActionResult(msg),
      title: 'Life Recap',
      icon: Icons.download_done_rounded,
    );
  }
}
