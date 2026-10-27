import 'dart:math';

import 'models.dart';
import 'world_data.dart';

/// The people you know live their own lives. Each birthday, a few of the
/// people you're connected to get a small update in the Life feed ("Tomás
/// started a pottery class"), which is also kept on their People card.
/// One-off milestones (retiring, getting married) only happen once.

class _Update {
  const _Update(
    this.id,
    this.text, {
    this.minAge = 0,
    this.maxAge = 120,
    this.once = false,
  });
  final String id;

  /// Uses {name}, {his} (his/her), {he} (he/she), {city}, {country}, {job}.
  final String text;
  final int minAge;
  final int maxAge;
  final bool once;
}

const _parent = [
  _Update(
    'paint',
    '{name} took up painting. The kitchen now smells of turpentine.',
    minAge: 40,
  ),
  _Update(
    '10k',
    '{name} ran a 10K and has not stopped talking about it.',
    minAge: 35,
  ),
  _Update(
    'garden',
    '{name} started a vegetable garden. The courgettes are winning.',
    minAge: 35,
  ),
  _Update(
    'cruise',
    '{name} went on a cruise and came back with a tan and 400 photos.',
    minAge: 45,
  ),
  _Update(
    'emoji',
    '{name} discovered emojis and now uses the aubergine one incorrectly.',
    minAge: 40,
  ),
  _Update(
    'promo',
    '{name} got a promotion at work and celebrated with a very small cake.',
    minAge: 30,
    maxAge: 62,
  ),
  _Update(
    'retire',
    '{name} retired after decades at work. The leaving speech made everyone cry.',
    minAge: 60,
    once: true,
  ),
  _Update(
    'cat',
    '{name} adopted a grumpy rescue cat called Mister Biscuits.',
    minAge: 40,
    once: true,
  ),
  _Update(
    'choir',
    '{name} joined a local choir and sings in the shower even more now.',
    minAge: 40,
  ),
  _Update(
    'reno',
    '{name} repainted the living room a colour {he} calls "sunrise". It is orange.',
    minAge: 35,
  ),
];

const _sibling = [
  _Update(
    'hair',
    '{name} dyed {his} hair bright blue. Your parents are coping.',
    maxAge: 19,
  ),
  _Update(
    'band',
    '{name} started a band. They have one song and four T-shirts.',
    minAge: 13,
    maxAge: 25,
  ),
  _Update(
    'firstjob',
    '{name} got {his} first job, at a local café.',
    minAge: 16,
    maxAge: 22,
    once: true,
  ),
  _Update('move', '{name} moved to {city} for work.', minAge: 20, once: true),
  _Update(
    'engaged',
    '{name} got engaged. The ring was hidden in a croissant.',
    minAge: 24,
    once: true,
  ),
  _Update(
    'marathon',
    '{name} ran {his} first marathon and limped for a week.',
    minAge: 20,
  ),
  _Update(
    'podcast',
    '{name} launched a podcast. So far it has eleven listeners, including your mum.',
    minAge: 18,
  ),
  _Update(
    'travel',
    '{name} spent a month travelling around {country}.',
    minAge: 18,
  ),
  _Update(
    'dog',
    '{name} got a dog and now only posts photos of the dog.',
    minAge: 20,
    once: true,
  ),
];

const _friend = [
  _Update('newjob', '{name} started a new job as a {job}.', minAge: 18),
  _Update(
    'climb',
    '{name} took up rock climbing and has the forearms to prove it.',
    minAge: 14,
  ),
  _Update(
    'travel',
    '{name} backpacked around {country} and sent you a postcard.',
    minAge: 18,
  ),
  _Update('bake', '{name} has become obsessed with baking bread.', minAge: 16),
  _Update(
    'flat',
    '{name} moved into a new flat in {city}.',
    minAge: 19,
    once: true,
  ),
  _Update(
    'love',
    '{name} is seeing someone new and won\'t stop smiling.',
    minAge: 16,
  ),
  _Update(
    'school',
    '{name} won the school science fair with a volcano that actually worked.',
    maxAge: 15,
    once: true,
  ),
  _Update(
    'game',
    '{name} got really into a video game and has not been seen since.',
    maxAge: 25,
  ),
  _Update(
    'wed',
    '{name} got married in a small ceremony by the sea.',
    minAge: 24,
    once: true,
  ),
];

const _partner = [
  _Update(
    'promo',
    '{name} got promoted at work. You celebrated with takeaway and dancing in the kitchen.',
    minAge: 20,
  ),
  _Update('half', '{name} ran a half-marathon. You held the sign.', minAge: 18),
  _Update('class', '{name} started evening classes in design.', minAge: 18),
  _Update(
    'plant',
    '{name} bought a plant. Then nine more. The flat is now a jungle.',
    minAge: 18,
  ),
  _Update('cook', '{name} learned to make dumplings from scratch.', minAge: 18),
];

const _jobs = [
  'nurse',
  'teacher',
  'graphic designer',
  'chef',
  'software developer',
  'electrician',
  'journalist',
  'paramedic',
  'bike courier',
  'café',
];

List<_Update> _poolFor(Npc n) => switch (n.id) {
  'mother' || 'father' => _parent,
  'sibling' => _sibling,
  _ => n.circle == 'Partner' ? _partner : _friend,
};

/// Feed updates about people you're connected to: family, partners and
/// friends you still talk to. At most two a year so the feed stays calm.
List<FeedEntry> npcUpdates(Life life, Random rng) {
  final country = countryNamed(life.country);
  final out = <FeedEntry>[];
  final people =
      life.npcs
          .where(
            (n) =>
                n.alive &&
                !n.contactCut &&
                !const {
                  'Children',
                  'Lover',
                  'School',
                  'Exes',
                }.contains(n.circle) &&
                (n.circle == 'Family' || n.circle == 'Partner' || n.bond >= 40),
          )
          .toList()
        ..shuffle(rng);
  for (final n in people) {
    if (out.length >= 2) break;
    if (rng.nextInt(100) >= 30) continue;
    final age = n.ageIn(life.year);
    final options = _poolFor(n)
        .where(
          (u) =>
              age >= u.minAge &&
              age <= u.maxAge &&
              !(u.once && n.done.contains(u.id)),
        )
        .toList();
    if (options.isEmpty) continue;
    final u = options[rng.nextInt(options.length)];
    final female =
        n.id == 'mother' || n.role.contains('Sister') || n.id == 'amara';
    final text = u.text
        .replaceAll('{name}', n.name)
        .replaceAll('{his}', female ? 'her' : 'his')
        .replaceAll('{he}', female ? 'she' : 'he')
        .replaceAll(
          '{city}',
          country.cities[rng.nextInt(country.cities.length)],
        )
        .replaceAll('{country}', countries[rng.nextInt(countries.length)].name)
        .replaceAll('{job}', _jobs[rng.nextInt(_jobs.length)]);
    if (u.once) n.done.add(u.id);
    n.news.add('Age ${life.age}: $text');
    if (n.news.length > 5) n.news.removeAt(0);
    out.add(FeedEntry(life.age, text, kind: 'npc', who: n.name));
  }
  return out;
}
