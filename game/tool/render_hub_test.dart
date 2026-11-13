// Renders the Career Hub screen for each Hub career to PNGs for a visual
// check. Not part of the suite:
//   flutter test tool/render_hub_test.dart --dart-define=OUT=<dir>
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
import 'package:relivable/ui/career_hub_screen.dart';
import 'package:relivable/engine/career_hub.dart';
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

void main() {
  IntroSplash.enabled = false;
  for (final id in const [
    'actor',
    'musician',
    'athlete',
    'politician',
    'police',
    'model',
    'doctor',
    'vet',
    'pilot',
    'military',
    'lawyer',
    'hustler',
    'astronaut',
    'fighter',
  ]) {
    testWidgets('hub $id', (t) async {
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      await t.runAsync(_fonts);
      t.view.physicalSize = const Size(390, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      CareerCurtain.enabled = false;
      late GameController c;
      await t.runAsync(() async {
        c = GameController();
        await c.load();
      });
      Sound.instance.enabled = false;
      c.startLife(seed: 51);
      final l = c.life!..age = 29;
      startCareer(l, careerById(id)!);
      l.sceneQueue.clear();
      l.hub['meter'] = 47;
      l.hub['beat'] = 1;
      l.hub['log'] = [
        'Age 28: cast in "Paper Crowns"',
        'Age 27: signed with a small agency',
      ];
      if (id == 'actor') {
        l.hub['agent'] = 1;
        l.hub['project'] = {
          'title': 'Paper Crowns',
          'kind': 'a TV series',
          'stage': 'shot',
        };
      }
      if (id == 'athlete') {
        l.hub['sport'] = 'Basketball';
        l.hub['record'] = '7 won, 3 lost';
        l.hub['place'] = 2;
      }
      if (id == 'musician') l.music['fans'] = 42000;
      if (id == 'politician') l.hub['chest'] = 24000;
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
      final nav = t.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(
        MaterialPageRoute(builder: (_) => CareerHubScreen(controller: c)),
      );
      for (var i = 0; i < 8; i++) {
        await t.pump(const Duration(milliseconds: 150));
      }
      expect(hubFor(l), isNotNull);
      await t.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        Directory(out).createSync(recursive: true);
        File('$out/hub_$id.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      nav.pop();
      await t.pump(const Duration(seconds: 1));
      CareerCurtain.enabled = true;
    });
  }
}
