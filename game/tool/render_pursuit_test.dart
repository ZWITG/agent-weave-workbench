// Renders the Hot Pursuit mini-games (Getaway, Break-in, Breakout) to PNGs
// for a visual check. Not part of the suite:
//   flutter test tool/render_pursuit_test.dart --dart-define=OUT=<dir>
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/models.dart';
import 'package:relivable/game_controller.dart';
import 'package:relivable/main.dart';
import 'package:relivable/sound.dart';
import 'package:relivable/ui/intro.dart';
import 'package:relivable/ui/minigames.dart';
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
  testWidgets('pursuit manhunt card', (t) async {
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
    c.startLife(seed: 41);
    final l = c.life!
      ..age = 30
      ..notoriety = 25;
    l.cases.add({'crime': 'armed_robbery', 'evidence': 60, 'age': 29});
    l.marks.add('most_wanted');
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: RelivableApp(controller: c),
      ),
    );
    c.openScene('manhunt:roadblock');
    c.goToEvent();
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(milliseconds: 150));
    }
    await t.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 1);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      Directory(out).createSync(recursive: true);
      File('$out/pursuit_card.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
  for (final game in const ['getaway', 'breakin', 'breakout']) {
    testWidgets('pursuit $game', (t) async {
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
      c.startLife(seed: 41);
      final l = c.life!..age = 30;
      if (game == 'breakout') {
        l.prison = Prison(
          crime: 'burglary',
          years: 4,
          since: 29,
          security: 'medium',
        );
      }
      final key = GlobalKey();
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: RelivableApp(controller: c),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await t.pump(const Duration(milliseconds: 150));
      }
      final ctx = t.element(find.byType(Scaffold).first);
      unawaited(
        showMiniGame(
          ctx,
          game,
          age: 30,
          title: switch (game) {
            'getaway' => 'Swing round and floor it',
            'breakin' => 'Go in yourself',
            _ => 'Nothing but nerve',
          },
          activity: game,
          life: l,
          game: game,
        ),
      );
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 150));
      }
      // A few moves so the board is mid-play.
      Future<void> press(String label, int times) async {
        for (var i = 0; i < times; i++) {
          final f = find.bySemanticsLabel(label);
          if (f.evaluate().isEmpty) return;
          await t.tap(f.first, warnIfMissed: false);
          await t.pump(const Duration(milliseconds: 260));
        }
      }

      if (game == 'getaway') {
        await t.pump(const Duration(milliseconds: 300));
      } else if (game == 'breakin') {
        await press('Up', 2);
      } else {
        await press('Up', 1);
      }
      await t.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        Directory(out).createSync(recursive: true);
        File('$out/pursuit_$game.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      // Let the timers end before the test closes.
      for (var i = 0; i < 200; i++) {
        await t.pump(const Duration(milliseconds: 150));
      }
    });
  }
}
