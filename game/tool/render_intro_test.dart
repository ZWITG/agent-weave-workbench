// Renders the opening animation frame by frame (60 fps) for the shareable
// intro video. Not part of the test suite; run it on its own:
//   flutter test tool/render_intro_test.dart --dart-define=OUT=<dir>
// then encode the frames with tool/make_intro_video.sh.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/theme.dart';
import 'package:relivable/ui/intro.dart';

const out = String.fromEnvironment('OUT', defaultValue: 'build/intro_frames');

void main() {
  for (final (name, size) in const [
    ('square', Size(540, 540)),
    ('vertical', Size(540, 960)),
  ]) {
    testWidgets('render $name', (t) async {
      await t.runAsync(() async {
        final font = FontLoader('Sora')
          ..addFont(rootBundle.load('assets/fonts/Sora-Variable.ttf'));
        await font.load();
      });
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final key = GlobalKey();
      await t.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
            key: key,
            child: ColoredBox(
              color: NF.bg,
              child: IntroSplash(onDone: () {}),
            ),
          ),
        ),
      );
      final dir = Directory('$out/$name')..createSync(recursive: true);
      // Up to the moment the intro would fade into the game (86% of
      // 3.6 s); the video adds its own hold and fade to black.
      const frames = 186;
      for (var i = 0; i < frames; i++) {
        if (i > 0) await t.pump(const Duration(microseconds: 16667));
        await t.runAsync(() async {
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '${dir.path}/f${i.toString().padLeft(4, '0')}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    });
  }
}
