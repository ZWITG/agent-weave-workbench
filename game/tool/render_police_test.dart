// Renders the police career (badge card, an academy scene) to PNGs for a
// visual check. Not part of the suite:
//   flutter test tool/render_police_test.dart --dart-define=OUT=<dir>
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
  for (final shot in const ['badge', 'academy']) {
    testWidgets('police $shot', (t) async {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      await t.runAsync(_fonts);
      t.view.physicalSize = const Size(390, 1100);
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
      startCareer(l, careerById('police')!);
      l.sceneQueue.clear();
      if (shot == 'badge') {
        l.marks.addAll([
          'academy_done',
          'cop_closed:4',
          'cop_lost:1',
          'cop_dirty:1',
          'undercover:velvet:28',
          'cop_cover:55',
        ]);
        l.careerRank = 3;
        l.job = 'Detective';
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
      if (shot == 'badge') {
        await t.tap(find.text('Path').first);
        await t.pump(const Duration(milliseconds: 400));
        await t.tap(find.text('Career').first);
        for (var i = 0; i < 6; i++) {
          await t.pump(const Duration(milliseconds: 150));
        }
      } else {
        c.openScene('academy:fitness');
        c.goToEvent();
        for (var i = 0; i < 10; i++) {
          await t.pump(const Duration(milliseconds: 150));
        }
      }
      await t.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        Directory(out).createSync(recursive: true);
        File('$out/police_$shot.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
