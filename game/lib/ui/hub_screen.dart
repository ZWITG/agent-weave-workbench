import 'package:flutter/material.dart';

import '../engine/engine.dart';
import '../engine/models.dart';
import '../engine/storylet.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'activities.dart';
import 'outcome_card.dart';
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

  GameController get c => widget.controller;
  Life get life => c.life!;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _LifeTab(controller: c),
      PeopleTab(controller: c),
      _PathTab(life: life),
      _WealthTab(life: life),
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
            progress: life.age / sliceEndAge,
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
                child: StatTile(statKey: row[0], value: life.stats[row[0]]),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(statKey: row[1], value: life.stats[row[1]]),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
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
          _FeedBubble(entry: feed[i]),
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

class _FeedBubble extends StatelessWidget {
  const _FeedBubble({required this.entry});
  final FeedEntry entry;

  @override
  Widget build(BuildContext context) {
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
        event.choices.every((c) => engine.fill(c.label, life).length <= 18);
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
    final label = Text(
      engine.fill(choice.label, life),
      textAlign: TextAlign.center,
    );
    return i == 0
        ? FilledButton(
            style: primaryButton(),
            onPressed: () => controller.choose(choice),
            child: label,
          )
        : OutlinedButton(
            style: secondaryButton(),
            onPressed: () => controller.choose(choice),
            child: label,
          );
  }
}

// ---------------- Path tab ----------------

class _PathTab extends StatelessWidget {
  const _PathTab({required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Life stage', life.stage),
      ('Education', _cap(life.education)),
      ('Job', life.job ?? 'None'),
      ('Salary', life.salary > 0 ? '\$${life.salary}/year' : '—'),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      children: [
        const SectionLabel('Your path'),
        const SizedBox(height: 10),
        NFCard(
          child: Column(children: [for (final r in rows) _kv(r.$1, r.$2)]),
        ),
        const SizedBox(height: 12),
        Text(
          'Find jobs, school actions and more with the search bar.',
          style: NF.sora(13, color: NF.muted),
        ),
      ],
    );
  }
}

// ---------------- Wealth tab ----------------

class _WealthTab extends StatelessWidget {
  const _WealthTab({required this.life});
  final Life life;

  @override
  Widget build(BuildContext context) {
    final assets = [
      if (life.flags.containsKey('owns_car')) 'Used car',
      if (life.flags.containsKey('own_flat')) 'Rented flat',
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      children: [
        const SectionLabel('Wealth'),
        const SizedBox(height: 10),
        NFCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Bank balance', style: NF.sora(13, color: NF.muted)),
              const SizedBox(height: 4),
              Text(
                money(life.money),
                style: NF.sora(
                  32,
                  weight: FontWeight.w700,
                  color: life.money < 0 ? NF.danger : NF.text,
                ),
              ),
              if (life.salary > 0)
                Text(
                  '+\$${life.salary} a year',
                  style: NF.sora(13, color: NF.blue),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        NFCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assets', style: NF.sora(15, weight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (assets.isEmpty)
                Text('Nothing yet.', style: NF.sora(14, color: NF.muted)),
              for (final a in assets)
                Text('• $a', style: NF.sora(14, color: NF.soft)),
            ],
          ),
        ),
      ],
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
        const SizedBox(height: 16),
        const SectionLabel('Hidden stats'),
        const SizedBox(height: 10),
        for (final k in Stats.hidden) ...[
          StatBar(label: _cap(k), value: life.stats[k], color: NF.orange),
          const SizedBox(height: 8),
        ],
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

Widget _kv(String k, String v) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 8),
  child: Row(
    children: [
      Expanded(
        child: Text(k, style: NF.sora(14, color: NF.muted)),
      ),
      Text(v, style: NF.sora(14, weight: FontWeight.w600)),
    ],
  ),
);

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
