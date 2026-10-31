// Renders frames of Lockdown (going into prison and coming out) to PNGs
// for a visual check. Not part of the suite:
//   flutter test tool/render_lockdown_test.dart --dart-define=OUT=<dir>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/models.dart';
import 'package:relivable/engine/echelon.dart';

import 'dart:math';

import 'package:relivable/game_controller.dart';
import 'package:relivable/main.dart';
import 'package:relivable/sound.dart';
import 'package:relivable/ui/intro.dart';
import 'package:shared_preferences/shared_preferences.dart';

const out = String.fromEnvironment('OUT', defaultValue: 'build/screens');

Future<void> _fonts() async {
  for (final (fam, file) in const [
    ('Sora', 'Sora-Variable.ttf'),
    ('Caveat', 'Caveat-Bold.ttf'),
    ('StardosStencil', 'StardosStencil-Bold.ttf'),
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

void main() {
  IntroSplash.enabled = false;
  testWidgets('lockdown frames', (t) async {
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
    c.startLife(seed: 21);
    final l = c.life!;
    l.age = 25;
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: RelivableApp(controller: c),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    Future<void> shot(String name) => t.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 1);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      Directory(out).createSync(recursive: true);
      File('$out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });

    // Going in.
    l.prison = Prison(crime: 'burglary', years: 5, since: 25);
    c.notifyListeners();
    var ms = 0;
    for (final at in const [
      200,
      900,
      1300,
      1550,
      1900,
      2400,
      2900,
      3300,
      3800,
      4300,
    ]) {
      await t.pump(Duration(milliseconds: at - ms));
      ms = at;
      await shot('enter_${at.toString().padLeft(4, '0')}');
    }
    await t.pump(const Duration(milliseconds: 800));
    await shot('enter_done');

    // Coming out.
    l.prison!.served = 3;
    l.prison = null;
    c.notifyListeners();
    ms = 0;
    for (final at in const [150, 700, 1200, 1700, 2300]) {
      await t.pump(Duration(milliseconds: at - ms));
      ms = at;
      await shot('release_${at.toString().padLeft(4, '0')}');
    }
    await t.pump(const Duration(milliseconds: 800));
    await shot('release_done');
  });

  testWidgets('inside tabs', (t) async {
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
    c.startLife(seed: 21);
    final l = c.life!;
    l.age = 27;
    l.prison = Prison(crime: 'burglary', years: 5, since: 25)
      ..served = 2
      ..job = 'Carpentry workshop'
      ..behaviour = 68
      ..respect = 41
      ..stash = 7
      ..gangId = 'iron'
      ..gangRank = 1
      ..gangStanding = 55;
    l.prison!.rivalry['owls'] = 40;
    l.prison!.courses.add('trade');
    l.prison!.items.addAll(['radio', 'books', 'phone']);
    l.prison!.nickname = 'Professor';
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: RelivableApp(controller: c),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    Future<void> shot(String name) => t.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 1);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      Directory(out).createSync(recursive: true);
      File('$out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    for (final tab in const ['Visits', 'File', 'Canteen', 'ID']) {
      await t.tap(find.text(tab).last);
      for (var i = 0; i < 4; i++) {
        await t.pump(const Duration(milliseconds: 150));
      }
      await shot('tab_$tab');
    }
    await t.tap(find.text('Cell').last);
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.text('Swipe up for the yard'));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    await shot('yard');
    await t.drag(find.text('THE YARD'), const Offset(0, -500));
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    await shot('yard_scrolled');
    await t.tap(find.text('Work out in the yard'));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    await shot('yard_game');
  });

  testWidgets('echelon', (t) async {
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    await t.runAsync(_fonts);
    await t.runAsync(() async {
      final f = FontLoader('Playfair')
        ..addFont(rootBundle.load('assets/fonts/PlayfairDisplay-Variable.ttf'));
      await f.load();
    });
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    late GameController c;
    await t.runAsync(() async {
      c = GameController();
      await c.load();
    });
    Sound.instance.enabled = false;
    c.startLife(seed: 33);
    final l = c.life!;
    l.age = 44;
    l.money = 160000000;
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: RelivableApp(controller: c),
      ),
    );
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    Future<void> shot(String name) => t.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 1);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      Directory(out).createSync(recursive: true);
      File('$out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    // Crossing the line: the Invitation.
    l.flags['upper_echelon'] = Memory(l.age, 'joining');
    echelonYear(l, Random(1));
    c.notifyListeners();
    var ms = 0;
    for (final at in const [400, 1300, 2000, 2700, 3400, 4200]) {
      await t.pump(Duration(milliseconds: at - ms));
      ms = at;
      await shot('invite_${at.toString().padLeft(4, '0')}');
    }
    await t.pump(const Duration(seconds: 2));
    // A new tier: the plaque.
    l.money = 2400000000;
    echelonYear(l, Random(2));
    c.notifyListeners();
    ms = 0;
    for (final at in const [500, 1200]) {
      await t.pump(Duration(milliseconds: at - ms));
      ms = at;
      await shot('tier_$at');
    }
    await t.pump(const Duration(seconds: 3));
    // The Echelon screen, from the Wealth tab.
    l.echelon['influence'] = 47;
    l.npcs.add(
      Npc(
        id: 'kid9',
        role: 'Son',
        name: 'Rafael',
        birthYear: l.year - 19,
        circle: 'Children',
      ),
    );
    l.echelon['ready'] = {'kid9': 45};
    final rs = rivals(l);
    rs[2]['feud'] = 70;
    l.echelon['rivals'] = rs;
    c.notifyListeners();
    await t.tap(find.text('Wealth').last);
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    await shot('wealth_card');
    await t.tap(find.text('THE ECHELON').first);
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    await shot('echelon_0');
    for (var k = 1; k <= 4; k++) {
      await t.drag(find.byType(Scrollable).last, const Offset(0, -700));
      for (var i = 0; i < 4; i++) {
        await t.pump(const Duration(milliseconds: 150));
      }
      await shot('echelon_$k');
    }
  });
}
