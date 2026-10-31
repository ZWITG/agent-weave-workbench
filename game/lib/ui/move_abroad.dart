import 'package:flutter/material.dart';

import '../engine/community.dart';
import '../engine/currency.dart';
import '../engine/migration.dart';
import '../engine/world_data.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'activities.dart' show OptionRow;
import 'result_popup.dart';
import 'widgets.dart';

/// Moving abroad: pick a country from a drop-down list, see what life
/// there is like and how a visa looks, then apply.
class MoveAbroadScreen extends StatefulWidget {
  const MoveAbroadScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<MoveAbroadScreen> createState() => _MoveAbroadScreenState();
}

class _MoveAbroadScreenState extends State<MoveAbroadScreen> {
  String? _to;

  Future<void> _crossWithoutVisa(BuildContext context, String to) async {
    final c = widget.controller;
    final l = c.life!;
    final route = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: NF.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          children: [
            Text(
              'Into $to without a visa',
              style: NF.sora(18, weight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'It is illegal. If you make it, you can only work cash-in-hand jobs for less pay, no bank will lend to you, and immigration checks can send you home.',
              style: NF.sora(13, color: NF.muted),
            ),
            const SizedBox(height: 12),
            for (final r in routes)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OptionRow(
                  icon: switch (r.id) {
                    'overstay' => Icons.flight_land_rounded,
                    'smuggler' => Icons.handshake_rounded,
                    _ => Icons.local_shipping_rounded,
                  },
                  title: '${r.label} · ${money(r.cost)}',
                  detail: migrateLock(l, r.id) ?? '${r.blurb}. ${r.risk}.',
                  locked: migrateLock(l, r.id) != null,
                  onTap: () => Navigator.pop(ctx, r.id),
                ),
              ),
          ],
        ),
      ),
    );
    if (route == null || !mounted) return;
    final r = c.migrateIllegally(to, route);
    final nav = Navigator.of(this.context);
    nav.pop();
    showResultPopup(
      nav.context,
      r,
      title: 'Crossing into $to',
      icon: Icons.warning_amber_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final l = c.life!;
    final options =
        countries.where((x) => x.name != l.country).map((x) => x.name).toList()
          ..sort();
    final to = _to;
    final p = to == null ? null : countryProfile(to);
    final odds = to == null ? null : visaOdds(l, to).$1;
    final short = l.money < emigrateCost;
    Widget fact(String k, String v) => Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Text(k, style: NF.sora(13, color: NF.muted)),
          const Spacer(),
          Text(v, style: NF.sora(13, weight: FontWeight.w600)),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: NF.bg,
      appBar: AppBar(
        backgroundColor: NF.bg,
        title: Text('Move abroad', style: NF.sora(18, weight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Text(
            'You live in ${l.city}, ${l.country}. A visa and the move cost ${money(emigrateCost)}; if the visa is refused, the fee is gone.',
            style: NF.sora(14, color: NF.soft),
          ),
          if (undocumented(l)) ...[
            const SizedBox(height: 8),
            Text(
              'You are living here without papers.',
              style: NF.sora(13, color: NF.danger),
            ),
          ],
          if (wasDeported(l)) ...[
            const SizedBox(height: 8),
            Text(
              'A deportation on your file makes visas harder to get.',
              style: NF.sora(13, color: NF.orange),
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: to,
            isExpanded: true,
            dropdownColor: NF.surface,
            decoration: InputDecoration(
              labelText: 'Where to?',
              filled: true,
              fillColor: NF.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            hint: const Text('Choose a country'),
            items: [
              for (final name in options)
                DropdownMenuItem(value: name, child: Text(name)),
            ],
            onChanged: (v) => setState(() => _to = v),
          ),
          if (p != null && to != null) ...[
            const SizedBox(height: 16),
            NFCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(to, style: NF.sora(18, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(p.blurb, style: NF.sora(13, color: NF.soft)),
                  if (p.culture.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(p.culture, style: NF.sora(12, color: NF.muted)),
                  ],
                  const SizedBox(height: 6),
                  fact('Visa', visaOutlook(odds!)),
                  fact('Money', currencyLabel(to)),
                  fact('Pay', p.payLabel),
                  fact('Cost of living', p.costLabel),
                  fact('Healthcare', p.healthcare),
                  fact('University', p.tuitionLabel),
                  fact('Military service', p.draftLabel),
                  fact('Safety', p.safety),
                  fact('Languages', p.languages.join(', ')),
                  if (p.climate == 'hostile')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Warning: LGBTQ+ people face legal risk here.',
                        style: NF.sora(13, color: NF.danger),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            style: primaryButton(),
            onPressed: to == null || short
                ? null
                : () {
                    final r = c.emigrate(to);
                    final nav = Navigator.of(context);
                    nav.pop();
                    showResultPopup(
                      nav.context,
                      r,
                      title: 'Moving to $to',
                      icon: Icons.flight_takeoff_rounded,
                    );
                  },
            child: Text(
              short
                  ? 'Needs ${money(emigrateCost)}'
                  : to == null
                  ? 'Choose a country first'
                  : 'Apply for a visa · ${money(emigrateCost)}',
            ),
          ),
          const SizedBox(height: 10),
          // The illegal way: three routes, each with its own price and risk.
          OutlinedButton.icon(
            style: secondaryButton(),
            icon: const Icon(Icons.warning_amber_rounded, size: 18),
            onPressed: to == null || l.age < 16
                ? null
                : () => _crossWithoutVisa(context, to),
            label: Text(
              l.age < 16
                  ? 'Cross without a visa · from 16'
                  : 'Cross without a visa',
            ),
          ),
        ],
      ),
    );
  }
}
