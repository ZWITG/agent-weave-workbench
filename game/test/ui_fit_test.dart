import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/kin.dart';
import 'package:relivable/engine/models.dart';
import 'package:relivable/game_controller.dart';
import 'package:relivable/main.dart';
import 'package:relivable/sound.dart';
import 'package:relivable/ui/shop_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Every main screen at small phone sizes and large text: nothing may be
/// cut off (a "RenderFlex overflowed" error fails the test and says where).
const _sizes = [Size(320, 568), Size(375, 667), Size(390, 844)];

Future<GameController> _game() async {
  final c = GameController();
  await c.load();
  Sound.instance.enabled = false;
  c.startLife(seed: 11);
  final l = c.life!;
  l.age = 34;
  l.money = 25000;
  l.debts['Credit card'] = 1800;
  l.job = 'Senior software engineer at a very long company name';
  l.salary = 72000;
  l.assets.add(
    Asset(
      id: 'car1',
      kind: 'car',
      name: 'Family car',
      value: 14000,
      yearlyCost: 1800,
      since: 30,
    ),
  );
  return c;
}

Future<void> _pump(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _tapText(WidgetTester t, String text) async {
  final f = find.text(text);
  if (f.evaluate().isEmpty) return;
  await t.ensureVisible(f.first);
  await _pump(t);
  await t.tap(f.first, warnIfMissed: false);
  await _pump(t);
}

Future<void> _scrollAll(WidgetTester t) async {
  final lists = find.byType(Scrollable);
  if (lists.evaluate().isEmpty) return;
  for (var i = 0; i < 6; i++) {
    await t.drag(lists.first, const Offset(0, -400), warnIfMissed: false);
    await _pump(t);
  }
  await t.drag(lists.first, const Offset(0, 4000), warnIfMissed: false);
  await _pump(t);
}

Future<void> _back(WidgetTester t) async {
  final b = find
      .byTooltip('Back to People')
      .evaluate()
      .followedBy(find.byTooltip('Back to Path').evaluate())
      .followedBy(find.byTooltip('Back to Wealth').evaluate())
      .followedBy(find.byTooltip('Back to Me').evaluate())
      .followedBy(find.byTooltip('Back to Shop').evaluate());
  if (b.isNotEmpty) {
    await t.tapAt(t.getCenter(find.byWidget(b.first.widget)));
    await _pump(t);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  seasonClock = () => DateTime(2026, 8, 1);

  for (final size in _sizes) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('fits ${size.width.toInt()}x${size.height.toInt()} '
          'at text x$scale', (t) async {
        SharedPreferences.setMockInitialValues({});
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        final problems = <String>{};
        final old = FlutterError.onError;
        FlutterError.onError = (d) {
          final msg = d.exceptionAsString();
          if (msg.contains('overflowed')) {
            final full = d.toString();
            final where = RegExp(r'lib/(ui/)?\w+\.dart:\d+')
                .allMatches(full)
                .map((m) => m.group(0))
                .toSet()
                .join(' ');
            problems.add('${msg.split('\n').first} at $where');
          } else {
            old?.call(d);
          }
        };
        addTearDown(() => FlutterError.onError = old);
        late GameController c;
        await t.runAsync(() async => c = await _game());
        c.profile.textScale = scale;
        await t.pumpWidget(RelivableApp(controller: c));
        await _pump(t);
        // Life tab and the Activities panel.
        await _scrollAll(t);
        await _tapText(t, 'Swipe up for activities');
        await _scrollAll(t);
        await _tapText(t, 'Wellbeing');
        await _scrollAll(t);
        await t.tapAt(const Offset(10, 10));
        await _pump(t);
        // Each tab, its home and one section.
        for (final (tab, section) in const [
          ('People', 'Family'),
          ('Path', 'Job board'),
          ('Wealth', 'Bank and loans'),
          ('Me', 'Family tree'),
        ]) {
          await t.tap(find.text(tab).last);
          await _pump(t);
          await _scrollAll(t);
          await _tapText(t, section);
          await _scrollAll(t);
          await _back(t);
        }
        // The shop and its departments.
        final nav = t.state<NavigatorState>(find.byType(Navigator).first);
        nav.push(MaterialPageRoute(builder: (_) => ShopScreen(controller: c)));
        await _pump(t);
        await _scrollAll(t);
        await _tapText(t, 'Tech');
        await _scrollAll(t);
        await _back(t);
        await _tapText(t, 'Your stuff');
        await _back(t);
        nav.pop();
        await _pump(t);

        // A person sheet.
        await t.tap(find.text('People').last);
        await _pump(t);
        await _tapText(t, 'Family');
        final card = find.textContaining('years').first;
        if (card.evaluate().isNotEmpty) {
          await t.tap(card, warnIfMissed: false);
          await _pump(t);
          await _scrollAll(t);
          nav.popUntil((r) => r.isFirst);
          await _pump(t);
        }
        await _back(t);

        // Health and Settings screens.
        await t.tap(find.text('Me').last);
        await _pump(t);
        for (final screen in const ['Health', 'Settings']) {
          await _tapText(t, screen);
          await _scrollAll(t);
          nav.popUntil((r) => r.isFirst);
          await _pump(t);
        }

        // An event card with long choices, its outcome and the next step.
        await t.tap(find.text('Life').last);
        await _pump(t);
        c.openScene('house_hunt');
        await _pump(t);
        await _scrollAll(t);
        c.choose(c.pendingEvent!.choices.first);
        await _pump(t);
        c.dismissOutcome();
        await _pump(t);
        await _scrollAll(t);

        // The end of a life: recap, story cards, then a new life.
        c.endThisLife();
        await _pump(t);
        await _scrollAll(t);
        await _tapText(t, 'Your Life Recap');
        nav.popUntil((r) => r.isFirst);
        await _pump(t);
        c.endLife();
        await _pump(t);
        await _scrollAll(t);
        FlutterError.onError = old;
        expect(problems, isEmpty, reason: problems.join('\n'));
      });
    }
  }
}
