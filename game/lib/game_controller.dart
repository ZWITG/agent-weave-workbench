import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine/actions.dart';
import 'engine/engine.dart';
import 'engine/models.dart';
import 'engine/relationships.dart';
import 'engine/storylet.dart';

/// Holds the current life, talks to the engine and saves on the device
/// after every change (offline-first; cloud sync comes in Phase 3).
class GameController extends ChangeNotifier {
  static const _saveKey = 'relivable.life.v1';

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
    final saved = prefs.getString(_saveKey);
    if (saved != null) {
      try {
        final j = jsonDecode(saved) as Map<String, dynamic>;
        life = Life.fromJson(Map<String, dynamic>.from(j['life']));
        final pid = j['pending'] as String?;
        if (pid != null) {
          pendingEvent = engine!.storylets
              .where((s) => s.id == pid)
              .firstOrNull;
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
    if (life == null) {
      await prefs.remove(_saveKey);
      return;
    }
    await prefs.setString(
      _saveKey,
      jsonEncode({'life': life!.toJson(), 'pending': pendingEvent?.id}),
    );
  }

  void startLife({String? firstName, String? gender, String? country}) {
    life = engine!.newLife(
      firstName: firstName,
      gender: gender,
      countryName: country,
    );
    pendingEvent = null;
    lastOutcome = null;
    _save();
    notifyListeners();
  }

  void endLife() {
    life = null;
    pendingEvent = null;
    lastOutcome = null;
    _save();
    notifyListeners();
  }

  bool get sliceFinished =>
      life != null &&
      (!life!.alive ||
          (life!.age >= sliceEndAge &&
              pendingEvent == null &&
              lastOutcome == null));

  void ageUp() {
    if (life == null || pendingEvent != null) return;
    lastOutcome = null;
    pendingEvent = engine!.ageUp(life!);
    _save();
    notifyListeners();
  }

  void choose(Choice choice) {
    if (life == null || pendingEvent == null) return;
    lastOutcome = engine!.choose(life!, pendingEvent!, choice);
    pendingEvent = null;
    _save();
    notifyListeners();
  }

  void dismissOutcome() {
    lastOutcome = null;
    notifyListeners();
  }

  ActionResult runAction(GameAction action) {
    final r = engine!.runAction(life!, action);
    _save();
    notifyListeners();
    return r;
  }

  /// Runs a person interaction from the People tab or the action search.
  ActionResult interact(Npc npc, Interaction interaction) {
    final r = engine!.interact(life!, npc, interaction);
    _save();
    notifyListeners();
    return r;
  }
}
