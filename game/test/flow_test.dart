import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/actions.dart';
import 'package:relivable/engine/kin.dart';
import 'package:relivable/engine/models.dart';
import 'package:relivable/engine/relationships.dart';
import 'package:relivable/game_controller.dart';
import 'package:relivable/sound.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The game as the player drives it: events, Continue, activities and
/// saving, through the same controller the screens use.
Future<GameController> _game({int seed = 7}) async {
  final c = GameController();
  await c.load();
  Sound.instance.enabled = false;
  c.startLife(seed: seed);
  return c;
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  seasonClock = () => DateTime(2026, 8, 1);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a multi-step scene runs on with only a choice and Continue', () async {
    final c = await _game();
    c.life!.age = 30;
    c.openScene('house_hunt');
    expect(c.pendingEvent?.id, 'scene:house_hunt');
    c.choose(c.pendingEvent!.choices.first);
    expect(c.pendingEvent, isNull);
    expect(c.lastOutcome, isNotNull);
    c.dismissOutcome();
    expect(c.pendingEvent?.id, 'scene:house_view');
    expect(c.life!.currentScene, startsWith('house_view:'));
  });

  test('nothing else starts while an event is open', () async {
    final c = await _game();
    c.life!.age = 30;
    c.openScene('house_hunt');
    final walk = allActions.firstWhere((a) => a.id == 'walk');
    final energy = c.life!.energy;
    final r = c.runAction(walk);
    expect(r.text, contains('Life tab'));
    expect(c.life!.energy, energy);
    expect(c.busyReason, isNotNull);
    final mum = c.life!.who('@parent')!;
    final talk = interactions.firstWhere((i) => i.appliesTo(mum));
    expect(c.interact(mum, talk).text, contains('Life tab'));
  });

  test('Age +1 shows a waiting step instead of skipping a year', () async {
    final c = await _game();
    c.life!.age = 30;
    c.openScene('house_hunt');
    c.choose(c.pendingEvent!.choices.first);
    c.ageUp();
    expect(c.life!.age, 30);
    expect(c.pendingEvent?.id, 'scene:house_view');
  });

  test('an unfinished scene survives closing the app', () async {
    final c = await _game();
    c.life!.age = 30;
    c.openScene('house_hunt');
    c.choose(c.pendingEvent!.choices.first);
    c.dismissOutcome();
    final key = c.life!.currentScene;
    await _settle();
    final again = GameController();
    await again.load();
    expect(again.life, isNotNull);
    expect(again.pendingEvent?.id, 'scene:house_view');
    expect(again.life!.currentScene, key);
  });

  test('big news from a birthday is picked out for a pop-up', () {
    final picked = bigNews([
      FeedEntry(30, 'Health +2 · Cash +\$400', kind: 'summary'),
      FeedEntry(
        30,
        'Your grandfather died peacefully in his sleep.',
        kind: 'npc',
      ),
      FeedEntry(30, 'Ana took up pottery.', kind: 'npc'),
      FeedEntry(30, 'You were diagnosed with asthma.', kind: 'serious'),
    ]);
    expect(picked, hasLength(2));
    expect(picked.first, contains('died'));
  });
}
