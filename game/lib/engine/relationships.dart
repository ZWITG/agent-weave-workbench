import 'dart:math';

import 'actions.dart';
import 'models.dart';
import 'school.dart' show schoolInteractions;

/// Person interactions from 04 Social, Module 1: seven groups of action
/// cards. Availability depends on age, relationship type and Bond %.
/// A repeated positive interaction gives half its effect the second time in
/// a year and none the third time ("diminishing returns").
class Interaction {
  const Interaction({
    required this.id,
    required this.label,
    required this.group,
    required this.keywords,
    required this.run,
    this.minAge = 0,
    this.maxAge = 120,
    this.positive = false,
    this.cost = 0,
    this.check,
    this.only,
  });

  /// Who this interaction is for (teachers, partners, children...). Null
  /// means everyone except people with their own restricted set.
  final bool Function(Npc n)? only;

  /// Teachers (and later pets) only get their own interactions plus these.
  static const _politeOnly = {'talk', 'compliment', 'argue', 'apologize'};

  bool appliesTo(Npc n) {
    if (only != null) return only!(n);
    if (n.circle == 'School') return _politeOnly.contains(id);
    return true;
  }

  final String id;
  final String label;

  /// Warm, Help, Ask, Conflict, Repair, Special, Teen/child.
  final String group;
  final List<String> keywords;
  final int minAge;
  final int maxAge;

  /// Positive interactions are subject to diminishing returns.
  final bool positive;
  final int cost;

  /// (life, npc, effect multiplier 0/0.5/1, rng) -> result.
  final ActionResult Function(Life life, Npc npc, double k, Random rng) run;
  final String? Function(Life life, Npc npc)? check;

  String key(Npc npc) => '$id:${npc.id}';

  int usesThisYear(Life life, Npc npc) => life.interactionCounts[key(npc)] ?? 0;

  /// Effect multiplier for the next use this year.
  double multiplier(Life life, Npc npc) {
    if (!positive) return 1;
    final n = usesThisYear(life, npc);
    return n == 0 ? 1 : (n == 1 ? 0.5 : 0);
  }

  /// Null when available; otherwise the reason it is locked.
  String? lockReason(Life life, Npc npc) {
    if (!npc.alive) return '${npc.name} has died';
    if (npc.contactCut && id != 'reconnect') return 'You cut contact';
    if (life.age < minAge) return 'Unlocks at $minAge';
    if (life.age > maxAge) return 'Only up to age $maxAge';
    if (cost > 0 && life.money < cost) return 'Needs \$$cost';
    if (!positive && usesThisYear(life, npc) > 0) return 'Done this year';
    return check?.call(life, npc);
  }

  /// Subtitle shown on the card ("Half effect: 2nd time this year").
  String hint(Life life, Npc npc) {
    if (positive) {
      final n = usesThisYear(life, npc);
      if (n == 1) return 'Half effect: 2nd time this year';
      if (n >= 2) return 'No effect again this year';
    }
    return cost > 0 ? 'Costs \$$cost' : 'Tap to do';
  }

  bool matches(String q, Npc npc) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return false;
    final name = npc.name.toLowerCase();
    final role = npc.role.toLowerCase();
    final words = s.split(RegExp(r'\s+'));
    final hitsAction = words.any(
      (w) =>
          label.toLowerCase().contains(w) ||
          keywords.any((k) => k.startsWith(w) || w.startsWith(k)),
    );
    final hitsPerson = words.any(
      (w) => name.startsWith(w) || role.contains(w) || _alias(w, npc),
    );
    return hitsAction && (hitsPerson || words.length == 1);
  }

  static bool _alias(String w, Npc npc) => switch (npc.id) {
    'mother' => ['mum', 'mom', 'mother', 'mam'].contains(w),
    'father' => ['dad', 'father', 'papa'].contains(w),
    'sibling' => ['brother', 'bro', 'sibling'].contains(w),
    _ => false,
  };
}

bool _parent(Npc n) => n.id == 'mother' || n.id == 'father';

/// Public form of the Bond helper for interactions defined in other
/// modules (school.dart, love.dart...).
ActionResult bondResult(
  Life life,
  Npc npc,
  String text, {
  int affection = 0,
  int trust = 0,
  int respect = 0,
  int familiarity = 0,
  int resentment = 0,
  NpcMemory? memory,
  List<String> extra = const [],
}) => _bond(
  life,
  npc,
  text,
  affection: affection,
  trust: trust,
  respect: respect,
  familiarity: familiarity,
  resentment: resentment,
  memory: memory,
  extra: extra,
);
bool _roll(Random rng, int pct) => rng.nextInt(100) < pct;
int _k(int v, double k) => (v * k).round();

String _signed(int v) => v > 0 ? '+$v' : '−${v.abs()}';

/// Applies facet changes and reports the resulting Bond % change.
ActionResult _bond(
  Life life,
  Npc npc,
  String text, {
  int affection = 0,
  int trust = 0,
  int respect = 0,
  int familiarity = 0,
  int resentment = 0,
  NpcMemory? memory,
  List<String> extra = const [],
}) {
  final before = npc.bond;
  npc.addFacets(
    affection: affection,
    trust: trust,
    respect: respect,
    familiarity: familiarity,
    resentment: resentment,
  );
  if (memory != null) npc.remember(memory);
  npc.lastContactAge = life.age;
  final d = npc.bond - before;
  return ActionResult(text, [
    if (d != 0) 'Bond with ${npc.name} ${_signed(d)}',
    if (d == 0 && affection + trust + respect + familiarity > 0)
      'No extra effect this year',
    ...extra,
  ]);
}

String? _grudgeBlock(Life life, Npc npc) {
  final g = npc.grudge;
  return g == null ? null : '${npc.name} still resents: ${g.text}';
}

/// Every interaction: the base set below plus each module's own set.
List<Interaction> get interactions => [
  ..._baseInteractions,
  ...schoolInteractions,
];

final _baseInteractions = <Interaction>[
  // ---------------- Warm ----------------
  Interaction(
    id: 'spend_time',
    label: 'Spend time',
    group: 'Warm',
    positive: true,
    keywords: ['spend', 'time', 'hang out', 'visit'],
    run: (life, n, k, rng) => _bond(
      life,
      n,
      life.age < 13
          ? 'You played with ${n.name} all afternoon.'
          : 'You spent the afternoon with ${n.name}.',
      affection: _k(4, k),
      familiarity: _k(3, k),
    ),
  ),
  Interaction(
    id: 'talk',
    label: 'Talk',
    group: 'Warm',
    positive: true,
    minAge: 3,
    keywords: ['talk', 'chat', 'conversation'],
    run: (life, n, k, rng) => _bond(
      life,
      n,
      'You and ${n.name} talked for hours.',
      affection: _k(2, k),
      trust: _k(3, k),
    ),
  ),
  Interaction(
    id: 'compliment',
    label: 'Compliment',
    group: 'Warm',
    positive: true,
    minAge: 4,
    keywords: ['compliment', 'praise', 'nice'],
    run: (life, n, k, rng) => n.resentment > 40 && _roll(rng, 50)
        ? _bond(
            life,
            n,
            '${n.name} rolled their eyes. "Do you want something?"',
            trust: -2,
          )
        : _bond(
            life,
            n,
            '${n.name} smiled for the rest of the day.',
            affection: _k(3, k),
            respect: _k(1, k),
          ),
  ),
  Interaction(
    id: 'hug',
    label: 'Hug',
    group: 'Warm',
    positive: true,
    keywords: ['hug', 'cuddle', 'embrace'],
    run: (life, n, k, rng) => n.bond < 30
        ? _bond(life, n, '${n.name} went stiff. It was awkward.', resentment: 2)
        : _bond(
            life,
            n,
            'A long hug. ${n.name} held on a moment longer.',
            affection: _k(4, k),
          ),
  ),
  Interaction(
    id: 'share_meal',
    label: 'Share a meal',
    group: 'Warm',
    positive: true,
    minAge: 8,
    keywords: ['meal', 'dinner', 'lunch', 'eat', 'food'],
    run: (life, n, k, rng) {
      if (life.age >= 18) life.money -= 20;
      return _bond(
        life,
        n,
        'You shared a meal with ${n.name} and caught up properly.',
        affection: _k(3, k),
        familiarity: _k(3, k),
        extra: [if (life.age >= 18) 'Money −\$20'],
      );
    },
  ),
  Interaction(
    id: 'call',
    label: 'Call or message',
    group: 'Warm',
    positive: true,
    minAge: 12,
    keywords: ['call', 'phone', 'message', 'text', 'ring'],
    run: (life, n, k, rng) => _bond(
      life,
      n,
      'You called ${n.name}. They were glad you did.',
      affection: _k(2, k),
      familiarity: _k(2, k),
    ),
  ),
  Interaction(
    id: 'letter',
    label: 'Write a letter',
    group: 'Warm',
    positive: true,
    minAge: 8,
    keywords: ['letter', 'write', 'card', 'note'],
    run: (life, n, k, rng) => _bond(
      life,
      n,
      'You wrote ${n.name} a real letter. They kept it.',
      affection: _k(4, k),
      trust: _k(1, k),
      memory: k > 0
          ? NpcMemory(
              age: life.age,
              text: 'the letter you wrote',
              valence: 2,
              intensity: 2,
              tags: ['kindness'],
            )
          : null,
    ),
  ),

  // ---------------- Help ----------------
  Interaction(
    id: 'gift',
    label: 'Give a gift',
    group: 'Help',
    positive: true,
    minAge: 5,
    cost: 50,
    keywords: ['gift', 'present', 'buy'],
    run: (life, n, k, rng) {
      life.money -= 50;
      return _bond(
        life,
        n,
        'You gave ${n.name} a gift they actually wanted.',
        affection: _k(5, k),
        respect: _k(1, k),
        extra: ['Money −\$50'],
      );
    },
  ),
  Interaction(
    id: 'give_money',
    label: 'Give money',
    group: 'Help',
    positive: true,
    minAge: 16,
    cost: 200,
    keywords: ['give', 'money', 'cash', 'support'],
    run: (life, n, k, rng) {
      life.money -= 200;
      return _bond(
        life,
        n,
        'You gave ${n.name} \$200, no strings attached.',
        affection: _k(4, k),
        trust: _k(3, k),
        extra: ['Money −\$200'],
        memory: NpcMemory(
          age: life.age,
          text: 'the \$200 you gave',
          valence: 2,
          intensity: 2,
          tags: ['money'],
        ),
      );
    },
  ),
  Interaction(
    id: 'lend_money',
    label: 'Lend money',
    group: 'Help',
    minAge: 18,
    cost: 500,
    keywords: ['lend', 'loan', 'borrow', 'money'],
    check: (life, n) =>
        n.debt > 0 ? '${n.name} still owes you \$${n.debt}' : null,
    run: (life, n, k, rng) {
      life.money -= 500;
      n.debt += 500;
      return _bond(
        life,
        n,
        'You lent ${n.name} \$500. They promised to pay it back.',
        trust: 3,
        extra: ['Money −\$500', 'Loan: \$500 owed to you'],
        memory: NpcMemory(
          age: life.age,
          text: 'the \$500 loan',
          valence: 1,
          intensity: 3,
          tags: ['money', 'loan'],
        ),
      );
    },
  ),
  Interaction(
    id: 'help_problem',
    label: 'Help with a problem',
    group: 'Help',
    positive: true,
    minAge: 10,
    keywords: ['help', 'problem', 'support', 'advice'],
    run: (life, n, k, rng) => _bond(
      life,
      n,
      'You helped ${n.name} sort out something that had been worrying them.',
      trust: _k(4, k),
      respect: _k(3, k),
    ),
  ),

  // ---------------- Ask ----------------
  Interaction(
    id: 'ask_money',
    label: 'Ask for money',
    group: 'Ask',
    minAge: 6,
    keywords: ['ask', 'money', 'allowance', 'cash', 'borrow'],
    check: (life, n) => _grudgeBlock(life, n),
    run: (life, n, k, rng) {
      if (_roll(rng, n.bond - n.refusals * 10)) {
        final amount = 10 + rng.nextInt(life.age * 6 + 1);
        life.money += amount;
        n.refusals = 0;
        return _bond(
          life,
          n,
          '${n.name} gave you \$$amount.',
          affection: -1,
          extra: ['Money +\$$amount'],
        );
      }
      n.refusals += 1;
      return _bond(
        life,
        n,
        '${n.name} said no.${n.refusals > 1 ? ' "You keep asking."' : ''}',
        resentment: n.refusals > 1 ? 4 * n.refusals : 0,
        memory: n.refusals >= 2
            ? NpcMemory(
                age: life.age,
                text: 'you asking for money again',
                valence: -1,
                intensity: 2,
                tags: ['money'],
              )
            : null,
        extra: [
          if (n.refusals > 1)
            'Why: asking again after a refusal builds resentment',
        ],
      );
    },
  ),
  Interaction(
    id: 'ask_advice',
    label: 'Ask for advice',
    group: 'Ask',
    positive: true,
    minAge: 6,
    keywords: ['advice', 'ask', 'help', 'guidance'],
    run: (life, n, k, rng) {
      life.stats.add('smarts', k > 0 ? 1 : 0);
      return _bond(
        life,
        n,
        '${n.name} gave you advice you will remember for years.',
        respect: _k(2, k),
        trust: _k(2, k),
      );
    },
  ),
  Interaction(
    id: 'ask_favour',
    label: 'Ask for a favour',
    group: 'Ask',
    minAge: 18,
    keywords: ['favour', 'favor', 'ask', 'reference', 'place to stay'],
    check: (life, n) => _grudgeBlock(life, n),
    run: (life, n, k, rng) {
      if (_roll(rng, n.trust)) {
        life.stats.add('happiness', 3);
        return _bond(
          life,
          n,
          '${n.name} said yes without hesitating.',
          trust: 1,
          extra: ['Happiness +3'],
        );
      }
      return _bond(
        life,
        n,
        '${n.name} made an excuse.',
        extra: ['Why: Trust is ${n.trust < 50 ? 'low' : 'not high enough'}'],
      );
    },
  ),

  // ---------------- Conflict ----------------
  Interaction(
    id: 'argue',
    label: 'Argue',
    group: 'Conflict',
    minAge: 6,
    keywords: ['argue', 'fight', 'disagree', 'row'],
    run: (life, n, k, rng) {
      life.stats.add('willpower', 1);
      return _bond(
        life,
        n,
        'You and ${n.name} argued until someone slammed a door.',
        affection: -3,
        resentment: 6,
        memory: NpcMemory(
          age: life.age,
          text: 'the argument at ${life.age}',
          valence: -1,
          intensity: 2,
          tags: ['conflict'],
        ),
      );
    },
  ),
  Interaction(
    id: 'insult',
    label: 'Insult',
    group: 'Conflict',
    minAge: 6,
    keywords: ['insult', 'mean', 'rude', 'mock'],
    run: (life, n, k, rng) {
      life.stats.add('karma', -2);
      return _bond(
        life,
        n,
        'You said something cruel to ${n.name}. They will not forget it.',
        respect: -4,
        resentment: 10,
        memory: NpcMemory(
          age: life.age,
          text: 'what you called them at ${life.age}',
          valence: -2,
          intensity: 3,
          tags: ['insult'],
        ),
      );
    },
  ),
  Interaction(
    id: 'prank',
    label: 'Prank',
    group: 'Conflict',
    minAge: 6,
    keywords: ['prank', 'joke', 'trick'],
    run: (life, n, k, rng) => _roll(rng, 50)
        ? _bond(life, n, '${n.name} laughed so hard they cried.', affection: 2)
        : _bond(
            life,
            n,
            'The prank went too far. ${n.name} was not amused.',
            resentment: 5,
            memory: NpcMemory(
              age: life.age,
              text: 'the prank that went too far',
              valence: -1,
              intensity: 2,
              tags: ['conflict'],
            ),
          ),
  ),
  Interaction(
    id: 'snub',
    label: 'Snub',
    group: 'Conflict',
    minAge: 10,
    keywords: ['snub', 'ignore', 'cold shoulder'],
    run: (life, n, k, rng) => _bond(
      life,
      n,
      'You ignored ${n.name} on purpose. They noticed.',
      affection: -4,
      resentment: 5,
      memory: NpcMemory(
        age: life.age,
        text: 'being ignored by you',
        valence: -1,
        intensity: 2,
        tags: ['absence'],
      ),
    ),
  ),

  // ---------------- Repair ----------------
  Interaction(
    id: 'apologize',
    label: 'Apologize',
    group: 'Repair',
    minAge: 4,
    keywords: ['apologize', 'apologise', 'sorry', 'apology'],
    check: (life, n) => n.resentment == 0 && n.grudge == null
        ? 'Nothing to apologize for'
        : null,
    run: (life, n, k, rng) {
      if (_roll(rng, n.trust > 30 ? 75 : 35)) {
        for (final m in n.memories.where((m) => m.negative)) {
          m.intensity = (m.intensity - 1).clamp(0, 5);
        }
        return _bond(
          life,
          n,
          '${n.name} accepted your apology.',
          resentment: -15,
          trust: 3,
        );
      }
      return _bond(
        life,
        n,
        '${n.name} said "sorry isn\'t enough".',
        resentment: -3,
        extra: ['Why: Trust is below 30, so repair is harder'],
      );
    },
  ),
  Interaction(
    id: 'amends',
    label: 'Make amends',
    group: 'Repair',
    minAge: 16,
    cost: 100,
    keywords: ['amends', 'make up', 'repair', 'gift', 'apology'],
    check: (life, n) => n.resentment == 0 && n.grudge == null
        ? 'Nothing to make amends for'
        : null,
    run: (life, n, k, rng) {
      life.money -= 100;
      for (final m in n.memories.where((m) => m.negative)) {
        m.intensity = (m.intensity - 2).clamp(0, 5);
      }
      return _bond(
        life,
        n,
        'A real apology and a thoughtful gift. Something thawed.',
        resentment: -25,
        affection: 4,
        extra: ['Money −\$100'],
        memory: NpcMemory(
          age: life.age,
          text: 'you making amends',
          valence: 2,
          intensity: 3,
          tags: ['repair'],
        ),
      );
    },
  ),
  Interaction(
    id: 'ask_forgiveness',
    label: 'Ask for forgiveness',
    group: 'Repair',
    minAge: 10,
    keywords: ['forgive', 'forgiveness', 'reconcile', 'make peace'],
    check: (life, n) => n.grudge == null ? '${n.name} holds no grudge' : null,
    run: (life, n, k, rng) {
      if (_roll(rng, 20 + n.affection ~/ 2)) {
        for (final m in n.memories.where((m) => m.negative)) {
          m.intensity = 0;
        }
        return _bond(
          life,
          n,
          '${n.name} forgave you. You both cried a little.',
          resentment: -35,
          trust: 5,
          memory: NpcMemory(
            age: life.age,
            text: 'forgiving you',
            valence: 3,
            intensity: 4,
            tags: ['repair'],
          ),
        );
      }
      return _bond(
        life,
        n,
        '${n.name} said they need more time.',
        resentment: -5,
      );
    },
  ),
  Interaction(
    id: 'forgive',
    label: 'Forgive',
    group: 'Repair',
    minAge: 8,
    keywords: ['forgive', 'let go'],
    check: (life, n) => n.debt == 0 ? 'Nothing to forgive yet' : null,
    run: (life, n, k, rng) {
      final d = n.debt;
      n.debt = 0;
      return _bond(
        life,
        n,
        'You told ${n.name} to forget the \$$d. They hugged you.',
        affection: 6,
        trust: 4,
        extra: ['Loan of \$$d written off'],
      );
    },
  ),

  // ---------------- Special ----------------
  Interaction(
    id: 'cut_contact',
    label: 'Cut contact',
    group: 'Special',
    minAge: 16,
    keywords: ['cut', 'contact', 'block', 'estrange', 'disown'],
    run: (life, n, k, rng) {
      n.contactCut = true;
      return _bond(
        life,
        n,
        'You cut ${n.name} out of your life.',
        affection: -10,
        resentment: 15,
        memory: NpcMemory(
          age: life.age,
          text: 'being cut off',
          valence: -3,
          intensity: 5,
          tags: ['cut_off'],
        ),
      );
    },
  ),
  Interaction(
    id: 'reconnect',
    label: 'Reconnect',
    group: 'Special',
    keywords: ['reconnect', 'unblock', 'reach out'],
    check: (life, n) => n.contactCut ? null : 'You are in touch',
    run: (life, n, k, rng) {
      n.contactCut = false;
      return _bond(
        life,
        n,
        'You reached out to ${n.name} again. They answered.',
        resentment: -10,
        familiarity: 2,
      );
    },
  ),

  // ---------------- Teen/child ----------------
  Interaction(
    id: 'play',
    label: 'Play together',
    group: 'Teen/child',
    positive: true,
    maxAge: 12,
    keywords: ['play', 'games', 'toys'],
    run: (life, n, k, rng) => _bond(
      life,
      n,
      'You played with ${n.name} until bedtime.',
      affection: _k(3, k),
      familiarity: _k(3, k),
    ),
  ),
  Interaction(
    id: 'ask_pet',
    label: 'Ask for a pet',
    group: 'Teen/child',
    minAge: 4,
    maxAge: 15,
    keywords: ['pet', 'dog', 'cat', 'puppy'],
    check: (life, n) {
      if (!_parent(n)) return 'Ask a parent';
      if (life.flags.containsKey('own_pet') ||
          life.flags.containsKey('dog_biscoito')) {
        return 'You already have a pet';
      }
      return null;
    },
    run: (life, n, k, rng) {
      if (_roll(rng, n.bond ~/ 2)) {
        life.flags['own_pet'] = Memory(
          life.age,
          'getting a kitten called Mochi',
        );
        life.stats.add('happiness', 6);
        return _bond(
          life,
          n,
          '${n.name} said yes! You named the kitten Mochi.',
          affection: 2,
          extra: ['Happiness +6'],
        );
      }
      n.refusals += 1;
      return _bond(
        life,
        n,
        '${n.name} said "not until you\'re older."',
        resentment: n.refusals > 1 ? 3 : 0,
      );
    },
  ),
  Interaction(
    id: 'tattle',
    label: 'Tattle on your brother',
    group: 'Teen/child',
    minAge: 4,
    maxAge: 15,
    keywords: ['tattle', 'tell', 'snitch'],
    check: (life, n) => _parent(n) && life.npc('sibling') != null
        ? null
        : 'Tell a parent about your brother',
    run: (life, n, k, rng) {
      final s = life.npc('sibling')!;
      s.addFacets(resentment: 6);
      s.remember(
        NpcMemory(
          age: life.age,
          text: 'you telling on them',
          valence: -1,
          intensity: 2,
          tags: ['betrayal'],
        ),
      );
      return _bond(
        life,
        n,
        'You told ${n.name} what ${s.name} did. ${s.name} got grounded.',
        trust: 1,
        extra: ['${s.name} resents you a little'],
      );
    },
  ),
  Interaction(
    id: 'copy_homework',
    label: 'Copy their homework',
    group: 'Teen/child',
    minAge: 8,
    maxAge: 17,
    keywords: ['homework', 'copy', 'cheat'],
    check: (life, n) => n.id == 'sibling' || n.circle == 'Friends'
        ? null
        : 'Only with a brother or friend',
    run: (life, n, k, rng) {
      life.stats.add('karma', -1);
      return _roll(rng, 70)
          ? _bond(
              life,
              n,
              '${n.name} let you copy. You owe them one.',
              familiarity: 2,
            )
          : _bond(
              life,
              n,
              'The teacher noticed identical answers. You both got detention.',
              resentment: 4,
              memory: NpcMemory(
                age: life.age,
                text: 'the homework detention',
                valence: -1,
                intensity: 2,
                tags: ['conflict'],
              ),
            );
    },
  ),
];

const interactionGroups = [
  'School',
  'Warm',
  'Help',
  'Ask',
  'Conflict',
  'Repair',
  'Special',
  'Teen/child',
];

/// Runs an interaction and counts it toward this year's uses.
ActionResult runInteraction(Life life, Npc npc, Interaction i, Random rng) {
  final k = i.multiplier(life, npc);
  life.interactionCounts[i.key(npc)] = i.usesThisYear(life, npc) + 1;
  return i.run(life, npc, k, rng);
}

/// Yearly relationship upkeep: drift without contact, fading memories,
/// loan repayments and "reach out" nudges. Returns feed lines.
List<String> yearlyRelationships(Life life, Random rng) {
  final lines = <String>[];
  for (final n in life.npcs.where((n) => n.alive)) {
    for (final m in n.memories) {
      m.intensity = (m.intensity - 0.2).clamp(0, 5);
    }
    n.memories.removeWhere((m) => m.intensity <= 0 && m.valence.abs() < 3);
    final livesTogether = life.age < 18 && n.circle == 'Family';
    final gap = life.age - n.lastContactAge;
    if (!livesTogether && !n.contactCut && gap >= 1) {
      final drift = switch (n.circle) {
        'Family' => 1 + rng.nextInt(3),
        'Partner' => 2 + rng.nextInt(5),
        _ => 4 + rng.nextInt(5),
      };
      n.addFacets(affection: -drift, familiarity: -(drift ~/ 2));
      if (gap == 3 && n.bond >= 30) {
        lines.add('You haven\'t spoken to ${n.name} in 3 years. Reach out?');
      }
    }
    if (livesTogether) n.lastContactAge = life.age;
    if (n.debt > 0) {
      if (_roll(rng, 35)) {
        lines.add('${n.name} paid back the \$${n.debt} they owed you.');
        life.money += n.debt;
        n.debt = 0;
        n.addFacets(trust: 2);
      }
    }
  }
  return lines;
}
