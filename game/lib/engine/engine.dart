import 'dart:math';

import 'actions.dart';
import 'models.dart';
import 'relationships.dart';
import 'storylet.dart';
import 'world_data.dart';

/// The prototype slice runs from birth to this age (Phase 2 scope).
const sliceEndAge = 30;

/// The result of choosing an option on an event card.
class Outcome {
  Outcome(this.text, this.notes);
  final String text;
  final List<String> notes;
}

/// Pure-Dart game rules: no Flutter imports, so the simulator bot and unit
/// tests can run lives headlessly.
class GameEngine {
  GameEngine(this.storylets);

  final List<Storylet> storylets;

  // ---------- New life ----------

  Life newLife({
    int? seed,
    String? firstName,
    String? gender,
    String? countryName,
    int startYear = 2026,
  }) {
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
        birthYear: startYear - 24 - rng.nextInt(14),
        bond: 70 + rng.nextInt(25),
      ),
      Npc(
        id: 'father',
        role: 'Father',
        name: pick(country.male),
        birthYear: startYear - 25 - rng.nextInt(16),
        bond: 60 + rng.nextInt(30),
      ),
      if (rng.nextDouble() < 0.75)
        Npc(
          id: 'sibling',
          role: 'Brother',
          name: pick(country.male),
          birthYear: startYear - 1 - rng.nextInt(4),
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
      birthYear: startYear,
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
    return life;
  }

  // ---------- Yearly loop ----------

  Random _rngFor(Life life, [int salt = 0]) =>
      Random(life.seed * 31 + life.age * 7919 + salt);

  /// Ages the character one year and returns the event to show, if any.
  Storylet? ageUp(Life life) {
    if (!life.alive || life.age >= sliceEndAge) return null;
    life.age += 1;
    life.usedActions.clear();
    life.interactionCounts.clear();
    for (final line in yearlyRelationships(life, _rngFor(life, 17))) {
      life.feed.add(FeedEntry(life.age, line, kind: 'nudge'));
    }
    final rng = _rngFor(life);

    _schoolMilestones(life);
    if (life.job != null && life.salary > 0) {
      life.money += life.salary;
    }
    // Gentle drift so idle years still matter.
    life.stats.add('happiness', rng.nextInt(5) - 2);
    if (life.age > 25) life.stats.add('health', -rng.nextInt(2));

    if (life.stats['health'] <= 0) {
      life.alive = false;
      life.causeOfDeath = 'Illness';
      life.feed.add(
        FeedEntry(
          life.age,
          'Your body gave out. You died at ${life.age}.',
          kind: 'milestone',
        ),
      );
      return null;
    }

    final event = pickStorylet(life, rng);
    if (event == null) {
      life.feed.add(FeedEntry(life.age, _quietYear(life, rng)));
    }
    return event;
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
    final notes = choice.effects.apply(life);
    final text = fill(
      choice.outcome.isEmpty ? choice.label : choice.outcome,
      life,
    );
    life.feed.add(FeedEntry(life.age, text));
    if (life.stats['health'] <= 0) {
      life.alive = false;
      life.causeOfDeath = 'Injuries';
    }
    return Outcome(text, notes);
  }

  /// Fills {mother}, {father}, {sibling}, {name}, {city}, {surname}.
  String fill(String text, Life life) => text
      .replaceAll('{name}', life.firstName)
      .replaceAll('{surname}', life.surname)
      .replaceAll('{city}', life.city)
      .replaceAll('{country}', life.country)
      .replaceAll('{mother}', life.npc('mother')?.name ?? 'your mother')
      .replaceAll('{father}', life.npc('father')?.name ?? 'your father')
      .replaceAll('{sibling}', life.npc('sibling')?.name ?? 'your cousin');

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

  ActionResult runAction(Life life, GameAction action) {
    final rng = _rngFor(life, action.id.hashCode);
    life.usedActions.add(action.id);
    final result = action.run(life, rng);
    final text = fill(result.text, life);
    life.feed.add(FeedEntry(life.age, text, kind: 'action'));
    return ActionResult(text, result.notes);
  }

  // ---------- Person interactions (People tab, action search) ----------

  ActionResult interact(Life life, Npc npc, Interaction i) {
    final rng = _rngFor(life, i.key(npc).hashCode);
    final r = runInteraction(life, npc, i, rng);
    final text = fill(r.text, life);
    life.feed.add(FeedEntry(life.age, text, kind: 'action'));
    return ActionResult(text, r.notes);
  }
}
