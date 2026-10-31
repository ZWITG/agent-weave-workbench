import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../engine/actions.dart';
import '../engine/engine.dart';
import '../engine/lifespan.dart';
import '../engine/meta.dart' show achievements, goalsFor, goalDone;
import '../engine/celebrity.dart';
import '../engine/models.dart';
import '../engine/storylet.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'activities.dart';
import 'hub_kit.dart';
import 'outcome_card.dart';
import 'result_popup.dart';
import 'path_tab.dart';
import 'health_screen.dart';
import 'meta_screens.dart';
import 'social_screen.dart';
import 'me_screens.dart';
import 'update_prompt.dart';
import 'wealth_tab.dart';
import 'people.dart';
import 'widgets.dart';

/// The web version running on an iPhone or iPad.
bool get _iosWeb => kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

class HubScreen extends StatefulWidget {
  const HubScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  int _tab = 0;
  String? _lastEvent;
  final _dockScroll = ScrollController();

  static const _destinations = [
    (Icons.auto_stories_outlined, Icons.auto_stories, 'Life'),
    (Icons.people_outline, Icons.people, 'People'),
    (Icons.school_outlined, Icons.school, 'Path'),
    (
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet,
      'Wealth',
    ),
    (Icons.person_outline, Icons.person, 'Me'),
  ];

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
    if (c.wantLifeTab) {
      c.wantLifeTab = false;
      if (_tab != 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _tab = 0);
        });
      }
    }
    if (c.toasts.isNotEmpty && _toast == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _nextToast());
    }
    final tabs = [
      _LifeTab(controller: c),
      PeopleTab(controller: c),
      PathTab(controller: c),
      WealthTab(controller: c),
      _MeTab(controller: c),
    ];
    // Desktop and other wide windows: tabs down the left, the game in the
    // middle and Activities always open on the right.
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final game = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: wide ? 720 : 560),
      child: Column(
        children: [
          _Header(
            life: life,
            // Tapping your money opens the Wealth tab.
            onMoney: () => setState(
              () => _tab = _destinations.indexWhere((d) => d.$3 == 'Wealth'),
            ),
            onFame: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SocialScreen(controller: c)),
            ),
          ),
          Expanded(
            child: IndexedStack(index: _tab, children: tabs),
          ),
          _BottomBar(
            controller: c,
            onActivities: () => _openSearch(context),
            onSearch: () => _openSearch(context, focusSearch: true),
            docked: wide,
          ),
        ],
      ),
    );
    if (wide) {
      return Scaffold(
        backgroundColor: NF.bg,
        body: GlowBackground(
          child: SafeArea(
            child: Row(
              children: [
                NavigationRail(
                  backgroundColor: NF.nav,
                  extended: MediaQuery.sizeOf(context).width >= 1300,
                  selectedIndex: _tab,
                  onDestinationSelected: (i) => setState(() => _tab = i),
                  labelType: MediaQuery.sizeOf(context).width >= 1300
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: [
                    for (final (icon, selected, label) in _destinations)
                      NavigationRailDestination(
                        icon: Icon(icon),
                        selectedIcon: Icon(selected),
                        label: Text(label),
                      ),
                  ],
                ),
                Expanded(child: Center(child: game)),
                Container(
                  width: 400,
                  decoration: BoxDecoration(
                    color: NF.surface,
                    border: Border(
                      left: BorderSide(color: NF.muted.withValues(alpha: 0.2)),
                    ),
                  ),
                  padding: const EdgeInsets.only(top: 16),
                  child: ActivitiesPanel(
                    controller: c,
                    scrollController: _dockScroll,
                    docked: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: NF.bg,
      body: GlowBackground(
        child: SafeArea(bottom: false, child: Center(child: game)),
      ),
      // On an iPhone home-screen web app the home indicator sits over the
      // bottom of the page, so the tabs get a little room below them.
      bottomNavigationBar: Container(
        color: NF.nav,
        padding: EdgeInsets.only(bottom: _iosWeb ? 14 : 0),
        child: NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          height: 64,
          destinations: [
            for (final (icon, selected, label) in _destinations)
              NavigationDestination(
                icon: Icon(icon),
                selectedIcon: Icon(selected),
                label: label,
              ),
          ],
        ),
      ),
    );
  }

  OverlayEntry? _toast;

  /// Achievements, goals and challenge ticks appear briefly at the top
  /// (never a bottom bar), one at a time.
  void _nextToast() {
    if (!mounted || _toast != null || c.toasts.isEmpty) return;
    final text = c.toasts.removeAt(0);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: Semantics(
          liveRegion: true,
          child: Material(
            color: NF.card,
            elevation: 8,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NF.orange.withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: NF.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: NF.sora(14, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    _toast = entry;
    Overlay.of(context).insert(entry);
    Future.delayed(const Duration(milliseconds: 2600), () {
      // The screen may have closed (a life ended) and taken the toast
      // with it; remove it only once.
      if (entry.mounted) entry.remove();
      if (_toast == entry) _toast = null;
      if (mounted) _nextToast();
    });
  }

  @override
  void dispose() {
    _dockScroll.dispose();
    if (_toast?.mounted ?? false) _toast!.remove();
    _toast = null;
    super.dispose();
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
  const _Header({required this.life, this.onMoney, this.onFame});
  final Life life;
  final VoidCallback? onMoney;
  final VoidCallback? onFame;

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
                if (life.prison != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'In prison · ${life.prison!.left} ${life.prison!.left == 1 ? 'year' : 'years'} left',
                      style: NF.sora(
                        12,
                        weight: FontWeight.w600,
                        color: NF.orange,
                      ),
                    ),
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
                label: 'Bank balance ${money(life.money)}. Open Wealth',
                button: true,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onMoney,
                  behavior: HitTestBehavior.opaque,
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
                        const SizedBox(width: 2),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: Color(0xFF5EE6A8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Your fame tier, the star coloured by your public image.
              if (life.fame > 0) ...[
                const SizedBox(height: 6),
                Semantics(
                  label:
                      'Fame: ${fameTierOf(life).name}, image ${imageLabel(life.image)}. Open Social',
                  button: true,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: onFame,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: NF.orange.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: NF.orange.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: life.image >= 25
                                ? NF.orange
                                : life.image > -25
                                ? NF.soft
                                : NF.danger,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            life.fame < 10
                                ? 'Fame ${life.fame}'
                                : fameTierOf(life).name,
                            style: NF.sora(
                              13,
                              weight: FontWeight.w700,
                              color: NF.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
    this.docked = false,
  });
  final GameController controller;

  /// Activities are already open beside the game (desktop).
  final bool docked;
  final VoidCallback onSearch;
  final VoidCallback onActivities;

  @override
  Widget build(BuildContext context) {
    final blocked = controller.pendingEvent != null;
    // A story step is waiting: the button shows it instead of skipping a
    // year past it.
    final waiting = !blocked && controller.life!.sceneQueue.isNotEmpty;
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
            if (!docked)
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
                            Flexible(
                              child: Text(
                                'Swipe up for activities',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: NF.sora(12, color: NF.muted),
                              ),
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
              // Left-hand layout mirrors the Age +1 / search cluster.
              textDirection: controller.profile.leftHanded
                  ? TextDirection.rtl
                  : TextDirection.ltr,
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
                            Expanded(
                              child: Text(
                                'What do you want to do?',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: NF.sora(14, color: NF.muted),
                              ),
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
                      : waiting
                      ? 'Carry on with what you started'
                      : (atEnd ? 'See your life recap' : 'Live another year'),
                  child: FilledButton(
                    style: orangeButton(),
                    onPressed: blocked
                        ? null
                        : () {
                            controller.ageUp();
                            final big = controller.yearHighlights;
                            if (big.isEmpty) return;
                            controller.yearHighlights = const [];
                            showResultPopup(
                              context,
                              ActionResult(
                                big.length == 1
                                    ? big.first
                                    : 'Some big things happened this year:',
                                big.length == 1 ? const [] : big,
                              ),
                              title: 'Age ${controller.life!.age}: big news',
                              icon: Icons.campaign_rounded,
                            );
                          },
                    child: Text(
                      waiting
                          ? 'Continue'
                          : atEnd
                          ? 'Recap'
                          : 'Age +1',
                    ),
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

class _LifeTab extends StatefulWidget {
  const _LifeTab({required this.controller});
  final GameController controller;

  @override
  State<_LifeTab> createState() => _LifeTabState();
}

/// Story filters: which feed kinds each chip shows.
const _feedFilters = <String, Set<String>?>{
  'All': null,
  'Big moments': {'milestone', 'summary', 'report'},
  'People': {'npc', 'bond'},
  'News': {'world'},
};

class _LifeTabState extends State<_LifeTab> {
  String _filter = 'All';

  GameController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final kinds = _feedFilters[_filter];
    final feed = life.feed.reversed
        .where((e) => kinds == null || kinds.contains(e.kind))
        .take(60)
        .toList();
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
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final f in _feedFilters.keys)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: _filter == f,
                    onSelected: (_) => setState(() => _filter = f),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (feed.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(switch (_filter) {
              'People' => 'News about the people in your life shows up here.',
              'News' => 'World news shows up here once a year.',
              _ => 'Your big moments will be collected here.',
            }, style: NF.sora(14, color: NF.muted)),
          ),
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
    // The news reaching your life (news_impact.dart).
    final news = entry.kind == 'news';
    return Align(
      alignment: action ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: action ? NF.surface2 : NF.surface,
          border: milestone || news
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
                news
                    ? Icons.newspaper_rounded
                    : milestone
                    ? Icons.star_rounded
                    : (action ? Icons.bolt_rounded : Icons.chat_bubble_rounded),
                size: 15,
                color: milestone || news
                    ? NF.orange
                    : (action ? NF.blue : NF.muted),
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
            // Mental-health moments always show real-life support.
            if (event.category == 'mind') const HelplinePanel(),
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

/// Me tab, shaped like the Activities panel: a search box, "Suggested for
/// you", and Browse tiles for everything about you and your profile.
/// Screens open on top; cards (family, identity, country, world, memories,
/// hidden stats) open as sections with a way back.
class _MeTab extends StatefulWidget {
  const _MeTab({required this.controller});
  final GameController controller;

  @override
  State<_MeTab> createState() => _MeTabState();
}

typedef _MeItem = ({
  String id,
  IconData icon,
  String label,
  String status,
  String about,
  bool alert,
  bool dim,
});

class _MeTabState extends State<_MeTab> {
  String? _section;
  String _q = '';
  final _search = TextEditingController();

  GameController get controller => widget.controller;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _go(BuildContext context, String id) {
    Widget? screen = switch (id) {
      'health' => HealthScreen(controller: controller),
      'social' => SocialScreen(controller: controller),
      'goals' => GoalsScreen(controller: controller),
      'achievements' => AchievementsScreen(controller: controller),
      'collections' => CollectionsScreen(controller: controller),
      'settings' => SettingsScreen(controller: controller),
      _ => null,
    };
    if (screen != null) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    } else if (id == 'rewind') {
      showRewind(context, controller);
    } else {
      setState(() {
        _section = id;
        _search.clear();
        _q = '';
      });
    }
  }

  List<_MeItem> _items(Life life) {
    final p = controller.profile;
    final sick =
        life.conditions.any((c) => !c.treated && c.known) ||
        life.addictions.isNotEmpty;
    final now = DateTime.now();
    final goals = goalsFor(now).where((g) => goalDone(p, g.id, now)).length;
    return [
      (
        id: 'health',
        icon: Icons.monitor_heart_rounded,
        label: 'Health',
        status: sick ? 'Needs attention' : 'Body and mind',
        about: 'Conditions, insurance, fitness, addictions and your mind',
        alert: sick,
        dim: false,
      ),
      (
        id: 'social',
        icon: Icons.campaign_rounded,
        label: 'Social',
        status: life.age < 13
            ? 'From age 13'
            : life.followers.isEmpty
            ? 'Start posting'
            : '${fameTierOf(life).name} · ${imageLabel(life.image).toLowerCase()}',
        about: 'Posts, followers, fame, deals and scandals',
        alert: false,
        dim: life.age < 13,
      ),
      (
        id: 'goals',
        icon: Icons.bolt_rounded,
        label: 'Goals',
        status: '$goals/3 today',
        about: 'Daily goals, Sparks, streaks and weekly challenges',
        alert: false,
        dim: false,
      ),
      (
        id: 'achievements',
        icon: Icons.emoji_events_rounded,
        label: 'Achievements',
        status: '${p.achievements.length} of ${achievements.length}',
        about: 'Every achievement and how to earn it',
        alert: false,
        dim: false,
      ),
      (
        id: 'collections',
        icon: Icons.collections_bookmark_rounded,
        label: 'Collections',
        status: '${p.collections.values.fold(0, (a, v) => a + v.length)} found',
        about: 'Careers, countries, titles, pets and stories across lives',
        alert: false,
        dim: false,
      ),
      (
        id: 'family',
        icon: Icons.account_tree_rounded,
        label: 'Family tree',
        status: 'Generation ${life.generation}',
        about: 'Your parents, partner, children and the family line',
        alert: false,
        dim: false,
      ),
      (
        id: 'identity',
        icon: Icons.face_rounded,
        label: 'Identity',
        status: life.pronouns.isEmpty ? 'Who you are' : life.pronouns,
        about: 'Name, gender, pronouns and orientation',
        alert: false,
        dim: false,
      ),
      (
        id: 'country',
        icon: Icons.public_rounded,
        label: 'Country',
        status: life.country,
        about: 'Laws, healthcare, ages and moving abroad',
        alert: false,
        dim: false,
      ),
      (
        id: 'world',
        icon: Icons.history_edu_rounded,
        label: 'Your world',
        status: 'History',
        about: 'Your family name and the history earlier lives wrote',
        alert: false,
        dim: false,
      ),
      (
        id: 'memories',
        icon: Icons.photo_album_rounded,
        label: 'Memories',
        status: '${life.flags.length} kept',
        about: 'The big moments of this life',
        alert: false,
        dim: life.flags.isEmpty,
      ),
      (
        id: 'traits',
        icon: Icons.psychology_rounded,
        label: 'Hidden stats',
        status: 'Your traits',
        about: 'Karma, willpower, discipline and the rest',
        alert: false,
        dim: false,
      ),
      (
        id: 'rewind',
        icon: Icons.history_toggle_off_rounded,
        label: 'Rewind',
        status: 'Undo a year',
        about: 'Go back to an earlier birthday',
        alert: false,
        dim: false,
      ),
      (
        id: 'settings',
        icon: Icons.settings_rounded,
        label: 'Settings',
        status: 'Sound, display',
        about: 'Sound, difficulty, accessibility and content',
        alert: false,
        dim: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final items = _items(life);
    final s = _section;
    if (s != null) {
      final it = items.firstWhere((i) => i.id == s);
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        children: [
          SectionBar(
            back: 'Me',
            title: it.label,
            sub: it.about,
            onBack: () => setState(() => _section = null),
          ),
          switch (s) {
            'family' => FamilyTree(life: life),
            'identity' => IdentityCard(controller: controller),
            'country' => CountryCard(controller: controller),
            'world' => _WorldCard(controller: controller),
            'traits' => HiddenStats(life: life),
            _ => _memories(life),
          },
        ],
      );
    }
    final searching = _q.trim().isNotEmpty;
    final p = controller.profile;
    final now = DateTime.now();
    final goalsLeft = goalsFor(now)
        .where((g) => !goalDone(p, g.id, now))
        .toList();
    final health = items.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      children: [
        HubSearch(
          controller: _search,
          hint: 'Search Me: health, family, settings…',
          onChanged: (v) => setState(() => _q = v),
        ),
        if (searching) ...[
          const SizedBox(height: 14),
          for (final i in items.where(
            (i) => matchesQuery(_q, [i.label, i.about, i.status]),
          )) ...[
            OptionRow(
              icon: i.icon,
              title: i.label,
              detail: i.about,
              onTap: () => _go(context, i.id),
            ),
            const SizedBox(height: 8),
          ],
          if (!items.any((i) => matchesQuery(_q, [i.label, i.about, i.status])))
            Text(
              'Nothing matches "$_q". Try "health", "family" or "sound".',
              style: NF.sora(14, color: NF.muted),
            ),
        ] else ...[
          const HubHeading('Suggested for you'),
          if (health.alert) ...[
            OptionRow(
              icon: Icons.monitor_heart_rounded,
              title: 'Your health needs attention',
              detail: 'See a doctor, start treatment or get help',
              onTap: () => _go(context, 'health'),
            ),
            const SizedBox(height: 8),
          ],
          OptionRow(
            icon: Icons.bolt_rounded,
            title: goalsLeft.isEmpty
                ? 'All of today\'s goals done'
                : goalsLeft.first.text,
            detail: goalsLeft.isEmpty
                ? '${p.sparks} Sparks · ${p.streak}-day streak'
                : 'Daily goal · +20 Sparks · ${p.streak}-day streak',
            onTap: () => _go(context, 'goals'),
          ),
          const SizedBox(height: 8),
          OptionRow(
            icon: Icons.account_tree_rounded,
            title: 'Your family tree',
            detail: 'Generation ${life.generation} of the ${life.surname}s',
            onTap: () => _go(context, 'family'),
          ),
          const HubHeading('Browse'),
          BrowseGrid(
            items: [
              for (final i in items)
                BrowseItem(
                  icon: i.icon,
                  label: i.label,
                  status: i.status,
                  alert: i.alert,
                  dim: i.dim,
                  onTap: () => _go(context, i.id),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        const VersionCard(),
        if (_iosWeb) ...[
          const SizedBox(height: 10),
          NFCard(
            child: Row(
              children: [
                const Icon(Icons.ios_share_rounded, color: NF.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Play full-screen: in Safari tap Share, then Add to Home Screen. Your lives stay saved on this phone.',
                    style: NF.sora(13, color: NF.soft),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        // Plan HE: a neutral, out-of-character way to end a life. It goes
        // straight to the recap; the support panel shows once a session.
        OutlinedButton(
          style: secondaryButton(),
          onPressed: () async {
            final showHelp = !controller.helplineShown;
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: NF.surface,
                title: const Text('End this life and see your recap?'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'This life ends here and goes to the Life Recap. It cannot be continued.',
                      ),
                      if (showHelp) const HelplinePanel(),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Keep playing'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('End this life'),
                  ),
                ],
              ),
            );
            controller.helplineShown = true;
            if (ok == true) controller.endThisLife();
          },
          child: const Text('End this life'),
        ),
      ],
    );
  }

  Widget _memories(Life life) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (life.flags.isEmpty)
        Text('No big memories yet.', style: NF.sora(14, color: NF.muted)),
      for (final m
          in life.flags.values.toList()..sort((a, b) => a.age.compareTo(b.age)))
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Age ${m.age} · ${controller.engine!.fill(m.label, life)}',
            style: NF.sora(14, color: NF.soft),
          ),
        ),
    ],
  );
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
