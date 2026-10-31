import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/ui/intro.dart';

void main() {
  Future<bool Function()> show(WidgetTester t, Size size) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    var done = false;
    await t.pumpWidget(
      MaterialApp(home: IntroSplash(onDone: () => done = true)),
    );
    return () => done;
  }

  for (final size in const [Size(320, 568), Size(1280, 800)]) {
    testWidgets(
      'ZWITG, then Relivable, then the game (${size.width.toInt()})',
      (t) async {
        final done = await show(t, size);
        await t.pump(const Duration(milliseconds: 900));
        expect(find.text('ZWITG'), findsOneWidget);
        expect(find.text('Relivable'), findsNothing);
        await t.pump(const Duration(milliseconds: 1500));
        expect(find.text('ZWITG'), findsNothing);
        expect(find.text('Relivable'), findsOneWidget);
        expect(done(), isFalse);
        await t.pump(const Duration(milliseconds: 1400));
        expect(done(), isTrue);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets('a tap skips the intro', (t) async {
    final done = await show(t, const Size(390, 844));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.byType(IntroSplash));
    expect(done(), isTrue);
  });
}
