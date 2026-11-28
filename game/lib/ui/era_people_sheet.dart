import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/era_people.dart';
import '../engine/eras.dart';
import '../engine/models.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'era_art.dart';
import 'era_kit.dart';
import 'minigames.dart';
import 'widgets.dart';

/// A person in an era life (Phase 2D, People redone): who they are (their
/// humour, what they love and hate, as far as you know), what's on their
/// mind this year, this year's three moments and the six ways. Each opens
/// a scene with choices, and the scene ends with their reply in their own
/// voice. Modern lives keep the modern sheet (people.dart).
void openEraPersonSheet(BuildContext context, GameController c, Npc npc) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: NF.surface,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListenableBuilder(
        listenable: c,
        builder: (context, _) =>
            EraPersonSheet(controller: c, npc: npc, scroll: scroll),
      ),
    ),
  );
}

class EraPersonSheet extends StatelessWidget {
  const EraPersonSheet({
    super.key,
    required this.controller,
    required this.npc,
    this.scroll,
  });
  final GameController controller;
  final Npc npc;
  final ScrollController? scroll;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final era = eraRegistry[life.era]!;
    final n = npc;
    eraNature(life, era, n);
    final chips = eraNatureChips(life, era, n);
    final mind = eraMind(life, n);
    final moments = n.alive ? eraMoments(life, era, n) : const <String>[];
    final where = eraWhere(life, era, n);
    final about = eraAbout(life, era, n);
    final matchable = eraChildrenToMatch(life).contains(n);
    return ListView(
      controller: scroll,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Center(
          child: Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: NF.text.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        eraKicker('People · ${n.role}'),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: NF.blue,
                shape: BoxShape.circle,
                border: Border.all(color: NF.text, width: 2),
              ),
              child: Text(
                n.name.characters.first,
                style: eraHand(life, 32).copyWith(color: NF.surface),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.name, style: eraHand(life, 32)),
                  Text(
                    [
                      if (n.alive) '${n.ageIn(life.year)}' else 'Died',
                      ?about,
                      where,
                    ].join(' · '),
                    style: NF.sora(13, color: NF.muted, height: 1.3),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        EraCard(
          life: life,
          title: n.gender == 'female' ? 'Her nature' : 'His nature',
          children: [
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final c in chips) _Chip(c.text, dashed: !c.known),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _Meter('Love', n.affection)),
                const SizedBox(width: 14),
                Expanded(child: _Meter('Trust', n.trust)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _Meter('Respect', n.respect)),
                const SizedBox(width: 14),
                Expanded(child: _Meter('Hurt', n.resentment, dark: true)),
              ],
            ),
          ],
        ),
        if (n.alive && mind != null) ...[
          const SizedBox(height: 12),
          EraCard(
            life: life,
            title: n.gender == 'female' ? 'On her mind this year' : 'On his mind this year',
            children: [
              Text(
                mind['told'] == true || n.bond >= 60
                    ? mind['text'] as String
                    : 'Something is troubling ${n.gender == 'female' ? 'her' : 'him'}. Ask, or visit.',
                style: NF.sora(14.5, color: NF.soft, height: 1.4),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  _Act(
                    eraHelpLabel(mind),
                    filled: true,
                    onTap: () => openEraScene(context, controller, n, 'help'),
                  ),
                  _Act(
                    'Visit',
                    onTap: () => openEraScene(context, controller, n, 'visit'),
                  ),
                ],
              ),
            ],
          ),
        ],
        if (moments.isNotEmpty) ...[
          const SizedBox(height: 12),
          EraCard(
            life: life,
            title: "This year's moments",
            note: 'New each year, from the season, ${n.gender == 'female' ? 'her' : 'his'} life and yours.',
            children: [
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, id) in moments.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: _MomentCard(
                        card: eraMomentCard(life, era, n, id),
                        onTap: () => openEraScene(context, controller, n, id),
                      ),
                    ),
                  ],
                  for (var i = moments.length; i < 3; i++) ...[
                    const SizedBox(width: 8),
                    const Expanded(child: SizedBox()),
                  ],
                ],
              ),
            ],
          ),
        ],
        if (n.alive) ...[
          const SizedBox(height: 12),
          EraCard(
            life: life,
            title: 'Always',
            children: [
              const SizedBox(height: 6),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.55,
                children: [
                  for (final w in eraWays)
                    _Way(
                      label: eraWayLabel(w),
                      sub: eraWayLock(life, n, w) ?? eraWaySub(w),
                      locked: eraWayLock(life, n, w) != null,
                      onTap: () => openEraScene(context, controller, n, w),
                    ),
                ],
              ),
            ],
          ),
        ],
        if (matchable) ...[
          const SizedBox(height: 12),
          EraCard(
            life: life,
            title: 'A match',
            children: [
              EraRow(
                first: true,
                title: 'Who will ${n.name.split(' ').first} marry?',
                sub: 'Arrange it, or let them choose',
                pill: 'Decide',
                onTap: () => openEraChildMatch(context, controller, n),
              ),
            ],
          ),
        ],
        if (n.memories.isNotEmpty) ...[
          const SizedBox(height: 12),
          EraCard(
            life: life,
            title: n.gender == 'female' ? 'She remembers' : 'He remembers',
            children: [
              for (final m in n.memories.reversed.take(4))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(
                    '“${m.text}”',
                    style: NF.sora(14, color: m.negative ? NF.orange : NF.soft, height: 1.35),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {this.dashed = false});
  final String text;
  final bool dashed;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: dashed ? 0.7 : 1,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NF.blue, width: dashed ? 1 : 1.3),
      ),
      child: Text(
        dashed ? '? $text' : text,
        style: NF.sora(12.5, color: NF.blue),
      ),
    ),
  );
}

class _Meter extends StatelessWidget {
  const _Meter(this.label, this.value, {this.dark = false});
  final String label;
  final int value;
  final bool dark;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: NF.sora(12.5, color: NF.soft)),
      const SizedBox(height: 3),
      Container(
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: NF.text, width: 1),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: (value / 100).clamp(0.0, 1.0),
          child: Container(color: dark ? NF.text : NF.blue),
        ),
      ),
    ],
  );
}

class _Act extends StatelessWidget {
  const _Act(this.label, {this.filled = false, required this.onTap});
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: EraPill(label, filled: filled),
  );
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({required this.card, required this.onTap});
  final ({String label, String sub, String tag}) card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      constraints: const BoxConstraints(minHeight: 116),
      padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
      decoration: BoxDecoration(
        color: NF.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NF.text, width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.label, style: NF.sora(13.5, weight: FontWeight.w700, height: 1.2)),
          const SizedBox(height: 4),
          Text(card.sub, style: NF.sora(11.5, color: NF.muted, height: 1.25)),
          const SizedBox(height: 8),
          Text(
            card.tag,
            style: NF.sora(10, color: NF.blue, weight: FontWeight.w700).copyWith(letterSpacing: 1.2),
          ),
        ],
      ),
    ),
  );
}

class _Way extends StatelessWidget {
  const _Way({required this.label, required this.sub, required this.locked, required this.onTap});
  final String label;
  final String sub;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: locked ? 0.55 : 1,
    child: InkWell(
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: NF.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: NF.text, width: 1.4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: NF.sora(14.5, weight: FontWeight.w700)),
            Text(
              sub,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: NF.sora(11, color: NF.muted, height: 1.2),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------- Scenes ----------------

/// Opens a way or a moment with [npc] as a scene.
void openEraScene(BuildContext context, GameController c, Npc npc, String kind) {
  final life = c.life!;
  final era = eraRegistry[life.era]!;
  _openScene(
    context,
    c,
    () => eraScene(c.life!, era, npc, kind),
    (choice, score) {
      EraOutcome? out;
      c.eraAct((l, e, rng) {
        out = eraChoose(l, e, npc, kind, choice, rng, score: score);
        return out!.text;
      });
      return out;
    },
    visit: kind == 'visit',
  );
}

/// Someone who came to you.
void openEraCall(BuildContext context, GameController c, EraCall call) {
  final era = eraRegistry[c.life!.era]!;
  _openScene(context, c, () => eraCallScene(c.life!, era, call), (choice, _) {
    EraOutcome? out;
    c.eraAct((l, e, rng) {
      out = eraAnswerCall(l, e, call, choice, rng);
      return out!.text;
    });
    return out;
  });
}

void openEraMatch(BuildContext context, GameController c) {
  final era = eraRegistry[c.life!.era]!;
  _openScene(context, c, () => eraMatchScene(c.life!, era), (choice, _) {
    EraOutcome? out;
    c.eraAct((l, e, rng) {
      out = eraAnswerMatch(l, e, choice, rng);
      return out!.text;
    });
    return out;
  });
}

void openEraChildMatch(BuildContext context, GameController c, Npc child) {
  final era = eraRegistry[c.life!.era]!;
  _openScene(context, c, () => eraChildMatchScene(c.life!, era, child), (choice, _) {
    EraOutcome? out;
    c.eraAct((l, e, rng) {
      out = eraAnswerChildMatch(l, e, child, choice, rng);
      return out!.text;
    });
    return out;
  });
}

void _openScene(
  BuildContext context,
  GameController c,
  EraScene Function() scene,
  EraOutcome? Function(String choice, double score) choose, {
  bool visit = false,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: NF.bg,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scroll) => EraSceneView(
        life: c.life!,
        scene: scene(),
        choose: choose,
        scroll: scroll,
        visit: visit,
      ),
    ),
  );
}

class EraSceneView extends StatefulWidget {
  const EraSceneView({
    super.key,
    required this.life,
    required this.scene,
    required this.choose,
    this.scroll,
    this.visit = false,
  });
  final Life life;
  final EraScene scene;
  final EraOutcome? Function(String choice, double score) choose;
  final ScrollController? scroll;
  final bool visit;

  @override
  State<EraSceneView> createState() => _EraSceneViewState();
}

class _EraSceneViewState extends State<EraSceneView> {
  EraOutcome? _out;

  Future<void> _pick(EraChoice ch) async {
    var score = 0.6;
    if (widget.scene.game) {
      final s = await showMiniGame(
        context,
        'memory',
        age: widget.life.age,
        title: widget.scene.title,
        activity: 'era_portrait',
        life: widget.life,
      );
      if (s == null) return;
      score = s;
    }
    final out = widget.choose(ch.id, score);
    if (mounted) setState(() => _out = out);
  }

  @override
  Widget build(BuildContext context) {
    final life = widget.life;
    final s = widget.scene;
    final out = _out;
    return ListView(
      controller: widget.scroll,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
      children: [
        eraKicker(s.kicker),
        const SizedBox(height: 4),
        Text(out == null ? s.title : (out.good ? 'It went well' : 'It went badly'), style: eraHand(life, 34)),
        const SizedBox(height: 10),
        if (out == null) ...[
          if (widget.visit) ...[
            const EraSceneDrawing(height: 130),
            const SizedBox(height: 12),
          ],
          Text(s.text, style: NF.sora(15.5, color: NF.soft, height: 1.45)),
          const SizedBox(height: 14),
          for (final ch in s.choices) ...[
            _ChoiceCard(choice: ch, onTap: ch.lock == null ? () => _pick(ch) : null),
            const SizedBox(height: 9),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Leave it'),
          ),
        ] else ...[
          if (out.quote.isNotEmpty) ...[
            Text('“${out.quote}”', style: eraHand(life, 26).copyWith(color: NF.text, height: 1.15)),
            const SizedBox(height: 12),
          ],
          Text(out.text, style: NF.sora(15.5, color: NF.soft, height: 1.45)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final d in out.deltas) EraPill(d, filled: true)],
          ),
          if (out.memory != null) ...[
            const SizedBox(height: 12),
            EraCard(
              life: life,
              title: 'They\'ll remember this',
              children: [
                Text(
                  '“${out.memory}.” It can come back: in a letter, when they\'re ill, or at the end.',
                  style: NF.sora(14, color: NF.soft, height: 1.4),
                ),
              ],
            ),
          ],
          if (out.learned != null) ...[
            const SizedBox(height: 12),
            EraCard(
              life: life,
              title: 'You learned',
              children: [Text(out.learned!, style: NF.sora(14, color: NF.soft, height: 1.4))],
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            style: primaryButton().copyWith(
              minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue'),
          ),
        ],
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.choice, this.onTap});
  final EraChoice choice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (hint, color) = switch (choice.hint) {
      'loves' => ('They love this', const Color(0xFF2F7A3E)),
      'help' => ('Helps what\'s on their mind', const Color(0xFF2F7A3E)),
      'upset' => ('Could upset them', const Color(0xFFB0662A)),
      'risky' => ('Risky', NF.orange),
      _ => ('', NF.muted),
    };
    return Opacity(
      opacity: choice.lock != null ? 0.6 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            color: NF.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NF.text, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(choice.label, style: NF.sora(15, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(choice.sub, style: NF.sora(12.5, color: NF.muted, height: 1.3)),
              if (choice.lock != null || hint.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  choice.lock ?? hint,
                  style: NF.sora(12, weight: FontWeight.w700, color: choice.lock != null ? NF.orange : color),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A small ink drawing of a house in the hills, for visits.
class EraSceneDrawing extends StatelessWidget {
  const EraSceneDrawing({super.key, this.height = 120});
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: NF.surface2,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: NF.text, width: 1.4),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(11),
      child: CustomPaint(painter: _HillsPainter(NF.text, NF.blue), size: Size.infinite),
    ),
  );
}

class _HillsPainter extends CustomPainter {
  _HillsPainter(this.ink, this.accent);
  final Color ink;
  final Color accent;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final hill = Path()
      ..moveTo(0, h * 0.8)
      ..quadraticBezierTo(w * 0.2, h * 0.45, w * 0.4, h * 0.7)
      ..quadraticBezierTo(w * 0.62, h * 0.95, w * 0.8, h * 0.6)
      ..quadraticBezierTo(w * 0.9, h * 0.45, w, h * 0.62)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    c.drawPath(hill, Paint()..color = ink.withValues(alpha: 0.08));
    c.drawPath(hill, line);
    // The house.
    final hx = w * 0.52, hy = h * 0.72;
    c.drawRect(Rect.fromLTWH(hx, hy - 26, 30, 26), line);
    c.drawPath(
      Path()
        ..moveTo(hx - 5, hy - 24)
        ..lineTo(hx + 15, hy - 40)
        ..lineTo(hx + 35, hy - 24),
      line,
    );
    // Cypresses.
    for (final x in [w * 0.15, w * 0.24, w * 0.86]) {
      final y = x < w / 2 ? h * 0.62 : h * 0.56;
      c.drawLine(Offset(x, y), Offset(x, y + 16), line);
      c.drawOval(Rect.fromCenter(center: Offset(x, y - 6), width: 9, height: 24), line);
    }
    // The sun.
    c.drawCircle(Offset(w * 0.85, h * 0.22), 10, line..color = accent);
  }

  @override
  bool shouldRepaint(covariant _HillsPainter old) => old.ink != ink;
}

/// The People tab of an era life, drawn as a portrait wall: calls and
/// invitations arrive as sealed letters, and everyone you know hangs in a
/// gold oval frame on a red wall with a ribbon for their mood. Tap a
/// portrait to open their scenes.
class EraPeopleWall extends StatelessWidget {
  const EraPeopleWall({super.key, required this.controller});
  final GameController controller;

  static const _order = ['Partner', 'Family', 'Children', 'Friends', 'Work', 'School', 'Exes', 'Pets'];

  static String mood(Life l, Npc n) {
    if (!n.alive) return 'remembered';
    if (eraMind(l, n) != null) return 'on their mind';
    if (n.resentment >= 40) return 'hurt';
    if (l.age - n.lastContactAge >= 5) return 'missing you';
    if (n.affection >= 70) return 'fond of you';
    return 'well';
  }

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final calls = eraCalls(life);
    final match = eraMatchLock(life) == null;
    final groups = <String, List<Npc>>{};
    for (final n in life.npcs.where((n) => n.alive)) {
      groups.putIfAbsent(n.circle, () => []).add(n);
    }
    final gone = life.npcs.where((n) => !n.alive).toList();
    final keys = groups.keys.toList()
      ..sort((a, b) {
        final ia = _order.indexOf(a), ib = _order.indexOf(b);
        return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
      });
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA87C2E), width: 2),
        gradient: const RadialGradient(
          center: Alignment(0, -0.6),
          radius: 1.2,
          colors: [Color(0xFF874033), Color(0xFF4F2018)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          inkKicker('People · ${life.year}', color: const Color(0xFFF0C37A)),
          Text('Your people', style: hand(40, color: const Color(0xFFF6DC8F))),
          for (final (i, call) in calls.indexed)
            _Letter(
              seal: call.npc.name.characters.first,
              title: _callTitle(call),
              quote: call.text,
              tilt: i.isEven ? -0.012 : 0.01,
              onTap: () => openEraCall(context, controller, call),
            ),
          if (match)
            _Letter(
              seal: '♥',
              glyph: 'flag',
              title: 'Seek a match',
              quote: 'A broker, a family, a dowry…',
              tilt: calls.length.isEven ? -0.012 : 0.01,
              onTap: () => openEraMatch(context, controller),
            ),
          for (final k in keys) ...[
            const SizedBox(height: 14),
            Text(k, style: hand(26, color: const Color(0xFFF0C37A))),
            _Frames(controller: controller, people: groups[k]!),
          ],
          if (gone.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('In memory', style: hand(26, color: const Color(0xFFD9C49A))),
            Opacity(opacity: 0.6, child: _Frames(controller: controller, people: gone)),
          ],
          if (life.npcs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'The wall is bare for now. New people arrive through work, love and events.',
                style: fell(14.5, color: const Color(0xFFF3E2BD)),
              ),
            ),
        ],
      ),
    );
  }

  static String _callTitle(EraCall call) {
    final first = call.npc.name.split(' ').first;
    return switch (call.kind) {
      'match' => 'A marriage broker calls',
      'childmatch' => 'A match for $first',
      'milestone' => 'News from $first',
      _ => 'A letter from $first',
    };
  }
}

class _Letter extends StatelessWidget {
  const _Letter({
    required this.seal,
    required this.title,
    required this.quote,
    required this.tilt,
    required this.onTap,
    this.glyph,
  });
  final String seal;
  final String? glyph;
  final String title;
  final String quote;
  final double tilt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Transform.rotate(
      angle: tilt,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
        decoration: const BoxDecoration(
          color: EraInk.paper,
          boxShadow: [BoxShadow(color: Color(0x55000000), offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            WaxSeal(glyph != null ? '' : seal.toUpperCase(), size: 40, glyph: glyph),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: fell(15.5)),
                  Text(
                    quote,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: hand(20, color: EraInk.ink2, height: 1.0),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Text('Open', style: TextStyle(fontFamily: 'Sora', fontSize: 12, fontWeight: FontWeight.w700, color: EraInk.red)),
          ],
        ),
      ),
    ),
  );
}

/// "Ser Piero da Vinci" → "Piero".
String _given(String name) {
  final w = name.split(' ');
  return w.length > 1 && const {'Ser', 'Messer', 'Monna', 'Madonna', 'Sir', 'Dame', 'Mistress', 'Master'}.contains(w.first)
      ? w[1]
      : w.first;
}

class _Frames extends StatelessWidget {
  const _Frames({required this.controller, required this.people});
  final GameController controller;
  final List<Npc> people;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth > 480 ? 4 : 3;
        final w = (box.maxWidth - (cols - 1) * 8) / cols;
        return Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final n in people)
              SizedBox(
                width: w,
                child: GestureDetector(
                  onTap: () => openEraPersonSheet(context, controller, n),
                  child: Column(
                    children: [
                      const SizedBox(height: 6),
                      InkPortrait(
                        seed: n.id,
                        female: n.gender == 'female',
                        age: n.ageIn(life.year),
                        width: min(w - 10, 96),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _given(n.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: fell(15, color: const Color(0xFFF3E2BD)),
                      ),
                      Text(
                        n.role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: fell(11.5, color: const Color(0xFFD9B88A)),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: EraPeopleWall.mood(life, n) == 'on their mind'
                              ? EraInk.goldLight
                              : const Color(0xFFF3E2BD),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          EraPeopleWall.mood(life, n),
                          style: const TextStyle(fontFamily: 'Sora', fontSize: 10, color: EraInk.red2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
