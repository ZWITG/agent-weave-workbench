import 'dart:math';

import 'actions.dart';
import 'homes.dart' show homeOf;
import 'models.dart';
import 'relationships.dart';
import 'storylet.dart';

/// Pets and animals (plan Social §6): every species is free to own. Pets
/// are characters with Bond, Health, Age and a temperament; they age,
/// can be neglected, and die with a memorial. Horses can be boarded at a
/// stable instead of needing an estate; exotic animals follow country law.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '−' : ''}\$$s';
}

typedef Species = ({
  String id,
  String name,
  String group,
  int minLife,
  int maxLife,
  int shelter,
  int breeder,
  int care,
  Set<String> illegalIn,
});

const species = <Species>[
  (
    id: 'dog',
    name: 'Dog',
    group: 'common',
    minLife: 10,
    maxLife: 15,
    shelter: 150,
    breeder: 1500,
    care: 600,
    illegalIn: {},
  ),
  (
    id: 'cat',
    name: 'Cat',
    group: 'common',
    minLife: 12,
    maxLife: 18,
    shelter: 100,
    breeder: 800,
    care: 400,
    illegalIn: {},
  ),
  (
    id: 'rabbit',
    name: 'Rabbit',
    group: 'common',
    minLife: 8,
    maxLife: 12,
    shelter: 60,
    breeder: 150,
    care: 200,
    illegalIn: {},
  ),
  (
    id: 'hamster',
    name: 'Hamster',
    group: 'common',
    minLife: 2,
    maxLife: 3,
    shelter: 20,
    breeder: 30,
    care: 60,
    illegalIn: {},
  ),
  (
    id: 'guinea_pig',
    name: 'Guinea pig',
    group: 'common',
    minLife: 5,
    maxLife: 7,
    shelter: 30,
    breeder: 60,
    care: 100,
    illegalIn: {},
  ),
  (
    id: 'goldfish',
    name: 'Goldfish',
    group: 'common',
    minLife: 5,
    maxLife: 10,
    shelter: 5,
    breeder: 5,
    care: 40,
    illegalIn: {},
  ),
  (
    id: 'budgie',
    name: 'Budgie',
    group: 'common',
    minLife: 5,
    maxLife: 10,
    shelter: 30,
    breeder: 60,
    care: 60,
    illegalIn: {},
  ),
  (
    id: 'turtle',
    name: 'Turtle',
    group: 'common',
    minLife: 20,
    maxLife: 40,
    shelter: 50,
    breeder: 150,
    care: 150,
    illegalIn: {},
  ),
  (
    id: 'horse',
    name: 'Horse',
    group: 'farm',
    minLife: 25,
    maxLife: 30,
    shelter: 2000,
    breeder: 8000,
    care: 6000,
    illegalIn: {},
  ),
  (
    id: 'donkey',
    name: 'Donkey',
    group: 'farm',
    minLife: 25,
    maxLife: 35,
    shelter: 500,
    breeder: 1200,
    care: 1500,
    illegalIn: {},
  ),
  (
    id: 'goat',
    name: 'Goat',
    group: 'farm',
    minLife: 12,
    maxLife: 18,
    shelter: 200,
    breeder: 400,
    care: 300,
    illegalIn: {},
  ),
  (
    id: 'pig',
    name: 'Pig',
    group: 'farm',
    minLife: 12,
    maxLife: 18,
    shelter: 300,
    breeder: 600,
    care: 400,
    illegalIn: {},
  ),
  (
    id: 'chicken',
    name: 'Chicken',
    group: 'farm',
    minLife: 5,
    maxLife: 10,
    shelter: 20,
    breeder: 40,
    care: 50,
    illegalIn: {},
  ),
  (
    id: 'llama',
    name: 'Llama',
    group: 'farm',
    minLife: 15,
    maxLife: 25,
    shelter: 1500,
    breeder: 3000,
    care: 800,
    illegalIn: {},
  ),
  (
    id: 'snake',
    name: 'Snake',
    group: 'exotic',
    minLife: 15,
    maxLife: 25,
    shelter: 300,
    breeder: 300,
    care: 200,
    illegalIn: {},
  ),
  (
    id: 'lizard',
    name: 'Lizard',
    group: 'exotic',
    minLife: 10,
    maxLife: 20,
    shelter: 150,
    breeder: 150,
    care: 150,
    illegalIn: {},
  ),
  (
    id: 'parrot',
    name: 'Parrot',
    group: 'exotic',
    minLife: 30,
    maxLife: 60,
    shelter: 1500,
    breeder: 1500,
    care: 300,
    illegalIn: {},
  ),
  (
    id: 'tarantula',
    name: 'Tarantula',
    group: 'exotic',
    minLife: 10,
    maxLife: 25,
    shelter: 80,
    breeder: 80,
    care: 50,
    illegalIn: {},
  ),
  (
    id: 'tortoise',
    name: 'Tortoise',
    group: 'exotic',
    minLife: 50,
    maxLife: 100,
    shelter: 400,
    breeder: 400,
    care: 150,
    illegalIn: {},
  ),
  (
    id: 'fennec',
    name: 'Fennec fox',
    group: 'exotic',
    minLife: 10,
    maxLife: 14,
    shelter: 2500,
    breeder: 2500,
    care: 600,
    illegalIn: {'Australia', 'United Kingdom', 'Ireland', 'Germany'},
  ),
  (
    id: 'monkey',
    name: 'Monkey',
    group: 'exotic',
    minLife: 20,
    maxLife: 30,
    shelter: 6000,
    breeder: 6000,
    care: 2000,
    illegalIn: {
      'Portugal',
      'Ireland',
      'Netherlands',
      'United Kingdom',
      'Germany',
      'Australia',
      'Japan',
      'India',
      'Canada',
      'Brazil',
    },
  ),
];

Species speciesById(String id) =>
    species.firstWhere((s) => s.id == id, orElse: () => species.first);

const temperaments = ['Calm', 'Playful', 'Shy', 'Grumpy', 'Clever'];

const _petNames = [
  'Pip',
  'Biscuit',
  'Luna',
  'Mochi',
  'Pepper',
  'Ziggy',
  'Bean',
  'Nala',
  'Rocket',
  'Tofu',
  'Olive',
  'Maple',
  'Captain',
  'Waffles',
  'Juniper',
  'Pickle',
  'Hazel',
  'Comet',
  'Noodle',
  'Clementine',
  'Toast',
  'Fig',
];

List<Npc> petsOf(Life l) =>
    l.npcs.where((n) => n.circle == 'Pets' && n.alive).toList();

bool _isPet(Npc n) => n.circle == 'Pets';

Species speciesOf(Npc pet) => speciesById(pet.info['species'] ?? 'dog');

int petHealth(Npc pet) => (pet.info['health'] as int?) ?? 90;

void _setHealth(Npc pet, int v) => pet.info['health'] = v.clamp(0, 100);

bool isElderly(Life l, Npc pet) =>
    pet.ageIn(l.year) >= (speciesOf(pet).maxLife * 0.7).round();

String? exoticWarning(Life l, Species s) => s.illegalIn.contains(l.country)
    ? 'Illegal to own in ${l.country}: confiscation and a fine are possible'
    : null;

/// Farm animals need a home with a garden, except horses (boarding).
String? farmLock(Life l, Species s) {
  if (s.group != 'farm' || s.id == 'horse') return null;
  final home = homeOf(l);
  return home == null || home.info['garden'] != true
      ? 'Needs a home with a garden'
      : null;
}

Npc newPet(
  Life l,
  Species s,
  Random rng, {
  String? name,
  int age = 0,
  String source = 'shelter',
}) {
  final pet = Npc(
    id: 'pet_${s.id}_${l.age}_${rng.nextInt(9999)}',
    role: s.name,
    name: name ?? _petNames[rng.nextInt(_petNames.length)],
    birthYear: l.year - age,
    circle: 'Pets',
    bond: 60 + rng.nextInt(15),
  )..lastContactAge = l.age;
  pet.info.addAll({
    'species': s.id,
    'temperament': temperaments[rng.nextInt(temperaments.length)],
    'health': 90,
    'tricks': <String>[],
    'insured': false,
    'lastCare': l.age,
    'lifespan': s.minLife + rng.nextInt(s.maxLife - s.minLife + 1),
    'source': source,
  });
  return pet;
}

String adoptPet(Life l, Species s, String source, String name, Random rng) {
  final cost = source == 'breeder' ? s.breeder : s.shelter;
  l.money -= cost;
  final pet = newPet(
    l,
    s,
    rng,
    name: name,
    age: source == 'shelter' ? rng.nextInt(4) : 0,
    source: source,
  );
  l.npcs.add(pet);
  l.flags['own_pet'] = Memory(l.age, 'adopting $name');
  if (source == 'shelter') l.stats.add('karma', 2);
  l.stats.add('happiness', 5);
  final warn = exoticWarning(l, s);
  return '$name the ${s.name.toLowerCase()} (${pet.info['temperament'].toString().toLowerCase()}) came home with you${source == 'shelter' ? ' from the shelter' : ''}.${s.id == 'horse' ? ' $name lives at a stable on the edge of town.' : ''}${warn == null ? '' : ' $warn.'}';
}

/// Yearly pet costs for the cash flow (food, vet, insurance, boarding).
int petCosts(Life l) {
  var total = 0;
  for (final p in petsOf(l)) {
    total += speciesOf(p).care;
    if (p.info['insured'] == true) total += 300;
  }
  return total;
}

/// Each birthday: pets age; neglect hurts; old age and illness end lives,
/// with a memorial and gentle grief (plan acceptance: every pet dies).
List<String> petsYear(Life l, Random rng) {
  final feed = <String>[];
  for (final p in petsOf(l)) {
    final s = speciesOf(p);
    final age = p.ageIn(l.year);
    if ((p.info['lastCare'] as int? ?? l.age) < l.age - 2) {
      _setHealth(p, petHealth(p) - 10);
      p.addFacets(affection: -10);
      feed.add(
        'A welfare officer knocked about ${p.name}. Pets need care every year: walks, play, the vet.',
      );
    }
    if (isElderly(l, p)) _setHealth(p, petHealth(p) - (4 + rng.nextInt(8)));
    if (s.illegalIn.contains(l.country) && rng.nextInt(100) < 25) {
      p.alive = false;
      p.info['died'] = 'confiscated';
      l.money -= 2000;
      feed.add(
        'Animal control confiscated ${p.name}: a ${s.name.toLowerCase()} is illegal in ${l.country}. You were fined \$2,000.',
      );
      continue;
    }
    final lifespan = (p.info['lifespan'] as int?) ?? s.maxLife;
    if (age >= lifespan || petHealth(p) <= 0) {
      p.alive = false;
      p.info['diedAge'] = age;
      final memory = p.memories.isNotEmpty
          ? p.memories.last.text
          : 'curling up next to you every evening';
      l.flags['pet_memorial_${p.id}'] = Memory(
        l.age,
        'saying goodbye to ${p.name}',
      );
      l.reason = 'Losing ${p.name}';
      l.stats.add('happiness', p.bond >= 60 ? -6 : -2);
      for (final c in l.npcs.where(
        (n) => n.circle == 'Children' && n.alive && n.ageIn(l.year) < 18,
      )) {
        c.remember(
          NpcMemory(
            age: l.age,
            text: 'losing ${p.name}, our first pet',
            valence: -1,
            intensity: 2,
            tags: ['pets'],
          ),
        );
      }
      feed.add(
        '${p.name} the ${s.name.toLowerCase()} died peacefully at $age. Favourite memory: $memory. A small memorial now sits by the door.',
      );
    }
  }
  return feed;
}

ActionResult _care(
  Life l,
  Npc p,
  String text, {
  int bond = 4,
  int health = 0,
  Map<String, int> stats = const {},
}) {
  p.info['lastCare'] = l.age;
  if (health != 0) _setHealth(p, petHealth(p) + health);
  stats.forEach(l.stats.add);
  return bondResult(
    l,
    p,
    text,
    affection: bond,
    extra: [if (health != 0) '${p.name}: health ${petHealth(p)}%'],
  );
}

final petInteractions = <Interaction>[
  Interaction(
    id: 'pet_walk',
    label: 'Walk or exercise',
    group: 'Pets',
    positive: true,
    keywords: ['walk', 'exercise', 'run', 'ride'],
    only: _isPet,
    run: (l, p, k, rng) {
      l.fitness = min(100, l.fitness + 3);
      return _care(
        l,
        p,
        speciesOf(p).id == 'horse'
            ? 'You rode ${p.name} through the woods until the light went gold.'
            : 'A long walk with ${p.name}, who greeted every single tree.',
        bond: (5 * k).round(),
        health: 3,
        stats: {'happiness': 2},
      );
    },
  ),
  Interaction(
    id: 'pet_play',
    label: 'Play',
    group: 'Pets',
    positive: true,
    keywords: ['play', 'fetch', 'toy'],
    only: _isPet,
    run: (l, p, k, rng) => _care(
      l,
      p,
      p.info['temperament'] == 'Grumpy'
          ? '${p.name} tolerated the game with great dignity. That counts as fun.'
          : '${p.name} played until they fell asleep mid-pounce.',
      bond: (6 * k).round(),
      stats: {'happiness': 3},
    ),
  ),
  Interaction(
    id: 'pet_treat',
    label: 'Give a treat',
    group: 'Pets',
    positive: true,
    keywords: ['treat', 'snack', 'feed'],
    only: _isPet,
    run: (l, p, k, rng) => _care(
      l,
      p,
      '${p.name} has never loved you more. For about four minutes.',
      bond: (3 * k).round(),
    ),
  ),
  Interaction(
    id: 'pet_groom',
    label: 'Groom',
    group: 'Pets',
    positive: true,
    keywords: ['groom', 'brush', 'bath', 'clean'],
    only: _isPet,
    run: (l, p, k, rng) => _care(
      l,
      p,
      'A full groom. ${p.name} looks magnificent and slightly offended.',
      bond: (3 * k).round(),
      health: 2,
    ),
  ),
  Interaction(
    id: 'pet_train',
    label: 'Teach a trick',
    group: 'Pets',
    keywords: ['train', 'trick', 'teach', 'sit'],
    only: (n) =>
        _isPet(n) &&
        const {
          'dog',
          'parrot',
          'horse',
          'pig',
          'cat',
          'rabbit',
        }.contains(n.info['species']),
    run: (l, p, k, rng) {
      const tricks = [
        'sit',
        'paw',
        'spin',
        'play dead',
        'fetch the post',
        'wave',
        'say hello',
      ];
      final known = List<String>.from(p.info['tricks'] ?? const []);
      final odds = p.info['temperament'] == 'Clever' ? 85 : 55;
      if (rng.nextInt(100) < odds && known.length < tricks.length) {
        final t = tricks.firstWhere((t) => !known.contains(t));
        p.info['tricks'] = [...known, t];
        return _care(
          l,
          p,
          '${p.name} learned to $t! You have shown everyone.',
          bond: 4,
          stats: {'happiness': 2},
        );
      }
      return _care(
        l,
        p,
        '${p.name} looked at you, then at the treat, then lay down. Maybe next time.',
        bond: 1,
      );
    },
  ),
  Interaction(
    id: 'pet_vet',
    label: 'Vet visit',
    group: 'Pets',
    keywords: ['vet', 'checkup', 'sick', 'doctor'],
    only: _isPet,
    run: (l, p, k, rng) {
      final cost = p.info['insured'] == true ? 30 : (l.age < 18 ? 0 : 150);
      l.money -= cost;
      return _care(
        l,
        p,
        isElderly(l, p)
            ? 'The vet said ${p.name} is getting old but comfortable, and gave you a list of ways to keep them happy.'
            : 'The vet gave ${p.name} a clean bill of health and a biscuit.',
        bond: 1,
        health: 12,
      );
    },
  ),
  Interaction(
    id: 'pet_insure',
    label: 'Pet insurance (\$300/yr)',
    group: 'Pets',
    keywords: ['insurance', 'insure'],
    minAge: 18,
    only: (n) => _isPet(n) && n.info['insured'] != true,
    run: (l, p, k, rng) {
      p.info['insured'] = true;
      return ActionResult('${p.name} is insured: vet visits now cost \$30.', [
        'Pet care +\$300 a year',
      ]);
    },
  ),
  Interaction(
    id: 'pet_rehome',
    label: 'Rehome',
    group: 'Pets',
    keywords: ['rehome', 'give away'],
    only: _isPet,
    run: (l, p, k, rng) {
      p.alive = false;
      p.info['died'] = 'rehomed';
      l.stats.add('karma', -2);
      l.stats.add('happiness', -3);
      return ActionResult(
        'You found ${p.name} a new home with a family who promised to send photos. The house feels emptier.',
        ['Karma down'],
      );
    },
  ),
];

/// Pets that storylets give you (the childhood "can we get a pet?").
void storyPets(Life l) {
  void give(String flag, String sp, String? name) {
    if (!l.flags.containsKey(flag) || l.marks.contains('pet_from:$flag')) {
      return;
    }
    l.marks.add('pet_from:$flag');
    l.npcs.add(
      newPet(
        l,
        speciesById(sp),
        Random(l.seed + flag.hashCode),
        name: name,
        age: 1,
        source: 'family',
      ),
    );
  }

  give('dog_biscoito', 'dog', 'Biscoito');
  give('family_cat', 'cat', null);
}

// ---------------- Scenes ----------------

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'pets',
  scene: true,
  choices: choices,
);

Storylet? petScene(String id, List<String> args, Life l) {
  switch (id) {
    case 'pet_adopt':
      final source = args.isNotEmpty ? args.first : 'shelter';
      final group = args.length > 1 ? args[1] : 'common';
      final list = species.where((s) => s.group == group).toList();
      return _scene(
        id,
        source == 'shelter'
            ? 'The shelter smells of disinfectant and hope. Every cage has a name card and a face pressed against the bars.'
            : group == 'exotic'
            ? 'The exotic animal dealer has a warehouse, a waiting list and a very relaxed attitude to paperwork. This year\'s animals:'
            : 'The breeder shows you photos of the parents and talks about bloodlines for twenty minutes.',
        [
          for (final s
              in group == 'exotic'
                  ? (list.toList()..shuffle(Random(l.seed + l.age))).take(3)
                  : list)
            Choice(
              label:
                  '${s.name} · ${_m(source == 'breeder' ? s.breeder : s.shelter)}',
              outcome: '',
              risk:
                  exoticWarning(l, s) ??
                  farmLock(l, s) ??
                  'Lives ${s.minLife}–${s.maxLife} years · ${_m(s.care)} a year to keep${s.id == 'horse' ? ' (stable boarding)' : ''}',
              needsMoney: source == 'breeder' ? s.breeder : s.shelter,
              lock: (l) => farmLock(l, s),
              run: (l, rng) {
                l.sceneQueue.add('pet_name:${s.id}:$source');
                return 'You fell for the ${s.name.toLowerCase()} immediately.';
              },
            ),
          if (source == 'shelter' && group == 'common')
            Choice(
              label: 'Visit a breeder instead',
              outcome: '',
              run: (l, rng) {
                l.sceneQueue.add('pet_adopt:breeder:common');
                return 'You drive out to a breeder.';
              },
            ),
          Choice(
            label: 'Not today',
            outcome: 'You left with nothing but dog hair on your jumper.',
          ),
        ],
      );
    case 'pet_name':
      final s = speciesById(args.first);
      final source = args.length > 1 ? args[1] : 'shelter';
      final r = Random(l.seed + l.age * 7 + s.id.hashCode);
      final names = (_petNames.toList()..shuffle(r)).take(3);
      return _scene(
        id,
        'Your new ${s.name.toLowerCase()} is looking at you, waiting for a name.',
        [
          for (final n in names)
            Choice(
              label: n,
              outcome: '',
              run: (l, rng) => adoptPet(l, s, source, n, rng),
            ),
        ],
      );
    case 'stray':
      return _scene(
        id,
        'A thin, muddy cat has followed you home three days running and is now sitting on your doorstep like it pays rent.',
        [
          Choice(
            label: 'Let it in for good',
            outcome: '',
            run: (l, rng) {
              final pet = newPet(
                l,
                speciesById('cat'),
                rng,
                age: 2,
                source: 'stray',
              );
              l.npcs.add(pet);
              l.stats.add('karma', 3);
              l.stats.add('happiness', 4);
              return 'You named it ${pet.name}. ${pet.name} immediately took the best chair.';
            },
          ),
          Choice(
            label: 'Take it to the shelter',
            outcome: 'The shelter scanned it, fed it and promised to find it a home.',
          ),
          Choice(
            label: 'Leave out food, nothing more',
            outcome: 'It ate and left. It comes back on Tuesdays.',
          ),
        ],
      );
  }
  return null;
}

final petActions = <GameAction>[
  GameAction(
    id: 'adopt_pet',
    label: 'Adopt a pet',
    category: 'Pets',
    keywords: [
      'pet',
      'dog',
      'cat',
      'adopt',
      'shelter',
      'animal',
      'rabbit',
      'hamster',
    ],
    minAge: 12,
    priceNote: 'Shelter or breeder · from \$5',
    run: (l, rng) {
      l.sceneQueue.add('pet_adopt:shelter:common');
      return ActionResult('You visit the animal shelter.');
    },
  ),
  GameAction(
    id: 'farm_animal',
    label: 'Get a farm animal or horse',
    category: 'Pets',
    keywords: ['horse', 'farm', 'goat', 'pig', 'chicken', 'llama', 'donkey'],
    minAge: 18,
    priceNote: 'Horses can be boarded at a stable',
    run: (l, rng) {
      l.sceneQueue.add('pet_adopt:breeder:farm');
      return ActionResult('You visit a farm sale.');
    },
  ),
  GameAction(
    id: 'exotic_pet',
    label: 'Visit the exotic pet dealer',
    category: 'Pets',
    keywords: [
      'exotic',
      'snake',
      'parrot',
      'lizard',
      'tortoise',
      'monkey',
      'fox',
    ],
    minAge: 18,
    priceNote: 'Three animals a year · laws vary by country',
    run: (l, rng) {
      l.sceneQueue.add('pet_adopt:breeder:exotic');
      return ActionResult('You find the dealer\'s warehouse.');
    },
  ),
];
