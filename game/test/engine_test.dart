import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:relivable/engine/actions.dart';
import 'package:relivable/engine/careers.dart';
import 'package:relivable/engine/celebrity.dart';
import 'package:relivable/engine/dynasty.dart';
import 'package:relivable/engine/family.dart';
import 'package:relivable/engine/finance.dart';
import 'package:relivable/engine/community.dart';
import 'package:relivable/engine/country_life.dart';
import 'package:relivable/engine/health.dart';
import 'package:relivable/engine/crime_jobs.dart';
import 'package:relivable/engine/gangs.dart';
import 'package:relivable/engine/prison_life.dart';
import 'package:relivable/engine/heists.dart';
import 'package:relivable/engine/identity.dart';
import 'package:relivable/engine/homes.dart';
import 'package:relivable/engine/justice.dart';
import 'package:relivable/engine/economy.dart';
import 'package:relivable/engine/business_kinds.dart';
import 'package:relivable/engine/births.dart';
import 'package:relivable/engine/elite.dart';
import 'package:relivable/engine/currency.dart';
import 'package:relivable/engine/lifespan.dart';
import 'package:relivable/engine/pets.dart';
import 'package:relivable/engine/social.dart';
import 'package:relivable/engine/love.dart';
import 'package:relivable/engine/meta.dart';
import 'package:relivable/engine/kin.dart';
import 'package:relivable/engine/possessions.dart';
import 'package:relivable/engine/profile.dart';
import 'package:relivable/engine/property.dart';
import 'package:relivable/engine/shopping.dart';
import 'package:relivable/engine/variants.dart';
import 'package:relivable/engine/recap.dart';
import 'package:relivable/engine/engine.dart';
import 'package:relivable/engine/jobs.dart';
import 'package:relivable/engine/models.dart';
import 'package:relivable/engine/music.dart';
import 'package:relivable/engine/news_impact.dart';
import 'package:relivable/engine/npc_life.dart';
import 'package:relivable/engine/odds.dart';
import 'package:relivable/engine/relationships.dart';
import 'package:relivable/engine/scenes.dart';
import 'package:relivable/engine/school.dart';
import 'package:relivable/engine/storylet.dart';
import 'package:relivable/engine/world.dart';
import 'package:relivable/engine/world_data.dart';
import 'package:relivable/sound.dart';

/// Price from a listing label like "Flat · Old Town · $180,000".
int listingPrice(String label) =>
    int.parse(label.split('\$').last.replaceAll(',', ''));

List<Storylet> loadStorylets() {
  return [
    for (final file in storyletFiles)
      ...(jsonDecode(File('assets/storylets/$file').readAsStringSync()) as List)
          .map((e) => Storylet.fromJson(Map<String, dynamic>.from(e))),
  ];
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
    // Murder means decades in prison; the bot would hide most of the game.
    final open = engine.actions
        .where((a) => a.id != 'murder' && a.lockReason(life) == null)
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
  // Seasonal events follow the real calendar; tests use a quiet day.
  seasonClock = () => DateTime(2026, 8, 1);
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
        // set by the love scenes (love.dart)
        'married',
        // set by the world when a new life is linked to an earlier one
        'echo_surname',
        'echo_city',
        'echo_country',
        // set by code: fostering, collecting, heirlooms (kin.dart,
        // possessions.dart)
        'foster_carer',
        'collector',
        'heirloom',
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
    // Very late-life (95+) and married-life storylets are checked directly
    // below: the random bot rarely lives that long and never marries.
    // Lives the bot rarely leads (fostering, collecting, heirlooms, raising
    // children and grandchildren) are checked directly too, with that
    // family built for them.
    const rare = {'foster_carer', 'collector', 'heirloom', 'grandparent'};
    // Follow-ups to an earlier choice with a short age window (Tomás's
    // wedding, the startup's result, getting caught sneaking out...): the
    // random bot reaches each only a handful of times in 500 lives, so
    // which ones it misses changes with any tweak. They are checked
    // directly below; the flags they need are covered by the "no dead
    // events" test above.
    bool chain(Storylet s) =>
        s.remembers != null &&
        s.requiresFlags.isNotEmpty &&
        s.maxAge - s.minAge <= 8;
    // Events that need a life state the random bot rarely reaches (owning
    // a house, retiring, a job plus an earlier choice) are also checked
    // directly, with that state built for them.
    bool rareState(Storylet s) =>
        s.conditions.keys.any(
          const {'owns', 'retired', 'money', 'prison'}.contains,
        ) ||
        (s.conditions.containsKey('job') && s.requiresFlags.isNotEmpty);
    bool direct(Storylet s) =>
        chain(s) ||
        rareState(s) ||
        s.minAge >= 95 ||
        s.requiresFlags.contains('married') ||
        s.requiresFlags.any(rare.contains) ||
        s.conditions.containsKey('childAge') ||
        s.requiresNpcs.any((n) => n == '@child' || n == '@grandchild');
    final never = storylets
        .where((s) => !fired.containsKey(s.id) && !direct(s))
        .map((s) => s.id)
        .toList();
    for (final s in storylets.where(direct)) {
      final old = engine.newLife(seed: 7)..age = s.minAge;
      final p = candidate(old, Random(1));
      old.npcs.add(p);
      setStage(old, p, 'married');
      for (final f in s.requiresFlags) {
        old.flags[f] = Memory(old.age, f);
      }
      if (s.conditions['job'] == true) {
        old.job = 'Accountant';
        old.salary = 40000;
      }
      if (s.conditions['retired'] == true) old.retired = true;
      final money = '${s.conditions['money'] ?? ''}';
      if (money.startsWith('>')) {
        old.money = int.parse(money.replaceAll(RegExp(r'[^0-9]'), '')) + 1;
      } else if (money.startsWith('<')) {
        old.money = 0;
      }
      if (s.requiresNpcs.contains('@friend') &&
          !old.npcs.any((n) => n.circle == 'Friends' && n.alive)) {
        old.npcs.add(
          Npc(
            id: 'pal',
            role: 'Friend',
            name: 'Sam',
            birthYear: old.year - old.age,
            circle: 'Friends',
            bond: 70,
          ),
        );
      }
      for (final kind in List<String>.from(s.conditions['owns'] ?? const [])) {
        old.assets.add(
          Asset(
            id: 'own_$kind',
            kind: kind,
            name: kind,
            value: 100000,
            yearlyCost: 0,
            since: old.age,
          ),
        );
      }
      final range = RegExp(r'^(\d+)')
          .firstMatch('${s.conditions['childAge'] ?? '30'}');
      old.npcs.add(
        newChild(old, Random(2), ageNow: int.parse(range!.group(1)!)),
      );
      for (final id in s.requiresNpcs.where((n) => !n.startsWith('@'))) {
        if (old.npc(id) == null) {
          old.npcs.add(
            Npc(
              id: id,
              role: 'Friend',
              name: id,
              birthYear: old.year - old.age,
              circle: 'Friends',
            ),
          );
        }
      }
      if (s.requiresNpcs.contains('@grandchild')) {
        old.npcs.add(
          Npc(
            id: 'gc',
            role: 'Granddaughter',
            name: 'Ava',
            birthYear: old.year - 6,
            circle: 'Grandchildren',
          ),
        );
      }
      expect(s.isEligible(old), isTrue, reason: s.id);
    }
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
      while (life.alive && life.age < sliceEndAge) {
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
    expect(life.salary, careerById('retail')!.payIn(life, 1));
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

  test('Kindling shows three profiles with compatibility, odds hidden', () {
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
    expect(partnerOf(life) != null || !out.text.contains('%'), isTrue);
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
    expect(life.sceneQueue, contains('insolvency:${b.name}'));
    expect(buildScene(life.sceneQueue.first, life)!.text, contains(b.name));
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
    expect(out.text, isNot(contains('Conviction chance')));
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
    expect(treat.choices.first.risk, 'A chance of success at stage 1');
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
    expect(rehab.choices.first.risk, startsWith('A chance'));
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
    final mum = life.who('@parent')!;
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

  // ---------------- Wave F1: identity, families, countries, content ----------------

  test('families of every shape at birth, with fitting storylets', () {
    final mums = engine.newLife(seed: 120, family: 'two_mums');
    expect(mums.npc('mother'), isNotNull);
    expect(mums.npc('mother2'), isNotNull);
    expect(mums.npc('father'), isNull);
    final dadText = storylets.where(
      (s) => s.requiresNpcs.contains('father') && s.minAge <= 3,
    );
    expect(dadText, isNotEmpty);
    for (final s in dadText) {
      expect(s.isEligible(mums..age = s.minAge), isFalse, reason: s.id);
    }
    final single = engine.newLife(seed: 121, family: 'single_dad');
    expect(single.npc('mother'), isNull);
    expect(single.feed.first.text, contains('on their own'));
  });

  test('identity: pronouns render, coming out changes bonds not stats', () {
    final life = engine.newLife(seed: 122, family: 'two')..age = 15;
    setIdentity(life, identity: 'Non-binary', pronouns: 'they/them');
    expect(engine.fill('{they} {them} {their}', life), 'they them their');
    life.pronouns = 'ze/zir/zir';
    expect(engine.fill('{they}/{them}', life), 'ze/zir');
    expect(life.sceneQueue, contains('coming_out'));
    final before = Map.of(life.stats.values)..remove('happiness');
    final scene = engine.nextScene(life)!;
    engine.choose(life, scene, scene.choices.first);
    final after = Map.of(life.stats.values)..remove('happiness');
    expect(after, before);
    expect(life.flags.containsKey('came_out'), isTrue);
    setIdentity(life, orientation: 'Gay');
    expect(life.attractedTo, life.gender == 'male' ? 'men' : 'women');
  });

  test('moving abroad shows visa odds and changes country rules', () {
    final life = engine.newLife(seed: 123, countryName: 'United States')
      ..age = 30;
    life.money = 50000;
    final (odds, why) = visaOdds(life, 'Ireland');
    expect(why.join(), contains('Shared language'));
    expect(odds, greaterThan(45));
    for (var i = 0; i < 10 && life.country == 'United States'; i++) {
      life.sceneQueue.add('emigrate');
      final scene = engine.nextScene(life)!;
      final pick = scene.choices.firstWhere(
        (c) => c.label.startsWith('Ireland'),
      );
      engine.choose(life, scene, pick);
      life.lastSeen.clear();
      life.age++;
    }
    expect(life.country, 'Ireland');
    expect(life.marks, containsAll(['lived:United States', 'lived:Ireland']));
    expect(healthSystem(life), 'universal');
    expect(countryProfile('Japan').lifeExpectancy, greaterThan(80));
    expect(countries.length, greaterThanOrEqualTo(14));
  });

  test('legal name change and plenty to do in adult life', () {
    final life = engine.newLife(seed: 124)..age = 40;
    life.sceneQueue.add('name_change');
    final scene = engine.nextScene(life)!;
    final old = life.firstName;
    engine.choose(life, scene, scene.choices.first);
    expect(life.firstName, isNot(old));
    final p = candidate(life, Random(5));
    life.npcs.add(p);
    life.npcs.add(newChild(life, Random(6), ageNow: 14));
    startCareer(life, careerById('office')!);
    final open = storylets.where((s) => s.isEligible(life)).length;
    expect(open, greaterThanOrEqualTo(8));
  });

  // ---------------- Wave F2: fame, social media and pets ----------------

  test('posts show reach and risk; fame and followers are separate', () {
    final life = engine.newLife(seed: 130)..age = 20;
    life.classic = true;
    final (chance, parts) = viralChance(life, 'vybe', 'talent');
    expect(chance, inInclusiveRange(0.5, 25));
    expect(parts.first, startsWith('skill'));
    for (var i = 0; i < 12; i++) {
      post(life, 'lenso', 'selfie', Random(i));
    }
    expect(life.followers['lenso'], greaterThan(0));
    expect(
      viralChance(life, 'lenso', 'selfie').$2.join(),
      contains('too often'),
    );
    expect(verifyRequirements(life).first.$1, contains('100k'));
    life.followers['vybe'] = 150000;
    life.fame = 25;
    expect(applyVerification(life).notes, contains('Verified'));
    expect(tierOf(life), 'Verified');
  });

  test('scandals only come from things you actually did', () {
    final life = engine.newLife(seed: 131)..age = 30;
    life.fame = 60;
    for (var i = 0; i < 30; i++) {
      fameYear(life, Random(i));
      life.fame = 60;
    }
    expect(life.sceneQueue.where((s) => s.startsWith('scandal')), isEmpty);
    life.flags['affair_found'] = Memory(29, 'an affair');
    life.deal = {
      'brand': 'X',
      'image': 'Luxury',
      'fee': 10000,
      'until': 40,
      'posts': 0,
    };
    expect(socialIncome(life).map((e) => e.$1), contains('Brand deal: X'));
    for (
      var i = 0;
      i < 40 && !life.sceneQueue.any((s) => s.startsWith('scandal'));
      i++
    ) {
      fameYear(life, Random(100 + i));
      life.fame = 60;
    }
    final id = life.sceneQueue.firstWhere((s) => s.startsWith('scandal'));
    expect(id, 'scandal:affair');
    life.sceneQueue.clear();
    life.sceneQueue.add(id);
    final scene = engine.nextScene(life)!;
    engine.choose(
      life,
      scene,
      scene.choices.firstWhere((c) => c.label == 'Deny everything'),
    );
    expect(life.cancelledUntil, greaterThan(life.age));
    expect(life.deal, isNull);
  });

  test('pets are characters that age, need care and are remembered', () {
    final life = engine.newLife(seed: 132, countryName: 'United Kingdom')
      ..age = 25;
    life.money = 10000;
    life.sceneQueue.add('pet_adopt:shelter:common');
    var scene = engine.nextScene(life)!;
    engine.choose(
      life,
      scene,
      scene.choices.firstWhere((c) => c.label.startsWith('Hamster')),
    );
    scene = engine.nextScene(life)!;
    engine.choose(life, scene, scene.choices.first);
    final pet = petsOf(life).single;
    expect(pet.role, 'Hamster');
    final hug = interactions.firstWhere((i) => i.id == 'hug');
    final walk = interactions.firstWhere((i) => i.id == 'pet_walk');
    expect(hug.appliesTo(pet), isFalse);
    expect(walk.appliesTo(pet), isTrue);
    expect(walk.appliesTo(life.npc('mother') ?? life.npcs.first), isFalse);
    for (var y = 0; y < 6 && pet.alive; y++) {
      life.age++;
      petsYear(life, Random(y));
    }
    expect(pet.alive, isFalse);
    expect(life.flags.keys.any((k) => k.startsWith('pet_memorial_')), isTrue);
    expect(exoticWarning(life, speciesById('monkey')), contains('Illegal'));
    expect(farmLock(life, speciesById('goat')), isNotNull);
    expect(farmLock(life, speciesById('horse')), isNull);
    expect(petCosts(life), 0);
  });

  // ---------------- Wave F3: titles, achievements, goals, challenges ----------------

  test('Life Titles are scored: main, minor and almost', () {
    final life = engine.newLife(seed: 140)..age = 100;
    life.alive = false;
    life.stats.values['karma'] = 60;
    expect(titleFor(life).name, 'The Centenarian');
    expect(minorTitles(life).map((t) => t.id), contains('survivor'));
    final (almost, progress) = almostTitle(life)!;
    expect(progress, inInclusiveRange(0.6, 0.99));
    expect(almost.test(life), isFalse);
    final young = engine.newLife(seed: 141)..age = 20;
    expect(titleFor(young).id, 'quiet');
  });

  test('achievements and collections are earned once, across lives', () {
    final p = Profile();
    final life = engine.newLife(seed: 142)..age = 25;
    startCareer(life, careerById('office')!);
    final first = checkMeta(life, p);
    expect(first, isNotEmpty);
    expect(p.achievements, contains('first_job'));
    expect(p.sparks, greaterThan(0));
    expect(checkMeta(life, p), isEmpty);
    expect(p.collections['careers'], contains(life.job));
    expect(p.collections['countries'], contains(life.country));
    life.alive = false;
    life.causeOfDeath = 'Natural causes';
    recordLifeEnd(life, p);
    recordLifeEnd(life, p);
    expect(p.collections['titles']!.length, greaterThanOrEqualTo(1));
    expect(p.collections['causes'], ['Natural causes']);
  });

  test('daily goals pay Sparks and streaks forgive one missed day a week', () {
    final p = Profile();
    final day = DateTime(2026, 11, 2);
    for (final g in goalsFor(day)) {
      for (var i = 0; i < g.need; i++) {
        trackGoal(p, g.events.first, day);
      }
    }
    expect(p.sparks, 3 * 20 + 50);
    expect(p.dailyBonusDays, 1);
    expect(recordPlayDay(p, day), isNull);
    expect(p.streak, 1);
    recordPlayDay(p, DateTime(2026, 11, 3));
    expect(p.streak, 2);
    expect(recordPlayDay(p, DateTime(2026, 11, 5)), contains('freeze'));
    expect(p.streak, 3);
    recordPlayDay(p, DateTime(2026, 11, 7));
    expect(p.streak, 1);
  });

  test('weekly challenges are fixed per week and pay out once', () {
    final week = currentWeek(DateTime(2026, 11, 4));
    expect(
      challengeFor(week).map((t) => t.id),
      challengeFor(week).map((t) => t.id),
    );
    expect(challengeFor(week).length, 4);
    expect(archiveWeeks(DateTime(2026, 11, 4)).length, 8);
    final life = engine.newLife(seed: 143);
    life.flags.addAll({
      'married': Memory(30, 'm'),
      'emigrated': Memory(30, 'e'),
      'grandparent': Memory(60, 'g'),
      'marathon': Memory(30, 'r'),
      'acquitted': Memory(30, 'a'),
      'good_neighbour': Memory(30, 'n'),
      'garden_volunteer': Memory(30, 'v'),
    });
    life.age = 95;
    life.alive = false;
    life.stats.values['karma'] = 90;
    // A week whose four tasks this life has all done.
    final fit = [
      for (var i = 0; i < 400; i++)
        currentWeek(DateTime(2026, 1, 5).add(Duration(days: 7 * i))),
    ].firstWhere((w) => challengeFor(w).every((t) => t.test(life)));
    final p = Profile()..activeWeek = fit;
    final out = trackChallenge(p, life, DateTime(2026, 11, 4));
    expect(out.join(), contains('Challenge complete'));
    expect(p.sparks, 100);
    expect(p.collections['challenges'], [challengeName(fit)]);
    expect(trackChallenge(p, life, DateTime(2026, 11, 4)), isEmpty);
  });

  // ---------------- Wave G1: heists, lawsuits and riots ----------------

  test('heists show their windows and end with an after-action report', () {
    final life = engine.newLife(seed: 150)..age = 30;
    life.money = 10000;
    final train = heistById('train');
    life.age = 30;
    final locked = heistWindowLock(life, train);
    expect(locked == null, life.year % 2 == 0);
    if (locked != null) expect(locked, contains('next window'));
    for (var i = 0; i < 6; i++) {
      life.sceneQueue.add('heist_go:jewellers:pros:10');
      final scene = engine.nextScene(life)!;
      final before = life.money;
      final out = engine.choose(life, scene, scene.choices.first);
      expect(out.text, contains('After-action report'));
      expect(out.text, contains('Entry'));
      expect(
        life.money > before ||
            life.sceneQueue.any((s) => s.startsWith('arrest')) ||
            life.cases.isNotEmpty,
        isTrue,
      );
      life.sceneQueue.clear();
      life.lastSeen.clear();
      life.age++;
    }
  });

  test('lawsuits need a grievance, settle in rounds and leave grudges', () {
    final life = engine.newLife(seed: 151)..age = 35;
    life.money = 50000;
    expect(grievances(life), isEmpty);
    final friend = Npc(
      id: 'pal',
      role: 'Friend',
      name: 'Sam Lee',
      birthYear: life.year - 35,
      circle: 'Friends',
      bond: 70,
    );
    friend.debt = 3000;
    life.npcs.add(friend);
    expect(grievances(life).single.id, 'debt:pal');
    life.sceneQueue.add('sue_lawyer:debt:pal');
    var scene = engine.nextScene(life)!;
    engine.choose(life, scene, scene.choices[1]);
    scene = engine.nextScene(life)!;
    expect(scene.text, contains('settle'));
    final before = life.money;
    engine.choose(life, scene, scene.choices.first);
    expect(life.money, greaterThan(before));
    expect(friend.debt, 0);
    expect(life.marks.any((m) => m.startsWith('grudge:pal')), isTrue);
    var struck = false;
    for (var i = 0; i < 40 && !struck; i++) {
      final feed = lawYear(life, Random(i));
      struck = feed.isNotEmpty;
    }
    expect(struck, isTrue);
  });

  test('a prison riot is a decision with explained odds', () {
    final life = engine.newLife(seed: 152)..age = 30;
    life.prison = Prison(crime: 'burglary', years: 4, since: 29);
    life.sceneQueue.add('riot');
    final scene = engine.nextScene(life)!;
    expect(scene.choices.length, 4);
    final out = engine.choose(life, scene, scene.choices.last);
    expect(out.text, contains('invisible'));
  });

  // ---------------- Wave G2: funerals and the Life Recap ----------------

  test('a funeral follows your wishes, your people and your grudges', () {
    final life = engine.newLife(seed: 160)..age = 70;
    final friend = Npc(
      id: 'pal',
      role: 'Friend',
      name: 'Sam Lee',
      birthYear: life.year - 70,
      circle: 'Friends',
      bond: 90,
    );
    friend.remember(
      NpcMemory(
        age: 30,
        text: 'you trusting them with a secret',
        valence: 3,
        intensity: 4,
      ),
    );
    final rival = Npc(
      id: 'riv',
      role: 'Neighbour',
      name: 'Kim Park',
      birthYear: life.year - 70,
      circle: 'Friends',
      bond: 10,
    )..resentment = 60;
    life.npcs.addAll([friend, rival]);
    life.sceneQueue.add('funeral_wish');
    final scene = engine.nextScene(life)!;
    expect(scene.choices.length, funeralTypes.length);
    engine.choose(life, scene, scene.choices[3]);
    final f = funeralFor(life);
    expect(f.type, 'sea');
    expect(f.speaker, isNotNull);
    expect(f.attendance, greaterThanOrEqualTo(1));
    expect(
      f.eulogy.any((e) => e.contains('Sam') && e.contains('trusting me')),
      isTrue,
    );
    expect(f.absent, contains('Kim'));
    expect(allActions.any((a) => a.id == 'plan_funeral'), isTrue);
  });

  test('archetype and Chaos Index read the shape of a life', () {
    final calm = engine.newLife(seed: 161)..age = 60;
    expect(chaosIndex(calm), lessThan(30));
    final wild = engine.newLife(seed: 162)..age = 60;
    for (final f in [
      'arrested',
      'prison',
      'divorced',
      'bankrupt',
      'heist',
      'escaped',
      'emigrated',
    ]) {
      wild.flags[f] = Memory(30, 'doing something dramatic');
    }
    wild.stats.values['impulsivity'] = 90;
    expect(chaosIndex(wild), greaterThan(chaosIndex(calm)));
    expect(riskScore(wild), greaterThan(riskScore(calm)));
    expect(archetypeOf(wild), isNotEmpty);
    final p = Profile();
    calm.alive = false;
    recordLifeEnd(calm, p);
    wild.alive = false;
    recordLifeEnd(wild, p);
    expect(p.chaosHistory.length, 2);
    expect(pastChaosOf(wild), [chaosIndex(calm)]);
    final chaos = recapCards(
      wild,
      pastChaos: pastChaosOf(wild),
    ).firstWhere((c) => c.kind == 'chaos');
    expect(chaos.body, contains('100%'));
    final back = Profile.fromJson(jsonDecode(jsonEncode(p.toJson())));
    expect(back.chaosHistory, p.chaosHistory);
  });

  test('recap cards respect the privacy toggles', () {
    final life = engine.newLife(seed: 163)..age = 50;
    life.money = 123456;
    life.flags['heist'] = Memory(40, 'the jewellers job');
    life.alive = false;
    life.causeOfDeath = 'a heart attack';
    final open = recapCards(life);
    final all = open.map((c) => '${c.big} ${c.body}').join(' ');
    expect(all, contains('123,456'));
    expect(all, contains('heist'));
    expect(all, contains('a heart attack'));
    final parent = life.npcs.firstWhere((n) => n.role == 'Mother');
    expect(all, contains(parent.name.split(' ').first));
    final safe = recapCards(
      life,
      hide: (names: true, crimes: true, money: true, cause: true),
    );
    final hidden = safe.map((c) => '${c.title} ${c.big} ${c.body}').join(' ');
    expect(hidden, isNot(contains('123,456')));
    expect(hidden, isNot(contains('heist')));
    expect(hidden, isNot(contains('a heart attack')));
    expect(hidden, isNot(contains(parent.name.split(' ').first)));
    expect(safe.map((c) => c.kind), containsAll(['archetype', 'chaos']));
    expect(
      recapText(life, safe, names: false),
      isNot(contains(life.firstName)),
    );
  });

  test('the Dynasty Recap lists every generation', () {
    final life = engine.newLife(seed: 164)..age = 40;
    life.lineage.add({
      'name': 'Ada Stone',
      'born': 1950,
      'died': 2030,
      'title': 'The Quiet Saint',
      'job': 'Nurse',
    });
    life.generation = 2;
    final lines = dynastyLines(life);
    expect(lines.length, 2);
    expect(lines.first, contains('Ada Stone'));
    expect(lines.last, contains('Generation 2'));
  });

  // ---------------- Wave G3: possessions ----------------

  Asset house(Life l, {int value = 300000}) => Asset(
    id: 'house_test',
    kind: 'house',
    name: 'Terraced house',
    value: value,
    yearlyCost: 3000,
    since: l.age,
    info: {'bedrooms': 3},
  );

  test('heirlooms pass down with their owners and stay out of the estate', () {
    final old = engine.newLife(seed: 170)..age = 75;
    old.assets
      ..clear()
      ..add(
        makeHeirloom(old, heirloomById('pocket_watch')!, ['Great-grandpa']),
      );
    old.money = 100000;
    old.savings = 0;
    old.invested = 0;
    final child = newChild(old, Random(3), ageNow: 40);
    old.npcs.add(child);
    old.npcs.add(newChild(old, Random(4), ageNow: 38));
    expect(estateOf(old), 100000);
    final heir = heirLife(old, child);
    final watch = heir.assets.singleWhere((a) => a.kind == 'heirloom');
    expect(heirloomHistory(watch), ['Great-grandpa', contains(old.fullName)]);
    expect(heir.feed.any((f) => f.text.contains('pocket watch')), isTrue);
    final sibling = heir.npcs.firstWhere(
      (n) => n.circle == 'Family' && n.alive,
    );
    final before = sibling.bond;
    final r = sellAsset(heir, watch);
    expect(r.text, contains('pocket watch'));
    expect(heir.flags.containsKey('sold_heirloom'), isTrue);
    expect(sibling.bond, lessThan(before));
  });

  test('collectibles follow trends, and fakes are found by an expert', () {
    expect(
      collectibleTrend('sneakers', 2040),
      collectibleTrend('sneakers', 2040),
    );
    final trends = [
      for (var y = 2000; y < 2100; y++) collectibleTrend('cards', y),
    ];
    expect(trends.any((t) => t >= 30), isTrue);
    expect(trends.any((t) => t <= -20), isTrue);
    final life = engine.newLife(seed: 171)..age = 30;
    life.money = 100000;
    life.sceneQueue.add('collect_market');
    final scene = engine.nextScene(life)!;
    expect(scene.choices.length, 4);
    engine.choose(life, scene, scene.choices.first);
    final item = life.assets.singleWhere((a) => a.kind == 'collectible');
    item.info['fake'] = true;
    item.info['checked'] = false;
    item.value = 2000;
    final r = appraiseCollection(life);
    expect(r.text, contains('fake'));
    expect(item.value, 100);
    expect(collectibleSale(item).$1, 100);
  });

  test('boats and planes need licences and cost upkeep', () {
    final life = engine.newLife(seed: 172)..age = 30;
    life.money = 400000;
    final buyBoat = allActions.firstWhere((a) => a.id == 'buy_boat');
    expect(buyBoat.lockReason(life), 'Needs a boat licence');
    life.flags['boat_licence'] = Memory(29, 'boat licence');
    expect(buyBoat.lockReason(life), isNull);
    life.sceneQueue.add('boat_dealer');
    final scene = engine.nextScene(life)!;
    engine.choose(
      life,
      scene,
      scene.choices.firstWhere((c) => c.label.startsWith('Speedboat')),
    );
    final boat = life.assets.singleWhere((a) => a.kind == 'boat');
    expect(boat.yearlyCost, 3000);
    expect(
      allActions.firstWhere((a) => a.id == 'buy_plane').lockReason(life),
      'Needs a pilot licence',
    );
    expect(
      allActions.firstWhere((a) => a.id == 'go_sailing').lockReason(life),
      isNull,
    );
  });

  test('home upgrades change life and how many guests you can host', () {
    final life = engine.newLife(seed: 173)..age = 35;
    life.money = 200000;
    final h = house(life);
    life.assets.add(h);
    final room = hostingCapacity(life);
    life.sceneQueue.add('home_upgrade');
    final scene = engine.nextScene(life)!;
    engine.choose(
      life,
      scene,
      scene.choices.firstWhere((c) => c.label.startsWith('Games room')),
    );
    expect(roomsOf(h), ['games']);
    expect(hostingCapacity(life), room + 6);
    expect(h.value, greaterThan(300000));
    final happy = life.stats['happiness'];
    possessionsYear(life, Random(1));
    expect(life.stats['happiness'], greaterThanOrEqualTo(min(100, happy)));
  });

  test('disasters strike homes, and insurance covers all but the excess', () {
    final life = engine.newLife(seed: 174, countryName: 'Japan')..age = 40;
    life.money = 50000;
    final h = house(life);
    life.assets.add(h);
    final insure = allActions.firstWhere((a) => a.id == 'home_insurance');
    insure.run(life, Random(1));
    expect(insured(h), isTrue);
    final premium = homeInsuranceCost(life);
    expect(premium, greaterThan(300));
    var hit = false;
    for (var i = 0; i < 300 && !hit; i++) {
      possessionsYear(life, Random(i));
      hit = life.sceneQueue.any((q) => q.startsWith('disaster:'));
    }
    expect(hit, isTrue);
    final scene = engine.nextScene(life)!;
    expect(scene.text, contains('insured'));
    final before = life.money;
    engine.choose(life, scene, scene.choices.first);
    expect(life.money, before - insuranceExcess);
    expect(h.condition, greaterThanOrEqualTo(90));
    expect(premiumFor(life, h), greaterThan(premium));
    life.sceneQueue.clear();
    life.lastYear = [];
    yearlyMoney(life, Random(2));
    expect(life.lastYear.any((l) => l.$1 == 'Home insurance'), isTrue);
  });

  // ---------------- Wave G4: family and seasons ----------------

  test('fostering: a placement, an allowance, then goodbye or adoption', () {
    final life = engine.newLife(seed: 180)..age = 35;
    expect(fosterLock(life), 'Needs a home of your own');
    life.assets.add(house(life));
    expect(fosterLock(life), isNull);
    life.sceneQueue.add('foster_offer');
    final offer = engine.nextScene(life)!;
    expect(offer.text, contains('social worker'));
    engine.choose(life, offer, offer.choices.first);
    final f = fostersOf(life).single;
    expect(life.flags.containsKey('foster_carer'), isTrue);
    life.lastYear = [];
    yearlyMoney(life, Random(1));
    expect(
      life.lastYear.firstWhere((l) => l.$1 == 'Fostering allowance').$2,
      fosterAllowance,
    );
    // Find a placement that ends in adoption.
    var adopted = false;
    for (var age = 36; age < 80 && !adopted; age++) {
      life.age = age;
      final end = fosterEndScene([f.id], life)!;
      if (end.choices.length == 2) {
        engine.choose(life, end, end.choices.first);
        adopted = true;
      }
    }
    expect(adopted, isTrue);
    expect(f.circle, 'Children');
    expect(f.info['stats'], isA<Map>());
    expect(childrenOf(life), contains(f));
  });

  test('surrogacy follows the country and leads to a birth', () {
    expect(surrogacyRule('United States'), 'commercial');
    expect(surrogacyRule('United Kingdom'), 'altruistic');
    expect(surrogacyRule('Germany'), 'unavailable');
    final life = engine.newLife(seed: 181, countryName: 'Germany')..age = 34;
    life.money = 500000;
    life.sceneQueue.add('surrogacy');
    final scene = engine.nextScene(life)!;
    expect(scene.text, contains('not available'));
    expect(scene.choices.first.label, contains('abroad'));
    var expecting = false;
    for (var i = 0; i < 10 && !expecting; i++) {
      scene.choices.first.run!(life, Random(i));
      expecting = life.flags.containsKey('expecting');
    }
    expect(expecting, isTrue);
  });

  test('grandchildren arrive as people and grow up', () {
    final life = engine.newLife(seed: 182)..age = 58;
    final child = newChild(life, Random(2), ageNow: 30);
    life.npcs.add(child);
    life.flags['grandparent'] = Memory(57, 'becoming a grandparent');
    final feed = grandchildrenYear(life, Random(3));
    final g = grandchildrenOf(life).single;
    expect(g.info['parent'], child.id);
    expect(feed.single.text, contains('grandparent'));
    expect(life.who('@grandchild'), g);
    expect(engine.fill('{grandchild}', life), g.name.split(' ').first);
    final babysit = allActions.firstWhere((a) => a.id == 'babysit');
    expect(babysit.lockReason(life), isNull);
    final before = g.bond;
    babysit.run(life, Random(1));
    expect(g.bond, greaterThan(before));
  });

  test('seasons follow the real calendar, once per season per life', () {
    expect(seasonOn(DateTime(2026, 10, 31))?.id, 'halloween');
    expect(seasonOn(DateTime(2027, 1, 2))?.id, 'new_year');
    expect(seasonOn(DateTime(2026, 12, 30))?.id, 'new_year');
    expect(seasonOn(DateTime(2026, 8, 1)), isNull);
    final pumpkin = allActions.firstWhere((a) => a.id == 'carve_pumpkin');
    final life = engine.newLife(seed: 183)..age = 10;
    life.money = 100;
    expect(pumpkin.lockReason(life), contains('Halloween'));
    seasonClock = () => DateTime(2026, 10, 31);
    try {
      expect(pumpkin.lockReason(life), isNull);
      var queued = false;
      for (var i = 0; i < 20 && !queued; i++) {
        seasonalYear(life, Random(i));
        queued = life.sceneQueue.contains('season:halloween');
      }
      expect(queued, isTrue);
      final scene = engine.nextScene(life)!;
      expect(scene.text, contains('Halloween'));
      for (var i = 0; i < 20; i++) {
        seasonalYear(life, Random(i));
      }
      expect(life.sceneQueue, isEmpty);
      for (final s in seasons) {
        seasonClock = () => DateTime(2026, s.from ~/ 100, s.from % 100);
        for (final age in [8, 30, 70]) {
          life.age = age;
          expect(seasonScene(s.id, life)?.choices, isNotEmpty, reason: s.id);
        }
      }
    } finally {
      seasonClock = () => DateTime(2026, 8, 1);
    }
  });

  // ---------------- Shopping ----------------

  test('shop prices follow deals and real-date sales', () {
    final quiet = DateTime(2026, 8, 1);
    final friday = DateTime(2026, 11, 27);
    expect(saleOn(quiet), isNull);
    expect(saleOn(friday)!.$1, 'Black Friday');
    expect(dealsOn(quiet), dealsOn(DateTime(2026, 8, 1)));
    expect(dealsOn(quiet).length, 3);
    final life = engine.newLife(seed: 190)..age = 30;
    life.economy = 'Normal';
    final laptop = itemById('laptop')!;
    final full = priceOf(life, laptop, quiet);
    if (!dealsOn(quiet).containsKey('laptop')) {
      expect(full, laptop.price);
    }
    expect(priceOf(life, laptop, friday), lessThan(laptop.price));
  });

  test('buying: cash, card and pay in 3, with lasting effects', () {
    final quiet = DateTime(2026, 8, 1);
    final life = engine.newLife(seed: 191)..age = 30;
    life.money = 5000;
    final laptop = itemById('laptop')!;
    final price = priceOf(life, laptop, quiet);
    buyItem(life, laptop, now: quiet);
    expect(life.money, 5000 - price);
    expect(life.items.single['id'], 'laptop');
    final smarts = life.stats['smarts'];
    shoppingYear(life, Random(99));
    expect(life.stats['smarts'], min(100, smarts + 1));
    expect(life.items.single['left'], laptop.years - 1);
    // Card
    final sofa = itemById('sofa')!;
    buyItem(life, sofa, pay: 'card', now: quiet);
    expect(life.debts['Credit card'], priceOf(life, sofa, quiet));
    // Pay in 3: a third now, the rest due in full next birthday at 0%.
    final bike = itemById('bike')!;
    final before = life.money;
    final p = priceOf(life, bike, quiet);
    expect(payLock(life, 'later', p), isNull);
    buyItem(life, bike, pay: 'later', now: quiet);
    expect(life.money, before - (p / 3).ceil());
    expect(life.debts[payLaterDebt], p - (p / 3).ceil());
    expect(rateOf(life, payLaterDebt), 0);
    // Under 18: cash only.
    final kid = engine.newLife(seed: 192)..age = 14;
    expect(payLock(kid, 'card', 100), 'Cards open at 18');
  });

  test('gifts land better when they match the person', () {
    final quiet = DateTime(2026, 8, 1);
    final life = engine.newLife(seed: 193)..age = 40;
    life.money = 1000;
    final mum = life.who('@parent')!;
    expect(tasteOf(life, mum), anyOf('adult', 'elder'));
    final toy = itemById('toy')!;
    final album = itemById('album')!;
    expect(loves(life, mum, album), isTrue);
    expect(loves(life, mum, toy), isFalse);
    mum.affection = 40;
    final a0 = mum.affection;
    buyItem(life, toy, giftFor: mum, now: quiet);
    final meh = mum.affection - a0;
    final a1 = mum.affection;
    final r = buyItem(life, album, giftFor: mum, now: quiet);
    expect(mum.affection - a1, greaterThan(meh));
    expect(r.notes.last, contains('they love this'));
    expect(mum.memories.any((m) => m.text.contains('photo album')), isTrue);
  });

  test('returns, resale, luxury valuables and subscriptions', () {
    final quiet = DateTime(2026, 8, 1);
    final life = engine.newLife(seed: 194)..age = 30;
    life.money = 20000;
    buyItem(life, itemById('console')!, now: quiet, rng: Random(1));
    final item = life.items.single;
    expect(returnLock(life, item), isNull);
    final m = life.money;
    returnItem(life, item);
    expect(life.money, m + ((item['paid'] as int) * 0.9).round());
    buyItem(life, itemById('guitar')!, now: quiet);
    life.age++;
    expect(returnLock(life, life.items.single), isNotNull);
    expect(resaleOf(life.items.single), greaterThan(0));
    sellItem(life, life.items.single);
    expect(life.items, isEmpty);
    buyItem(life, itemById('watch')!, now: quiet);
    expect(
      life.assets.any((a) => a.kind == 'valuable' && a.name == 'Luxury watch'),
      isTrue,
    );
    final gym = subById('gym')!;
    subscribe(life, gym);
    expect(subscriptionCost(life), gym.yearly);
    life.lastYear = [];
    yearlyMoney(life, Random(3));
    expect(
      life.lastYear.firstWhere((l) => l.$1 == 'Subscriptions').$2,
      -gym.yearly,
    );
    unsubscribe(life, gym);
    expect(life.subs, isEmpty);
    final copy = Life.fromJson(jsonDecode(jsonEncode(life.toJson())));
    expect(copy.toJson(), life.toJson());
  });

  // ---------------- More control ----------------

  test('activities offer ways to do them, and who to bring', () {
    final life = engine.newLife(seed: 200)..age = 30;
    life.money = 10000;
    final gym = allActions.firstWhere((a) => a.id == 'gym');
    expect(variantsFor('gym').map((v) => v.id), contains('hard'));
    final buddy = variantsFor('gym').firstWhere((v) => v.withPerson);
    final friend = life.who('@parent')!;
    final before = friend.bond;
    final r = engine.runAction(life, gym, variant: buddy, who: friend);
    expect(friend.bond, greaterThan(before));
    expect(r.notes.any((n) => n.startsWith('Bond with')), isTrue);
    final trip = allActions.firstWhere((a) => a.id == 'vacation');
    final beach = variantsFor('vacation').first;
    life.money = 100;
    expect(beach.lockReason(life), contains('Needs'));
    life.money = 5000;
    engine.runAction(life, trip, variant: beach);
    expect(life.money, 2000);
    // Going all out can strain something; the odds show before choosing.
    final hard = variantsFor('gym').firstWhere((v) => v.id == 'hard');
    expect(hard.detail, contains('strain'));
  });

  test('time with people: options they enjoy, and fights that follow up', () {
    final life = engine.newLife(seed: 201)..age = 40;
    life.money = 1000;
    final mum = life.who('@parent')!;
    final spend = interactions.firstWhere((i) => i.id == 'spend_time');
    final ways = interactionVariantsFor('spend_time');
    final walk = ways.firstWhere((w) => w.id == 'walk');
    expect(walk.suits(life, mum), isTrue);
    final r = engine.interact(life, mum, spend, variant: walk);
    expect(r.notes, contains('Just their thing'));
    final argue = interactions.firstWhere((i) => i.id == 'argue');
    engine.interact(life, mum, argue);
    expect(life.sceneQueue, contains('reaction:${mum.id}'));
    final scene = engine.nextScene(life)!;
    expect(scene.choices.length, 4);
    final resentment = mum.resentment;
    engine.choose(life, scene, scene.choices.first);
    expect(mum.resentment, lessThan(resentment));
  });

  test('haggling for a car and negotiating a job offer', () {
    final life = engine.newLife(seed: 202)..age = 30;
    life.money = 100000;
    life.sceneQueue.add('car_pay:family');
    var scene = engine.nextScene(life)!;
    expect(scene.choices.first.label, contains('Haggle'));
    engine.choose(life, scene, scene.choices.first);
    scene = engine.nextScene(life)!;
    expect(scene.choices.first.label, isNot(contains('Haggle')));
    final job = careers.firstWhere((c) => c.lockReason(life) == null);
    startCareer(life, job);
    life.sceneQueue.add('job_offer:${job.id}:90');
    scene = engine.nextScene(life)!;
    expect(scene.choices.map((c) => c.label), contains('Ask for 10% more'));
    final pay = life.salary;
    engine.choose(life, scene, scene.choices[1]);
    expect(life.salary, anyOf(pay, (pay * 1.1).round()));
  });

  test('new mini-games: playing well beats playing badly', () {
    for (final id in ['yoga', 'video_games', 'write_story', 'reflect']) {
      final a = allActions.firstWhere((a) => a.id == id);
      expect(a.miniGame, isNotNull, reason: id);
      expect(a.scored, isNotNull, reason: id);
    }
    final story = allActions.firstWhere((a) => a.id == 'write_story');
    final good = engine.newLife(seed: 210)..age = 20;
    final bad = engine.newLife(seed: 210)..age = 20;
    final g0 = good.stats['creativity'], b0 = bad.stats['creativity'];
    engine.runAction(good, story, score: 1);
    engine.runAction(bad, story, score: 0);
    expect(
      good.stats['creativity'] - g0,
      greaterThan(bad.stats['creativity'] - b0),
    );
  });

  // ---------------- Prison gangs ----------------

  Life inmate(int seed) {
    final l = engine.newLife(seed: seed)..age = 30;
    l.prison = Prison(crime: 'burglary', years: 8, since: 29);
    l.money = 5000;
    return l;
  }

  test('joining a gang: pick a crew, pass the initiation, get perks', () {
    final l = inmate(220);
    final join = allActions.firstWhere((a) => a.id == 'join_gang');
    expect(join.lockReason(l), isNull);
    engine.runAction(l, join);
    var scene = engine.nextScene(l)!;
    expect(scene.choices.length, gangs.length + 1);
    engine.choose(l, scene, scene.choices[1]); // the Iron Brotherhood
    scene = engine.nextScene(l)!;
    expect(scene.id, 'scene:gang_initiation');
    final health = l.stats['health'];
    engine.choose(l, scene, scene.choices.first);
    expect(l.prison!.gangId, 'iron');
    expect(l.stats['health'], lessThan(health));
    expect(join.lockReason(l), isNotNull);
    final respect = l.prison!.respect;
    gangYear(l, Random(1));
    expect(l.prison!.respect, greaterThan(respect));
  });

  test('orders, wars, promotion and getting out', () {
    final l = inmate(221);
    l.prison!
      ..gangId = 'owls'
      ..gangStanding = 90
      ..served = 2
      ..rivalry['iron'] = 95;
    final feed = gangYear(l, Random(2));
    expect(l.prison!.gangRank, 1);
    expect(feed.single, contains('Member'));
    expect(l.sceneQueue, contains('gang_war:iron'));
    var scene = engine.nextScene(l)!;
    expect(scene.choices.map((c) => c.label), contains('Broker a truce'));
    engine.choose(l, scene, scene.choices.first);
    expect(l.prison!.rivalry['iron'], 40);
    l.sceneQueue.add('gang_order');
    scene = engine.nextScene(l)!;
    expect(scene.choices.last.label, 'Tell the guards');
    l.sceneQueue.add('gang_leave');
    scene = engine.nextScene(l)!;
    engine.choose(l, scene, scene.choices[1]); // buy your way out
    expect(l.prison!.gangId, isNull);
    expect(l.marks, contains('ex_gang:owls'));
    final back = Life.fromJson(jsonDecode(jsonEncode(l.toJson())));
    expect(back.prison!.rivalry, l.prison!.rivalry);
  });

  test('gang rank weighs on parole and snitches are shut out', () {
    final p = Prison(crime: 'fraud', years: 5, since: 30);
    expect(gangParolePenalty(p), 0);
    p
      ..gangId = 'ledger'
      ..gangRank = 3;
    expect(gangParolePenalty(p), 0.2);
    final l = inmate(222);
    l.prison!.snitch = true;
    l.sceneQueue.add('gang_pick');
    final scene = engine.nextScene(l)!;
    expect(scene.choices.length, 1);
    expect(
      Prison.fromJson({'crime': 'x', 'years': 2, 'since': 1, 'gang': true})
          .gangId,
      'owls',
    );
  });

  // ---------------- Prison life ----------------

  test('a visit lifts a bond, and smuggling fills the stash', () {
    final l = inmate(230);
    final mum = l.who('@parent')!..addFacets(affection: 10);
    final visit = allActions.firstWhere((a) => a.id == 'prison_visit');
    expect(visit.lockReason(l), isNull);
    engine.runAction(l, visit);
    var scene = engine.nextScene(l)!;
    expect(scene.id, 'scene:visit_pick');
    final pick = scene.choices.firstWhere(
      (c) => c.label.startsWith(mum.name.split(' ').first),
    );
    engine.choose(l, scene, pick);
    scene = engine.nextScene(l)!;
    expect(scene.id, 'scene:visit');
    final before = mum.bond;
    engine.choose(l, scene, scene.choices.first);
    expect(mum.bond, greaterThan(before));
    // Smuggling: either the stash grows or the visitor is banned.
    l.sceneQueue.add('visit:${mum.id}');
    scene = engine.nextScene(l)!;
    final smuggle = scene.choices.firstWhere(
      (c) => c.label.contains('smuggle'),
    );
    smuggle.run!(l, Random(5));
    expect(l.prison!.stash > 0 || l.prison!.banned.contains(mum.id), isTrue);
  });

  test('trading in the yard spends the stash', () {
    final l = inmate(231);
    l.prison!.stash = 5;
    final trade = allActions.firstWhere((a) => a.id == 'prison_trade');
    final ways = variantsFor('prison_trade');
    expect(ways.map((v) => v.id), containsAll(['protection', 'call', 'sell']));
    final respect = l.prison!.respect;
    engine.runAction(l, trade, variant: ways.first);
    expect(l.prison!.stash, 2);
    expect(l.prison!.respect, greaterThan(respect));
    final money = l.money;
    final sell = ways.firstWhere((v) => v.id == 'sell');
    sell.run(l, Random(1), null, null);
    expect(l.money, money + 120);
    expect(sell.lockReason(l), isNotNull);
  });

  test('named courses: a trade certificate and a degree', () {
    final l = inmate(232);
    l.education = 'high school graduate';
    l.stats.add('smarts', 100);
    l.sceneQueue.add('prison_course');
    var scene = engine.nextScene(l)!;
    final trade = scene.choices.firstWhere(
      (c) => c.label == 'Trade certificate',
    );
    engine.choose(l, scene, trade);
    expect(l.marks, contains('trade_cert'));
    expect(
      courseLock(l, prisonCourses.firstWhere((c) => c.id == 'trade')),
      'Done',
    );
    for (var i = 0; i < 3; i++) {
      l.sceneQueue.add('prison_course');
      scene = engine.nextScene(l)!;
      engine.choose(
        l,
        scene,
        scene.choices.firstWhere((c) => c.label.startsWith('Degree')),
      );
    }
    expect(l.education, 'graduate');
    expect(l.prison!.courses, contains('degree'));
  });

  test('solitary locks most activities, then ends', () {
    final l = inmate(233);
    l.prison!.solitary = 1;
    final job = allActions.firstWhere((a) => a.id == 'prison_job');
    final exercise = allActions.firstWhere((a) => a.id == 'cell_exercise');
    expect(job.lockReason(l), 'Not possible in solitary');
    expect(exercise.lockReason(l), isNull);
    prisonLifeYear(l, Random(1));
    expect(l.prison!.solitary, 0);
    expect(job.lockReason(l), isNull);
  });

  test('new escape routes, life on the run and recapture', () {
    final l = inmate(234);
    l.prison!.job = 'Kitchen';
    l.sceneQueue.add('escape');
    var scene = engine.nextScene(l)!;
    final labels = scene.choices.map((c) => c.label).toList();
    expect(labels, contains('Hide in a delivery'));
    final crew = scene.choices.firstWhere((c) => c.label.contains('crew'));
    expect(crew.lock!(l), isNotNull);
    engine.choose(
      l,
      scene,
      scene.choices.firstWhere((c) => c.label == 'Hide in a delivery'),
    );
    scene = engine.nextScene(l)!;
    expect(scene.id, 'scene:escape_tool');
    // Force a success, then live as a fugitive until caught.
    final out = inmate(235);
    out.sceneQueue.add('escape_tool:delivery:85');
    scene = engine.nextScene(out)!;
    var seed = 0;
    while (out.prison != null && seed < 50) {
      scene.choices.first.run!(out, Random(seed++));
      if (out.prison != null && out.prison!.solitary > 0) {
        expect(out.prison!.solitary, 1); // a failed try is a year in solitary
        out.prison!.solitary = 0;
      }
    }
    expect(isFugitive(out), isTrue);
    for (var i = 0; i < 40 && isFugitive(out); i++) {
      out.age++;
      prisonLifeYear(out, Random(i));
    }
    expect(isFugitive(out), isFalse);
    expect(out.prison!.security, 'maximum');
  });

  test('parole check-ins, the halfway house and sealing a record', () {
    final l = inmate(236);
    l.prison!.served = 5;
    l.record.add({'crime': 'burglary', 'age': 29, 'band': 'serious'});
    final text = release(l, parole: true);
    expect(text, contains('halfway house'));
    expect(l.assets.any((a) => a.name == 'Halfway house'), isTrue);
    l.sceneQueue.add('parole_checkin');
    final scene = engine.nextScene(l)!;
    final skip = scene.choices.firstWhere((c) => c.label == 'Skip it');
    var seed = 0;
    while (l.prison == null && seed < 40) {
      skip.run!(l, Random(seed++));
    }
    expect(l.prison!.crime, 'parole violation');
    // Years later, crime-free: seal it and the record stops counting.
    l.prison = null;
    l.age = 40;
    final seal = allActions.firstWhere((a) => a.id == 'seal_record');
    expect(seal.lockReason(l), isNull);
    expect(hasSeriousRecord(l), isTrue);
    engine.runAction(l, seal);
    expect(hasSeriousRecord(l), isFalse);
    // The halfway house runs out.
    l.assets.removeWhere((a) => a.name != 'Halfway house');
    prisonLifeYear(l, Random(1));
    expect(l.assets.any((a) => a.name == 'Halfway house'), isFalse);
    final back = Prison.fromJson(
      Prison(crime: 'x', years: 2, since: 1).toJson()
        ..['stash'] = 3
        ..['courses'] = ['ged'],
    );
    expect(back.stash, 3);
    expect(back.courses, ['ged']);
  });

  test('everyday activities can be redone, and help less each time', () {
    final l = engine.newLife(seed: 240)..age = 25;
    l.stats.add('health', -100);
    l.stats.add('health', 20);
    final gym = allActions.firstWhere((a) => a.id == 'gym');
    final gains = <int>[];
    for (var i = 0; i < maxRedo; i++) {
      expect(gym.lockReason(l), isNull, reason: 'try ${i + 1}');
      final h = l.stats['health'];
      engine.runAction(l, gym);
      gains.add(l.stats['health'] - h);
    }
    expect(gym.lockReason(l), contains('times this year'));
    expect(gains.first, greaterThan(gains.last));
    final doctor = allActions.firstWhere((a) => a.id == 'apply_job');
    expect(redoable.contains(doctor.id), isFalse);
    expect(gainFactor(0, 90), lessThan(gainFactor(0, 30)));
  });

  test('a crime is a job: target, approach, twist, and street skill', () {
    final l = engine.newLife(seed: 250)..age = 25;
    final burglary = allActions.firstWhere((a) => a.id == 'burglary');
    engine.runAction(l, burglary);
    var scene = engine.nextScene(l)!;
    expect(scene.id, 'scene:crime_plan');
    expect(scene.choices.length, 4);
    engine.choose(l, scene, scene.choices[2]); // the mansion
    scene = engine.nextScene(l)!;
    expect(scene.id, 'scene:crime_go');
    expect(scene.choices[2].lock!(l), isNotNull); // no lookout yet
    l.sceneQueue.add('crime_twist:burglary:0:100');
    scene = engine.nextScene(l)!;
    expect(scene.choices.first.label, contains('Grab'));
    // Getting away with it raises street skill and leaves a case.
    final before = l.cases.length;
    finishCrime(l, crimeById('burglary'), Random(1), 0, 100);
    expect(crimeSkill(l), 4);
    expect(l.cases.length, before + 1);
    final lie = allActions.firstWhere((a) => a.id == 'lie_low');
    final ev = l.cases.last['evidence'] as int;
    engine.runAction(l, lie);
    expect(l.cases.isEmpty || (l.cases.last['evidence'] as int) < ev, isTrue);
  });

  test('a stolen car can be sold to a chop shop or kept', () {
    final l = engine.newLife(seed: 251)..age = 25;
    l.assets.removeWhere((a) => a.kind == 'car');
    final cash = l.money;
    finishCrime(l, crimeById('car_theft'), Random(1), 0, 100);
    expect(l.money, cash); // nothing paid until you choose
    var scene = engine.nextScene(l)!;
    expect(scene.id, 'scene:crime_car');
    final ev = l.cases.last['evidence'] as int;
    engine.choose(l, scene, scene.choices[1]); // keep it
    final car = l.assets.singleWhere((a) => a.info['stolen'] == true);
    expect(car.kind, 'car');
    expect(car.name, startsWith('Stolen'));
    expect(l.cases.last['evidence'] as int, greaterThan(ev));
    // Selling the next one pays instead.
    finishCrime(l, crimeById('car_theft'), Random(2), 0, 100);
    scene = engine.nextScene(l)!;
    engine.choose(l, scene, scene.choices.first);
    expect(l.money, greaterThan(cash));
    // A car theft conviction takes the stolen car back.
    expect(
      convict(l, crimeById('car_theft'), 0, 'fine'),
      contains('stolen car'),
    );
    expect(l.assets.any((a) => a.info['stolen'] == true), isFalse);
  });

  test('murder: pick someone, they die, and the case never goes cold', () {
    final l = engine.newLife(seed: 252)..age = 30;
    final murder = allActions.firstWhere((a) => a.id == 'murder');
    expect(murder.lockReason(l), isNull);
    engine.runAction(l, murder);
    var scene = engine.nextScene(l)!;
    expect(scene.id, 'scene:murder_pick');
    final victim = murderTargets(l).first;
    engine.choose(l, scene, scene.choices.first);
    scene = engine.nextScene(l)!;
    expect(scene.id, 'scene:murder_how');
    // Getting away with it: the victim dies and a case stays open.
    commitMurder(l, victim, Random(1), 0, 0);
    expect(victim.alive, isFalse);
    final file = l.cases.last;
    expect(file['crime'], 'murder');
    for (var i = 0; i < 20; i++) {
      justiceYear(l, Random(1000 + i)..nextInt(1));
      if (l.cases.isEmpty) break;
    }
    // Either it is still open or the police finally came for you.
    expect(
      l.cases.any((c) => c['crime'] == 'murder') ||
          l.sceneQueue.any((s) => s.startsWith('arrest:murder')),
      isTrue,
    );
    expect(
      sentenceYears(l, crimeById('murder'), 80, Random(1)),
      greaterThanOrEqualTo(10),
    );
  });

  test('the player never sees the odds, only prices and rates', () {
    expect(hideOdds('Smarts help · risk about 40%'), 'Smarts help');
    expect(hideOdds('About 62% to win at trial'), 'A chance to win at trial');
    expect(
      hideOdds('The car had a tracker. (Risk was 40%.)'),
      'The car had a tracker.',
    );
    expect(
      hideOdds('Guilty. Conviction chance was 62%: your record.'),
      'Guilty.',
    );
    expect(
      hideOdds('You left evidence behind: 45/100. Done.'),
      'You left evidence behind. Done.',
    );
    expect(hideOdds('Why: 10% restocking fee'), 'Why: 10% restocking fee');
    expect(hideOdds('Saved \$20 (25% off)'), 'Saved \$20 (25% off)');
    expect(
      hideOdds('Bond 60% · Ask about their day'),
      'Bond 60% · Ask about their day',
    );
    // Every choice and crime hint in the game comes out clean.
    final l = engine.newLife(seed: 253)..age = 30;
    for (final a in allActions.where((a) => a.category == 'Crime')) {
      expect(a.hintFor(l) ?? '', isNot(contains('%')), reason: a.id);
    }
    expect(Choice(label: 'x', outcome: '', risk: '40%').risk, isNull);
  });

  test('the news reaches your life: pay, homes and a choice', () {
    final l = engine.newLife(seed: 254)..age = 35;
    l.job = 'Accountant';
    l.salary = 50000;
    WorldStory story(String effect) => WorldStory(
      year: l.year,
      category: 'economy',
      headline: effect,
      body: '',
      effect: effect,
    );
    // A recession puts your job on the line.
    final feed = newsYear(l, [story('hiring_down')], Random(1));
    expect(feed, isEmpty);
    expect(l.sceneQueue.last, 'news_hit:hiring_down');
    final scene = engine.nextScene(
      l..sceneQueue.removeRange(0, l.sceneQueue.length - 1),
    )!;
    expect(scene.id, 'scene:news_hit');
    engine.choose(l, scene, scene.choices.first); // take the pay cut
    expect(l.salary, 45000);
    // A boom raises pay; a tax cut pays a rebate.
    final cash = l.money;
    newsYear(l, [story('hiring_up'), story('tax_cut')], Random(1));
    expect(l.salary, greaterThan(45000));
    expect(l.money, greaterThan(cash));
    // Inflation makes living cost more.
    final before = livingCost(l);
    l.worldMods = {'prices': 15};
    expect(livingCost(l), greaterThan(before));
  });

  test('friends you make join People', () {
    final l = engine.newLife(seed: 255)..age = 20;
    l.stats.values['charisma'] = 100;
    final before = l.npcs.where((n) => n.circle == 'Friends').length;
    final make = allActions.firstWhere((a) => a.id == 'make_friend');
    for (var i = 0; i < 3; i++) {
      engine.runAction(l, make);
    }
    expect(
      l.npcs.where((n) => n.circle == 'Friends').length,
      greaterThan(before),
    );
    // A storylet can add a new, named friend without a fixed name.
    final e = Effects(
      addNpcs: [
        {'role': 'Neighbour', 'count': 2},
      ],
    );
    final n = l.npcs.length;
    final notes = e.apply(l);
    expect(l.npcs.length, n + 2);
    expect(l.npcs.last.circle, 'Friends');
    expect(l.npcs.last.name, contains(' '));
    expect(notes.where((x) => x.contains('joined your friends')).length, 2);
    // Test scores still show; only odds are hidden.
    expect(hideOdds('You scored 72/100.'), 'You scored 72/100.');
  });

  test('the news does not repeat itself year after year', () {
    final w = World(seed: 77);
    final c = countries.first;
    final city = c.cities.first;
    for (var y = 2026; y < 2086; y++) {
      w.ensureYear(y, c.name, city);
    }
    for (final scope in ['global', c.name, city]) {
      final seen = <String, int>{};
      for (var y = 2026; y < 2086; y++) {
        for (final s in w.stories[y]!.where(
          (s) => s.scope == scope && s.category != 'economy',
        )) {
          final last = seen[s.template!];
          if (last != null) {
            expect(y - last, greaterThanOrEqualTo(5), reason: s.headline);
          }
          seen[s.template!] = y;
        }
      }
    }
    // A run of the same economy never prints the same story two years in a row.
    for (var y = 2027; y < 2086; y++) {
      final a = w.stories[y - 1]!.firstWhere((s) => s.category == 'economy');
      final b = w.stories[y]!.firstWhere((s) => s.category == 'economy');
      if (w.economyFor(y) == w.economyFor(y - 1) &&
          (const {
            'Boom',
            'Normal',
            'Recession',
            'Slowdown',
          }.contains(w.economyFor(y)))) {
        expect(b.headline, isNot(a.headline), reason: '$y');
      }
    }
  });

  test('every shop department has plenty to choose from', () {
    final ids = catalogue.map((i) => i.id).toList();
    expect(ids.toSet().length, ids.length);
    for (final d in departments.keys.where((d) => d != 'subs')) {
      final n = catalogue.where((i) => i.dept == d).length;
      expect(n, greaterThanOrEqualTo(10), reason: d);
    }
    expect(subscriptions.length, greaterThanOrEqualTo(15));
    // Something for every budget in the everyday departments.
    for (final d in ['clothes', 'tech', 'home', 'books', 'sport', 'beauty']) {
      final prices = catalogue.where((i) => i.dept == d).map((i) => i.price);
      expect(prices.any((p) => p < 100), isTrue, reason: d);
      expect(prices.any((p) => p >= 500), isTrue, reason: d);
    }
  });

  test('landlords: several rentals, tenants you choose, rent levels', () {
    final l = engine.newLife(seed: 256)..age = 35;
    l.money = 5000000;
    final homes = listings(l);
    buyListing(l, homes[0], homes[0].price); // a home to live in
    expect(homeOf(l), isNotNull);
    // Buy three homes to let.
    for (var k = 1; k <= 3; k++) {
      l.marks.add('hunt:${l.age}:let');
      buyListing(l, homes[k], homes[k].price);
    }
    expect(lettingsOf(l).length, 3);
    final a = lettingsOf(l).first;
    expect(isVacant(a), isTrue);
    // No pop-up after buying: you find tenants when you choose to.
    expect(l.sceneQueue.any((k) => k.startsWith('let_pick')), isFalse);
    // An empty year only leaves a reminder in the feed.
    final empty = propertyYear(l, Random(9));
    expect(empty.where((x) => x.contains('still empty')).length, 3);
    expect(l.sceneQueue.any((k) => k.startsWith('let_pick')), isFalse);
    expect(rentIncome(l, a), 0);
    // Choose a tenant from the applicants.
    l.sceneQueue
      ..clear()
      ..add('let_pick:${a.id}');
    var scene = engine.nextScene(l)!;
    expect(scene.choices.length, 5); // three applicants, an agent, leave empty
    engine.choose(l, scene, scene.choices.first);
    expect(isVacant(a), isFalse);
    expect(rentIncome(l, a), greaterThan(0));
    // Raising the rent raises the income.
    final before = rentFor(a);
    a.info['rentLevel'] = 'high';
    expect(rentFor(a), greaterThan(before));
    // A year as a landlord runs without errors and may need decisions.
    l.age++;
    propertyYear(l, Random(3));
    expect(lettingsOf(l).length, 3);
  });

  test('moving house: sell or let the old one; remortgage', () {
    final l = engine.newLife(seed: 257)..age = 35;
    l.job = 'Engineer';
    l.salary = 60000;
    final homes = listings(l);
    l.money = (homes[0].price * 0.4).round();
    buyListing(l, homes[0], homes[0].price);
    final first = homeOf(l)!;
    expect(l.debts['Mortgage'], greaterThan(0));
    // Equity release: borrow against the home.
    l.sceneQueue
      ..clear()
      ..add('remortgage');
    final re = engine.nextScene(l);
    expect(re, isNotNull);
    // Move to a new home; the old one becomes a rental until you decide.
    l.money = 5000000;
    l.marks.add('hunt:${l.age}:move');
    l.sceneQueue.clear();
    buyListing(l, homes[1], homes[1].price);
    expect(homeOf(l), isNot(first));
    expect(l.sceneQueue.first, 'old_home:${first.id}');
    final scene = engine.nextScene(l)!;
    final cash = l.money;
    engine.choose(l, scene, scene.choices.first); // sell it
    expect(l.assets.contains(first), isFalse);
    expect(l.money, greaterThan(cash));
    expect(l.debts.containsKey('Buy-to-let mortgage'), isFalse);
  });

  test('renting: six places, flatmates join People, deposits', () {
    final l = engine.newLife(seed: 258)..age = 22;
    l.money = 20000;
    final places = rentalListings(l);
    expect(places.length, 6);
    expect(places.any((p) => p.rent <= 8000), isTrue);
    final shared = places.where((p) => p.shared).firstOrNull;
    final friends = l.npcs.where((n) => n.role == 'Flatmate').length;
    if (shared != null) {
      rentFlat(l, shared, Random(1));
      expect(l.npcs.where((n) => n.role == 'Flatmate').length, friends + 2);
    } else {
      rentFlat(l, places.first, Random(1));
    }
    expect(l.has('rental'), isTrue);
    // Moving to another place returns the deposit (maybe less deductions).
    final cash = l.money;
    rentFlat(l, places.last, Random(2));
    expect(l.assets.where((a) => a.kind == 'rental').length, 1);
    expect(l.money, isNot(cash));
  });

  test('fame: tiers, public image, fame activities and celebrity life', () {
    final l = engine.newLife(seed: 259)..age = 30;
    expect(fameTierOf(l).name, 'Unknown');
    final talk = allActions.firstWhere((a) => a.id == 'talk_show');
    expect(talk.lockReason(l), isNotNull);
    l.fame = 50;
    expect(fameTierOf(l).name, 'Celebrity');
    expect(talk.lockReason(l), isNull);
    final cash = l.money;
    engine.runAction(l, talk);
    expect(l.money, greaterThan(cash));
    // Image is separate from fame and stays in range.
    addImage(l, 500);
    expect(l.image, 100);
    addImage(l, -500);
    expect(l.image, -100);
    // A scandal hurts your image as well as your fame.
    l.image = 0;
    l.flags['affair_found'] = Memory(l.age, 'x');
    l.sceneQueue.add('scandal:affair');
    final scandal = engine.nextScene(l)!;
    engine.choose(l, scandal, scandal.choices.first);
    expect(l.image, lessThan(0));
    // Feuds raise fame, cost image, and ask what you do next.
    final feud = allActions.firstWhere((a) => a.id == 'start_feud');
    final fame = l.fame;
    engine.runAction(l, feud);
    expect(l.fame, greaterThan(fame));
    expect(l.sceneQueue.any((s) => s.startsWith('fame_feud:')), isTrue);
    // A product line earns more when you are liked.
    l.marks.add('product_line');
    l.image = 50;
    final liked = productIncome(l);
    l.image = -50;
    expect(productIncome(l), lessThan(liked));
    // Years of celebrity life run without errors.
    l.fame = 80;
    for (var y = 0; y < 10; y++) {
      l.age++;
      celebrityYear(l, Random(y));
    }
    expect(fameTierOf(l).name, isNot('Unknown'));
  });

  test(
    'countries: researched profiles shape pay, prices, school and service',
    () {
      // Every country has a full profile, not the fallback.
      for (final c in countries) {
        final p = countryProfile(c.name);
        expect(p.everyday, isNotEmpty, reason: c.name);
        expect(p.local, isNotEmpty, reason: c.name);
        expect(p.culture, isNotEmpty, reason: c.name);
      }
      expect(countries.length, greaterThanOrEqualTo(24));
      final l = engine.newLife(seed: 260)..age = 25;
      final retail = careerById('retail')!;
      l.country = 'United States';
      final us = retail.payIn(l, 0);
      final usCost = livingCost(l);
      l.country = 'Kenya';
      expect(retail.payIn(l, 0), lessThan(us));
      expect(livingCost(l), lessThan(usCost));
      // Gambling is banned for citizens in Egypt; the casino says so.
      final casino = allActions.firstWhere((a) => a.id == 'casino');
      l.money = 10000;
      l.country = 'Egypt';
      expect(casino.lockReason(l), contains('illegal'));
      l.country = 'United States';
      l.age = 19;
      expect(casino.lockReason(l), contains('21'));
      // Military service: every 18-year-old man in South Korea is called up.
      final k = engine.newLife(seed: 261);
      k.country = 'South Korea';
      k.age = 18;
      if (k.gender == 'male') {
        countryYear(k, Random(1));
        expect(k.sceneQueue, contains('draft'));
        final scene = engine.nextScene(k)!;
        engine.choose(k, scene, scene.choices.first);
        expect(k.flags.containsKey('served'), isTrue);
      }
      // Retirement follows the country.
      expect(countryProfile('France').retireAge, lessThan(65));
      expect(countryProfile('Germany').tuition, 0);
    },
  );

  test('sounds match what happened, and every cue has a file', () {
    expect(Sound.cueFor('Blue lights fill the street.'), 'siren');
    expect(Sound.cueFor('Your grandmother died at 91.'), 'sad');
    expect(Sound.cueFor('A baby girl was born.'), 'celebrate');
    expect(Sound.cueFor('You were promoted to manager.'), 'promote');
    expect(Sound.cueFor('You got the keys to a flat.'), 'keys');
    expect(Sound.cueFor('It went viral.'), 'cheer');
    expect(Sound.cueFor('Nothing much happened.', money: 5000), 'coin');
    expect(Sound.cueFor('Nothing much happened.', money: -5000), 'spend');
    expect(Sound.cueFor('Nothing much happened.'), isNull);
    for (final name in [
      'siren',
      'sad',
      'celebrate',
      'promote',
      'keys',
      'cheer',
      'heartbeat',
      'coin',
      'spend',
      'purchase',
      'news',
      'whoosh',
      'hit',
      'miss',
      'tick',
      'win',
      'lose',
      'tap',
      'age_up',
      'good',
      'bad',
      'neutral',
    ]) {
      expect(
        File('assets/sounds/$name.wav').existsSync(),
        isTrue,
        reason: name,
      );
    }
  });

  test('social media and fame feed each other', () {
    final l = engine.newLife(seed: 262)..age = 25;
    // Fame and a good image make posts likelier to spread.
    final (plain, _) = viralChance(l, 'vybe', 'talent');
    l.fame = 60;
    l.image = 60;
    final (famous, why) = viralChance(l, 'vybe', 'talent');
    expect(famous, greaterThan(plain));
    expect(why, contains('your fame'));
    // Fame moments off-screen bring followers.
    expect(l.followers, isEmpty);
    final talk = allActions.firstWhere((a) => a.id == 'talk_show');
    engine.runAction(l, talk);
    expect(maxFollowers(l), greaterThan(0));
    // Social media actions live in their own Activities category.
    final post = allActions.firstWhere((a) => a.id == 'post_online');
    expect(post.category, 'Social media');
    final verify = allActions.firstWhere((a) => a.id == 'get_verified');
    expect(verify.category, 'Social media');
  });

  test(
    'music: a quiet hobby, then Road to the Underground, then the big time',
    () {
      final l = engine.newLife(seed: 263)..age = 20;
      l.stats.values['creativity'] = 95;
      l.flags['instrument'] = Memory(15, 'guitar');
      final write = allActions.firstWhere((a) => a.id == 'write_song');
      final single = allActions.firstWhere((a) => a.id == 'release_single');
      final pop = variantsFor('write_song').firstWhere((v) => v.id == 'pop');
      // It starts as a hobby: the Music category is closed.
      expect(write.category, 'Hobbies');
      expect(musicUnlocked(l), isFalse);
      for (var i = 0; i < 3; i++) {
        engine.runAction(l, write, score: 1, variant: pop);
      }
      expect(unreleased(l).length, 3);
      void releaseOne(int how) {
        engine.runAction(l, single);
        var scene = engine.nextScene(l)!;
        expect(scene.id, 'scene:release_pick');
        engine.choose(l, scene, scene.choices.first);
        scene = engine.nextScene(l)!;
        engine.choose(l, scene, scene.choices[how]);
      }

      releaseOne(0); // at home
      expect(musicUnlocked(l), isFalse);
      l.age++;
      l.usedActions.clear();
      l.energy = 10;
      l.money = 50000;
      releaseOne(1); // in a studio
      // Three written, two released: the chapter opens.
      expect(musicUnlocked(l), isTrue);
      expect(l.sceneQueue, contains('underground_intro'));
      final intro = engine.nextScene(l)!;
      engine.choose(l, intro, intro.choices.first);
      expect(roadProgress(l), contains('studio'));
      // The chapter's small tasks.
      for (final id in ['play_gig', 'jam_session', 'sell_merch']) {
        engine.runAction(l, allActions.firstWhere((a) => a.id == id));
      }
      expect(roadProgress(l), containsAll(['open_mic', 'jam', 'merch']));
      released(l).first['streams'] = 30000;
      roadCheck(l, Random(1));
      expect(roadDone(l), isTrue);
      expect(l.flags.containsKey('underground'), isTrue);
      // Now the big time: an album with an audience charts and labels call.
      l.age++;
      l.usedActions.clear();
      l.energy = 10;
      for (var i = 0; i < 3; i++) {
        engine.runAction(l, write, score: 1, variant: pop);
      }
      l.age++;
      l.usedActions.clear();
      l.energy = 10;
      for (var i = 0; i < 3; i++) {
        engine.runAction(l, write, score: 1, variant: pop);
      }
      // A seasoned songwriter with a real fanbase.
      l.music['skill'] = 95;
      l.music['fans'] = 3000000;
      l.fame = 60;
      l.followers['vybe'] = 2000000;
      engine.runAction(
        l,
        allActions.firstWhere((a) => a.id == 'release_album'),
      );
      final album = engine.nextScene(l)!;
      expect(album.id, 'scene:album_how');
      engine.choose(l, album, album.choices.first);
      expect(released(l).any((s) => (s['best'] as int) > 0), isTrue);
      expect(knownFor(l), contains('your music'));
      expect(l.sceneQueue, contains('label_offer'));
      // Royalties each birthday, fading streams, and a tour.
      final rate = released(l).last['rate'] as int;
      expect(musicRoyalties(l), greaterThan(0));
      expect(released(l).last['rate'] as int, lessThan(rate));
      final tour = allActions.firstWhere((a) => a.id == 'go_on_tour');
      expect(tour.lockReason(l), isNull);
    },
  );

  test('song titles: your own name, tidied', () {
    final l = engine.newLife(seed: 264)..age = 20;
    writeSong(l, Random(1), 'rock', 0.8);
    final song = l.songs.last;
    final old = song['title'];
    expect(renameSong(l, song, '   '), old);
    expect(renameSong(l, song, '  Late   Bus Home '), 'Late Bus Home');
    expect(renameSong(l, song, 'x' * 60).length, 40);
  });

  test(
    'music: skill grows, quality decides hits, fame counts once established',
    () {
      final l = engine.newLife(seed: 265)..age = 20;
      // Songwriting improves with every song, faster when played well.
      writeSong(l, Random(1), 'pop', 1);
      final afterGood = songwritingOf(l);
      final m = engine.newLife(seed: 265)..age = 20;
      writeSong(m, Random(1), 'pop', 0);
      expect(afterGood, greaterThan(songwritingOf(m)));
      // Same artist, same luck: a strong song beats a weak one by far.
      int streamsFor(int q, {int fame = 0}) {
        final a = engine.newLife(seed: 266)..age = 25;
        a.fame = fame;
        a.followers['vybe'] = fame * 100000;
        final song = {
          'title': 'T',
          'genre': 'folk',
          'q': q,
          'age': 25,
          'out': false,
          'streams': 0,
          'rate': 0,
          'best': 0,
        };
        a.songs.add(song);
        releaseSongs(a, [song], 'home', Random(7));
        return song['streams'] as int;
      }

      expect(streamsFor(90), greaterThan(streamsFor(40) * 5));
      // Before you are established, fame does not lift a song.
      expect(streamsFor(60, fame: 80), streamsFor(60));
      // Several releases a year.
      final single = allActions.firstWhere((a) => a.id == 'release_single');
      expect(single.repeatable, isTrue);
    },
  );

  test('upper echelon: hidden below \$100M, opens above it', () {
    final l = engine.newLife(seed: 311)..age = 40;
    final elite = allActions.where((a) => a.category == 'Upper echelon');
    expect(elite.length, greaterThanOrEqualTo(12));
    l.money = 90000000;
    engine.ageUp(l);
    expect(upperEchelon(l), isFalse);
    for (final a in elite) {
      expect(a.lockReason(l), isNotNull);
    }
    l.money = 150000000;
    l.sceneQueue.clear();
    final first = engine.ageUp(l);
    expect(upperEchelon(l), isTrue);
    final intro = first?.id == 'scene:elite_intro'
        ? first!
        : buildScene('elite_intro', l)!;
    expect(
      first?.id == 'scene:elite_intro' || l.sceneQueue.contains('elite_intro'),
      isTrue,
    );
    expect(intro.id, 'scene:elite_intro');
    engine.choose(l, intro, intro.choices.first);
    l.usedActions.clear();
    l.energy = 10;
    final rich = allActions.firstWhere((a) => a.id == 'rich_list');
    expect(rich.lockReason(l), isNull);
    final yacht = allActions.firstWhere((a) => a.id == 'superyacht');
    engine.runAction(l, yacht);
    expect(l.assets.any((a) => a.name == 'Superyacht'), isTrue);
    expect(yacht.lockReason(l), isNotNull);
    // Islands come as a choice of three.
    l.money = 200000000;
    engine.runAction(l, allActions.firstWhere((a) => a.id == 'buy_island'));
    final islands = engine.nextScene(l)!;
    expect(islands.id, 'scene:elite_island');
    engine.choose(l, islands, islands.choices.first);
    expect(l.assets.any((a) => a.kind == 'island'), isTrue);
    // The ranking makes sense.
    expect(richerThan(100000000), inInclusiveRange(100000, 130000));
    expect(richerThan(1000000000), inInclusiveRange(3700, 3800));
    l.marks.add('security');
    expect(eliteCosts(l).any((c) => c.$1 == 'Security detail'), isTrue);
  });

  test('money shows in the local currency', () {
    expect(moneyIn(1000, 'United States'), '\$1,000');
    expect(moneyIn(1000, 'Japan'), '¥150,000');
    expect(moneyIn(-1000, 'United Kingdom'), '−£790');
    expect(localizeMoney('Costs \$2,000', 'Nigeria'), 'Costs ₦3,100,000');
    // Already-local amounts are not converted twice.
    expect(localizeMoney('MX\$500', 'Mexico'), 'MX\$500');
    expect(localizeMoney('-\$10', 'Germany'), '−€9');
  });

  test('upper echelon: owning things opens more to do with them', () {
    final l = engine.newLife(seed: 317)..age = 45;
    l.flags['upper_echelon'] = Memory(45, 'joining');
    GameAction act(String id) => allActions.firstWhere((a) => a.id == id);
    void fresh() {
      l.usedActions.clear();
      l.energy = 10;
      l.money = 2000000000;
    }

    fresh();
    // Asset-based activities wait for the asset.
    for (final id in [
      'island_retreat',
      'island_resort',
      'yacht_party',
      'sign_star',
      'new_stadium',
      'paper_campaign',
      'lend_art',
      'private_museum',
      'foundation_gala',
    ]) {
      expect(act(id).lockReason(l), isNotNull, reason: id);
    }
    engine.runAction(l, act('buy_team'));
    final teams = engine.nextScene(l)!;
    engine.choose(l, teams, teams.choices[1]);
    final team = l.assets.firstWhere((a) => a.kind == 'team');
    fresh();
    engine.runAction(l, act('sign_star'));
    expect(team.info['squad'], 12);
    fresh();
    engine.runAction(l, act('new_stadium'));
    expect(team.info['stadium'], isTrue);
    expect(act('new_stadium').lockReason(l), isNotNull);
    // A season pays out and the squad ages.
    eliteYear(l, Random(3));
    expect(team.info['squad'], 8);
    // Foundation, then galas grow it.
    fresh();
    engine.runAction(l, act('start_foundation'));
    final fund = foundationFund(l);
    expect(fund, greaterThan(0));
    fresh();
    expect(act('foundation_gala').lockReason(l), isNull);
    engine.runAction(l, act('foundation_gala'));
    expect(foundationFund(l), greaterThan(fund));
    // A second passport helps visas.
    final before = visaOdds(l, 'Japan').$1;
    fresh();
    engine.runAction(l, act('second_passport'));
    expect(visaOdds(l, 'Japan').$1, greaterThan(before));
    // Billionaire milestone and the pledge.
    expect(act('giving_pledge').lockReason(l), isNull);
    l.sceneQueue.clear();
    l.flags.remove('billionaire');
    eliteYear(l, Random(5));
    expect(l.flags.containsKey('billionaire'), isTrue);
    expect(l.sceneQueue, contains('elite_billion'));
    for (final id in ['elite_billion', 'elite_leak', 'elite_ask']) {
      expect(buildScene(id, l), isNotNull, reason: id);
    }
    // Offshore adds a cash line.
    fresh();
    engine.runAction(l, act('offshore'));
    expect(eliteCosts(l).any((c) => c.$1.startsWith('Offshore')), isTrue);
  });

  test('moving abroad names the new currency', () {
    expect(currencyLabel('Japan'), 'Japanese yen (¥)');
    expect(currencyLabel('France'), 'euro (€)');
  });

  test('businesses: run several at once, each its own trade', () {
    final life = engine.newLife(seed: 331)..age = 30;
    life.money = 1000000;
    void found(int industry) {
      life.sceneQueue.add('biz_found');
      var scene = engine.nextScene(life)!;
      engine.choose(life, scene, scene.choices[industry]);
      scene = engine.nextScene(life)!;
      engine.choose(life, scene, scene.choices.first);
      scene = engine.nextScene(life)!;
      engine.choose(life, scene, scene.choices.first);
      while (engine.nextScene(life) != null) {}
    }

    found(0);
    found(0);
    found(4);
    expect(life.businesses.length, 3);
    expect(life.businesses[1].name, endsWith(' 2'));
    // The newest is the one being managed; switching works.
    expect(life.business, life.businesses.last);
    focusBusiness(life, 0);
    expect(life.business, life.businesses.first);
    // Every trade has its own role, upgrades, signature and events.
    for (final ind in industries) {
      final k = bizKinds[ind.id];
      expect(k, isNotNull, reason: ind.id);
      expect(k!.perks.length, 3);
      for (final e in k.events) {
        final b = life.businesses.first;
        expect(tradeEventScene([e, b.name], life), isNotNull, reason: e);
      }
    }
    // Upgrades raise sales; moves are once a year per business.
    final cafe = life.business!;
    final perk = bizKinds['cafe']!.perks[1];
    buyPerk(life, perk);
    expect(perkEffects(cafe).$1, greaterThan(0));
    expect(perkLock(life, perk), 'Done');
    runSignature(life, Random(1));
    expect(signatureLock(life), 'Done this year');
    focusBusiness(life, 1);
    expect(signatureLock(life), isNull);
    // Each business trades every birthday.
    final names = life.businesses.map((b) => b.name).toSet();
    final before = life.businesses.map((b) => b.revenue).toList();
    engine.ageUp(life);
    expect(before.every((r) => r == 0), isTrue);
    expect(
      life.businesses
          .where((b) => names.contains(b.name))
          .every((b) => b.revenue > 0),
      isTrue,
    );
    // Saved and loaded together.
    final copy = Life.fromJson(
      jsonDecode(jsonEncode(life.toJson())) as Map<String, dynamic>,
    );
    expect(copy.businesses.length, life.businesses.length);
    expect(copy.businesses.first.perks, contains(perk.id));
    // An old save with one business still loads.
    final old = life.toJson()
      ..remove('businesses')
      ..['business'] = life.businesses.first.toJson();
    expect(Life.fromJson(old).businesses.length, 1);
    // Bankruptcy takes them all.
    bankruptcy(life);
    expect(life.businesses, isEmpty);
  });

  test('logic fixes: people, prison, trophies and businesses', () {
    final l = engine.newLife(seed: 401)..age = 30;
    l.money = 100000;
    // An ex stays in your life when you meet someone new.
    final first = candidate(l, Random(1));
    l.npcs.add(first);
    endRelationship(l, first, 'breaking up');
    final second = candidate(l, Random(2));
    l.npcs.add(second);
    expect(l.npcs.where((n) => n.circle == 'Exes'), isNotEmpty);
    expect(second.id, isNot(first.id));
    // An affair partner never shares an id with anyone.
    engine.runAction(l, allActions.firstWhere((a) => a.id == 'affair'));
    final ids = l.npcs.map((n) => n.id).toList();
    expect(ids.toSet().length, ids.length);
    // Going back inside costs the job, like any sentence.
    l.job = 'Accountant';
    l.salary = 40000;
    l.marks.add('parole_until:${l.age + 3}');
    recapture(l, Random(1));
    expect(l.job, isNull);
    // Selling a bunker stops the caretakers' bill; selling the newspaper
    // ends its protection.
    final r = engine.newLife(seed: 402)..age = 50;
    r.flags['upper_echelon'] = Memory(50, 'x');
    r.money = 500000000;
    engine.runAction(r, allActions.firstWhere((a) => a.id == 'bunker'));
    expect(eliteCosts(r).any((c) => c.$1 == 'Bunker caretakers'), isTrue);
    r.assets.removeWhere((a) => a.kind == 'bunker');
    expect(eliteCosts(r).any((c) => c.$1 == 'Bunker caretakers'), isFalse);
    r.usedActions.clear();
    engine.runAction(r, allActions.firstWhere((a) => a.id == 'buy_newspaper'));
    expect(r.marks, contains('publicist'));
    r.assets.removeWhere((a) => a.kind == 'media');
    eliteYear(r, Random(1));
    expect(r.marks, isNot(contains('publicist')));
    // Two failing businesses each get their own crisis.
    final b = engine.newLife(seed: 403)..age = 40;
    for (final name in ['A Café', 'B Café']) {
      b.businesses.add(
        Business(name: name, industry: 'cafe', tier: 'mid', since: 30)
          ..quality = 5
          ..brand = 0
          ..satisfaction = 0
          ..staff = 30
          ..lossYears = 1,
      );
    }
    for (final x in [...b.businesses]) {
      businessYear(b, Random(1), x);
    }
    expect(b.sceneQueue.where((q) => q.startsWith('insolvency:')).length, 2);
  });

  test('babies arrive in many more ways', () {
    Life adult(int seed, String gender) {
      final l = engine.newLife(seed: seed, gender: gender)..age = 28;
      l.money = 50000;
      return l;
    }

    void pick(Life l, String id, int choice) {
      final s = buildScene(id, l)!;
      engine.choose(l, s, s.choices[choice]);
    }

    // Every new scene builds in its situation.
    final l = adult(501, 'female');
    final p = candidate(l, Random(1))..info['gender'] = 'male';
    l.npcs.add(p);
    for (final id in ['baby_surprise', 'baby_fling']) {
      if (id == 'baby_fling') l.npcs.remove(p);
      expect(buildScene(id, l), isNotNull, reason: id);
    }
    l.npcs.add(p);
    // A surprise kept: a birth plan, then a baby with a birth story.
    pick(l, 'baby_surprise', 0);
    expect(l.flags.containsKey('expecting'), isTrue);
    expect(l.sceneQueue, contains('birth_plan'));
    l.sceneQueue.clear();
    pick(l, 'birth_plan', 1);
    expect(l.marks, contains('birth_plan:home'));
    l.flags.remove('expecting');
    final birth = buildScene('birth', l)!;
    expect(birth.text, isNotEmpty);
    engine.choose(l, birth, birth.choices.first);
    expect(childrenOf(l), isNotEmpty);
    expect(l.marks.any((m) => m.startsWith('birth_plan:')), isFalse);
    // Placing a baby for adoption, and the letter 18 years later.
    final m = adult(502, 'female');
    final q = candidate(m, Random(3))..info['gender'] = 'male';
    m.npcs.add(q);
    pick(m, 'baby_surprise', 1);
    m.flags.remove('expecting');
    final placed = buildScene('birth', m)!;
    engine.choose(m, placed, placed.choices.first);
    expect(childrenOf(m), isEmpty);
    final mark = m.marks.firstWhere((x) => x.startsWith('placed:'));
    final name = mark.split(':')[1];
    m.age += 18;
    for (var i = 0; i < 40 && m.marks.contains(mark); i++) {
      reunionYear(m, Random(i));
    }
    final q2 = m.sceneQueue.firstWhere((x) => x.startsWith('adopted_reunion'));
    pick(m, q2, 0);
    expect(childrenOf(m).single.name, name);
    // A fling: the other parent is recorded even without dating.
    final f = adult(503, 'male');
    pick(f, 'baby_fling', 1);
    f.flags.remove('expecting');
    final fb = buildScene('birth', f)!;
    engine.choose(f, fb, fb.choices.first);
    expect(childrenOf(f).single.info['otherParent'], isNotNull);
    // Surprises happen over the years for a couple not trying.
    var surprises = 0;
    for (var seed = 1; seed <= 200; seed++) {
      final c = adult(600 + seed, 'female');
      c.npcs.add(candidate(c, Random(seed))..info['gender'] = 'male');
      surpriseBabyYear(c, Random(seed));
      if (c.sceneQueue.contains('baby_surprise')) surprises++;
    }
    expect(surprises, inInclusiveRange(1, 20));
  });
}
