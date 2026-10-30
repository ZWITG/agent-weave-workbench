import 'package:flutter/material.dart';

import '../engine/actions.dart';
import '../engine/profile.dart';
import '../engine/models.dart';
import '../engine/relationships.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'minigames.dart';
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

extension on List<(String, IconData)> {
  (String, IconData) named(String name) => firstWhere((e) => e.$1 == name);
}

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
  });

  final GameController controller;
  final ScrollController scrollController;
  final bool focusSearch;

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
    final suggested = _suggested();
    return [
      if (suggested.isNotEmpty) ...[
        Text('Suggested for you', style: NF.sora(15, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        for (final a in suggested) ...[
          actionRow(context, c, a),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 14),
      ],
      Text('Browse', style: NF.sora(15, weight: FontWeight.w700)),
      const SizedBox(height: 10),
      LayoutBuilder(
        builder: (context, box) {
          final cols = box.maxWidth > 420 ? 4 : 3;
          final w = (box.maxWidth - (cols - 1) * 10) / cols;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // In prison the Prison tile comes first; outside, it hides.
              // Seasonal activities show first, and only while their
              // season is on.
              for (final (cat, icon) in [
                if (life.prison != null) activityCategories.named('Prison'),
                if (_in('Seasonal').any(_inSeason))
                  activityCategories.named('Seasonal'),
                ...activityCategories.where(
                  (e) => e.$1 != 'Prison' && e.$1 != 'Seasonal',
                ),
              ])
                if (_in(cat).isNotEmpty)
                  SizedBox(width: w, child: _categoryTile(cat, icon)),
            ],
          );
        },
      ),
    ];
  }

  Widget _categoryTile(String cat, IconData icon) {
    final all = _in(cat);
    final open = all.where(_open).length;
    final label = open == 0 ? _earliestUnlock(all) : '$open open';
    return Semantics(
      button: true,
      label: '$cat, $label',
      excludeSemantics: true,
      child: Material(
        color: open == 0 ? NF.surface2.withValues(alpha: 0.45) : NF.surface2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _category = cat),
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
                  style: NF.sora(11, color: open == 0 ? NF.muted : NF.blue),
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
    final locked = all.where((a) => !_open(a)).toList();
    return [
      if (open.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Nothing here is open yet. See below for when each one unlocks.',
            style: NF.sora(14, color: NF.muted),
          ),
        ),
      for (final a in open) ...[
        actionRow(context, c, a),
        const SizedBox(height: 8),
      ],
      if (locked.isNotEmpty) ...[
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: () => setState(() => _showLocked = !_showLocked),
          icon: Icon(
            _showLocked ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          ),
          label: Text(
            '${_showLocked ? 'Hide' : 'Show'} ${locked.length} locked',
          ),
        ),
        if (_showLocked)
          for (final a in locked) ...[
            actionRow(context, c, a),
            const SizedBox(height: 8),
          ],
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
        actionRow(context, c, a),
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
            : () {
                final busy = c.busyReason;
                if (busy != null) {
                  showBusyNotice(context, c, busy);
                  return;
                }
                final r = c.interact(n, i);
                final nav = Navigator.of(context)..pop();
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
                      lock ?? 'Bond ${n.bond}% · ${i.hint(life, n)}',
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
          onTap: locked ? null : onTap,
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
      a.hint?.call(life) ??
      a.priceNote ??
      (a.cost > 0 ? 'Costs ${money(a.cost)}' : 'Free');
  return OptionRow(
    icon: categoryIconFor(a.category),
    title: a.label,
    detail: lock ?? (a.miniGame != null ? '$price · Mini-game' : price),
    locked: lock != null,
    trailing: a.miniGame != null ? Icons.sports_esports_rounded : null,
    onTap: () => runActionFlow(context, c, a, closeSheet: closeSheet),
  );
}

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
  // Confirm big decisions (plan UX §8.5): crime, quitting, moving abroad,
  // or spending more than half your cash.
  final big =
      a.category == 'Crime' ||
      const {'quit_job', 'retire', 'emigrate', 'name_change'}.contains(a.id) ||
      (a.cost > 0 && a.cost > c.life!.money / 2);
  if (c.profile.confirmBig && big) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NF.surface,
        title: Text('${a.label}?', style: NF.sora(18, weight: FontWeight.w700)),
        content: Text(
          a.hint?.call(c.life!) ??
              a.priceNote ??
              (a.cost > 0
                  ? 'Costs ${money(a.cost)}'
                  : 'This is a big decision.'),
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
      title: a.label,
    );
    if (score == null) return; // closed without playing
  }
  final before = c.pendingEvent;
  final r = c.runAction(a, score: score);
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
