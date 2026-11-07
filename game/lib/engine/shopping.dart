import 'dart:math';

import 'actions.dart';
import 'finance.dart' show cardLimit, creditBand;
import 'health.dart' show exposeTo;
import 'models.dart';

// The shop: departments of things with lasting effects, quality you can
// feel, daily deals and real-date sales, three ways to pay, gifts people
// love (or just politely accept), subscriptions that renew each birthday,
// and returns and second-hand sales.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '−' : ''}\$$s';
}

typedef ShopItem = ({
  String id,
  String dept,
  String name,
  int price,
  String blurb,
  Map<String, int> now,
  Map<String, int> yearly,
  int years,
  int resale,
  int minAge,
  Set<String> likes,
});

ShopItem _i(
  String id,
  String dept,
  String name,
  int price,
  String blurb, {
  Map<String, int> now = const {},
  Map<String, int> yearly = const {},
  int years = 0,
  int resale = 30,
  int minAge = 8,
  Set<String> likes = const {},
}) => (
  id: id,
  dept: dept,
  name: name,
  price: price,
  blurb: blurb,
  now: now,
  yearly: yearly,
  years: years,
  resale: resale,
  minAge: minAge,
  likes: likes,
);

const departments = <String, String>{
  'clothes': 'Clothes',
  'tech': 'Tech',
  'home': 'Home',
  'books': 'Books',
  'sport': 'Hobbies',
  'beauty': 'Health & beauty',
  'food': 'Food & drink',
  'luxury': 'Luxury',
  'gifts': 'Gifts',
  'subs': 'Subscriptions',
};

final catalogue = <ShopItem>[
  // Clothes and style
  _i(
    'basics',
    'clothes',
    'Wardrobe basics',
    120,
    'Jeans, tees and socks without holes',
    now: {'looks': 2, 'happiness': 1},
  ),
  _i(
    'outfit',
    'clothes',
    'Designer outfit',
    900,
    'Turns heads for a few years',
    now: {'looks': 4, 'happiness': 2},
    yearly: {'looks': 1},
    years: 3,
    resale: 25,
    minAge: 14,
    likes: {'teen', 'adult'},
  ),
  _i(
    'trainers',
    'clothes',
    'Running shoes',
    150,
    'Make every run a little easier',
    now: {'athleticism': 1},
    yearly: {'health': 1},
    years: 2,
    likes: {'teen', 'adult'},
  ),
  _i(
    'coat',
    'clothes',
    'Statement coat',
    400,
    'Warm, sharp and very you',
    now: {'looks': 3},
    years: 4,
    resale: 20,
    minAge: 14,
  ),
  _i(
    'perfume',
    'clothes',
    'Perfume',
    180,
    'You smell expensive',
    now: {'looks': 1, 'happiness': 1},
    minAge: 14,
    likes: {'partner', 'adult', 'elder'},
  ),
  // Tech
  _i(
    'phone_budget',
    'tech',
    'Budget phone',
    250,
    'Calls, messages and one decent camera',
    now: {'happiness': 1},
    years: 3,
    resale: 20,
    minAge: 10,
  ),
  _i(
    'phone',
    'tech',
    'Latest phone',
    1100,
    'The camera is better than your eyes',
    now: {'happiness': 4, 'charisma': 1},
    years: 3,
    resale: 35,
    minAge: 12,
    likes: {'teen'},
  ),
  _i(
    'laptop',
    'tech',
    'Laptop',
    900,
    'Smarts +1 a year while it lasts',
    now: {'happiness': 2},
    yearly: {'smarts': 1},
    years: 4,
    resale: 25,
    minAge: 10,
    likes: {'teen'},
  ),
  _i(
    'console',
    'tech',
    'Games console',
    500,
    'Happiness +1 a year · can become a habit',
    now: {'happiness': 3},
    yearly: {'happiness': 1},
    years: 5,
    resale: 30,
    minAge: 6,
    likes: {'kid', 'teen'},
  ),
  _i(
    'headphones',
    'tech',
    'Noise-cancelling headphones',
    220,
    'The world goes quiet',
    now: {'happiness': 2},
    years: 3,
    resale: 25,
    likes: {'teen', 'adult'},
  ),
  _i(
    'smartwatch',
    'tech',
    'Smartwatch',
    350,
    'Health +1 a year · nags you to stand up',
    now: {'happiness': 1},
    yearly: {'health': 1},
    years: 3,
    resale: 20,
    minAge: 14,
  ),
  // Home
  _i(
    'sofa',
    'home',
    'Very comfy sofa',
    1200,
    'Happiness +1 a year for 8 years',
    yearly: {'happiness': 1},
    years: 8,
    resale: 15,
    minAge: 18,
  ),
  _i(
    'bed',
    'home',
    'Proper mattress',
    800,
    'Health +1 a year · actual sleep',
    yearly: {'health': 1},
    years: 8,
    resale: 5,
    minAge: 18,
  ),
  _i(
    'plants',
    'home',
    'Houseplant jungle',
    90,
    'Some will survive',
    now: {'happiness': 2},
    minAge: 14,
    likes: {'elder', 'adult'},
  ),
  _i(
    'coffee',
    'home',
    'Coffee machine',
    300,
    'Happiness +1 a year · mornings fixed',
    yearly: {'happiness': 1},
    years: 5,
    resale: 20,
    minAge: 18,
    likes: {'adult'},
  ),
  _i(
    'art',
    'home',
    'Framed art print',
    150,
    'A wall worth looking at',
    now: {'creativity': 1, 'happiness': 1},
    years: 15,
    resale: 30,
    minAge: 14,
    likes: {'adult', 'elder', 'partner'},
  ),
  // Books and learning
  _i(
    'novel',
    'books',
    'A good novel',
    15,
    'Gone in a weekend',
    now: {'happiness': 1, 'smarts': 1},
    minAge: 6,
    likes: {'adult', 'elder', 'teen'},
  ),
  _i(
    'textbooks',
    'books',
    'Study guide bundle',
    120,
    'Exams feel less scary',
    now: {'smarts': 3},
    minAge: 10,
  ),
  _i(
    'course',
    'books',
    'Language course',
    300,
    'Smarts +1 a year for 2 years',
    now: {'smarts': 1},
    yearly: {'smarts': 1},
    years: 2,
    minAge: 12,
    likes: {'adult'},
  ),
  _i(
    'artkit',
    'books',
    'Art supplies',
    80,
    'Paints, pencils and a fresh sketchbook',
    now: {'creativity': 3},
    minAge: 4,
    likes: {'kid', 'teen'},
  ),
  // Sport and hobbies
  _i(
    'bike',
    'sport',
    'Bicycle',
    450,
    'Health +1 a year for 6 years',
    now: {'athleticism': 2},
    yearly: {'health': 1},
    years: 6,
    resale: 35,
    minAge: 6,
    likes: {'kid', 'teen'},
  ),
  _i(
    'guitar',
    'sport',
    'Guitar',
    350,
    'Creativity +1 a year if you practise',
    now: {'creativity': 2},
    yearly: {'creativity': 1},
    years: 10,
    resale: 45,
    minAge: 8,
    likes: {'teen'},
  ),
  _i(
    'camera',
    'sport',
    'Camera',
    700,
    'Creativity +3 · holidays look better',
    now: {'creativity': 3},
    years: 6,
    resale: 40,
    minAge: 12,
  ),
  _i(
    'boardgames',
    'sport',
    'Board game night set',
    60,
    'Friends and family come round more',
    now: {'happiness': 2},
    years: 10,
    resale: 10,
    minAge: 6,
    likes: {'kid', 'adult', 'elder'},
  ),
  _i(
    'camping',
    'sport',
    'Camping gear',
    400,
    'Tent, stove and a sleeping bag',
    now: {'happiness': 2},
    years: 8,
    resale: 30,
    minAge: 12,
  ),
  // Luxury (kept on the Wealth tab as valuables)
  _i(
    'handbag',
    'luxury',
    'Designer handbag',
    2800,
    'Keeps about half its value',
    now: {'looks': 2, 'happiness': 3},
    resale: 50,
    minAge: 16,
    likes: {'partner', 'adult'},
  ),
  _i(
    'watch',
    'luxury',
    'Luxury watch',
    8000,
    'Can gain value if you look after it',
    now: {'looks': 2, 'happiness': 3},
    resale: 75,
    minAge: 18,
    likes: {'partner', 'adult'},
  ),
  _i(
    'jewellery',
    'luxury',
    'Fine jewellery',
    2500,
    'Sparkles · resale about 55%',
    now: {'looks': 2, 'happiness': 4},
    resale: 55,
    minAge: 16,
    likes: {'partner', 'elder'},
  ),
  // Gifts
  _i(
    'flowers',
    'gifts',
    'Flowers',
    40,
    'Bright, fragrant and a little apologetic',
    minAge: 6,
    likes: {'partner', 'elder', 'adult'},
  ),
  _i(
    'chocolates',
    'gifts',
    'Box of chocolates',
    25,
    'The good ones, with the map inside',
    minAge: 4,
    likes: {'kid', 'elder', 'partner'},
  ),
  _i(
    'toy',
    'gifts',
    'Toy',
    50,
    'Loud, colourful, adored',
    minAge: 8,
    likes: {'kid'},
  ),
  _i(
    'videogame',
    'gifts',
    'Video game',
    70,
    'Gone for the weekend',
    minAge: 8,
    likes: {'kid', 'teen'},
  ),
  _i(
    'giftcard',
    'gifts',
    'Gift card',
    100,
    'Safe, if not very personal',
    minAge: 10,
    likes: {'teen'},
  ),
  _i(
    'experience',
    'gifts',
    'Experience day',
    300,
    'A spa day, a race track, a cooking class',
    minAge: 16,
    likes: {'partner', 'adult'},
  ),
  _i(
    'album',
    'gifts',
    'Photo album of memories',
    60,
    'Made by hand, page by page',
    minAge: 10,
    likes: {'elder', 'partner', 'adult'},
  ),
  // More of everything: budget, mid-range and premium in each department.
  _i(
    'charity_find',
    'clothes',
    'Charity-shop find',
    25,
    'A vintage jacket for the price of a sandwich',
    now: {'looks': 1, 'happiness': 1},
    minAge: 10,
  ),
  _i(
    'hoodie',
    'clothes',
    'Cosy hoodie',
    45,
    'The one you will live in all winter',
    now: {'happiness': 2},
    likes: {'kid', 'teen'},
  ),
  _i(
    'sunglasses',
    'clothes',
    'Sunglasses',
    90,
    'Instantly cooler, slightly squintier',
    now: {'looks': 1},
    years: 3,
    resale: 15,
    minAge: 12,
    likes: {'adult', 'teen'},
  ),
  _i(
    'boots',
    'clothes',
    'Leather boots',
    260,
    'Good boots last a decade if you polish them',
    now: {'looks': 2},
    years: 5,
    resale: 20,
    minAge: 14,
  ),
  _i(
    'suit',
    'clothes',
    'Tailored suit',
    750,
    'Interviews, weddings and funerals, sorted',
    now: {'looks': 3, 'charisma': 2},
    years: 5,
    resale: 15,
    minAge: 16,
  ),
  _i(
    'gown',
    'clothes',
    'Evening dress',
    600,
    'For the night everyone remembers',
    now: {'looks': 4, 'happiness': 2},
    years: 3,
    resale: 20,
    minAge: 16,
    likes: {'partner'},
  ),
  _i(
    'sportswear',
    'clothes',
    'Gym kit',
    80,
    'Matching kit makes the gym less scary',
    now: {'athleticism': 1},
    yearly: {'health': 1},
    years: 2,
    minAge: 12,
  ),
  _i(
    'streetwear',
    'clothes',
    'Limited-drop trainers',
    320,
    'Queued online for an hour for these',
    now: {'looks': 2, 'happiness': 3},
    years: 2,
    resale: 60,
    minAge: 13,
    likes: {'teen'},
  ),
  _i(
    'uniform_new',
    'clothes',
    'New school uniform',
    70,
    'Crisp, stiff, and two sizes too big',
    now: {'happiness': -1, 'discipline': 1},
    minAge: 5,
  ),
  _i(
    'ebook_reader',
    'tech',
    'E-reader',
    130,
    'A whole library in your bag',
    now: {'smarts': 1},
    yearly: {'smarts': 1},
    years: 4,
    resale: 20,
    minAge: 10,
    likes: {'adult', 'elder'},
  ),
  _i(
    'tablet',
    'tech',
    'Tablet',
    450,
    'Films in bed, drawing on the train',
    now: {'happiness': 2},
    yearly: {'creativity': 1},
    years: 4,
    resale: 25,
    likes: {'kid', 'teen'},
  ),
  _i(
    'gaming_pc',
    'tech',
    'Gaming PC',
    1800,
    'Glows in seven colours, runs everything',
    now: {'happiness': 5},
    yearly: {'happiness': 1},
    years: 5,
    resale: 40,
    minAge: 12,
    likes: {'teen'},
  ),
  _i(
    'vr',
    'tech',
    'VR headset',
    550,
    'You will walk into the sofa at least once',
    now: {'happiness': 3, 'athleticism': 1},
    years: 3,
    minAge: 13,
  ),
  _i(
    'speaker',
    'tech',
    'Smart speaker',
    60,
    'Plays music, sets timers, mishears you',
    now: {'happiness': 1},
    years: 4,
    resale: 10,
    minAge: 10,
  ),
  _i(
    'drone',
    'tech',
    'Camera drone',
    700,
    'Your holiday videos just got cinematic',
    now: {'creativity': 2, 'happiness': 2},
    years: 3,
    resale: 35,
    minAge: 14,
  ),
  _i(
    'earbuds',
    'tech',
    'Wireless earbuds',
    150,
    'You will lose one within a year',
    now: {'happiness': 1},
    years: 2,
    resale: 10,
    minAge: 10,
    likes: {'adult', 'teen'},
  ),
  _i(
    'camera_film',
    'tech',
    'Instant camera',
    90,
    'Photos you can hold, fridge-ready',
    now: {'creativity': 1, 'happiness': 1},
    years: 3,
    resale: 20,
    minAge: 10,
    likes: {'partner', 'teen'},
  ),
  _i(
    'candles',
    'home',
    'Scented candles',
    30,
    'The flat smells like a forest now',
    now: {'happiness': 1},
    minAge: 12,
    likes: {'adult', 'elder', 'partner'},
  ),
  _i(
    'blackout',
    'home',
    'Blackout curtains',
    110,
    'Sleep in until noon, finally',
    now: {'health': 1},
    yearly: {'health': 1},
    years: 5,
    resale: 10,
    minAge: 14,
  ),
  _i(
    'desk',
    'home',
    'Proper desk and chair',
    350,
    'Your back will thank you',
    now: {'discipline': 1},
    yearly: {'smarts': 1},
    years: 6,
    resale: 25,
    minAge: 10,
  ),
  _i(
    'kitchen_kit',
    'home',
    'Good pans and knives',
    250,
    'Cooking stops feeling like a chore',
    now: {'happiness': 1},
    yearly: {'health': 1},
    years: 6,
    resale: 20,
    minAge: 16,
  ),
  _i(
    'robot_vac',
    'home',
    'Robot vacuum',
    400,
    'It names itself. It fights the cat.',
    now: {'happiness': 2},
    years: 4,
    resale: 25,
    minAge: 18,
  ),
  _i(
    'rug',
    'home',
    'Big soft rug',
    180,
    'The room finally feels finished',
    now: {'happiness': 2},
    years: 6,
    resale: 15,
    minAge: 16,
  ),
  _i(
    'bookshelf',
    'home',
    'Bookshelf wall',
    500,
    'Room for every book you will ever buy',
    now: {'smarts': 1, 'happiness': 1},
    years: 10,
    resale: 20,
    minAge: 16,
  ),
  _i(
    'hot_tub',
    'home',
    'Hot tub',
    5500,
    'For the garden. The neighbours will hear.',
    now: {'happiness': 6},
    yearly: {'health': 1, 'happiness': 1},
    years: 8,
    minAge: 21,
  ),
  _i(
    'aircon',
    'home',
    'Air conditioning',
    1500,
    'Summer nights you can actually sleep through',
    now: {'health': 1},
    yearly: {'happiness': 1},
    years: 10,
    resale: 20,
    minAge: 18,
  ),
  _i(
    'smart_home',
    'home',
    'Smart home kit',
    600,
    'Lights, heating and locks from your phone',
    now: {'happiness': 2},
    years: 6,
    resale: 20,
    minAge: 18,
  ),
  _i(
    'comics',
    'books',
    'Comic book stack',
    20,
    'Read in one sitting, re-read for years',
    now: {'happiness': 2, 'creativity': 1},
    likes: {'kid', 'teen'},
  ),
  _i(
    'picture_book',
    'books',
    'Picture books',
    15,
    'Read aloud, three times a night',
    now: {'smarts': 1, 'happiness': 1},
    minAge: 3,
    likes: {'kid'},
  ),
  _i(
    'cookbook',
    'books',
    'Cookbook',
    30,
    'Splattered pages mean it is working',
    now: {'health': 1, 'creativity': 1},
    minAge: 12,
    likes: {'adult', 'elder', 'partner'},
  ),
  _i(
    'biography',
    'books',
    'Inspiring biography',
    20,
    'Someone else did it the hard way first',
    now: {'willpower': 2},
    minAge: 12,
    likes: {'adult', 'elder'},
  ),
  _i(
    'selfhelp',
    'books',
    'Self-help book',
    18,
    'Underlined, highlighted, half-finished',
    now: {'happiness': 1, 'discipline': 1},
    minAge: 14,
  ),
  _i(
    'encyclopedia',
    'books',
    'Illustrated encyclopaedia',
    90,
    'The answer to every question you ask at 10',
    now: {'smarts': 2},
    yearly: {'smarts': 1},
    years: 4,
    resale: 20,
    likes: {'kid'},
  ),
  _i(
    'exam_prep',
    'books',
    'Exam prep course',
    450,
    'Past papers, a tutor and a timetable',
    now: {'smarts': 3, 'discipline': 2},
    minAge: 14,
  ),
  _i(
    'coding',
    'books',
    'Coding bootcamp',
    2500,
    'Twelve weeks, a laptop sticker and a new career',
    now: {'smarts': 4},
    yearly: {'smarts': 1},
    years: 2,
    minAge: 16,
  ),
  _i(
    'masterclass',
    'books',
    'Online masterclass',
    150,
    'Learn from someone famous in their kitchen',
    now: {'creativity': 2, 'smarts': 1},
    minAge: 14,
  ),
  _i(
    'skateboard',
    'sport',
    'Skateboard',
    90,
    'Bruised knees, proud grin',
    now: {'athleticism': 2, 'happiness': 2},
    years: 3,
    likes: {'kid', 'teen'},
  ),
  _i(
    'yoga_mat',
    'sport',
    'Yoga mat and blocks',
    50,
    'Floor time, but intentional',
    now: {'health': 1},
    yearly: {'health': 1},
    years: 4,
    resale: 10,
    minAge: 12,
  ),
  _i(
    'weights',
    'sport',
    'Home weights',
    250,
    'No more queues for the bench',
    now: {'athleticism': 2},
    yearly: {'athleticism': 1, 'health': 1},
    years: 8,
    resale: 40,
    minAge: 14,
  ),
  _i(
    'fishing',
    'sport',
    'Fishing rod and tackle',
    150,
    'Patience, sold by the metre',
    now: {'happiness': 2, 'willpower': 1},
    yearly: {'happiness': 1},
    years: 6,
    resale: 25,
    minAge: 10,
    likes: {'adult', 'elder'},
  ),
  _i(
    'paints',
    'sport',
    'Oil paint set and easel',
    220,
    'Your first masterpiece is ugly. Keep going.',
    now: {'creativity': 3},
    yearly: {'creativity': 1},
    years: 4,
    resale: 20,
    minAge: 10,
  ),
  _i(
    'piano_kb',
    'sport',
    'Digital piano',
    600,
    'Headphones in, neighbours spared',
    now: {'creativity': 2},
    yearly: {'creativity': 1, 'smarts': 1},
    years: 8,
    resale: 40,
  ),
  _i(
    'golf',
    'sport',
    'Golf clubs',
    900,
    'A good walk, frequently spoiled',
    now: {'charisma': 1, 'happiness': 2},
    yearly: {'health': 1},
    years: 8,
    resale: 35,
    minAge: 14,
    likes: {'elder'},
  ),
  _i(
    'lego',
    'sport',
    'Huge building set',
    150,
    'Four thousand pieces and one missing',
    now: {'creativity': 2, 'happiness': 3},
    likes: {'adult', 'kid', 'teen'},
  ),
  _i(
    'telescope',
    'sport',
    'Telescope',
    350,
    'Saturn\'s rings from your back garden',
    now: {'smarts': 2, 'happiness': 2},
    years: 8,
    minAge: 10,
    likes: {'kid', 'teen'},
  ),
  _i(
    'kayak',
    'sport',
    'Kayak',
    800,
    'Weekends on the water',
    now: {'athleticism': 2, 'happiness': 3},
    yearly: {'health': 1},
    years: 6,
    resale: 40,
    minAge: 14,
  ),
  _i(
    'climbing',
    'sport',
    'Climbing gear',
    300,
    'Harness, shoes and a chalk bag',
    now: {'athleticism': 2, 'willpower': 1},
    yearly: {'athleticism': 1},
    years: 4,
    resale: 25,
    minAge: 12,
  ),
  _i(
    'sewing',
    'sport',
    'Sewing machine',
    200,
    'Hem trousers, then make a whole dress',
    now: {'creativity': 2},
    yearly: {'creativity': 1},
    years: 8,
    resale: 25,
    minAge: 12,
  ),
  _i(
    'skincare',
    'beauty',
    'Skincare routine',
    60,
    'Seven steps, glowing results (eventually)',
    now: {'looks': 1},
    yearly: {'looks': 1},
    years: 1,
    minAge: 12,
  ),
  _i(
    'haircut',
    'beauty',
    'Salon haircut',
    80,
    'You walked out a new person',
    now: {'looks': 3, 'happiness': 2},
    minAge: 6,
  ),
  _i(
    'makeover',
    'beauty',
    'Full makeover',
    350,
    'Hair, brows, wardrobe advice and a pep talk',
    now: {'looks': 5, 'happiness': 3, 'charisma': 1},
    minAge: 16,
  ),
  _i(
    'spa',
    'beauty',
    'Spa day',
    200,
    'Robes, steam and cucumber water',
    now: {'health': 2, 'happiness': 4},
    minAge: 16,
    likes: {'adult', 'elder', 'partner'},
  ),
  _i(
    'massage',
    'beauty',
    'Sports massage',
    70,
    'It hurts, then it really helps',
    now: {'health': 2},
    minAge: 16,
  ),
  _i(
    'vitamins',
    'beauty',
    'Vitamins and supplements',
    40,
    'Probably doing something',
    now: {'health': 1},
    years: 1,
    minAge: 14,
  ),
  _i(
    'glasses',
    'beauty',
    'Designer glasses',
    300,
    'See better, look sharper',
    now: {'looks': 2, 'smarts': 1},
    years: 4,
    resale: 5,
  ),
  _i(
    'braces',
    'beauty',
    'Teeth straightening',
    3500,
    'A year of metal, a lifetime of smiles',
    now: {'looks': 6, 'happiness': -2},
    minAge: 12,
  ),
  _i(
    'whitening',
    'beauty',
    'Teeth whitening',
    400,
    'A smile you can see from space',
    now: {'looks': 2, 'charisma': 1},
    minAge: 18,
  ),
  _i(
    'fitness_tracker',
    'beauty',
    'Fitness tracker',
    120,
    'Ten thousand steps, nagged daily',
    now: {'health': 1},
    yearly: {'health': 1, 'discipline': 1},
    years: 3,
    resale: 15,
    minAge: 12,
  ),
  _i(
    'meditation_cushion',
    'beauty',
    'Meditation corner',
    90,
    'A cushion, a candle and a quiet five minutes',
    now: {'happiness': 1},
    yearly: {'willpower': 1},
    years: 5,
    minAge: 14,
  ),
  _i(
    'tattoo',
    'beauty',
    'Tattoo',
    250,
    'Meaningful now. Ask again in twenty years.',
    now: {'looks': 1, 'happiness': 3, 'impulsivity': 2},
    minAge: 18,
  ),
  _i(
    'takeaway',
    'food',
    'Takeaway feast',
    40,
    'Too much food, no washing up',
    now: {'happiness': 2, 'health': -1},
    minAge: 10,
  ),
  _i(
    'groceries',
    'food',
    'Healthy food shop',
    90,
    'Vegetables you will actually cook',
    now: {'health': 2},
    minAge: 16,
  ),
  _i(
    'restaurant',
    'food',
    'Dinner somewhere fancy',
    180,
    'Tiny portions, huge memories',
    now: {'happiness': 4, 'charisma': 1},
    minAge: 16,
    likes: {'partner'},
  ),
  _i(
    'tasting',
    'food',
    'Tasting menu for two',
    500,
    'Twelve courses, one of them foam',
    now: {'happiness': 6},
    minAge: 18,
    likes: {'partner'},
  ),
  _i(
    'cake',
    'food',
    'Celebration cake',
    45,
    'Candles optional, joy guaranteed',
    now: {'happiness': 2},
    likes: {'elder', 'kid'},
  ),
  _i(
    'coffee_beans',
    'food',
    'Fancy coffee beans',
    25,
    'Single origin, double espresso',
    now: {'happiness': 1},
    minAge: 16,
  ),
  _i(
    'wine',
    'food',
    'Good bottle of wine',
    35,
    'Better than the one you usually get',
    now: {'happiness': 2},
    minAge: 18,
    likes: {'adult', 'elder', 'partner'},
  ),
  _i(
    'wine_case',
    'food',
    'Case of fine wine',
    600,
    'For special occasions (every Friday)',
    now: {'happiness': 3},
    years: 2,
    resale: 60,
    minAge: 18,
  ),
  _i(
    'bbq',
    'food',
    'Barbecue grill',
    300,
    'Summer weekends with everyone round',
    now: {'happiness': 2, 'charisma': 1},
    yearly: {'happiness': 1},
    years: 6,
    resale: 20,
    minAge: 18,
  ),
  _i(
    'cooking_class',
    'food',
    'Cooking class',
    120,
    'You learned to julienne. Twice.',
    now: {'creativity': 1, 'health': 1},
    minAge: 12,
  ),
  _i(
    'sweets',
    'food',
    'Pick-and-mix bag',
    8,
    'A sugar rush in a paper bag',
    now: {'happiness': 1},
    minAge: 4,
    likes: {'kid'},
  ),
  _i(
    'designer_shoes',
    'luxury',
    'Designer shoes',
    1200,
    'Red soles, sore feet, no regrets',
    now: {'looks': 3, 'happiness': 2},
    resale: 40,
    minAge: 18,
  ),
  _i(
    'diamond_ring',
    'luxury',
    'Diamond ring',
    6000,
    'A rock that lasts forever, so they say',
    now: {'happiness': 3},
    resale: 55,
    minAge: 18,
    likes: {'partner'},
  ),
  _i(
    'art_original',
    'luxury',
    'Original painting',
    15000,
    'A real canvas by a rising artist',
    now: {'happiness': 3, 'creativity': 1},
    resale: 80,
    minAge: 21,
  ),
  _i(
    'pen',
    'luxury',
    'Gold fountain pen',
    900,
    'Signing things has never felt better',
    now: {'charisma': 1},
    resale: 50,
    minAge: 18,
  ),
  _i(
    'cufflinks',
    'luxury',
    'Gold cufflinks',
    1500,
    'For the cuffs of a very good shirt',
    now: {'looks': 2},
    resale: 50,
    minAge: 18,
  ),
  _i(
    'vintage_wine',
    'luxury',
    'Vintage wine collection',
    12000,
    'Twelve bottles older than you',
    now: {'happiness': 2},
    resale: 85,
    minAge: 21,
  ),
  _i(
    'sculpture',
    'luxury',
    'Bronze sculpture',
    25000,
    'Visitors will ask about it. Every time.',
    now: {'happiness': 3},
    resale: 75,
    minAge: 25,
  ),
  _i(
    'rare_watch',
    'luxury',
    'Rare collector\'s watch',
    30000,
    'Hand-wound, numbered, waitlisted',
    now: {'happiness': 4, 'looks': 2},
    resale: 95,
    minAge: 25,
  ),
  _i(
    'fur_coat',
    'luxury',
    'Cashmere coat',
    3500,
    'Warm, light and wildly expensive',
    now: {'looks': 4},
    resale: 35,
    minAge: 18,
  ),
  _i(
    'mug',
    'gifts',
    'Funny mug',
    15,
    'Their new favourite',
    likes: {'adult', 'teen'},
  ),
  _i(
    'teddy',
    'gifts',
    'Teddy bear',
    30,
    'Soft, huggable, instantly named',
    likes: {'kid', 'partner'},
  ),
  _i(
    'perfume_gift',
    'gifts',
    'Perfume gift set',
    80,
    'The one they mentioned once, months ago',
    likes: {'adult', 'partner'},
  ),
  _i(
    'jewellery_gift',
    'gifts',
    'Silver necklace',
    150,
    'Small, shiny and thoughtful',
    likes: {'partner', 'teen'},
  ),
  _i(
    'concert',
    'gifts',
    'Concert tickets',
    180,
    'Their favourite band, front-ish row',
    likes: {'adult', 'partner', 'teen'},
  ),
  _i(
    'slippers',
    'gifts',
    'Sheepskin slippers',
    60,
    'Warm toes all winter',
    likes: {'elder'},
  ),
  _i(
    'puzzle',
    'gifts',
    'Jigsaw puzzle',
    25,
    'A thousand pieces of sky',
    likes: {'elder', 'kid'},
  ),
  _i(
    'holiday',
    'gifts',
    'Weekend away',
    900,
    'Two nights somewhere lovely',
    minAge: 18,
    likes: {'elder', 'partner'},
  ),
  _i(
    'plant_gift',
    'gifts',
    'Potted orchid',
    35,
    'Elegant, and hard to kill',
    likes: {'adult', 'elder'},
  ),
  _i(
    'pocket_money',
    'gifts',
    'Pocket money',
    20,
    'Cash in a card. Always a hit.',
    likes: {'kid', 'teen'},
  ),
];

/// Subscriptions renew each birthday and show in the cash flow.
typedef Subscription = ({
  String id,
  String name,
  int yearly,
  Map<String, int> effects,
  int minAge,
  String blurb,
});

const subscriptions = <Subscription>[
  (
    id: 'streaming',
    name: 'Streaming service',
    yearly: 180,
    effects: {'happiness': 1},
    minAge: 12,
    blurb: 'Happiness +1 a year',
  ),
  (
    id: 'music',
    name: 'Music app',
    yearly: 120,
    effects: {'happiness': 1},
    minAge: 12,
    blurb: 'Happiness +1 a year',
  ),
  (
    id: 'gym',
    name: 'Gym membership',
    yearly: 480,
    effects: {'health': 1, 'athleticism': 1},
    minAge: 16,
    blurb: 'Health and athleticism +1 a year',
  ),
  (
    id: 'mealkit',
    name: 'Meal kit deliveries',
    yearly: 2400,
    effects: {'health': 1},
    minAge: 18,
    blurb: 'Health +1 a year · no more beige dinners',
  ),
  (
    id: 'courses',
    name: 'Online courses',
    yearly: 300,
    effects: {'smarts': 1},
    minAge: 14,
    blurb: 'Smarts +1 a year',
  ),
  (
    id: 'box',
    name: 'Monthly mystery box',
    yearly: 360,
    effects: {'happiness': 1},
    minAge: 16,
    blurb: 'Happiness +1 a year · mostly socks',
  ),
  (
    id: 'news',
    name: 'News subscription',
    yearly: 90,
    effects: {'smarts': 1},
    minAge: 14,
    blurb: 'Smarts +1 a year · fewer paywalls',
  ),
  (
    id: 'cloud',
    name: 'Cloud storage',
    yearly: 60,
    effects: {},
    minAge: 12,
    blurb: 'Every photo you have ever taken, safe',
  ),
  (
    id: 'gamepass',
    name: 'Games pass',
    yearly: 150,
    effects: {'happiness': 1},
    minAge: 10,
    blurb: 'Happiness +1 a year · hundreds of games',
  ),
  (
    id: 'language_app',
    name: 'Language app premium',
    yearly: 80,
    effects: {'smarts': 1},
    minAge: 10,
    blurb: 'Smarts +1 a year · the owl is watching',
  ),
  (
    id: 'therapy',
    name: 'Therapy sessions',
    yearly: 1800,
    effects: {'happiness': 2, 'willpower': 1},
    minAge: 16,
    blurb: 'Happiness +2 a year · someone to really talk to',
  ),
  (
    id: 'yoga_studio',
    name: 'Yoga studio pass',
    yearly: 700,
    effects: {'health': 1, 'happiness': 1},
    minAge: 14,
    blurb: 'Health +1, Happiness +1 a year',
  ),
  (
    id: 'wine_club',
    name: 'Wine club',
    yearly: 480,
    effects: {'happiness': 1},
    minAge: 18,
    blurb: 'Happiness +1 a year · six bottles a quarter',
  ),
  (
    id: 'dating',
    name: 'Dating app premium',
    yearly: 240,
    effects: {'charisma': 1},
    minAge: 18,
    blurb: 'See who liked you · Charisma +1 a year',
  ),
  (
    id: 'charity',
    name: 'Monthly charity donation',
    yearly: 300,
    effects: {'karma': 2, 'happiness': 1},
    minAge: 16,
    blurb: 'Karma +2 a year · it adds up',
  ),
  (
    id: 'magazine',
    name: 'Hobby magazine',
    yearly: 50,
    effects: {'creativity': 1},
    minAge: 8,
    blurb: 'Creativity +1 a year',
  ),
  (
    id: 'vpn',
    name: 'Password manager and VPN',
    yearly: 70,
    effects: {},
    minAge: 16,
    blurb: 'Peace of mind online',
  ),
  (
    id: 'flowers_sub',
    name: 'Weekly flowers',
    yearly: 520,
    effects: {'happiness': 1},
    minAge: 18,
    blurb: 'Happiness +1 a year · the flat always smells nice',
  ),
];

/// Luxury buys that gain value over time.
const _appreciates = {
  'watch',
  'rare_watch',
  'vintage_wine',
  'art_original',
  'sculpture',
};

ShopItem? itemById(String id) => catalogue.where((i) => i.id == id).firstOrNull;
Subscription? subById(String id) =>
    subscriptions.where((s) => s.id == id).firstOrNull;

int _hash(String s) =>
    s.codeUnits.fold(11, (a, c) => (a * 31 + c) & 0x7fffffff);

// ---------------- Sales and deals ----------------

/// A sale running on this real date, if any: (name, percent off, depts).
(String, int, Set<String>)? saleOn(DateTime d) {
  final md = d.month * 100 + d.day;
  if (md >= 1120 && md <= 1130) {
    return ('Black Friday', 30, {...departments.keys}..remove('subs'));
  }
  if (md >= 1210 && md <= 1224) {
    return ('Holiday gift sale', 15, {'gifts', 'tech'});
  }
  if (md >= 1226 || md <= 105) {
    return ('New Year sale', 25, {'clothes', 'home'});
  }
  if (md >= 701 && md <= 715) return ('Summer sale', 40, {'clothes', 'sport'});
  if (md >= 820 && md <= 905) return ('Back to school', 20, {'books', 'tech'});
  return null;
}

/// Three daily deals, the same for everyone on the same day.
Map<String, int> dealsOn(DateTime d) {
  final r = Random(_hash('${d.year}-${d.month}-${d.day}'));
  final pool = catalogue.where((i) => i.dept != 'gifts').toList();
  final out = <String, int>{};
  while (out.length < 3) {
    out[pool[r.nextInt(pool.length)].id] = const [20, 30, 40][out.length];
  }
  return out;
}

/// Percent off this item today (the bigger of the sale and the deal).
int discountOn(ShopItem i, DateTime d) {
  final sale = saleOn(d);
  final fromSale = sale != null && sale.$3.contains(i.dept) ? sale.$2 : 0;
  return max(fromSale, dealsOn(d)[i.id] ?? 0);
}

int priceOf(Life l, ShopItem i, DateTime d) {
  final econ = switch (l.economy) {
    'Boom' => 1.05,
    'Recession' || 'Crash' => 0.95,
    _ => 1.0,
  };
  final p = i.price * econ * (100 - discountOn(i, d)) / 100;
  return max(1, p < 100 ? p.round() : (p / 5).round() * 5);
}

// ---------------- Paying ----------------

/// Pay in 3: a third now, the rest due in full at the next birthday.
const payLaterDebt = 'Pay later';

String? payLock(Life l, String how, int price) => switch (how) {
  'cash' => l.money >= price ? null : 'Needs ${_m(price)} in cash',
  'card' =>
    l.age < 18
        ? 'Cards open at 18'
        : (l.debts['Credit card'] ?? 0) + price > cardLimit(l)
        ? 'Over your ${_m(cardLimit(l))} card limit'
        : null,
  _ =>
    l.age < 18
        ? 'Opens at 18'
        : price < 60
        ? 'Only for \$60 or more'
        : creditBand(l.credit) == 'Poor'
        ? 'Your credit score is too low'
        : (l.debts[payLaterDebt] ?? 0) + price > 3000
        ? 'Pay later is capped at \$3,000 owed'
        : l.money < (price / 3).ceil()
        ? 'Needs ${_m((price / 3).ceil())} today'
        : null,
};

void _pay(Life l, String how, int price) {
  switch (how) {
    case 'cash':
      l.money -= price;
    case 'card':
      l.credit ??= 640;
      l.debts['Credit card'] = (l.debts['Credit card'] ?? 0) + price;
    default:
      final now = (price / 3).ceil();
      l.money -= now;
      l.credit ??= 640;
      l.debts[payLaterDebt] = (l.debts[payLaterDebt] ?? 0) + price - now;
  }
}

// ---------------- Gifts ----------------

/// Who someone is, for gift tastes.
String tasteOf(Life l, Npc n) {
  if (n.circle == 'Partner') return 'partner';
  final a = n.ageIn(l.year);
  if (a < 13) return 'kid';
  if (a < 18) return 'teen';
  if (a >= 65) return 'elder';
  return 'adult';
}

bool loves(Life l, Npc n, ShopItem i) => i.likes.contains(tasteOf(l, n));

// ---------------- Buying, returning, selling ----------------

List<Map<String, dynamic>> ownedItems(Life l) => l.items;

String? itemLock(Life l, ShopItem i) {
  if (l.age < i.minAge) return 'From age ${i.minAge}';
  if (l.prison != null) return 'Not possible in prison';
  return null;
}

ActionResult buyItem(
  Life l,
  ShopItem i, {
  String pay = 'cash',
  Npc? giftFor,
  DateTime? now,
  Random? rng,
}) {
  final d = now ?? DateTime.now();
  final price = priceOf(l, i, d);
  final off = discountOn(i, d);
  _pay(l, pay, price);
  final notes = <String>[
    switch (pay) {
      'cash' => 'Money −${_m(price)}',
      'card' => 'On your credit card: ${_m(price)} at 20% a year',
      _ =>
        'Money −${_m((price / 3).ceil())} today, ${_m(price - (price / 3).ceil())} due next birthday',
    },
    if (off > 0) 'Saved ${_m(i.price - price)} ($off% off)',
  ];
  final bought = l.marks.where((m) => m.startsWith('bought:${l.age}:')).length;
  l.marks.add('bought:${l.age}:${i.id}');
  if (giftFor != null) {
    final love = loves(l, giftFor, i);
    final gain = min(12, 3 + price ~/ 150) * (love ? 2 : 1);
    giftFor.addFacets(affection: gain, trust: love ? 2 : 0);
    giftFor.lastContactAge = l.age;
    giftFor.remember(
      NpcMemory(
        age: l.age,
        text: 'the ${i.name.toLowerCase()} you gave me',
        valence: love ? 2 : 1,
        intensity: love ? 3 : 2,
        tags: ['gift'],
      ),
    );
    l.stats.add('happiness', 1);
    final who = giftFor.name.split(' ').first;
    return ActionResult(
      love
          ? '$who unwrapped it and lit up. "How did you know?" They will remember this one.'
          : '$who said thank you and meant it, mostly. It was a kind thought.',
      [...notes, 'Bond with $who +$gain${love ? ' (they love this)' : ''}'],
    );
  }
  i.now.forEach(l.stats.add);
  notes.addAll([
    for (final e in i.now.entries)
      '${e.key[0].toUpperCase()}${e.key.substring(1)} ${e.value >= 0 ? '+' : '−'}${e.value.abs()}',
  ]);
  if (l.stats['happiness'] < 40) {
    l.stats.add('happiness', 2);
    notes.add('Retail therapy: happiness +2, for now');
  }
  if (i.dept == 'luxury') {
    l.assets.add(
      Asset(
        id: '${i.id}${l.age}_$bought',
        kind: 'valuable',
        name: i.name,
        value: (price * i.resale / 100).round(),
        yearlyCost: 0,
        since: l.age,
        // Collectables gain value; the rest slowly lose it.
        info: {'dep': _appreciates.contains(i.id) ? -2 : 3},
      ),
    );
    notes.add(
      'Kept on Wealth › What you own · worth about ${_m((price * i.resale / 100).round())}',
    );
  } else if (i.years > 0) {
    l.items.add({
      'id': i.id,
      'paid': price,
      'age': l.age,
      'left': i.years,
      'pay': pay,
    });
  }
  if (i.id == 'console' && rng != null) {
    final note = exposeTo(l, 'gaming', rng);
    if (note != null) notes.add(note);
  }
  if (bought >= 5 &&
      l.stats['impulsivity'] > 55 &&
      !l.flags.containsKey('shopaholic')) {
    l.flags['shopaholic'] = Memory(l.age, 'shopping a little too much');
    notes.add(
      'Why: that is ${bought + 1} things this year. The parcels are piling up.',
    );
  }
  return ActionResult(switch (i.dept) {
    'clothes' =>
      'You tried it on, turned around twice in the mirror and bought it.',
    'tech' => 'You peeled off the plastic film. Best moment of the week.',
    'home' => 'It took two people and some swearing to get it in, but it fits perfectly.',
    'books' => 'You started it on the bus home.',
    'sport' => 'You used it the same day. That is a good sign.',
    'luxury' => 'The shop assistant wrapped it in tissue paper like a newborn.',
    _ => 'Bought.',
  }, notes);
}

/// Things bought this year can go back for 90% (cash) or come off the card.
String? returnLock(Life l, Map<String, dynamic> item) =>
    item['age'] == l.age ? null : 'Only in the year you bought it';

ActionResult returnItem(Life l, Map<String, dynamic> item) {
  final paid = item['paid'] as int;
  final i = itemById(item['id'] as String)!;
  l.items.remove(item);
  i.now.forEach((k, v) => l.stats.add(k, -v));
  if (item['pay'] == 'card') {
    final card = (l.debts['Credit card'] ?? 0) - paid;
    if (card > 0) {
      l.debts['Credit card'] = card;
    } else {
      l.debts.remove('Credit card');
      if (card < 0) l.money -= card;
    }
    return ActionResult(
      'You returned the ${i.name.toLowerCase()} with the receipt.',
      ['Refunded ${_m(paid)} to your card'],
    );
  }
  final back = (paid * 0.9).round();
  l.money += back;
  return ActionResult(
    'You returned the ${i.name.toLowerCase()}. The restocking fee stung a little.',
    ['Money +${_m(back)}', 'Why: 10% restocking fee'],
  );
}

int resaleOf(Map<String, dynamic> item) {
  final i = itemById(item['id'] as String);
  if (i == null) return 0;
  final wear = (item['left'] as int) / max(1, i.years);
  return max(
    5,
    ((item['paid'] as int) * i.resale / 100 * (0.4 + 0.6 * wear)).round(),
  );
}

ActionResult sellItem(Life l, Map<String, dynamic> item) {
  final i = itemById(item['id'] as String)!;
  final price = resaleOf(item);
  l.items.remove(item);
  l.money += price;
  return ActionResult(
    'A buyer came round, haggled a bit and took the ${i.name.toLowerCase()} away.',
    ['Money +${_m(price)}'],
  );
}

// ---------------- Subscriptions ----------------

String? subLock(Life l, Subscription s) {
  if (l.age < s.minAge) return 'From age ${s.minAge}';
  if (l.subs.contains(s.id)) return 'Subscribed';
  return null;
}

ActionResult subscribe(Life l, Subscription s) {
  l.subs.add(s.id);
  return ActionResult('You signed up for the ${s.name.toLowerCase()}.', [
    '${_m(s.yearly)} a year, paid each birthday',
    s.blurb,
  ]);
}

ActionResult unsubscribe(Life l, Subscription s) {
  l.subs.remove(s.id);
  return ActionResult(
    'You cancelled the ${s.name.toLowerCase()}. They asked if you were sure three times.',
    ['Saves ${_m(s.yearly)} a year'],
  );
}

/// Yearly cost of every subscription (part of the cash flow).
int subscriptionCost(Life l) =>
    l.subs.fold(0, (a, id) => a + (subById(id)?.yearly ?? 0));

// ---------------- Each birthday ----------------

/// Things wear out, keep giving, or break; subscriptions renew.
List<String> shoppingYear(Life l, Random rng) {
  final feed = <String>[];
  for (final item in List<Map<String, dynamic>>.from(l.items)) {
    final i = itemById(item['id'] as String);
    if (i == null) {
      l.items.remove(item);
      continue;
    }
    i.yearly.forEach(l.stats.add);
    var left = (item['left'] as int) - 1;
    if (i.dept == 'tech' && left > 0 && rng.nextInt(100) < 6) {
      left = 0;
      feed.add('You dropped your ${i.name.toLowerCase()}. It did not survive.');
    } else if (left <= 0) {
      feed.add(
        'Your ${i.name.toLowerCase()} finally wore out after ${i.years} years.',
      );
    }
    if (left <= 0) {
      l.items.remove(item);
    } else {
      item['left'] = left;
    }
  }
  for (final id in l.subs) {
    subById(id)?.effects.forEach(l.stats.add);
  }
  if (l.flags.containsKey('shopaholic') && l.subs.length >= 4) {
    feed.add(
      'You have ${l.subs.length} subscriptions. You use about two of them.',
    );
  }
  return feed;
}

// ---------------- The activity that opens the shop ----------------

final shopAction = GameAction(
  id: 'shopping',
  label: 'Go shopping',
  category: 'Money',
  keywords: [
    'shop',
    'shopping',
    'buy',
    'clothes',
    'gift',
    'phone',
    'laptop',
    'jewellery',
    'deal',
    'sale',
    'subscription',
  ],
  minAge: 8,
  repeatable: true,
  screen: 'shop',
  hint: (l) {
    final s = saleOn(DateTime.now());
    return s != null
        ? '${s.$1}: ${s.$2}% off'
        : 'Eight departments · daily deals';
  },
  run: (l, rng) => ActionResult('You head to the shops.'),
);
