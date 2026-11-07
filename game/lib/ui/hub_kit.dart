import 'package:flutter/material.dart';

import '../theme.dart';

/// The pieces that give every tab the same shape as the Activities panel:
/// a search box, "Suggested for you" rows, a "Browse" grid of tiles that
/// each open one section, and a section page with an obvious way back.

class HubSearch extends StatelessWidget {
  const HubSearch({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    style: NF.sora(15),
    onChanged: onChanged,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: NF.sora(14, color: NF.muted),
      prefixIcon: Icon(Icons.search, color: NF.muted),
      suffixIcon: controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: 'Clear search',
              icon: Icon(Icons.close_rounded, color: NF.muted),
              onPressed: () {
                controller.clear();
                onChanged('');
              },
            ),
      filled: true,
      fillColor: NF.surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

/// "Suggested for you", "Browse" and other headings, as in Activities.
class HubHeading extends StatelessWidget {
  const HubHeading(this.title, {super.key, this.sub});
  final String title;
  final String? sub;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: NF.sora(15, weight: FontWeight.w700)),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(sub!, style: NF.sora(12, color: NF.muted)),
        ],
      ],
    ),
  );
}

/// One tile in a Browse grid. [alert] marks something that needs the
/// player (shown in orange); [dim] marks a tile with nothing open yet.
class BrowseItem {
  const BrowseItem({
    required this.icon,
    required this.label,
    required this.status,
    required this.onTap,
    this.alert = false,
    this.dim = false,
  });

  final IconData icon;
  final String label;
  final String status;
  final VoidCallback onTap;
  final bool alert;
  final bool dim;
}

class BrowseGrid extends StatelessWidget {
  const BrowseGrid({super.key, required this.items});
  final List<BrowseItem> items;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cols = box.maxWidth > 420 ? 4 : 3;
      final w = (box.maxWidth - (cols - 1) * 10) / cols;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final i in items) SizedBox(width: w, child: BrowseTile(i)),
        ],
      );
    },
  );
}

class BrowseTile extends StatelessWidget {
  const BrowseTile(this.item, {super.key});
  final BrowseItem item;

  @override
  Widget build(BuildContext context) {
    final i = item;
    return Semantics(
      button: true,
      label: '${i.label}, ${i.status}',
      excludeSemantics: true,
      child: Material(
        color: i.dim ? NF.surface2.withValues(alpha: 0.45) : NF.surface2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: i.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(i.icon, size: 26, color: i.dim ? NF.muted : NF.orange),
                    if (i.alert)
                      Positioned(
                        right: -4,
                        top: -2,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: NF.danger,
                            shape: BoxShape.circle,
                            border: Border.all(color: NF.surface2, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    i.label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: NF.sora(
                      13,
                      weight: FontWeight.w600,
                      color: i.dim ? NF.muted : NF.text,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  i.status,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NF.sora(
                    11,
                    color: i.alert
                        ? NF.orange
                        : i.dim
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
}

/// The top of a section page: a back button to the tab's home, the
/// section's name and one line about it.
class SectionBar extends StatelessWidget {
  const SectionBar({
    super.key,
    required this.back,
    required this.title,
    required this.onBack,
    this.sub,
  });

  final String back;
  final String title;
  final String? sub;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: 'Back to $back',
          style: IconButton.styleFrom(backgroundColor: NF.surface2),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: onBack,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: NF.sora(19, weight: FontWeight.w700)),
              if (sub != null) Text(sub!, style: NF.sora(12, color: NF.muted)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Case-insensitive match of a search query against several words.
bool matchesQuery(String q, Iterable<String> words) {
  final t = q.trim().toLowerCase();
  if (t.isEmpty) return true;
  return words.any((w) => w.toLowerCase().contains(t));
}
