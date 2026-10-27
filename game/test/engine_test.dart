import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/careers.dart';
import 'package:relivable/engine/dynasty.dart';
import 'package:relivable/engine/family.dart';
import 'package:relivable/engine/finance.dart';
import 'package:relivable/engine/health.dart';
import 'package:relivable/engine/homes.dart';
import 'package:relivable/engine/justice.dart';
import 'package:relivable/engine/economy.dart';
import 'package:relivable/engine/lifespan.dart';
import 'package:relivable/engine/love.dart';
import 'package:relivable/engine/engine.dart';
import 'package:relivable/engine/jobs.dart';
import 'package:relivable/engine/models.dart';
import 'package:relivable/engine/npc_life.dart';
import 'package:relivable/engine/relationships.dart';
import 'package:relivable/engine/scenes.dart';
import 'package:relivable/engine/school.dart';
import 'package:relivable/engine/storylet.dart';
import 'package:relivable/engine/world.dart';

/// Price from a listing label like "Flat · Old Town · $180,000".
int listingPrice(String label) =>
    int.parse(label.split('\$').last.replaceAll(',', ''));

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
    life.money = 60000;
    final buy = engine.actions.firstWhere((a) => a.id == 'buy_house');
    engine.runAction(life, buy);
    // Listings → a home → offers until one is accepted.
    for (var tries = 0; tries < 12 && !life.has('house'); tries++) {
      if (life.sceneQueue.isEmpty) life.sceneQueue.add('house_hunt');
      var scene = engine.nextScene(life);
      while (scene != null) {
        final pick = scene.id == 'scene:house_hunt'
            ? scene.choices.firstWhere(
                (c) => buyLock(life, listingPrice(c.label)) == null,
              )
            : scene.id == 'scene:house_view'
            ? scene.choices.firstWhere((c) => c.label.startsWith('Offer 5%'))
            : scene.choices.first;
        engine.choose(life, scene, pick);
        scene = engine.nextScene(life);
      }
      life.marks.clear();
      life.age++;
    }
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
    final life = engine.newLife(seed: 63, countryName: 'United States')
      ..age = 30;
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

  test('Kindling shows three profiles with compatibility and odds', () {
    final life = engine.newLife(seed: 90)..age = 25;
    life.money = 1000;
    life.sceneQueue.add('kindling');
    final scene = engine.nextScene(life)!;
    expect(scene.choices.length, 4);
    for (final c in scene.choices.take(3)) {
      expect(c.risk, matches(RegExp('^(Spark|Steady|Mixed|Rocky)')));
      expect(c.needsMoney, 60);
    }
    final out = engine.choose(life, scene, scene.choices.first);
    expect(life.money, 940);
    expect(
      partnerOf(life) != null || out.text.contains('Odds were about'),
      isTrue,
    );
  });

  test('proposal, prenup and wedding lead to marriage', () {
    final life = engine.newLife(seed: 91)..age = 30;
    life.money = 60000;
    final p = candidate(life, Random(1))..addFacets(affection: 40, trust: 40);
    life.npcs.add(p);
    setStage(life, p, 'living');
    for (
      var i = 0;
      i < 6 && stageOf(life, partnerOf(life)!) != 'engaged';
      i++
    ) {
      life.sceneQueue.add('proposal');
      final s = engine.nextScene(life)!;
      engine.choose(life, s, s.choices[1]);
    }
    expect(stageOf(life, partnerOf(life)!), 'engaged');
    life.sceneQueue.add('prenup');
    var s = engine.nextScene(life)!;
    engine.choose(life, s, s.choices.first);
    expect(partnerOf(life)!.info['prenup'], 'none');
    s = engine.nextScene(life)!;
    expect(s.id, 'scene:wedding');
    engine.choose(life, s, s.choices.first);
    final spouse = partnerOf(life)!;
    expect(stageOf(life, spouse), 'married');
    expect(spouse.role, anyOf('Wife', 'Husband'));
  });

  test('divorce splits savings by the prenup', () {
    for (final (prenup, keep) in const [
      ('none', 48000),
      ('standard', 73000),
      ('ironclad', 88000),
    ]) {
      final life = engine.newLife(seed: 92)..age = 40;
      life.money = 100000;
      life.savings = 0;
      life.invested = 0;
      final p = candidate(life, Random(2));
      life.npcs.add(p);
      setStage(life, p, 'married');
      p.info['prenup'] = prenup;
      life.sceneQueue.add('divorce');
      final s = engine.nextScene(life)!;
      engine.choose(life, s, s.choices.first);
      expect(life.money, keep, reason: prenup);
      expect(partnerOf(life), isNull);
      expect(life.flags.containsKey('divorced'), isTrue);
    }
  });

  test('a pregnancy becomes a birth scene and a named child', () {
    final life = engine.newLife(seed: 93)..age = 31;
    final p = candidate(life, Random(3));
    life.npcs.add(p);
    life.flags['expecting'] = Memory(life.age, 'expecting');
    familyYear(life, Random(4));
    expect(life.sceneQueue, contains('birth'));
    final s = engine.nextScene(life)!;
    engine.choose(life, s, s.choices.first);
    final kids = childrenOf(life);
    expect(kids, isNotEmpty);
    expect(kids.first.name, s.choices.first.label);
    expect(kids.first.info['stats'], isA<Map>());
    expect(kids.first.info['otherParent'], p.name);
  });

  test('heirs inherit, trusts open at 18, and dynasties have a cap', () {
    final old = engine.newLife(seed: 94)..age = 70;
    old.assets.clear();
    old.money = 1000000;
    old.savings = 0;
    old.invested = 0;
    final adult = newChild(old, Random(5), ageNow: 30);
    old.npcs.add(adult);
    final minor = newChild(old, Random(6), ageNow: 10);
    old.npcs.add(minor);
    expect(estateOf(old), 900000);
    expect(shareFor(old, adult), 450000);

    final heir = heirLife(old, adult);
    expect(heir.generation, 2);
    expect(heir.surname, old.surname);
    expect(heir.money, 450000);
    expect(heir.lineage.single['name'], old.fullName);
    expect(
      heir.npcs.where((n) => n.circle == 'Family' && !n.alive),
      hasLength(1),
    );

    final young = heirLife(old, minor);
    expect(young.trust, 450000);
    young.age = 18;
    final before = young.money;
    expect(releaseTrust(young), isNotNull);
    expect(young.money, before + 450000);
    expect(young.trust, 0);

    expect(dynastyCap(plus: false), 4);
    expect(dynastyCap(plus: true), 8);
    old.money = -50000;
    expect(estateOf(old), 0);
  });

  // ---------------- Wave E: money, homes, crime and health ----------------

  test('credit score follows payments and prices loans', () {
    final life = engine.newLife(seed: 100)..age = 25;
    startCareer(life, careerById('office')!);
    expect(life.credit, isNull);
    takeLoan(life, loanTypes.first, 3000);
    expect(life.credit, 640);
    final rate = rateOf(life, 'Personal loan');
    expect(rate, inInclusiveRange(0.08, 0.18));
    life.money = 100000;
    yearlyMoney(life, Random(1));
    expect(life.credit, greaterThan(640));
    life.credit = 820;
    expect(loanTypes.first.rate(life), lessThan(rate));
    // Far over the card limit: a default, and a crisis scene.
    life.debts['Credit card'] = 50000;
    life.money = 0;
    life.age++;
    yearlyMoney(life, Random(2));
    expect(life.credit, lessThan(820));
    expect(life.sceneQueue, contains('debt_crisis'));
  });

  test('bankruptcy clears most debts, keeps the home, blocks loans', () {
    final life = engine.newLife(seed: 101)..age = 40;
    startCareer(life, careerById('office')!);
    life.debts.addAll({
      'Credit card': 20000,
      'Personal loan': 10000,
      'Student loan': 5000,
      'Mortgage': 100000,
    });
    life.invested = 3000;
    life.savings = 10000;
    bankruptcy(life);
    expect(life.debts.keys.toSet(), {'Student loan', 'Mortgage'});
    expect(life.invested, 0);
    expect(life.savings, 2000);
    expect(life.credit, 320);
    expect(loanLock(life, loanTypes.first), contains('bankruptcy'));
  });

  test('market prices are shared, stay in a band and pay dividends', () {
    final a = World(seed: 9), b = World(seed: 9);
    expect(a.pricesFor(2030), b.pricesFor(2030));
    for (var y = 2030; y < 2600; y++) {
      for (final t in tickers.where((t) => y >= t.since)) {
        final p = a.pricesFor(y)[t.id]!;
        expect(p.isFinite, isTrue);
        expect(
          p,
          lessThan(t.base * (t.kind == 'coin' ? 500 : 60)),
          reason: '${t.id} in $y',
        );
      }
    }
    final life = engine.newLife(seed: 102)..age = 30;
    life.quotes = Map.of(a.pricesFor(2030));
    life.money = 10000;
    buyShares(life, 'BRKL', 5000);
    expect(life.money, 5000);
    expect(holdingValue(life, 'BRKL'), inInclusiveRange(4999, 5001));
    expect(dividends(life), greaterThan(0));
    sellShares(life, 'BRKL', holdingValue(life, 'BRKL'));
    expect(life.shares, isEmpty);
    expect(life.money, inInclusiveRange(9999, 10001));
  });

  test('a business explains its year; losses lead to insolvency', () {
    final life = engine.newLife(seed: 103)..age = 30;
    life.money = 100000;
    life.sceneQueue.add('biz_found');
    var scene = engine.nextScene(life);
    while (scene != null) {
      engine.choose(life, scene, scene.choices.first);
      scene = engine.nextScene(life);
    }
    final b = life.business!;
    expect(b.industry, industries.first.id);
    final profit = businessYear(life, Random(3));
    expect(b.revenue, greaterThan(0));
    expect(b.lines.first.$1, 'Revenue');
    expect(b.reasons, isNotEmpty);
    expect(profit, b.profit);
    b
      ..quality = 5
      ..brand = 0
      ..satisfaction = 0
      ..staff = 30;
    for (var y = 0; y < 2; y++) {
      life.age++;
      businessYear(life, Random(y));
    }
    expect(life.sceneQueue, contains('insolvency'));
  });

  test('house hunting: viewings reveal traits, surveys reveal all', () {
    final life = engine.newLife(seed: 104)..age = 30;
    life.money = 500;
    final homes = listings(life);
    expect(homes.length, 6);
    expect(listings(life).map((h) => h.price), homes.map((h) => h.price));
    final h = homes.firstWhere(
      (h) => h.traits.isNotEmpty,
      orElse: () => homes.first,
    );
    life.sceneQueue.add('house_view:${h.i}');
    final view = engine.nextScene(life)!;
    final survey = view.choices.firstWhere((c) => c.label.contains('survey'));
    engine.choose(life, view, survey);
    final again = engine.nextScene(life)!;
    expect(again.text, contains('surveyed'));
    expect(buyLock(life, h.price), contains('deposit'));
  });

  test('crime: risk with reasons, arrest, plea, prison and release', () {
    final life = engine.newLife(seed: 105)..age = 25;
    startCareer(life, careerById('office')!);
    final (odds, why) = caughtOdds(life, crimeById('burglary'));
    expect(odds, inInclusiveRange(3, 90));
    expect(why, isA<List<String>>());
    life.sceneQueue.add('arrest:burglary:60');
    var scene = engine.nextScene(life)!;
    engine.choose(
      life,
      scene,
      scene.choices.firstWhere((c) => c.label == 'Go quietly'),
    );
    scene = engine.nextScene(life)!;
    expect(scene.text, contains('plead guilty'));
    engine.choose(life, scene, scene.choices.first);
    expect(life.prison, isNotNull);
    expect(life.job, isNull);
    expect(life.record, hasLength(1));
    expect(life.npc('cellmate'), isNotNull);
    final gym = engine.actions.firstWhere((a) => a.id == 'gym');
    final job = engine.actions.firstWhere((a) => a.id == 'prison_job');
    expect(gym.lockReason(life), 'Not possible in prison');
    expect(job.lockReason(life), isNull);
    expect(careerById('police')!.lockReason(life), isNotNull);
    for (var y = 0; y < 8 && life.prison != null; y++) {
      life.age++;
      prisonYear(life, Random(y));
      var s = engine.nextScene(life);
      while (s != null) {
        engine.choose(life, s, s.choices.first);
        s = engine.nextScene(life);
      }
    }
    expect(life.prison, isNull);
  });

  test('trials explain the verdict; records seal after clean years', () {
    final life = engine.newLife(seed: 106)..age = 20;
    life.sceneQueue.add('trial:burglary:50:88');
    final trial = engine.nextScene(life)!;
    final out = engine.choose(life, trial, trial.choices.first);
    expect(out.text, contains('Conviction chance'));
    life.prison = null;
    life.record
      ..clear()
      ..add({
        'crime': 'burglary',
        'age': 20,
        'band': 'moderate',
        'sentence': 'fine',
        'youth': false,
        'sealed': false,
      });
    life.education = 'high school graduate';
    life.age = 25;
    expect(
      careerById('police')!.lockReason(life),
      'Blocked by a criminal record',
    );
    life.age = 31;
    justiceYear(life, Random(1));
    expect(convictions(life), 0);
  });

  test('illness shows symptoms first; care costs follow the country', () {
    final us = engine.newLife(seed: 107, countryName: 'United States')
      ..age = 50;
    final pt = engine.newLife(seed: 107, countryName: 'Portugal')..age = 50;
    expect(careCost(us, 40000), 40000);
    expect(careCost(pt, 40000), lessThan(4000));
    us.insurance = 'full';
    expect(careCost(us, 40000), 4000);
    us.money = 100000;
    us.conditions.add(Condition(id: 'cancer', since: 50, stage: 1));
    us.sceneQueue.add('symptom:cancer');
    final symptom = engine.nextScene(us)!;
    expect(symptom.text, contains('lump'));
    us.conditions.first.known = true;
    us.sceneQueue.add('treat:cancer');
    final treat = engine.nextScene(us)!;
    expect(treat.choices.first.risk, contains('85% success at stage 1'));
    final before = healthRiskFactor(us);
    us.conditions.first.stage = 4;
    expect(healthRiskFactor(us), greaterThan(before * 5));
    expect(conditionCause(us), 'Cancer');
  });

  test('addiction: exposure, yearly costs, rehab and relapse', () {
    final life = engine.newLife(seed: 108)..age = 25;
    life.stats.values['willpower'] = 0;
    life.stats.values['impulsivity'] = 100;
    life.stress = 100;
    for (var i = 0; i < 200 && life.addictions.isEmpty; i++) {
      exposeTo(life, 'alcohol', Random(i));
    }
    expect(life.addictions, contains('alcohol'));
    expect(healthCosts(life).map((c) => c.$1), contains('Drinking'));
    life.sceneQueue.add('rehab:alcohol');
    final rehab = engine.nextScene(life)!;
    expect(rehab.choices.first.risk, contains('% chance'));
    life.addictions.clear();
    life.recovery['alcohol'] = 0;
    var relapsed = false;
    for (var i = 0; i < 50 && !relapsed; i++) {
      life.recovery['alcohol'] = 0;
      healthYear(life, Random(i));
      relapsed = life.addictions.containsKey('alcohol');
    }
    expect(relapsed, isTrue);
  });

  test('long low mood brings depression with support options', () {
    final life = engine.newLife(seed: 109)..age = 30;
    for (var y = 0; y < 2; y++) {
      life.stats.values['happiness'] = 10;
      healthYear(life, Random(y));
    }
    expect(conditionOf(life, 'depression'), isNotNull);
    life.sceneQueue.remove('mind:depression');
    life.sceneQueue.add('mind:depression');
    final scene = engine.nextScene(life)!;
    expect(scene.category, 'mind');
    expect(scene.choices.map((c) => c.label).join(), contains('therapist'));
  });

  test('people you love grow old, and losing them brings grief', () {
    final life = engine.newLife(seed: 110)..age = 60;
    final mum = life.npc('mother')!;
    mum.addFacets(affection: 50, trust: 50);
    life.npcs[life.npcs.indexOf(mum)] = mum;
    var lines = <String>[];
    for (var i = 0; i < 200 && mum.alive; i++) {
      lines = npcAging(life, Random(i));
      life.age++;
    }
    expect(mum.alive, isFalse);
    expect(lines.join(), contains('died'));
  });
}
