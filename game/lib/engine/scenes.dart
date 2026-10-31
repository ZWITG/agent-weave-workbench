import 'dart:math';

import 'lifespan.dart';
import 'dynasty.dart';
import 'finance.dart';
import 'health.dart';
import 'homes.dart';
import 'heists.dart';
import 'gangs.dart';
import 'kin.dart';
import 'possessions.dart';
import 'recap.dart';
import 'relationships.dart' show reactionScene;
import 'crime_jobs.dart';
import 'pets.dart';
import 'prison_life.dart';
import 'social.dart';
import 'celebrity.dart';
import 'country_life.dart';
import 'music.dart';
import 'births.dart' show birthScene;
import 'life_events.dart' show lifeEventScene;
import 'underworld.dart' show underworldScene;
import 'migration.dart' show migrationScene;
import 'business_kinds.dart' show tradeEventScene;
import 'elite.dart';
import 'community.dart';
import 'identity.dart';
import 'justice.dart';
import 'family.dart';
import 'jobs.dart';
import 'love.dart';
import 'models.dart';
import 'news_impact.dart';
import 'property.dart';
import 'school.dart';
import 'storylet.dart';

/// Code-driven events ("scenes"): the same event card as storylets, but
/// their choices run Dart code (interviews, trials, illnesses, births...).
/// A scene is queued by id ("illness:flu") on life.sceneQueue and rebuilt
/// from that id, so a pending scene survives saving.

Storylet? buildScene(String id, Life life) {
  final parts = id.split(':');
  final arg = parts.length > 1 ? parts.sublist(1).join(':') : '';
  return switch (parts.first) {
    'illness' => _illness(id, arg, life),
    'retire_offer' => _retireOffer(id, life),
    'apply_uni' => applyUniScene(life),
    'choose_major' => life.school.major == null ? chooseMajorScene() : null,
    'apply_grad' => applyGradScene(),
    'exams' => examScene(life),
    'lessons' => lessonsScene(),
    'tryouts' => tryoutsScene(life),
    'cheat' => cheatScene(),
    'job_offer' => jobOfferScene(parts.sublist(1), life),
    'interview' =>
      parts.length == 3
          ? interviewScene(life, parts[1], int.tryParse(parts[2]) ?? 0)
          : null,
    'kindling' ||
    'proposal' ||
    'prenup' ||
    'wedding' ||
    'divorce' ||
    'affair_found' ||
    'ultimatum' ||
    'partner_affair' => loveScene(parts.first, life),
    'parents_split' ||
    'family_planning' ||
    'birth' ||
    'adopt' => familyScene(parts.first, life),
    'baby_surprise' ||
    'baby_lover' ||
    'baby_fling' ||
    'baby_ex' ||
    'birth_plan' ||
    'adopted_reunion' => birthScene(parts.first, parts.sublist(1), life),
    'loss' ||
    'estate' ||
    'honeymoon' ||
    'fired_now' ||
    'child_wedding' ||
    'grandchild' ||
    'step_parent' => lifeEventScene(parts.first, parts.sublist(1), life),
    'crew_pick' ||
    'crew_invite' ||
    'crew_initiation' ||
    'crew_test' ||
    'crew_rival' ||
    'crew_cops' ||
    'crew_found_out' ||
    'crew_coup' ||
    'crew_leave' ||
    'biz_racket' ||
    'unexplained_wealth' => underworldScene(
      parts.first,
      parts.sublist(1),
      life,
    ),
    'immigration_check' => migrationScene(parts.first, parts.sublist(1), life),
    'will' => willScene(),
    'burnout' ||
    'audition' ||
    'election' ||
    'deployment' ||
    'hospital_case' ||
    'big_case' ||
    'police_case' => jobScene(parts.first, life),
    'debt_crisis' => debtCrisisScene(life),
    'biz_found' ||
    'biz_tier' ||
    'biz_fund' ||
    'insolvency' => businessScene(parts.first, parts.sublist(1), life),
    'biz_event' => tradeEventScene(parts.sublist(1), life),
    'hunt_purpose' ||
    'old_home' ||
    'let_pick' ||
    'let_trouble' ||
    'let_list' ||
    'let_manage' ||
    'remortgage' ||
    'landlord_rise' ||
    'landlord_sells' => propertyScene(parts.first, parts.sublist(1), life),
    'house_hunt' ||
    'house_view' ||
    'bidding' ||
    'flat_hunt' ||
    'car_dealer' ||
    'car_pay' => homeScene(parts.first, parts.sublist(1), life),
    'arrest' ||
    'charge' ||
    'lawyer' ||
    'trial' ||
    'parole' ||
    'escape' ||
    'escape_tool' ||
    'appeal' ||
    'prison_job' => justiceScene(parts.first, parts.sublist(1), life),
    'symptom' ||
    'treat' ||
    'mind' ||
    'rehab' => healthScene(parts.first, parts.sublist(1), life),
    'heist' ||
    'heist_crew' ||
    'heist_intel' ||
    'heist_go' => heistScene(parts.first, parts.sublist(1), life),
    'sue' ||
    'sue_lawyer' ||
    'sue_offer' ||
    'sue_trial' ||
    'sued' => lawsuitScene(parts.first, parts.sublist(1), life),
    'riot' => riotScene(life),
    'gang_pick' ||
    'gang_initiation' ||
    'gang_order' ||
    'gang_war' ||
    'gang_pressure' ||
    'gang_leave' => gangScene(parts.first, parts.sublist(1), life),
    'news_hit' => newsScene(parts.sublist(1), life),
    'crime_plan' ||
    'crime_go' ||
    'crime_twist' ||
    'crime_car' ||
    'murder_pick' ||
    'murder_how' => crimeJobScene(parts.first, parts.sublist(1), life),
    'visit_pick' ||
    'visit' ||
    'prison_course' ||
    'trustee' ||
    'on_the_run' ||
    'parole_checkin' ||
    'old_crew' => prisonLifeScene(parts.first, parts.sublist(1), life),
    'brand_deal' ||
    'scandal' ||
    'comeback' => socialScene(parts.first, parts.sublist(1), life),
    'release_pick' ||
    'release_how' ||
    'album_how' ||
    'label_offer' ||
    'underground_intro' => musicScene(parts.first, parts.sublist(1), life),
    'elite_intro' ||
    'elite_billion' ||
    'elite_leak' ||
    'elite_ask' ||
    'elite_threat' ||
    'elite_island' ||
    'elite_team' => eliteScene(parts.first, parts.sublist(1), life),
    'draft' => countryScene(parts.first, parts.sublist(1), life),
    'fame_rumour' ||
    'fame_stalker' ||
    'fame_award' ||
    'fame_feud' => celebrityScene(parts.first, parts.sublist(1), life),
    'pet_adopt' ||
    'pet_name' ||
    'stray' => petScene(parts.first, parts.sublist(1), life),
    'coming_out' ||
    'name_change' => identityScene(parts.first, parts.sublist(1), life),
    'emigrate' ||
    'shop' ||
    'party' ||
    'black_market' => communityScene(parts.first, parts.sublist(1), life),
    'funeral_wish' => funeralWishScene(),
    'collect_market' ||
    'boat_dealer' ||
    'plane_dealer' ||
    'home_upgrade' ||
    'disaster' => possessionScene(parts.first, parts.sublist(1), life),
    'foster_offer' ||
    'foster_end' ||
    'surrogacy' ||
    'season' => kinScene(parts.first, parts.sublist(1), life),
    'reaction' => reactionScene(parts.sublist(1), life),
    _ => null,
  };
}

Storylet _scene(
  String id,
  String text,
  List<Choice> choices, {
  String category = 'life',
}) => Storylet(
  id: 'scene:$id',
  text: text,
  choices: choices,
  category: category,
  scene: true,
);

String _m(int v) =>
    '\$${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}';

// ---------------- Everyday illness (plan HE-001: GP and ER) ----------------

typedef Illness = ({
  String name,
  String text,
  int severity,
  int minAge,
  int maxAge,
});

const illnesses = <String, Illness>{
  'flu': (
    name: 'the flu',
    text: 'You wake up shivering under three blankets. Everything aches, even your hair. The thermometer says you are not going anywhere today.',
    severity: 6,
    minAge: 3,
    maxAge: 120,
  ),
  'chickenpox': (
    name: 'chickenpox',
    text: 'You are covered in itchy red spots from head to toe. {mother} has hidden the scratchy jumpers and bought a bottle of pink lotion.',
    severity: 4,
    minAge: 2,
    maxAge: 11,
  ),
  'ear': (
    name: 'an ear infection',
    text: 'Your ear throbs like there is a tiny drummer inside it. You can barely hear the TV, and you have cried twice since breakfast.',
    severity: 4,
    minAge: 1,
    maxAge: 12,
  ),
  'food': (
    name: 'food poisoning',
    text: 'That reheated takeaway was a mistake. You have spent the night on the bathroom floor, promising the universe you will never eat prawns again.',
    severity: 5,
    minAge: 10,
    maxAge: 120,
  ),
  'ankle': (
    name: 'a sprained ankle',
    text: 'You stepped off a kerb wrong and heard a pop. Your ankle has swollen to the size of a grapefruit and turned an interesting purple.',
    severity: 5,
    minAge: 8,
    maxAge: 120,
  ),
  'migraine': (
    name: 'migraines',
    text: 'For a week, blinding headaches have come out of nowhere. Bright light feels like knives, and you have had to lie down in the dark twice.',
    severity: 5,
    minAge: 14,
    maxAge: 120,
  ),
  'back': (
    name: 'back pain',
    text: 'Your lower back has seized up. Putting on socks has become a twenty-minute project involving a lot of swearing.',
    severity: 5,
    minAge: 30,
    maxAge: 120,
  ),
  'chest': (
    name: 'a chest infection',
    text: 'A cough that started as a tickle has moved into your chest. You wheeze on the stairs and sleep propped up on four pillows.',
    severity: 7,
    minAge: 50,
    maxAge: 120,
  ),
};

/// Picks an illness that fits the age, or null.
String? pickIllness(Life life, Random rng) {
  final fits = illnesses.entries
      .where((e) => life.age >= e.value.minAge && life.age <= e.value.maxAge)
      .toList();
  if (fits.isEmpty) return null;
  return fits[rng.nextInt(fits.length)].key;
}

Storylet? _illness(String id, String key, Life life) {
  final ill = illnesses[key];
  if (ill == null) return null;
  final gpCost = careCost(life, 80);
  final erCost = careCost(life, 400);
  final sev = ill.severity;
  return _scene(id, ill.text, category: 'health', [
    Choice(
      label: gpCost > 0 ? 'See a GP (${_m(gpCost)})' : 'Go to the doctor',
      outcome: '',
      risk: 'Likely to help',
      lock: (l) => l.money < gpCost ? 'Needs ${_m(gpCost)}' : null,
      run: (l, rng) {
        l.reason = 'Treated ${ill.name}';
        l.money -= gpCost;
        l.stats.add('health', sev ~/ 2 + 2);
        return 'The doctor listened, prodded and diagnosed ${ill.name}. A prescription and a few days of rest later, you felt like yourself again.';
      },
    ),
    Choice(
      label: erCost > 0
          ? 'Go to the emergency room (${_m(erCost)})'
          : 'Go to the emergency room',
      outcome: '',
      risk: 'Fast, costly',
      lock: (l) => l.money < erCost ? 'Needs ${_m(erCost)}' : null,
      run: (l, rng) {
        l.reason = 'Emergency care';
        l.money -= erCost;
        l.stats.add('health', sev);
        l.stats.add('happiness', -1);
        return 'Four hours in a plastic chair, then a brisk young doctor sorted you out in ten minutes. Expensive, but you walked out feeling much better.';
      },
    ),
    Choice(
      label: 'Ask a pharmacist (\$15)',
      outcome: '',
      risk: 'Cheap · fine for mild illnesses',
      needsMoney: 15,
      run: (l, rng) {
        l.reason = 'Pharmacy for ${ill.name}';
        l.money -= 15;
        if (sev <= 6 || rng.nextInt(100) < 40) {
          l.stats.add('health', sev ~/ 3 + 1);
          return 'The pharmacist knew exactly what you needed. Three days later you were fine.';
        }
        l.stats.add('health', -1);
        return 'The pharmacist frowned and told you to see a doctor if it did not clear up. It did not, for a while.';
      },
    ),
    Choice(
      label: 'Rest at home',
      outcome: '',
      risk: 'Usually fine',
      run: (l, rng) {
        l.reason = 'Resting off ${ill.name}';
        if (rng.nextInt(100) < 70) {
          l.stats.add('health', 1);
          return 'You stayed in bed with tea and terrible daytime TV. It took a week, but it passed.';
        }
        l.stats.add('health', -sev ~/ 2);
        return 'You rested, but it dragged on and got worse before it got better. A doctor might have sped things up.';
      },
    ),
    Choice(
      label: 'Ignore it',
      outcome: '',
      risk: 'Risky',
      run: (l, rng) {
        l.reason = 'Ignored ${ill.name}';
        l.stats.add('health', -sev);
        l.stats.add('willpower', 1);
        return 'You carried on as if nothing was wrong. Your body disagreed, loudly, for weeks.';
      },
    ),
  ]);
}

// ---------------- Retirement (plan CA-010) ----------------

Storylet? _retireOffer(String id, Life life) {
  if (life.job == null || life.retired) return null;
  return _scene(
    id,
    'Your manager calls you in for a chat. "You have given this place ${life.yearsWorked} years," she says. "If you ever want to retire, there is a lovely leaving do in it for you. No pressure."',
    [
      Choice(
        label: 'Retire now',
        outcome: '',
        run: (l, rng) {
          l.reason = 'Retiring';
          final text = retire(l);
          l.stats.add('happiness', 6);
          return '$text There was cake, a card signed by people you had never met and a speech that made you cry. Your pension is ${_m(l.pension)} a year.';
        },
      ),
      Choice(
        label: 'Keep working',
        outcome: 'You said you had a few good years left in you. Your manager looked relieved; nobody else knows where anything is kept.',
        effects: Effects(stats: {'discipline': 2}),
      ),
    ],
  );
}
