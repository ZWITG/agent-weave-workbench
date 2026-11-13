// Renders the career looks (the Curtain mid-play, and the Life tab in a few
// looks) to PNGs for a visual check. Not part of the suite:
//   flutter test tool/render_careers_test.dart --dart-define=OUT=<dir>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/game_controller.dart';
import 'package:relivable/main.dart';
import 'package:relivable/sound.dart';
import 'package:relivable/ui/intro.dart';
import 'package:relivable/engine/careers.dart';
import 'package:relivable/ui/career_curtain.dart';
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
  for (final (id, curtain) in const [
    ('actor', true),
    ('police', false),
    ('doctor', false),
    ('athlete', false),
    ('lawyer', false),
    ('musician', false),
    ('pilot', false),
    ('military', false),
  ]) {
    testWidgets('career look $id', (t) async {
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
      c.startLife(seed: 51);
      final l = c.life!..age = 29;
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
      startCareer(l, careerById(id)!);
      l.sceneQueue.clear();
      c.notifyListeners();
      if (curtain) {
        for (var i = 0; i < 14; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
      } else {
        CareerCurtain.enabled = false;
        for (var i = 0; i < 30; i++) {
          await t.pump(const Duration(milliseconds: 150));
        }
      }
      await t.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        Directory(out).createSync(recursive: true);
        File('$out/career_$id${curtain ? '_curtain' : ''}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      CareerCurtain.enabled = true;
      await t.pump(const Duration(seconds: 4));
    });
  }
}
