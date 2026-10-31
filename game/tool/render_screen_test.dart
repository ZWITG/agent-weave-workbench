// Renders the Life screen of a life in prison (Yard Time) to a PNG for a
// visual check. Not part of the suite:
//   flutter test tool/render_screen_test.dart --dart-define=OUT=<dir>
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
import 'package:shared_preferences/shared_preferences.dart';

const out = String.fromEnvironment('OUT', defaultValue: 'build/screens');

void main() {
  IntroSplash.enabled = false;
  for (final (w, h) in const [(390.0, 844.0), (320.0, 640.0)]) {
    testWidgets('prison life screen ${w.toInt()}', (t) async {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      await t.runAsync(() async {
        for (final (fam, file) in const [
          ('Sora', 'Sora-Variable.ttf'),
          ('Caveat', 'Caveat-Bold.ttf'),
          ('StardosStencil', 'StardosStencil-Bold.ttf'),
          ('MaterialIcons', null),
        ]) {
          final f = FontLoader(fam);
          if (file == null) {
            final p = '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter-sdk/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
            f.addFont(Future.value(ByteData.sublistView(File(p).readAsBytesSync())));
          } else {
            f.addFont(rootBundle.load('assets/fonts/$file'));
          }
          await f.load();
        }
      });
      t.view.physicalSize = Size(w, h);
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
        ..stash = 12;
      l.feed
        ..add(FeedEntry(26, 'You finished the carpentry course. The instructor said your joints were "almost professional".', kind: 'action'))
        ..add(FeedEntry(27, 'An hour in the yard. For a moment the sun felt the same as it does outside.'))
        ..add(FeedEntry(27, 'Your mum came to visit. She brought photos of the dog.', kind: 'milestone'));
      final key = GlobalKey();
      await t.pumpWidget(RepaintBoundary(key: key, child: RelivableApp(controller: c)));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 150));
      }
      await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 2);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        Directory(out).createSync(recursive: true);
        File('$out/prison_${w.toInt()}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
    });
  }
}
