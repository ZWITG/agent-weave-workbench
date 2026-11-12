// Renders Activities › Crime (Back Alley) to PNGs for a visual check. Not
// part of the suite:
//   flutter test tool/render_crime_test.dart --dart-define=OUT=<dir>
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/crime_wall.dart';
import 'package:relivable/engine/models.dart';
import 'package:relivable/game_controller.dart';
import 'package:relivable/main.dart';
import 'package:relivable/sound.dart';
import 'package:relivable/engine/actions.dart';
import 'package:relivable/ui/back_alley.dart';
import 'package:relivable/ui/intro.dart';
import 'package:relivable/ui/result_popup.dart';
import 'package:shared_preferences/shared_preferences.dart';

const out = String.fromEnvironment('OUT', defaultValue: 'build/screens');

/// How deep in trouble each render is.
void _setUp(Life l, String mood) {
  l.age = 27;
  l.money = 40000;
  l.sceneQueue.clear();
  l.cases.clear();
  l.notoriety = 0;
  l.dirty = 0;
  l.crew.clear();
  l.marks.removeWhere((m) => m.startsWith('wall'));
  void did(List<String> ids, [int times = 1]) {
    for (var i = 0; i < times; i++) {
      for (final id in ids) {
        noteCrime(l, id);
      }
    }
  }

  switch (mood) {
    case 'warm':
      l.notoriety = 8;
      l.dirty = 30000;
      did(['shoplift', 'pickpocket'], 2);
    case 'hot':
      l.notoriety = 15;
      l.dirty = 120000;
      l.crew['id'] = 'velvet';
      did(['shoplift', 'fraud', 'identity_theft', 'hacking', 'burglary'], 3);
      l.cases.add({'crime': 'burglary', 'evidence': 30, 'age': 26});
    case 'redhot':
      l.notoriety = 25;
      l.dirty = 900000;
      l.crew['id'] = 'harbour';
      did([
        'shoplift',
        'pickpocket',
        'graffiti',
        'burglary',
        'car_theft',
        'smuggling',
        'crew_job',
        'plan_heist',
        'extortion',
        'armed_robbery',
        'counterfeiting',
      ], 4);
      l.cases
        ..add({'crime': 'armed_robbery', 'evidence': 60, 'age': 26})
        ..add({'crime': 'smuggling', 'evidence': 40, 'age': 27});
  }
}

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
  for (final mood in const ['clean', 'warm', 'hot', 'redhot']) {
    for (final (w, h) in const [(1280.0, 1300.0), (390.0, 900.0)]) {
      testWidgets('crime $mood ${w.toInt()}', (t) async {
        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.setMockInitialValues({});
        await t.runAsync(_fonts);
        t.view.physicalSize = Size(w, h);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        late GameController c;
        await t.runAsync(() async {
          c = GameController();
          await c.load();
        });
        Sound.instance.enabled = false;
        c.startLife(seed: 33);
        _setUp(c.life!, mood);
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
        if (w < 1000) {
          await t.tap(find.bySemanticsLabel('Open activities').first);
          for (var i = 0; i < 8; i++) {
            await t.pump(const Duration(milliseconds: 150));
          }
        }
        // The Activities list builds lazily: scroll down to Crime.
        final list = find
            .ancestor(
              of: find.textContaining('Pick what to do this year'),
              matching: find.byType(Scrollable),
            )
            .first;
        final tile = find.text('Crime');
        final el = list.evaluate().first;
        await t.scrollUntilVisible(
          tile,
          300,
          scrollable: find.byElementPredicate((e) => e == el),
        );
        await t.pump(const Duration(milliseconds: 200));
        await t.tap(tile.last);
        await t.pump(const Duration(milliseconds: 200));
        // Back to the top of the Crime page for the picture.
        await t.scrollUntilVisible(
          find.byType(AlleyScene),
          -300,
          scrollable: find.byElementPredicate((e) => e == el),
        );
        for (var i = 0; i < 10; i++) {
          await t.pump(const Duration(milliseconds: 150));
        }
        await t.runAsync(() async {
          final b =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await b.toImage(pixelRatio: 1);
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          Directory(out).createSync(recursive: true);
          File('$out/crime_${mood}_${w.toInt()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
        // A crime result on the page: case notes with a stamp.
        if (mood == 'hot' && w < 1000) {
          unawaited(
            showResultPopup(
              t.element(find.byType(AlleyScene)),
              ActionResult(
                'You lifted a wallet on the tram and melted into the crowd before anyone looked up.',
                ['Money +€340', 'Happiness +2'],
              ),
              title: 'Pickpocket',
              icon: Icons.back_hand_rounded,
            ),
          );
          for (var i = 0; i < 8; i++) {
            await t.pump(const Duration(milliseconds: 150));
          }
          await t.runAsync(() async {
            final b =
                key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final img = await b.toImage(pixelRatio: 1);
            final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
            File('$out/crime_result_${w.toInt()}.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
          });
        }
      });
    }
  }
}
