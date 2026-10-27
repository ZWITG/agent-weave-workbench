import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/careers.dart';
import 'package:relivable/engine/economy.dart';
import 'package:relivable/engine/lifespan.dart';
import 'package:relivable/engine/engine.dart';
import 'package:relivable/engine/jobs.dart';
import 'package:relivable/engine/models.dart';
import 'package:relivable/engine/npc_life.dart';
import 'package:relivable/engine/relationships.dart';
import 'package:relivable/engine/scenes.dart';
import 'package:relivable/engine/school.dart';
import 'package:relivable/engine/storylet.dart';
import 'package:relivable/engine/world.dart';

List<Storylet> loadStorylets() {
  final raw = File('assets/storylets/core.json').readAsStringSync();
  return (jsonDecode(raw) as List)
      .map((e) => Storylet.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

/// Plays a whole life (birth to death) choosing at random, like a player
/// who only picks choices that are open.
Life simulate(GameEngine engine, int seed, Map<String, int> fired) {
  final rng = Random(seed);
  final life = engine.newLife(seed: seed);
  while (life.alive && life.age < sliceEndAge) {
    var event = engine.ageUp(life);
    while (event != null) {
      fired[event.id] = (fired[event.id] ?? 0) + 1;
      final open = event.choices
          .where((c) => c.lockReason(life) == null)
          .toList();
      if (open.isEmpty) break;
      engine.choose(life, event, open[rng.nextInt(open.length)]);
      event = engine.nextScene(life);
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
          .where((i) => i.appliesTo(n) && i.lockReason(life, n) == null)
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
    final apply = engine.actions.firstWhere((a) => a.id == 'apply_uni');
    expect(apply.lockReason(life), isNull);
    life.education = 'university';
    life.eduSince = life.age;
    life.school.major = 'Nursing';
    expect(courseProgress(life), 'Year 1 of 4');
    for (var i = 0; i < 4; i++) {
      engine.ageUp(life);
      life.sceneQueue.clear();
    }
    expect(life.education, 'graduate');
    expect(life.school.degrees, contains('Degree in Nursing'));
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
    for (final c in careers.where((c) => !c.special)) {
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

  test('lives run to a natural end at believable ages', () {
    final ages = <int>[];
    for (var seed = 600; seed < 700; seed++) {
      final life = simulate(engine, seed, {});
      expect(life.alive, isFalse);
      expect(life.causeOfDeath, isNotNull);
      ages.add(life.age);
    }
    ages.sort();
    final median = ages[ages.length ~/ 2];
    expect(
      median,
      inInclusiveRange(55, 100),
      reason: 'median age at death $median',
    );
  });

  test('death risk rises with age and falls with good health', () {
    final life = engine.newLife(seed: 61);
    life.stats.values['health'] = 50;
    life.age = 30;
    final young = deathChance(life);
    life.age = 85;
    final old = deathChance(life);
    expect(old, greaterThan(young * 50));
    life.stats.values['health'] = 95;
    expect(deathChance(life), lessThan(old));
  });

  test('retiring pays a pension every birthday', () {
    final life = engine.newLife(seed: 62)..age = 64;
    startCareer(life, careerById('teacher')!);
    life.yearsWorked = 30;
    retire(life);
    expect(life.pension, greaterThan(statePension));
    final before = life.money;
    yearlyMoney(life, Random(1));
    expect(life.lastYear.any((l) => l.$1 == 'Pension'), isTrue);
    expect(life.money, isNot(before));
  });

  test('seed codes round-trip and the same seed gives the same start', () {
    for (final seed in [1, 42, 123456789, 0x7ffffffe]) {
      expect(parseSeedCode(seedCode(seed)), seed);
    }
    final a = engine.newLife(seed: 777, startYear: 2026);
    final b = engine.newLife(seed: 777, startYear: 2026);
    expect(a.fullName, b.fullName);
    expect(a.city, b.city);
    expect(parseSeedCode('not a code!'), isNull);
  });

  test('scenes: illness choices run, lock and log why stats changed', () {
    final life = engine.newLife(seed: 63)..age = 30;
    life.money = 0;
    final scene = buildScene('illness:flu', life)!;
    expect(scene.choices.first.lockReason(life), contains('Needs'));
    final rest = scene.choices.firstWhere((c) => c.label == 'Rest at home');
    final out = engine.choose(life, scene, rest);
    expect(out.text, isNotEmpty);
    life.stats.add('health', -5);
    expect(life.statLog.last.stat, 'health');
  });

  test('energy limits activities unless Classic mode is on', () {
    final life = engine.newLife(seed: 64)..age = 20;
    life.energy = 0;
    final read = engine.actions.firstWhere((a) => a.id == 'read');
    expect(read.lockReason(life), contains('energy'));
    life.classic = true;
    expect(read.lockReason(life), isNull);
  });

  test(
    'grades follow the plan formula and report cards reveal hidden stats',
    () {
      final life = engine.newLife(seed: 70)..age = 13;
      life.education = 'secondary';
      life.stats.values['smarts'] = 90;
      life.stats.values['discipline'] = 20;
      life.school.effort = 100;
      final card = reportCard(life, Random(1))!;
      expect(card, startsWith('Report card'));
      expect(life.school.grades['Maths'], greaterThanOrEqualTo(70));
      expect(life.discovered, contains('discipline'));
      expect(life.school.gpa, greaterThan(2.5));
      life.stats.values['smarts'] = 20;
      life.school.effort = 0;
      reportCard(life, Random(2));
      expect(letter(life.school.grades['Maths']!), anyOf('D', 'F', 'C'));
    },
  );

  test('discipline escalates: detentions, suspension, then expulsion', () {
    final life = engine.newLife(seed: 71)..age = 16;
    life.education = 'secondary';
    newTeachers(life, Random(1));
    for (var i = 0; i < 2; i++) {
      expect(punish(life, 'test'), contains('detention'));
    }
    expect(punish(life, 'test'), contains('suspended'));
    for (var i = 0; i < 5; i++) {
      punish(life, 'test');
    }
    expect(life.flags.containsKey('expelled'), isTrue);
    expect(life.education, 'dropout');
  });

  test('admissions explain the score and scholarships cut fees', () {
    final life = engine.newLife(seed: 72)..age = 18;
    life.education = 'high school graduate';
    life.school.gpa = 3.9;
    life.school.testScore = 95;
    life.school.extracurricular = 80;
    life.stats.values['smarts'] = 95;
    final a = admissionScore(life);
    expect(a.score, greaterThanOrEqualTo(80));
    expect(a.weakest.length, 2);
    expect(scholarshipFor(life, a.score)!.$1, 'Merit scholarship');
    final scene = applyUniScene(life)!;
    final open = scene.choices.firstWhere((c) => c.label.startsWith('Open'));
    expect(open.risk, 'Likely');
    engine.choose(life, scene, open);
    expect(life.education, 'university');
    expect(life.school.tuition, lessThan(tiers['Open']!.fees));
  });

  test('graduate schools lock with exact reasons', () {
    final life = engine.newLife(seed: 73)..age = 23;
    life.education = 'graduate';
    life.school.major = 'Economics';
    life.school.gpa = 3.2;
    life.stats.values['smarts'] = 70;
    final med = gradSchools.firstWhere((g) => g.name == 'Medical school');
    expect(gradLock(life, med), contains('major'));
    final mba = gradSchools.firstWhere((g) => g.degree == 'MBA');
    expect(gradLock(life, mba), isNull);
  });

  test('cliques have entry rules and teachers get school interactions', () {
    final life = engine.newLife(seed: 74)..age = 13;
    life.education = 'secondary';
    life.stats.values['smarts'] = 40;
    final books = cliques.firstWhere((c) => c.id == 'bookworms');
    expect(cliqueLock(life, books), contains('Smarts'));
    final out = cliques.firstWhere((c) => c.id == 'outsiders');
    expect(cliqueLock(life, out), isNull);
    joinClique(life, out);
    expect(life.school.clique, 'outsiders');
    newTeachers(life, Random(3));
    final t = life.npcs.firstWhere((n) => n.circle == 'School');
    final hug = interactions.firstWhere((i) => i.id == 'hug');
    final help = interactions.firstWhere((i) => i.id == 'ask_help');
    expect(hug.appliesTo(t), isFalse);
    expect(help.appliesTo(t), isTrue);
    expect(help.appliesTo(life.npc('mother')!), isFalse);
  });

  test('special careers explain their entry rules', () {
    final life = engine.newLife(seed: 80)..age = 25;
    life.education = 'high school graduate';
    for (final c in careers.where((c) => c.special && c.id != 'hustler')) {
      for (final st in [...Stats.visible, ...Stats.hidden]) {
        life.stats.values[st] = 10;
      }
      expect(c.lockReason(life), isNotNull, reason: c.id);
    }
    life.stats.values['looks'] = 80;
    expect(careerById('model')!.lockReason(life), isNull);
  });

  test('interviews take three answers and explain the result', () {
    final life = engine.newLife(seed: 81)..age = 22;
    life.education = 'high school graduate';
    final office = careerById('office')!;
    applyForCareer(life, office, Random(1));
    var scene = engine.nextScene(life);
    var answers = 0;
    Outcome? last;
    while (scene != null) {
      last = engine.choose(life, scene, scene.choices.first);
      answers++;
      scene = engine.nextScene(life);
    }
    expect(answers, 3);
    expect(last!.text, contains('Interview score'));
  });

  test('performance drives firing and promotions show their odds', () {
    final life = engine.newLife(seed: 82)..age = 30;
    startCareer(life, careerById('office')!);
    expect(bossOf(life), isNotNull);
    life.performance = 10;
    life.stats.values['discipline'] = 5;
    life.stress = 90;
    for (var y = 0; y < 3 && life.job != null; y++) {
      life.age++;
      workYear(life, Random(y), hard: false, slack: true);
    }
    expect(life.job, isNull);
    expect(life.flags.containsKey('fired'), isTrue);
    startCareer(life, careerById('office')!);
    life.performance = 90;
    life.jobSince = life.age - 4;
    expect(promotionOdds(life), greaterThan(30));
  });
}
