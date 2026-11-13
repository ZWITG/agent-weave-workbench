part of 'career_hub.dart';

// People in the Career Hub (docs/phase-2/03, 6.2 "Contacts" and links):
//
// - Contacts: the boss and two colleagues every job brings (jobs.dart)
//   become the career's own people: a mentor-figure (the boss), an ally
//   and a rival. They live in People like anyone else. An ally you are
//   close to puts in a word each year; a rival competes with you for the
//   same part, seat or promotion.
// - Lawyers defend people they know who are arrested.
// - Doctors treat people they know who are brought in.
// - Judges hear cases from the crime list, and sometimes someone they
//   know stands in the dock.

/// (boss, ally, rival) for each Hub career.
const hubContactRoles = <String, (String, String, String)>{
  'actor': ('Agent', 'Director who rates you', 'Rival actor'),
  'musician': ('Manager', 'Producer', 'Rival frontman'),
  'athlete': ('Head coach', 'Team captain', 'Rival for your place'),
  'model': ('Booker', 'Photographer', 'Rival model'),
  'politician': ('Party whip', 'Campaign manager', 'Opposition rival'),
  'military': ('Commanding officer', 'Section mate', 'Rival for promotion'),
  'lawyer': ('Senior partner', 'Paralegal', 'Opposing counsel'),
  'doctor': ('Consultant', 'Charge nurse', 'Rival registrar'),
  'pilot': ('Chief pilot', 'Captain you fly with', 'Rival first officer'),
  'vet': ('Practice owner', 'Veterinary nurse', 'Rival vet'),
  'hustler': ('Market old-timer', 'Fellow busker', 'Rival on the next pitch'),
  'police': ('Sergeant', 'Partner', 'Rival detective'),
};

/// Gives the workplace's people their career roles.
void _castContacts(Life l, String careerId) {
  final roles = hubContactRoles[careerId];
  if (roles == null) return;
  for (final (id, role, kind) in [
    ('boss', roles.$1, 'boss'),
    ('colleague1', roles.$2, 'ally'),
    ('colleague2', roles.$3, 'rival'),
  ]) {
    final n = l.npcs.where((n) => n.id == id && n.circle == 'Work').firstOrNull;
    if (n == null) continue;
    n.role = role;
    n.info['contact'] = kind;
    if (kind == 'rival') n.addBond(-12);
  }
}

/// The career's people, boss first, then the ally and the rival.
List<Npc> hubContacts(Life l) {
  const order = {'boss': 0, 'ally': 1, 'rival': 2};
  return l.npcs
      .where((n) => n.alive && n.circle == 'Work' && n.info['contact'] != null)
      .toList()
    ..sort(
      (a, b) => order[a.info['contact']]!.compareTo(order[b.info['contact']]!),
    );
}

Npc? _contact(Life l, String kind) =>
    hubContacts(l).where((n) => n.info['contact'] == kind).firstOrNull;

String _first(Npc n) => n.name.split(' ').first;

/// What the career's people do this year.
List<String> _peopleYear(Life l, Random rng) {
  final feed = <String>[];
  final ally = _contact(l, 'ally');
  if (ally != null &&
      ally.bond >= 70 &&
      hubSpecs[l.careerId]?.meterOf == null) {
    _bump(l, 3);
    feed.add(
      '${_first(ally)}, your ${ally.role.toLowerCase()}, put in a word for you. ${hubSpecs[l.careerId]!.meter} +3.',
    );
  }
  final rival = _contact(l, 'rival');
  if (rival != null &&
      rng.nextInt(100) < 22 &&
      !l.sceneQueue.any((q) => q.startsWith('hub:people:rival'))) {
    l.sceneQueue.add('hub:people:rival');
  }
  // People you know find you through your work.
  if (l.careerId == 'lawyer' && !isJudge(l) && rng.nextInt(100) < 14) {
    _queueKnown(l, rng, 'defend');
  }
  if (l.careerId == 'doctor' && rng.nextInt(100) < 14) {
    _queueKnown(l, rng, 'patient');
  }
  return feed;
}

/// People you know (not workmates, not pets), adults first.
List<Npc> _known(Life l) => l.npcs
    .where(
      (n) =>
          n.alive &&
          !n.contactCut &&
          n.ageIn(l.year) >= 16 &&
          const {
            'Family',
            'Friends',
            'Partner',
            'Children',
            'Lover',
          }.contains(n.circle),
    )
    .toList();

void _queueKnown(Life l, Random rng, String what) {
  final people = _known(l);
  if (people.isEmpty) return;
  final n = people[rng.nextInt(people.length)];
  l.sceneQueue.add('hub:people:$what:${n.id}:${rng.nextInt(1000)}');
}

/// What the rival is competing with you for.
String _prize(String id) => switch (id) {
  'actor' => 'the same lead role',
  'musician' => 'the same festival headline slot',
  'athlete' => 'your place in the starting line-up',
  'model' => 'the same campaign',
  'politician' => 'your seat',
  'military' => 'the same promotion',
  'lawyer' => 'the same big client',
  'doctor' => 'the same consultant post',
  'pilot' => 'the same captaincy',
  'vet' => 'the same farm contracts',
  'hustler' => 'the best pitch in town',
  _ => 'the same promotion',
};

Storylet? _rivalScene(Life l) {
  final rival = _contact(l, 'rival');
  final spec = hubSpecs[l.careerId];
  if (rival == null || spec == null) return null;
  final who = _first(rival);
  return _scene(
    'people_rival',
    '$who, your ${rival.role.toLowerCase()}, is going for ${_prize(l.careerId!)}. Everyone knows only one of you can have it.',
    [
      Choice(
        label: 'Beat them fair and square',
        outcome: '',
        risk: 'Depends on your ${spec.meter}',
        run: (l, rng) {
          if (rng.nextInt(100) < 30 + hubMeter(l) ~/ 2) {
            _bump(l, 6);
            rival.addBond(-4);
            _log(l, 'beat $who to ${_prize(l.careerId!)}');
            return 'You won it. $who shook your hand a second too long. ${spec.meter} +6.';
          }
          _bump(l, -3);
          rival.addBond(2);
          return '$who got it. You sent a card. You meant about half of it. ${spec.meter} −3.';
        },
      ),
      Choice(
        label: 'Undermine them quietly',
        outcome: '',
        risk: 'Could backfire badly',
        run: (l, rng) {
          l.stats.add('karma', -4);
          if (rng.nextInt(100) < 55) {
            _bump(l, 8);
            rival.addBond(-25);
            rival.remember(
              NpcMemory(
                age: l.age,
                text: 'you undermined them at work',
                valence: -3,
                intensity: 4,
              ),
            );
            return 'A rumour here, a missed email there. It worked, and $who will never forgive you. ${spec.meter} +8.';
          }
          _bump(l, -10);
          rival.addBond(-20);
          return 'It came out who started the rumour. ${spec.meter} −10, and $who is telling everyone.';
        },
      ),
      Choice(
        label: 'Back them for it',
        outcome: '',
        run: (l, rng) {
          l.stats.add('karma', 3);
          rival.addBond(25);
          rival.remember(
            NpcMemory(
              age: l.age,
              text: 'you backed them when you did not have to',
              valence: 3,
              intensity: 3,
            ),
          );
          if (rival.bond >= 60) {
            rival.info['contact'] = 'ally';
            rival.role = rival.role.replaceFirst('Rival', 'Friendly rival');
            return '$who got it, and did not forget who backed them. The rivalry is over: you have an ally now.';
          }
          return '$who got it and looked at you differently afterwards. Maybe not a rival for ever.';
        },
      ),
    ],
  );
}

Npc? _npc(Life l, String id) =>
    l.npcs.where((n) => n.id == id && n.alive).firstOrNull;

/// Crimes someone you know might be charged with (justice.dart's list).
const _chargeable = [
  'shoplifting',
  'vandalism',
  'burglary',
  'car_theft',
  'fraud',
  'assault',
  'tax_evasion',
  'street_racing',
  'insurance_fraud',
  'identity_theft',
];

String _crimeLabel(String id) =>
    crimes.where((c) => c.id == id).firstOrNull?.label.toLowerCase() ?? id;

String _crimeBand(String id) =>
    crimes.where((c) => c.id == id).firstOrNull?.band ?? 'moderate';

Storylet? _defendScene(Life l, String npcId, int seed) {
  final n = _npc(l, npcId);
  if (n == null) return null;
  final crime = _chargeable[seed % _chargeable.length];
  final label = _crimeLabel(crime);
  final who = _first(n);
  final minor = _crimeBand(crime) == 'minor';
  String verdict(Life l, Random rng, int odds, String how) {
    if (rng.nextInt(100) < odds) {
      n.addBond(18);
      n.remember(
        NpcMemory(
          age: l.age,
          text: 'you got them off a charge of $label',
          valence: 3,
          intensity: 5,
        ),
      );
      _log(l, 'cleared $who of $label');
      return '$how Not guilty. $who cried on the court steps and has told everyone you are a genius.';
    }
    final years = minor ? 0 : 1 + (seed % 3);
    n.addBond(-4);
    n.remember(
      NpcMemory(
        age: l.age,
        text: 'convicted of $label',
        valence: -1,
        intensity: 3,
      ),
    );
    return years == 0
        ? '$how Guilty, but a fine and community service. $who is relieved and a little embarrassed.'
        : '$how Guilty. $who was sentenced to $years ${years == 1 ? 'year' : 'years'}. You promised to visit.';
  }

  return _scene(
    'people_defend',
    'Your phone rings at 2am. It is $who (your ${n.role.toLowerCase()}), calling from a police station: arrested for $label. "You are a lawyer. Please."',
    [
      Choice(
        label: 'Defend $who yourself',
        outcome: '',
        risk: 'Depends on your Reputation',
        run: (l, rng) {
          final odds =
              30 + hubMeter(l) ~/ 2 + l.stats['smarts'] ~/ 6 + (minor ? 15 : 0);
          final out = verdict(
            l,
            rng,
            odds,
            'You took the case, unpaid, and slept in your office for a week.',
          );
          if (out.contains('Not guilty')) _bump(l, 4);
          return out;
        },
      ),
      Choice(
        label: 'Hire the best defender you know',
        outcome: '',
        risk: 'Costs ${_m(6000)}',
        needsMoney: 6000,
        run: (l, rng) {
          l.money -= 6000;
          n.addBond(6);
          return verdict(l, rng, 60, 'You paid for the best in the business.');
        },
      ),
      Choice(
        label: 'Stay out of it',
        outcome: '',
        run: (l, rng) {
          n.addBond(-20);
          n.remember(
            NpcMemory(
              age: l.age,
              text: 'you would not help when they were arrested',
              valence: -3,
              intensity: 4,
            ),
          );
          return 'You gave $who a number for the duty solicitor. They have not called you since.';
        },
      ),
    ],
  );
}

const _ailments = [
  'chest pains',
  'a broken hip',
  'a burst appendix',
  'pneumonia',
  'a bad fall',
  'a stroke scare',
];

Storylet? _patientScene(Life l, String npcId, int seed) {
  final n = _npc(l, npcId);
  if (n == null) return null;
  final what = _ailments[seed % _ailments.length];
  final who = _first(n);
  return _scene(
    'people_patient',
    'The ambulance doors open and it is $who, your ${n.role.toLowerCase()}, with $what. They see you and grab your hand. The rules say you should not treat people you know.',
    [
      Choice(
        label: 'Treat $who yourself',
        outcome: '',
        risk: 'Against the rules',
        run: (l, rng) {
          final ok = rng.nextInt(100) < 50 + hubMeter(l) ~/ 2;
          final caught = rng.nextInt(100) < 25;
          n.addBond(ok ? 20 : 5);
          n.remember(
            NpcMemory(
              age: l.age,
              text: 'you treated them yourself when they had $what',
              valence: 3,
              intensity: 5,
            ),
          );
          if (caught) _bump(l, -6);
          if (ok) _bump(l, 3);
          return '${ok ? 'Your hands did not shake once. $who was home within the week.' : 'It was harder than you thought. $who pulled through, slowly.'}${caught ? ' The medical director had a word about the rules. Ward trust −6.' : ''}';
        },
      ),
      Choice(
        label: 'Hand $who to your best colleague',
        outcome: '',
        risk: 'Safe',
        run: (l, rng) {
          n.addBond(8);
          _bump(l, 2);
          return 'You stayed by the bed between shifts while someone else did the medicine. $who was fine. That was the right call.';
        },
      ),
      Choice(
        label: 'Pull strings to skip the queue',
        outcome: '',
        risk: 'Others wait longer',
        run: (l, rng) {
          l.stats.add('karma', -3);
          n.addBond(12);
          return '$who was seen in ten minutes. Somebody else waited four hours. You did not look at the board on your way out.';
        },
      ),
    ],
  );
}

/// Crimes a judge hears: from justice.dart's list.
const _docket = [
  'shoplifting',
  'burglary',
  'fraud',
  'assault',
  'car_theft',
  'embezzlement',
  'armed_robbery',
  'tax_evasion',
  'hacking',
  'extortion',
  'money_laundering',
  'street_racing',
];

/// A judge's hearing: a stranger from the crime list, or now and then
/// someone you know.
Storylet _hearingScene(Life l, String? which) {
  final i = int.tryParse(which ?? '') ?? 0;
  final crime = _docket[i % _docket.length];
  final label = _crimeLabel(crime);
  final band = _crimeBand(crime);
  final serious = band == 'serious' || band == 'severe';
  final known = i % 7 == 3 ? (_known(l)..shuffle(Random(i))).firstOrNull : null;
  final country = countryNamed(l.country);
  final rnd = Random(i + l.seed);
  final pool = rnd.nextBool() ? country.female : country.male;
  final stranger =
      '${pool[rnd.nextInt(pool.length)]} ${country.surnames[rnd.nextInt(country.surnames.length)]}';
  final who = known?.name ?? stranger;
  String rule(Life l, int rep, int karma, String text) {
    _add(l, 'heard');
    _bump(l, rep);
    l.stats.add('karma', karma);
    return '$text Reputation ${rep >= 0 ? '+' : '−'}${rep.abs()}.';
  }

  if (known != null) {
    return _scene(
      'people_recuse',
      'You open the next file and stop. The defendant is $who, your ${known.role.toLowerCase()}, charged with $label. Nobody else in the courtroom knows.',
      [
        Choice(
          label: 'Step aside from the case',
          outcome: '',
          risk: 'The right thing',
          run: (l, rng) {
            known.addBond(-2);
            return rule(
              l,
              4,
              2,
              'You declared the connection and handed the file to a colleague. $who looked hurt, then understood.',
            );
          },
        ),
        Choice(
          label: 'Hear it and be lenient',
          outcome: '',
          risk: 'Could end your career',
          run: (l, rng) {
            known.addBond(15);
            if (rng.nextInt(100) < 35) {
              _add(l, 'heard');
              _bump(l, -25);
              l.marks.add('scandal:judge:${l.age}');
              _log(l, 'exposed for judging a case of someone they knew');
              return 'A journalist found the connection. The inquiry was short. Reputation −25.';
            }
            return rule(
              l,
              0,
              -4,
              'A suspended sentence. Nobody asked. You will always know.',
            );
          },
        ),
        Choice(
          label: 'Hear it and be harsh, to be safe',
          outcome: '',
          run: (l, rng) {
            known.addBond(-30);
            known.remember(
              NpcMemory(
                age: l.age,
                text: 'you sentenced them harshly',
                valence: -3,
                intensity: 5,
              ),
            );
            return rule(
              l,
              2,
              -2,
              'You gave $who the full term. They have not spoken to you since.',
            );
          },
        ),
      ],
    );
  }
  return _scene(
    'lawyer_bench',
    'Before you: $who, found guilty of $label. The court waits for your sentence.',
    [
      Choice(
        label: 'Show mercy',
        outcome: '',
        run: (l, rng) => rule(
          l,
          serious ? -3 : 3,
          2,
          serious
              ? 'A light sentence for a serious crime. The papers were not kind.'
              : 'A community order and a lecture they will remember.',
        ),
      ),
      Choice(
        label: 'Follow the guidelines',
        outcome: '',
        run: (l, rng) => rule(
          l,
          4,
          0,
          'A fair sentence, by the book. The appeal court will not touch it.',
        ),
      ),
      Choice(
        label: 'Make an example',
        outcome: '',
        run: (l, rng) => rule(
          l,
          serious ? 3 : -4,
          -2,
          serious
              ? 'The maximum. The victims\' families thanked you outside.'
              : 'A harsh sentence for $label. The newspapers called it out of touch.',
        ),
      ),
    ],
  );
}

Storylet? _peopleScene(List<String> args, Life l) {
  if (args.length < 2) return null;
  return switch (args[1]) {
    'rival' => _rivalScene(l),
    'defend' when args.length >= 4 => _defendScene(
      l,
      args[2],
      int.tryParse(args[3]) ?? 0,
    ),
    'patient' when args.length >= 4 => _patientScene(
      l,
      args[2],
      int.tryParse(args[3]) ?? 0,
    ),
    _ => null,
  };
}
