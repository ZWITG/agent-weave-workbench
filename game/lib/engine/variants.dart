import 'dart:math';

import 'actions.dart';
import 'models.dart';
import 'social.dart';

// Ways to do an activity: how hard, how much to spend, and who to bring.
// The Activities panel asks before running; a mini-game (if the activity
// has one) still decides how well it went.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '\$$s';
}

class ActionVariant {
  const ActionVariant({
    required this.id,
    required this.label,
    required this.detail,
    required this.run,
    this.cost = 0,
    this.withPerson = false,
    this.minAge = 0,
    this.check,
  });

  final String id;
  final String label;

  /// What it does, shown before choosing ("Health +3 to +7 · 10% strain").
  final String detail;
  final int cost;

  /// Asks who to bring; [run] gets that person.
  final bool withPerson;
  final int minAge;

  /// Any other reason this way is not possible right now.
  final String? Function(Life l)? check;

  /// [score] is the mini-game result (0..1), or null when there is none.
  final ActionResult Function(Life l, Random rng, Npc? who, double? score) run;

  String? lockReason(Life l) {
    if (l.age < minAge) return 'From age $minAge';
    if (cost > 0 && l.money < cost) return 'Needs ${_m(cost)}';
    if (withPerson && companions(l).isEmpty) return 'Nobody to bring yet';
    return check?.call(l);
  }
}

/// People you can bring along: alive, not pets, not inside.
List<Npc> companions(Life l) =>
    (l.npcs
        .where(
          (n) =>
              n.alive &&
              n.circle != 'Pets' &&
              n.circle != 'Prison' &&
              !n.contactCut,
        )
        .toList()
      ..sort((a, b) => b.bond.compareTo(a.bond)));

/// Bringing someone: they enjoy it, remember it, and you catch up.
String _together(Life l, Npc? who, String what, {int bond = 5}) {
  if (who == null) return '';
  who.addFacets(affection: bond, trust: 1);
  who.lastContactAge = l.age;
  who.remember(
    NpcMemory(
      age: l.age,
      text: what,
      valence: 1,
      intensity: 2,
      tags: ['together'],
    ),
  );
  return 'Bond with ${who.name.split(' ').first} +$bond';
}

ActionResult _with(
  Life l,
  String text,
  Map<String, int> stats, {
  Npc? who,
  String together = 'spending the day with you',
  int bond = 5,
  int cost = 0,
}) {
  if (cost > 0) l.money -= cost;
  final r = statChange(l, text, stats);
  final b = _together(l, who, together, bond: bond);
  return ActionResult(r.text, [
    if (cost > 0) 'Money −${_m(cost)}',
    ...r.notes,
    if (b.isNotEmpty) b,
  ]);
}

String _first(Npc? n) => n?.name.split(' ').first ?? 'them';

double _s(double? score) => score ?? 0.6;

final actionVariants = <String, List<ActionVariant>>{
  // Social media: what kind of post, on each platform (social.dart).
  for (final p in platforms)
    'post_${p.id}': [
      for (final t in postTypes)
        ActionVariant(
          id: t.id,
          label: t.label,
          detail:
              '${t.blurb}${p.fits.contains(t.id) ? ' · suits ${p.name}' : ''}${t.risk >= 2 ? ' · can backfire' : ''}',
          check: (l) => postLock(l, p.id, t.id),
          run: (l, rng, who, score) => post(l, p.id, t.id, rng),
        ),
    ],
  'gym': [
    ActionVariant(
      id: 'light',
      label: 'Light session',
      detail: 'Health +1 to +3 · no strain',
      run: (l, rng, who, score) {
        l.fitness = min(100, l.fitness + 4);
        return _with(
          l,
          'An easy session. You left feeling looser, not wrecked.',
          {'health': 1 + (_s(score) * 2).round(), 'athleticism': 1},
        );
      },
    ),
    ActionVariant(
      id: 'normal',
      label: 'Normal session',
      detail: 'Health +2 to +5, athleticism +2',
      run: (l, rng, who, score) {
        l.fitness = min(100, l.fitness + 8);
        return _with(
          l,
          'You worked out until everything ached, in a good way.',
          {
            'health': 2 + (_s(score) * 3).round(),
            'looks': rng.nextInt(2),
            'athleticism': 2,
          },
        );
      },
    ),
    ActionVariant(
      id: 'hard',
      label: 'Go all out',
      detail: 'Health +3 to +7 · about 10% chance of a strain',
      run: (l, rng, who, score) {
        final strain =
            rng.nextInt(100) < max(3, 12 - l.stats['athleticism'] ~/ 12);
        if (strain) {
          return _with(
            l,
            'You pushed one rep too far and felt something twang. A week of hobbling.',
            {'health': -3, 'happiness': -2},
          );
        }
        l.fitness = min(100, l.fitness + 12);
        return _with(
          l,
          'You emptied the tank. Personal best, shaking legs, huge grin.',
          {'health': 3 + (_s(score) * 4).round(), 'looks': 1, 'athleticism': 3},
        );
      },
    ),
    ActionVariant(
      id: 'buddy',
      label: 'Train with someone',
      detail: 'Health +2 to +4 · Bond +5',
      withPerson: true,
      run: (l, rng, who, score) {
        l.fitness = min(100, l.fitness + 7);
        return _with(
          l,
          '${_first(who)} spotted you, you spotted them, and you both talked far too much between sets.',
          {
            'health': 2 + (_s(score) * 2).round(),
            'athleticism': 1,
            'happiness': 1,
          },
          who: who,
          together: 'working out together',
        );
      },
    ),
  ],
  'study': [
    ActionVariant(
      id: 'quick',
      label: 'Quick revision',
      detail: 'Smarts +1 to +3',
      run: (l, rng, who, score) {
        l.school.effort = 75;
        return _with(
          l,
          'Twenty minutes with your notes. Better than nothing.',
          {'smarts': 1 + (_s(score) * 2).round()},
        );
      },
    ),
    ActionVariant(
      id: 'long',
      label: 'A proper study session',
      detail: 'Smarts +2 to +6 · happiness −1',
      run: (l, rng, who, score) {
        l.school.effort = 100;
        return _with(
          l,
          'Three hours at the desk. It is finally starting to click.',
          {
            'smarts': 2 + (_s(score) * 4).round(),
            'discipline': 1,
            'happiness': -1,
          },
        );
      },
    ),
    ActionVariant(
      id: 'allnighter',
      label: 'Pull an all-nighter',
      detail: 'Smarts +3 to +8 · health −3, happiness −2',
      run: (l, rng, who, score) {
        l.school.effort = 100;
        return _with(
          l,
          'You watched the sun come up over your textbook. You know everything and can feel nothing.',
          {
            'smarts': 3 + (_s(score) * 5).round(),
            'health': -3,
            'happiness': -2,
          },
        );
      },
    ),
    ActionVariant(
      id: 'group',
      label: 'Study with someone',
      detail: 'Smarts +1 to +4 · Bond +4',
      withPerson: true,
      run: (l, rng, who, score) {
        l.school.effort = 100;
        return _with(
          l,
          'You quizzed each other until you were both laughing at the wrong answers.',
          {'smarts': 1 + (_s(score) * 3).round(), 'happiness': 1},
          who: who,
          together: 'studying together',
          bond: 4,
        );
      },
    ),
  ],
  'walk': [
    ActionVariant(
      id: 'alone',
      label: 'Alone, phone off',
      detail: 'Happiness +2, health +1',
      run: (l, rng, who, score) => _with(
        l,
        'Just you and your thoughts, which turned out to be decent company.',
        {'happiness': 2, 'health': 1},
      ),
    ),
    ActionVariant(
      id: 'park',
      label: 'The long way through the park',
      detail: 'Happiness +3, health +1',
      run: (l, rng, who, score) => _with(
        l,
        rng.nextBool()
            ? 'A dog brought you a stick and refused to take no for an answer.'
            : 'The trees were turning gold. You walked twice as far as planned.',
        {'happiness': 3, 'health': 1},
      ),
    ),
    ActionVariant(
      id: 'together',
      label: 'Walk with someone',
      detail: 'Happiness +2 · Bond +5',
      withPerson: true,
      run: (l, rng, who, score) => _with(
        l,
        'You walked with ${_first(who)} and talked about everything and nothing.',
        {'happiness': 2, 'health': 1},
        who: who,
        together: 'a long walk together',
      ),
    ),
  ],
  'read': [
    ActionVariant(
      id: 'novel',
      label: 'A novel',
      detail: 'Happiness +2, creativity +1',
      run: (l, rng, who, score) => _with(
        l,
        'You read until the story was more real than the room.',
        {'happiness': 2, 'creativity': 1},
      ),
    ),
    ActionVariant(
      id: 'nonfiction',
      label: 'Non-fiction',
      detail: 'Smarts +2',
      run: (l, rng, who, score) => _with(
        l,
        'You learned three facts you now cannot stop telling people.',
        {'smarts': 2},
      ),
    ),
    ActionVariant(
      id: 'aloud',
      label: 'Read aloud to someone',
      detail: 'Happiness +2 · Bond +4',
      withPerson: true,
      minAge: 8,
      run: (l, rng, who, score) => _with(
        l,
        'You did all the voices. ${_first(who)} asked for one more chapter.',
        {'happiness': 2, 'charisma': 1},
        who: who,
        together: 'you reading to me',
        bond: 4,
      ),
    ),
  ],
  'meditate': [
    ActionVariant(
      id: 'short',
      label: 'Ten quiet minutes',
      detail: 'Happiness +2 to +4',
      run: (l, rng, who, score) => _with(
        l,
        'You sat in silence and felt a little lighter.',
        {'happiness': 2 + rng.nextInt(3), 'willpower': 1},
      ),
    ),
    ActionVariant(
      id: 'guided',
      label: 'A guided session',
      detail: 'Happiness +3, willpower +2',
      run: (l, rng, who, score) => _with(
        l,
        'A calm voice told you to notice your breathing. You noticed you had not been.',
        {'happiness': 3, 'willpower': 2},
      ),
    ),
    ActionVariant(
      id: 'retreat',
      label: 'Weekend retreat (\$300)',
      detail: 'Happiness +6, willpower +3, health +1',
      cost: 300,
      minAge: 16,
      run: (l, rng, who, score) => _with(
        l,
        'Two days of silence, lentils and birdsong. You came back a slightly different person.',
        {'happiness': 6, 'willpower': 3, 'health': 1},
        cost: 300,
      ),
    ),
  ],
  'nightlife': [
    ActionVariant(
      id: 'cheap',
      label: 'A cheap night (\$40)',
      detail: 'Happiness +3',
      cost: 40,
      run: (l, rng, who, score) => _with(
        l,
        'Cheap drinks, a sticky floor and one perfect song.',
        {'happiness': 3},
        cost: 40,
      ),
    ),
    ActionVariant(
      id: 'big',
      label: 'A big night (\$200)',
      detail: 'Happiness +6 · health −2 · you might meet someone',
      cost: 200,
      run: (l, rng, who, score) {
        final met = rng.nextInt(100) < 25 && l.who('@partner') == null;
        if (met) {
          l.flags['nightlife_meet'] ??= Memory(
            l.age,
            'meeting someone on a night out',
          );
        }
        return _with(
          l,
          met
              ? 'You danced until 3am and swapped numbers with someone who laughed at all your jokes.'
              : 'VIP booth, terrible decisions, a kebab at dawn. Legendary.',
          {'happiness': 6, 'health': -2, 'charisma': 1},
          cost: 200,
        );
      },
    ),
    ActionVariant(
      id: 'friends',
      label: 'Out with someone (\$80)',
      detail: 'Happiness +4 · Bond +6',
      cost: 80,
      withPerson: true,
      run: (l, rng, who, score) => _with(
        l,
        'You and ${_first(who)} closed the bar and walked home singing.',
        {'happiness': 4},
        who: who,
        together: 'a great night out with you',
        bond: 6,
        cost: 80,
      ),
    ),
  ],
  'vacation': [
    ActionVariant(
      id: 'beach',
      label: 'Beach resort (\$3,000)',
      detail: 'Happiness +8, health +2',
      cost: 3000,
      run: (l, rng, who, score) => _with(
        l,
        'Two weeks of sun, sea and doing absolutely nothing. You came home a new colour.',
        {'happiness': 8, 'health': 2},
        cost: 3000,
      ),
    ),
    ActionVariant(
      id: 'city',
      label: 'City break (\$1,800)',
      detail: 'Happiness +6, smarts +2',
      cost: 1800,
      run: (l, rng, who, score) => _with(
        l,
        'Museums, markets and getting lost on purpose. Your feet hate you.',
        {'happiness': 6, 'smarts': 2},
        cost: 1800,
      ),
    ),
    ActionVariant(
      id: 'backpack',
      label: 'Backpacking (\$1,200)',
      detail: 'Happiness +7, charisma +2 · a little risky',
      cost: 1200,
      run: (l, rng, who, score) {
        final lost = rng.nextInt(100) < 15;
        return _with(
          l,
          lost
              ? 'Your bag was stolen on day three. The strangers who helped you are now lifelong friends.'
              : 'Night buses, hostels and a sunrise you will describe at every party for the rest of your life.',
          {'happiness': lost ? 4 : 7, 'charisma': 2},
          cost: lost ? 1500 : 1200,
        );
      },
    ),
    ActionVariant(
      id: 'together',
      label: 'Go with someone (\$4,500)',
      detail: 'Happiness +8 · Bond +10',
      cost: 4500,
      withPerson: true,
      run: (l, rng, who, score) => _with(
        l,
        'You and ${_first(who)} found a tiny restaurant on the first night and went back every evening.',
        {'happiness': 8},
        who: who,
        together: 'our holiday together',
        bond: 10,
        cost: 4500,
      ),
    ),
  ],
  'weekend_trip': [
    ActionVariant(
      id: 'camping',
      label: 'Camping (\$150)',
      detail: 'Happiness +4, health +1',
      cost: 150,
      run: (l, rng, who, score) => _with(
        l,
        'It rained, the tent leaked, and it was brilliant.',
        {'happiness': 4, 'health': 1},
        cost: 150,
      ),
    ),
    ActionVariant(
      id: 'spa',
      label: 'Spa hotel (\$600)',
      detail: 'Happiness +5, health +2, looks +1',
      cost: 600,
      run: (l, rng, who, score) => _with(
        l,
        'Robes, steam rooms and a nap you will think about for years.',
        {'happiness': 5, 'health': 2, 'looks': 1},
        cost: 600,
      ),
    ),
    ActionVariant(
      id: 'together',
      label: 'Away with someone (\$400)',
      detail: 'Happiness +4 · Bond +7',
      cost: 400,
      withPerson: true,
      run: (l, rng, who, score) => _with(
        l,
        'A little cottage, a fire and ${_first(who)} beating you at cards all weekend.',
        {'happiness': 4},
        who: who,
        together: 'that weekend away',
        bond: 7,
        cost: 400,
      ),
    ),
  ],
  'volunteer': [
    ActionVariant(
      id: 'animals',
      label: 'Animal shelter',
      detail: 'Karma +3, happiness +2',
      run: (l, rng, who, score) => _with(
        l,
        'You walked eight dogs and fell in love with all of them.',
        {'karma': 3, 'happiness': 2},
      ),
    ),
    ActionVariant(
      id: 'foodbank',
      label: 'Food bank',
      detail: 'Karma +4',
      run: (l, rng, who, score) => _with(
        l,
        'You packed 300 food parcels. Every one of them was going to someone.',
        {'karma': 4, 'happiness': 1},
      ),
    ),
    ActionVariant(
      id: 'tutor',
      label: 'Tutor kids',
      detail: 'Karma +3, smarts +1',
      minAge: 15,
      run: (l, rng, who, score) => _with(
        l,
        'A kid who hated maths got a question right and looked at you like a magician.',
        {'karma': 3, 'smarts': 1, 'charisma': 1},
      ),
    ),
    ActionVariant(
      id: 'together',
      label: 'Volunteer with someone',
      detail: 'Karma +3 · Bond +4',
      withPerson: true,
      run: (l, rng, who, score) => _with(
        l,
        'You and ${_first(who)} spent the day helping out and felt good about the world.',
        {'karma': 3, 'happiness': 1},
        who: who,
        together: 'volunteering together',
        bond: 4,
      ),
    ),
  ],
  'paint': [
    ActionVariant(
      id: 'sketch',
      label: 'A quick sketch',
      detail: 'Creativity +2',
      run: (l, rng, who, score) => _with(
        l,
        'You filled a page with doodles. One of them is actually good.',
        {'creativity': 2},
      ),
    ),
    ActionVariant(
      id: 'canvas',
      label: 'A big canvas (\$60)',
      detail: 'Creativity +4, happiness +1',
      cost: 60,
      minAge: 8,
      run: (l, rng, who, score) => _with(
        l,
        'You worked on it all weekend. It is going on the wall.',
        {'creativity': 4, 'happiness': 1},
        cost: 60,
      ),
    ),
    ActionVariant(
      id: 'sell',
      label: 'Sell at a market',
      detail: 'Creativity +1 · money depends on your Creativity',
      minAge: 14,
      run: (l, rng, who, score) {
        final take = (l.stats['creativity'] * (2 + rng.nextInt(4))).round();
        l.money += take;
        final r = _with(
          l,
          take > 250
              ? 'A collector bought three pieces and asked for your card.'
              : 'You sold a couple of small pieces and gave away a few more.',
          {'creativity': 1, 'happiness': 2},
        );
        return ActionResult(r.text, ['Money +${_m(take)}', ...r.notes]);
      },
    ),
    ActionVariant(
      id: 'teach',
      label: 'Paint with someone',
      detail: 'Creativity +2 · Bond +4',
      withPerson: true,
      run: (l, rng, who, score) => _with(
        l,
        '${_first(who)} painted a horse that looks like a sofa. It is your favourite thing you own.',
        {'creativity': 2, 'happiness': 2},
        who: who,
        together: 'painting together',
        bond: 4,
      ),
    ),
  ],
  'work_harder': [
    ActionVariant(
      id: 'overtime',
      label: 'Take overtime',
      detail: 'Extra pay · happiness −2',
      run: (l, rng, who, score) {
        final pay = max(200, (l.salary * 0.04).round());
        l.money += pay;
        final r = _with(
          l,
          'Late nights and weekend shifts. Your bank balance noticed; so did your back.',
          {'happiness': -2, 'discipline': 1},
        );
        return ActionResult(r.text, [
          'Money +${_m(pay)}',
          ...r.notes,
          'Better odds of a raise',
        ]);
      },
    ),
    ActionVariant(
      id: 'help',
      label: 'Help a struggling colleague',
      detail: 'Karma +2, charisma +1',
      run: (l, rng, who, score) => _with(
        l,
        'You stayed late to help a colleague hit their deadline. They told the whole team.',
        {'karma': 2, 'charisma': 1},
      ),
    ),
    ActionVariant(
      id: 'impress',
      label: 'Impress the boss',
      detail: 'Better odds of a promotion · happiness −1',
      run: (l, rng, who, score) {
        final boss = l.who('@boss');
        boss?.addFacets(respect: 4);
        final r = _with(
          l,
          'You volunteered for the project nobody wanted and delivered it early.',
          {'discipline': 2, 'happiness': -1},
        );
        return ActionResult(r.text, [
          ...r.notes,
          if (boss != null) '${_first(boss)} noticed',
          'Better odds of a raise',
        ]);
      },
    ),
  ],
  'family_dinner': [
    ActionVariant(
      id: 'simple',
      label: 'Something simple (\$20)',
      detail: 'Happiness +2 · family Bond +2',
      cost: 20,
      run: (l, rng, who, score) {
        for (final n in l.npcs.where(
          (n) =>
              n.alive &&
              (n.circle == 'Family' ||
                  n.circle == 'Children' ||
                  n.circle == 'Partner'),
        )) {
          n.addFacets(affection: 2);
          n.lastContactAge = l.age;
        }
        return _with(
          l,
          'Pasta, everyone round the table, and one argument about nothing.',
          {'happiness': 2},
          cost: 20,
        );
      },
    ),
    ActionVariant(
      id: 'feast',
      label: 'A proper feast (\$120)',
      detail: 'Happiness +4, creativity +1 · family Bond +4',
      cost: 120,
      run: (l, rng, who, score) {
        for (final n in l.npcs.where(
          (n) =>
              n.alive &&
              (n.circle == 'Family' ||
                  n.circle == 'Children' ||
                  n.circle == 'Partner'),
        )) {
          n.addFacets(affection: 4);
          n.lastContactAge = l.age;
        }
        return _with(
          l,
          'Five courses, three generations and a toast that made everyone cry.',
          {'happiness': 4, 'creativity': 1},
          cost: 120,
        );
      },
    ),
    ActionVariant(
      id: 'invite',
      label: 'Invite someone special',
      detail: 'Happiness +3 · Bond +6',
      cost: 40,
      withPerson: true,
      run: (l, rng, who, score) => _with(
        l,
        'You cooked ${_first(who)}\'s favourite. They had seconds and then thirds.',
        {'happiness': 3},
        who: who,
        together: 'the dinner you cooked for me',
        bond: 6,
        cost: 40,
      ),
    ),
  ],
  'romantic_gesture': [
    ActionVariant(
      id: 'letter',
      label: 'Write a love letter',
      detail: 'Free · Bond +4, creativity +1',
      run: (l, rng, who, score) {
        final p = l.who('@partner');
        return _with(
          l,
          '${_first(p)} read it twice and put it somewhere safe.',
          {'creativity': 1, 'happiness': 1},
          who: p,
          together: 'the letter you wrote me',
          bond: 4,
        );
      },
    ),
    ActionVariant(
      id: 'dinner',
      label: 'Dinner somewhere special (\$150)',
      detail: 'Bond +7, happiness +3',
      cost: 150,
      run: (l, rng, who, score) {
        final p = l.who('@partner');
        return _with(
          l,
          'Candles, a window table and ${_first(p)} laughing at your stories all night.',
          {'happiness': 3},
          who: p,
          together: 'our special dinner',
          bond: 7,
          cost: 150,
        );
      },
    ),
    ActionVariant(
      id: 'away',
      label: 'A surprise weekend away (\$900)',
      detail: 'Bond +12, happiness +5',
      cost: 900,
      run: (l, rng, who, score) {
        final p = l.who('@partner');
        return _with(
          l,
          'You packed their bag in secret. ${_first(p)} cried when they saw the hotel.',
          {'happiness': 5},
          who: p,
          together: 'the surprise weekend away',
          bond: 12,
          cost: 900,
        );
      },
    ),
  ],
  'prison_trade': [
    ActionVariant(
      id: 'protection',
      label: 'Buy protection',
      detail: '3 from your stash · Respect +8, safer in the yard',
      check: (l) => (l.prison?.stash ?? 0) < 3 ? 'Needs 3 in your stash' : null,
      run: (l, rng, who, score) {
        final p = l.prison!;
        p.stash -= 3;
        p.respect = min(100, p.respect + 8);
        return ActionResult(
          'Three phone cards and a jar of coffee buy you a very large friend who walks the yard with you.',
          ['Stash −3', 'Respect +8'],
        );
      },
    ),
    ActionVariant(
      id: 'call',
      label: 'Buy a phone call home',
      detail: '2 from your stash · Bond +8 with who you call',
      withPerson: true,
      check: (l) => (l.prison?.stash ?? 0) < 2 ? 'Needs 2 in your stash' : null,
      run: (l, rng, who, score) {
        l.prison!.stash -= 2;
        final b = _together(l, who, 'a phone call from prison', bond: 8);
        l.stats.add('happiness', 4);
        return ActionResult(
          'Ten minutes on a borrowed phone, crouched in a corner. ${_first(who)} cried when they heard your voice.',
          ['Stash −2', 'Happiness +4', if (b.isNotEmpty) b],
        );
      },
    ),
    ActionVariant(
      id: 'sell',
      label: 'Sell your stash',
      detail: 'Everything you hold · \$60 each, paid outside',
      check: (l) => (l.prison?.stash ?? 0) < 1 ? 'Your stash is empty' : null,
      run: (l, rng, who, score) {
        final p = l.prison!;
        final cash = p.stash * 60;
        p.stash = 0;
        l.money += cash;
        return ActionResult(
          'A cousin of a cellmate pays into your account on the outside. Nobody asks questions.',
          ['Stash sold', 'Money +${_m(cash)}'],
        );
      },
    ),
    ActionVariant(
      id: 'lend',
      label: 'Lend at interest',
      detail: '4 from your stash · double back, about 35% never repay',
      check: (l) => (l.prison?.stash ?? 0) < 4 ? 'Needs 4 in your stash' : null,
      run: (l, rng, who, score) {
        final p = l.prison!;
        p.stash -= 4;
        if (rng.nextInt(100) < 35) {
          p.respect = max(0, p.respect - 3);
          return ActionResult(
            'He swore he would pay you back by Friday. He got transferred on Thursday.',
            ['Stash −4', 'Respect −3'],
          );
        }
        p.stash += 8;
        p.respect = min(100, p.respect + 3);
        return ActionResult(
          'Paid back double, on time. Word gets round that you are good for business.',
          ['Stash +4', 'Respect +3'],
        );
      },
    ),
  ],
};

List<ActionVariant> variantsFor(String actionId) =>
    actionVariants[actionId] ?? const [];
