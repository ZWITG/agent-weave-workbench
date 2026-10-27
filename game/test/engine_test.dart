import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/careers.dart';
import 'package:relivable/engine/economy.dart';
import 'package:relivable/engine/engine.dart';
import 'package:relivable/engine/models.dart';
import 'package:relivable/engine/npc_life.dart';
import 'package:relivable/engine/relationships.dart';
import 'package:relivable/engine/storylet.dart';
import 'package:relivable/engine/world.dart';

List<Storylet> loadStorylets() {
  final raw = File('assets/storylets/core.json').readAsStringSync();
  return (jsonDecode(raw) as List)
      .map((e) => Storylet.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

/// Plays a whole life (birth to the slice end) choosing at random.
Life simulate(GameEngine engine, int seed, Map<String, int> fired) {
  final rng = Random(seed);
  final life = engine.newLife(seed: seed);
  while (life.alive && life.age < sliceEndAge) {
    final event = engine.ageUp(life);
    if (event != null) {
      fired[event.id] = (fired[event.id] ?? 0) + 1;
      engine.choose(
        life,
        event,
        event.choices[rng.nextInt(event.choices.length)],
      );
    }
    final open = engine.actions
        .where((a) => a.lockReason(life) == null)
        .toList();
    if (open.isNotEmpty && rng.nextBool()) {
      engine.runAction(life, open[rng.nextInt(open.length)]);
    }
    // Random person interactions.
    for (var k = 0; k < 2; k++) {
      final n = life.npcs[rng.nextInt(life.npcs.length)];
      final avail = interactions
          .where((i) => i.lockReason(life, n) == null)
          .toList();
      if (avail.isNotEmpty) {
        engine.interact(life, n, avail[rng.nextInt(avail.length)]);
      }
    }
  }
  return life;
}

void main() {
  final storylets = loadStorylets();
  final engine = GameEngine(storylets);

  test('storylet ids are unique and every choice has a label', () {
    final ids = storylets.map((s) => s.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final s in storylets) {
      expect(s.choices, isNotEmpty, reason: s.id);
      expect(s.minAge <= s.maxAge, isTrue, reason: s.id);
    }
  });

  test(
    'flags required by a storylet are set by some choice (no dead events)',
    () {
      final settable = <String>{
        'caught_shoplifting',
        'owns_car',
        // set by the world when a new life is linked to an earlier one
        'echo_surname',
        'echo_city',
        'echo_country',
      }; // set by actions
      for (final s in storylets) {
        for (final c in s.choices) {
          settable.addAll(c.effects.setFlags.keys);
        }
      }
      for (final s in storylets) {
        for (final f in [
          ...s.requiresFlags,
          if (s.remembers != null) s.remembers!,
        ]) {
          expect(
            settable.contains(f),
            isTrue,
            reason: '${s.id} needs flag $f that nothing sets',
          );
        }
      }
    },
  );

  test('simulator bot: 500 lives run to the end without errors', () {
    final fired = <String, int>{};
    for (var seed = 1; seed <= 500; seed++) {
      final life = simulate(engine, seed, fired);
      expect(life.age <= sliceEndAge, isTrue);
      for (final k in [...Stats.visible, ...Stats.hidden]) {
        expect(life.stats[k], inInclusiveRange(0, 100));
      }
      for (final n in life.npcs) {
        expect(n.bond, inInclusiveRange(0, 100));
      }
    }
    final never = storylets
        .where((s) => !fired.containsKey(s.id))
        .map((s) => s.id)
        .toList();
    expect(
      never,
      isEmpty,
      reason: 'Storylets that never fired in 500 lives: $never',
    );
  });

  test('a remembered choice comes back years later', () {
    // Find a seed where the sibling lawsuit happens, then check the callback.
    for (var seed = 1; seed < 3000; seed++) {
      final life = engine.newLife(seed: seed);
      if (life.npc('sibling') == null) continue;
      while (life.age < sliceEndAge) {
        final e = engine.ageUp(life);
        if (e == null) continue;
        final sue = e.choices.where(
          (c) => c.effects.setFlags.containsKey('sued_sibling'),
        );
        engine.choose(life, e, sue.isNotEmpty ? sue.first : e.choices.first);
        if (e.id == 'sibling_door_baby') {
          expect(life.flags.containsKey('reconciled_sibling'), isTrue);
          return;
        }
      }
    }
    fail('The lawsuit callback never fired');
  });

  test('saves round-trip through JSON', () {
    final life = simulate(engine, 42, {});
    final copy = Life.fromJson(jsonDecode(jsonEncode(life.toJson())));
    expect(copy.toJson(), life.toJson());
  });

  test('locked actions explain why', () {
    final baby = engine.newLife(seed: 7);
    final job = engine.actions.firstWhere((a) => a.id == 'apply_job');
    expect(job.lockReason(baby), 'Unlocks at 18');
  });

  test('Bond % follows the planning formula and has a label', () {
    final n = Npc(
      id: 'x',
      role: 'Friend',
      name: 'Sam',
      birthYear: 2000,
      bond: 50,
    );
    expect(n.bond, 50);
    n.resentment = 20;
    expect(n.bond, 40); // 0.35*50 + 0.25*50 + 0.2*50 + 0.2*50 - 0.5*20
    expect(n.bondLabel, 'Distant');
  });

  test('positive interactions have diminishing returns within a year', () {
    final life = engine.newLife(seed: 11)..age = 20;
    final mum = life.npc('mother')!
      ..affection = 40
      ..familiarity = 40;
    final spend = interactions.firstWhere((i) => i.id == 'spend_time');
    final b0 = mum.bond;
    engine.interact(life, mum, spend);
    final b1 = mum.bond;
    engine.interact(life, mum, spend);
    final b2 = mum.bond;
    engine.interact(life, mum, spend);
    final b3 = mum.bond;
    expect(b1 - b0, greaterThan(b2 - b1));
    expect(b3, b2);
    expect(spend.hint(life, mum), 'No effect again this year');
  });

  test('a grudge blocks asking for favours and says why', () {
    final life = engine.newLife(seed: 12)..age = 25;
    final dad = life.npc('father')!;
    dad.remember(
      NpcMemory(
        age: 24,
        text: 'the money you never paid back',
        valence: -3,
        intensity: 5,
        tags: ['money'],
      ),
    );
    final favour = interactions.firstWhere((i) => i.id == 'ask_favour');
    expect(favour.lockReason(life, dad), contains('still resents'));
  });

  test('mini-game activities resolve at any score and keep stats in range', () {
    final games = engine.actions.where((a) => a.miniGame != null).toList();
    expect(games.length, greaterThanOrEqualTo(5));
    for (final a in games) {
      expect(a.scored, isNotNull, reason: a.id);
      for (final score in [0.0, 0.6, 1.0]) {
        final life = engine.newLife(seed: 21)
          ..age = 30
          ..money = 5000;
        final r = engine.runAction(life, a, score: score);
        expect(r.text, isNotEmpty);
        for (final v in life.stats.values.values) {
          expect(v, inInclusiveRange(0, 100));
        }
      }
    }
  });

  test('university finishes after four years and opens degree jobs', () {
    final life = engine.newLife(seed: 31)..age = 18;
    life.education = 'high school graduate';
    final nurse = careerById('nurse')!;
    expect(nurse.lockReason(life), contains('University degree'));
    final enrol = engine.actions.firstWhere((a) => a.id == 'enrol_university');
    expect(enrol.lockReason(life), isNull);
    engine.runAction(life, enrol);
    expect(courseProgress(life), 'Year 1 of 4');
    for (var i = 0; i < 4; i++) {
      engine.ageUp(life);
    }
    expect(life.education, 'graduate');
    life.stats.values['smarts'] = 80;
    expect(nurse.lockReason(life), isNull);
  });

  test('career ladder: promotion needs time in role and says why', () {
    final life = engine.newLife(seed: 32)..age = 20;
    startCareer(life, careerById('retail')!);
    final promo = engine.actions.firstWhere((a) => a.id == 'ask_promotion');
    expect(promo.lockReason(life), 'Needs 2 more years in role');
    life.age += 2;
    expect(promo.lockReason(life), isNull);
    life.stats.values['discipline'] = 100;
    life.stats.values['smarts'] = 100;
    var tries = 0;
    while (life.careerRank == 0 && tries++ < 20) {
      life.usedActions.clear();
      engine.runAction(life, promo);
      life.age++; // the roll is seeded per year
    }
    expect(life.careerRank, 1);
    expect(life.job, 'Shift supervisor');
    expect(life.salary, careerById('retail')!.salaryAt(1));
  });

  test('every job on the board is reachable by some education path', () {
    for (final c in careers) {
      final life = engine.newLife(seed: 33)..age = 25;
      life.stats.values['smarts'] = 90;
      life.education = switch (c.needs) {
        'trade' => 'trade certificate',
        'associate' => 'associate degree',
        'degree' => 'graduate',
        _ => 'high school graduate',
      };
      expect(c.lockReason(life), isNull, reason: c.id);
    }
  });

  test('each birthday\'s cash flow adds up exactly to the change in cash', () {
    for (var seed = 0; seed < 200; seed++) {
      final life = engine.newLife(seed: seed)..age = 22;
      startCareer(life, careers[seed % careers.length]);
      life.money = 3000 * (seed % 5);
      if (seed.isEven) addRental(life);
      if (seed % 3 == 0) life.debts['Student loan'] = 8000;
      life.lifestyle = lifestyles.keys.elementAt(seed % 3);
      for (var y = 0; y < 5; y++) {
        final before = life.money;
        yearlyMoney(life, Random(seed * 10 + y));
        final sum = life.lastYear.fold(0, (a, l) => a + l.$2);
        expect(life.money - before, sum, reason: 'seed $seed year $y');
        expect(life.money, greaterThanOrEqualTo(0));
        expect(life.netWorthByAge[life.age], life.netWorth);
        life.age++;
      }
    }
  });

  test('overspending becomes credit card debt, with a warning', () {
    final life = engine.newLife(seed: 41)..age = 25;
    addRental(life);
    life.money = 0;
    final feed = yearlyMoney(life, Random(1));
    expect(life.debts['Credit card'], greaterThan(0));
    expect(feed.join(), contains('credit card'));
  });

  test('a house comes with a mortgage that shrinks every year', () {
    final life = engine.newLife(seed: 42)..age = 30;
    startCareer(life, careerById('developer')!);
    life.money = 30000;
    final buy = engine.actions.firstWhere((a) => a.id == 'buy_house');
    engine.runAction(life, buy);
    expect(life.has('house'), isTrue);
    final owed = life.debts['Mortgage']!;
    yearlyMoney(life, Random(2));
    expect(life.debts['Mortgage'], lessThan(owed));
    expect(annuity(100000, 0.05, 25), inInclusiveRange(7090, 7100));
  });

  test('one world, one history: every life in a year reads the same news', () {
    final world = World(seed: 7);
    final e = GameEngine(loadStorylets(), world: world);
    final a = e.newLife(seed: 1, countryName: 'Portugal');
    final b = e.newLife(seed: 2, countryName: 'Portugal');
    for (var i = 0; i < 6; i++) {
      e.ageUp(a);
    }
    final seen = world
        .storiesFor(a.year, 'Portugal', a.city)
        .map((s) => s.headline)
        .toList();
    while (b.year < a.year) {
      e.ageUp(b);
    }
    final global = world
        .storiesFor(b.year, 'Portugal', b.city)
        .where((s) => s.scope == 'global');
    for (final s in global) {
      expect(seen, contains(s.headline));
    }
    expect(world.economyFor(a.year), a.economy);
    // The world survives saving.
    final copy = World.fromJson(jsonDecode(jsonEncode(world.toJson())));
    expect(
      copy.storiesFor(a.year, 'Portugal', a.city).length,
      world.storiesFor(a.year, 'Portugal', a.city).length,
    );
  });

  test('a notable deed enters the history and echoes into a later life', () {
    final world = World(seed: 9);
    final e = GameEngine(loadStorylets(), world: world);
    final first = e.newLife(seed: 3, countryName: 'Ireland');
    first.age = 26;
    first.flags['jackpot'] = Memory(26, 'winning the lottery');
    e.checkDeeds(first);
    expect(world.ledger.single.headline, contains('lottery'));
    expect(world.reputation(first.surname), isNotNull);
    world.recordLife(first);
    // The next life starts later in the same world and can meet that story.
    final next = e.newLife(seed: 4, countryName: 'Ireland');
    expect(next.birthYear, greaterThanOrEqualTo(first.year));
    expect(next.echo['person'], '${first.firstName} ${first.surname}');
    expect(e.fill('{echo_person}', next), next.echo['person']);
  });

  test('people you know get yearly updates in the feed', () {
    final life = engine.newLife(seed: 51)..age = 30;
    var updates = 0;
    for (var y = 0; y < 20; y++) {
      updates += npcUpdates(life, Random(y)).length;
    }
    expect(updates, greaterThan(3));
    expect(life.npcs.any((n) => n.news.isNotEmpty), isTrue);
  });

  test('the newspaper costs \$2 once a year and can be re-read', () {
    final life = engine.newLife(seed: 52)..age = 20;
    life.money = 10;
    final paper = engine.actions.firstWhere((a) => a.id == 'newspaper');
    engine.runAction(life, paper);
    expect(life.money, 8);
    expect(paper.lockReason(life), isNull);
    engine.runAction(life, paper);
    expect(life.money, 8);
  });
}
