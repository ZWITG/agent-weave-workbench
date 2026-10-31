import 'package:flutter/material.dart';

import '../engine/community.dart';
import '../engine/world_data.dart';
import '../game_controller.dart';
import '../theme.dart';
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
        ],
      ),
    );
  }
}
