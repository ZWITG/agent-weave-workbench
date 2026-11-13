// The main header on a small phone with large text, measured with the
// game's real font (the test font makes every character a full em). In its
// own file: a loaded font would change the other UI tests' layouts.
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/career_hub.dart' show hubMeter;
import 'package:relivable/engine/careers.dart';
import 'package:relivable/game_controller.dart';
import 'package:relivable/main.dart';
import 'package:relivable/sound.dart';
import 'package:relivable/ui/career_curtain.dart';
import 'package:relivable/ui/intro.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pump(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  IntroSplash.enabled = false;
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the header keeps the name readable on a small phone', (t) async {
    // Real glyph widths: the test font makes every character a full em.
    await t.runAsync(() async {
      final f = FontLoader('Sora')
        ..addFont(rootBundle.load('assets/fonts/Sora-Variable.ttf'));
      await f.load();
    });
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(320, 568);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    late GameController c;
    await t.runAsync(() async {
      c = GameController();
      await c.load();
    });
    Sound.instance.enabled = false;
    c.startLife(seed: 11);
    c.life!.age = 34;
    c.updateProfile((p) => p.textScale = 1.3);
    CareerCurtain.enabled = false;
    addTearDown(() => CareerCurtain.enabled = true);
    await t.pumpWidget(RelivableApp(controller: c));
    await pump(t);
    final l = c.life!..money = 25000;
    l.fame = 40;
    startCareer(l, careerById('politician')!);
    l.sceneQueue.clear();
    c.notifyListeners();
    await pump(t);
    // The name column keeps its room; money goes short when it must.
    final city = find.textContaining(l.city).first;
    expect(t.getSize(city).width, greaterThan(90));
    expect(find.text('\$25K'), findsOneWidget);
    // The meter chip has room too.
    expect(find.text(' ${hubMeter(l)}'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
