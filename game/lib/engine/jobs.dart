import 'dart:math';

import 'actions.dart';
import 'careers.dart';
import 'models.dart';
import 'storylet.dart';
import 'justice.dart' show convictions;
import 'world_data.dart';

/// Life at work (plan Module 5): boss and colleagues, a visible
/// performance meter, firing with reasons, stress and burnout, interviews,
/// and each special career's signature mechanic.

String _m(int v) =>
    '\$${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

// ---------------- Boss and colleagues ----------------

Npc? bossOf(Life l) => l.npcs.where((n) => n.id == 'boss').firstOrNull;

/// New workplace: a boss and two colleagues with memory (plan CA-009).
void newWorkplace(Life l, Career c) {
  final country = countryNamed(l.country);
  final rng = Random(l.seed + l.age * 13 + c.id.hashCode);
  String name() {
    final pool = rng.nextBool() ? country.female : country.male;
    return '${pool[rng.nextInt(pool.length)]} ${country.surnames[rng.nextInt(country.surnames.length)]}';
  }

  l.npcs.add(
    Npc(
      id: 'boss',
      role: 'Boss · ${c.field}',
      name: name(),
      birthYear: l.year - 35 - rng.nextInt(20),
      circle: 'Work',
      bond: 45 + rng.nextInt(15),
    )..lastContactAge = l.age,
  );
  for (var i = 1; i <= 2; i++) {
    l.npcs.add(
      Npc(
        id: 'colleague$i',
        role: 'Colleague',
        name: name(),
        birthYear: l.year - 22 - rng.nextInt(25),
        circle: 'Work',
        bond: 40 + rng.nextInt(25),
      )..lastContactAge = l.age,
    );
  }
}

/// Leaving a job: the workplace goes, but colleagues you were close to stay
/// on as friends.
void leaveWorkplace(Life l) {
  final keep = <Npc>[];
  for (final n in l.npcs.where((n) => n.circle == 'Work')) {
    if (n.bond >= 70) {
      final f = Npc(
        id: 'friend_${n.id}_${l.age}',
        role: 'Friend (former colleague)',
        name: n.name,
        birthYear: n.birthYear,
        circle: 'Friends',
        bond: n.bond,
        memories: n.memories,
      )..lastContactAge = l.age;
      keep.add(f);
    }
  }
  l.npcs.removeWhere((n) => n.circle == 'Work');
  l.npcs.addAll(keep);
}

/// Ends the current job for any reason.
void leaveJob(Life l, {bool fired = false}) {
  leaveWorkplace(l);
  l.job = null;
  l.salary = 0;
  l.careerId = null;
  l.careerRank = 0;
  l.jobLostAge = l.age;
  if (fired) l.flags['fired'] = Memory(l.age, 'being fired');
}

// ---------------- The working year ----------------

/// Performance, firing, stress, burnout and special-career events.
/// [hard] / [slack] say how you worked last year.
List<String> workYear(
  Life l,
  Random rng, {
  required bool hard,
  required bool slack,
}) {
  final lines = <String>[];
  if (l.job == null) {
    l.stress = l.stress - 6;
    l.flags.remove('high_stress');
    return lines;
  }
  l.reason = 'Work';
  final c = careerById(l.careerId);
  final effort = slack ? 0 : (hard ? 6 : 3);
  if (c != null) {
    final key = l.stats[c.keyStat];
    final boss = bossOf(l)?.bond ?? 50;
    final delta =
        effort +
        (key - 50) ~/ 10 +
        boss ~/ 20 -
        l.stress ~/ 20 +
        rng.nextInt(9) -
        4 -
        3;
    l.performance = (l.performance + delta).clamp(0, 100);
    if (l.performance < 25) {
      l.lowPerfYears++;
      if (l.lowPerfYears >= 2) {
        final old = l.job;
        leaveJob(l, fired: true);
        l.stats.add('happiness', -8);
        lines.add(
          'You were let go from your job as $old. Why: performance below 25% for two years (effort, ${c.keyStat}, your boss and stress all count).',
        );
        return lines;
      }
      lines.add(
        'Your manager had a serious word: performance is at ${l.performance}%. Another year like this and you are out.',
      );
    } else {
      l.lowPerfYears = 0;
    }
  }
  l.stress =
      l.stress +
      (l.salary > 20000 ? 6 : 3) +
      (hard ? 10 : 0) -
      (slack ? 6 : 0) -
      4;
  if (l.stress > 80) {
    if (l.flags.containsKey('high_stress')) {
      l.flags.remove('high_stress');
      l.sceneQueue.add('burnout');
    } else {
      l.flags['high_stress'] = Memory(l.age, 'a very stressful year');
    }
  } else {
    l.flags.remove('high_stress');
  }
  if (c != null && c.special) lines.addAll(_specialYear(l, c, rng));
  return lines;
}

void _promote(Life l, Career c, List<String> lines, String why) {
  if (l.careerRank >= c.ladder.length - 1) return;
  l.careerRank++;
  l.jobSince = l.age;
  l.job = c.ladder[l.careerRank];
  l.salary = c.payIn(l, l.careerRank);
  if (l.careerRank == c.ladder.length - 1) {
    l.flags['top_of_career'] = Memory(l.age, 'becoming ${l.job}');
  }
  lines.add('$why You are now ${l.job} (${_m(l.salary)} a year).');
}

/// Signature mechanics (plan: big breaks 3–8% a year, always explained).
List<String> _specialYear(Life l, Career c, Random rng) {
  final lines = <String>[];
  final key = l.stats[c.keyStat];
  final breakOdds = (3 + max(0, key - 60) ~/ 8 + (l.performance - 50) ~/ 15)
      .clamp(3, 8);
  switch (c.id) {
    case 'actor':
      if (rng.nextInt(100) < 35) l.sceneQueue.add('audition');
      if (rng.nextInt(100) < breakOdds) {
        _promote(
          l,
          c,
          lines,
          'Big break: a casting director saw you in a small play and called your agent.',
        );
      }
    case 'musician':
      if (rng.nextInt(100) < breakOdds) {
        _promote(
          l,
          c,
          lines,
          'Big break: a video of you playing went viral overnight.',
        );
      }
    case 'model':
      if (l.age > 35) {
        l.performance = max(0, l.performance - 12);
        lines.add(
          'Bookings are drying up. The industry likes its models young, which is its loss.',
        );
      } else if (rng.nextInt(100) < breakOdds) {
        _promote(
          l,
          c,
          lines,
          'Big break: a famous photographer requested you by name.',
        );
      }
    case 'athlete':
      if (rng.nextInt(100) < 8) {
        l.stats.add('health', -8);
        l.performance = max(0, l.performance - 15);
        lines.add('You were injured mid-season and spent months in rehab.');
      }
      if (l.age >= 35 && rng.nextInt(100) < 40) {
        final old = l.job;
        leaveJob(l);
        l.flags['retired_athlete'] = Memory(
          l.age,
          'retiring from professional sport',
        );
        lines.add(
          'At ${l.age}, your body told you it was time. You retired as $old to a standing ovation.',
        );
      } else if (rng.nextInt(100) < breakOdds) {
        _promote(
          l,
          c,
          lines,
          'Big break: a top club scouted you after a man-of-the-match performance.',
        );
      }
    case 'politician':
      if ((l.age - l.jobSince) % 4 == 3) l.sceneQueue.add('election');
    case 'military':
      if (rng.nextInt(100) < 25) l.sceneQueue.add('deployment');
    case 'doctor':
      if (rng.nextInt(100) < 30) l.sceneQueue.add('hospital_case');
    case 'lawyer':
      if (rng.nextInt(100) < 30) l.sceneQueue.add('big_case');
    case 'police':
      if (rng.nextInt(100) < 25) l.sceneQueue.add('police_case');
    case 'hustler':
      final take =
          (c.payIn(l, l.careerRank) *
                  (0.5 + rng.nextDouble()) *
                  (0.7 + l.stats['charisma'] / 166))
              .round();
      l.salary = take;
      lines.add(
        'A ${take > c.payIn(l, l.careerRank) ? 'good' : 'lean'} year on the street: you made about ${_m(take)}.',
      );
  }
  return lines;
}

// ---------------- Interviews (plan CA-008) ----------------

typedef _Answer = (String text, String stat, double bonus);
typedef _Question = (String text, List<_Answer> answers);

const _questions = <String, List<_Question>>{
  'office': [
    (
      '"Tell me about a time you solved a problem at work or school."',
      [
        ('Walk through it step by step', 'smarts', 0.1),
        ('Tell a funny story about it', 'charisma', 0.0),
        ('Say you have never had a problem', 'karma', -0.3),
      ],
    ),
    (
      '"Where do you see yourself in five years?"',
      [
        ('In this company, with more responsibility', 'discipline', 0.15),
        ('Running my own business', 'charisma', -0.05),
        ('Honestly? Not sure', 'karma', 0.0),
      ],
    ),
    (
      '"What is your biggest weakness?"',
      [
        ('I take on too much, and I am learning to delegate', 'charisma', 0.1),
        ('Perfectionism', 'smarts', -0.1),
        ('Mornings', 'karma', 0.05),
      ],
    ),
  ],
  'care': [
    (
      '"A patient\'s family is shouting at you. What do you do?"',
      [
        ('Stay calm and listen', 'karma', 0.15),
        ('Call security', 'discipline', 0.0),
        ('Explain the rules firmly', 'charisma', 0.05),
      ],
    ),
    (
      '"Why this work?"',
      [
        ('I want to help people', 'karma', 0.1),
        ('It is a stable career', 'discipline', 0.0),
        ('My family pushed me', 'charisma', -0.2),
      ],
    ),
    (
      '"How do you handle a long, hard shift?"',
      [
        ('Routine, rest and a good team', 'discipline', 0.1),
        ('Coffee. A lot of coffee', 'charisma', 0.0),
        ('I just push through', 'willpower', 0.05),
      ],
    ),
  ],
  'tech': [
    (
      '"Talk us through something you built."',
      [
        ('Explain the design and the trade-offs', 'smarts', 0.15),
        ('Show the result and how people used it', 'creativity', 0.05),
        ('Say a friend did most of it', 'karma', -0.3),
      ],
    ),
    (
      '"Something breaks at 2 a.m. What do you do?"',
      [
        ('Check the logs, fix it, write it up', 'discipline', 0.15),
        ('Wake the whole team', 'charisma', -0.1),
        ('Leave it till morning', 'karma', -0.2),
      ],
    ),
    (
      '"How do you learn new things?"',
      [
        ('Build small projects', 'creativity', 0.1),
        ('Read the documentation cover to cover', 'smarts', 0.1),
        ('Ask someone who knows', 'charisma', 0.05),
      ],
    ),
  ],
  'service': [
    (
      '"A customer is rude to you. What do you do?"',
      [
        ('Smile and stay polite', 'karma', 0.15),
        ('Get the manager', 'discipline', 0.05),
        ('Tell them how it is', 'charisma', -0.2),
      ],
    ),
    (
      '"Can you work weekends?"',
      [
        ('Yes, whenever you need me', 'discipline', 0.15),
        ('Some weekends', 'karma', 0.05),
        ('I would rather not', 'charisma', -0.15),
      ],
    ),
    (
      '"Why should we hire you?"',
      [
        ('I am reliable and I learn fast', 'discipline', 0.1),
        ('People like me', 'charisma', 0.1),
        ('I need the money', 'karma', -0.05),
      ],
    ),
  ],
  'uniform': [
    (
      '"Run through the fitness test for us."',
      [
        ('Push yourself to the limit', 'athleticism', 0.15),
        ('Pace yourself carefully', 'discipline', 0.1),
        ('Joke about it', 'charisma', -0.1),
      ],
    ),
    (
      '"Would you follow an order you disagreed with?"',
      [
        ('Follow it, then raise it properly', 'discipline', 0.15),
        ('Refuse if it was wrong', 'karma', 0.05),
        ('Depends who gave it', 'charisma', -0.1),
      ],
    ),
    (
      '"How do you stay calm under pressure?"',
      [
        ('Training and breathing', 'willpower', 0.1),
        ('I just do', 'athleticism', 0.0),
        ('I am not sure I do', 'karma', -0.1),
      ],
    ),
  ],
  'creative': [
    (
      '"Show us what you can do."',
      [
        ('Give it everything', 'creativity', 0.15),
        ('Play it safe and polished', 'discipline', 0.05),
        ('Charm the room', 'charisma', 0.1),
      ],
    ),
    (
      '"Who inspires you?"',
      [
        ('Name an obscure artist and explain why', 'creativity', 0.1),
        ('Name a famous star', 'charisma', 0.0),
        ('Myself', 'karma', -0.2),
      ],
    ),
    (
      '"Can you take direction?"',
      [
        ('Absolutely, try anything', 'discipline', 0.15),
        ('Within reason', 'charisma', 0.05),
        ('I have my own vision', 'creativity', -0.05),
      ],
    ),
  ],
};

Storylet? interviewScene(Life l, String careerId, int q) {
  final c = careerById(careerId);
  if (c == null || q > 2) return null;
  final (text, answers) = _questions[c.interview]![q];
  return Storylet(
    id: 'scene:interview:$careerId:$q',
    text: q == 0
        ? 'Interview for ${c.title}. You are sitting across a table from two people with notebooks. The first question: $text'
        : 'Question ${q + 1} of 3: $text',
    category: 'work',
    scene: true,
    choices: [
      for (final (answer, stat, bonus) in answers)
        Choice(
          label: answer,
          outcome: '',
          run: (life, rng) {
            final score = (life.stats[stat] / 100 + bonus).clamp(0.0, 1.0);
            (life.interview ??= InterviewState()).record(answer, score);
            if (q < 2) {
              life.sceneQueue.add('interview:$careerId:${q + 1}');
              return score >= 0.6
                  ? 'The interviewers glanced at each other and nodded.'
                  : 'One of them wrote something down without looking up.';
            }
            return _decide(life, c, rng);
          },
        ),
    ],
  );
}

/// Plan formula: hire = clamp(0.25 + reqFit×0.35 + interview×0.3 +
/// (Charisma − 50)/200 + referral, 0.02, 0.95), with world news, the
/// family name, difficulty and how competitive the job is.
String _decide(Life l, Career c, Random rng) {
  final iv = l.interview ?? InterviewState();
  final score = iv.answered == 0 ? 0.5 : iv.score / iv.answered;
  final referral = l.npcs.any((n) => n.circle == 'Friends' && n.bond >= 75)
      ? 0.1
      : 0.0;
  final p =
      (0.25 +
              0.35 +
              score * 0.3 +
              (l.stats['charisma'] - 50) / 200 +
              referral +
              ((l.worldMods['hiring'] ?? 0) + (l.worldMods['name'] ?? 0)) /
                  100 -
              c.baseSalary / 200000 -
              min(0.18, convictions(l) * 0.06) +
              (l.marks.contains('trade_cert') && convictions(l) > 0 ? 0.1 : 0) +
              (c.special ? l.fame / 400 : 0) -
              (c.special ? 0.1 : 0) +
              (l.difficulty == 'easy'
                  ? 0.1
                  : l.difficulty == 'hard'
                  ? -0.1
                  : 0))
          .clamp(0.02, 0.95);
  final pct = (p * 100).round();
  final summary =
      'Interview score ${(score * 100).round()}%. Best answer: "${iv.best}". Weakest: "${iv.worst}".${convictions(l) > 0 ? ' Your criminal record counted against you.' : ''}';
  l.interview = null;
  if (rng.nextDouble() < p) {
    final had = l.job;
    startCareer(l, c);
    l.sceneQueue.insert(0, 'job_offer:${c.id}:${(score * 100).round()}');
    return '${had == null ? 'You got the job!' : 'You handed in your notice as $had: you got the job!'} They offer you ${c.title} on ${_m(l.salary)} a year. $summary';
  }
  l.stats.add('happiness', -3);
  return 'A polite email: they went with someone else. Your chance was about $pct%. $summary Tip: raise ${c.keyStat} or ask a close friend for a referral.';
}

/// The offer after a good interview: take it, negotiate the pay, or ask
/// for more time off instead.
Storylet? jobOfferScene(List<String> args, Life l) {
  final c = careerById(args.isEmpty ? null : args.first);
  if (c == null || l.careerId != c.id) return null;
  final interview = args.length > 1 ? int.tryParse(args[1]) ?? 50 : 50;
  final odds = (35 + l.stats['charisma'] ~/ 3 + interview ~/ 5).clamp(10, 85);
  return Storylet(
    id: 'scene:job_offer',
    text:
        'HR sends the contract for ${c.title}: ${_m(l.salary)} a year. You could sign it as it is, or try your luck.',
    category: 'work',
    scene: true,
    choices: [
      Choice(
        label: 'Sign it',
        outcome: 'You signed on the line and bought a new pen to celebrate.',
      ),
      Choice(
        label: 'Ask for 10% more',
        outcome: '',
        risk: 'About $odds% chance · Charisma and your interview help',
        run: (l, rng) {
          if (rng.nextInt(100) < odds) {
            final more = (l.salary * 0.1).round();
            l.salary += more;
            return 'They came back the next day: yes. ${_m(more)} a year more, for one awkward email.';
          }
          return 'They said the offer is final. You signed anyway, and nobody holds it against you.';
        },
      ),
      Choice(
        label: 'Ask for more holiday instead',
        outcome: '',
        run: (l, rng) {
          l.stats.add('happiness', 2);
          l.stress = max(0, l.stress - 10);
          return 'Five extra days off a year, agreed without a fight. Your future self says thank you.';
        },
      ),
    ],
  );
}

// ---------------- Special-career scenes ----------------

Storylet? jobScene(String kind, Life l) {
  final c = careerById(l.careerId);
  Storylet scene(String text, List<Choice> choices) => Storylet(
    id: 'scene:$kind',
    text: text,
    category: 'work',
    scene: true,
    choices: choices,
  );
  switch (kind) {
    case 'burnout':
      if (l.job == null) return null;
      return scene(
        'You have not slept properly in months. Sunday nights make your chest tight, and yesterday you cried in the work toilets for no reason you could name. Something has to give.',
        [
          Choice(
            label: 'Take time off',
            outcome: '',
            run: (life, rng) {
              life.stress = 30;
              life.performance = max(0, life.performance - 10);
              life.stats.add('happiness', 5);
              return 'You took six weeks off. The first was strange, the second was sleep, and by the end you remembered who you were. Work coped without you.';
            },
          ),
          Choice(
            label: 'Push through',
            outcome: '',
            risk: 'Hurts your health',
            run: (life, rng) {
              life.stats.add('health', -6);
              life.stats.add('happiness', -4);
              return 'You gritted your teeth and kept going. Your body kept a careful record of the cost.';
            },
          ),
          Choice(
            label: 'Quit',
            outcome: '',
            run: (life, rng) {
              final old = life.job;
              leaveJob(life);
              life.stress = 15;
              life.stats.add('happiness', 6);
              return 'You resigned as $old and walked out into the sunshine feeling ten years younger and slightly terrified.';
            },
          ),
        ],
      );
    case 'audition':
      if (c?.id != 'actor') return null;
      return scene(
        'Your agent calls: a casting director wants to see you for a role in a new series. The audition is tomorrow at nine, and the sides arrived ten minutes ago.',
        [
          Choice(
            label: 'Prepare all night',
            outcome: '',
            risk: 'Likely',
            run: (life, rng) {
              if (rng.nextInt(100) < 40 + life.stats['charisma'] ~/ 3) {
                life.performance = min(100, life.performance + 15);
                life.money += 6000;
                return 'You nailed it and got the part: six weeks of filming and \$6,000. Your name is in the credits, in small letters.';
              }
              return 'You were good, but they went with someone taller. That is the business.';
            },
          ),
          Choice(
            label: 'Improvise on the day',
            outcome: '',
            risk: 'Risky',
            run: (life, rng) {
              if (rng.nextInt(100) < 25 + life.stats['creativity'] ~/ 3) {
                life.performance = min(100, life.performance + 20);
                life.money += 9000;
                return 'You threw the script away and made the room laugh. They rewrote the part for you.';
              }
              life.performance = max(0, life.performance - 5);
              return 'You threw the script away. They wanted the script.';
            },
          ),
        ],
      );
    case 'election':
      if (c?.id != 'politician' || l.careerRank >= c!.ladder.length - 1) {
        return null;
      }
      final next = c.ladder[l.careerRank + 1];
      return scene(
        'Election season. Your party wants you to run for $next. The polls are close, the posters are printed and your phone has not stopped ringing.',
        [
          Choice(
            label: 'Campaign hard (\$5,000)',
            outcome: '',
            needsMoney: 5000,
            risk: 'Good chance',
            run: (life, rng) => _election(life, c, rng, 15, 5000),
          ),
          Choice(
            label: 'Run a clean, cheap campaign',
            outcome: '',
            risk: 'Close',
            run: (life, rng) => _election(life, c, rng, 0, 0),
          ),
          Choice(
            label: 'Sit this one out',
            outcome:
                'You stayed in your current seat. There is always next time.',
          ),
        ],
      );
    case 'deployment':
      if (c?.id != 'military') return null;
      return scene(
        'Your unit is being deployed overseas for six months. You have two weeks to say goodbye, sort your affairs and pack a bag that weighs as much as you do.',
        [
          Choice(
            label: 'Volunteer for the front line',
            outcome: '',
            risk: 'Dangerous',
            run: (life, rng) {
              if (rng.nextInt(100) < 15) {
                life.stats.add('health', -20);
                return 'You were wounded in an ambush and flown home. You will carry the scar and the memory. The army gave you a medal and a long recovery.';
              }
              life.flags['medal'] = Memory(
                life.age,
                'earning a medal for bravery',
              );
              life.performance = min(100, life.performance + 20);
              return 'You came home with a medal for bravery and stories you do not tell at parties.';
            },
          ),
          Choice(
            label: 'Ask for a support role',
            outcome: '',
            run: (life, rng) {
              life.performance = min(100, life.performance + 5);
              return 'You spent six months keeping the base running. Unglamorous, essential and safe.';
            },
          ),
        ],
      );
    case 'hospital_case':
      if (c?.id != 'doctor') return null;
      return scene(
        'A patient arrives with chest pain that does not fit any textbook. The scans are unclear, the senior doctor is in theatre and the nurse is looking at you for a decision.',
        [
          Choice(
            label: 'Order more tests',
            outcome: '',
            run: (life, rng) {
              life.performance = min(100, life.performance + 6);
              return 'The extra tests found a rare tear in an artery. Your caution saved a life, and your boss noticed.';
            },
          ),
          Choice(
            label: 'Treat what seems most likely',
            outcome: '',
            risk: 'Risky',
            run: (life, rng) {
              if (rng.nextInt(100) < life.stats['smarts'] - 10) {
                life.performance = min(100, life.performance + 10);
                return 'Your instinct was right. The patient walked out three days later and sent the ward a cake.';
              }
              life.performance = max(0, life.performance - 15);
              life.stats.add('happiness', -6);
              return 'Your first guess was wrong. The patient recovered, but there was a review, and it stung.';
            },
          ),
        ],
      );
    case 'big_case':
      if (c?.id != 'lawyer') return null;
      return scene(
        'A big case lands on your desk: a family suing a company that poisoned their water. Your firm would rather you settle quietly. The family wants their day in court.',
        [
          Choice(
            label: 'Fight it in court',
            outcome: '',
            risk: 'Hard',
            run: (life, rng) {
              if (rng.nextInt(100) <
                  life.stats['smarts'] ~/ 2 + life.stats['charisma'] ~/ 4) {
                life.performance = min(100, life.performance + 20);
                life.stats.add('karma', 4);
                life.money += 15000;
                return 'You won. The judge called your closing argument "devastating". The family hugged you on the court steps, and the bonus was not bad either.';
              }
              life.performance = max(0, life.performance - 8);
              return 'You lost on a technicality. The family thanked you anyway, which was somehow worse.';
            },
          ),
          Choice(
            label: 'Settle',
            outcome: '',
            run: (life, rng) {
              life.money += 5000;
              life.stats.add('karma', -2);
              return 'You negotiated a settlement. The family got some money; the company got silence. The partners were pleased.';
            },
          ),
        ],
      );
    case 'police_case':
      if (c?.id != 'police') return null;
      return scene(
        'A string of break-ins on the same street. Your sergeant hands you the file: three houses, no witnesses, and a neighbour who seems to know more than he is saying.',
        [
          Choice(
            label: 'Lean on the neighbour',
            outcome: '',
            run: (life, rng) {
              if (rng.nextInt(100) < 50 + life.stats['charisma'] ~/ 4) {
                life.performance = min(100, life.performance + 12);
                return 'He cracked and named his nephew. Case closed, and the station bought you a coffee.';
              }
              return 'He clammed up and called a lawyer. The case went cold.';
            },
          ),
          Choice(
            label: 'Stake out the street',
            outcome: '',
            run: (life, rng) {
              life.performance = min(100, life.performance + 8);
              life.stats.add('health', -1);
              return 'Three cold nights in a car, then you caught them climbing a fence. Slow, solid police work.';
            },
          ),
        ],
      );
  }
  return null;
}

String _election(Life l, Career c, Random rng, int bonus, int cost) {
  l.money -= cost;
  final rep = (l.worldMods['name'] ?? 0) * 2;
  final odds =
      (30 +
              (l.stats['charisma'] - 50) ~/ 2 +
              (l.stats['karma'] - 50) ~/ 4 +
              bonus +
              rep +
              (l.performance - 50) ~/ 5)
          .clamp(5, 90);
  if (rng.nextInt(100) < odds) {
    final lines = <String>[];
    _promote(l, c, lines, 'You won the election with $odds% odds going in!');
    l.flags['elected'] = Memory(l.age, 'winning an election');
    return lines.join(' ');
  }
  l.stats.add('happiness', -6);
  return 'You lost the election. Your odds were about $odds% (Charisma, Karma, your record and your family name all count). You keep your current seat.';
}

// ---------------- Activities added by this module ----------------

final jobActions = <GameAction>[
  GameAction(
    id: 'slack_off',
    label: 'Slack off at work',
    category: 'Work',
    keywords: ['slack', 'lazy', 'coast', 'easy', 'work'],
    minAge: 14,
    extraCheck: (l) => l.job == null ? 'You don\'t have a job' : null,
    run: (l, rng) => statChange(
      l,
      'You took long lunches and answered emails very, very slowly. Relaxing, but your manager noticed.',
      {'happiness': 3},
    ),
  ),
  GameAction(
    id: 'chores',
    label: 'Do chores for pocket money',
    category: 'Work',
    keywords: ['chores', 'pocket money', 'allowance', 'tidy', 'wash up'],
    minAge: 6,
    maxAge: 13,
    run: (l, rng) {
      final pay = 5 + rng.nextInt(16);
      l.money += pay;
      l.npc('mother')?.addFacets(affection: 2);
      final r = statChange(
        l,
        'You washed the car, hoovered the stairs and only broke one plate. Your parents paid up.',
        {'discipline': 1},
      );
      return ActionResult(r.text, ['Money +\$$pay', ...r.notes]);
    },
  ),
  GameAction(
    id: 'flight_school',
    label: 'Go to flight school',
    category: 'School',
    keywords: ['flight school', 'pilot', 'licence', 'fly', 'aviation'],
    minAge: 18,
    cost: 15000,
    extraCheck: (l) => l.flags.containsKey('pilot_licence')
        ? 'You already have a licence'
        : (l.stats['health'] < 55 ? 'Needs Health 55+ for the medical' : null),
    run: (l, rng) {
      l.money -= 15000;
      l.flags['pilot_licence'] = Memory(l.age, 'earning your pilot licence');
      return ActionResult(
        'A year of simulators, early mornings and one terrifying first solo landing. You earned your commercial pilot licence.',
        ['Money −\$15,000', 'Pilot careers unlocked'],
      );
    },
  ),
  GameAction(
    id: 'bar_exam',
    label: 'Take the bar exam',
    category: 'School',
    keywords: ['bar exam', 'lawyer', 'law', 'qualify'],
    minAge: 21,
    cost: 500,
    extraCheck: (l) => !l.school.degrees.contains('Law')
        ? 'Needs a Law degree'
        : (l.flags.containsKey('passed_bar') ? 'You passed already' : null),
    run: (l, rng) {
      l.money -= 500;
      final odds = (l.stats['smarts'] - 15).clamp(10, 95);
      if (rng.nextInt(100) < odds) {
        l.flags['passed_bar'] = Memory(l.age, 'passing the bar exam');
        return ActionResult(
          'Two days of exams, then a nervous month of waiting. You passed the bar!',
          ['Money −\$500', 'Lawyer careers unlocked'],
        );
      }
      return ActionResult(
        'You did not pass this time. Plenty of great lawyers needed two attempts.',
        [
          'Money −\$500',
          'Why: pass chance about $odds% (Smarts)',
          'Retakes allowed next year',
        ],
      );
    },
  ),
  GameAction(
    id: 'write_song',
    label: 'Write and release a song',
    category: 'Hobbies',
    keywords: ['song', 'music', 'write', 'release', 'single'],
    minAge: 12,
    extraCheck: (l) =>
        l.stats['creativity'] < 40 ? 'Needs Creativity 40+' : null,
    run: (l, rng) {
      final quality = (l.stats['creativity'] * 0.7 + rng.nextInt(40)).round();
      final musician = l.careerId == 'musician';
      if (quality >= 85) {
        final pay = musician ? 8000 + rng.nextInt(20000) : 500;
        l.money += pay;
        l.flags['hit_song'] = Memory(l.age, 'writing a hit song');
        if (musician) l.performance = min(100, l.performance + 20);
        return ActionResult(
          'Your song took off. Strangers are humming it on the bus.',
          ['Song quality $quality/100', 'Money +${_m(pay)}'],
        );
      }
      if (musician) l.performance = min(100, l.performance + 3);
      return ActionResult(
        quality >= 60
            ? 'A solid song. Your fans liked it; the charts did not notice.'
            : 'Not your best work. You will rewrite the chorus one day.',
        ['Song quality $quality/100'],
      );
    },
  ),
];
