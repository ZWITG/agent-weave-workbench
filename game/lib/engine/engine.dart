import 'dart:math';

import 'actions.dart';
import 'careers.dart';
import 'economy.dart';
import 'lifespan.dart';
import 'npc_life.dart';
import 'models.dart';
import 'relationships.dart';
import 'scenes.dart';
import 'school.dart';
import 'storylet.dart';
import 'world.dart';
import 'world_data.dart';

/// The prototype slice runs from birth to this age (Phase 2 scope).
/// Lives run from birth to death; this is only the hard upper bound.
const sliceEndAge = 120;

/// The result of choosing an option on an event card.
class Outcome {
  Outcome(
    this.text,
    this.notes, {
    this.headline = '',
    this.tone = 'neutral',
    this.category = 'life',
    this.statDeltas = const {},
    this.bondDeltas = const {},
    this.moneyDelta = 0,
    this.echoes = const [],
  });

  final String text;
  final List<String> notes;

  /// Short reaction ("That went well.", "Ouch.").
  final String headline;

  /// good, bad, mixed or neutral: drives colour and sound.
  final String tone;
  final String category;

  /// Visible stat -> change.
  final Map<String, int> statDeltas;

  /// Person name -> Bond % change.
  final Map<String, int> bondDeltas;
  final int moneyDelta;

  /// Lines about consequences ("Leo will remember this").
  final List<String> echoes;
}

/// Pure-Dart game rules: no Flutter imports, so the simulator bot and unit
/// tests can run lives headlessly.
class GameEngine {
  GameEngine(this.storylets, {World? world}) : world = world ?? World(seed: 1);

  final List<Storylet> storylets;

  /// The player's one persistent world (world.dart). The controller swaps
  /// in the saved world; tests use a fresh one.
  World world;

  // ---------- New life ----------

  Life newLife({
    int? seed,
    String? firstName,
    String? gender,
    String? countryName,
    int? startYear,
  }) {
    final start = startYear ?? world.year;
    final s = seed ?? DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
    final rng = Random(s);
    final country = countryName != null
        ? countryNamed(countryName)
        : countries[rng.nextInt(countries.length)];
    final g = gender ?? (rng.nextBool() ? 'female' : 'male');
    final pool = g == 'female' ? country.female : country.male;
    final surname = country.surnames[rng.nextInt(country.surnames.length)];
    String pick(List<String> l) => l[rng.nextInt(l.length)];

    final npcs = <Npc>[
      Npc(
        id: 'mother',
        role: 'Mother',
        name: pick(country.female),
        birthYear: start - 24 - rng.nextInt(14),
        bond: 70 + rng.nextInt(25),
      ),
      Npc(
        id: 'father',
        role: 'Father',
        name: pick(country.male),
        birthYear: start - 25 - rng.nextInt(16),
        bond: 60 + rng.nextInt(30),
      ),
      if (rng.nextDouble() < 0.75)
        Npc(
          id: 'sibling',
          role: 'Brother',
          name: pick(country.male),
          birthYear: start - 1 - rng.nextInt(4),
          bond: 55 + rng.nextInt(30),
        ),
    ];

    final life = Life(
      seed: s,
      firstName: firstName?.trim().isNotEmpty == true
          ? firstName!.trim()
          : pick(pool),
      surname: surname,
      gender: g,
      country: country.name,
      city: pick(country.cities),
      birthYear: start,
      stats: Stats.random(rng),
      npcs: npcs,
    );
    life.feed.add(
      FeedEntry(
        0,
        'You were born in ${life.city}, ${life.country}, to ${npcs[0].name} and ${npcs[1].name}.',
        kind: 'milestone',
      ),
    );
    if (life.npc('sibling') != null) {
      life.feed.add(
        FeedEntry(
          0,
          'Your big brother ${life.npc('sibling')!.name} is not impressed.',
        ),
      );
    }
    final echo = world.echoFor(life);
    if (echo != null) {
      life.echo.addAll(echo);
      life.flags['echo_${echo['relation']}'] = Memory(
        0,
        'hearing about ${echo['person']}',
      );
    }
    world.ensureYear(life.year, life.country, life.city);
    life.economy = world.economyFor(life.year);
    return life;
  }

  // ---------- Yearly loop ----------

  Random _rngFor(Life life, [int salt = 0]) =>
      Random(life.seed * 31 + life.age * 7919 + salt);

  /// Ages the character one year and returns the event to show, if any.
  Storylet? ageUp(Life life) {
    if (!life.alive || life.age >= sliceEndAge) return null;
    life.lastYearStats = Map.of(life.stats.values);
    life.age += 1;
    life.usedActions.clear();
    life.interactionCounts.clear();
    life.energy = 10;
    if (life.job != null) life.yearsWorked++;
    for (final line in yearlyRelationships(life, _rngFor(life, 17))) {
      life.feed.add(FeedEntry(life.age, line, kind: 'nudge'));
    }
    final rng = _rngFor(life);

    _schoolMilestones(life);
    schoolStage(life, rng);
    final card = reportCard(life, _rngFor(life, 31));
    if (card != null) life.feed.add(FeedEntry(life.age, card, kind: 'report'));
    for (final line in schoolYear(life, _rngFor(life, 37))) {
      life.feed.add(FeedEntry(life.age, line));
    }
    _worldYear(life);
    for (final line in yearlyMoney(life, rng)) {
      life.feed.add(FeedEntry(life.age, line, kind: 'nudge'));
    }
    life.feed.addAll(npcUpdates(life, _rngFor(life, 23)));
    checkDeeds(life);
    // Gentle drift so idle years still matter.
    life.reason = 'Ups and downs';
    life.stats.add('happiness', rng.nextInt(5) - 2);
    if (life.difficulty == 'hard') life.stats.add('happiness', -1);
    final body = ageBody(life, rng);
    if (body != null) {
      life.feed.add(FeedEntry(life.age, body, kind: 'milestone'));
    }

    if (life.stats['health'] <= 0 || rng.nextDouble() < deathChance(life)) {
      life.alive = false;
      life.causeOfDeath = life.stats['health'] <= 0
          ? 'Illness'
          : causeOfDeath(life, rng);
      life.feed.add(
        FeedEntry(
          life.age,
          'Your story ended at ${life.age}. Cause: ${life.causeOfDeath}.',
          kind: 'milestone',
        ),
      );
      return null;
    }

    final chapter = chapterFor(life);
    if (chapter != life.chapter) {
      if (life.chapter.isNotEmpty) {
        life.feed.add(
          FeedEntry(
            life.age,
            'A new chapter begins: $chapter',
            kind: 'milestone',
          ),
        );
      }
      life.chapter = chapter;
    }
    _birthdaySummary(life);

    // Scenes (scenes.dart) come before ordinary events.
    if (life.job != null &&
        !life.retired &&
        life.age >= 65 &&
        !life.lastSeen.containsKey('scene:retire_offer')) {
      life.sceneQueue.add('retire_offer');
    }
    final sick = life.age < 10 ? 0.16 : (life.age > 60 ? 0.2 : 0.09);
    if (rng.nextDouble() < sick) {
      final ill = pickIllness(life, rng);
      if (ill != null) life.sceneQueue.add('illness:$ill');
    }
    if (inSchool(life) && (life.age == 16 || life.age == 17)) {
      life.sceneQueue.add('exams');
    }
    if (life.education == 'university' && life.school.major == null) {
      life.sceneQueue.add('choose_major');
    }
    final scene = nextScene(life);
    if (scene != null) return scene;

    final event = pickStorylet(life, rng);
    if (event == null) {
      life.feed.add(FeedEntry(life.age, _quietYear(life, rng)));
    }
    return event;
  }

  /// The next queued scene that still makes sense, if any.
  Storylet? nextScene(Life life) {
    while (life.sceneQueue.isNotEmpty) {
      final s = buildScene(life.sceneQueue.removeAt(0), life);
      if (s != null) return s;
    }
    return null;
  }

  /// One feed line with what changed over the birthday itself.
  void _birthdaySummary(Life life) {
    final parts = <String>[
      for (final k in Stats.visible)
        if ((life.stats[k] - (life.lastYearStats[k] ?? life.stats[k])) != 0)
          '${k[0].toUpperCase()}${k.substring(1)} ${_signed(life.stats[k] - life.lastYearStats[k]!)}',
    ];
    final cash = life.lastYear.fold(0, (a, l) => a + l.$2);
    if (cash != 0) {
      final digits = cash.abs().toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => ',',
      );
      parts.add('Cash ${cash > 0 ? '+' : '−'}\$$digits');
    }
    if (parts.isNotEmpty) {
      life.feed.add(FeedEntry(life.age, parts.join(' · '), kind: 'summary'));
    }
  }

  Storylet? pickStorylet(Life life, Random rng) {
    final eligible = storylets.where((s) => s.isEligible(life)).toList();
    if (eligible.isEmpty) return null;
    final total = eligible.fold<int>(0, (a, s) => a + s.weight);
    var roll = rng.nextInt(total);
    for (final s in eligible) {
      roll -= s.weight;
      if (roll < 0) return s;
    }
    return eligible.last;
  }

  Outcome choose(Life life, Storylet event, Choice choice) {
    life.lastSeen[event.id] = life.age;
    final statsBefore = {for (final k in Stats.visible) k: life.stats[k]};
    final bondsBefore = {for (final n in life.npcs) n.id: n.bond};
    final npcsBefore = life.npcs.map((n) => n.id).toSet();
    final moneyBefore = life.money;
    life.reason = event.scene ? choice.label : 'Choice: ${choice.label}';
    final notes = choice.effects.apply(life);
    final custom = choice.run?.call(life, _rngFor(life, event.id.hashCode));
    checkDeeds(life);
    final statDeltas = <String, int>{
      for (final k in Stats.visible)
        if (life.stats[k] != statsBefore[k]) k: life.stats[k] - statsBefore[k]!,
    };
    final bondDeltas = <String, int>{
      for (final n in life.npcs)
        if (bondsBefore.containsKey(n.id) && n.bond != bondsBefore[n.id])
          n.name: n.bond - bondsBefore[n.id]!,
    };
    final moneyDelta = life.money - moneyBefore;
    final score =
        statDeltas.values.fold<int>(0, (a, b) => a + b) +
        bondDeltas.values.fold<int>(0, (a, b) => a + b) ~/ 3 +
        (moneyDelta > 0 ? 3 : (moneyDelta < 0 ? -2 : 0));
    final hasGood =
        statDeltas.values.any((v) => v > 0) ||
        bondDeltas.values.any((v) => v > 0) ||
        moneyDelta > 0;
    final hasBad =
        statDeltas.values.any((v) => v < 0) ||
        bondDeltas.values.any((v) => v < 0) ||
        moneyDelta < 0;
    final tone = hasGood && hasBad && score.abs() < 4
        ? 'mixed'
        : score > 0
        ? 'good'
        : score < 0
        ? 'bad'
        : 'neutral';
    const headlines = {
      'good': [
        'That went well.',
        'Good call.',
        'Nicely done.',
        'A moment to remember.',
      ],
      'bad': [
        'Ouch.',
        'That stung.',
        'Not your finest hour.',
        'Well, that happened.',
      ],
      'mixed': ['Win some, lose some.', 'A bit of both.', 'It\'s complicated.'],
      'neutral': ['Life goes on.', 'So it goes.', 'Noted.'],
    };
    final hl = headlines[tone]!;
    final echoes = <String>[
      for (final n in life.npcs)
        if (!npcsBefore.contains(n.id)) '${n.name} is now part of your life',
      for (final id in choice.effects.npcMemory.keys)
        if (life.npc(id) != null) '${life.npc(id)!.name} will remember this',
      if (choice.effects.setFlags.isNotEmpty)
        'This moment may come back years from now',
    ];
    final text = fill(
      custom ?? (choice.outcome.isEmpty ? choice.label : choice.outcome),
      life,
    );
    life.feed.add(FeedEntry(life.age, text));
    if (life.stats['health'] <= 0) {
      life.alive = false;
      life.causeOfDeath = 'Injuries';
    }
    return Outcome(
      text,
      notes,
      headline: hl[(life.seed + life.age) % hl.length],
      tone: tone,
      category: event.category,
      statDeltas: statDeltas,
      bondDeltas: bondDeltas,
      moneyDelta: moneyDelta,
      echoes: echoes,
    );
  }

  /// Fills {mother}, {father}, {sibling}, {name}, {city}, {surname}.
  String fill(String text, Life life) => text
      .replaceAll('{name}', life.firstName)
      .replaceAll('{surname}', life.surname)
      .replaceAll('{city}', life.city)
      .replaceAll('{country}', life.country)
      .replaceAll('{mother}', life.npc('mother')?.name ?? 'your mother')
      .replaceAll('{father}', life.npc('father')?.name ?? 'your father')
      .replaceAll('{sibling}', life.npc('sibling')?.name ?? 'your cousin')
      .replaceAll('{echo_person}', life.echo['person'] ?? 'someone')
      .replaceAll('{echo_deed}', life.echo['deed'] ?? 'something')
      .replaceAll('{echo_year}', life.echo['year'] ?? 'years ago');

  void _schoolMilestones(Life life) {
    void milestone(String text) =>
        life.feed.add(FeedEntry(life.age, text, kind: 'milestone'));
    switch (life.age) {
      case 5:
        life.education = 'primary';
        milestone('You started primary school.');
      case 12:
        life.education = 'secondary';
        milestone('You started secondary school.');
      case 18:
        if (life.education == 'secondary') {
          life.education = 'high school graduate';
          milestone('You finished secondary school.');
        }
    }
    final done = graduateIfDone(life);
    if (done != null) milestone(done);
  }

  String _quietYear(Life life, Random rng) {
    const lines = [
      'A quiet year. Nothing much happened.',
      'The year went by in a blur.',
      'You spent the year finding your feet.',
      'An ordinary year, and that was fine.',
    ];
    return lines[rng.nextInt(lines.length)];
  }

  // ---------- Actions (the action search) ----------

  List<GameAction> get actions => allActions;

  /// Runs an activity. [score] (0..1) comes from its mini-game, if played.
  ActionResult runAction(Life life, GameAction action, {double? score}) {
    final rng = _rngFor(life, action.id.hashCode);
    final again = life.usedActions.contains(action.id);
    life.reason = action.label;
    if (!life.classic && !action.repeatable) {
      life.energy = max(0, life.energy - 1);
    }
    life.usedActions.add(action.id);
    final result = score != null && action.scored != null
        ? action.scored!(life, rng, score.clamp(0, 1))
        : action.run(life, rng);
    final text = fill(result.text, life);
    if (!(action.repeatable && again)) {
      life.feed.add(FeedEntry(life.age, text, kind: 'action'));
    }
    checkDeeds(life);
    return ActionResult(text, result.notes);
  }

  /// Applies for a job on the Path tab's job board.
  ActionResult applyForJob(Life life, Career career) {
    final rng = _rngFor(life, 'apply:${career.id}'.hashCode);
    final r = applyForCareer(life, career, rng);
    checkDeeds(life);
    final text = fill(r.text, life);
    life.feed.add(FeedEntry(life.age, text, kind: 'action'));
    return ActionResult(text, r.notes);
  }

  // ---------- The world ----------

  /// The world's side of a birthday: this year's news (made once, shared by
  /// every life), the world economy, and effects that reach the player.
  void _worldYear(Life life) {
    final year = life.year;
    world.ensureYear(year, life.country, life.city);
    world.year = max(world.year, year);
    life.economy = world.economyFor(year);
    life.worldMods = world.modsFor(year, life.country, life.city, life.surname);
    life.reason = 'In the news';
    life.stats.add('health', life.worldMods['health'] ?? 0);
    life.stats.add('happiness', life.worldMods['happiness'] ?? 0);
    final news = world.headlineFor(year, life.country, life.city);
    if (news != null) {
      life.feed.add(FeedEntry(life.age, news.headline, kind: 'world'));
    }
  }

  /// Notable things this life did join the world's history (and the papers).
  void checkDeeds(Life life) {
    final who = '${life.firstName} ${life.surname}';
    final city = life.city;
    void deed(
      String key,
      String headline,
      String body, {
      Map<String, int> axes = const {},
      bool national = false,
      String category = 'local',
    }) => world.recordDeed(
      life,
      key,
      headline: headline,
      body: body,
      axes: axes,
      national: national,
      category: category,
    );

    if (life.flags.containsKey('sued_sibling')) {
      deed(
        'feud',
        'Family feud over a $city flat ends in court',
        '$who has won sole ownership of a family flat after taking a brother '
            'to court. Neighbours say the two no longer speak.',
        axes: {'infamy': 5},
      );
    }
    if (life.job == 'Restaurant owner') {
      deed(
        'restaurant',
        'New restaurant opens in $city',
        'Local cook $who has opened a restaurant of their own. Early reviews '
            'praise the food and the warm welcome.',
        axes: {'fame': 6},
      );
    }
    if (life.lastSeen.containsKey('startup_result')) {
      deed(
        'startup',
        'Supermarket giant buys the app LeftOver',
        'The leftover-sharing app has been bought outright. Early backers, '
            'including $who of $city, are celebrating a surprise payday.',
        axes: {'wealth': 8},
        national: true,
        category: 'economy',
      );
    }
    if (life.flags.containsKey('jackpot')) {
      deed(
        'jackpot',
        '$who wins the lottery jackpot',
        'The \$250,000 winner from $city said they would "probably still go '
            'to work on Monday".',
        axes: {'fame': 8, 'wealth': 10},
        national: true,
      );
    }
    if (life.flags.containsKey('arrested')) {
      deed(
        'arrest',
        'Pickpocket caught on a $city tram',
        life.age >= 18
            ? '$who, ${life.age}, was arrested after a passenger felt a hand '
                  'in her bag. Police say patrols will continue.'
            : 'A local teenager was arrested after a passenger felt a hand in '
                  'her bag. Police say patrols will continue.',
        axes: {'infamy': 8},
        category: 'crime',
      );
    }
    if (life.netWorth >= 1000000) {
      deed(
        'millionaire',
        '$city\'s newest millionaire is just ${life.age}',
        '$who has built a fortune of over \$1 million. Asked for advice, '
            'they said: "Spend less than you earn. Also, luck."',
        axes: {'wealth': 20, 'fame': 5},
        national: true,
      );
    }
    if (life.careerRank >= 3 && life.job != null) {
      deed(
        'top_${life.careerId}',
        '$who named ${life.job}',
        'After years working their way up, $who has reached the top of their '
            'field in $city.',
        axes: {'power': 8, 'fame': 4},
      );
    }
    if (life.lastSeen.containsKey('sibling_generous_thanks')) {
      deed(
        'bakery',
        'Bakery names its best loaf after a generous sibling',
        'A small $city bakery\'s bestselling sourdough is named after $who, '
            'who gave the shop\'s owner the building it stands in.',
        axes: {'philanthropy': 6},
      );
    }
  }

  // ---------- Person interactions (People tab, action search) ----------

  ActionResult interact(Life life, Npc npc, Interaction i) {
    final rng = _rngFor(life, i.key(npc).hashCode);
    life.reason = '${i.label} · ${npc.name}';
    final r = runInteraction(life, npc, i, rng);
    final text = fill(r.text, life);
    life.feed.add(FeedEntry(life.age, text, kind: 'action'));
    return ActionResult(text, r.notes);
  }
}

String _signed(int v) => v > 0 ? '+$v' : '−${v.abs()}';
