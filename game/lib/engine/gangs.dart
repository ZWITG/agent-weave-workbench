import 'dart:math';

import 'actions.dart';
import 'models.dart';
import 'storylet.dart';

// Prison gangs: three rival crews, each with its own perks and risks. You
// can be recruited or ask to join, pass an initiation, carry out orders,
// climb from recruit to shot-caller, fight or broker peace in gang wars,
// snitch to the guards, or try to get out.

typedef Gang = ({
  String id,
  String name,
  String about,
  String perk,
  String risk,
});

const gangs = <Gang>[
  (
    id: 'owls',
    name: 'The Night Owls',
    about: 'Smugglers. Phones, chocolate and cigarettes move through them.',
    perk: 'Contraband comforts: happiness +2 a year',
    risk: 'Smuggling orders can add time to your sentence',
  ),
  (
    id: 'iron',
    name: 'The Iron Brotherhood',
    about: 'Muscle. Nobody touches their people.',
    perk: 'Full protection in the yard, respect +5 a year',
    risk: 'Most likely to drag you into fights',
  ),
  (
    id: 'ledger',
    name: 'The Ledger',
    about: 'Quiet fixers with friends among the guards and in the office.',
    perk: 'Paperwork goes your way: behaviour +4 a year',
    risk: 'Orders are subtle, but getting caught is costly',
  ),
];

Gang gangById(String id) => gangs.firstWhere((g) => g.id == id);

const gangRanks = ['Recruit', 'Member', 'Lieutenant', 'Shot-caller'];

String _first(Gang g) => g.name.replaceFirst('The ', '');

/// How much gang membership weighs on a parole hearing.
double gangParolePenalty(Prison p) => p.gangId == null
    ? (p.snitch ? 0 : 0)
    : const [0.08, 0.1, 0.15, 0.2][p.gangRank];

Storylet _scene(String id, String text, List<Choice> choices) => Storylet(
  id: 'scene:$id',
  text: text,
  category: 'crime',
  scene: true,
  choices: choices,
);

String? _inPrison(Life l) => l.prison == null ? 'Only in prison' : null;

void _join(Life l, Gang g, {int standing = 30}) {
  final p = l.prison!;
  p.gangId = g.id;
  p.gangRank = 0;
  p.gangStanding = standing;
  p.respect = min(100, p.respect + 15);
  for (final other in gangs.where((o) => o.id != g.id)) {
    p.rivalry[other.id] = 20 + Random(l.seed + l.age).nextInt(20);
  }
  l.flags['prison_gang'] = Memory(l.age, 'joining ${g.name}');
}

void _leave(Life l) {
  final p = l.prison!;
  l.marks.add('ex_gang:${p.gangId}');
  p.gangId = null;
  p.gangRank = 0;
  p.gangStanding = 0;
  p.rivalry.clear();
}

/// Picking a gang to approach, with what each offers and costs.
Storylet? gangPickScene(Life l) {
  final p = l.prison;
  if (p == null || p.gangId != null) return null;
  if (p.snitch) {
    return _scene(
      'gang_pick',
      'Word travels fast inside. Every table goes quiet when you walk past: nobody takes in a snitch.',
      [
        Choice(
          label: 'Eat alone',
          outcome: 'You ate alone. You will for a while.',
        ),
      ],
    );
  }
  return _scene(
    'gang_pick',
    'Three crews run this wing. Each one would take you, for a price.',
    [
      for (final g in gangs)
        Choice(
          label: g.name,
          outcome: '',
          risk: '${g.about} ${g.perk}. ${g.risk}.',
          run: (l, rng) {
            l.sceneQueue.insert(0, 'gang_initiation:${g.id}');
            return 'You sat down at their table. Nobody told you to leave. A big man leaned over: "There is a test."';
          },
        ),
      Choice(
        label: 'Stay on your own',
        outcome:
            'You decided to do your own time. It is lonelier, and it is yours.',
      ),
    ],
  );
}

/// Getting in: take a beating, run a job, or pay tribute.
Storylet? initiationScene(List<String> args, Life l) {
  final p = l.prison;
  if (p == null || p.gangId != null || args.isEmpty) return null;
  final g = gangById(args.first);
  return _scene(
    'gang_initiation',
    '${g.name} want proof you are serious before you are one of them.',
    [
      Choice(
        label: 'Take the beating',
        outcome: '',
        risk: 'Health −6 · you are in, no questions',
        run: (l, rng) {
          l.stats.add('health', -6);
          _join(l, g, standing: 35);
          return 'Thirty seconds in a blind spot by the laundry. You got up on your own. That was the point. You are in.';
        },
      ),
      Choice(
        label: 'Run a job for them',
        outcome: '',
        risk: 'About 25% chance the guards catch you (behaviour −15)',
        run: (l, rng) {
          if (rng.nextInt(100) < 25) {
            p.behaviour = max(0, p.behaviour - 15);
            _join(l, g, standing: 20);
            return 'You were caught with the package halfway down the corridor and kept your mouth shut. The guards wrote you up; ${_first(g)} let you in.';
          }
          _join(l, g, standing: 40);
          return 'The package went where it was meant to go and nobody saw a thing. They let you in.';
        },
      ),
      Choice(
        label: 'Pay tribute (\$400)',
        outcome: '',
        needsMoney: 400,
        risk: 'In, but they will think you are soft',
        run: (l, rng) {
          l.money -= 400;
          _join(l, g, standing: 15);
          return 'Money changed hands through a visitor. You are in, but nobody is impressed.';
        },
      ),
      Choice(
        label: 'Back out',
        outcome: 'You stood up and walked away. They will remember that, for better or worse.',
      ),
    ],
  );
}

typedef _Order = ({String text, String job, int risk});

const _orders = <String, List<_Order>>{
  'owls': [
    (
      text: 'A phone came in with a visitor. Someone has to carry it from the visits hall to B wing.',
      job: 'Carry the phone',
      risk: 30,
    ),
    (
      text: 'The Owls need a lookout while a delivery comes over the fence.',
      job: 'Keep watch',
      risk: 15,
    ),
  ],
  'iron': [
    (
      text: 'A man on your landing owes the Brotherhood. They want you to remind him.',
      job: 'Lean on him',
      risk: 25,
    ),
    (
      text: 'The Brotherhood want everyone in the yard at 2pm. Something is going to happen.',
      job: 'Be there',
      risk: 20,
    ),
  ],
  'ledger': [
    (
      text: 'The Ledger need a few pages copied from the office while you clean it.',
      job: 'Copy the pages',
      risk: 30,
    ),
    (
      text: 'A guard needs to "find" an envelope. You are to leave it in the right place.',
      job: 'Leave the envelope',
      risk: 20,
    ),
  ],
};

/// An order from the top: do it, refuse, or tell the guards.
Storylet? orderScene(Life l) {
  final p = l.prison;
  if (p == null || p.gangId == null) return null;
  final g = gangById(p.gangId!);
  final options = _orders[g.id]!;
  final o = options[(l.age + l.seed) % options.length];
  final risk = (o.risk - p.gangRank * 5).clamp(5, 50);
  return _scene('gang_order', '${o.text} (${g.name})', [
    Choice(
      label: o.job,
      outcome: '',
      risk: 'About $risk% chance of getting caught · standing up',
      run: (l, rng) {
        if (rng.nextInt(100) < risk) {
          p.behaviour = max(0, p.behaviour - 15);
          if (g.id == 'owls' && rng.nextBool()) p.years += 1;
          p.gangStanding = min(100, p.gangStanding + 5);
          return 'A guard caught you mid-job. You took the blame alone, which the gang respected, and the parole board will not.';
        }
        p.gangStanding = min(100, p.gangStanding + 12);
        p.respect = min(100, p.respect + 4);
        return 'Done, clean. Later someone left an extra chocolate bar on your bunk. That is how they say thank you.';
      },
    ),
    Choice(
      label: 'Refuse',
      outcome: '',
      risk: 'Standing drops; they might make an example of you',
      run: (l, rng) {
        p.gangStanding = max(0, p.gangStanding - 15);
        if (rng.nextInt(100) < 35) {
          l.stats.add('health', -4);
          return 'They did not take it well. You will be sore for a week.';
        }
        return 'You said no. They said nothing, which was worse.';
      },
    ),
    Choice(
      label: 'Tell the guards',
      outcome: '',
      risk: 'Behaviour up · about 40% chance they find out you snitched',
      run: (l, rng) {
        p.behaviour = min(100, p.behaviour + 15);
        if (rng.nextInt(100) < 40) {
          l.stats.add('health', -10);
          _leave(l);
          p.snitch = true;
          p.respect = max(0, p.respect - 30);
          return 'Somebody saw you in the governor\'s office. That night they came for you. You are out of the gang, and every crew now knows you as a snitch.';
        }
        return 'The guards stopped it quietly and noted your help. Nobody knows it was you. Yet.';
      },
    ),
  ]);
}

/// Tension with a rival boils over.
Storylet? warScene(List<String> args, Life l) {
  final p = l.prison;
  if (p == null || p.gangId == null || args.isEmpty) return null;
  final mine = gangById(p.gangId!);
  final rival = gangById(args.first);
  final odds = (30 + l.stats['charisma'] ~/ 3 + p.gangRank * 8).clamp(10, 85);
  return _scene(
    'gang_war',
    '${mine.name} and ${rival.name} are at war. Trays are being sharpened in the kitchen. Everyone is looking at you.',
    [
      Choice(
        label: 'Fight with your crew',
        outcome: '',
        risk: 'Respect and standing up · health and behaviour down',
        run: (l, rng) {
          l.stats.add('health', -(4 + rng.nextInt(8)));
          p.behaviour = max(0, p.behaviour - 12);
          p.respect = min(100, p.respect + 10);
          p.gangStanding = min(100, p.gangStanding + 15);
          p.rivalry[rival.id] = 40;
          return 'It was over in four minutes. Lockdown for a week. Your crew will not forget who stood with them.';
        },
      ),
      Choice(
        label: 'Broker a truce',
        outcome: '',
        risk: 'About $odds% chance · Charisma and rank help',
        run: (l, rng) {
          if (rng.nextInt(100) < odds) {
            p.rivalry[rival.id] = 10;
            p.gangStanding = min(100, p.gangStanding + 20);
            p.respect = min(100, p.respect + 8);
            p.behaviour = min(100, p.behaviour + 5);
            return 'You sat both sides down in the library and talked until they shook hands. People call you a peacemaker now, even the guards.';
          }
          p.rivalry[rival.id] = min(100, (p.rivalry[rival.id] ?? 50) + 10);
          p.gangStanding = max(0, p.gangStanding - 5);
          return 'Nobody listened. The fight happened anyway, and you were in the middle of nothing.';
        },
      ),
      Choice(
        label: 'Stay in your cell',
        outcome: '',
        run: (l, rng) {
          p.gangStanding = max(0, p.gangStanding - 12);
          return 'You heard it through the door. Afterwards, your crew stopped saving you a seat.';
        },
      ),
    ],
  );
}

/// A gang notices you.
Storylet? pressureScene(Life l) {
  final p = l.prison;
  if (p == null || p.gangId != null || p.snitch) return null;
  final g = gangs[(l.seed + l.age) % gangs.length];
  return _scene(
    'gang_pressure',
    '${g.name} have been watching you. One of them sits down next to you at lunch: "You could use friends in here. We could use you."',
    [
      Choice(
        label: 'Hear them out',
        outcome: '',
        run: (l, rng) {
          l.sceneQueue.insert(0, 'gang_initiation:${g.id}');
          return 'You listened. They told you what it would take.';
        },
      ),
      Choice(
        label: 'Turn them down politely',
        outcome: 'You said thanks, but you are doing your own time. They shrugged. For now.',
      ),
      Choice(
        label: 'Tell them where to go',
        outcome: '',
        risk: 'Respect up, but they may not let it go',
        run: (l, rng) {
          p.respect = min(100, p.respect + 6);
          if (rng.nextBool()) {
            l.stats.add('health', -5);
            return 'Bold. They caught you in the shower block a week later. You gave as good as you got.';
          }
          return 'They laughed and left you alone. Word got around that you are not easy prey.';
        },
      ),
    ],
  );
}

/// Each prison birthday for gang life: perks, orders, wars, promotion.
List<String> gangYear(Life l, Random rng) {
  final p = l.prison;
  if (p == null) return const [];
  final feed = <String>[];
  if (p.gangId == null) {
    if (!p.snitch && p.respect >= 35 && rng.nextInt(100) < 15) {
      l.sceneQueue.add('gang_pressure');
    }
    return feed;
  }
  final g = gangById(p.gangId!);
  switch (g.id) {
    case 'owls':
      l.stats.add('happiness', 2);
    case 'iron':
      p.respect = min(100, p.respect + 5);
    default:
      p.behaviour = min(100, p.behaviour + 4);
  }
  for (final r in p.rivalry.keys.toList()) {
    p.rivalry[r] = min(100, p.rivalry[r]! + 8 + rng.nextInt(10));
  }
  final hot = p.rivalry.entries.where((e) => e.value >= 70).firstOrNull;
  if (hot != null) {
    l.sceneQueue.add('gang_war:${hot.key}');
  } else if (rng.nextInt(100) < 40) {
    l.sceneQueue.add('gang_order');
  }
  if (p.gangRank < 3 &&
      p.gangStanding >= 60 + p.gangRank * 10 &&
      p.served >= p.gangRank + 1) {
    p.gangRank++;
    p.gangStanding = max(30, p.gangStanding - 25);
    p.respect = min(100, p.respect + 10);
    feed.add(
      'You have been made ${gangRanks[p.gangRank]} of ${g.name}. People stand up a little straighter when you walk in.',
    );
  }
  return feed;
}

// ---------------- Activities ----------------

final gangActions = <GameAction>[
  GameAction(
    id: 'join_gang',
    label: 'Find a gang',
    category: 'Prison',
    keywords: ['gang', 'crew', 'protection', 'join'],
    hint: (l) => l.prison?.snitch == true
        ? 'Nobody takes in a snitch'
        : 'Three crews, each with perks and risks',
    extraCheck: (l) =>
        _inPrison(l) ?? (l.prison!.gang ? 'You are already in a gang' : null),
    run: (l, rng) {
      l.sceneQueue.add('gang_pick');
      return ActionResult('You start watching who sits where at lunch.');
    },
  ),
  GameAction(
    id: 'gang_time',
    label: 'Spend time with your crew',
    category: 'Prison',
    keywords: ['gang', 'crew', 'loyalty'],
    hint: (l) => l.prison?.gangId == null
        ? 'Not in a gang'
        : 'Standing ${l.prison!.gangStanding}% · ${gangRanks[l.prison!.gangRank]}',
    extraCheck: (l) =>
        _inPrison(l) ?? (l.prison!.gang ? null : 'You are not in a gang'),
    run: (l, rng) {
      final p = l.prison!;
      p.gangStanding = min(100, p.gangStanding + 8);
      p.respect = min(100, p.respect + 2);
      return ActionResult(
        'Cards, stories and plans in the corner of the yard. They are starting to trust you.',
        ['Standing ${p.gangStanding}%', 'Respect ${p.respect}%'],
      );
    },
  ),
  GameAction(
    id: 'gang_truce',
    label: 'Call a truce with a rival crew',
    category: 'Prison',
    keywords: ['truce', 'peace', 'gang', 'war'],
    hint: (l) => 'Lieutenants and shot-callers only',
    extraCheck: (l) =>
        _inPrison(l) ??
        (!l.prison!.gang
            ? 'You are not in a gang'
            : l.prison!.gangRank < 2
            ? 'Needs the rank of Lieutenant'
            : null),
    run: (l, rng) {
      final p = l.prison!;
      for (final r in p.rivalry.keys.toList()) {
        p.rivalry[r] = max(0, p.rivalry[r]! - 30);
      }
      p.behaviour = min(100, p.behaviour + 5);
      return ActionResult(
        'You sent word through the kitchen: nobody moves on anybody until spring. Everyone agreed, for now.',
        ['Tension with rivals −30', 'Behaviour ${p.behaviour}%'],
      );
    },
  ),
  GameAction(
    id: 'leave_gang',
    label: 'Leave your gang',
    category: 'Prison',
    keywords: ['leave', 'quit', 'gang', 'out'],
    hint: (l) => 'There is a price for getting out',
    extraCheck: (l) =>
        _inPrison(l) ?? (l.prison!.gang ? null : 'You are not in a gang'),
    run: (l, rng) {
      l.sceneQueue.add('gang_leave');
      return ActionResult('You ask for a word with whoever is in charge.');
    },
  ),
];

/// Getting out costs something: a beating, money, or a transfer.
Storylet? leaveScene(Life l) {
  final p = l.prison;
  if (p == null || p.gangId == null) return null;
  final g = gangById(p.gangId!);
  return _scene(
    'gang_leave',
    'You tell ${g.name} you want out. Nobody says anything for a long time.',
    [
      Choice(
        label: 'Take the beating out',
        outcome: '',
        risk: 'Health −${6 + p.gangRank * 3} · you are free of them',
        run: (l, rng) {
          l.stats.add('health', -(6 + p.gangRank * 3));
          _leave(l);
          return 'They made it hurt. Then it was over, and you belong to nobody but yourself again.';
        },
      ),
      Choice(
        label: 'Buy your way out (\$1,000)',
        outcome: '',
        needsMoney: 1000,
        run: (l, rng) {
          l.money -= 1000;
          _leave(l);
          return 'The money went through a visitor. They let you go without a word.';
        },
      ),
      Choice(
        label: 'Ask for a transfer to another wing',
        outcome: '',
        lock: (l) => p.behaviour < 60 ? 'Needs behaviour 60%+' : null,
        run: (l, rng) {
          _leave(l);
          p.respect = max(0, p.respect - 10);
          return 'The governor approved it. You started again in a new wing with new faces.';
        },
      ),
      Choice(
        label: 'Change your mind',
        outcome: 'You said you were only joking. Nobody laughed.',
      ),
    ],
  );
}

/// Scenes in this file, dispatched from buildScene.
Storylet? gangScene(String id, List<String> args, Life l) => switch (id) {
  'gang_pick' => gangPickScene(l),
  'gang_initiation' => initiationScene(args, l),
  'gang_order' => orderScene(l),
  'gang_war' => warScene(args, l),
  'gang_pressure' => pressureScene(l),
  'gang_leave' => leaveScene(l),
  _ => null,
};
