import 'dart:math';

import 'package:flutter/material.dart';

import '../engine/career_hub.dart';
import '../engine/careers.dart';
import '../engine/models.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'activities.dart' show actionRow;
import 'career_stage.dart';
import 'people.dart' show openPersonSheet;
import 'widgets.dart';

// The Career Hub screen ("Calling", docs/phase-2/03): the career's look
// across the top as a motif strip, the signature meter, the season strip,
// the next step on the ladder, the career's own activities and what has
// happened so far.

void openCareerHub(BuildContext context, GameController c) => Navigator.of(
  context,
).push(MaterialPageRoute(builder: (_) => CareerHubScreen(controller: c)));

/// A compact card for Path › Career and the Career page of Activities.
class HubCard extends StatelessWidget {
  const HubCard({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final l = controller.life!;
    final spec = hubFor(l);
    final look = careerLooks[l.careerId];
    if (spec == null || look == null) return const SizedBox.shrink();
    final p = look.palette;
    final m = hubMeter(l);
    return Semantics(
      button: true,
      label:
          '${look.name}: ${l.job}. ${spec.meter} $m of 100. Open your career',
      excludeSemantics: true,
      child: Material(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openCareerHub(context, controller),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 34,
                child: CustomPaint(painter: CareerMotif(l.careerId!, 0.3)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 14),
                child: Row(
                  children: [
                    Icon(look.icon, color: p.orange, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            look.name.toUpperCase(),
                            style: NF
                                .sora(
                                  10.5,
                                  weight: FontWeight.w700,
                                  color: p.blue,
                                )
                                .copyWith(letterSpacing: 1.6),
                          ),
                          Text(
                            l.job ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: NF.sora(
                              17,
                              weight: FontWeight.w700,
                              color: p.text,
                            ),
                          ),
                          const SizedBox(height: 6),
                          _MeterBar(label: spec.meter, value: m, palette: p),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: p.muted),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeterBar extends StatelessWidget {
  const _MeterBar({
    required this.label,
    required this.value,
    required this.palette,
  });
  final String label;
  final int value;
  final NFPalette palette;
  static const big = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: NF.sora(big ? 14 : 12, color: palette.muted),
            ),
          ),
          Text(
            '$value',
            style: NF.sora(
              big ? 20 : 13,
              weight: FontWeight.w800,
              color: palette.text,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          value: value / 100,
          minHeight: big ? 10 : 6,
          backgroundColor: palette.surface2,
          color: palette.orange,
        ),
      ),
    ],
  );
}

class CareerHubScreen extends StatefulWidget {
  const CareerHubScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<CareerHubScreen> createState() => _CareerHubScreenState();
}

class _CareerHubScreenState extends State<CareerHubScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motif = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  GameController get c => widget.controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The motif moves slowly, unless Reduce motion is on.
    if (MediaQuery.of(context).disableAnimations) {
      _motif.stop();
    } else if (!_motif.isAnimating) {
      _motif.repeat();
    }
  }

  @override
  void dispose() {
    _motif.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final l = c.life;
      final spec = l == null ? null : hubFor(l);
      final look = careerLooks[l?.careerId];
      if (l == null || spec == null || look == null) {
        return Scaffold(
          appBar: AppBar(backgroundColor: NF.bg),
          body: Center(
            child: Text(
              'You are not in a special career right now.',
              style: NF.sora(15, color: NF.muted),
            ),
          ),
        );
      }
      return Scaffold(
        backgroundColor: NF.bg,
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _header(context, l, spec, look),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _body(context, l, spec, look),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _header(BuildContext context, Life l, HubSpec spec, CareerLook look) {
    final p = look.palette;
    return Stack(
      children: [
        // The career's scene (career_stage.dart), drawn and animated.
        SizedBox(
          height: 176,
          width: double.infinity,
          child: ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _motif,
              builder: (_, _) => CustomPaint(
                painter: HubScenePainter(
                  l.careerId!,
                  _motif.value,
                  beat: hubBeat(l),
                ),
              ),
            ),
          ),
        ),
        // Fade the motif out behind the title.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.55, 1.0],
                colors: [p.bg.withValues(alpha: 0), p.bg],
              ),
            ),
          ),
        ),
        Positioned(
          left: 4,
          top: 4,
          child: IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_rounded, color: p.text),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 10,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(look.icon, color: p.orange, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      look.name.toUpperCase(),
                      style: NF
                          .sora(11, weight: FontWeight.w700, color: p.blue)
                          .copyWith(letterSpacing: 2),
                    ),
                    Text(
                      l.job ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NF.sora(
                        24,
                        weight: FontWeight.w800,
                        color: p.text,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _body(
    BuildContext context,
    Life l,
    HubSpec spec,
    CareerLook look,
  ) {
    final p = look.palette;
    final career = careerById(l.careerId)!;
    final actions = c.engine!.actions
        .where((a) => a.category == 'Career' && hubActionFits(l, a.id))
        .toList();
    final next = promotionLock(l);
    final log = hubLog(l);
    final details = spec.details?.call(l) ?? const [];
    final words = wordsFor(l.careerId!);
    return [
      NFCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The meter as the career's own instrument (career_stage.dart).
            AnimatedBuilder(
              animation: _motif,
              builder: (_, _) => HubInstrument(
                look: l.careerId!,
                label: spec.meter,
                value: hubMeter(l),
                t: _motif.value,
              ),
            ),
            const SizedBox(height: 8),
            Text(spec.meterBlurb, style: NF.sora(13, color: NF.soft)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _seasonStrip(l, spec, p),
      const SizedBox(height: 12),
      NFCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            hubHeading(l.careerId!, words.$1),
            const SizedBox(height: 10),
            HubLadder(
              look: l.careerId!,
              ladder: career.ladder,
              rank: l.careerRank,
              next: next,
            ),
          ],
        ),
      ),
      if (details.isNotEmpty) ...[
        const SizedBox(height: 12),
        NFCard(
          child: Column(
            children: [
              for (final (k, v) in details)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(k, style: NF.sora(13, color: NF.muted)),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        flex: 2,
                        child: Text(
                          v,
                          textAlign: TextAlign.right,
                          style: NF.sora(13, weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
      if (hubContacts(l) case final people when people.isNotEmpty) ...[
        const SizedBox(height: 18),
        hubHeading(l.careerId!, 'Your people'),
        const SizedBox(height: 8),
        for (final n in people) ...[
          HubContactCard(
            look: l.careerId!,
            name: n.name,
            role: n.role,
            kind: n.info['contact'] as String,
            bond: n.bond,
            onTap: () => openPersonSheet(context, c, n),
          ),
          const SizedBox(height: 8),
        ],
      ],
      const SizedBox(height: 18),
      KeyedSubtree(
        key: const ValueKey('hub-work'),
        child: hubHeading(l.careerId!, words.$2),
      ),
      const SizedBox(height: 8),
      for (final a in actions) ...[
        actionRow(context, c, a, closeSheet: false),
        const SizedBox(height: 8),
      ],
      if (log.isNotEmpty) ...[
        const SizedBox(height: 10),
        hubHeading(l.careerId!, words.$3),
        const SizedBox(height: 8),
        for (final line in log)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: SizedBox(
                    width: 20,
                    child: Text(
                      words.$4,
                      style: NF.sora(
                        13,
                        weight: FontWeight.w700,
                        color: p.orange,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(line, style: NF.sora(13, color: NF.soft)),
                ),
              ],
            ),
          ),
      ],
    ];
  }

  Widget _seasonStrip(Life l, HubSpec spec, NFPalette p) {
    final beat = hubBeat(l);
    final look = careerLooks[l.careerId];
    return Semantics(
      label: 'Season: ${spec.seasons.join(', ')}. Now: ${spec.seasons[beat]}',
      excludeSemantics: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < spec.seasons.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: i == beat
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              p.orange.withValues(alpha: 0.30),
                              p.orange.withValues(alpha: 0.08),
                            ],
                          )
                        : null,
                    color: i == beat ? null : NF.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: i == beat ? p.orange : NF.border,
                      width: i == beat ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (i == beat) ...[
                        Icon(look?.icon, size: 14, color: p.orange),
                        const SizedBox(height: 3),
                      ] else
                        Text('${i + 1}', style: NF.sora(10, color: NF.muted)),
                      Text(
                        spec.seasons[i],
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: i == beat
                            ? hubFace(l.careerId!, 12, NF.text)
                            : NF.sora(11, color: NF.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Each career look's motif, drawn as a strip: marquee bulbs, VU meters, a
/// pitch, camera flashes, a ballot ribbon, dog tags, wood grain, a heart
/// trace, an artificial horizon, a hedgerow, a chalk board, a light bar.
/// [t] (0..1) moves it.
class CareerMotif extends CustomPainter {
  CareerMotif(this.id, this.t, {this.tall = false});
  final String id;
  final double t;
  final bool tall;

  @override
  void paint(Canvas canvas, Size size) {
    final look = careerLooks[id];
    if (look == null) return;
    final p = look.palette;
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.surface2, p.bg],
        ).createShader(Offset.zero & size),
    );
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = p.borderStrong.withValues(alpha: 0.8);
    final y = tall ? h * 0.32 : h / 2;
    switch (id) {
      case 'actor':
        // A row of bulbs, with a light chasing along it.
        final n = (w / 22).floor();
        for (var i = 0; i < n; i++) {
          final x = 11 + i * 22.0;
          final lit = ((i / n - t) % 1).abs() < 0.12;
          canvas.drawCircle(
            Offset(x, y),
            5,
            Paint()..color = lit ? p.blue : p.blue.withValues(alpha: 0.35),
          );
          if (lit) {
            canvas.drawCircle(
              Offset(x, y),
              11,
              Paint()..color = p.blue.withValues(alpha: 0.18),
            );
          }
        }
      case 'musician':
        final n = (w / 12).floor();
        for (var i = 0; i < n; i++) {
          final v =
              (sin(i * 0.9 + t * pi * 6) * 0.5 + 0.5) *
              (0.4 + 0.6 * sin(i * 0.31).abs());
          final bh = (tall ? h * 0.55 : h * 0.8) * v;
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(i * 12.0 + 3, (tall ? h * 0.6 : h) - bh, 7, bh),
              const Radius.circular(2),
            ),
            Paint()
              ..color = (v > 0.7 ? p.orange : p.blue).withValues(alpha: 0.8),
          );
        }
      case 'athlete':
        canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), line);
        canvas.drawCircle(Offset(w / 2, y), min(h * 0.3, 26), line);
        canvas.drawRect(Rect.fromLTWH(-2, y - 18, 40, 36), line);
        canvas.drawRect(Rect.fromLTWH(w - 38, y - 18, 40, 36), line);
        canvas.drawCircle(
          Offset(w * (0.2 + 0.6 * ((t * 2) % 1)), y),
          4,
          Paint()..color = p.blue,
        );
      case 'model':
        final rnd = Random(7);
        for (var i = 0; i < 9; i++) {
          final x = rnd.nextDouble() * w;
          final yy = rnd.nextDouble() * (tall ? h * 0.6 : h);
          final a = ((t * 3 + i / 9) % 1) < 0.15 ? 0.9 : 0.15;
          final paint = Paint()
            ..color = p.text.withValues(alpha: a)
            ..strokeWidth = 1.5;
          canvas.drawLine(Offset(x - 8, yy), Offset(x + 8, yy), paint);
          canvas.drawLine(Offset(x, yy - 8), Offset(x, yy + 8), paint);
        }
      case 'politician':
        for (var i = -4; i < (w / 18) + 4; i++) {
          final x = i * 18.0 + t * 36;
          canvas.drawLine(
            Offset(x, 0),
            Offset(x + h * 0.6, tall ? h * 0.6 : h),
            Paint()
              ..color = (i.isEven ? p.orange : p.blue).withValues(alpha: 0.45)
              ..strokeWidth = 6,
          );
        }
      case 'military':
        for (final dx in [-14.0, 14.0]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(w / 2 + dx, y),
                width: 34,
                height: 20,
              ),
              const Radius.circular(8),
            ),
            Paint()..color = p.soft.withValues(alpha: 0.55),
          );
        }
        canvas.drawLine(Offset(0, y - 12), Offset(w, y - 12), line);
      case 'lawyer':
        for (var i = 0; i < 6; i++) {
          final path = Path()..moveTo(0, i * h / 6 + 3);
          for (var x = 0.0; x <= w; x += 20) {
            path.lineTo(x, i * h / 6 + 3 + sin(x / 40 + i) * 2.5);
          }
          canvas.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..color = p.borderStrong.withValues(alpha: 0.25)
              ..strokeWidth = 1.2,
          );
        }
      case 'doctor':
        final path = Path()..moveTo(0, y);
        final shift = t * w;
        for (var x = 0.0; x <= w; x += 2) {
          final u = ((x + shift) % 120) / 120;
          final dy = u > 0.42 && u < 0.46
              ? -h * 0.3
              : u > 0.46 && u < 0.5
              ? h * 0.2
              : 0.0;
          path.lineTo(x, y + dy);
        }
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = p.blue,
        );
      case 'pilot':
        final tilt = sin(t * pi * 2) * 0.06;
        canvas.save();
        canvas.translate(w / 2, y);
        canvas.rotate(tilt);
        canvas.drawRect(
          Rect.fromLTWH(-w, 0, w * 2, h),
          Paint()..color = p.orange.withValues(alpha: 0.12),
        );
        canvas.drawLine(Offset(-w, 0), Offset(w, 0), line);
        canvas.restore();
        canvas.drawLine(
          Offset(w / 2 - 30, y),
          Offset(w / 2 - 8, y),
          Paint()
            ..color = p.blue
            ..strokeWidth = 3,
        );
        canvas.drawLine(
          Offset(w / 2 + 8, y),
          Offset(w / 2 + 30, y),
          Paint()
            ..color = p.blue
            ..strokeWidth = 3,
        );
      case 'vet':
        canvas.drawCircle(
          Offset(w * (0.15 + 0.7 * t), tall ? h * 0.22 : h * 0.3),
          8,
          Paint()..color = p.orange.withValues(alpha: 0.8),
        );
        for (var x = 0.0; x < w + 30; x += 28) {
          canvas.drawCircle(
            Offset(x, tall ? h * 0.62 : h),
            18,
            Paint()..color = p.blue.withValues(alpha: 0.35),
          );
        }
      case 'hustler':
        final chalk = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = p.text.withValues(alpha: 0.4);
        for (var i = 0; i < (w / 70).floor(); i++) {
          final x = 12 + i * 70.0;
          canvas.drawLine(Offset(x, y - 6), Offset(x + 30, y - 6), chalk);
          canvas.drawLine(Offset(x, y + 4), Offset(x + 18, y + 4), chalk);
          canvas.drawCircle(
            Offset(x + 44, y),
            6,
            chalk..color = p.blue.withValues(alpha: 0.6),
          );
        }
      case 'astronaut':
        // Stars, and a capsule crossing the strip.
        final rnd = Random(9);
        for (var i = 0; i < (w / 14).floor(); i++) {
          canvas.drawCircle(
            Offset(rnd.nextDouble() * w, rnd.nextDouble() * h),
            rnd.nextDouble() * 1.2,
            Paint()..color = p.text.withValues(alpha: 0.6),
          );
        }
        canvas.drawCircle(
          Offset(w * ((t * 0.7) % 1), y),
          3.5,
          Paint()..color = p.orange,
        );
        canvas.drawLine(
          Offset(0, y + 6),
          Offset(w, y - 6),
          Paint()
            ..color = p.blue.withValues(alpha: 0.3)
            ..strokeWidth = 1,
        );
      case 'fighter':
        // Three ropes and a belt glint.
        for (var i = 0; i < 3; i++) {
          canvas.drawLine(
            Offset(0, y - 8 + i * 8.0),
            Offset(w, y - 8 + i * 8.0),
            Paint()
              ..color = (i == 1 ? p.text : p.orange).withValues(alpha: 0.6)
              ..strokeWidth = 2,
          );
        }
        canvas.drawCircle(
          Offset(w * ((t * 1.2) % 1), y),
          5,
          Paint()..color = p.borderStrong,
        );
      case 'police':
        final on = (t * 6).floor().isEven;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(w / 4, y),
              width: w / 2 - 20,
              height: 12,
            ),
            const Radius.circular(6),
          ),
          Paint()..color = p.orange.withValues(alpha: on ? 0.85 : 0.25),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(w * 3 / 4, y),
              width: w / 2 - 20,
              height: 12,
            ),
            const Radius.circular(6),
          ),
          Paint()..color = p.blue.withValues(alpha: on ? 0.25 : 0.85),
        );
    }
  }

  @override
  bool shouldRepaint(CareerMotif old) => old.t != t || old.id != id;
}
