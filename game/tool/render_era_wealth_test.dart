// Renders the Phase 2D era screens (Wealth, Homes, the Great Houses,
// Activities, the market and People) to PNGs for a visual check. Not part
// of the suite:
//   flutter test tool/render_era_wealth_test.dart --dart-define=OUT=<dir>
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/era_market.dart';
import 'package:relivable/engine/era_people.dart';
import 'package:relivable/engine/era_wealth.dart';
import 'package:relivable/engine/eras.dart';
import 'package:relivable/engine/legends.dart' show visibleChoices;
import 'package:relivable/engine/models.dart';
import 'package:relivable/game_controller.dart';
import 'package:relivable/main.dart';
import 'package:relivable/sound.dart';
import 'package:relivable/ui/career_curtain.dart';
import 'package:relivable/ui/era_houses_screen.dart';
import 'package:relivable/ui/era_people_sheet.dart';
import 'package:relivable/ui/minigames.dart';
import 'package:relivable/ui/intro.dart';
import 'package:shared_preferences/shared_preferences.dart';

const out = String.fromEnvironment('OUT', defaultValue: 'build/era_wealth');

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

  Future<(GameController, GlobalKey)> leo(WidgetTester t, {double h = 1300}) async {
    final (c, key) = await _app(t, h: h);
    c.startLegendLife('leonardo', seed: 3);
    _grow(c, 26);
    return (c, key);
  }

  void rich(GameController c) {
    final l = c.life!;
    final e = eraRegistry[l.era]!;
    final rng = Random(1);
    l.money = 400;
    eraBuy(l, e, 'paper', rng);
    eraBuy(l, e, 'lute', rng);
    eraDepositMoney(l, e, 100);
    eraInvest(l, e, 'silk');
    l.money = 120;
    c.notifyListeners();
  }

  testWidgets('Leonardo: Wealth', (t) async {
    final (c, key) = await leo(t, h: 1700);
    rich(c);
    await show(t, c, key);
    await _tab(t, 3);
    await _shot(t, key, '01_leonardo_wealth');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Leonardo: Homes', (t) async {
    final (c, key) = await leo(t, h: 1500);
    await show(t, c, key);
    await _tab(t, 3);
    await t.tap(find.text('Home').first);
    await t.pump(const Duration(milliseconds: 500));
    await _shot(t, key, '02_leonardo_homes');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Leonardo: the Great Houses', (t) async {
    final (c, key) = await leo(t, h: 1250);
    await show(t, c, key);
    await _tab(t, 3);
    Navigator.of(t.element(find.byType(Scaffold).first)).push(
      MaterialPageRoute<void>(builder: (_) => EraHousesScreen(controller: c)),
    );
    await t.pump(const Duration(milliseconds: 500));
    await _shot(t, key, '03_leonardo_great_houses');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Leonardo: Activities', (t) async {
    final (c, key) = await leo(t, h: 1300);
    await show(t, c, key);
    await t.tap(find.textContaining('What do you want').first, warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 600));
    await _shot(t, key, '04_leonardo_activities');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Leonardo: Carnival mini-game', (t) async {
    final (c, key) = await leo(t, h: 900);
    await show(t, c, key);
    final g = miniPools['era_carnival']!.first;
    showMiniGame(
      t.element(find.byType(Scaffold).first),
      g,
      age: c.life!.age,
      title: 'Carnival',
      activity: 'era_carnival',
      life: c.life,
      game: g,
    );
    await t.pump(const Duration(milliseconds: 800));
    await _shot(t, key, '05_leonardo_carnival_game');
    await t.pump(const Duration(seconds: 20));
  });

  testWidgets('Leonardo: the joust mini-game', (t) async {
    final (c, key) = await leo(t, h: 900);
    await show(t, c, key);
    final g = miniPools['era_joust']!.first;
    showMiniGame(
      t.element(find.byType(Scaffold).first),
      g,
      age: c.life!.age,
      title: 'Watch a joust',
      activity: 'era_joust',
      life: c.life,
      game: g,
    );
    await t.pump(const Duration(milliseconds: 800));
    await _shot(t, key, '06_leonardo_joust_game');
    await t.pump(const Duration(seconds: 20));
  });

  testWidgets('Leonardo: the market', (t) async {
    final (c, key) = await leo(t, h: 1500);
    rich(c);
    await show(t, c, key);
    await _tab(t, 3);
    await t.tap(find.text('Things you own').first);
    await t.pump(const Duration(milliseconds: 500));
    await _shot(t, key, '07_leonardo_market');
    await t.pump(const Duration(seconds: 10));
  });

  Npc mother(GameController c) => c.life!.npcs.firstWhere((n) => n.id == 'mother');

  testWidgets('Leonardo: Caterina', (t) async {
    final (c, key) = await leo(t, h: 1700);
    final m = mother(c);
    final e = eraRegistry[c.life!.era]!;
    eraNature(c.life!, e, m);
    m.info['mind'] = {
      'year': c.life!.year,
      'id': 'harvest',
      'text': 'The harvest failed and there\'s little to eat. She won\'t ask you for help.',
      'help': 'grain',
      'told': true,
    };
    await show(t, c, key);
    await _tab(t, 1);
    await t.tap(find.textContaining('Caterina').first);
    await t.pump(const Duration(milliseconds: 700));
    await _shot(t, key, '08_leonardo_caterina');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Leonardo: a visit, then what happened', (t) async {
    final (c, key) = await leo(t, h: 1300);
    final m = mother(c);
    await show(t, c, key);
    openEraScene(t.element(find.byType(Scaffold).first), c, m, 'visit');
    await t.pump(const Duration(milliseconds: 700));
    await _shot(t, key, '09_leonardo_visit');
    await t.tap(find.text('Talk about the old days').first);
    await t.pump(const Duration(milliseconds: 700));
    await _shot(t, key, '10_leonardo_visit_outcome');
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

  testWidgets('London: activities in 1590', (t) async {
    final (c, key) = await _app(t, h: 1300);
    await ordinary(t, c, 'england', 1560, 30, city: 'London');
    await show(t, c, key);
    await t.tap(find.textContaining('What do you want').first, warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 600));
    await _shot(t, key, '11_london_activities');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Fez: wealth', (t) async {
    final (c, key) = await _app(t, h: 1500);
    await ordinary(t, c, 'fez', 1500, 30, city: 'Fez');
    c.life!.money = 200;
    c.life!.eraWorld['faith'] = 'muslim';
    await show(t, c, key);
    await _tab(t, 3);
    await _shot(t, key, '12_fez_wealth');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Mbanza Kongo: homes', (t) async {
    final (c, key) = await _app(t, h: 1200);
    await ordinary(t, c, 'kongo', 1520, 25, city: 'Mbanza Kongo');
    c.life!.money = 300;
    await show(t, c, key);
    await _tab(t, 3);
    await t.tap(find.text('Home').first);
    await t.pump(const Duration(milliseconds: 500));
    await _shot(t, key, '13_kongo_homes');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Timbuktu: the Great Houses', (t) async {
    final (c, key) = await _app(t, h: 1200);
    await ordinary(t, c, 'songhai', 1500, 30, city: 'Timbuktu');
    await show(t, c, key);
    await _tab(t, 3);
    Navigator.of(t.element(find.byType(Scaffold).first)).push(
      MaterialPageRoute<void>(builder: (_) => EraHousesScreen(controller: c)),
    );
    await t.pump(const Duration(milliseconds: 500));
    await _shot(t, key, '14_timbuktu_great_houses');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Florence: a match', (t) async {
    final (c, key) = await _app(t, h: 1100);
    await ordinary(t, c, 'florence', 1480, 19, city: 'Florence', gender: 'female');
    c.life!.money = 400;
    c.life!.npcs.removeWhere((n) => n.circle == 'Partner');
    await show(t, c, key);
    await _tab(t, 1);
    openEraMatch(t.element(find.byType(Scaffold).first), c);
    await t.pump(const Duration(milliseconds: 700));
    await _shot(t, key, '15_florence_match');
    await t.pump(const Duration(seconds: 10));
  });

  testWidgets('Leonardo: People tab', (t) async {
    final (c, key) = await leo(t, h: 1100);
    final l = c.life!;
    l.eraWorld['calls'] = [
      {'npc': 'uncle', 'kind': 'invite', 'text': 'Francesco invites you to supper. He says there\'ll be eel pie.', 'year': l.year},
    ];
    await show(t, c, key);
    await _tab(t, 1);
    await _shot(t, key, '16_leonardo_people');
    await t.pump(const Duration(seconds: 10));
  });
}
