import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine/actions.dart';
import 'engine/careers.dart';
import 'engine/dynasty.dart';
import 'engine/engine.dart';
import 'engine/health.dart' show endThisLifeRules;
import 'engine/models.dart';
import 'engine/relationships.dart';
import 'engine/storylet.dart';
import 'engine/profile.dart';
import 'engine/scenes.dart';
import 'engine/world.dart';
import 'sound.dart';

/// Holds the current life, talks to the engine and saves on the device
/// after every change (offline-first; cloud sync comes in Phase 3).
class GameController extends ChangeNotifier {
  static const _saveKey = 'relivable.life.v1';

  /// The player's one world, saved apart from the current life so it
  /// survives every life that ends.
  static const _worldKey = 'relivable.world.v1';
  static const _profileKey = 'relivable.profile.v1';

  /// The last few birthdays of the current life, for Rewind.
  static const _rewindKey = 'relivable.rewind.v1';
  static const _rewindDepth = 6;

  Profile profile = Profile();
  final List<Map<String, dynamic>> _snapshots = [];

  GameEngine? engine;
  Life? life;
  Storylet? pendingEvent;
  Outcome? lastOutcome;
  bool loading = true;

  String? loadError;

  Future<void> load() async {
    try {
      await _load();
    } catch (e, st) {
      loadError = '$e';
      debugPrint('Relivable load failed: $e\n$st');
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _load() async {
    final raw = await rootBundle.loadString('assets/storylets/core.json');
    final list = (jsonDecode(raw) as List)
        .map((e) => Storylet.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    engine = GameEngine(list);
    final prefs = await SharedPreferences.getInstance();
    Sound.instance.enabled = prefs.getBool('relivable.sound') ?? true;
    final world = prefs.getString(_worldKey);
    if (world != null) {
      try {
        engine!.world = World.fromJson(jsonDecode(world));
      } catch (_) {
        // A damaged world file starts a fresh history rather than blocking play.
      }
    }
    final prof = prefs.getString(_profileKey);
    if (prof != null) {
      try {
        profile = Profile.fromJson(jsonDecode(prof));
      } catch (_) {}
    }
    final snaps = prefs.getString(_rewindKey);
    if (snaps != null) {
      try {
        _snapshots.addAll([
          for (final s in jsonDecode(snaps) as List)
            Map<String, dynamic>.from(s),
        ]);
      } catch (_) {}
    }
    final saved = prefs.getString(_saveKey);
    if (saved != null) {
      try {
        final j = jsonDecode(saved) as Map<String, dynamic>;
        life = Life.fromJson(Map<String, dynamic>.from(j['life']));
        final pid = j['pending'] as String?;
        if (pid != null) {
          pendingEvent = pid.startsWith('scene:')
              ? buildScene(pid.substring(6), life!)
              : engine!.storylets.where((s) => s.id == pid).firstOrNull;
        }
      } catch (_) {
        life = null;
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (engine != null) {
      await prefs.setString(_worldKey, jsonEncode(engine!.world.toJson()));
    }
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    await prefs.setString(_rewindKey, jsonEncode(_snapshots));
    if (life == null) {
      await prefs.remove(_saveKey);
      return;
    }
    await prefs.setString(
      _saveKey,
      jsonEncode({'life': life!.toJson(), 'pending': pendingEvent?.id}),
    );
  }

  void startLife({
    String? firstName,
    String? gender,
    String? country,
    int? seed,
  }) {
    life =
        engine!.newLife(
            seed: seed,
            firstName: firstName,
            gender: gender,
            countryName: country,
          )
          ..difficulty = profile.difficulty
          ..ironman = profile.ironman
          ..classic = profile.classic;
    _snapshots.clear();
    pendingEvent = null;
    lastOutcome = null;
    _save();
    notifyListeners();
  }

  void endLife() {
    if (life != null) engine!.world.recordLife(life!);
    life = null;
    pendingEvent = null;
    lastOutcome = null;
    _snapshots.clear();
    _save();
    notifyListeners();
  }

  /// The life is over (death, or the very rare 120-year limit).
  bool get sliceFinished =>
      life != null &&
      (!life!.alive ||
          (life!.age >= sliceEndAge &&
              pendingEvent == null &&
              lastOutcome == null));

  // ---------------- Dynasty (plan Social §4) ----------------

  int get generationCap => dynastyCap(plus: profile.plusTest);

  /// Continue the family as one of the children.
  void continueAsHeir(Npc heir) {
    final old = life!;
    engine!.world.recordLife(old);
    life = heirLife(old, heir);
    engine!.world.ensureYear(life!.year, life!.country, life!.city);
    life!.quotes = Map.of(engine!.world.pricesFor(life!.year));
    pendingEvent = null;
    lastOutcome = null;
    _snapshots.clear();
    _save();
    notifyListeners();
  }

  /// "End this life" (plan HE: neutral, out of character): straight to the
  /// recap. The helpline panel shows once per session before it.
  bool helplineShown = false;

  void endThisLife() {
    if (life == null) return;
    endThisLifeRules(life!);
    pendingEvent = null;
    lastOutcome = null;
    _save();
    notifyListeners();
  }

  /// Queues a scene from a screen (Health screen "Get support"...) and
  /// shows it on the Life tab.
  void openScene(String id) {
    if (life == null) return;
    life!.sceneQueue.add(id);
    _sceneAfterAction();
    _save();
    notifyListeners();
  }

  // ---------------- Rewind (plan CL-021/023) ----------------

  /// Ages you can go back to (start of that year), newest first.
  List<int> get rewindAges => [
    for (final s in _snapshots.reversed) s['age'] as int,
  ];

  /// Null when Rewind is allowed, otherwise why not.
  String? get rewindLock {
    final l = life;
    if (l == null) return 'No life';
    if (l.ironman) return 'Ironman lives cannot rewind';
    if (_snapshots.isEmpty) return 'Nothing to rewind to yet';
    if (!profile.plusTest && l.rewindsUsed >= 1) {
      return 'Your free Rewind for this life is used (Plus: unlimited)';
    }
    return null;
  }

  void rewindTo(int age) {
    if (rewindLock != null) return;
    final i = _snapshots.lastIndexWhere((s) => s['age'] == age);
    if (i < 0) return;
    final used = life!.rewindsUsed + 1;
    life = Life.fromJson(Map<String, dynamic>.from(_snapshots[i]['life']))
      ..rewindsUsed = used;
    life!.feed.add(
      FeedEntry(
        life!.age,
        'You rewound time to age ${life!.age}.',
        kind: 'milestone',
      ),
    );
    _snapshots.removeRange(i, _snapshots.length);
    pendingEvent = null;
    lastOutcome = null;
    _save();
    notifyListeners();
  }

  void _snapshot() {
    final l = life!;
    if (!l.alive) return;
    _snapshots.add({'age': l.age, 'life': jsonDecode(jsonEncode(l.toJson()))});
    if (_snapshots.length > _rewindDepth) _snapshots.removeAt(0);
  }

  // ---------------- Settings ----------------

  void updateProfile(void Function(Profile p) change) {
    change(profile);
    if (life != null) life!.classic = profile.classic;
    _save();
    notifyListeners();
  }

  /// After an activity, a queued scene (interview, trial...) opens at once.
  void _sceneAfterAction() {
    if (pendingEvent == null && life != null && life!.sceneQueue.isNotEmpty) {
      pendingEvent = engine!.nextScene(life!);
    }
  }

  void ageUp() {
    if (life == null || pendingEvent != null) return;
    lastOutcome = null;
    Sound.instance.ageUp();
    _snapshot();
    pendingEvent = engine!.ageUp(life!);
    _save();
    notifyListeners();
  }

  void choose(Choice choice) {
    if (life == null || pendingEvent == null) return;
    lastOutcome = engine!.choose(life!, pendingEvent!, choice);
    Sound.instance.outcome(lastOutcome!.tone);
    pendingEvent = null;
    _save();
    notifyListeners();
  }

  void dismissOutcome() {
    lastOutcome = null;
    notifyListeners();
  }

  /// Runs a Wealth-tab money action (deposit, loan, sell...) and saves.
  T wealth<T>(T Function(Life life) action) {
    final r = action(life!);
    _save();
    notifyListeners();
    return r;
  }

  // Results play their own good/bad sound when the pop-up opens.
  ActionResult applyForJob(Career career) {
    final r = engine!.applyForJob(life!, career);
    _sceneAfterAction();
    _save();
    notifyListeners();
    return r;
  }

  ActionResult runAction(GameAction action, {double? score}) {
    final r = engine!.runAction(life!, action, score: score);
    _sceneAfterAction();
    _save();
    notifyListeners();
    return r;
  }

  /// Runs a person interaction from the People tab or the action search.
  ActionResult interact(Npc npc, Interaction interaction) {
    final r = engine!.interact(life!, npc, interaction);
    _sceneAfterAction();
    _save();
    notifyListeners();
    return r;
  }

  bool get soundOn => Sound.instance.enabled;

  Future<void> setSound(bool on) async {
    Sound.instance.enabled = on;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('relivable.sound', on);
  }
}
