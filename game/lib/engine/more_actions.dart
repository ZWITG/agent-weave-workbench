import 'dart:math';

import 'actions.dart';
import 'careers.dart';
import 'school.dart' show punish;
import 'economy.dart';
import 'minigame_rules.dart';
import 'health.dart' show careCost, conditionInfo;
import 'justice.dart' show caughtInTheAct, riskHint;
import 'friends.dart';
import 'life_events.dart' show easeAftermath;
import 'models.dart';
import 'world_data.dart';

/// The expanded Activities set: the genre's Activities menu (gym, doctor,
/// love, nightlife, lottery, casino, travel, licences, pets, identity, crime)
/// plus Relivable additions (hobbies, side hustles, saving, therapy).
/// Every action is free; locked ones explain why.

bool _roll(Random rng, int percent) => rng.nextInt(100) < percent;

/// Extra police patrols from world news make crime riskier.
int _police(Life life) => life.worldMods['policing'] ?? 0;

String? _notFlag(Life life, String flag, String reason) =>
    life.flags.containsKey(flag) ? reason : null;

ActionResult _pay(Life life, int cost, String text, Map<String, int> deltas) {
  life.money -= cost;
  final r = statChange(life, text, deltas);
  return ActionResult(r.text, ['Money −\$$cost', ...r.notes]);
}

final moreActions = <GameAction>[
  // ---------- Wellbeing ----------
  GameAction(
    id: 'walk',
    label: 'Go for a walk',
    category: 'Wellbeing',
    keywords: ['walk', 'outside', 'park', 'fresh air'],
    minAge: 5,
    run: (life, rng) {
      life.fitness = min(100, life.fitness + 3);
      return statChange(
        life,
        'You walked through {city} until your head felt clear.',
        {'happiness': 2, 'health': 1},
      );
    },
  ),
  GameAction(
    id: 'yoga',
    miniGame: 'timing',
    scored: yogaScored,
    label: 'Take a yoga class',
    category: 'Wellbeing',
    keywords: ['yoga', 'stretch', 'class', 'calm'],
    minAge: 14,
    cost: 15,
    run: (life, rng) {
      life.fitness = min(100, life.fitness + 4);
      return _pay(
        life,
        15,
        'You held a pose you did not know your body could do.',
        {'health': 2, 'happiness': 2, 'discipline': 1},
      );
    },
  ),
  GameAction(
    id: 'therapy',
    label: 'See a therapist',
    category: 'Wellbeing',
    keywords: ['therapy', 'therapist', 'talk', 'mental', 'stress', 'sad'],
    minAge: 12,
    run: (life, rng) {
      final cost = careCost(life, 120);
      life.money -= cost;
      final mind = life.conditions
          .where((c) => conditionInfo[c.id]?.kind == 'mind' && !c.treated)
          .firstOrNull;
      if (mind != null) {
        mind.treated = true;
        life.marks.add('therapy:${mind.id}');
      }
      final eased = easeAftermath(life);
      final r = statChange(
        life,
        mind == null
            ? 'You talked it through with a therapist. Some things got lighter.'
            : 'You started regular sessions for your ${conditionInfo[mind.id]!.name.toLowerCase()}. Your therapist said, "This is very treatable." You believed her a little.',
        {'happiness': 4 + rng.nextInt(4), 'willpower': 2},
      );
      return ActionResult(r.text, [
        if (cost > 0) 'Money −\$$cost',
        ?eased,
        ...r.notes,
      ]);
    },
  ),
  GameAction(
    id: 'salon',
    label: 'Salon and spa day',
    category: 'Wellbeing',
    keywords: ['salon', 'spa', 'haircut', 'hair', 'massage', 'nails'],
    minAge: 12,
    cost: 90,
    run: (life, rng) => _pay(
      life,
      90,
      'A new haircut and a massage. You look and feel brand new.',
      {'looks': 2 + rng.nextInt(3), 'happiness': 3},
    ),
  ),

  // ---------- Health ----------
  GameAction(
    id: 'dentist',
    label: 'Visit the dentist',
    category: 'Health',
    keywords: ['dentist', 'teeth', 'smile'],
    minAge: 3,
    run: (life, rng) => statChange(
      life,
      _roll(rng, 30)
          ? 'Two fillings. The dentist sighed loudly.'
          : 'Perfect teeth. The dentist was impressed.',
      {'health': 1, 'looks': 1},
    ),
  ),
  GameAction(
    id: 'diet',
    label: 'Start eating healthier',
    category: 'Health',
    keywords: ['diet', 'food', 'healthy', 'eat', 'vegetables'],
    minAge: 12,
    run: (life, rng) => _roll(rng, 30 + life.stats['willpower'] ~/ 2)
        ? statChange(
            life,
            'You swapped crisps for fruit and actually stuck with it.',
            {'health': 3, 'looks': 1, 'willpower': 1},
          )
        : statChange(life, 'You lasted four days. Then pizza happened.', {
            'happiness': 1,
          }),
  ),
  GameAction(
    id: 'plastic_surgery',
    label: 'Cosmetic procedure',
    category: 'Health',
    keywords: ['surgery', 'plastic', 'cosmetic', 'botox', 'nose', 'looks'],
    minAge: 18,
    cost: 2500,
    run: (life, rng) {
      life.money -= 2500;
      if (_roll(rng, 85)) {
        final r = statChange(
          life,
          'The procedure went well. You keep checking the mirror.',
          {'looks': 6 + rng.nextInt(6), 'happiness': 2},
        );
        return ActionResult(r.text, ['Money −\$2500', ...r.notes]);
      }
      final r = statChange(
        life,
        'The surgeon botched it. It will take a year to settle.',
        {'looks': -6, 'happiness': -5, 'health': -3},
      );
      return ActionResult(r.text, [
        'Money −\$2500',
        ...r.notes,
        'Why: 15% risk on every procedure',
      ]);
    },
  ),

  // ---------- Family ----------
  GameAction(
    id: 'family_dinner',
    label: 'Cook a family dinner',
    category: 'Family',
    keywords: ['cook', 'dinner', 'family', 'meal', 'food'],
    minAge: 10,
    run: (life, rng) {
      final notes = <String>[];
      for (final n in life.npcs.where((n) => n.alive)) {
        n.addBond(2);
        notes.add('Bond with ${n.name} +2');
      }
      life.stats.add('creativity', 1);
      return ActionResult(
        'You cooked dinner for everyone. {father} asked for seconds.',
        notes,
      );
    },
  ),

  // ---------- Love ----------
  GameAction(
    id: 'dating_app',
    label: 'Try a dating app',
    category: 'Love',
    keywords: ['date', 'dating', 'app', 'love', 'match', 'romance'],
    minAge: 18,
    cost: 40,
    extraCheck: (life) => _notFlag(life, 'partner', 'You\'re with Amara'),
    run: (life, rng) {
      life.money -= 40;
      final chance =
          25 + life.stats['looks'] ~/ 3 + life.stats['charisma'] ~/ 4;
      if (_roll(rng, chance)) {
        life.flags['dating'] = Memory(life.age, 'dating someone from an app');
        return statChange(
          life,
          'Your match was funny, kind and on time. Second date booked.',
          {'happiness': 6, 'charisma': 1},
        );
      }
      return statChange(
        life,
        'Your match spent the whole dinner talking about crypto.',
        {'happiness': -2},
      );
    },
  ),
  GameAction(
    id: 'romantic_gesture',
    label: 'Plan something romantic',
    category: 'Love',
    keywords: ['romantic', 'partner', 'gift', 'flowers', 'love', 'date night'],
    minAge: 18,
    cost: 120,
    extraCheck: (life) =>
        life.flags.containsKey('partner') || life.flags.containsKey('dating')
        ? null
        : 'You\'re not seeing anyone',
    run: (life, rng) => _pay(
      life,
      120,
      'A picnic at sunset. Worth every cent.',
      {'happiness': 6},
    ),
  ),

  // ---------- Social ----------
  GameAction(
    id: 'nightlife',
    label: 'Go out clubbing',
    category: 'Social',
    keywords: ['club', 'nightlife', 'dance', 'bar', 'night out', 'drinks'],
    minAge: 18,
    cost: 60,
    run: (life, rng) => _roll(rng, 75)
        ? _pay(
            life,
            60,
            'You danced until 4 a.m. Your feet will never forgive you.',
            {'happiness': 5, 'charisma': 1, 'health': -1},
          )
        : _pay(life, 60, 'The bouncer took one look and said no.', {
            'happiness': -3,
          }),
  ),
  GameAction(
    id: 'make_friend',
    label: 'Try to make a new friend',
    category: 'Social',
    keywords: ['friend', 'friends', 'lonely', 'meet', 'social'],
    minAge: 5,
    run: (life, rng) {
      if (!_roll(rng, 45 + life.stats['charisma'] ~/ 2)) {
        return statChange(life, 'You tried. It was awkward. Maybe next time.', {
          'happiness': -1,
        });
      }
      final f = meetFriend(life, rng);
      final r = statChange(
        life,
        'You clicked with ${f.name.split(' ').first} straight away. Plans already made.',
        {'happiness': 4, 'charisma': 2},
      );
      return ActionResult(r.text, [
        ...r.notes,
        '${f.name} joined your friends',
      ]);
    },
  ),
  GameAction(
    id: 'skip_class',
    label: 'Skip class',
    category: 'School',
    keywords: ['skip', 'class', 'bunk', 'truant', 'school'],
    minAge: 10,
    extraCheck: (life) =>
        life.education == 'primary' || life.education == 'secondary'
        ? null
        : 'Only while in school',
    run: (life, rng) {
      life.school.effort = 0;
      if (_roll(rng, 30)) {
        final p = punish(life, 'skipping class');
        final r = statChange(
          life,
          'The head teacher spotted you at the shopping centre. $p',
          {'happiness': -3, 'smarts': -1},
        );
        return ActionResult(r.text, [
          ...r.notes,
          'Why: caught skipping (30% chance)',
        ]);
      }
      return statChange(life, 'You spent the afternoon at the park. Bliss.', {
        'happiness': 3,
        'smarts': -1,
        'discipline': -2,
      });
    },
  ),
  GameAction(
    id: 'ask_teacher',
    label: 'Ask a teacher for help',
    category: 'School',
    keywords: ['teacher', 'help', 'tutor', 'school', 'grades'],
    minAge: 6,
    extraCheck: (life) =>
        life.education == 'primary' ||
            life.education == 'secondary' ||
            studying(life)
        ? null
        : 'Only while in school',
    run: (life, rng) => statChange(
      life,
      'Your teacher stayed after class to explain it properly.',
      {'smarts': 3, 'discipline': 1},
    ),
  ),
  GameAction(
    id: 'join_club',
    label: 'Join a school club',
    category: 'School',
    keywords: ['club', 'chess', 'debate', 'robotics', 'school', 'team'],
    minAge: 8,
    extraCheck: (life) =>
        life.education == 'primary' || life.education == 'secondary'
        ? null
        : 'Only while in school',
    run: (life, rng) {
      const clubs = [
        'chess club',
        'debate team',
        'robotics club',
        'school band',
        'football team',
      ];
      final club = clubs[rng.nextInt(clubs.length)];
      final name = club[0].toUpperCase() + club.substring(1);
      if (!life.school.clubs.contains(name)) life.school.clubs.add(name);
      return statChange(
        life,
        'You joined the $club. You belong somewhere now.',
        {
          'happiness': 3,
          'charisma': 1,
          'smarts': club == 'chess club' || club == 'robotics club' ? 2 : 0,
        },
      );
    },
  ),

  // ---------- Work ----------
  GameAction(
    id: 'work_harder',
    label: 'Work harder',
    category: 'Work',
    keywords: ['work', 'harder', 'overtime', 'effort', 'job', 'performance'],
    minAge: 14,
    extraCheck: (life) => life.job == null ? 'You don\'t have a job' : null,
    run: (life, rng) => statChange(
      life,
      'You stayed late and your manager noticed.',
      {'happiness': -2, 'discipline': 2, 'health': -1},
    ),
  ),
  GameAction(
    id: 'ask_raise',
    label: 'Ask for a raise',
    category: 'Work',
    keywords: ['raise', 'pay', 'salary', 'promotion', 'boss'],
    minAge: 16,
    extraCheck: (life) => life.job == null ? 'You don\'t have a job' : null,
    run: (life, rng) {
      if (_roll(
        rng,
        30 + life.stats['charisma'] ~/ 3 + life.stats['discipline'] ~/ 5,
      )) {
        final raise = (life.salary * 0.08).round() + 500;
        life.salary += raise;
        return ActionResult('Your boss said yes. You tried to look calm.', [
          'Salary +\$$raise/year',
        ]);
      }
      return statChange(
        life,
        'Your boss said "not this year". Maybe next year.',
        {'happiness': -3},
      );
    },
  ),
  GameAction(
    id: 'freelance',
    label: 'Do a freelance gig',
    category: 'Work',
    keywords: ['freelance', 'gig', 'side hustle', 'money', 'babysit', 'lawn'],
    minAge: 12,
    run: (life, rng) {
      final gigs = life.age < 18
          ? [
              'babysat the neighbours\' kids',
              'mowed three lawns',
              'washed cars on your street',
            ]
          : [
              'designed a logo for a café',
              'delivered food all weekend',
              'tutored a student',
            ];
      // Reviews build a reputation that raises your rates (plan CA-002).
      final rep = life.freelanceRep;
      final base =
          (life.age < 18 ? 30 : 200) + rng.nextInt(life.age < 18 ? 60 : 400);
      final pay = (base * (1 + rep / 100)).round();
      life.money += pay;
      final good = rng.nextInt(100) < 55 + life.stats['discipline'] ~/ 4;
      life.freelanceRep = (rep + (good ? 6 : -4)).clamp(0, 100);
      return ActionResult('You ${gigs[rng.nextInt(gigs.length)]}.', [
        'Money +\$$pay',
        good
            ? 'A 5-star review: reputation ${life.freelanceRep}'
            : 'A grumpy review: reputation ${life.freelanceRep}',
      ]);
    },
  ),

  // ---------- Money ----------
  GameAction(
    id: 'lottery',
    label: 'Buy a lottery ticket',
    category: 'Money',
    keywords: ['lottery', 'ticket', 'jackpot', 'gamble', 'luck'],
    minAge: 18,
    cost: 5,
    run: (life, rng) {
      life.money -= 5;
      final r = rng.nextInt(10000);
      if (r == 0) {
        life.money += 250000;
        life.flags['jackpot'] = Memory(life.age, 'winning the lottery');
        return statChange(
          life,
          'You matched every number. You won \$250,000!',
          {'happiness': 15},
        );
      }
      if (r < 120) {
        life.money += 50;
        return ActionResult('Three numbers! You won \$50.', ['Money +\$45']);
      }
      return ActionResult('Not a single number. The odds are 1 in 10,000.', [
        'Money −\$5',
      ]);
    },
  ),
  GameAction(
    id: 'casino',
    miniGame: 'cards',
    scored: casinoScored,
    label: 'Play blackjack at the casino',
    category: 'Money',
    keywords: ['casino', 'blackjack', 'gamble', 'bet', 'cards'],
    minAge: 18,
    cost: 100,
    // Gambling ages follow the country; some ban it for citizens.
    extraCheck: (life) {
      final p = countryProfile(life.country);
      if (p.gamblingBanned) return 'Gambling is illegal in ${life.country}';
      if (life.age < p.gamblingAge) return 'From age ${p.gamblingAge} here';
      return null;
    },
    run: (life, rng) {
      final won = _roll(rng, 45);
      life.money += won ? 100 : -100;
      return statChange(
        life,
        won
            ? 'Blackjack! You walked away \$100 up.'
            : 'The dealer had 21. You lost \$100.',
        {'happiness': won ? 3 : -3},
      );
    },
  ),
  GameAction(
    id: 'invest',
    label: 'Invest in an index fund',
    category: 'Money',
    keywords: ['invest', 'stocks', 'fund', 'savings', 'market', 'shares'],
    minAge: 18,
    cost: 1000,
    run: (life, rng) {
      invest(life, 1000);
      return ActionResult(
        'You put \$1,000 into an index fund. It rises and falls with the economy.',
        ['Money −\$1,000', 'See it grow on the Wealth tab'],
      );
    },
  ),

  // ---------- News ----------
  GameAction(
    id: 'newspaper',
    label: 'Buy a newspaper',
    category: 'News',
    keywords: ['news', 'newspaper', 'paper', 'headlines', 'world', 'read'],
    minAge: 8,
    repeatable: true,
    screen: 'newspaper',
    priceNote: '\$2 (free for under-18s) · re-read free all year',
    // Children read the family's copy; adults buy their own once a year.
    extraCheck: (life) =>
        life.age >= 18 &&
            !life.usedActions.contains('paper_bought') &&
            life.money < 2
        ? 'Needs \$2'
        : null,
    run: (life, rng) {
      if (life.usedActions.contains('paper_bought')) {
        return ActionResult('You picked up today\'s paper again.');
      }
      life.usedActions.add('paper_bought');
      if (life.age < 18) {
        return ActionResult('You borrowed the family\'s copy of the paper.');
      }
      life.money -= 2;
      return ActionResult('You bought the ${life.city} Chronicle.', [
        'Money −\$2',
      ]);
    },
  ),

  // ---------- Travel ----------
  GameAction(
    id: 'weekend_trip',
    label: 'Weekend trip',
    category: 'Travel',
    keywords: ['trip', 'weekend', 'travel', 'getaway', 'beach'],
    minAge: 16,
    cost: 300,
    run: (life, rng) => _pay(
      life,
      300,
      'A weekend by the sea. You came back sunburnt and happy.',
      {'happiness': 5},
    ),
  ),
  GameAction(
    id: 'vacation',
    label: 'Go on holiday abroad',
    category: 'Travel',
    keywords: ['holiday', 'vacation', 'abroad', 'travel', 'flight'],
    minAge: 18,
    cost: 1500,
    run: (life, rng) {
      const places = [
        'Japan',
        'Peru',
        'Morocco',
        'Iceland',
        'Thailand',
        'Italy',
      ];
      final place = places[rng.nextInt(places.length)];
      life.flags['visited_$place'] = Memory(life.age, 'travelling to $place');
      return _pay(
        life,
        1500,
        'Two weeks in $place. You still dream about the food.',
        {'happiness': 8, 'creativity': 2},
      );
    },
  ),

  // ---------- Hobbies ----------
  GameAction(
    id: 'instrument',
    miniGame: 'memory',
    scored: instrumentScored,
    label: 'Practise an instrument',
    category: 'Hobbies',
    keywords: [
      'instrument',
      'music',
      'guitar',
      'piano',
      'drums',
      'practise',
      'practice',
    ],
    minAge: 6,
    run: (life, rng) => statChange(
      life,
      'You practised until your fingers hurt.',
      {'creativity': 3, 'discipline': 2, 'happiness': 1},
    ),
  ),
  GameAction(
    id: 'paint',
    label: 'Paint or draw',
    category: 'Hobbies',
    keywords: ['paint', 'draw', 'art', 'sketch', 'creative'],
    minAge: 3,
    run: (life, rng) => statChange(
      life,
      'You painted something you are actually proud of.',
      {'creativity': 3, 'happiness': 2},
    ),
  ),
  GameAction(
    id: 'write_story',
    miniGame: 'memory',
    scored: storyScored,
    label: 'Write a story',
    category: 'Hobbies',
    keywords: ['write', 'story', 'book', 'novel', 'poem'],
    minAge: 8,
    run: (life, rng) => statChange(
      life,
      'You wrote a story about a city that remembers everyone who lived there.',
      {'creativity': 3, 'smarts': 1},
    ),
  ),
  GameAction(
    id: 'video_games',
    miniGame: 'reaction',
    scored: gamesScored,
    label: 'Play video games',
    category: 'Hobbies',
    keywords: ['games', 'gaming', 'video games', 'play', 'console'],
    minAge: 5,
    run: (life, rng) => statChange(
      life,
      'You lost a whole Saturday to a game. Worth it.',
      {'happiness': 3, 'discipline': -1},
    ),
  ),

  // ---------- Pets ----------
  GameAction(
    id: 'driving_lessons',
    miniGame: 'reaction',
    scored: drivingScored,
    label: 'Take driving lessons',
    category: 'Licences',
    keywords: ['driving', 'licence', 'license', 'drive', 'test', 'car'],
    minAge: 16,
    cost: 400,
    extraCheck: (life) => life.age < countryProfile(life.country).drivingAge
        ? 'From age ${countryProfile(life.country).drivingAge} here'
        : _notFlag(life, 'licence', 'You already have a licence'),
    run: (life, rng) {
      life.money -= 400;
      if (_roll(rng, 55 + life.stats['discipline'] ~/ 4)) {
        life.flags['licence'] = Memory(life.age, 'your driving licence');
        return ActionResult('You passed your driving test!', [
          'Money −\$400',
          'Driving licence',
        ]);
      }
      return ActionResult(
        'You failed the test on a roundabout. Try again next year.',
        ['Money −\$400', 'Why: nerves and a roundabout'],
      );
    },
  ),

  // ---------- Identity ----------
  GameAction(
    id: 'change_look',
    label: 'Change your style',
    category: 'Identity',
    keywords: ['style', 'clothes', 'fashion', 'look', 'tattoo', 'piercing'],
    minAge: 13,
    cost: 80,
    run: (life, rng) => _pay(
      life,
      80,
      'A whole new wardrobe. You feel more like yourself.',
      {'looks': 2, 'happiness': 3},
    ),
  ),

  // ---------- Crime ----------
  GameAction(
    id: 'pickpocket',
    miniGame: 'timing',
    scored: pickpocketScored,
    label: 'Pickpocket a stranger',
    category: 'Crime',
    hint: (l) => riskHint((35 + _police(l)).clamp(3, 95), 'minor'),
    keywords: ['pickpocket', 'steal', 'wallet', 'crime'],
    minAge: 14,
    run: (life, rng) {
      if (_roll(rng, 35 + _police(life))) {
        life.flags['arrested'] = Memory(
          life.age,
          'being arrested for pickpocketing',
        );
        caughtInTheAct(life, 'pickpocketing');
        return statChange(
          life,
          'A police officer grabbed your wrist. You spent a night in a cell.',
          {'happiness': -8, 'karma': -5},
        );
      }
      final take = 20 + rng.nextInt(120);
      life.money += take;
      return ActionResult('You lifted a wallet on the tram. \$$take inside.', [
        'Money +\$$take',
        'Karma down',
      ]);
    },
  ),
  GameAction(
    id: 'graffiti',
    label: 'Spray graffiti',
    category: 'Crime',
    hint: (l) => riskHint((25 + _police(l)).clamp(3, 95), 'minor'),
    keywords: ['graffiti', 'vandal', 'spray', 'paint', 'street art'],
    minAge: 12,
    run: (life, rng) => _roll(rng, 25 + _police(life))
        ? () {
            caughtInTheAct(life, 'vandalism');
            return statChange(life, 'Caught red-handed, spray can in hand.', {
              'happiness': -4,
              'karma': -2,
            });
          }()
        : statChange(
            life,
            'Your piece on the underpass is the talk of {city}.',
            {'creativity': 3, 'karma': -1},
          ),
  ),
];
