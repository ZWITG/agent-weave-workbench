// Renders the career marks outside the Hub for a visual check: the header
// with the meter chip on a small phone with large text, a stamped career
// result and a frame of the Final Bow. Not part of the suite:
//   flutter test tool/render_marks_test.dart --dart-define=OUT=<dir>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/actions.dart' show ActionResult;
import 'package:relivable/engine/careers.dart';
import 'package:relivable/game_controller.dart';
import 'package:relivable/main.dart';
import 'package:relivable/sound.dart';
import 'package:relivable/theme.dart';
import 'package:relivable/ui/intro.dart';
import 'package:relivable/ui/result_popup.dart';
import 'package:shared_preferences/shared_preferences.dart';

const out = String.fromEnvironment('OUT', defaultValue: 'build/screens');

Future<void> _fonts() async {
  for (final (fam, file) in const [
    ('Sora', 'Sora-Variable.ttf'),
    ('Caveat', 'Caveat-Bold.ttf'),
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

Future<void> _shot(WidgetTester t, GlobalKey key, String name) =>
    t.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      Directory(out).createSync(recursive: true);
      File('$out/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    });

Future<void> _frames(WidgetTester t, int n, [int ms = 150]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(Duration(milliseconds: ms));
  }
}

void main() {
  IntroSplash.enabled = false;
  for (final scale in const [1.0, 1.3]) {
    testWidgets('header at $scale', (t) async {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      await t.runAsync(_fonts);
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      late GameController c;
      await t.runAsync(() async {
        c = GameController();
        await c.load();
      });
      Sound.instance.enabled = false;
      c.startLife(seed: 51);
      c.updateProfile((p) => p.textScale = scale);
      final l = c.life!
        ..age = 29
        ..money = 25000
        ..fame = 40;
      final key = GlobalKey();
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: RelivableApp(controller: c),
        ),
      );
      await _frames(t, 6);
      startCareer(l, careerById('politician')!);
      l.sceneQueue.clear();
      c.notifyListeners();
      await _frames(t, 30);
      await _shot(t, key, 'header_money_$scale');
    });
  }
  for (final (id, tone, text) in const [
    ('actor', 'good', 'The director loved your read. You got the part.'),
    ('athlete', 'bad', 'You pushed too hard and were injured in training.'),
    ('politician', 'mixed', 'The bill went through, but with changes.'),
  ]) {
    testWidgets('marks $id', (t) async {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      await t.runAsync(_fonts);
      t.view.physicalSize = const Size(320, 568);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      late GameController c;
      await t.runAsync(() async {
        c = GameController();
        await c.load();
      });
      Sound.instance.enabled = false;
      c.startLife(seed: 51);
      c.updateProfile((p) => p.textScale = 1.3);
      final l = c.life!..age = 29;
      final key = GlobalKey();
      await t.pumpWidget(
        RepaintBoundary(
          key: key,
          child: RelivableApp(controller: c),
        ),
      );
      await _frames(t, 6);
      startCareer(l, careerById(id)!);
      l.sceneQueue.clear();
      l.hub['meter'] = 47;
      c.notifyListeners();
      await _frames(t, 30);
      await _shot(t, key, 'marks_${id}_header');

      final ctx = t.element(find.byType(Scaffold).first);
      showResultPopup(
        ctx,
        ActionResult(text, [
          tone == 'bad' ? 'Health −6' : 'Happiness +4',
          if (tone == 'mixed') 'Money −\$2,000',
        ]),
        title: 'Career activity',
        look: NF.career,
      );
      await _frames(t, 4);
      await _shot(t, key, 'marks_${id}_stamp');
      Navigator.of(ctx).pop();
      await _frames(t, 4);

      // The Final Bow, part way in.
      l.retired = true;
      l.job = null;
      c.notifyListeners();
      await t.pump(const Duration(milliseconds: 16));
      await t.pump(const Duration(milliseconds: 900));
      await _shot(t, key, 'marks_${id}_bow');
      await t.pump(const Duration(milliseconds: 700));
      await _shot(t, key, 'marks_${id}_bow_close');
      await _frames(t, 10, 200);
    });
  }
}
