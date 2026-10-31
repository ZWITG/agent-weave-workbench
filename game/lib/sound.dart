import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Short, original sound effects (assets/sounds, generated for Relivable by
/// tool/make_sounds.py) plus light haptics. Players can turn sound off on
/// the Me tab.
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
    _play('tap', volume: 0.5);
  }

  /// Panels and sheets sliding open.
  void whoosh() => _play('whoosh', volume: 0.4);

  /// Plays one named sound (news, purchase, keys...).
  void cue(String name) => _play(name, volume: 0.7);

  // ---- Mini-games ----
  void hit() {
    HapticFeedback.lightImpact();
    _play('hit', volume: 0.6);
  }

  void miss() => _play('miss', volume: 0.6);
  void tick() => _play('tick', volume: 0.5);
  void gameOver(double score) => _play(score >= 0.5 ? 'win' : 'lose');

  /// A sound for what actually happened, from the result's words, or null
  /// to fall back on the good / bad / neutral sound.
  static String? cueFor(String text, {int money = 0}) {
    final t = text.toLowerCase();
    bool has(List<String> words) => words.any(t.contains);
    if (has(['under arrest', 'handcuff', 'arrested', 'blue lights'])) {
      return 'siren';
    }
    if (has(['died', 'passed away', 'funeral', 'your story ended'])) {
      return 'sad';
    }
    if (has([
      'was born',
      'baby girl',
      'baby boy',
      'you got married',
      'wedding',
      'said yes',
    ])) {
      return 'celebrate';
    }
    if (has(['promoted', 'promotion', 'read your name', 'award', 'you won'])) {
      return 'promote';
    }
    if (has(['got the keys', 'moved into', 'signed the lease'])) return 'keys';
    if (has(['went viral', 'red carpet', 'talk show', 'fans'])) return 'cheer';
    if (has(['diagnos', 'hospital', 'ambulance'])) return 'heartbeat';
    if (money >= 1000) return 'coin';
    if (money <= -1000) return 'spend';
    return null;
  }

  /// The sound for a result: what happened if it has its own cue,
  /// otherwise how it went.
  void outcome(String tone, {String text = '', int money = 0}) {
    if (tone == 'bad') HapticFeedback.heavyImpact();
    _play(
      cueFor(text, money: money) ??
          switch (tone) {
            'good' => 'good',
            'bad' => 'bad',
            _ => 'neutral',
          },
    );
  }
}
