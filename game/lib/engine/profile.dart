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

  /// More accessibility (plan UX §8): colour-vision mode (default, protan,
  /// deutan, tritan, mono), left-hand layout, confirm big decisions and
  /// always auto-resolve mini-games.
  String colourMode = 'default';
  bool leftHanded = false;
  bool confirmBig = true;
  bool autoMiniGames = false;

  // ---- Meta (meta.dart): kept across every life ----
  /// Achievement id -> date earned.
  final Map<String, String> achievements = {};
  final Map<String, List<String>> collections = {};

  /// Sparks: the only soft currency, earn-only, never sold.
  int sparks = 0;
  int streak = 0;
  int bestStreak = 0;
  String? lastPlayDay;
  String? freezeWeek;
  final Map<String, dynamic> daily = {};
  int dailyBonusDays = 0;

  /// Week (Monday date) -> finished task ids; finished weeks; the week
  /// being played (null = this week).
  final Map<String, List<String>> weeklyDone = {};
  final List<String> challengesDone = [];
  String? activeWeek;

  /// Chaos Index of every finished life, for "more chaotic than X%".
  final List<int> chaosHistory = [];

  Map<String, dynamic> toJson() => {
    'classic': classic,
    'reduceMotion': reduceMotion,
    'textScale': textScale,
    'hidden': hidden.toList(),
    'plusTest': plusTest,
    'difficulty': difficulty,
    'ironman': ironman,
    'colourMode': colourMode,
    'leftHanded': leftHanded,
    'confirmBig': confirmBig,
    'autoMiniGames': autoMiniGames,
    'achievements': achievements,
    'collections': collections,
    'sparks': sparks,
    'streak': streak,
    'bestStreak': bestStreak,
    'lastPlayDay': lastPlayDay,
    'freezeWeek': freezeWeek,
    'daily': daily,
    'dailyBonusDays': dailyBonusDays,
    'weeklyDone': weeklyDone,
    'challengesDone': challengesDone,
    'activeWeek': activeWeek,
    'chaosHistory': chaosHistory,
  };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile()
    ..classic = j['classic'] ?? false
    ..reduceMotion = j['reduceMotion'] ?? false
    ..textScale = (j['textScale'] as num?)?.toDouble() ?? 1.0
    ..hidden.addAll(List<String>.from(j['hidden'] ?? []))
    ..plusTest = j['plusTest'] ?? false
    ..difficulty = j['difficulty'] ?? 'normal'
    ..ironman = j['ironman'] ?? false
    ..colourMode = j['colourMode'] ?? 'default'
    ..leftHanded = j['leftHanded'] ?? false
    ..confirmBig = j['confirmBig'] ?? true
    ..autoMiniGames = j['autoMiniGames'] ?? false
    ..achievements.addAll(Map<String, String>.from(j['achievements'] ?? {}))
    ..collections.addAll({
      for (final e in Map<String, dynamic>.from(j['collections'] ?? {}).entries)
        e.key: List<String>.from(e.value),
    })
    ..sparks = j['sparks'] ?? 0
    ..streak = j['streak'] ?? 0
    ..bestStreak = j['bestStreak'] ?? 0
    ..lastPlayDay = j['lastPlayDay']
    ..freezeWeek = j['freezeWeek']
    ..daily.addAll(Map<String, dynamic>.from(j['daily'] ?? {}))
    ..dailyBonusDays = j['dailyBonusDays'] ?? 0
    ..weeklyDone.addAll({
      for (final e in Map<String, dynamic>.from(j['weeklyDone'] ?? {}).entries)
        e.key: List<String>.from(e.value),
    })
    ..challengesDone.addAll(List<String>.from(j['challengesDone'] ?? []))
    ..activeWeek = j['activeWeek']
    ..chaosHistory.addAll(List<int>.from(j['chaosHistory'] ?? []));
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
