// Renders real screens from the "Calling" update (special careers) for the
// Instagram batch: Career Hubs in their looks, the Curtain, the new
// mini-games, a stamped result and a Life Recap page. Phone size (390x844)
// at 2x. Not part of the suite:
//   flutter test tool/render_calling_promo_test.dart --dart-define=OUT=<dir>
// then: python3 tool/make_calling_posts.py <dir> media/social/calling
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/actions.dart' show ActionResult;
import 'package:relivable/engine/careers.dart';
import 'package:relivable/engine/currency.dart' show activeCountry;
import 'package:relivable/engine/recap.dart';
import 'package:relivable/game_controller.dart';
import 'package:relivable/main.dart';
import 'package:relivable/sound.dart';
import 'package:relivable/theme.dart';
import 'package:relivable/ui/career_curtain.dart';
import 'package:relivable/ui/career_hub_screen.dart';
import 'package:relivable/ui/intro.dart';
import 'package:relivable/ui/life_recap.dart';
import 'package:relivable/ui/minigames.dart' show showMiniGame;
import 'package:relivable/ui/result_popup.dart';
import 'package:shared_preferences/shared_preferences.dart';

const out = String.fromEnvironment('OUT', defaultValue: 'build/calling');

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

Future<void> _frames(WidgetTester t, int n, [int ms = 150]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(Duration(milliseconds: ms));
  }
}

Future<void> _shot(WidgetTester t, GlobalKey key, String name) => t.runAsync(
  () async {
    final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final img = await b.toImage(pixelRatio: 2);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory('$out/stills').createSync(recursive: true);
    File('$out/stills/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
  },
);

/// A game at age [age] in career [id], with a lively Hub.
Future<(GameController, GlobalKey)> _setUp(
  WidgetTester t,
  String id, {
  int age = 31,
  int rank = 1,
  int meter = 64,
  bool curtain = false,
}) async {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({});
  await t.runAsync(_fonts);
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  CareerCurtain.enabled = curtain;
  addTearDown(() => CareerCurtain.enabled = true);
  late GameController c;
  await t.runAsync(() async {
    c = GameController();
    await c.load();
  });
  Sound.instance.enabled = false;
  c.startLife(seed: 77);
  // English-language ads: an American life, in dollars.
  activeCountry = 'United States';
  final l = c.life!
    ..age = age
    ..country = 'United States'
    ..city = 'Chicago';
  l.money = 184000;
  final key = GlobalKey();
  await t.pumpWidget(
    RepaintBoundary(
      key: key,
      child: RelivableApp(controller: c),
    ),
  );
  await _frames(t, 6);
  if (!curtain) {
    startCareer(l, careerById(id)!);
    l.sceneQueue.clear();
    l.careerRank = rank;
    l.job = careerById(id)!.ladder[rank];
    l.hub['meter'] = meter;
    l.hub['beat'] = 2;
    c.notifyListeners();
    await _frames(t, 8);
  }
  return (c, key);
}

void main() {
  IntroSplash.enabled = false;

  // Career Hubs, each in its look.
  for (final (id, rank, meter, extra) in const [
    ('actor', 2, 72, 'actor'),
    ('astronaut', 2, 81, 'astronaut'),
    ('fighter', 2, 84, 'fighter'),
    ('politician', 1, 63, ''),
    ('lawyer', 2, 77, ''),
    ('doctor', 2, 69, ''),
    ('pilot', 1, 47, ''),
    ('vet', 2, 58, ''),
    ('hustler', 1, 66, ''),
    ('musician', 1, 70, ''),
    ('athlete', 2, 76, ''),
    ('model', 2, 68, ''),
    ('military', 3, 74, ''),
    ('police', 3, 60, ''),
  ]) {
    testWidgets('hub $id', (t) async {
      final (c, key) = await _setUp(t, id, rank: rank, meter: meter);
      final l = c.life!;
      if (extra == 'actor') {
        l.hub['agent'] = 1;
        l.hub['project'] = {
          'title': 'Paper Crowns',
          'kind': 'a film',
          'stage': 'released',
        };
      }
      if (extra == 'astronaut') l.hub['flown'] = ['station'];
      if (extra == 'fighter') {
        l.hub['style'] = 'MMA';
        l.hub['wins'] = 14;
        l.hub['losses'] = 2;
        l.hub['kos'] = 9;
      }
      if (id == 'musician') l.music['fans'] = 260000;
      if (id == 'hustler') l.hub['pitch'] = 'square';
      if (id == 'police') l.marks.add('cop_closed:8');
      l.hub['log'] = <String>[];
      final nav = t.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(
        MaterialPageRoute(builder: (_) => CareerHubScreen(controller: c)),
      );
      await _frames(t, 14);
      await _shot(t, key, 'hub_$id');
    });
  }

  // The Curtain: the look opening as a career starts.
  for (final id in const ['actor', 'astronaut', 'fighter']) {
    testWidgets('curtain $id', (t) async {
      final (c, key) = await _setUp(t, id, curtain: true);
      startCareer(c.life!, careerById(id)!);
      c.life!.sceneQueue.clear();
      c.notifyListeners();
      await t.pump(const Duration(milliseconds: 16));
      await t.pump(const Duration(milliseconds: 900));
      await _shot(t, key, 'curtain_$id');
      await _frames(t, 30, 100);
    });
  }

  // The new mini-games.
  for (final (id, act, game) in const [
    ('fighter', 'fig_fight', 'fight'),
    ('astronaut', 'ast_sim', 'docking'),
  ]) {
    testWidgets('game $game', (t) async {
      final (_, key) = await _setUp(t, id);
      final ctx = t.element(find.byType(Scaffold).first);
      showMiniGame(
        ctx,
        game,
        age: 30,
        title: game == 'fight' ? 'Fight night' : 'Docking simulator',
        activity: act,
        game: game,
      );
      await _frames(t, 12, 100);
      await _shot(t, key, 'game_$game');
    });
  }

  // A stamped result.
  testWidgets('stamp fighter', (t) async {
    final (_, key) = await _setUp(t, 'fighter');
    final ctx = t.element(find.byType(Scaffold).first);
    showResultPopup(
      ctx,
      ActionResult(
        'You walked through Danny "The Hammer"\'s jab and ended it in the second round. The crowd was on its feet.',
        ['Ranking +7', 'Money +\$48,000'],
      ),
      title: 'Fight',
      look: NF.career,
    );
    await _frames(t, 4);
    await _shot(t, key, 'stamp_fighter');
  });

  // A Life Recap page for a career.
  testWidgets('recap astronaut', (t) async {
    final (c, key) = await _setUp(t, 'astronaut', rank: 3, meter: 88);
    final l = c.life!;
    l.hub['flown'] = ['station', 'moon', 'mars'];
    l.hub['since'] = 26;
    l.hub['log'] = [
      'Age 49: flew to Mars',
      'Age 41: flew to the Moon',
      'Age 33: flew to the space station',
    ];
    l.age = 58;
    final nav = t.state<NavigatorState>(find.byType(Navigator).first);
    nav.push(MaterialPageRoute(builder: (_) => LifeRecapScreen(controller: c)));
    await _frames(t, 6);
    final at = recapCards(l).indexWhere((x) => x.kind == 'look:astronaut');
    t.widget<PageView>(find.byType(PageView)).controller!.jumpToPage(at);
    await _frames(t, 6);
    await _shot(t, key, 'recap_astronaut');
  });

  // Motion for the Reel: two seconds of each Hub's scene and instrument,
  // 30 frames a second, to OUT/reel_<id>/f0000.png.
  for (final (id, rank, meter) in const [
    ('actor', 2, 72),
    ('musician', 1, 81),
    ('athlete', 2, 76),
    ('politician', 1, 63),
    ('astronaut', 2, 81),
    ('fighter', 2, 84),
    ('doctor', 2, 69),
    ('police', 3, 60),
  ]) {
    testWidgets('reel $id', (t) async {
      final (c, key) = await _setUp(t, id, rank: rank, meter: meter);
      if (id == 'musician') c.life!.music['fans'] = 260000;
      if (id == 'fighter') c.life!.hub['style'] = 'MMA';
      if (id == 'police') c.life!.marks.add('cop_closed:8');
      final nav = t.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(
        MaterialPageRoute(builder: (_) => CareerHubScreen(controller: c)),
      );
      await _frames(t, 8);
      final dir = Directory('$out/reel_$id')..createSync(recursive: true);
      for (var i = 0; i < 60; i++) {
        await t.pump(const Duration(milliseconds: 33));
        await t.runAsync(() async {
          final b =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await b.toImage(pixelRatio: 2);
          final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
          File('${dir.path}/f${i.toString().padLeft(4, '0')}.png')
              .writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      }
    });
  }
}
