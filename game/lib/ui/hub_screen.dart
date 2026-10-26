import 'package:flutter/material.dart';

import '../engine/actions.dart';
import '../engine/engine.dart';
import '../engine/models.dart';
import '../engine/storylet.dart';
import '../game_controller.dart';
import '../theme.dart';
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
      _PeopleTab(controller: c),
      _PathTab(life: life),
      _WealthTab(life: life),
      _MeTab(controller: c),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                _Header(life: life),
                Expanded(child: IndexedStack(index: _tab, children: tabs)),
                _BottomBar(controller: c, onSearch: () => _openSearch(context)),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        height: 64,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.auto_stories_outlined), selectedIcon: Icon(Icons.auto_stories), label: 'Life'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'People'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Path'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wealth'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }

  void _openSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ActionSearch(controller: c),
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
          Avatar(initials: life.initials),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(life.fullName, style: NF.sora(20, weight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                Text('${life.age} · ${life.job ?? life.stage} · ${life.city}',
                    style: NF.sora(13, color: NF.muted), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Pill('${life.year}'),
        ],
      ),
    );
  }
}

// ---------------- Bottom bar: search + Age +1 ----------------

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.controller, required this.onSearch});
  final GameController controller;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final blocked = controller.pendingEvent != null;
    final atEnd = controller.life!.age >= sliceEndAge;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
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
                  child: Row(children: [
                    const Icon(Icons.search, color: NF.muted, size: 20),
                    const SizedBox(width: 8),
                    Text('What do you want to do?', style: NF.sora(14, color: NF.muted)),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: blocked ? 'Choose an option first' : (atEnd ? 'See your life recap' : 'Live another year'),
            child: FilledButton(
              style: orangeButton(),
              onPressed: blocked ? null : (atEnd ? () => controller.ageUp() : controller.ageUp),
              child: Text(atEnd ? 'Recap' : 'Age +1'),
            ),
          ),
        ],
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
        for (final k in Stats.visible) ...[
          StatBar(label: k[0].toUpperCase() + k.substring(1), value: life.stats[k]),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        if (controller.pendingEvent != null) _EventCard(controller: controller, event: controller.pendingEvent!),
        if (controller.lastOutcome != null) _OutcomeCard(controller: controller, outcome: controller.lastOutcome!),
        const SizedBox(height: 12),
        for (final entry in feed) _FeedBubble(entry: entry),
      ],
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
          border: milestone ? Border.all(color: NF.orange.withValues(alpha: 0.6)) : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(action ? 18 : 6),
            bottomRight: Radius.circular(action ? 6 : 18),
          ),
        ),
        child: Text.rich(TextSpan(children: [
          TextSpan(text: 'Age ${entry.age} · ', style: NF.sora(13, weight: FontWeight.w700, color: NF.muted)),
          TextSpan(text: entry.text, style: NF.sora(14, color: NF.soft, height: 1.45)),
        ])),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.controller, required this.event});
  final GameController controller;
  final Storylet event;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    final engine = controller.engine!;
    final mem = event.remembers != null ? life.flags[event.remembers] : null;
    final compact = event.choices.length == 3 && event.choices.every((c) => engine.fill(c.label, life).length <= 18);
    return Semantics(
      container: true,
      liveRegion: true,
      child: NFCard(
        color: NF.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel('Now · ${event.category}'),
            const SizedBox(height: 10),
            Text(engine.fill(event.text, life), style: NF.sora(19, weight: FontWeight.w600, height: 1.35)),
            if (mem != null) ...[
              const SizedBox(height: 8),
              Text('Remembers: ${engine.fill(mem.label, life)} (age ${mem.age})', style: NF.sora(12, color: NF.muted)),
            ],
            const SizedBox(height: 14),
            if (compact)
              Row(children: [
                for (var i = 0; i < event.choices.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _choiceButton(i, life, engine)),
                ],
              ])
            else
              Column(children: [
                for (var i = 0; i < event.choices.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  SizedBox(width: double.infinity, child: _choiceButton(i, life, engine)),
                ],
              ]),
          ],
        ),
      ),
    );
  }

  Widget _choiceButton(int i, Life life, GameEngine engine) {
    final choice = event.choices[i];
    final label = Text(engine.fill(choice.label, life), textAlign: TextAlign.center);
    return i == 0
        ? FilledButton(style: primaryButton(), onPressed: () => controller.choose(choice), child: label)
        : OutlinedButton(style: secondaryButton(), onPressed: () => controller.choose(choice), child: label);
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({required this.controller, required this.outcome});
  final GameController controller;
  final Outcome outcome;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: NFCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('What happened', color: NF.blue),
            const SizedBox(height: 10),
            Text(outcome.text, style: NF.sora(16, height: 1.45)),
            if (outcome.notes.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (final n in outcome.notes) Pill(n, bg: NF.surface2, fg: NF.text),
              ]),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: controller.dismissOutcome, child: const Text('OK')),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Action search ----------------

class _ActionSearch extends StatefulWidget {
  const _ActionSearch({required this.controller});
  final GameController controller;

  @override
  State<_ActionSearch> createState() => _ActionSearchState();
}

class _ActionSearchState extends State<_ActionSearch> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final life = c.life!;
    final results = c.engine!.actions.where((a) => a.matches(_q)).toList()
      ..sort((a, b) => (a.lockReason(life) == null ? 0 : 1).compareTo(b.lockReason(life) == null ? 0 : 1));
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: TextField(
                autofocus: true,
                style: NF.sora(15),
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: 'Try "job", "gym", "party", "money"…',
                  hintStyle: NF.sora(14, color: NF.muted),
                  prefixIcon: const Icon(Icons.search, color: NF.muted),
                  filled: true,
                  fillColor: NF.surface2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: results.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) => _actionTile(context, results[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(BuildContext context, GameAction a) {
    final c = widget.controller;
    final lock = a.lockReason(c.life!);
    return Material(
      color: NF.surface2,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        minTileHeight: 56,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(a.label, style: NF.sora(15, weight: FontWeight.w600, color: lock == null ? NF.text : NF.muted)),
        subtitle: Text(lock ?? a.category, style: NF.sora(12, color: lock == null ? NF.muted : NF.orange)),
        trailing: Icon(lock == null ? Icons.chevron_right : Icons.lock_outline, color: NF.muted),
        onTap: lock != null
            ? null
            : () {
                final r = c.runAction(a);
                Navigator.of(context).pop();
                _showResult(context, r);
              },
      ),
    );
  }
}

void _showResult(BuildContext context, ActionResult r) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(r.notes.isEmpty ? r.text : '${r.text}\n${r.notes.join(' · ')}'),
    duration: const Duration(seconds: 4),
  ));
}

// ---------------- People tab ----------------

class _PeopleTab extends StatelessWidget {
  const _PeopleTab({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final life = controller.life!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      children: [
        const SectionLabel('Family'),
        const SizedBox(height: 10),
        for (final n in life.npcs) ...[
          NFCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Avatar(initials: n.name.substring(0, 1), size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(n.name, style: NF.sora(16, weight: FontWeight.w700)),
                      Text('${n.role} · ${n.ageIn(life.year)}', style: NF.sora(12, color: NF.muted)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                StatBar(label: 'Bond', value: n.bond, color: NF.orange),
                if (n.memories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Remembers: "${n.memories.last}"', style: NF.sora(12, color: NF.muted)),
                ],
                const SizedBox(height: 10),
                Builder(builder: (context) {
                  final lock = controller.spendTimeLock(n);
                  return OutlinedButton(
                    style: secondaryButton().copyWith(minimumSize: const WidgetStatePropertyAll(Size(64, 44))),
                    onPressed: lock != null
                        ? null
                        : () => ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(controller.spendTime(n)))),
                    child: Text(lock ?? 'Spend time together'),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
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
        NFCard(child: Column(children: [for (final r in rows) _kv(r.$1, r.$2)])),
        const SizedBox(height: 12),
        Text('Find jobs, school actions and more with the search bar.', style: NF.sora(13, color: NF.muted)),
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bank balance', style: NF.sora(13, color: NF.muted)),
            const SizedBox(height: 4),
            Text('\$${life.money}', style: NF.sora(32, weight: FontWeight.w700, color: life.money < 0 ? NF.danger : NF.text)),
            if (life.salary > 0) Text('+\$${life.salary} a year', style: NF.sora(13, color: NF.blue)),
          ]),
        ),
        const SizedBox(height: 10),
        NFCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Assets', style: NF.sora(15, weight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (assets.isEmpty) Text('Nothing yet.', style: NF.sora(14, color: NF.muted)),
            for (final a in assets) Text('• $a', style: NF.sora(14, color: NF.soft)),
          ]),
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
        const SectionLabel('Hidden stats'),
        const SizedBox(height: 10),
        for (final k in Stats.hidden) ...[
          StatBar(label: _cap(k), value: life.stats[k], color: NF.orange),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        const SectionLabel('Memories', color: NF.blue),
        const SizedBox(height: 10),
        if (life.flags.isEmpty) Text('No big memories yet.', style: NF.sora(14, color: NF.muted)),
        for (final m in life.flags.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('Age ${m.age} · ${controller.engine!.fill(m.label, life)}', style: NF.sora(14, color: NF.soft)),
          ),
        const SizedBox(height: 24),
        OutlinedButton(
          style: secondaryButton(),
          onPressed: () async {
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Start a new life?'),
                content: const Text('This life will end and cannot be continued.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep playing')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('New life')),
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
      child: Row(children: [
        Expanded(child: Text(k, style: NF.sora(14, color: NF.muted))),
        Text(v, style: NF.sora(14, weight: FontWeight.w600)),
      ]),
    );

String _cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
