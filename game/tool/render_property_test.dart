// Renders Wealth › Real estate to a PNG for a visual check. Not part of
// the suite:
//   flutter test tool/render_property_test.dart --dart-define=OUT=<dir>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/homes.dart';
import 'package:relivable/engine/realty.dart';
import 'package:relivable/game_controller.dart';
import 'package:relivable/main.dart';
import 'package:relivable/sound.dart';
import 'package:relivable/ui/intro.dart';
import 'package:shared_preferences/shared_preferences.dart';

const out = String.fromEnvironment('OUT', defaultValue: 'build/screens');

/// --dart-define=EMPTY=true renders a life with no property (the plot).
const empty = bool.fromEnvironment('EMPTY');

void main() {
  IntroSplash.enabled = false;
  for (final (w, h) in const [(390.0, 2900.0), (320.0, 2900.0)]) {
    testWidgets('real estate ${w.toInt()}', (t) async {
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
            final p =
                '${Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter-sdk/flutter'}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
            f.addFont(
              Future.value(ByteData.sublistView(File(p).readAsBytesSync())),
            );
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
      l.age = 38;
      l.money = 900000;
      l.economy = 'Normal';
      final homes = listings(l);
      if (!empty) buyListing(l, homes[0], homes[0].price);
      if (!empty) {
        buyListing(l, homes[1], homes[1].price);
        buyListing(l, homes[2], homes[2].price);
        final lets = l.assets.where((a) => a.info['let'] == true).toList();
        lets[0].info['tenant'] = {
          'kind': 'family',
          'name': 'Ana Rivera',
          'since': 36,
        };
        makeHolidayLet(l, lets[1]);
        buyListing(l, homes[3], homes[3].price);
        buyListing(l, homes[4], homes[4].price);
        buyCommercial(l, commercialUnits(l).first);
        lets[0].info['traits'] = ['haunted'];
      }
      l.money = 120000;
      l.sceneQueue.clear();
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
      await t.tap(find.text('Wealth').first);
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 150));
      }
      await t.tap(find.text('Real estate').first);
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 150));
      }
      // Let the home icons decode.
      for (var i = 0; i < 3; i++) {
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 400)),
        );
        await t.pump(const Duration(milliseconds: 50));
      }
      await t.runAsync(() async {
        final b =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        Directory(out).createSync(recursive: true);
        File('$out/real_estate${empty ? '_empty' : ''}_${w.toInt()}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      // A property scene keeps the look on the Life tab.
      if (!empty) {
        c.openScene('sell_home:${homeOf(l)!.id}');
        c.goToEvent();
        for (var i = 0; i < 12; i++) {
          await t.pump(const Duration(milliseconds: 150));
        }
        await t.runAsync(() async {
          final b =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await b.toImage(pixelRatio: 1);
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          File('$out/sale_scene_${w.toInt()}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    });
  }
}
