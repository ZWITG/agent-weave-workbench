import 'dart:math';

import 'actions.dart';
import 'models.dart';
import 'storylet.dart';

/// Health, body and mind (plan Module 9): chronic and serious conditions
/// that always show symptoms first, diagnosis and treatment with costs and
/// odds, healthcare and insurance by country, addictions and recovery,
/// mental health with support options (and a real-life helpline panel in
/// the UI), a fitness meter, and the people around you growing old.

String _m(int v) {
  final s = v.abs().toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '−' : ''}\$$s';
}

typedef ConditionInfo = ({
  String id,
  String name,
  String kind,
  int minAge,
  double onset,
  int meds,
  String symptom,
  String late,
});

const conditionInfo = <String, ConditionInfo>{
  'asthma': (
    id: 'asthma',
    name: 'Asthma',
    kind: 'chronic',
    minAge: 3,
    onset: 0.002,
    meds: 300,
    symptom: 'You get out of breath on the stairs, and a dry cough keeps you awake at night.',
    late: '',
  ),
  'diabetes': (
    id: 'diabetes',
    name: 'Type 2 diabetes',
    kind: 'chronic',
    minAge: 30,
    onset: 0.003,
    meds: 1200,
    symptom: 'You are always thirsty, always tired, and a small cut on your hand is taking weeks to heal.',
    late: '',
  ),
  'hypertension': (
    id: 'hypertension',
    name: 'High blood pressure',
    kind: 'chronic',
    minAge: 40,
    onset: 0.005,
    meds: 400,
    symptom: 'Headaches most mornings, and the blood-pressure machine at the pharmacy beeped at you in alarm.',
    late: '',
  ),
  'arthritis': (
    id: 'arthritis',
    name: 'Arthritis',
    kind: 'chronic',
    minAge: 50,
    onset: 0.005,
    meds: 500,
    symptom: 'Your knees and fingers ache every morning and take an hour to loosen up.',
    late: '',
  ),
  'heart': (
    id: 'heart',
    name: 'Heart disease',
    kind: 'serious',
    minAge: 45,
    onset: 0.002,
    meds: 2000,
    symptom: 'A tight, heavy feeling in your chest when you climb the stairs. It passes, then comes back.',
    late: 'Chest pain wakes you at night and you are short of breath even sitting down.',
  ),
  'cancer': (
    id: 'cancer',
    name: 'Cancer',
    kind: 'serious',
    minAge: 30,
    onset: 0.0015,
    meds: 0,
    symptom: 'A lump that was not there before, and you have been losing weight without trying.',
    late: 'You are exhausted all the time and the pain is getting harder to ignore.',
  ),
  'kidney': (
    id: 'kidney',
    name: 'Kidney disease',
    kind: 'serious',
    minAge: 50,
    onset: 0.001,
    meds: 8000,
    symptom: 'Swollen ankles, constant tiredness and a strange metallic taste in your mouth.',
    late: 'You feel sick most days and your legs have swollen badly.',
  ),
  'depression': (
    id: 'depression',
    name: 'Depression',
    kind: 'mind',
    minAge: 12,
    onset: 0,
    meds: 0,
    symptom: 'For months everything has felt grey and heavy. Getting out of bed takes everything you have. This is depression, and it is treatable.',
    late: '',
  ),
  'anxiety': (
    id: 'anxiety',
    name: 'Anxiety',
    kind: 'mind',
    minAge: 12,
    onset: 0,
    meds: 0,
    symptom: 'Your heart races for no reason, your thoughts spiral at 3am and ordinary things feel impossible. This is anxiety, and it is treatable.',
    late: '',
  ),
  'grief': (
    id: 'grief',
    name: 'Grief',
    kind: 'mind',
    minAge: 5,
    onset: 0,
    meds: 0,
    symptom: 'Since the funeral, the world has kept going and you have not. Grief comes in waves, and you do not have to carry it alone.',
    late: '',
  ),
  'insomnia': (
    id: 'insomnia',
    name: 'Insomnia',
    kind: 'mind',
    minAge: 14,
    onset: 0,
    meds: 0,
    symptom: 'You lie awake every night watching the ceiling. You are running on four hours of sleep and it shows.',
    late: '',
  ),
};

Condition? conditionOf(Life l, String id) =>
    l.conditions.where((c) => c.id == id).firstOrNull;

// ---------------- Healthcare and insurance ----------------

/// Healthcare system by country (plan: country data).
const healthSystems = {
  'Portugal': 'universal',
  'Ireland': 'universal',
  'Netherlands': 'universal',
  'United States': 'insurance',
  'Nigeria': 'out of pocket',
  'Philippines': 'out of pocket',
};

String healthSystem(Life l) => healthSystems[l.country] ?? 'universal';

const insurancePlans = {
  'none': (label: 'No insurance', premium: 0, covers: 0.0),
  'basic': (label: 'Basic', premium: 1800, covers: 0.6),
  'full': (label: 'Full', premium: 4800, covers: 0.9),
};

int insurancePremium(Life l) {
  if (l.age < 18 || healthSystem(l) == 'universal') return 0;
  final base = insurancePlans[l.insurance]?.premium ?? 0;
  return healthSystem(l) == 'out of pocket' ? (base * 0.3).round() : base;
}

/// What a treatment that lists at [base] dollars costs you here.
int careCost(Life l, int base) {
  if (l.age < 18) return 0;
  final system = healthSystem(l);
  if (system == 'universal') return (base * 0.05 / 10).round() * 10;
  final local = system == 'out of pocket' ? base * 0.35 : base.toDouble();
  final covers = insurancePlans[l.insurance]?.covers ?? 0;
  return (local * (1 - covers) / 10).round() * 10;
}

String careNote(Life l) => switch (healthSystem(l)) {
  'universal' => 'Universal healthcare: treatment is nearly free',
  'insurance' =>
    l.insurance == 'none'
        ? 'No health insurance: you pay full price'
        : '${insurancePlans[l.insurance]!.label} insurance covers ${(insurancePlans[l.insurance]!.covers * 100).round()}%',
  _ =>
    l.insurance == 'none'
        ? 'You pay for care yourself'
        : '${insurancePlans[l.insurance]!.label} insurance covers ${(insurancePlans[l.insurance]!.covers * 100).round()}%',
};

/// Yearly health costs for the cash flow: premium, medication, therapy,
/// and what addictions cost.
List<(String, int)> healthCosts(Life l) {
  final out = <(String, int)>[];
  final premium = insurancePremium(l);
  if (premium > 0) out.add(('Health insurance', -premium));
  var meds = 0;
  for (final c in l.conditions) {
    final info = conditionInfo[c.id];
    if (info == null || !c.treated) continue;
    if (info.kind == 'mind') {
      if (l.marks.contains('therapy:${c.id}')) meds += careCost(l, 1500);
    } else if (!l.marks.contains('lifestyle:${c.id}')) {
      meds += careCost(l, info.meds);
    }
  }
  if (meds > 0) out.add(('Medication and care', -meds));
  if (l.age >= 16) {
    if (l.addictions.containsKey('alcohol')) out.add(('Drinking', -1500));
    if (l.addictions.containsKey('nicotine')) out.add(('Cigarettes', -2000));
    if (l.addictions.containsKey('gambling')) {
      out.add(('Gambling losses', -max(500, (max(0, l.money) * 0.05).round())));
    }
  }
  return out;
}

// ---------------- Death risk and causes ----------------

/// Multiplier on the yearly death chance from conditions, addictions and
/// fitness (plan: conditionFactor × lifestyleFactor).
double healthRiskFactor(Life l) {
  var f = 1.0;
  for (final c in l.conditions) {
    final info = conditionInfo[c.id];
    if (info == null || c.treated) continue;
    if (info.kind == 'serious') {
      f *= switch (c.stage) {
        >= 4 => 12.0,
        3 => 3.0,
        2 => 1.5,
        _ => 1.1,
      };
    } else if (c.id == 'hypertension') {
      f *= 1.3;
    } else if (c.id == 'diabetes') {
      f *= 1.2;
    }
  }
  if (l.addictions.containsKey('alcohol')) f *= 1.3;
  if (l.addictions.containsKey('nicotine')) f *= 1.4;
  if (l.fitness >= 70) f *= 0.85;
  if (l.fitness <= 20) f *= 1.2;
  return f;
}

/// A condition that explains a death (it always showed symptoms first).
String? conditionCause(Life l) {
  final serious =
      l.conditions.where((c) => conditionInfo[c.id]?.kind == 'serious').toList()
        ..sort((a, b) => b.stage.compareTo(a.stage));
  if (serious.isNotEmpty && serious.first.stage >= 2) {
    return conditionInfo[serious.first.id]!.name;
  }
  return null;
}

// ---------------- Addictions ----------------

const addictionNames = {
  'alcohol': 'Alcohol',
  'nicotine': 'Nicotine',
  'gambling': 'Gambling',
  'gaming': 'Gaming',
};

/// Plan: p = baseRisk × (1.5 − Willpower/100) × (1 + Stress/200), raised
/// by impulsivity. Returns a note when an addiction starts.
String? exposeTo(Life l, String kind, Random rng) {
  if (l.addictions.containsKey(kind)) return null;
  final base = switch (kind) {
    'alcohol' => 0.04,
    'nicotine' => 0.05,
    'gambling' => 0.05,
    _ => 0.03,
  };
  final p =
      base *
      (1.5 - l.stats['willpower'] / 100) *
      (1 + l.stress / 200) *
      (0.5 + l.stats['impulsivity'] / 100) *
      (l.recovery.containsKey(kind) ? 2 : 1);
  if (rng.nextDouble() >= p) return null;
  l.addictions[kind] = 0;
  l.recovery.remove(kind);
  l.flags['addiction_$kind'] = Memory(
    l.age,
    'your struggle with ${addictionNames[kind]!.toLowerCase()}',
  );
  return switch (kind) {
    'alcohol' => 'You have started needing a drink to unwind. Every night. (Addiction: alcohol. Help is in the Health screen.)',
    'nicotine' =>
      'One cigarette at a party became a pack a day. (Addiction: nicotine.)',
    'gambling' => 'You keep thinking about the next bet, and the one after that. (Addiction: gambling.)',
    _ => 'One more game has turned into six hours, most nights. (Addiction: gaming.)',
  };
}

// ---------------- The yearly body and mind ----------------

/// Each birthday: fitness, conditions (onsets always come with symptoms),
/// mental health, addictions and relapse.
List<String> healthYear(Life l, Random rng) {
  final feed = <String>[];
  l.reason = 'Health';
  // Fitness (plan: ΔFitness = activity gains − decay). Children run
  // around anyway; adults lose a little every year unless they train.
  if (l.age < 18) {
    if (l.fitness < 55) l.fitness += 3;
  } else {
    l.fitness = (l.fitness - 2 - (l.age >= 50 ? 1 : 0)).clamp(0, 100);
  }
  l.reason = 'Fitness';
  if (l.fitness >= 70) l.stats.add('health', 1);
  if (l.fitness <= 15 && rng.nextBool()) l.stats.add('health', -1);

  for (final c in l.conditions.toList()) {
    final info = conditionInfo[c.id];
    if (info == null) continue;
    switch (info.kind) {
      case 'serious':
        if (c.treated) break;
        if (c.stage < 4 && rng.nextInt(100) < 60) c.stage++;
        l.reason = info.name;
        l.stats.add('health', -c.stage);
        if (c.stage >= 3 && !c.known) l.sceneQueue.add('symptom:${c.id}');
      case 'chronic':
        if (c.treated) break;
        l.reason = info.name;
        if (c.id == 'arthritis') {
          l.stats.add('happiness', -2);
        } else {
          l.stats.add('health', c.id == 'diabetes' ? -2 : -1);
        }
      case 'mind':
        final odds = c.treated
            ? 45
            : c.id == 'grief'
            ? 35
            : 12;
        if (rng.nextInt(100) < odds) {
          l.conditions.remove(c);
          l.marks.remove('therapy:${c.id}');
          l.marks.add('recovered:${l.age}');
          feed.add(
            c.id == 'grief'
                ? 'The grief has softened. You still miss them, but you can smile at the memories now.'
                : 'You notice you feel like yourself again. ${info.name} has eased${c.treated ? ', and the support helped' : ''}.',
          );
        } else {
          l.reason = info.name;
          l.stats.add('happiness', c.treated ? -1 : -3);
        }
    }
  }

  // New conditions: chance rises with age, poor health, low fitness,
  // smoking and drinking.
  for (final info in conditionInfo.values) {
    if (info.kind == 'mind' || l.age < info.minAge) continue;
    if (conditionOf(l, info.id) != null) continue;
    var p =
        (info.id == 'asthma'
            ? (l.age < 30 ? info.onset : info.onset / 4)
            : info.onset * exp(0.04 * (l.age - info.minAge))) *
        (1 + (50 - l.stats['health']) / 50).clamp(0.7, 1.8);
    if (l.fitness < 25) p *= 1.5;
    if (l.fitness > 70) p *= 0.7;
    if (l.addictions.containsKey('nicotine') &&
        (info.id == 'heart' || info.id == 'cancer' || info.id == 'asthma')) {
      p *= 2;
    }
    if (l.addictions.containsKey('alcohol') &&
        (info.id == 'heart' || info.id == 'kidney')) {
      p *= 1.5;
    }
    if (rng.nextDouble() < p) {
      l.conditions.add(Condition(id: info.id, since: l.age));
      l.sceneQueue.add('symptom:${info.id}');
      break;
    }
  }

  // Mental health onsets come from long low mood, high stress or loss,
  // never at random (and not again straight after recovering).
  l.lowMoodYears = l.stats['happiness'] < 30 ? l.lowMoodYears + 1 : 0;
  l.highStressYears = l.stress > 75 ? l.highStressYears + 1 : 0;
  final cooling = [for (var a = l.age - 3; a < l.age; a++) 'recovered:$a']
      .any(l.marks.contains);
  if (cooling) {
    // Give recovery room to breathe.
  } else if (l.lowMoodYears >= 2 && conditionOf(l, 'depression') == null) {
    _mindOnset(l, 'depression');
  } else if (l.highStressYears >= 2 && conditionOf(l, 'anxiety') == null) {
    _mindOnset(l, 'anxiety');
  } else if (l.stress > 60 &&
      conditionOf(l, 'insomnia') == null &&
      rng.nextInt(100) < 8) {
    _mindOnset(l, 'insomnia');
  }

  // Addictions and recovery (plan: relapse risk 25% in year 1, falling).
  for (final e in l.addictions.entries.toList()) {
    l.addictions[e.key] = e.value + 1;
    l.reason = '${addictionNames[e.key]} addiction';
    switch (e.key) {
      case 'alcohol':
        l.stats.add('health', -3);
        l.stats.add('happiness', -1);
        if (l.job != null) l.performance = max(0, l.performance - 8);
      case 'nicotine':
        l.stats.add('health', -2);
      case 'gambling':
        l.stress = l.stress + 5;
      default:
        l.stats.add('happiness', -1);
        if (l.age < 22) l.school.effort = max(0, l.school.effort - 10);
    }
  }
  for (final e in l.recovery.entries.toList()) {
    const risk = [25, 15, 10, 5, 3];
    final r = (risk[min(e.value, risk.length - 1)] * (1 + l.stress / 200))
        .round();
    if (rng.nextInt(100) < r) {
      l.recovery.remove(e.key);
      l.addictions[e.key] = 0;
      feed.add(
        'After ${e.value} ${e.value == 1 ? 'year' : 'years'} clean, you slipped back into ${addictionNames[e.key]!.toLowerCase()}. Recovery is not a straight line; help is still there when you want it.',
      );
    } else if (e.value >= 10) {
      l.recovery.remove(e.key);
    } else {
      l.recovery[e.key] = e.value + 1;
    }
  }
  return feed;
}

void _mindOnset(Life l, String id) {
  l.conditions.add(Condition(id: id, since: l.age, known: true));
  l.sceneQueue.add('mind:$id');
}

// ---------------- The people around you grow old ----------------

/// NPCs age and die (rarely young, more often old). Close losses bring
/// grief. Returns feed lines.
List<String> npcAging(Life l, Random rng) {
  final feed = <String>[];
  for (final n in l.npcs) {
    if (!n.alive) continue;
    final age = n.ageIn(l.year);
    if (age < 40) continue;
    final q = (0.00002 * exp(0.085 * age) * 1.3).clamp(0.0, 0.6);
    if (rng.nextDouble() >= q) continue;
    n.alive = false;
    n.info['diedAge'] = age;
    const close = {'Family', 'Partner', 'Friends', 'Children'};
    if (!close.contains(n.circle)) continue;
    feed.add(
      '${n.circle == 'Partner' ? 'Your ${n.role.toLowerCase()}' : n.role} ${n.name} died at $age. ${n.bond >= 60 ? 'You were there at the end, holding their hand.' : 'You had not spoken in a while.'}',
    );
    if (n.circle == 'Partner') {
      l.flags['widowed'] = Memory(l.age, 'losing ${n.name}');
    }
    if (n.bond >= 60 && conditionOf(l, 'grief') == null) {
      _mindOnset(l, 'grief');
    }
    l.reason = 'Losing ${n.name}';
    l.stats.add('happiness', n.bond >= 60 ? -10 : -3);
    break;
  }
  return feed;
}

// ---------------- Scenes ----------------

Storylet _scene(
  String id,
  String text,
  List<Choice> choices, {
  String category = 'health',
}) => Storylet(
  id: 'scene:$id',
  text: text,
  category: category,
  scene: true,
  choices: choices,
);

/// Treatment odds by stage (plan: early detection matters).
int _odds(List<int> byStage, int stage) =>
    byStage[(stage - 1).clamp(0, byStage.length - 1)];

Storylet? healthScene(String id, List<String> args, Life l) {
  switch (id) {
    case 'symptom':
      final c = conditionOf(l, args.first);
      final info = conditionInfo[args.first];
      if (c == null || info == null || c.known) return null;
      final gp = careCost(l, 80);
      final full = careCost(l, 400);
      String diagnose(Life l, Random rng, int odds, String how) {
        if (rng.nextInt(100) < odds) {
          c.known = true;
          l.sceneQueue.add('treat:${c.id}');
          return '$how The diagnosis: ${info.name.toLowerCase()}${info.kind == 'serious' ? ', stage ${c.stage}' : ''}.';
        }
        return '$how The doctor thinks it is stress. "Come back if it gets worse."';
      }

      return _scene(
        id,
        c.stage >= 3 && info.late.isNotEmpty ? info.late : info.symptom,
        [
          Choice(
            label: 'See a GP${gp > 0 ? ' (${_m(gp)})' : ''}',
            outcome: '',
            risk: info.kind == 'serious'
                ? 'Often finds it'
                : 'Likely to find it',
            needsMoney: gp,
            run: (l, rng) {
              l.money -= gp;
              return diagnose(
                l,
                rng,
                info.kind == 'serious' ? 70 : 85,
                'The GP listened carefully and ran some tests.',
              );
            },
          ),
          Choice(
            label:
                'Full check-up with scans${full > 0 ? ' (${_m(full)})' : ''}',
            outcome: '',
            risk: 'Almost always finds it',
            needsMoney: full,
            run: (l, rng) {
              l.money -= full;
              return diagnose(
                l,
                rng,
                95,
                'Blood tests, scans and a lot of waiting rooms.',
              );
            },
          ),
          Choice(
            label: 'Wait and see',
            outcome: '',
            risk: info.kind == 'serious'
                ? 'Can get worse'
                : 'Usually gets worse',
            run: (l, rng) => 'You told yourself it was nothing. Your body keeps sending the message.',
          ),
        ],
      );
    case 'treat':
      final c = conditionOf(l, args.first);
      final info = conditionInfo[args.first];
      if (c == null || info == null) return null;
      Choice manage(
        String label,
        int base,
        String text, {
        bool lifestyle = false,
      }) {
        final cost = careCost(l, base);
        return Choice(
          label: lifestyle ? label : '$label (${_m(cost)} a year)',
          outcome: '',
          risk: lifestyle
              ? 'Needs Fitness 50+ and Willpower 50+'
              : 'Keeps it under control',
          lock: lifestyle
              ? (l) => l.fitness < 50 || l.stats['willpower'] < 50
                    ? 'Needs Fitness 50+ and Willpower 50+'
                    : null
              : null,
          run: (l, rng) {
            c.treated = true;
            if (lifestyle) l.marks.add('lifestyle:${c.id}');
            return text;
          },
        );
      }

      Choice cure(
        String label,
        int base,
        List<int> byStage,
        String win,
        String lose, {
        Map<String, int> side = const {},
      }) {
        final cost = careCost(l, base);
        final odds = _odds(byStage, c.stage);
        return Choice(
          label: '$label${cost > 0 ? ' (${_m(cost)})' : ' (free)'}',
          outcome: '',
          risk: '$odds% success at stage ${c.stage}',
          needsMoney: cost,
          run: (l, rng) {
            l.money -= cost;
            l.reason = label;
            side.forEach(l.stats.add);
            if (rng.nextInt(100) < odds) {
              l.conditions.remove(c);
              l.flags['survived_${c.id}'] = Memory(
                l.age,
                'beating ${info.name.toLowerCase()}',
              );
              l.stats.add('happiness', 8);
              return win;
            }
            l.stats.add('health', -6);
            return '$lose Odds were $odds% at stage ${c.stage}; catching it earlier helps.';
          },
        );
      }

      final decline = Choice(
        label: 'Decline treatment',
        outcome: '',
        risk: info.kind == 'serious' ? 'It will progress' : 'It will get worse',
        run: (l, rng) => 'You decided against treatment for now. You can change your mind from the Health screen.',
      );
      final head =
          'Diagnosis: ${info.name}${info.kind == 'serious' ? ', stage ${c.stage} of 4' : ''}. ${careNote(l)}.';
      switch (c.id) {
        case 'asthma':
          return _scene(id, '$head An inhaler keeps most people well.', [
            manage(
              'Inhaler and check-ups',
              info.meds,
              'You keep an inhaler in every pocket now. Breathing is easier.',
            ),
            manage(
              'Breathing exercises and fitness',
              0,
              'You built your lungs up with swimming and exercises.',
              lifestyle: true,
            ),
            decline,
          ]);
        case 'diabetes':
          return _scene(
            id,
            '$head It can be managed with medication, or sometimes with diet and exercise.',
            [
              manage(
                'Medication',
                info.meds,
                'Daily tablets and a blood-sugar monitor. You feel more awake than you have in years.',
              ),
              manage(
                'Diet and exercise',
                0,
                'You overhauled your diet and walk every day. Your doctor is impressed.',
                lifestyle: true,
              ),
              decline,
            ],
          );
        case 'hypertension':
          return _scene(
            id,
            '$head Untreated, it raises the risk of a stroke or heart attack.',
            [
              manage(
                'Daily tablets',
                info.meds,
                'One small tablet every morning. Your numbers came down within weeks.',
              ),
              manage(
                'Cut salt and exercise',
                0,
                'Less salt, more walking. Your blood pressure dropped.',
                lifestyle: true,
              ),
              decline,
            ],
          );
        case 'arthritis':
          return _scene(
            id,
            '$head There is no cure, but pain can be managed.',
            [
              manage(
                'Painkillers and physiotherapy',
                info.meds,
                'Physio twice a week and the right painkillers. Mornings are bearable again.',
              ),
              decline,
            ],
          );
        case 'heart':
          return _scene(id, '$head A specialist explains your options.', [
            cure(
              'Bypass surgery',
              60000,
              [90, 80, 60, 40],
              'The surgery went well. After three months of recovery, you can climb stairs again without thinking about it.',
              'The surgery did not fix it.',
            ),
            manage(
              'Medication and lifestyle changes',
              info.meds,
              'Statins, aspirin and a strict diet. It will not cure it, but it keeps it from getting worse.',
            ),
            decline,
          ]);
        case 'cancer':
          return _scene(
            id,
            '$head An oncologist walks you through the options. Your hands are shaking.',
            [
              cure(
                'Surgery',
                40000,
                [85, 70, 45, 25],
                'The surgeon removed it all. After months of check-ups, the word you were waiting for: remission.',
                'The surgery could not remove all of it.',
              ),
              cure(
                'Chemotherapy',
                25000,
                [75, 60, 40, 20],
                'Months of chemo, lost hair and endless tiredness, then the scan came back clear. Remission.',
                'The treatment was brutal and the scan still shows it.',
                side: {'happiness': -6, 'looks': -4},
              ),
              cure(
                'Join a clinical trial',
                0,
                [40, 40, 40, 40],
                'The new treatment worked. You will be in a medical journal.',
                'The trial drug did not work for you.',
                side: {'health': -3},
              ),
              Choice(
                label: 'Palliative care',
                outcome: '',
                risk: 'Comfort, not a cure',
                run: (l, rng) {
                  l.stats.add('happiness', 5);
                  l.marks.add('palliative');
                  return 'You chose comfort and time with the people you love. The nurses are kind, and the garden is lovely in the mornings.';
                },
              ),
              decline,
            ],
          );
        case 'kidney':
          return _scene(
            id,
            '$head A specialist talks about dialysis and transplants.',
            [
              manage(
                'Dialysis',
                info.meds,
                'Three afternoons a week attached to a machine. It is tiring, but it keeps you going.',
              ),
              cure(
                'Kidney transplant',
                50000,
                [80, 75, 65, 50],
                'A donor match came through. The new kidney started working the next day.',
                'Your body rejected the kidney.',
              ),
              decline,
            ],
          );
      }
      return null;
    case 'mind':
      final c = conditionOf(l, args.first);
      final info = conditionInfo[args.first];
      if (c == null || info == null) return null;
      final close =
          l.npcs
              .where(
                (n) =>
                    n.alive &&
                    n.bond >= 50 &&
                    const {'Family', 'Partner', 'Friends'}.contains(n.circle),
              )
              .toList()
            ..sort((a, b) => b.bond.compareTo(a.bond));
      final therapy = careCost(l, 1500);
      final psych = careCost(l, 600);
      return _scene(
        id,
        '${info.symptom} You do not have to fix this alone. What would help right now?',
        category: 'mind',
        [
          if (close.isNotEmpty)
            Choice(
              label: 'Talk to ${close.first.name.split(' ').first}',
              outcome: '',
              risk: 'Bond ${close.first.bond}%',
              run: (l, rng) {
                final n = close.first;
                n.addFacets(affection: 4, trust: 4);
                n.lastContactAge = l.age;
                l.stats.add('happiness', 4);
                if (rng.nextInt(100) < 25 + n.bond ~/ 4) c.treated = true;
                return '${n.name.split(' ').first} listened for two hours without once trying to fix it. Then they said, "I am here. Every week, if you want." It helped more than you expected.';
              },
            ),
          Choice(
            label:
                'See a therapist${therapy > 0 ? ' (${_m(therapy)} a year)' : ''}',
            outcome: '',
            risk: 'Helps most people',
            run: (l, rng) {
              c.treated = true;
              l.marks.add('therapy:${c.id}');
              l.stats.add('happiness', 3);
              return 'Your therapist has a soft voice and a box of tissues within reach. Week by week, it gets a little lighter.';
            },
          ),
          if (c.id != 'grief')
            Choice(
              label:
                  'Ask a doctor about medication${psych > 0 ? ' (${_m(psych)})' : ''}',
              outcome: '',
              risk: 'Takes a few weeks to work',
              needsMoney: psych,
              run: (l, rng) {
                l.money -= psych;
                c.treated = true;
                l.stats.add('happiness', 2);
                return 'The doctor took you seriously and started you on a low dose. After a few weeks, the fog began to lift.';
              },
            ),
          Choice(
            label: 'Join a support group (free)',
            outcome: '',
            run: (l, rng) {
              c.treated = true;
              l.stats.add('happiness', 2);
              return 'A circle of folding chairs and people who understand without explanation. You did not speak the first week. By the third, you did.';
            },
          ),
          if (l.job != null)
            Choice(
              label: 'Take time off work',
              outcome: '',
              risk: 'Performance −10',
              run: (l, rng) {
                l.stress = l.stress - 30;
                l.performance = max(0, l.performance - 10);
                if (rng.nextInt(100) < 35) c.treated = true;
                return 'Your boss said, "Take the time you need." You slept, walked and slowly came back to yourself.';
              },
            ),
          Choice(
            label: 'Not right now',
            outcome: '',
            run: (l, rng) => 'Okay. Support is always there in the Health screen when you are ready.',
          ),
        ],
      );
    case 'rehab':
      final kind = args.isNotEmpty && l.addictions.containsKey(args.first)
          ? args.first
          : l.addictions.keys.firstOrNull;
      if (kind == null) return null;
      final years = l.addictions[kind]!;
      final support = l.npcs
          .where(
            (n) =>
                n.alive &&
                const {'Family', 'Partner', 'Friends'}.contains(n.circle),
          )
          .fold(0, (a, n) => max(a, n.bond));
      final therapy = l.conditions.any(
        (c) => conditionInfo[c.id]?.kind == 'mind' && c.treated,
      );
      int odds(double bonus) =>
          ((0.35 +
                          l.stats['willpower'] / 200 +
                          support / 300 +
                          (therapy ? 0.1 : 0) -
                          years * 0.03 +
                          bonus)
                      .clamp(0.1, 0.9) *
                  100)
              .round();
      Choice option(String label, int base, double bonus, String text) {
        final cost = careCost(l, base);
        final p = odds(bonus);
        return Choice(
          label:
              '$label${base > 0 ? (cost > 0 ? ' (${_m(cost)})' : ' (covered)') : ''}',
          outcome: '',
          risk: '$p% chance (Willpower, support, years)',
          needsMoney: cost,
          run: (l, rng) {
            l.money -= cost;
            if (rng.nextInt(100) < p) {
              l.addictions.remove(kind);
              l.recovery[kind] = 0;
              l.flags['recovery_$kind'] = Memory(l.age, 'getting clean');
              l.stats.add('happiness', 6);
              return '$text It worked. You are in recovery. The first year is the hardest; you are not alone in it.';
            }
            l.stats.add('willpower', 2);
            return '$text It did not stick this time. Recovery is not a straight line, and every try teaches you something.';
          },
        );
      }

      return _scene(
        id,
        'You have lived with ${addictionNames[kind]!.toLowerCase()} addiction for $years ${years == 1 ? 'year' : 'years'}. Admitting it is the first step, and you just took it.',
        [
          option(
            'Outpatient programme',
            2000,
            0,
            'Evening sessions twice a week for three months.',
          ),
          option(
            'Residential rehab',
            15000,
            0.15,
            'Six weeks away from everything, with people who know exactly how this goes.',
          ),
          option(
            'Support group',
            0,
            -0.05,
            'Weekly meetings, a sponsor and a lot of bad coffee.',
          ),
          option(
            'Quit on my own',
            0,
            -0.15,
            'You poured it all away and gritted your teeth.',
          ),
        ],
      );
  }
  return null;
}

// ---------------- Actions ----------------

String? _hasAddiction(Life l) => l.addictions.isEmpty ? 'No addictions' : null;

final healthActions = <GameAction>[
  GameAction(
    id: 'rehab',
    label: 'Get help with an addiction',
    category: 'Health',
    priceNote: 'Free and paid options',
    keywords: [
      'rehab',
      'addiction',
      'quit',
      'sober',
      'recovery',
      'drinking',
      'smoking',
    ],
    minAge: 12,
    extraCheck: _hasAddiction,
    run: (l, rng) {
      l.sceneQueue.add('rehab:${l.addictions.keys.first}');
      return ActionResult('You made the call.');
    },
  ),
  GameAction(
    id: 'healer',
    label: 'Visit an alternative healer',
    category: 'Health',
    keywords: ['healer', 'alternative', 'crystals', 'herbal', 'remedy'],
    minAge: 16,
    cost: 150,
    hint: (l) =>
        'Costs \$150 · not a real treatment · risk rises with repeat visits',
    run: (l, rng) {
      l.money -= 150;
      final visits = l.marks.where((m) => m.startsWith('healer:')).length;
      l.marks.add('healer:${l.age}');
      if (rng.nextInt(100) < 10 + visits * 5) {
        l.reason = 'Alternative healer';
        l.stats.add('health', -5);
        return ActionResult(
          'The "detox tea" made you violently ill. Nothing the healer does can treat a real condition.',
          ['Money −\$150', 'Health −5', 'Risk was ${10 + visits * 5}%'],
        );
      }
      l.reason = 'Alternative healer';
      l.stats.add('happiness', 2);
      return ActionResult(
        'Incense, soft music and a lot of confident talk. You felt calmer. ${l.conditions.isEmpty ? '' : 'Your ${conditionInfo[l.conditions.first.id]?.name.toLowerCase() ?? 'condition'} has not changed: this is not a real treatment.'}',
        ['Money −\$150', 'Happiness +2'],
      );
    },
  ),
];

/// "End this life" (plan): neutral, out of character, straight to the
/// recap. Never awards achievements.
void endThisLifeRules(Life l) {
  l.alive = false;
  l.endedEarly = true;
  l.causeOfDeath = 'Life ended early';
  l.feed.add(
    FeedEntry(
      l.age,
      'This life was ended from the menu at ${l.age}.',
      kind: 'milestone',
    ),
  );
}
