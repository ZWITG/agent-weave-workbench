import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine/migration.dart' as migration;
import 'engine/actions.dart';
import 'engine/careers.dart';
import 'engine/dynasty.dart';
import 'engine/engine.dart';
import 'engine/health.dart' show endThisLifeRules;
import 'engine/meta.dart';
import 'engine/community.dart' show emigrateTo;
import 'engine/currency.dart';
import 'engine/models.dart';
import 'engine/relationships.dart';
import 'engine/storylet.dart';
import 'engine/variants.dart';
import 'engine/profile.dart';
import 'engine/scenes.dart';
import 'engine/world.dart';
import 'sound.dart';

/// Holds the current life, talks to the engine and saves on the device
/// after every change (offline-first; cloud sync comes in Phase 3).
class GameController extends ChangeNotifier {
  /// Money everywhere is shown in the currency of where you live.
  @override
  void notifyListeners() {
    if (life != null) activeCountry = life!.country;
    super.notifyListeners();
  }

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
    final list = <Storylet>[
      for (final file in storyletFiles)
        ...(jsonDecode(
          await rootBundle.loadString('assets/storylets/$file'),
        ) as List).map((e) => Storylet.fromJson(Map<String, dynamic>.from(e))),
    ];
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
      Map<String, dynamic>? j;
      try {
        j = jsonDecode(saved) as Map<String, dynamic>;
        life = Life.fromJson(Map<String, dynamic>.from(j['life']));
      } catch (_) {
        life = null;
      }
      // An unfinished event is rebuilt from its full key; if that fails the
      // life carries on without it rather than being lost.
      final pid = j?['pending'] as String?;
      if (life != null && pid != null) {
        try {
          pendingEvent = pid.startsWith('scene:')
              ? buildScene(life!.currentScene ?? pid.substring(6), life!)
              : engine!.storylets.where((s) => s.id == pid).firstOrNull;
        } catch (_) {
          pendingEvent = null;
        }
        if (pendingEvent == null) {
          life!.currentScene = null;
          life!.feed.add(
            FeedEntry(
              life!.age,
              'An unfinished moment from last time could not be picked up again.',
              kind: 'nudge',
            ),
          );
        }
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
    String? family,
    String? identity,
    String? pronouns,
    String? interest,
  }) {
    life =
        engine!.newLife(
            seed: seed,
            firstName: firstName,
            gender: gender,
            countryName: country,
            family: family,
          )
          ..genderIdentity = identity ?? ''
          ..pronouns = pronouns ?? ''
          ..attractedTo = interest ?? ''
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
    recordLifeEnd(old, profile);
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
    recordLifeEnd(life!, profile);
    pendingEvent = null;
    lastOutcome = null;
    _save();
    notifyListeners();
  }

  /// Why nothing else can start right now, or null. An event on screen, or
  /// the next step of one, has to be finished first.
  String? get busyReason {
    final l = life;
    if (l == null) return null;
    if (!l.alive) return 'This life is over.';
    if (pendingEvent != null) return 'Finish the event on the Life tab first.';
    if (l.sceneQueue.isNotEmpty) {
      return lastOutcome != null
          ? 'Tap Continue on the Life tab to finish what you started.'
          : 'Something is waiting for you on the Life tab.';
    }
    return null;
  }

  /// Set when the Life tab should come to the front (an event opened from
  /// another tab or screen). The hub reads and clears it.
  bool wantLifeTab = false;

  void goToEvent() {
    wantLifeTab = true;
    notifyListeners();
  }

  /// Shows any scene queued from a screen (identity changes...).
  void showQueued() {
    _sceneAfterAction();
    _save();
    notifyListeners();
  }

  /// Queues a scene from a screen (Health screen "Get support"...) and
  /// shows it on the Life tab.
  void openScene(String id) {
    if (life == null || busyReason != null) return;
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

  /// The big things from the last birthday (deaths, arrests, diagnoses,
  /// births...), shown in a pop-up so they are not lost in the feed.
  List<String> yearHighlights = const [];

  void ageUp() {
    if (life == null || pendingEvent != null) return;
    lastOutcome = null;
    if (life!.sceneQueue.isNotEmpty) {
      _sceneAfterAction();
      _save();
      notifyListeners();
      return;
    }
    Sound.instance.ageUp();
    _snapshot();
    final seen = life!.feed.length;
    pendingEvent = engine!.ageUp(life!);
    yearHighlights = bigNews(life!.feed.skip(seen));
    final freeze = recordPlayDay(profile, DateTime.now());
    if (freeze != null) toasts.add(freeze);
    _meta(['age']);
    _save();
    notifyListeners();
  }

  // ---------------- Meta (achievements, goals, challenges) ----------------

  /// Short notices shown at the top of the screen, oldest first.
  final List<String> toasts = [];

  late final Set<String> _storyIds = {for (final s in engine!.storylets) s.id};

  void _meta(List<String> events) {
    final l = life;
    if (l == null) return;
    final now = DateTime.now();
    for (final e in events) {
      toasts.addAll(trackGoal(profile, e, now));
    }
    toasts.addAll(checkMeta(l, profile, storyIds: _storyIds));
    toasts.addAll(trackChallenge(profile, l, now));
    if (!l.alive) recordLifeEnd(l, profile);
  }

  /// Counts an event that happens outside actions (a social post...).
  void trackEvent(String event) {
    _meta([event]);
    _save();
    notifyListeners();
  }

  /// Plays an archived weekly challenge (null = this week).
  void playChallenge(String? week) {
    profile.activeWeek = week;
    _save();
    notifyListeners();
  }

  void choose(Choice choice) {
    // A second tap on a card that is already fading away does nothing.
    if (life == null ||
        pendingEvent == null ||
        !pendingEvent!.choices.contains(choice)) {
      return;
    }
    lastOutcome = engine!.choose(life!, pendingEvent!, choice);
    Sound.instance.outcome(
      lastOutcome!.tone,
      text: lastOutcome!.text,
      money: lastOutcome!.moneyDelta,
    );
    pendingEvent = null;
    _meta(['choice']);
    _save();
    notifyListeners();
  }

  /// "Continue" on an outcome: the next step of the same story follows
  /// straight away.
  void dismissOutcome() {
    lastOutcome = null;
    _sceneAfterAction();
    _save();
    notifyListeners();
  }

  /// Runs a Wealth-tab money action (deposit, loan, sell...) and saves.
  T wealth<T>(T Function(Life life) action) {
    final r = action(life!);
    _sceneAfterAction();
    _meta(const []);
    _save();
    notifyListeners();
    return r;
  }

  // Results play their own good/bad sound when the pop-up opens.
  ActionResult applyForJob(Career career) {
    final busy = busyReason;
    if (busy != null) return ActionResult(busy);
    final r = engine!.applyForJob(life!, career);
    _sceneAfterAction();
    _save();
    notifyListeners();
    return r;
  }

  ActionResult runAction(
    GameAction action, {
    double? score,
    ActionVariant? variant,
    Npc? who,
  }) {
    final busy = busyReason;
    if (busy != null) return ActionResult(busy);
    final r = engine!.runAction(
      life!,
      action,
      score: score,
      variant: variant,
      who: who,
    );
    _sceneAfterAction();
    _meta([
      'action:${action.id}',
      'category:${action.category}',
      if (action.category == 'Crime') 'crime',
    ]);
    _save();
    notifyListeners();
    return r;
  }

  /// Moving abroad to [country], chosen on the Move abroad screen: the
  /// same activity (energy, once a year, the feed) with the country set.
  ActionResult emigrate(String country) {
    final a = engine!.actions.firstWhere((x) => x.id == 'emigrate');
    return runAction(
      GameAction(
        id: a.id,
        label: a.label,
        category: a.category,
        keywords: a.keywords,
        minAge: a.minAge,
        extraCheck: a.extraCheck,
        run: (l, rng) => ActionResult(emigrateTo(l, country, rng)),
      ),
    );
  }

  /// Crossing to [country] without a visa by [route] (migration.dart),
  /// from the Move abroad screen: counts as this year's move.
  ActionResult migrateIllegally(String country, String route) {
    final a = engine!.actions.firstWhere((x) => x.id == 'emigrate');
    return runAction(
      GameAction(
        id: a.id,
        label: 'Cross without a visa',
        category: a.category,
        keywords: a.keywords,
        minAge: 16,
        extraCheck: (l) => migration.migrateLock(l, route),
        run: (l, rng) =>
            ActionResult(migration.migrateIllegally(l, country, route, rng)),
      ),
    );
  }

  /// Runs a person interaction from the People tab or the action search.
  ActionResult interact(
    Npc npc,
    Interaction interaction, {
    InteractionVariant? variant,
  }) {
    final busy = busyReason;
    if (busy != null) return ActionResult(busy);
    final r = engine!.interact(life!, npc, interaction, variant: variant);
    _sceneAfterAction();
    _meta(['interaction:${npc.circle}']);
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

const _bigKinds = {
  'news',
  'milestone',
  'serious',
  'chronic',
  'mind',
  'title',
  'career',
  'risk',
  'house',
  'grudge',
};

final _bigWords = RegExp(
  r'\b(died|dies|death|passed away|funeral|arrest|prison|released|parole|'
  r'fired|laid off|diagnos|divorc|born|pregnan|inherit|evict|bankrupt|'
  r'warrant|recaptur|solitary|burgl|stolen|flood|fire|crash|accident|'
  r'cancer|heart attack|engaged|married|broke up|left you|it is over|'
  r'promot|lottery|lawsuit|sued|deport|amnesty|asylum|legal status|'
  r'billionaire|richest|rich list|Lieutenant|Underboss|Boss of|informant|'
  r'grandchild|grandparent|will is read|estate)',
  caseSensitive: false,
);

/// The feed lines worth stopping the player for, at most five.
List<String> bigNews(Iterable<FeedEntry> entries) => [
  for (final e in entries)
    if (e.kind != 'summary' &&
        e.kind != 'action' &&
        e.kind != 'world' &&
        (_bigKinds.contains(e.kind) || _bigWords.hasMatch(e.text)))
      e.text,
].take(5).toList();
