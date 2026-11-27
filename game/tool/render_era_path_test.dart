// Renders the Phase 2B era Path screens to PNGs for a visual check. Not part of
// the suite:
//   flutter test tool/render_era_path_test.dart --dart-define=OUT=<dir>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/era_path.dart';
import 'package:relivable/engine/eras.dart';
import 'package:relivable/engine/legends.dart';
import 'package:relivable/game_controller.dart';
import 'package:relivable/main.dart';
import 'package:relivable/sound.dart';
import 'package:relivable/ui/career_curtain.dart';
import 'package:relivable/ui/intro.dart';
import 'package:shared_preferences/shared_preferences.dart';

const out = String.fromEnvironment('OUT', defaultValue: 'build/era_path');

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

  Future<GlobalKey> show(
    WidgetTester t,
    GameController c,
    GlobalKey key,
  ) async {
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: RelivableApp(controller: c),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
    await _tab(t, 2);
    return key;
  }

  testWidgets('Leonardo: Path in 1478', (t) async {
    final (c, key) = await _app(t, h: 1500);
    c.startLegendLife('leonardo', seed: 3);
    _grow(c, 26);
    await show(t, c, key);
    await _shot(t, key, '1_leonardo_path');
    await t.drag(find.text('Your calling'), const Offset(0, -1500));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.textContaining('more closed'));
    await t.pump(const Duration(milliseconds: 300));
    await t.drag(find.textContaining('closed jobs'), const Offset(0, -700));
    await _shot(t, key, '2_leonardo_closed_jobs');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Leonardo: a commission', (t) async {
    final (c, key) = await _app(t);
    c.startLegendLife('leonardo', seed: 3);
    _grow(c, 26);
    await show(t, c, key);
    await t.tap(find.text('Take on a commission'));
    await _shot(t, key, '3_leonardo_commission');
    await t.pump(const Duration(seconds: 10));
  });

  for (final (name, region, year, age, setup)
      in <(String, String, int, int, void Function(GameController))>[
        ('4_florence_girl', 'florence', 1480, 15, (c) {}),
        (
          '5_timbuktu_student',
          'songhai',
          1505,
          16,
          (c) {
            final l = c.life!;
            final e = eraRegistry['renaissance']!;
            l.city = 'Timbuktu';
            l.eraPath['reads'] = ['arabic', 'read'];
            l.job = null;
            syncEraJob(l, e);
            enrolEraSchool(l, e, e.schoolById('sankore')!);
            l.eraPath['schoolYears'] = 2;
          },
        ),
        (
          '6_london_player',
          'england',
          1570,
          22,
          (c) {
            final l = c.life!;
            final e = eraRegistry['renaissance']!;
            l.city = 'London';
            l.job = null;
            syncEraJob(l, e);
            takeEraJob(l, e, e.job('player')!);
            l.eraPath['years'] = 3;
            l.eraPath['trade'] = 3;
          },
        ),
        (
          '7_kongo_noble',
          'kongo',
          1500,
          16,
          (c) {
            final l = c.life!;
            l.city = 'Mbanza Kongo';
            l.eraPath['status'] = 3;
          },
        ),
      ]) {
    testWidgets('ordinary life: $name', (t) async {
      final (c, key) = await _app(t, h: 1500);
      // A girl in Florence; boys elsewhere (Sankore and the playhouse
      // took only men).
      final girl = name == '4_florence_girl';
      for (var seed = 1; seed < 99; seed++) {
        c.startEraLife(region: region, year: year, seed: seed);
        if ((c.life!.gender == 'female') == girl) break;
      }
      _grow(c, age);
      setup(c);
      c.notifyListeners();
      await show(t, c, key);
      await _shot(t, key, name);
      await t.pump(const Duration(seconds: 10));
    });
  }
}
