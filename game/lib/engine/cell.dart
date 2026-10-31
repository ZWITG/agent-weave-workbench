import 'dart:math';

import 'actions.dart';
import 'models.dart';
import 'variants.dart' show ActionVariant;

// Your cell: things you buy with your stash and keep on the shelf, each
// doing something every year you are inside. Some are allowed (a radio,
// paperbacks, photos); some are contraband (a phone, a shank, a bag of
// brew) that work better but are lost, with a penalty, if a cell search
// finds them. Everything stays behind when you are released.
//
// The yard also gives you a nickname once people know who you are, from
// what you are known for (lifting, studying, the kitchen, your crew...).

typedef CellItem = ({
  String id,
  String name,
  int price,
  bool contraband,
  String effect,
});

const cellItems = <CellItem>[
  (
    id: 'radio',
    name: 'Radio',
    price: 4,
    contraband: false,
    effect: 'Happiness +2 every year',
  ),
  (
    id: 'books',
    name: 'Shelf of paperbacks',
    price: 3,
    contraband: false,
    effect: 'Smarts +1 every year',
  ),
  (
    id: 'photos',
    name: 'Photos on the wall',
    price: 2,
    contraband: false,
    effect: 'Family stays a little closer',
  ),
  (
    id: 'hotplate',
    name: 'Hot plate',
    price: 5,
    contraband: false,
    effect: 'Health +1 a year, and noodles to sell (stash +1)',
  ),
  (
    id: 'phone',
    name: 'Smuggled phone',
    price: 8,
    contraband: true,
    effect: 'Calls home every year · contraband',
  ),
  (
    id: 'shank',
    name: 'Shank',
    price: 4,
    contraband: true,
    effect: 'Win yard fights · contraband, worst if found',
  ),
  (
    id: 'brew',
    name: 'Bag of prison brew',
    price: 3,
    contraband: true,
    effect: 'Happiness +4, health −1 a year · contraband',
  ),
];

CellItem cellItem(String id) => cellItems.firstWhere((i) => i.id == id);

bool hasItem(Life l, String id) => l.prison?.items.contains(id) ?? false;

/// "Buy for your cell": one option per item, paid from your stash.
final cellShopVariants = <ActionVariant>[
  for (final item in cellItems)
    ActionVariant(
      id: item.id,
      label: item.name,
      detail: '${item.price} from your stash · ${item.effect}',
      check: (l) {
        final p = l.prison;
        if (p == null) return 'Only in prison';
        if (p.items.contains(item.id)) return 'Already on your shelf';
        if (p.stash < item.price) return 'Needs ${item.price} in your stash';
        return null;
      },
      run: (l, rng, who, score) {
        final p = l.prison!;
        p.stash -= item.price;
        p.items.add(item.id);
        return ActionResult(
          switch (item.id) {
            'radio' => 'A battered radio with one working speaker. At night you find a station that plays old songs.',
            'books' => 'Six paperbacks with the covers falling off. You line them up on the shelf like they matter. They do.',
            'photos' => 'You tape the photos above your bunk. Faces from outside, watching over you.',
            'hotplate' => 'A hot plate from the commissary. Instant noodles have never tasted so much like freedom.',
            'phone' => 'A phone the size of your thumb, delivered inside a shoe. You hide it in the mattress.',
            'shank' =>
              'A toothbrush filed to a point. You hope you never need it.',
            _ => 'A bag of fermenting fruit and sugar under the bunk. It smells terrible.',
          },
          [
            'Stash −${item.price}',
            if (item.contraband) 'Contraband: a search could find it',
          ],
        );
      },
    ),
];

/// A year of what is on your shelf, and the cell search.
List<String> cellYear(Life l, Random rng, int searchOdds) {
  final p = l.prison!;
  final feed = <String>[];
  if (p.items.contains('radio')) l.stats.add('happiness', 2);
  if (p.items.contains('books')) l.stats.add('smarts', 1);
  if (p.items.contains('hotplate')) {
    l.stats.add('health', 1);
    p.stash += 1;
  }
  if (p.items.contains('brew')) {
    l.stats.add('happiness', 4);
    l.stats.add('health', -1);
  }
  if (p.items.contains('photos') || p.items.contains('phone')) {
    for (final n in l.npcs.where(
      (n) => n.alive && (n.circle == 'Family' || n.circle == 'Partner'),
    )) {
      n.addFacets(affection: p.items.contains('phone') ? 3 : 1);
      if (p.items.contains('phone')) n.lastContactAge = l.age;
    }
  }
  // Searches look for contraband too, not only a big stash.
  final hidden = p.items.where((i) => cellItem(i).contraband).toList();
  if (hidden.isNotEmpty && p.solitary == 0 && rng.nextInt(100) < searchOdds) {
    final found = hidden[rng.nextInt(hidden.length)];
    p.items.remove(found);
    p.behaviour = max(0, p.behaviour - 12);
    if (found == 'shank') {
      p.years += 1;
      p.solitary = max(p.solitary, 1);
      feed.add(
        'Guards tore your cell apart and found the shank. A year added to your sentence, and a year in solitary.',
      );
    } else {
      feed.add(
        'A cell search found your ${cellItem(found).name.toLowerCase()}. Confiscated, and a mark on your file.',
      );
    }
  }
  final name = earnNickname(l);
  if (name != null) {
    feed.add('The yard has started calling you "$name". It sticks.');
  }
  return feed;
}

/// Gives you a yard name once people know you (respect 55+ or two years
/// in), from what you are known for. Null if nothing new.
String? earnNickname(Life l) {
  final p = l.prison!;
  if (p.nickname != null) return null;
  if (p.respect < 55 && p.served < 2) return null;
  final name = p.snitch
      ? 'Canary'
      : p.gangId == 'iron' && p.gangRank >= 1
      ? 'Iron'
      : p.yardSets >= 4
      ? 'Bench'
      : p.courses.length >= 2 || p.degreeYears >= 2
      ? 'Professor'
      : p.job == 'Kitchen'
      ? 'Chef'
      : p.job == 'Library'
      ? 'Books'
      : p.trustee
      ? 'Keys'
      : p.gangId == 'owls'
      ? 'Owl'
      : p.gangId == 'ledger'
      ? 'Accountant'
      : p.items.contains('radio')
      ? 'DJ'
      : p.respect >= 70
      ? 'Boss'
      : 'Quiet';
  p.nickname = name;
  return name;
}
