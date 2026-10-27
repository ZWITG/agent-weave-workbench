import 'package:flutter/material.dart';

import '../engine/actions.dart';
import '../engine/engine.dart';
import '../engine/lifespan.dart';
import '../engine/models.dart';
import '../engine/storylet.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'activities.dart';
import 'outcome_card.dart';
import 'result_popup.dart';
import 'path_tab.dart';
import 'me_screens.dart';
import 'update_prompt.dart';
import 'wealth_tab.dart';
import 'people.dart';
import 'widgets.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  int _tab = 0;
  String? _lastEvent;

  GameController get c => widget.controller;
  Life get life => c.life!;

  @override
  Widget build(BuildContext context) {
    // A new event or scene (an interview from the Path tab, say) brings
    // you back to the Life tab, where its card is.
    final event = c.pendingEvent?.id;
    if (event != null && event != _lastEvent && _tab != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _tab = 0);
      });
    }
    _lastEvent = event;
    final tabs = [
      _LifeTab(controller: c),
      PeopleTab(controller: c),
      PathTab(controller: c),
      WealthTab(controller: c),
      _MeTab(controller: c),
    ];
    return Scaffold(
      backgroundColor: NF.bg,
      body: GlowBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                children: [
                  _Header(life: life),
                  Expanded(
                    child: IndexedStack(index: _tab, children: tabs),
                  ),
                  _BottomBar(
                    controller: c,
                    onActivities: () => _openSearch(context),
                    onSearch: () => _openSearch(context, focusSearch: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        height: 64,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Life',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'People',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Path',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'Wealth',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Me',
          ),
        ],
      ),
    );
  }

  /// Opens the Activities panel (swipe up on the bottom bar, or tap it).
  void _openSearch(BuildContext context, {bool focusSearch = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: NF.surface,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.66,
        minChildSize: 0.35,
        maxChildSize: 0.95,
        snap: true,
        builder: (context, scroll) => ActivitiesPanel(
          controller: c,
          scrollController: scroll,
          focusSearch: focusSearch,
        ),
      ),
    );
  }
}

// ---------------- Header ----------------

class _Header extends StatelessWidget {
  const _Header({required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          AgeRingAvatar(
            initials: life.initials,
            progress: (life.age / 100).clamp(0.0, 1.0),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  life.fullName,
                  style: NF.sora(20, weight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Age ${life.age} · ${life.job ?? life.stage}',
                  style: NF.sora(13, color: NF.soft),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${life.city}, ${life.country}',
                  style: NF.sora(12, color: NF.muted),
                  overflow: TextOverflow.ellipsis,
                ),
                if (isFrail(life))
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.monitor_heart_rounded,
                          size: 14,
                          color: NF.danger,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          frailtyLabel(life),
                          style: NF.sora(
                            12,
                            weight: FontWeight.w600,
                            color: NF.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Pill('${life.year}'),
              const SizedBox(height: 6),
              Semantics(
                label: 'Bank balance ${money(life.money)}',
                excludeSemantics: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5EE6A8).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: const Color(0xFF5EE6A8).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        size: 14,
                        color: Color(0xFF5EE6A8),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        money(life.money),
                        style: NF.sora(
                          13,
                          weight: FontWeight.w700,
                          color: life.money < 0
                              ? NF.danger
                              : const Color(0xFF5EE6A8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------- Bottom bar: search + Age +1 ----------------

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.controller,
    required this.onSearch,
    required this.onActivities,
  });
  final GameController controller;
  final VoidCallback onSearch;
  final VoidCallback onActivities;

  @override
  Widget build(BuildContext context) {
    final blocked = controller.pendingEvent != null;
    final atEnd = controller.life!.age >= sliceEndAge;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < -150) onActivities();
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              button: true,
              label: 'Open activities',
              excludeSemantics: true,
              child: InkWell(
                onTap: onActivities,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: NF.borderStrong,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 18,
                            color: NF.muted,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            'Swipe up for activities',
                            style: NF.sora(12, color: NF.muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: 'Search actions: what do you want to do?',
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: onSearch,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: NF.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: NF.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: NF.muted, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'What do you want to do?',
                              style: NF.sora(14, color: NF.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Tooltip(
                  message: blocked
                      ? 'Choose an option first'
                      : (atEnd ? 'See your life recap' : 'Live another year'),
                  child: FilledButton(
                    style: orangeButton(),
                    onPressed: blocked
                        ? null
                        : (atEnd ? () => controller.ageUp() : controller.ageUp),
                    child: Text(atEnd ? 'Recap' : 'Age +1'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Life tab ----------------

class _LifeTab extends StatelessWidget {
  const _LifeTab({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final feed = life.feed.reversed.take(60).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      children: [
        for (final row in const [
          ['happiness', 'health'],
          ['smarts', 'looks'],
        ]) ...[
          Row(
            children: [
              Expanded(
                child: StatTile(
                  statKey: row[0],
                  value: life.stats[row[0]],
                  trend:
                      life.stats[row[0]] -
                      (life.lastYearStats[row[0]] ?? life.stats[row[0]]),
                  onTap: () => showStatHistory(context, life, row[0]),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  statKey: row[1],
                  value: life.stats[row[1]],
                  trend:
                      life.stats[row[1]] -
                      (life.lastYearStats[row[1]] ?? life.stats[row[1]]),
                  onTap: () => showStatHistory(context, life, row[1]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: motion(context, const Duration(milliseconds: 350)),
          switchInCurve: Curves.easeOutCubic,
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(a),
              child: child,
            ),
          ),
          child: controller.pendingEvent != null
              ? _EventCard(
                  key: ValueKey('e${life.age}${controller.pendingEvent!.id}'),
                  controller: controller,
                  event: controller.pendingEvent!,
                )
              : controller.lastOutcome != null
              ? OutcomeCard(
                  key: ValueKey(
                    'o${life.age}${controller.lastOutcome!.text.hashCode}',
                  ),
                  controller: controller,
                  outcome: controller.lastOutcome!,
                )
              : const SizedBox.shrink(key: ValueKey('none')),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < feed.length; i++) ...[
          if (i == 0 || feed[i].age != feed[i - 1].age)
            _YearDivider(age: feed[i].age, year: life.birthYear + feed[i].age),
          _FeedBubble(
            entry: feed[i],
            onTap: feed[i].kind == 'world' && feed[i].age == life.age
                ? () => _readPaper(context, controller)
                : null,
          ),
        ],
      ],
    );
  }
}

class _YearDivider extends StatelessWidget {
  const _YearDivider({required this.age, required this.year});
  final int age;
  final int year;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: NF.orange.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Age $age · $year',
              style: NF.sora(12, weight: FontWeight.w700, color: NF.orange),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: NF.border)),
        ],
      ),
    );
  }
}

/// Tapping this year's headline buys (or re-opens) the newspaper.
void _readPaper(BuildContext context, GameController c) {
  final paper = allActions.firstWhere((a) => a.id == 'newspaper');
  final lock = paper.lockReason(c.life!);
  if (lock != null) {
    showResultPopup(
      context,
      ActionResult('The full story is in today\'s paper.', ['Why: $lock']),
      title: 'Read all about it',
      icon: Icons.newspaper_rounded,
    );
    return;
  }
  runActionFlow(context, c, paper, closeSheet: false);
}

class _FeedBubble extends StatelessWidget {
  const _FeedBubble({required this.entry, this.onTap});
  final FeedEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (entry.kind == 'world') return _newsBubble();
    if (entry.kind == 'npc') return _npcBubble();
    if (entry.kind == 'summary') return _summaryBubble();
    final milestone = entry.kind == 'milestone';
    final action = entry.kind == 'action';
    return Align(
      alignment: action ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: action ? NF.surface2 : NF.surface,
          border: milestone
              ? Border.all(color: NF.orange.withValues(alpha: 0.6))
              : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(action ? 18 : 6),
            bottomRight: Radius.circular(action ? 6 : 18),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 8),
              child: Icon(
                milestone
                    ? Icons.star_rounded
                    : (action ? Icons.bolt_rounded : Icons.chat_bubble_rounded),
                size: 15,
                color: milestone ? NF.orange : (action ? NF.blue : NF.muted),
              ),
            ),
            Flexible(
              child: Text(
                entry.text,
                style: NF.sora(14, color: NF.soft, height: 1.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "In the news": this year's headline; tap to read the paper.
  Widget _newsBubble() => Semantics(
    button: onTap != null,
    label:
        'In the news: ${entry.text}${onTap != null ? '. Tap to read the paper' : ''}',
    excludeSemantics: true,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: NF.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NF.blue.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                const Icon(Icons.newspaper_rounded, size: 20, color: NF.blue),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IN THE NEWS',
                        style: NF
                            .sora(10, weight: FontWeight.w800, color: NF.blue)
                            .copyWith(letterSpacing: 1.2),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.text,
                        style: NF.sora(
                          14,
                          weight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Read',
                    style: NF.sora(12, weight: FontWeight.w700, color: NF.blue),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: NF.blue,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

  /// What changed over the birthday (plan CL-002 year summary).
  Widget _summaryBubble() => Semantics(
    label: 'Birthday changes: ${entry.text}',
    excludeSemantics: true,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final part in entry.text.split(' · '))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: NF.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: NF.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    part.contains('−')
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 12,
                    color: part.contains('−')
                        ? NF.danger
                        : const Color(0xFF5EE6A8),
                  ),
                  const SizedBox(width: 4),
                  Text(part, style: NF.sora(12, color: NF.soft)),
                ],
              ),
            ),
        ],
      ),
    ),
  );

  /// A life update from someone you know, with their avatar.
  Widget _npcBubble() => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxWidth: 330),
      padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
      decoration: BoxDecoration(
        color: NF.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Avatar(initials: (entry.who ?? '?').substring(0, 1), size: 28),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              entry.text,
              style: NF.sora(14, color: NF.soft, height: 1.45),
            ),
          ),
        ],
      ),
    ),
  );
}

class _EventCard extends StatelessWidget {
  const _EventCard({super.key, required this.controller, required this.event});
  final GameController controller;
  final Storylet event;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final engine = controller.engine!;
    final mem = event.remembers != null ? life.flags[event.remembers] : null;
    final compact =
        event.choices.length == 3 &&
        event.choices.every(
          (c) =>
              engine.fill(c.label, life).length <= 18 &&
              c.risk == null &&
              c.lockReason(life) == null,
        );
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A3358), Color(0xFF1E2440)],
          ),
          border: Border.all(color: NF.blue.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: NF.blue.withValues(alpha: 0.18),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: NF.orange.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    categoryIcon(event.category),
                    size: 19,
                    color: NF.orange,
                  ),
                ),
                const SizedBox(width: 10),
                SectionLabel('Now · ${event.category}'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              engine.fill(event.text, life),
              style: NF.sora(19, weight: FontWeight.w600, height: 1.35),
            ),
            if (mem != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: NF.bg.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      size: 14,
                      color: NF.orange,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Remembers: ${engine.fill(mem.label, life)} (age ${mem.age})',
                        style: NF.sora(12, color: NF.soft),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            if (compact)
              Row(
                children: [
                  for (var i = 0; i < event.choices.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _choiceButton(i, life, engine)),
                  ],
                ],
              )
            else
              Column(
                children: [
                  for (var i = 0; i < event.choices.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: _choiceButton(i, life, engine),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _choiceButton(int i, Life life, GameEngine engine) {
    final choice = event.choices[i];
    final lock = choice.lockReason(life);
    final hint = lock ?? choice.risk;
    final label = hint == null
        ? Text(engine.fill(choice.label, life), textAlign: TextAlign.center)
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                engine.fill(choice.label, life),
                textAlign: TextAlign.center,
              ),
              Text(
                lock != null ? '🔒 $lock' : hint,
                textAlign: TextAlign.center,
                style: lock != null
                    ? NF.sora(11, weight: FontWeight.w500, color: NF.orange)
                    : const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
              ),
            ],
          );
    final onPressed = lock == null ? () => controller.choose(choice) : null;
    return i == 0 && lock == null
        ? FilledButton(
            style: primaryButton(),
            onPressed: onPressed,
            child: label,
          )
        : OutlinedButton(
            style: secondaryButton(),
            onPressed: onPressed,
            child: label,
          );
  }
}

// ---------------- Me tab ----------------

class _MeTab extends StatelessWidget {
  const _MeTab({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      children: [
        Material(
          color: NF.surface,
          borderRadius: BorderRadius.circular(16),
          child: SwitchListTile(
            title: Text(
              'Sound effects',
              style: NF.sora(15, weight: FontWeight.w600),
            ),
            subtitle: Text(
              'Age-up chime, choices and results',
              style: NF.sora(12, color: NF.muted),
            ),
            value: controller.soundOn,
            onChanged: controller.setSound,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: secondaryButton(),
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Settings'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(controller: controller),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: secondaryButton(),
                icon: const Icon(Icons.history_toggle_off_rounded),
                label: const Text('Rewind'),
                onPressed: () => showRewind(context, controller),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const VersionCard(),
        const SizedBox(height: 16),
        _WorldCard(controller: controller),
        const SizedBox(height: 16),
        FamilyTree(life: life),
        const SizedBox(height: 16),
        const SectionLabel('Hidden stats'),
        const SizedBox(height: 10),
        HiddenStats(life: life),
        const SizedBox(height: 16),
        const SectionLabel('Memories', color: NF.blue),
        const SizedBox(height: 10),
        if (life.flags.isEmpty)
          Text('No big memories yet.', style: NF.sora(14, color: NF.muted)),
        for (final m in life.flags.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'Age ${m.age} · ${controller.engine!.fill(m.label, life)}',
              style: NF.sora(14, color: NF.soft),
            ),
          ),
        const SizedBox(height: 24),
        OutlinedButton(
          style: secondaryButton(),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Start a new life?'),
                content: const Text(
                  'This life will end and cannot be continued.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Keep playing'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('New life'),
                  ),
                ],
              ),
            );
            if (ok == true) controller.endLife();
          },
          child: const Text('Start a new life'),
        ),
      ],
    );
  }
}

/// Me tab: your world's memory (plan Module 11): family name, earlier
/// notable lives and the history they wrote.
class _WorldCard extends StatelessWidget {
  const _WorldCard({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final world = controller.engine!.world;
    final name = world.reputation(life.surname);
    final history = world.ledger.reversed.take(6).toList();
    return NFCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.public_rounded, color: NF.blue, size: 20),
              const SizedBox(width: 8),
              Text('Your world', style: NF.sora(15, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'One world, one history. Every life you play happens here, and '
            'the world remembers what they did.',
            style: NF.sora(12, color: NF.muted),
          ),
          const SizedBox(height: 10),
          Text(
            name ?? 'The ${life.surname} name: not known yet',
            style: NF.sora(14, weight: FontWeight.w600),
          ),
          if (life.echo.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Linked to ${life.echo['person']} (${life.echo['year']}) by '
              '${switch (life.echo['relation']) {
                'surname' => 'name',
                'city' => 'home town',
                _ => 'country',
              }}.',
              style: NF.sora(13, color: NF.soft),
            ),
          ],
          if (world.lives.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Earlier lives', style: NF.sora(12, color: NF.muted)),
            for (final l in world.lives.reversed.take(4))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('• $l', style: NF.sora(13, color: NF.soft)),
              ),
          ],
          const SizedBox(height: 12),
          Text('In the history books', style: NF.sora(12, color: NF.muted)),
          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Nothing yet. Do something the papers will notice.',
                style: NF.sora(13, color: NF.soft),
              ),
            ),
          for (final s in history)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${s.year} · ${s.headline}',
                style: NF.sora(13, color: NF.soft),
              ),
            ),
        ],
      ),
    );
  }
}
