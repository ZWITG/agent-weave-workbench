// Renders the Phase 2C era screens (Health, The law, prison, Faith, the
// news) to PNGs for a visual check. Not part of the suite:
//   flutter test tool/render_era_world_test.dart --dart-define=OUT=<dir>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/legends.dart' show visibleChoices;
import 'package:relivable/game_controller.dart';
import 'package:relivable/main.dart';
import 'package:relivable/sound.dart';
import 'package:relivable/ui/career_curtain.dart';
import 'package:relivable/ui/intro.dart';
import 'package:shared_preferences/shared_preferences.dart';

const out = String.fromEnvironment('OUT', defaultValue: 'build/era_world');

Future<void> _fonts() async {
  for (final (fam, file) in const [
    ('Sora', 'Sora-Variable.ttf'),
    ('Caveat', 'Caveat-Bold.ttf'),
    ('IMFellDWPica', 'IMFellDWPica-Regular.ttf'),
    ('Playfair', 'PlayfairDisplay-Variable.ttf'),
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

  Future<void> show(WidgetTester t, GameController c, GlobalKey key) async {
    await t.pumpWidget(
      RepaintBoundary(key: key, child: RelivableApp(controller: c)),
    );
    await t.pump(const Duration(milliseconds: 300));
  }

  Future<void> me(WidgetTester t, String tile) async {
    await _tab(t, 4);
    await t.tap(find.text(tile).first);
    await t.pump(const Duration(milliseconds: 500));
  }

  Future<(GameController, GlobalKey)> leo(WidgetTester t, {double h = 1300}) async {
    final (c, key) = await _app(t, h: h);
    c.startLegendLife('leonardo', seed: 3);
    _grow(c, 26);
    return (c, key);
  }

  testWidgets('Leonardo: Me tab', (t) async {
    final (c, key) = await leo(t, h: 1100);
    await show(t, c, key);
    await _tab(t, 4);
    await _shot(t, key, '01_leonardo_me');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Leonardo: Health in a plague year', (t) async {
    final (c, key) = await leo(t, h: 1700);
    c.life!.eraWorld['ill'] = ['bone'];
    await show(t, c, key);
    await me(t, 'Health');
    await _shot(t, key, '02_leonardo_health');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Leonardo: The law', (t) async {
    final (c, key) = await leo(t, h: 1500);
    await show(t, c, key);
    await me(t, 'Crime and the law');
    await _shot(t, key, '03_leonardo_law');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Leonardo: a hearing', (t) async {
    final (c, key) = await leo(t, h: 1000);
    await show(t, c, key);
    c.eraLifeAct((l, e, rng) {
      l.eraWorld['hearing'] = {
        'crime': 'smuggle',
        'label': 'Smuggle salt past the gabelle',
        'sentence': {'kind': 'fine', 'amount': 10, 'orPrison': 1},
      };
      l.sceneQueue.add('era_hearing');
      return 'Caught.';
    });
    await t.pump(const Duration(milliseconds: 600));
    await _shot(t, key, '04_leonardo_hearing');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Leonardo: in the Stinche', (t) async {
    final (c, key) = await leo(t, h: 1300);
    c.life!.eraWorld['inside'] = {
      'kind': 'prison',
      'name': 'the Stinche',
      'left': 1,
      'debt': 0,
      'fed': true,
      'since': c.life!.year,
      'why': 'a brawl on the Ponte Vecchio',
    };
    await show(t, c, key);
    await _tab(t, 1);
    await _shot(t, key, '05_leonardo_stinche');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Leonardo: Faith', (t) async {
    final (c, key) = await leo(t, h: 1300);
    await show(t, c, key);
    await me(t, 'Faith');
    await _shot(t, key, '06_leonardo_faith');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Leonardo: the news of 1478', (t) async {
    final (c, key) = await leo(t, h: 1300);
    await show(t, c, key);
    await t.tap(find.byIcon(Icons.newspaper_rounded).last);
    await t.pump(const Duration(milliseconds: 600));
    await _shot(t, key, '07_leonardo_news');
    await t.pump(const Duration(seconds: 10));
  });

  Future<GameController> ordinary(
    WidgetTester t,
    GameController c,
    String region,
    int year,
    int age, {
    String? city,
    String gender = 'male',
  }) async {
    for (var seed = 1; seed < 199; seed++) {
      c.startEraLife(region: region, year: year, seed: seed);
      if (c.life!.gender != gender) continue;
      _grow(c, age);
      if (c.life!.alive && c.life!.age == age) break;
    }
    if (city != null) c.life!.city = city;
    c.life!
      ..alive = true
      ..sceneQueue.clear();
    c.life!.eraWorld
      ..remove('inside')
      ..remove('hearing');
    c.pendingEvent = null;
    c.notifyListeners();
    return c;
  }

  testWidgets('London: Newgate', (t) async {
    final (c, key) = await _app(t, h: 1200);
    await ordinary(t, c, 'england', 1570, 24, city: 'London');
    final l = c.life!;
    l.eraWorld['inside'] = {
      'kind': 'prison',
      'name': 'Newgate',
      'left': 2,
      'debt': 0,
      'fed': false,
      'since': l.year,
      'why': 'stealing at Smithfield market',
    };
    await show(t, c, key);
    await _tab(t, 1);
    await _shot(t, key, '08_london_newgate');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('London: faith in 1594', (t) async {
    final (c, key) = await _app(t, h: 1500);
    await ordinary(t, c, 'england', 1560, 34, city: 'London');
    await show(t, c, key);
    await me(t, 'Faith');
    await _shot(t, key, '09_london_faith');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Fez: the law', (t) async {
    final (c, key) = await _app(t, h: 1400);
    await ordinary(t, c, 'fez', 1500, 22, city: 'Fez');
    c.life!.eraWorld['heat'] = 1;
    await show(t, c, key);
    await me(t, 'Crime and the law');
    await _shot(t, key, '10_fez_law');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Fez: faith', (t) async {
    final (c, key) = await _app(t, h: 1200);
    await ordinary(t, c, 'fez', 1500, 22, city: 'Fez');
    c.life!.eraWorld['faith'] = 'muslim';
    await show(t, c, key);
    await me(t, 'Faith');
    await _shot(t, key, '11_fez_faith');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Mbanza Kongo: health', (t) async {
    final (c, key) = await _app(t, h: 1500);
    await ordinary(t, c, 'kongo', 1520, 20, city: 'Mbanza Kongo');
    c.life!.eraWorld['ill'] = ['fever'];
    await show(t, c, key);
    await me(t, 'Health');
    await _shot(t, key, '12_kongo_health');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Florence: the florin sign', (t) async {
    final (c, key) = await _app(t, h: 700);
    await ordinary(t, c, 'florence', 1480, 20, city: 'Florence');
    await show(t, c, key);
    await _shot(t, key, '13_florence_florin');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Venice: the news of 1576', (t) async {
    final (c, key) = await _app(t, h: 1100);
    await ordinary(t, c, 'venice', 1540, 36, city: 'Venice');
    await show(t, c, key);
    await t.tap(find.byIcon(Icons.newspaper_rounded).last);
    await t.pump(const Duration(milliseconds: 600));
    await _shot(t, key, '14_venice_avvisi');
    await t.pump(const Duration(seconds: 10));
  });
}
