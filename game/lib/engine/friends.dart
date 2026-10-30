import 'dart:math';

import 'models.dart';
import 'world_data.dart';

/// Someone you just made friends with: a local name, an age near yours,
/// added to People under Friends.
Npc meetFriend(
  Life l,
  Random rng, {
  String role = 'Friend',
  int bond = 60,
  int ageOffset = 0,
  int spread = 3,
}) {
  final c = countryNamed(l.country);
  final girl = rng.nextBool();
  final pool = girl ? c.female : c.male;
  final age = max(3, l.age + ageOffset - spread + rng.nextInt(spread * 2 + 1));
  var i = l.npcs.length;
  while (l.npcs.any((n) => n.id == 'friend_${l.age}_$i')) {
    i++;
  }
  final n = Npc(
    id: 'friend_${l.age}_$i',
    role: role,
    name:
        '${pool[rng.nextInt(pool.length)]} ${c.surnames[rng.nextInt(c.surnames.length)]}',
    birthYear: l.year - age,
    circle: 'Friends',
    bond: bond,
  )..lastContactAge = l.age;
  n.info['gender'] = girl ? 'female' : 'male';
  l.npcs.add(n);
  return n;
}
