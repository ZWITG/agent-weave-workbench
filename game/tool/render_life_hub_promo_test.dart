// Renders real screens for social batch 3: the Encore mini-games in their
// careers' looks, the Life feed with pins, the Turning points filter,
// today's newspaper and a back issue from before you were born. Phone size
// (390x844) at 2x. Not part of the suite:
//   flutter test tool/render_life_hub_promo_test.dart --dart-define=OUT=<dir>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/careers.dart';
import 'package:relivable/engine/currency.dart' show activeCountry;
import 'package:relivable/game_controller.dart';
import 'package:relivable/main.dart';
import 'package:relivable/sound.dart';
import 'package:relivable/ui/career_curtain.dart';
import 'package:relivable/ui/intro.dart';
import 'package:relivable/ui/minigames.dart' show showMiniGame;
import 'package:relivable/ui/newspaper.dart';
import 'package:shared_preferences/shared_preferences.dart';

const out = String.fromEnvironment('OUT', defaultValue: 'build/life_hub');

Future<void> _fonts() async {
  for (final (fam, file) in const [
    ('Sora', 'Sora-Variable.ttf'),
    ('Caveat', 'Caveat-Bold.ttf'),
    ('StardosStencil', 'StardosStencil-Bold.ttf'),
    ('Playfair', 'PlayfairDisplay-Variable.ttf'),
    ('MaterialIcons', null),
  ]) {
    final f = FontLoader(fam);
    if (file == null) {
      final p =
          '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter-sdk/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
      f.addFont(Future.value(ByteData.sublistView(File(p).readAsBytesSync())));
    } else {
      f.addFont(rootBundle.load('assets/fonts/$file'));
    }
    await f.load();
  }
}

Future<void> _frames(WidgetTester t, int n) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _shot(WidgetTester t, GlobalKey key, String name) => t.runAsync(
  () async {
    final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('$out/stills').createSync(recursive: true);
    File('$out/stills/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  },
);

/// Lives [years] years, always taking an event's first choice.
void _live(GameController c, int years) {
  for (var i = 0; i < years && c.life!.alive; i++) {
    c.ageUp();
    for (var guard = 0; guard < 6; guard++) {
      if (c.pendingEvent != null) {
        c.choose(c.pendingEvent!.choices.first);
      }
      if (c.lastOutcome != null) c.dismissOutcome();
      if (c.pendingEvent == null && c.life!.sceneQueue.isEmpty) break;
    }
  }
}

void main() {
  IntroSplash.enabled = false;
  CareerCurtain.enabled = false;

  // The Encore mini-games, each played inside its career's look.
  for (final (id, act, game, title) in const [
    ('actor', 'act_audition', 'coldread', 'Cold read'),
    ('musician', 'mus_rehearse', 'soundcheck', 'Soundcheck'),
    ('athlete', 'ath_train', 'matchday', 'Match day'),
    ('politician', 'pol_speech', 'debate', 'The debate'),
    ('model', 'mod_casting', 'runway', 'The runway'),
    ('doctor', 'doc_triage', 'triage', 'Triage'),
    ('vet', 'vet_clinic', 'diagnose', 'Diagnose'),
    ('pilot', 'pil_check', 'crosswind', 'Crosswind landing'),
    ('military', 'mil_drill', 'obstacle', 'Obstacle course'),
    ('lawyer', 'law_cross', 'objection', 'Cross-examination'),
    ('hustler', 'hus_busk', 'pitch', 'The pitch'),
  ]) {
    testWidgets('encore $game', (t) async {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      await t.runAsync(_fonts);
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      late GameController c;
      await t.runAsync(() async {
        c = GameController();
        await c.load();
      });
      Sound.instance.enabled = false;
      c.startLife(seed: 77);
      activeCountry = 'United States';
      final l = c.life!
        ..age = 31
        ..country = 'United States'
        ..city = 'Chicago';
      final key = GlobalKey();
      await t.pumpWidget(
        RepaintBoundary(key: key, child: RelivableApp(controller: c)),
      );
      await _frames(t, 6);
      startCareer(l, careerById(id)!);
      l.sceneQueue.clear();
      l.careerRank = 1;
      l.job = careerById(id)!.ladder[1];
      l.hub['meter'] = 64;
      c.notifyListeners();
      await _frames(t, 8);
      final ctx = t.element(find.byType(Scaffold).first);
      showMiniGame(ctx, game, age: 31, title: title, activity: act, game: game);
      await _frames(t, 12);
      await _shot(t, key, 'encore_$game');
    });
  }

  testWidgets('life hub promo', (t) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await t.runAsync(_fonts);
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    late GameController c;
    await t.runAsync(() async {
      c = GameController();
      await c.load();
    });
    Sound.instance.enabled = false;
    c.startLife(seed: 77);
    activeCountry = 'United States';
    c.life!
      ..country = 'United States'
      ..city = 'Chicago';
    _live(c, 46);
    final l = c.life!;
    // Pin the two closest people so the strip has something to say.
    final people = l.npcs.where((n) => n.alive).toList();
    for (final n in people.take(2)) {
      c.togglePinned('npc:${n.id}');
    }
    c.ageUp();
    if (c.pendingEvent != null) c.choose(c.pendingEvent!.choices.first);
    if (c.lastOutcome != null) c.dismissOutcome();

    c.toasts.clear();
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(key: key, child: RelivableApp(controller: c)),
    );
    await _frames(t, 10);
    c.toasts.clear();
    c.notifyListeners();
    await _frames(t, 30);
    await _shot(t, key, 'life_pinned');

    final tp = find.text('Turning points');
    if (tp.evaluate().isNotEmpty) {
      await t.ensureVisible(tp.first);
      await t.tap(tp.first, warnIfMissed: false);
      await _frames(t, 8);
      await _shot(t, key, 'life_turning_points');
    }

    final ctx = t.element(find.byType(Navigator).first);
    openNewspaper(ctx, c);
    await _frames(t, 10);
    await _shot(t, key, 'news_today');
    Navigator.of(ctx).pop();
    await _frames(t, 6);

    final years = c.engine!.world.backIssueYears(l.year);
    // The earliest paper whose front page doesn't lead on AI (messaging
    // guardrail in docs/phase-1/10 Go-to-Market.md 1.3).
    final world = c.engine!.world;
    final clean = years.toList()..sort();
    final pick = clean.firstWhere(
      (y) => !world
          .storiesFor(y, l.country, l.city)
          .take(2)
          .any((s) => RegExp(r'\bAI\b').hasMatch('${s.headline} ${s.body}')),
      orElse: () => clean.first,
    );
    // ignore: avoid_print
    print('back issue year: $pick (born ${l.birthYear})');
    openNewspaper(ctx, c, year: pick);
    await _frames(t, 10);
    await _shot(t, key, 'news_back_issue');
    Navigator.of(ctx).pop();
    await _frames(t, 6);
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(seconds: 10));
  });
}
