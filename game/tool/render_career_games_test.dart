// Renders the career mini-games ("Calling", spec 6.2) for visual checks.
// Not part of the suite:
//   flutter test tool/render_career_games_test.dart --dart-define=OUT=<dir>
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/theme.dart';
import 'package:relivable/ui/minigames.dart';

const out = String.fromEnvironment('OUT', defaultValue: 'build/career_games');

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
  const games = {
    'act_audition': 'coldread',
    'mus_rehearse': 'soundcheck',
    'ath_train': 'matchday',
    'pol_speech': 'debate',
    'mod_casting': 'runway',
    'doc_triage': 'triage',
    'vet_clinic': 'diagnose',
    'pil_check': 'crosswind',
    'mil_drill': 'obstacle',
    'law_cross': 'objection',
    'hus_busk': 'pitch',
  };
  for (final MapEntry(key: activity, value: g) in games.entries) {
    testWidgets('career game $g', (t) async {
      await t.runAsync(_fonts);
      t.view.physicalSize = const Size(390, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final key = GlobalKey<NavigatorState>();
      final shot = GlobalKey();
      await t.pumpWidget(
        RepaintBoundary(
          key: shot,
          child: MaterialApp(
            theme: NF.theme(),
            navigatorKey: key,
            home: const Scaffold(),
          ),
        ),
      );
      showMiniGame(
        key.currentContext!,
        g,
        age: 30,
        title: g,
        activity: activity,
        game: g,
      );
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 150));
      }
      await t.runAsync(() async {
        final b =
            shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 1);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        Directory(out).createSync(recursive: true);
        File('$out/$g.png').writeAsBytesSync(bytes!.buffer.asUint8List());
      });
      Navigator.of(key.currentContext!).pop();
      await t.pump(const Duration(seconds: 1));
    });
  }
}
