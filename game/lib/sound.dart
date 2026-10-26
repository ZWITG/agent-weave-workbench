import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Short, original sound effects (assets/sounds, generated for Relivable)
/// plus light haptics. Players can turn sound off on the Me tab.
class Sound {
  Sound._();
  static final instance = Sound._();

  bool enabled = true;
  final _players = <String, AudioPlayer>{};

  Future<void> _play(String name, {double volume = 0.8}) async {
    if (!enabled) return;
    try {
      final p = _players.putIfAbsent(
        name,
        () => AudioPlayer()..setReleaseMode(ReleaseMode.stop),
      );
      await p.stop();
      await p.play(AssetSource('sounds/$name.wav'), volume: volume);
    } catch (_) {
      // Sound is a nicety: never let audio errors affect the game.
    }
  }

  void ageUp() {
    HapticFeedback.mediumImpact();
    _play('age_up');
  }

  void tap() {
    HapticFeedback.selectionClick();
    _play('tap', volume: 0.6);
  }

  void outcome(String tone) {
    if (tone == 'bad') HapticFeedback.heavyImpact();
    _play(switch (tone) {
      'good' => 'good',
      'bad' => 'bad',
      _ => 'neutral',
    });
  }
}
