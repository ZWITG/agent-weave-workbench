// Renders the Phase 1 Legend screens to PNGs for a visual check. Not part
// of the suite:
//   flutter test tool/render_legends_test.dart --dart-define=OUT=<dir>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/legends.dart';
import 'package:relivable/engine/storylet.dart';
import 'package:relivable/game_controller.dart';
import 'package:relivable/main.dart';
import 'package:relivable/sound.dart';
import 'package:relivable/ui/codex.dart';
import 'package:relivable/ui/career_curtain.dart';
import 'package:relivable/ui/intro.dart';
import 'package:relivable/ui/legend_intro.dart';
import 'package:relivable/ui/newspaper.dart' show openNewspaper;
import 'package:shared_preferences/shared_preferences.dart';

const out = String.fromEnvironment('OUT', defaultValue: 'build/legends');

Future<void> _fonts() async {
  for (final (fam, file) in const [
    ('Sora', 'Sora-Variable.ttf'),
    ('Caveat', 'Caveat-Bold.ttf'),
    ('IMFellDWPica', 'IMFellDWPica-Regular.ttf'),
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

/// Plays the Legend to [year] with a strategy, leaving the next event
/// pending (if any).
Storylet? _playTo(GameController c, int year, {bool war = true}) {
  final e = c.engine!;
  final l = c.life!;
  Storylet? s;
  while (l.alive && l.year < year) {
    s = e.ageUp(l);
    if (s == null) continue;
    if (l.year >= year) return s;
    final shown = visibleChoices(l, s);
    var i = war
        ? shown.indexWhere((x) => x.rewrites == 'leo_engineer_milan')
        : -1;
    if (war && i < 0) {
      i = shown.indexWhere((x) => (x.adds['military'] ?? 0) > 0);
    }
    if (i < 0) i = shown.indexWhere((x) => x.canon);
    if (i < 0) i = 0;
    e.choose(l, s, shown[i]);
    s = null;
  }
  return s;
}

Future<void> _shot(WidgetTester t, GlobalKey key, String name) async {
  for (var i = 0; i < 10; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
  await t.runAsync(() async {
    final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory(out).createSync(recursive: true);
    File('$out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<(GameController, GlobalKey)> _app(
  WidgetTester t, {
  double h = 844,
}) async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  await t.runAsync(_fonts);
  t.view.physicalSize = Size(390, h);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  CareerCurtain.enabled = false;
  late GameController c;
  await t.runAsync(() async {
    c = GameController();
    await c.load();
  });
  Sound.instance.enabled = false;
  return (c, GlobalKey());
}

void main() {
  IntroSplash.enabled = false;

  testWidgets('legend home with the Chronicle line', (t) async {
    final (c, key) = await _app(t);
    c.startLegendLife('leonardo', seed: 3);
    final s = _playTo(c, 1478);
    c.pendingEvent = null;
    if (s != null) {
      c.engine!.choose(c.life!, s, visibleChoices(c.life!, s).first);
    }
    c.lastOutcome = null;
    c.notifyListeners();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: RelivableApp(controller: c),
      ),
    );
    await _shot(t, key, '1_legend_home');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('legend turning point', (t) async {
    final (c, key) = await _app(t, h: 1000);
    c.startLegendLife('leonardo', seed: 3);
    final s = _playTo(c, 1482);
    expect(s?.pivot, 'letter_1482');
    c.pendingEvent = s;
    c.notifyListeners();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: RelivableApp(controller: c),
      ),
    );
    await _shot(t, key, '2_turning_point');
    // Take the rewrite, and show the outcome.
    final rw = s!.choices.firstWhere((x) => x.rewrites != null);
    c.choose(rw);
    await _shot(t, key, '3_turning_point_outcome');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('codex and fate', (t) async {
    final (c, key) = await _app(t, h: 1300);
    for (var seed = 3; seed < 60; seed++) {
      c.startLegendLife('leonardo', seed: seed);
      _playTo(c, 1600, war: true);
      if (c.life!.fate == 'engineer_of_milan' && c.life!.codex.length >= 4) {
        break;
      }
    }
    final l = c.life!;
    expect(l.alive, isFalse);
    c.pendingEvent = null;
    c.notifyListeners();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: RelivableApp(controller: c),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    // ignore: avoid_print
    print('fate ${l.fate} chronicle ${l.chronicle} pivots ${l.pivots}');
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(
      MaterialPageRoute(
        builder: (_) => CodexScreen(life: l, legend: c.legend!),
      ),
    );
    await _shot(t, key, '4_codex_fate');
    await t.pump(const Duration(seconds: 10));
  });

  for (final paper in [false, true]) {
    testWidgets('modern life with a linked past $paper', (t) async {
      final (c, key) = await _app(t, h: paper ? 2300 : 844);
      await t.runAsync(c.toggleSamplePast);
      c.startLife(seed: 21, country: 'Italy');
      // A member of the house, born so the 525th anniversary of 1499 falls
      // in their childhood.
      final e = c.engine!;
      c.life = e.newLife(
        seed: 21,
        countryName: 'Italy',
        startYear: 2016,
        descendant: true,
      );
      final l = c.life!;
      while (l.year < 2024) {
        final s = e.ageUp(l);
        if (s != null) e.choose(l, s, visibleChoices(l, s).first);
      }
      c.pendingEvent = null;
      c.lastOutcome = null;
      c.notifyListeners();
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: RelivableApp(controller: c),
        ),
      );
      if (!paper) {
        await _shot(t, key, '5_modern_linked_past');
        await t.pump(const Duration(seconds: 10));
        return;
      }
      openNewspaper(t.element(find.byType(Navigator).first), c);
      await _shot(t, key, '6_newspaper_from_history');
      // ignore: avoid_print
      print(
        'assets ${l.assets.map((a) => a.name)} npcs ${l.npcs.map((n) => n.name)}',
      );
      await t.pump(const Duration(seconds: 10));
    });
  }

  // ---- Release preview screens ----

  testWidgets('new life with the Legends button', (t) async {
    final (c, key) = await _app(t, h: 1000);
    c.life = null;
    c.notifyListeners();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: RelivableApp(controller: c),
      ),
    );
    await _shot(t, key, '7_new_life_legends_button');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('preview Path and Wealth, activities and a toast', (t) async {
    final (c, key) = await _app(t);
    c.startLegendLife('leonardo', seed: 3);
    final s = _playTo(c, 1478);
    if (s != null) {
      c.engine!.choose(c.life!, s, visibleChoices(c.life!, s).first);
    }
    c.pendingEvent = null;
    c.lastOutcome = null;
    c.notifyListeners();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: RelivableApp(controller: c),
      ),
    );
    await _shot(t, key, '0_warmup');
    await t.tap(find.byType(NavigationDestination).at(2));
    await _shot(t, key, '8_path_preview');
    await t.tap(find.byType(NavigationDestination).at(3));
    await _shot(t, key, '9_wealth_preview');
    await t.tap(find.byType(NavigationDestination).at(0));
    await t.tap(find.bySemanticsLabel('Open activities'));
    await _shot(t, key, '10_activities_preview');
    t.state<NavigatorState>(find.byType(Navigator).first).pop();
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.byType(NavigationDestination).at(1));
    await t.pump(const Duration(milliseconds: 400));
    c.toasts.add('Achievement unlocked: Mirror writing');
    c.notifyListeners();
    await _shot(t, key, '11_toast_on_parchment');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('recap with the history button', (t) async {
    final (c, key) = await _app(t, h: 1700);
    c.startLegendLife('leonardo', seed: 3);
    _playTo(c, 1600);
    c.pendingEvent = null;
    c.lastOutcome = null;
    c.notifyListeners();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: RelivableApp(controller: c),
      ),
    );
    await _shot(t, key, '12_recap_history_button');
    await t.tap(find.text("Make this your world's history"));
    await t.pump(const Duration(milliseconds: 300));
    expect(c.pastLinked, isTrue);
    await t.pump(const Duration(seconds: 10));
  });

  // ---- Legend selector and opening ----

  testWidgets('legend selector card and opening frames', (t) async {
    final (c, key) = await _app(t);
    c.life = null;
    c.notifyListeners();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: RelivableApp(controller: c),
      ),
    );
    await _shot(t, key, '13_selector_card');
    final card = find.byType(LegendSelectCard);
    final at = t.getCenter(card);
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    for (final (i, f) in [(1, 0.08), (2, 0.4), (3, 0.62), (4, 0.9)]) {
      nav.push(
        PageRouteBuilder<void>(
          opaque: false,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, _, _) => LegendIntro(
            legend: c.playableLegends.first,
            from: at,
            onStart: () {},
            at: f,
          ),
        ),
      );
      await _shot(t, key, '14_opening_$i');
      nav.pop();
      await t.pump(const Duration(milliseconds: 500));
    }
    // The real thing: tap, and the life starts after the opening.
    await t.tap(card);
    for (var i = 0; i < 20; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(c.life, isNull);
    for (var i = 0; i < 25 && c.life == null; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(c.life?.legendId, 'leonardo');
    await t.pump(const Duration(milliseconds: 700));
    await _shot(t, key, '15_into_the_life');
    await t.pump(const Duration(seconds: 10));
  });
}
