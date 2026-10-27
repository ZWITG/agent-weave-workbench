/// Things that belong to the player rather than to one life: settings,
/// and (Wave F) achievements, collections, Sparks and challenges.
/// Saved separately from the life and the world.
class Profile {
  Profile();

  /// Classic mode: no energy limit on activities (plan CL-006).
  bool classic = false;

  /// Accessibility (plan SOC-SE-003/005).
  bool reduceMotion = false;
  double textScale = 1.0;

  /// Content filters (plan SOC-SE-009): 'crime', 'gambling'.
  final Set<String> hidden = {};

  /// Test switch for Relivable Plus features (unlimited Rewind, 8
  /// generations, Destiny Mode). Real purchases need store accounts, so in
  /// the prototype the owner can switch Plus on to try those features.
  bool plusTest = false;

  /// Default difficulty for new lives.
  String difficulty = 'normal';
  bool ironman = false;

  Map<String, dynamic> toJson() => {
    'classic': classic,
    'reduceMotion': reduceMotion,
    'textScale': textScale,
    'hidden': hidden.toList(),
    'plusTest': plusTest,
    'difficulty': difficulty,
    'ironman': ironman,
  };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile()
    ..classic = j['classic'] ?? false
    ..reduceMotion = j['reduceMotion'] ?? false
    ..textScale = (j['textScale'] as num?)?.toDouble() ?? 1.0
    ..hidden.addAll(List<String>.from(j['hidden'] ?? []))
    ..plusTest = j['plusTest'] ?? false
    ..difficulty = j['difficulty'] ?? 'normal'
    ..ironman = j['ironman'] ?? false;
}

/// Activities hidden by the content filters.
bool filteredOut(Profile p, String category, String actionId) {
  if (p.hidden.contains('crime') && category == 'Crime') return true;
  if (p.hidden.contains('violence') &&
      const {'assault', 'armed_robbery'}.contains(actionId)) {
    return true;
  }
  if (p.hidden.contains('gambling') &&
      const {'casino', 'lottery'}.contains(actionId)) {
    return true;
  }
  return false;
}
