import 'dart:math';

import 'actions.dart';
import 'models.dart';

/// The expanded Activities set: the genre's Activities menu (gym, doctor,
/// love, nightlife, lottery, casino, travel, licences, pets, identity, crime)
/// plus Relivable additions (hobbies, side hustles, saving, therapy).
/// Every action is free; locked ones explain why.

bool _roll(Random rng, int percent) => rng.nextInt(100) < percent;

String? _needsFlag(Life life, String flag, String reason) =>
    life.flags.containsKey(flag) ? null : reason;

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
    run: (life, rng) => statChange(
      life,
      'You walked through {city} until your head felt clear.',
      {'happiness': 2, 'health': 1},
    ),
  ),
  GameAction(
    id: 'yoga',
    label: 'Take a yoga class',
    category: 'Wellbeing',
    keywords: ['yoga', 'stretch', 'class', 'calm'],
    minAge: 14,
    cost: 15,
    run: (life, rng) => _pay(
      life,
      15,
      'You held a pose you did not know your body could do.',
      {'health': 2, 'happiness': 2, 'discipline': 1},
    ),
  ),
  GameAction(
    id: 'therapy',
    label: 'See a therapist',
    category: 'Wellbeing',
    keywords: ['therapy', 'therapist', 'talk', 'mental', 'stress', 'sad'],
    minAge: 12,
    run: (life, rng) {
      final cost = life.age >= 18 ? 60 : 0;
      life.money -= cost;
      final r = statChange(
        life,
        'You talked it through with a therapist. Some things got lighter.',
        {'happiness': 4 + rng.nextInt(4), 'willpower': 2},
      );
      return ActionResult(r.text, [if (cost > 0) 'Money −\$$cost', ...r.notes]);
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
    run: (life, rng) => _roll(rng, 45 + life.stats['charisma'] ~/ 2)
        ? statChange(
            life,
            'You clicked with someone straight away. Plans already made.',
            {'happiness': 4, 'charisma': 2},
          )
        : statChange(life, 'You tried. It was awkward. Maybe next time.', {
            'happiness': -1,
          }),
  ),
  GameAction(
    id: 'post_online',
    label: 'Post on social media',
    category: 'Social',
    keywords: ['post', 'social media', 'online', 'photo', 'viral', 'followers'],
    minAge: 13,
    run: (life, rng) {
      if (_roll(
        rng,
        8 + life.stats['looks'] ~/ 10 + life.stats['creativity'] ~/ 10,
      )) {
        life.flags['went_viral'] = Memory(life.age, 'going viral');
        return statChange(
          life,
          'Your post went viral. Strangers know your face now.',
          {'happiness': 6, 'charisma': 2},
        );
      }
      return statChange(life, 'Eleven likes. Three were from your family.', {
        'happiness': 1,
      });
    },
  ),

  // ---------- School ----------
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
    run: (life, rng) => _roll(rng, 30)
        ? statChange(
            life,
            'The head teacher spotted you at the shopping centre. Detention.',
            {'happiness': -3, 'smarts': -1},
          )
        : statChange(life, 'You spent the afternoon at the park. Bliss.', {
            'happiness': 3,
            'smarts': -1,
            'discipline': -2,
          }),
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
            life.education == 'university'
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
      final pay =
          (life.age < 18 ? 30 : 200) + rng.nextInt(life.age < 18 ? 60 : 400);
      life.money += pay;
      return ActionResult('You ${gigs[rng.nextInt(gigs.length)]}.', [
        'Money +\$$pay',
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
    label: 'Play blackjack at the casino',
    category: 'Money',
    keywords: ['casino', 'blackjack', 'gamble', 'bet', 'cards'],
    minAge: 18,
    cost: 100,
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
      final change = rng.nextInt(400) - 120;
      life.money += change;
      return ActionResult(
        change >= 0
            ? 'Your \$1,000 grew by \$$change this year.'
            : 'The market dipped. Your \$1,000 lost \$${change.abs()}.',
        [
          'Money ${change >= 0 ? '+' : '−'}\$${change.abs()}',
          'Why: markets go up and down',
        ],
      );
    },
  ),

  // ---------- Assets ----------
  GameAction(
    id: 'rent_flat',
    label: 'Rent your own flat',
    category: 'Assets',
    keywords: ['flat', 'apartment', 'rent', 'move out', 'home'],
    minAge: 18,
    cost: 1200,
    extraCheck: (life) => _notFlag(life, 'own_flat', 'You already have a flat'),
    run: (life, rng) {
      life.money -= 1200;
      life.flags['own_flat'] = Memory(life.age, 'your first flat');
      return statChange(
        life,
        'You moved into a small flat with a big window.',
        {'happiness': 5},
      );
    },
  ),
  GameAction(
    id: 'buy_house',
    label: 'Buy a house',
    category: 'Assets',
    keywords: ['house', 'home', 'mortgage', 'buy', 'property'],
    minAge: 21,
    cost: 25000,
    extraCheck: (life) {
      if (life.flags.containsKey('owns_house')) {
        return 'You already own a house';
      }
      if (life.job == null) return 'Needs a job for the mortgage';
      return null;
    },
    run: (life, rng) {
      life.money -= 25000;
      life.flags['owns_house'] = Memory(life.age, 'buying your first house');
      return statChange(
        life,
        'You put down a deposit and got the keys to a house in {city}.',
        {'happiness': 8},
      );
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
    id: 'adopt_pet',
    label: 'Adopt a pet',
    category: 'Pets',
    keywords: ['pet', 'dog', 'cat', 'adopt', 'shelter', 'animal'],
    minAge: 18,
    cost: 150,
    extraCheck: (life) => _notFlag(life, 'own_pet', 'You already have a pet'),
    run: (life, rng) {
      const pets = [
        'a scruffy terrier called Pip',
        'a one-eyed cat called Captain',
        'a lazy greyhound called Rocket',
      ];
      final pet = pets[rng.nextInt(pets.length)];
      life.flags['own_pet'] = Memory(life.age, 'adopting $pet');
      return _pay(life, 150, 'You adopted $pet from the shelter.', {
        'happiness': 6,
        'karma': 2,
      });
    },
  ),
  GameAction(
    id: 'walk_pet',
    label: 'Walk your pet',
    category: 'Pets',
    keywords: ['pet', 'walk', 'dog', 'play'],
    extraCheck: (life) =>
        _needsFlag(life, 'own_pet', 'You don\'t have a pet yet'),
    run: (life, rng) => statChange(
      life,
      'A long walk with your pet. Best part of the day.',
      {'happiness': 3, 'health': 1},
    ),
  ),

  // ---------- Licences ----------
  GameAction(
    id: 'driving_lessons',
    label: 'Take driving lessons',
    category: 'Licences',
    keywords: ['driving', 'licence', 'license', 'drive', 'test', 'car'],
    minAge: 16,
    cost: 400,
    extraCheck: (life) =>
        _notFlag(life, 'licence', 'You already have a licence'),
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
    label: 'Pickpocket a stranger',
    category: 'Crime',
    keywords: ['pickpocket', 'steal', 'wallet', 'crime'],
    minAge: 14,
    run: (life, rng) {
      if (_roll(rng, 35)) {
        life.flags['arrested'] = Memory(
          life.age,
          'being arrested for pickpocketing',
        );
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
    keywords: ['graffiti', 'vandal', 'spray', 'paint', 'street art'],
    minAge: 12,
    run: (life, rng) => _roll(rng, 25)
        ? statChange(
            life,
            'Caught red-handed. You scrubbed walls for a month.',
            {'happiness': -4, 'karma': -2},
          )
        : statChange(
            life,
            'Your piece on the underpass is the talk of {city}.',
            {'creativity': 3, 'karma': -1},
          ),
  ),
];
