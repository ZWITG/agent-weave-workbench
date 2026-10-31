import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/kin.dart';
import 'package:relivable/engine/models.dart';
import 'package:relivable/game_controller.dart';
import 'package:relivable/main.dart';
import 'package:relivable/sound.dart';
import 'package:relivable/engine/actions.dart';
import 'package:relivable/ui/activities.dart';
import 'package:relivable/ui/minigames.dart';
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

  testWidgets('every activity mini-game is themed and fits a small phone', (
    t,
  ) async {
    final games = allActions.where((a) => a.miniGame != null).toList();
    expect(games.length, greaterThanOrEqualTo(11));
    for (final a in games) {
      expect(miniThemes.containsKey(a.id), isTrue, reason: a.id);
    }
    t.view.physicalSize = const Size(320, 568);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final problems = <String>[];
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      final msg = d.exceptionAsString();
      if (msg.contains('overflowed')) {
        problems.add(msg.split('\n').first);
      } else {
        old?.call(d);
      }
    };
    final key = GlobalKey<NavigatorState>();
    await t.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1.3)),
          child: child!,
        ),
        home: const Scaffold(),
      ),
    );
    // Every game an activity rotates through, with its own instructions.
    for (final a in games) {
      final pool = miniPools[a.id] ?? [a.miniGame!];
      expect(pool.length, greaterThanOrEqualTo(2), reason: a.id);
      for (final g in pool) {
        showMiniGame(
          key.currentContext!,
          a.miniGame!,
          age: 20,
          title: a.label,
          activity: a.id,
          game: g,
        );
        await t.pump(const Duration(milliseconds: 400));
        await t.pump(const Duration(milliseconds: 400));
        await t.pump(const Duration(seconds: 2));
        expect(
          find.text(miniIntro(a.id, g)),
          findsOneWidget,
          reason: '${a.id} / $g',
        );
        key.currentState!.pop();
        await t.pump(const Duration(milliseconds: 400));
        await t.pump(const Duration(seconds: 3));
      }
    }
    // The same activity never offers the same game twice in a row.
    for (final id in miniPools.keys) {
      var last = pickMiniGame(id, '');
      for (var i = 0; i < 10; i++) {
        final g = pickMiniGame(id, '');
        expect(g, isNot(last), reason: id);
        last = g;
      }
    }
    FlutterError.onError = old;
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  testWidgets('timed mini-games run to a score; blackjack plays out', (
    t,
  ) async {
    final key = GlobalKey<NavigatorState>();
    await t.pumpWidget(MaterialApp(navigatorKey: key, home: const Scaffold()));
    for (final (activity, g) in [
      ('reflect', 'balance'),
      ('driving_lessons', 'lanes'),
      ('video_games', 'whack'),
      ('instrument', 'rhythm'),
      ('study', 'words'),
    ]) {
      double? score = -1;
      showMiniGame(
        key.currentContext!,
        'reps',
        age: 20,
        title: g,
        activity: activity,
        game: g,
      ).then((v) => score = v);
      // Words gives 14 seconds a word if nobody plays.
      for (var i = 0; i < 200; i++) {
        await t.pump(const Duration(milliseconds: 250));
      }
      expect(find.text('Continue'), findsOneWidget, reason: g);
      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(score, inInclusiveRange(0, 1), reason: g);
    }
    double? score = -1;
    showMiniGame(
      key.currentContext!,
      'cards',
      age: 20,
      title: 'Casino',
      activity: 'casino',
      game: 'blackjack',
    ).then((v) => score = v);
    await t.pumpAndSettle();
    for (var hand = 0; hand < 3; hand++) {
      if (find.text('Stand').evaluate().isNotEmpty) {
        await t.tap(find.text('Stand'));
        await t.pump();
      }
      await t.tap(find.textContaining(hand == 2 ? 'See result' : 'Next hand'));
      await t.pump();
    }
    await t.tap(find.text('Continue'));
    await t.pumpAndSettle();
    expect(score, inInclusiveRange(0, 1));
  });

  testWidgets('social media and fame are categories in Activities', (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    late GameController c;
    await t.runAsync(() async => c = await _game());
    await t.pumpWidget(RelivableApp(controller: c));
    await _pump(t);
    await _tapText(t, 'Swipe up for activities');
    await t.scrollUntilVisible(
      find.text('Music, fame and social media'),
      200,
      scrollable: find
          .ancestor(
            of: find.text('Look after yourself'),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await _pump(t);
    expect(find.text('Music, fame and social media'), findsOneWidget);
    await _tapText(t, 'Social media');
    expect(find.text('Post on Vybe'), findsOneWidget);
    expect(find.text('Post on Hearthcast'), findsOneWidget);
    // Posting asks what kind of post, right in Activities.
    await _tapText(t, 'Post on Vybe');
    expect(find.text('Talent clip'), findsOneWidget);
    await _tapText(t, 'Talent clip');
    await _pump(t);
    expect(c.life!.followers['vybe'], isNotNull);
    // Let the achievement toasts that the first post unlocks play out.
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(seconds: 3));
    }
  });

  testWidgets('moving abroad picks a country from a drop-down list', (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    late GameController c;
    await t.runAsync(() async => c = await _game());
    final move = c.engine!.actions.firstWhere((a) => a.id == 'emigrate');
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  runActionFlow(context, c, move, closeSheet: false),
              child: const Text('Move'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Move'));
    await _pump(t);
    expect(find.text('Choose a country'), findsOneWidget);
    // Just looking uses nothing up.
    expect(c.life!.usedActions, isNot(contains('emigrate')));
    await t.tap(find.text('Choose a country'));
    await _pump(t);
    await t.tap(find.text('Japan').last);
    await _pump(t);
    expect(find.text('Visa'), findsOneWidget);
    expect(find.textContaining('Apply for a visa'), findsOneWidget);
    final cash = c.life!.money;
    await t.tap(find.textContaining('Apply for a visa'));
    await _pump(t);
    expect(c.life!.money, lessThanOrEqualTo(cash - 3000));
    expect(c.life!.usedActions, contains('emigrate'));
    expect(find.text('Moving to Japan'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(seconds: 3));
    }
  });

  testWidgets('players name their own songs', (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    late GameController c;
    await t.runAsync(() async => c = await _game());
    c.profile.autoMiniGames = true;
    final write = c.engine!.actions.firstWhere((a) => a.id == 'write_song');
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  runActionFlow(context, c, write, closeSheet: false),
              child: const Text('Write'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Write'));
    await _pump(t);
    await _tapText(t, 'Pop');
    expect(find.text('Name your song'), findsOneWidget);
    await t.enterText(find.byType(TextField), '  Kitchen   Disco  ');
    await _tapText(t, 'Name it');
    expect(c.life!.songs.last['title'], 'Kitchen Disco');
    expect(find.textContaining('"Kitchen Disco"'), findsOneWidget);
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(seconds: 3));
    }
  });

  testWidgets('a fame badge shows only when you have some fame', (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    late GameController c;
    await t.runAsync(() async => c = await _game());
    c.life!.fame = 0;
    await t.pumpWidget(RelivableApp(controller: c));
    await _pump(t);
    expect(find.text('Celebrity'), findsNothing);
    expect(find.textContaining('Fame '), findsNothing);
    c.life!.fame = 50;
    c.updateProfile((_) {});
    await _pump(t);
    expect(find.text('Celebrity'), findsOneWidget);
    // Tapping it opens the Social screen.
    await t.tap(find.text('Celebrity'));
    await _pump(t);
    expect(find.text('Fame'), findsWidgets);
    expect(find.textContaining('Public image'), findsOneWidget);
  });

  testWidgets('owned things expand to show their options', (t) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    late GameController c;
    await t.runAsync(() async => c = await _game());
    final l = c.life!;
    l.assets.add(
      Asset(
        id: 'home1',
        kind: 'house',
        name: 'Terraced house',
        value: 250000,
        yearlyCost: 3000,
        since: 32,
        info: {'area': 'Old Town'},
      ),
    );
    l.assets.add(
      Asset(
        id: 'let1',
        kind: 'house',
        name: 'Flat',
        value: 150000,
        yearlyCost: 1800,
        since: 33,
        info: {'area': 'Northgate', 'let': true, 'tenant': null},
      ),
    );
    await t.pumpWidget(RelivableApp(controller: c));
    await _pump(t);
    // Tapping your money opens the Wealth tab.
    await t.tap(find.text('\$25,000').first);
    await _pump(t);
    expect(find.text('What you own'), findsOneWidget);
    await _tapText(t, 'What you own');
    // Closed: the empty rental still shows its one urgent button.
    expect(find.text('Find a tenant'), findsOneWidget);
    expect(find.text('Add a room'), findsNothing);
    // Back to the top of the list, where the homes are.
    await t.drag(find.byType(Scrollable).first, const Offset(0, 2000));
    await _pump(t);
    await _tapText(t, 'Terraced house');
    expect(find.text('Add a room'), findsOneWidget);
    expect(find.text('Remortgage'), findsOneWidget);
    expect(find.text('Sell'), findsOneWidget);
    await _tapText(t, 'Flat');
    expect(find.text('Manage'), findsOneWidget);
  });

  testWidgets('desktop: side tabs, the game and Activities side by side', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues({});
    t.view.physicalSize = const Size(1366, 768);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final problems = <String>[];
    final old = FlutterError.onError;
    FlutterError.onError = (d) {
      final msg = d.exceptionAsString();
      if (msg.contains('overflowed')) {
        problems.add(msg.split('\n').first);
      } else {
        old?.call(d);
      }
    };
    late GameController c;
    await t.runAsync(() async => c = await _game());
    await t.pumpWidget(RelivableApp(controller: c));
    await _pump(t);
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Activities'), findsWidgets);
    await t.tap(find.text('Wellbeing').first);
    await _pump(t);
    await t.tap(find.text('Wealth').first);
    await _pump(t);
    FlutterError.onError = old;
    expect(problems, isEmpty, reason: problems.join('\n'));
  });
}
