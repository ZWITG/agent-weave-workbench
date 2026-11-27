// Renders the Phase 2 era screens to PNGs for a visual check. Not part of
// the suite:
//   flutter test tool/render_era_test.dart --dart-define=OUT=<dir>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/legends.dart';
import 'package:relivable/game_controller.dart';
import 'package:relivable/main.dart';
import 'package:relivable/sound.dart';
import 'package:relivable/ui/career_curtain.dart';
import 'package:relivable/ui/intro.dart';
import 'package:shared_preferences/shared_preferences.dart';

const out = String.fromEnvironment('OUT', defaultValue: 'build/era');

Future<void> _fonts() async {
  for (final (fam, file) in const [
    ('Sora', 'Sora-Variable.ttf'),
    ('Caveat', 'Caveat-Bold.ttf'),
    ('IMFellDWPica', 'IMFellDWPica-Regular.ttf'),
    ('MaterialIcons', null),
  ]) {
    final f = FontLoader(fam);
    if (file == null) {
      final p =
          '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
      f.addFont(Future.value(ByteData.sublistView(File(p).readAsBytesSync())));
    } else {
      f.addFont(rootBundle.load('assets/fonts/$file'));
    }
    await f.load();
  }
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

/// Ages a life to [age], taking the first choice of each event.
void _grow(GameController c, int age) {
  final e = c.engine!;
  final l = c.life!;
  while (l.alive && l.age < age) {
    final s = e.ageUp(l);
    if (s != null) {
      final shown = visibleChoices(l, s);
      if (shown.isNotEmpty) e.choose(l, s, shown.first);
    }
  }
  c.pendingEvent = null;
  c.lastOutcome = null;
  l.money = 120;
  c.notifyListeners();
}

Future<void> _tab(WidgetTester t, int i) async {
  await t.tap(find.byType(NavigationDestination).at(i));
  await t.pump(const Duration(milliseconds: 300));
}

void main() {
  IntroSplash.enabled = false;

  testWidgets('Leonardo: place card, journeys and a journey', (t) async {
    final (c, key) = await _app(t);
    c.startLegendLife('leonardo', seed: 3);
    _grow(c, 30);
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: RelivableApp(controller: c),
      ),
    );
    await _shot(t, key, '0_warm');
    await t.tap(find.bySemanticsLabel('Open activities'));
    await _shot(t, key, '1_place_card');
    await t.tap(find.text('Make a journey'));
    await _shot(t, key, '2_journeys');
    await t.tap(find.text('Go').first);
    await _shot(t, key, '3_journey_result');
    await t.pump(const Duration(seconds: 10));
  });

  for (final (name, region, year) in [
    ('4_london_1600', 'england', 1570),
    ('5_timbuktu_1510', 'songhai', 1480),
    ('6_kongo_1520', 'kongo', 1490),
  ]) {
    testWidgets('purse in $name', (t) async {
      final (c, key) = await _app(t);
      c.startEraLife(region: region, year: year, seed: 7);
      _grow(c, 30);
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: RelivableApp(controller: c),
        ),
      );
      await _tab(t, 3);
      await _shot(t, key, name);
      await t.pump(const Duration(seconds: 10));
    });
  }
}
