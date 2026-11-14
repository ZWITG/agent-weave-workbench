// Records real gameplay for the promo video: one life, played in the real
// game, from childhood through activities, a mini-game, prison (Lockdown
// and the inside tabs), release, and the rise to the very top (Molten, the
// Invitation, a new tier and the Echelon). Stills go to OUT/stills, moving
// moments to OUT/<name>/f0000.png at 30 fps. Not part of the suite:
//   flutter test tool/render_promo_test.dart --dart-define=OUT=<dir>
// then build the video with tool/make_promo_video.py.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/echelon.dart';
import 'package:relivable/engine/justice.dart';
import 'package:relivable/engine/models.dart';
import 'package:relivable/game_controller.dart';
import 'package:relivable/main.dart';
import 'package:relivable/sound.dart';
import 'package:relivable/ui/intro.dart';
import 'package:relivable/ui/minigames.dart';
import 'package:shared_preferences/shared_preferences.dart';

const out = String.fromEnvironment('OUT', defaultValue: 'build/promo');

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
  testWidgets('promo footage', (t) async {
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
    c.startLife(seed: 1207, firstName: 'Maya', gender: 'female');
    final key = GlobalKey();
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: RelivableApp(controller: c),
      ),
    );
    Future<void> settle([int n = 6]) async {
      for (var i = 0; i < n; i++) {
        await t.pump(const Duration(milliseconds: 150));
      }
    }

    Future<void> grab(String path) => t.runAsync(() async {
      final b =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage(pixelRatio: 2);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      final f = File('$out/$path');
      f.parent.createSync(recursive: true);
      f.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
    Future<void> still(String name) => grab('stills/$name.png');
    Future<void> clip(String name, double seconds) async {
      final n = (seconds * 30).round();
      for (var i = 0; i < n; i++) {
        await t.pump(const Duration(microseconds: 33333));
        await grab('$name/f${i.toString().padLeft(4, '0')}.png');
      }
    }

    await settle();
    final l = c.life!;
    final rng = Random(4);
    // ---- Growing up: real birthdays and real choices.
    var events = 0;
    for (var y = 0; y < 24; y++) {
      c.ageUp();
      await settle(2);
      var guard = 0;
      while (c.pendingEvent != null && guard++ < 6) {
        final ev = c.pendingEvent!;
        if (events < 3 && l.age >= 6) {
          await settle(3);
          await still('event_${events++}');
        }
        final open = ev.choices.where((x) => x.lockReason(l) == null).toList();
        if (open.isEmpty) break;
        c.choose(open[rng.nextInt(open.length)]);
        await settle(2);
        if (c.lastOutcome != null) c.dismissOutcome();
        await settle(2);
      }
      if (l.age == 8) await still('life_08');
      if (l.age == 17) await still('life_17');
    }
    await settle();
    await still('life_24');
    // ---- Activities.
    await t.tap(find.text('Swipe up for activities'));
    await settle(8);
    await still('activities_0');
    await t.drag(find.byType(Scrollable).last, const Offset(0, -520));
    await settle(6);
    await still('activities_1');
    Navigator.of(t.element(find.text('Activities').first)).pop();
    await settle();
    // ---- A mini-game.
    final ctx = t.element(find.byType(Scaffold).first);
    showMiniGame(
      ctx,
      'reps',
      age: l.age,
      title: 'Work out · Heavy session',
      activity: 'gym',
      life: l,
    );
    await settle(8);
    await still('mini_0');
    for (final label in ['Tap to start', 'LIFT']) {
      final f = find.text(label);
      if (f.evaluate().isNotEmpty) {
        await t.tap(f.first, warnIfMissed: false);
        await t.pump(const Duration(milliseconds: 120));
      }
    }
    for (var i = 0; i < 14; i++) {
      final f = find.text('LIFT');
      if (f.evaluate().isEmpty) break;
      await t.tap(f.first, warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 140));
    }
    await still('mini_1');
    Navigator.of(ctx).popUntil((r) => r.isFirst);
    await settle(10);
    // ---- People.
    await t.tap(find.text('People').last);
    await settle();
    await still('people');
    await t.tap(find.text('Life').last);
    await settle();
    // ---- Prison: the takeover, played in real time.
    l.age = 31;
    l.money = 4200;
    convict(l, crimeById('burglary'), 4, 'prison');
    c.notifyListeners();
    await clip('lockdown', 4.9);
    await settle(8);
    final p = l.prison!
      ..served = 2
      ..job = 'Library'
      ..behaviour = 71
      ..respect = 58
      ..stash = 9
      ..gangId = 'ledger'
      ..gangRank = 1
      ..gangStanding = 62
      ..nickname = 'Books';
    p.items.addAll(['radio', 'books', 'phone']);
    p.courses.addAll(['diploma', 'trade']);
    p.rivalry['iron'] = 35;
    c.notifyListeners();
    await settle();
    await still('prison_cell');
    for (final tab in ['Visits', 'File', 'Canteen', 'ID']) {
      await t.tap(find.text(tab).last);
      await settle(5);
      await still('prison_${tab.toLowerCase()}');
    }
    await t.tap(find.text('Cell').last);
    await settle();
    await t.tap(find.text('Swipe up for the yard'));
    await settle(10);
    await still('prison_yard');
    Navigator.of(t.element(find.text('THE YARD').first)).pop();
    await settle();
    // ---- Release.
    release(l);
    c.notifyListeners();
    await clip('release', 2.9);
    await settle(10);
    // ---- The top: molten gold, the Invitation, a new tier.
    l.age = 46;
    l.money = 165000000;
    l.flags['upper_echelon'] = Memory(l.age, 'joining the upper echelon');
    echelonYear(l, Random(1));
    l.sceneQueue.clear();
    c.notifyListeners();
    await clip('molten', 10.6);
    await settle(10);
    l.money = 2600000000;
    echelonYear(l, Random(2));
    l.sceneQueue.clear();
    c.notifyListeners();
    await clip('tier', 2.7);
    await settle(16);
    l.echelon['influence'] = 52;
    final rs = rivals(l);
    rs[1]['feud'] = 72;
    l.echelon['rivals'] = rs;
    c.notifyListeners();
    await settle();
    await still('gilded_life');
    await t.tap(find.text('Wealth').last);
    await settle();
    await still('gilded_wealth');
    await t.tap(find.text('THE ECHELON').first);
    await settle(8);
    await still('echelon_0');
    for (var k = 1; k <= 2; k++) {
      await t.drag(find.byType(Scrollable).last, const Offset(0, -640));
      await settle(5);
      await still('echelon_$k');
    }
  });
}
