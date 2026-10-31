import 'package:flutter/material.dart';

import '../engine/actions.dart';
import '../engine/odds.dart';
import '../engine/profile.dart';
import '../engine/models.dart';
import '../engine/music.dart';
import '../engine/currency.dart';
import '../engine/elite.dart';
import '../engine/relationships.dart';
import '../engine/variants.dart';
import '../game_controller.dart';
import '../sound.dart';
import '../theme.dart';
import 'health_screen.dart' show CrimeProfileCard;
import 'minigames.dart';
import 'move_abroad.dart';
import 'newspaper.dart';
import 'social_screen.dart';
import 'people.dart';
import 'result_popup.dart';
import 'shop_screen.dart';
import 'widgets.dart';

/// Category order and icons for the Activities panel.
const activityCategories = <(String, IconData)>[
  ('Wellbeing', Icons.self_improvement_rounded),
  ('Health', Icons.medical_services_rounded),
  ('School', Icons.school_rounded),
  ('Work', Icons.work_rounded),
  ('Money', Icons.savings_rounded),
  ('Love', Icons.favorite_rounded),
  ('Social', Icons.celebration_rounded),
  ('Upper echelon', Icons.diamond_rounded),
  ('Music', Icons.music_note_rounded),
  ('Social media', Icons.phone_iphone_rounded),
  ('Fame', Icons.star_rounded),
  ('Hobbies', Icons.palette_rounded),
  ('Travel', Icons.flight_rounded),
  ('Assets', Icons.home_work_rounded),
  ('Pets', Icons.pets_rounded),
  ('Licences', Icons.badge_rounded),
  ('Identity', Icons.face_rounded),
  ('Faith', Icons.self_improvement_rounded),
  ('Law', Icons.gavel_rounded),
  ('Crime', Icons.local_police_rounded),
  ('Prison', Icons.door_sliding_rounded),
  ('News', Icons.newspaper_rounded),
  ('Family', Icons.family_restroom_rounded),
  ('Seasonal', Icons.event_available_rounded),
];

/// The categories in a few friendly groups, so the home view reads as a
/// handful of short sections instead of one big grid.
const activityGroups = <(String, String, List<String>)>[
  (
    'The upper echelon',
    'Life among the richest people alive',
    ['Upper echelon'],
  ),
  (
    'Look after yourself',
    'Body, mind and the things you love',
    ['Wellbeing', 'Health', 'Hobbies', 'Faith'],
  ),
  ('People', 'Love, friends and family', ['Love', 'Social', 'Family']),
  (
    'Music, fame and social media',
    'Songs, posts, followers and the spotlight',
    ['Music', 'Social media', 'Fame'],
  ),
  (
    'Work and money',
    'Learn, earn, save and buy',
    ['School', 'Work', 'Money', 'Assets', 'Licences'],
  ),
  (
    'Out and about',
    'Trips, pets, who you are and the news',
    ['Travel', 'Pets', 'Identity', 'News'],
  ),
  ('Rules and risks', 'Lawyers, courts and crime', ['Law', 'Crime']),
];

/// One plain sentence at the top of each category.
const categoryBlurbs = <String, String>{
  'Wellbeing': 'Small things that lift your mood and keep you steady.',
  'Health': 'Doctors, check-ups and getting better.',
  'School': 'Study, exams and school life.',
  'Work': 'Find a job, do well in it, or change direction.',
  'Money': 'Banking, saving, borrowing and investing.',
  'Love': 'Dating, romance and your partner.',
  'Social': 'Going out, friends and being seen.',
  'Upper echelon': 'Islands, superyachts, teams, art, space and legacy. Few people alive have this much money.',
  'Music': 'Write songs, release them, and earn from streams for years. A hit makes you famous.',
  'Social media': 'Post on each platform. Fame gets your posts seen; a good image gets them shared.',
  'Fame': 'Talk shows, red carpets, fans and feuds. Needs some fame first.',
  'Hobbies': 'Make things, play and practise.',
  'Travel': 'Holidays, weekends away and moving abroad.',
  'Assets': 'Homes, cars and the things you own.',
  'Pets': 'Adopt and care for animals.',
  'Licences': 'Driving and other licences.',
  'Identity': 'Your name, your look and who you are.',
  'Faith': 'Belief, ritual and community.',
  'Law': 'Lawyers, lawsuits and your record.',
  'Crime': 'Risky choices. You might get caught.',
  'Prison': 'Make the most of your time inside.',
  'News': 'What is happening in the world.',
  'Family': 'Time with the people closest to you.',
  'Seasonal': 'On for a short time only.',
};

IconData categoryIconFor(String c) => activityCategories
    .firstWhere((e) => e.$1 == c, orElse: () => (c, Icons.auto_awesome_rounded))
    .$2;

/// The Activities panel, opened by swiping up on the bottom bar.
///
/// Home view: search, up to four "Suggested for you" actions and a grid of
/// categories showing how many activities are open right now. A category
/// opens a simple list; locked activities are folded away at the bottom.
class ActivitiesPanel extends StatefulWidget {
  const ActivitiesPanel({
    super.key,
    required this.controller,
    required this.scrollController,
    this.focusSearch = false,
    this.docked = false,
  });

  final GameController controller;
  final ScrollController scrollController;
  final bool focusSearch;

  /// Shown beside the game on a wide (desktop) window instead of in a
  /// sheet: nothing to close after an activity.
  final bool docked;

  @override
  State<ActivitiesPanel> createState() => _ActivitiesPanelState();
}

class _ActivitiesPanelState extends State<ActivitiesPanel> {
  String _q = '';
  String? _category;
  bool _showLocked = false;
  final _search = TextEditingController();

  GameController get c => widget.controller;
  Life get life => c.life!;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Every activity, minus those hidden by the content filters.
  List<GameAction> get _actions => c.engine!.actions
      .where((a) => !filteredOut(c.profile, a.category, a.id))
      // Music stays out of sight until Road to the Underground opens it.
      .where((a) => a.category != 'Music' || musicUnlocked(life))
      // The upper echelon stays secret until the fortune passes the line.
      .where((a) => a.category != 'Upper echelon' || upperEchelon(life))
      .toList();

  List<GameAction> _in(String cat) =>
      _actions.where((a) => a.category == cat).toList();

  bool _open(GameAction a) => a.lockReason(life) == null;

  /// A seasonal activity that fits today's season and this age, even if
  /// something else (like money) still locks it.
  bool _inSeason(GameAction a) =>
      a.extraCheck?.call(life) == null &&
      life.age >= a.minAge &&
      life.age <= a.maxAge;

  /// Up to four relevant, available actions for this moment in life.
  List<GameAction> _suggested() {
    final byId = {for (final a in _actions) a.id: a};
    final ids = <String>[
      if (life.prison != null) ...[
        'prison_job',
        'prison_study',
        'prison_gym',
        'write_letters',
        'talk_cellmate',
      ],
      if (life.addictions.isNotEmpty) 'rehab',
      if (life.education == 'primary' ||
          life.education == 'secondary' ||
          life.education == 'university')
        'study',
      if (life.age >= 18 && life.job == null && life.education != 'university')
        'apply_job',
      if (life.age >= 14 && life.age < 18 && life.job == null) 'part_time',
      if (life.stats['health'] < 55) 'doctor',
      if (life.stats['happiness'] < 55) 'meditate',
      if (life.job != null) 'ask_raise',
      if (life.age >= 12) 'gym',
      'read',
      'walk',
      'paint',
    ];
    final out = <GameAction>[];
    for (final id in ids) {
      final a = byId[id];
      if (a != null && _open(a) && !out.contains(a)) out.add(a);
      if (out.length == 4) break;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final searching = _q.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          _header(),
          if (_category == null && !searching) ...[
            const SizedBox(height: 4),
            Text(
              life.classic
                  ? 'Pick anything to do this year. Tap a group to see what is in it.'
                  : 'Pick what to do this year. Most activities use 1 energy, and it refills on your birthday.',
              style: NF.sora(13, color: NF.muted),
            ),
          ],
          const SizedBox(height: 12),
          _searchField(),
          const SizedBox(height: 18),
          if (searching)
            ..._searchResults(context)
          else if (_category == null)
            ..._home(context)
          else
            ..._categoryPage(context, _category!),
        ],
      ),
    );
  }

  Widget _header() {
    if (_category != null && _q.trim().isEmpty) {
      return Row(
        children: [
          IconButton(
            tooltip: 'Back to all activities',
            onPressed: () => setState(() {
              _category = null;
              _showLocked = false;
            }),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Icon(categoryIconFor(_category!), color: NF.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _category!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NF.sora(22, weight: FontWeight.w700),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            'Activities',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NF.sora(22, weight: FontWeight.w700),
          ),
        ),
        if (!life.classic)
          Semantics(
            label: 'Energy ${life.energy} of 10 this year',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: NF.blue.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, size: 16, color: NF.blue),
                  const SizedBox(width: 4),
                  Text(
                    '${life.energy}/10',
                    style: NF.sora(13, weight: FontWeight.w700, color: NF.blue),
                  ),
                ],
              ),
            ),
          )
        else
          Text('Age ${life.age}', style: NF.sora(13, color: NF.muted)),
      ],
    );
  }

  Widget _searchField() => TextField(
    controller: _search,
    autofocus: widget.focusSearch,
    style: NF.sora(15),
    onChanged: (v) => setState(() => _q = v),
    decoration: InputDecoration(
      hintText: 'Search activities and people',
      hintStyle: NF.sora(14, color: NF.muted),
      prefixIcon: const Icon(Icons.search, color: NF.muted),
      suffixIcon: _q.isEmpty
          ? null
          : IconButton(
              tooltip: 'Clear search',
              icon: const Icon(Icons.close_rounded, color: NF.muted),
              onPressed: () => setState(() {
                _search.clear();
                _q = '';
              }),
            ),
      filled: true,
      fillColor: NF.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );

  // ---------------- Home ----------------

  List<Widget> _home(BuildContext context) {
    final suggested = _suggested().take(3).toList();
    // Right now: prison while inside, and seasonal activities while on.
    final now = [
      if (life.prison != null) 'Prison',
      if (_in('Seasonal').any(_inSeason)) 'Seasonal',
    ];
    bool ready(String cat) => _in(cat).any(_open);
    final later = [
      for (final g in activityGroups)
        for (final cat in g.$3)
          if (_in(cat).isNotEmpty && !ready(cat)) cat,
    ];
    return [
      if (suggested.isNotEmpty) ...[
        _sectionTitle('Good ideas right now', 'Tap one to do it'),
        for (final a in suggested) ...[
          actionRow(context, c, a, closeSheet: !widget.docked),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 14),
      ],
      if (now.isNotEmpty) ...[
        _sectionTitle(
          life.prison != null ? 'Inside' : 'On now',
          life.prison != null
              ? 'Most other activities wait until you are out'
              : 'Only for a short time',
        ),
        _tiles(now),
        const SizedBox(height: 18),
      ],
      for (final g in activityGroups)
        if (g.$3.any((cat) => _in(cat).isNotEmpty && ready(cat))) ...[
          _sectionTitle(g.$1, g.$2),
          _tiles([
            for (final cat in g.$3)
              if (_in(cat).isNotEmpty && ready(cat)) cat,
          ]),
          const SizedBox(height: 18),
        ],
      if (later.isNotEmpty) ...[
        TextButton.icon(
          onPressed: () => setState(() => _showLocked = !_showLocked),
          icon: Icon(
            _showLocked ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          ),
          label: Text(
            _showLocked
                ? 'Hide what unlocks later'
                : '${later.length} more unlock later',
          ),
        ),
        if (_showLocked) _tiles(later),
      ],
    ];
  }

  Widget _sectionTitle(String title, String sub) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: NF.sora(15, weight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(sub, style: NF.sora(12, color: NF.muted)),
      ],
    ),
  );

  Widget _tiles(List<String> cats) => LayoutBuilder(
    builder: (context, box) {
      final cols = box.maxWidth > 420 ? 4 : 3;
      final w = (box.maxWidth - (cols - 1) * 10) / cols;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final cat in cats)
            SizedBox(width: w, child: _categoryTile(cat, categoryIconFor(cat))),
        ],
      );
    },
  );

  Widget _categoryTile(String cat, IconData icon) {
    final all = _in(cat);
    final open = all.where(_open).length;
    // A chapter in progress is flagged on its category.
    final chapter = cat == 'Music' && musicUnlocked(life) && !roadDone(life);
    final label = chapter
        ? 'New chapter'
        : open == 0
        ? _earliestUnlock(all)
        : '$open to do';
    return Semantics(
      button: true,
      label: '$cat, $label',
      excludeSemantics: true,
      child: Material(
        color: open == 0 ? NF.surface2.withValues(alpha: 0.45) : NF.surface2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() {
            _category = cat;
            _showLocked = false;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              children: [
                Icon(icon, size: 26, color: open == 0 ? NF.muted : NF.orange),
                const SizedBox(height: 8),
                Text(
                  cat,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NF.sora(
                    13,
                    weight: FontWeight.w600,
                    color: open == 0 ? NF.muted : NF.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: NF.sora(
                    11,
                    weight: chapter ? FontWeight.w700 : FontWeight.w400,
                    color: chapter
                        ? NF.orange
                        : open == 0
                        ? NF.muted
                        : NF.blue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _earliestUnlock(List<GameAction> all) {
    final future =
        all.where((a) => a.minAge > life.age).map((a) => a.minAge).toList()
          ..sort();
    return future.isEmpty ? 'Locked' : 'From age ${future.first}';
  }

  // ---------------- Category page ----------------

  List<Widget> _categoryPage(BuildContext context, String cat) {
    final all = _in(cat);
    final open = all.where(_open).toList();
    final done = all
        .where((a) => !_open(a) && a.lockReason(life) == 'Done this year')
        .toList();
    final locked = all.where((a) => !_open(a) && !done.contains(a)).toList();
    final free = open.where((a) => a.cost == 0).toList();
    final paid = open.where((a) => a.cost > 0).toList();
    List<Widget> rows(List<GameAction> list) => [
      for (final a in list) ...[
        actionRow(context, c, a, closeSheet: !widget.docked),
        const SizedBox(height: 8),
      ],
    ];
    return [
      if (categoryBlurbs[cat] != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(categoryBlurbs[cat]!, style: NF.sora(14, color: NF.soft)),
        ),
      if (cat == 'Crime') ...[
        CrimeProfileCard(life: life),
        const SizedBox(height: 12),
      ],
      if (open.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            done.isNotEmpty
                ? 'You have done everything here this year. More next year.'
                : 'Nothing here is open yet. See below for when each one unlocks.',
            style: NF.sora(14, color: NF.muted),
          ),
        ),
      // Short lists stay as one list; longer ones split by price.
      if (open.length <= 5 || free.isEmpty || paid.isEmpty)
        ...rows(open)
      else ...[
        _sectionTitle('Free', 'No money needed'),
        ...rows(free),
        const SizedBox(height: 10),
        _sectionTitle('Costs money', 'The price shows on each one'),
        ...rows(paid),
      ],
      if (done.isNotEmpty) ...[
        const SizedBox(height: 10),
        _sectionTitle('Done this year', 'Ready again after your birthday'),
        ...rows(done),
      ],
      if (locked.isNotEmpty) ...[
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () => setState(() => _showLocked = !_showLocked),
          icon: Icon(
            _showLocked ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          ),
          label: Text(
            _showLocked
                ? 'Hide what is not open yet'
                : '${locked.length} not open yet',
          ),
        ),
        if (_showLocked) ...rows(locked),
      ],
    ];
  }

  // ---------------- Search ----------------

  List<Widget> _searchResults(BuildContext context) {
    final actions = _actions.where((a) => a.matches(_q)).toList()
      ..sort((a, b) => (_open(a) ? 0 : 1).compareTo(_open(b) ? 0 : 1));
    final people = searchInteractions(life, _q).take(8).toList();
    if (actions.isEmpty && people.isEmpty) {
      return [
        Text(
          'Nothing matches "$_q" yet. Try "job", "gym" or a name.',
          style: NF.sora(14, color: NF.muted),
        ),
      ];
    }
    return [
      for (final a in actions) ...[
        actionRow(context, c, a, closeSheet: !widget.docked),
        const SizedBox(height: 8),
      ],
      if (people.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text('With people', style: NF.sora(15, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final (n, i) in people) ...[
          _personRow(context, n, i),
          const SizedBox(height: 8),
        ],
      ],
    ];
  }

  // ---------------- Rows ----------------

  Widget _personRow(BuildContext context, Npc n, Interaction i) {
    final lock = i.lockReason(life, n);
    return Material(
      color: NF.surface2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: lock != null
            ? null
            : () async {
                final nav = Navigator.of(context);
                final busy = c.busyReason;
                if (busy != null) {
                  await showBusyNotice(context, c, busy);
                  return;
                }
                InteractionVariant? how;
                final ways = interactionVariantsFor(i.id);
                if (ways.isNotEmpty) {
                  how = await pickInteractionVariant(context, life, n, i, ways);
                  if (how == null || !nav.mounted) return;
                }
                final r = c.interact(n, i, variant: how);
                if (!widget.docked) nav.pop();
                if (c.pendingEvent != null) {
                  showEvent(nav.context, c);
                  return;
                }
                showResultPopup(
                  nav.context,
                  r,
                  title: '${i.label} · ${n.name}',
                  icon: Icons.favorite_rounded,
                );
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Avatar(initials: n.name.substring(0, 1), size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i.label} · ${n.name}',
                      style: NF.sora(
                        15,
                        weight: FontWeight.w600,
                        color: lock == null ? NF.text : NF.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lock ?? 'Bond ${n.bond}% · ${hideOdds(i.hint(life, n))}',
                      style: NF.sora(
                        12,
                        color: lock == null ? NF.muted : NF.orange,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                lock == null
                    ? Icons.chevron_right_rounded
                    : Icons.lock_outline_rounded,
                color: NF.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One clean row: icon, name, one line of detail, and a clear state.
/// Locked rows stay visible and show their reason in orange.
class OptionRow extends StatelessWidget {
  const OptionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.detail,
    this.locked = false,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool locked;
  final IconData? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = locked ? NF.muted : NF.orange;
    return Semantics(
      button: !locked,
      label: '$title. $detail',
      excludeSemantics: true,
      child: Material(
        color: locked ? NF.surface2.withValues(alpha: 0.45) : NF.surface2,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: locked || onTap == null
              ? null
              : () {
                  Sound.instance.tap();
                  onTap!();
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 19, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: NF.sora(
                          15,
                          weight: FontWeight.w600,
                          color: locked ? NF.muted : NF.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        style: NF.sora(
                          12,
                          color: locked ? NF.orange : NF.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  locked
                      ? Icons.lock_outline_rounded
                      : trailing ?? Icons.chevron_right_rounded,
                  color: NF.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A row for an activity. Tapping plays its mini-game (if it has one),
/// runs it and shows the result. [closeSheet] pops the Activities sheet.
Widget actionRow(
  BuildContext context,
  GameController c,
  GameAction a, {
  bool closeSheet = true,
}) {
  final life = c.life!;
  final lock = a.lockReason(life);
  final price =
      a.hintFor(life) ??
      a.priceNote ??
      (a.cost > 0 ? 'Costs ${money(a.cost)}' : 'Free');
  return OptionRow(
    icon: categoryIconFor(a.category),
    title: a.label,
    detail: localizeMoney(
      lock ?? (a.miniGame != null ? '$price · Mini-game' : price),
    ),
    locked: lock != null,
    trailing: a.miniGame != null ? Icons.sports_esports_rounded : null,
    onTap: () => runActionFlow(context, c, a, closeSheet: closeSheet),
  );
}

/// Choose how to do an activity. Locked options stay visible with why.
Future<ActionVariant?> pickVariant(
  BuildContext context,
  Life life,
  GameAction a,
  List<ActionVariant> options,
) => showModalBottomSheet<ActionVariant>(
  context: context,
  backgroundColor: NF.surface,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (ctx) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(ctx).size.height * 0.8,
    ),
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Text(a.label, style: NF.sora(18, weight: FontWeight.w700)),
        Text('How do you want to do it?', style: NF.sora(13, color: NF.muted)),
        const SizedBox(height: 12),
        for (final v in options.where((v) => life.age <= v.maxAge)) ...[
          OptionRow(
            icon: v.withPerson
                ? Icons.group_add_rounded
                : categoryIconFor(a.category),
            title: v.label,
            detail:
                v.lockReason(life) ??
                (v.withPerson ? '${v.detail} · pick who' : v.detail),
            locked: v.lockReason(life) != null,
            onTap: () => Navigator.pop(ctx, v),
          ),
          const SizedBox(height: 8),
        ],
      ],
    ),
  ),
);

/// Choose how to spend time with someone or what to talk about. Options
/// they especially enjoy are marked.
Future<InteractionVariant?> pickInteractionVariant(
  BuildContext context,
  Life life,
  Npc npc,
  Interaction i,
  List<InteractionVariant> ways,
) => showModalBottomSheet<InteractionVariant>(
  context: context,
  backgroundColor: NF.surface,
  isScrollControlled: true,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (ctx) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(ctx).size.height * 0.8,
    ),
    child: ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        Text(
          '${i.label} · ${npc.name.split(' ').first}',
          style: NF.sora(18, weight: FontWeight.w700),
        ),
        Text('What would you like to do?', style: NF.sora(13, color: NF.muted)),
        const SizedBox(height: 12),
        for (final w in ways) ...[
          OptionRow(
            icon: w.suits(life, npc)
                ? Icons.favorite_rounded
                : Icons.chat_bubble_outline_rounded,
            title: w.label,
            detail:
                w.lockReason(life) ??
                (w.suits(life, npc)
                    ? '${w.detail} · just their thing'
                    : w.detail),
            locked: w.lockReason(life) != null,
            onTap: () => Navigator.pop(ctx, w),
          ),
          const SizedBox(height: 8),
        ],
      ],
    ),
  ),
);

/// Choose who comes along, closest first.
Future<Npc?> pickCompanion(BuildContext context, Life life, String what) =>
    showModalBottomSheet<Npc>(
      context: context,
      backgroundColor: NF.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.8,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            Text(
              'Who comes along?',
              style: NF.sora(18, weight: FontWeight.w700),
            ),
            Text(what, style: NF.sora(13, color: NF.muted)),
            const SizedBox(height: 12),
            for (final n in companions(life).take(15)) ...[
              OptionRow(
                icon: Icons.person_rounded,
                title: '${n.name.split(' ').first} · ${n.role}',
                detail: 'Bond ${n.bond}% · ${n.bondLabel}',
                onTap: () => Navigator.pop(ctx, n),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );

/// "Not yet": an event (or its next step) on the Life tab comes first.
/// "Go to event" closes any sheets and screens and shows it.
Future<void> showBusyNotice(
  BuildContext context,
  GameController c,
  String reason,
) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: NF.surface,
      title: Text('Not yet', style: NF.sora(18, weight: FontWeight.w700)),
      content: Text(reason, style: NF.sora(14, color: NF.soft)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('OK'),
        ),
        FilledButton(
          style: primaryButton(),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Go to event'),
        ),
      ],
    ),
  );
  if (go == true && context.mounted) showEvent(context, c);
}

/// Closes sheets and screens and brings the Life tab (and its event) up.
void showEvent(BuildContext context, GameController c) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  c.goToEvent();
}

/// Asks what to call a new song, starting from a suggested title. Returns
/// the name typed, or null to keep the suggestion.
Future<String?> askSongTitle(BuildContext context, String suggested) {
  final field = TextEditingController(text: suggested);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: NF.surface,
      title: Text(
        'Name your song',
        style: NF.sora(18, weight: FontWeight.w700),
      ),
      content: TextField(
        controller: field,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'Song title'),
        onSubmitted: (v) => Navigator.pop(ctx, v),
        onTap: () => field.selection = TextSelection(
          baseOffset: 0,
          extentOffset: field.text.length,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Keep "$suggested"'),
        ),
        FilledButton(
          style: primaryButton(),
          onPressed: () => Navigator.pop(ctx, field.text),
          child: const Text('Name it'),
        ),
      ],
    ),
  );
}

Future<void> runActionFlow(
  BuildContext context,
  GameController c,
  GameAction a, {
  bool closeSheet = true,
}) async {
  final nav = Navigator.of(context);
  final busy = c.busyReason;
  if (busy != null) {
    await showBusyNotice(context, c, busy);
    return;
  }
  // Moving abroad has its own screen with a country list; nothing is
  // used up until you apply.
  if (a.screen == 'move_abroad') {
    if (closeSheet) nav.pop();
    nav.push(
      MaterialPageRoute(builder: (_) => MoveAbroadScreen(controller: c)),
    );
    return;
  }
  // How to do it (light or hard session, which trip, who to bring).
  ActionVariant? variant;
  Npc? who;
  final options = variantsFor(a.id);
  if (options.isNotEmpty) {
    variant = await pickVariant(context, c.life!, a, options);
    if (variant == null || !context.mounted) return;
    if (variant.withPerson) {
      who = await pickCompanion(context, c.life!, variant.label);
      if (who == null || !context.mounted) return;
    }
  }
  // Confirm big decisions (plan UX §8.5): crime, quitting, moving abroad,
  // or spending more than half your cash.
  final big =
      a.category == 'Crime' ||
      const {'quit_job', 'retire', 'emigrate', 'name_change'}.contains(a.id) ||
      (a.cost > 0 && a.cost > c.life!.money / 2) ||
      (variant != null && variant.cost > c.life!.money / 2);
  if (c.profile.confirmBig && big) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NF.surface,
        title: Text('${a.label}?', style: NF.sora(18, weight: FontWeight.w700)),
        content: Text(
          localizeMoney(
            a.hintFor(c.life!) ??
                a.priceNote ??
                (a.cost > 0
                    ? 'Costs ${money(a.cost)}'
                    : 'This is a big decision.'),
          ),
          style: NF.sora(14, color: NF.soft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            style: primaryButton(),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Do it'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
  }
  double? score;
  if (a.miniGame != null && c.profile.autoMiniGames) {
    score = 0.6; // the same fair middle result as "Skip"
  } else if (a.miniGame != null) {
    score = await showMiniGame(
      context,
      a.miniGame!,
      age: c.life!.age,
      title: variant == null ? a.label : '${a.label} · ${variant.label}',
      activity: a.id,
      life: c.life,
    );
    if (score == null) return; // closed without playing
  }
  final before = c.pendingEvent;
  final songsBefore = c.life!.songs.length;
  var r = c.runAction(a, score: score, variant: variant, who: who);
  // A new song: let the player give it their own title.
  if (c.life!.songs.length > songsBefore && context.mounted) {
    final song = c.life!.songs.last;
    final old = song['title'] as String;
    final name = await askSongTitle(context, old);
    if (name != null && name.trim().isNotEmpty && name.trim() != old) {
      final now = c.wealth((l) => renameSong(l, song, name));
      r = ActionResult(r.text.replaceAll('"$old"', '"$now"'), r.notes);
    }
  }
  if (closeSheet) nav.pop();
  if (!nav.mounted) return;
  // The activity opened a scene (an interview, a viewing...): go straight
  // to it instead of showing a pop-up that only says it started.
  if (c.pendingEvent != null && c.pendingEvent != before) {
    showEvent(nav.context, c);
    return;
  }
  if (a.screen == 'newspaper') {
    openNewspaper(nav.context, c);
    return;
  }
  if (a.screen == 'shop') {
    openShop(nav.context, c);
    return;
  }
  if (a.screen == 'social') {
    nav.push(MaterialPageRoute(builder: (_) => SocialScreen(controller: c)));
    return;
  }
  showResultPopup(
    nav.context,
    r,
    title: a.label,
    icon: categoryIconFor(a.category),
  );
}
