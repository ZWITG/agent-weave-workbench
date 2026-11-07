import 'dart:math';

import 'actions.dart';
import 'celebrity.dart' show addFame, addImage, gainFollowers;
import 'friends.dart' show meetFriend;
import 'jobs.dart' show bossOf;
import 'justice.dart' show caughtInTheAct;
import 'love.dart' show goingOut;
import 'models.dart';
import 'music.dart' show listenersOf, streamsLabel;
import 'social.dart' show followersLabel;
import 'variants.dart';
import 'world_data.dart' show countryProfile;

// Options for everyday activities that used to be a single tap: how you
// make friends, which night out, what kind of diet, which procedure, how
// you ask for a raise, which side gig, what kind of tour...

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '\$$s';
}

bool _roll(Random rng, int pct) => rng.nextInt(100) < pct;

ActionResult _paid(Life l, int cost, ActionResult r) =>
    cost <= 0 ? r : ActionResult(r.text, ['Money −${_m(cost)}', ...r.notes]);

ActionResult _stats(
  Life l,
  String text,
  Map<String, int> deltas, {
  int cost = 0,
}) {
  if (cost > 0) l.money -= cost;
  return _paid(l, cost, statChange(l, text, deltas));
}

final moreVariants = <String, List<ActionVariant>>{
  // ---------------- Social ----------------
  'make_friend': [
    for (final (id, label, detail, bonus, stat, where, cost) in const [
      (
        'club',
        'Join a sports club',
        'Meet people while getting fit',
        5,
        'athleticism',
        'at the club after training',
        30,
      ),
      (
        'volunteer',
        'Volunteer somewhere',
        'Kind people, good karma',
        0,
        'karma',
        'while volunteering at the food bank',
        0,
      ),
      (
        'neighbour',
        'Knock on a neighbour\'s door',
        'Free, a little awkward',
        -5,
        'charisma',
        'over the garden fence',
        0,
      ),
      (
        'class',
        'Take an evening class',
        'Pottery, salsa or cooking',
        10,
        'creativity',
        'in your evening class',
        60,
      ),
      (
        'online',
        'Find your people online',
        'Easy, but online friends can stay online',
        -10,
        'smarts',
        'in an online group about your favourite thing',
        0,
      ),
    ])
      ActionVariant(
        id: id,
        label: label,
        detail: cost > 0 ? '${_m(cost)} · $detail' : detail,
        cost: cost,
        minAge: id == 'class' || id == 'volunteer' ? 12 : 5,
        run: (l, rng, who, score) {
          if (cost > 0) l.money -= cost;
          if (!_roll(rng, 45 + bonus + l.stats['charisma'] ~/ 2)) {
            return _paid(
              l,
              cost,
              statChange(l, 'You tried $where. Nobody clicked this time.', {
                stat: 1,
                'happiness': -1,
              }),
            );
          }
          final f = meetFriend(l, rng);
          final r = statChange(
            l,
            'You got talking to ${f.name.split(' ').first} $where. Plans already made.',
            {'happiness': 4, stat: 2},
          );
          return _paid(
            l,
            cost,
            ActionResult(r.text, [...r.notes, '${f.name} joined your friends']),
          );
        },
      ),
  ],
  'go_out': [
    for (final (id, label, detail, extra, stats, text) in const [
      (
        'bar',
        'Drinks at a bar',
        'The classic night out',
        0,
        <String, int>{},
        '',
      ),
      (
        'club',
        'Dancing at a club',
        'Loud, late, and you will feel it tomorrow',
        40,
        {'athleticism': 1, 'health': -1},
        'You danced until the lights came on. ',
      ),
      (
        'gig',
        'A live music gig',
        'Sing along with strangers',
        30,
        {'creativity': 1},
        'The band played your song and the whole room sang. ',
      ),
      (
        'karaoke',
        'Karaoke night',
        'Charisma goes up, dignity goes down',
        0,
        {'charisma': 1},
        'You sang a power ballad with your whole chest. ',
      ),
    ])
      ActionVariant(
        id: id,
        label: label,
        detail: extra > 0 ? 'About ${_m(60 + extra)} · $detail' : detail,
        cost: 60 + extra,
        minAge: 18,
        run: (l, rng, who, score) {
          if (extra > 0) l.money -= extra;
          final r = goingOut(l, rng);
          final s = stats.isEmpty ? null : statChange(l, '', stats);
          return ActionResult('$text${r.text}', [
            if (extra > 0) 'Extra ${_m(extra)}',
            ...r.notes,
            ...?s?.notes,
          ]);
        },
      ),
  ],

  // ---------------- Health and looks ----------------
  'dentist': [
    ActionVariant(
      id: 'checkup',
      label: 'A check-up',
      detail: 'Free · health and smile',
      run: (l, rng, who, score) => statChange(
        l,
        _roll(rng, 30)
            ? 'Two fillings. The dentist sighed loudly.'
            : 'Perfect teeth. The dentist was impressed.',
        {'health': 1, 'looks': 1},
      ),
    ),
    ActionVariant(
      id: 'whitening',
      label: 'Teeth whitening',
      detail: '\$400 · a brighter smile',
      cost: 400,
      minAge: 16,
      run: (l, rng, who, score) => _stats(
        l,
        'Your smile is now visible from space. People keep asking what changed.',
        {'looks': 3, 'happiness': 2},
        cost: 400,
      ),
    ),
    ActionVariant(
      id: 'braces',
      label: 'Braces',
      detail: '\$3,000 · a year of wires, then straight teeth',
      cost: 3000,
      minAge: 10,
      check: (l) => l.flags.containsKey('braces') ? 'You have had them' : null,
      run: (l, rng, who, score) {
        l.flags['braces'] = Memory(l.age, 'getting braces');
        return _stats(
          l,
          'A year of metal and soup. When they came off, your smile was perfect.',
          {'looks': 5, 'happiness': -1},
          cost: 3000,
        );
      },
    ),
  ],
  'diet': [
    for (final (id, label, detail, bonus, win, text) in const [
      (
        'mediterranean',
        'Mediterranean',
        'Olive oil, fish, vegetables: steady and kind',
        10,
        {'health': 3, 'looks': 1},
        'Tomatoes, olive oil and grilled fish. You feel lighter and calmer.',
      ),
      (
        'plant',
        'Plant-based',
        'Good for you and the planet',
        0,
        {'health': 3, 'karma': 1},
        'Lentils have become your personality. You feel great.',
      ),
      (
        'sugar',
        'Cut out sugar',
        'Hard for a week, easy after',
        -5,
        {'health': 3, 'looks': 2},
        'Three days of headaches, then clear skin and steady energy.',
      ),
      (
        'crash',
        'A crash diet',
        'Fast results, risky for your health',
        15,
        {'looks': 3, 'health': -2},
        'You lost weight fast and felt dizzy all month.',
      ),
    ])
      ActionVariant(
        id: id,
        label: label,
        detail: detail,
        minAge: 12,
        run: (l, rng, who, score) =>
            _roll(rng, 30 + bonus + l.stats['willpower'] ~/ 2)
            ? statChange(l, text, {...win, 'willpower': 1})
            : statChange(l, 'You lasted four days. Then pizza happened.', {
                'happiness': 1,
              }),
      ),
  ],
  'plastic_surgery': [
    for (final (id, label, cost, gain, min, text) in const [
      (
        'botox',
        'Botox',
        500,
        3,
        25,
        'A few small injections. You look rested, and slightly surprised.',
      ),
      (
        'nose',
        'A nose job',
        6000,
        7,
        18,
        'The bandages came off. You keep checking the mirror.',
      ),
      (
        'veneers',
        'Veneers',
        8000,
        6,
        18,
        'A Hollywood smile, one tooth at a time.',
      ),
      (
        'facelift',
        'A facelift',
        15000,
        9,
        40,
        'Ten years younger, according to everyone who is being polite.',
      ),
    ])
      ActionVariant(
        id: id,
        label: label,
        detail: '${_m(cost)} · looks up, small risk it goes wrong',
        cost: cost,
        minAge: min,
        run: (l, rng, who, score) {
          l.money -= cost;
          if (_roll(rng, id == 'botox' ? 95 : 85)) {
            return _paid(
              l,
              cost,
              statChange(l, text, {
                'looks': gain + rng.nextInt(3),
                'happiness': 2,
              }),
            );
          }
          return _paid(
            l,
            cost,
            statChange(
              l,
              'It did not go well. It will take a year to settle, and you avoid mirrors.',
              {'looks': -gain ~/ 2 - 2, 'happiness': -5, 'health': -2},
            ),
          );
        },
      ),
  ],
  'salon': [
    for (final (id, label, cost, stats, text) in const [
      (
        'haircut',
        'A haircut',
        40,
        {'looks': 2},
        'A sharp new cut. You keep touching it.',
      ),
      (
        'spa',
        'A spa day',
        150,
        {'happiness': 5, 'stress': -8},
        'Massage, steam room and a robe you wanted to steal.',
      ),
      (
        'makeover',
        'A full makeover',
        400,
        {'looks': 5, 'happiness': 3},
        'Hair, skin, nails and brows. A stranger complimented you on the bus.',
      ),
    ])
      ActionVariant(
        id: id,
        label: label,
        detail: _m(cost),
        cost: cost,
        minAge: 12,
        run: (l, rng, who, score) {
          final s = Map<String, int>.from(stats);
          final stress = s.remove('stress') ?? 0;
          if (stress != 0) l.stress = l.stress + stress;
          return _stats(l, text, s, cost: cost);
        },
      ),
  ],
  'change_look': [
    for (final (id, label, cost, min, stats, text) in const [
      (
        'wardrobe',
        'A new wardrobe',
        80,
        13,
        {'looks': 2, 'happiness': 3},
        'A whole new wardrobe. You feel more like yourself.',
      ),
      (
        'hair',
        'Dye your hair',
        60,
        13,
        {'looks': 1, 'happiness': 3, 'creativity': 1},
        'Bright new hair colour. Your grandparents have opinions.',
      ),
      (
        'piercing',
        'Get a piercing',
        50,
        16,
        {'happiness': 3},
        'A tiny piercing and a lot of bravado.',
      ),
      (
        'tattoo',
        'Get a tattoo',
        250,
        18,
        {'happiness': 4, 'creativity': 1},
        'Three hours in the chair and a design you will love for a long time, probably.',
      ),
    ])
      ActionVariant(
        id: id,
        label: label,
        detail: _m(cost),
        cost: cost,
        minAge: min,
        run: (l, rng, who, score) {
          if (id == 'tattoo') {
            l.marks.add('tattoo:${l.age}');
          }
          final r = _stats(l, text, stats, cost: cost);
          // A new look makes you harder for witnesses to recognise (a
          // tattoo, the opposite).
          if (l.notoriety > 0 && (id == 'wardrobe' || id == 'hair')) {
            l.notoriety = max(0, l.notoriety - 2);
            return ActionResult(r.text, [
              ...r.notes,
              'Harder to recognise: heat down',
            ]);
          }
          return r;
        },
      ),
  ],
  'healer': [
    for (final (id, label, text) in const [
      (
        'acupuncture',
        'Acupuncture',
        'Tiny needles and a long, quiet hour. You felt oddly calm.',
      ),
      (
        'crystals',
        'Crystal healing',
        'Stones on your chest and a lot of confident talk.',
      ),
      (
        'herbal',
        'A herbal remedy',
        'A bag of dried leaves that smelled like a meadow.',
      ),
    ])
      ActionVariant(
        id: id,
        label: label,
        detail: '\$150 · relaxing, not a real treatment',
        cost: 150,
        minAge: 16,
        run: (l, rng, who, score) {
          l.money -= 150;
          final visits = l.marks.where((m) => m.startsWith('healer:')).length;
          l.marks.add('healer:${l.age}');
          if (_roll(rng, (id == 'herbal' ? 15 : 5) + visits * 5)) {
            l.stats.add('health', -5);
            return ActionResult(
              id == 'herbal'
                  ? 'The remedy made you violently ill. Nothing the healer does can treat a real condition.'
                  : 'You felt worse afterwards, and nothing changed. It is not a real treatment.',
              ['Money −\$150', 'Health −5'],
            );
          }
          l.stats.add('happiness', 2);
          return ActionResult('$text Your health has not changed.', [
            'Money −\$150',
            'Happiness +2',
          ]);
        },
      ),
  ],

  // ---------------- Work and money ----------------
  'ask_raise': [
    for (final (id, label, detail, bonus, fail) in const [
      (
        'polite',
        'Ask politely',
        'Safe, modest chance',
        0,
        'Your boss said "not this year". Maybe next year.',
      ),
      (
        'results',
        'Show your results',
        'Works if you have been working hard',
        10,
        'Your boss said the numbers were "fine". Not good enough, apparently.',
      ),
      (
        'offer',
        'Say you have another offer',
        'Bigger raise, or they call your bluff',
        5,
        'Your boss said: "Then you should take it." You did not have one.',
      ),
    ])
      ActionVariant(
        id: id,
        label: label,
        detail: detail,
        minAge: 16,
        run: (l, rng, who, score) {
          final odds =
              30 +
              bonus +
              l.stats['charisma'] ~/ 3 +
              l.stats['discipline'] ~/ 5 +
              (id == 'results' ? l.performance ~/ 5 - 10 : 0);
          if (_roll(rng, odds)) {
            final raise =
                (l.salary * (id == 'offer' ? 0.15 : 0.08)).round() + 500;
            l.salary += raise;
            return ActionResult(
              id == 'offer'
                  ? 'Your boss went pale and matched it. You tried very hard to look calm.'
                  : 'Your boss said yes. You tried to look calm.',
              ['Salary +${_m(raise)}/year'],
            );
          }
          if (id == 'offer') {
            l.performance = max(0, l.performance - 10);
            bossOf(l)?.addFacets(trust: -10);
          }
          return statChange(l, fail, {'happiness': -3});
        },
      ),
  ],
  'freelance': [
    for (final (id, label, stat, adult, gig) in const [
      (
        'design',
        'Design work',
        'creativity',
        true,
        'designed a logo for a café',
      ),
      ('writing', 'Writing', 'smarts', true, 'wrote copy for a website'),
      ('coding', 'Coding', 'smarts', true, 'fixed a small company\'s website'),
      (
        'delivery',
        'Deliveries',
        'athleticism',
        true,
        'delivered food all weekend',
      ),
      ('tutoring', 'Tutoring', 'smarts', true, 'tutored a student'),
      ('lawns', 'Mow lawns', 'athleticism', false, 'mowed three lawns'),
      (
        'babysit',
        'Babysit',
        'charisma',
        false,
        'babysat the neighbours\' kids',
      ),
      (
        'carwash',
        'Wash cars',
        'discipline',
        false,
        'washed cars on your street',
      ),
    ])
      ActionVariant(
        id: id,
        label: label,
        detail:
            'Pay depends on your ${stat == 'athleticism' ? 'fitness' : stat} and reviews',
        minAge: adult ? 18 : 12,
        maxAge: adult ? 200 : 17,
        run: (l, rng, who, score) {
          final rep = l.freelanceRep;
          final skill = l.stats[stat];
          final base = adult
              ? 150 + skill * 4 + rng.nextInt(250)
              : 20 + skill ~/ 2 + rng.nextInt(40);
          final pay = (base * (1 + rep / 100)).round();
          l.money += pay;
          final good =
              rng.nextInt(100) < 45 + skill ~/ 5 + l.stats['discipline'] ~/ 6;
          l.freelanceRep = (rep + (good ? 6 : -4)).clamp(0, 100);
          l.stats.add(stat, 1);
          return ActionResult('You $gig.', [
            'Money +${_m(pay)}',
            good
                ? 'A 5-star review: reputation ${l.freelanceRep}'
                : 'A grumpy review: reputation ${l.freelanceRep}',
          ]);
        },
      ),
  ],
  'part_time': [
    for (final (id, job, stat, pay) in const [
      ('cafe', 'café server', 'charisma', 1.0),
      ('shop', 'shop assistant', 'charisma', 1.0),
      ('papers', 'newspaper delivery', 'athleticism', 0.8),
      ('dogs', 'dog walker', 'athleticism', 0.9),
      ('tutor', 'tutor for younger kids', 'smarts', 1.3),
    ])
      ActionVariant(
        id: id,
        label: job[0].toUpperCase() + job.substring(1),
        detail: id == 'tutor'
            ? 'Better pay · needs Smarts 60+'
            : 'Builds ${stat == 'athleticism' ? 'fitness' : stat}',
        minAge: 14,
        check: (l) =>
            id == 'tutor' && l.stats['smarts'] < 60 ? 'Needs Smarts 60+' : null,
        run: (l, rng, who, score) {
          l.job = 'Part-time $job';
          l.salary =
              ((1500 + rng.nextInt(1500)) *
                      pay *
                      countryProfile(l.country).wage)
                  .round();
          l.stats.add(stat, 1);
          return ActionResult('You got a job as a $job.', [
            'Income +${_m(l.salary)}/year',
          ]);
        },
      ),
  ],
  'lottery': [
    for (final (id, label, cost, odds, prize) in const [
      ('scratch', 'A scratch card', 2, 2000, 1000),
      ('weekly', 'The weekly draw', 5, 100000, 250000),
      ('mega', 'The mega jackpot', 20, 10000000, 50000000),
    ])
      ActionVariant(
        id: id,
        label: label,
        detail: '${_m(cost)} · top prize ${_m(prize)}',
        cost: cost,
        minAge: 18,
        run: (l, rng, who, score) {
          l.money -= cost;
          final r = rng.nextInt(odds);
          if (r == 0) {
            l.money += prize;
            l.flags['jackpot'] = Memory(l.age, 'winning the lottery');
            l.stats.add('happiness', id == 'scratch' ? 4 : 15);
            return ActionResult(
              'You checked it three times. You won ${_m(prize)}!',
              ['Money +${_m(prize - cost)}'],
            );
          }
          // Small prizes: about one ticket in 40 wins ten times its price.
          if (r < odds ~/ 40) {
            final small = cost * 10;
            l.money += small;
            return ActionResult('A small win: ${_m(small)}.', [
              'Money +${_m(small - cost)}',
            ]);
          }
          return ActionResult('Nothing. Not even close.', [
            'Money −${_m(cost)}',
          ]);
        },
      ),
  ],
  'chores': [
    for (final (id, label, stat, text) in const [
      (
        'dishes',
        'Wash the dishes',
        'discipline',
        'You washed up without being asked twice.',
      ),
      (
        'car',
        'Wash the car',
        'athleticism',
        'The car sparkled. You were soaked.',
      ),
      (
        'garden',
        'Weed the garden',
        'discipline',
        'An afternoon of weeds and worms.',
      ),
      (
        'sibling',
        'Look after a younger cousin',
        'charisma',
        'You kept a small child alive and entertained for an afternoon.',
      ),
    ])
      ActionVariant(
        id: id,
        label: label,
        detail: 'A few dollars of pocket money',
        minAge: 6,
        run: (l, rng, who, score) {
          final pay = 5 + rng.nextInt(16) + (id == 'sibling' ? 5 : 0);
          l.money += pay;
          l.npc('mother')?.addFacets(affection: 2);
          final r = statChange(l, text, {stat: 1});
          return ActionResult(r.text, ['Money +${_m(pay)}', ...r.notes]);
        },
      ),
  ],

  // ---------------- Crime ----------------
  'graffiti': [
    for (final (id, label, risk, stats, text) in const [
      (
        'tag',
        'Tag a wall',
        0,
        {'creativity': 1, 'karma': -1},
        'Your tag is on the bus shelter now.',
      ),
      (
        'mural',
        'Paint a big mural at night',
        10,
        {'creativity': 4, 'karma': -1},
        'Your mural on the underpass is the talk of {city}.',
      ),
      (
        'protest',
        'Paint a protest message',
        15,
        {'creativity': 2, 'karma': 1},
        'Your message on the town hall wall made the local news.',
      ),
    ])
      ActionVariant(
        id: id,
        label: label,
        detail: id == 'tag'
            ? 'Quick, low risk'
            : 'Bigger art, bigger risk of getting caught',
        minAge: 12,
        run: (l, rng, who, score) {
          if (_roll(rng, 20 + risk + (l.worldMods['policing'] ?? 0))) {
            caughtInTheAct(l, 'vandalism');
            return statChange(l, 'Caught red-handed, spray can in hand.', {
              'happiness': -4,
              'karma': -2,
            });
          }
          return statChange(l, text, stats);
        },
      ),
  ],

  // ---------------- Faith ----------------
  'community_service': [
    for (final (id, label, stats, text) in const [
      (
        'gathering',
        'A community gathering',
        {'happiness': 3, 'karma': 1},
        'Shared food, old songs and people who asked how you were and meant it.',
      ),
      (
        'kitchen',
        'Serve at a soup kitchen',
        {'karma': 3, 'happiness': 2},
        'You served two hundred bowls of soup and learned a lot of names.',
      ),
      (
        'choir',
        'Sing in the choir',
        {'happiness': 3, 'creativity': 1},
        'Forty voices and one of them was yours. The hall rang.',
      ),
      (
        'festival',
        'Help run a festival',
        {'happiness': 3, 'charisma': 1},
        'You ran the raffle and sold every ticket by noon.',
      ),
    ])
      ActionVariant(
        id: id,
        label: label,
        detail: id == 'kitchen'
            ? 'Kindness, good karma'
            : 'Belonging and good company',
        minAge: id == 'kitchen' || id == 'festival' ? 12 : 4,
        run: (l, rng, who, score) {
          for (final n in l.npcs.where(
            (n) => n.alive && n.circle == 'Family',
          )) {
            n.addFacets(affection: 1);
          }
          return statChange(l, text, stats);
        },
      ),
  ],

  // ---------------- Fame and music ----------------
  'talk_show': [
    for (final (id, label, detail, stat, fame, image) in const [
      (
        'late',
        'A late-night comedy show',
        'Be funny: charisma matters',
        'charisma',
        4,
        3,
      ),
      ('morning', 'A morning show', 'Safe and friendly', 'charisma', 2, 4),
      (
        'serious',
        'A serious interview',
        'Be smart: big image swing',
        'smarts',
        3,
        8,
      ),
    ])
      ActionVariant(
        id: id,
        label: label,
        detail: detail,
        minAge: 16,
        run: (l, rng, who, score) {
          final fee = 2000 + l.fame * 150;
          l.money += fee;
          final good =
              l.stats[stat] >= 50 || _roll(rng, id == 'morning' ? 70 : 45);
          if (good) {
            addFame(l, fame);
            addImage(l, image);
            final f = gainFollowers(l, l.fame * 800);
            return ActionResult(
              id == 'serious'
                  ? 'You answered every hard question thoughtfully. People who never liked you started to.'
                  : 'You were charming and a little self-deprecating. The clip went everywhere.',
              [
                'Fee +${_m(fee)}',
                'Fame up',
                'Image up',
                '+${followersLabel(f)} followers',
              ],
            );
          }
          addFame(l, 1);
          addImage(l, -image);
          return ActionResult(
            id == 'serious'
                ? 'One answer came out very wrong. The quote is everywhere.'
                : 'You froze on a simple question. The clip did numbers, sadly.',
            ['Fee +${_m(fee)}', 'Image down'],
          );
        },
      ),
  ],
  'go_on_tour': [
    for (final (id, label, detail, size, health) in const [
      ('clubs', 'Small clubs', 'Close to the fans, gentle on you', 0.5, 2),
      ('arenas', 'An arena tour', 'Big money, hard on your body', 1.0, 4),
      ('world', 'A world tour', 'Huge money and fame, exhausting', 1.8, 8),
    ])
      ActionVariant(
        id: id,
        label: label,
        detail: detail,
        minAge: 18,
        check: (l) => id == 'world' && listenersOf(l) < 1000000 && l.fame < 60
            ? 'Needs 1M listeners or real fame'
            : null,
        run: (l, rng, who, score) {
          final tickets =
              ((listenersOf(l) * (0.3 + rng.nextDouble() * 0.3) +
                          l.fame * 800) *
                      size)
                  .round();
          final cut = l.music['label'] != null ? 0.6 : 0.8;
          final pay = (tickets * 45 * cut).round();
          l.money += pay;
          addFame(l, id == 'world' ? 6 : (id == 'arenas' ? 3 : 1));
          gainFollowers(l, tickets ~/ 2);
          l.stats.add('health', -health);
          l.stats.add('happiness', id == 'clubs' ? 6 : 4);
          return ActionResult(
            switch (id) {
              'clubs' => 'Sweaty rooms, sticky floors and fans who knew every word. You remembered why you started.',
              'world' => 'Five continents, sixty shows and a jet lag that never ended. Your name is on posters in languages you cannot read.',
              _ => 'Thirty cities, a tour bus that smelled of crisps and a crowd that knew every word.',
            },
            [
              'Money +${_m(pay)} after crew and venues',
              '${streamsLabel(tickets)} tickets sold',
              'Health −$health',
            ],
          );
        },
      ),
  ],
};
