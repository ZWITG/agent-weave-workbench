import 'package:flutter/material.dart';

import '../engine/identity.dart';
import '../engine/lifespan.dart';
import '../engine/world_data.dart';
import '../game_controller.dart';
import '../theme.dart';
import 'widgets.dart';

class NewLifeScreen extends StatefulWidget {
  const NewLifeScreen({super.key, required this.controller});
  final GameController controller;

  @override
  State<NewLifeScreen> createState() => _NewLifeScreenState();
}

class _NewLifeScreenState extends State<NewLifeScreen> {
  final _name = TextEditingController();
  final _seed = TextEditingController();
  String? _seedError;
  String? _gender;
  String? _country;
  String? _identity;
  String? _pronouns;
  String? _interest;
  String? _family;

  @override
  void dispose() {
    _name.dispose();
    _seed.dispose();
    super.dispose();
  }

  Widget _chips(
    String title,
    List<String> options,
    String? value,
    void Function(String?) set, {
    String Function(String)? label,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: PickList<String?>(
      label: title,
      value: value,
      options: [
        (null, 'Random'),
        for (final o in options)
          (o, label?.call(o) ?? '${o[0].toUpperCase()}${o.substring(1)}'),
      ],
      onPick: (v) => setState(() => set(v)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NF.bg,
      body: GlowBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: EdgeInsets.all(24),
                children: [
                  SizedBox(height: 24),
                  const SectionLabel('Relivable'),
                  const SizedBox(height: 12),
                  Text(
                    'Every choice is remembered.',
                    style: NF.sora(30, weight: FontWeight.w700, height: 1.2),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Live a life from birth. People remember what you did, and so does the world.',
                    style: NF.sora(15, color: NF.soft, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    style: orangeButton().copyWith(
                      minimumSize: const WidgetStatePropertyAll(
                        Size.fromHeight(60),
                      ),
                    ),
                    onPressed: () => widget.controller.startLife(),
                    child: const Text('Surprise me'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: secondaryButton().copyWith(
                      minimumSize: const WidgetStatePropertyAll(
                        Size.fromHeight(52),
                      ),
                    ),
                    icon: const Icon(Icons.today_rounded),
                    label: Text(
                      'Daily Seed · ${seedCode(dailySeed(DateTime.now()))}',
                    ),
                    onPressed: () => widget.controller.startLife(
                      seed: dailySeed(DateTime.now()),
                    ),
                  ),
                  const SizedBox(height: 18),
                  NFCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionLabel('How hard?', color: NF.blue),
                        const SizedBox(height: 10),
                        PickList<String>(
                          label: 'Difficulty',
                          value: widget.controller.profile.difficulty,
                          options: [
                            for (final e in difficulties.entries)
                              (e.key, '${e.value.label} · ${e.value.blurb}'),
                          ],
                          onPick: (v) => setState(
                            () => widget.controller.updateProfile(
                              (p) => p.difficulty = v,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('Ironman (no Rewind)'),
                              selected: widget.controller.profile.ironman,
                              onSelected: (v) => setState(
                                () => widget.controller.updateProfile(
                                  (p) => p.ironman = v,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  NFCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionLabel('Or build a life', color: NF.blue),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _name,
                          style: NF.sora(15),
                          decoration: InputDecoration(
                            labelText: 'First name (optional)',
                            labelStyle: NF.sora(14, color: NF.muted),
                            filled: true,
                            fillColor: NF.surface2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Gender', style: NF.sora(13, color: NF.muted)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final g in const ['female', 'male'])
                              ChoiceChip(
                                label: Text(g == 'female' ? 'Female' : 'Male'),
                                selected: _gender == g,
                                onSelected: (v) =>
                                    setState(() => _gender = v ? g : null),
                              ),
                            ChoiceChip(
                              label: const Text('Random'),
                              selected: _gender == null,
                              onSelected: (_) => setState(() => _gender = null),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        PickList<String?>(
                          label: 'Country',
                          value: _country,
                          options: [
                            (null, 'Random'),
                            for (final n in [
                              for (final c in countries) c.name,
                            ]..sort())
                              (n, n),
                          ],
                          onPick: (v) => setState(() => _country = v),
                        ),
                        const SizedBox(height: 16),
                        _chips(
                          'Gender identity',
                          genderIdentities,
                          _identity,
                          (v) => _identity = v,
                        ),
                        _chips(
                          'Pronouns',
                          pronounSets.keys.toList(),
                          _pronouns,
                          (v) => _pronouns = v,
                        ),
                        _chips(
                          'Interested in (later in life)',
                          const ['women', 'men', 'everyone'],
                          _interest,
                          (v) => _interest = v,
                        ),
                        _chips(
                          'Family',
                          const [
                            'two',
                            'single_mum',
                            'single_dad',
                            'two_mums',
                            'two_dads',
                          ],
                          _family,
                          (v) => _family = v,
                          label: (f) => switch (f) {
                            'two' => 'Mum and dad',
                            'single_mum' => 'Single mum',
                            'single_dad' => 'Single dad',
                            'two_mums' => 'Two mums',
                            _ => 'Two dads',
                          },
                        ),
                        Text(
                          'Identity never changes your stats or what you can do. Leave anything on Random.',
                          style: NF.sora(12, color: NF.muted),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          style: primaryButton().copyWith(
                            minimumSize: const WidgetStatePropertyAll(
                              Size.fromHeight(56),
                            ),
                          ),
                          onPressed: () => widget.controller.startLife(
                            firstName: _name.text,
                            gender: _gender,
                            country: _country,
                            family: _family,
                            identity: _identity,
                            pronouns: _pronouns,
                            interest: _interest,
                          ),
                          child: const Text('Be born'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  NFCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionLabel('Have a seed code?', color: NF.blue),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _seed,
                          style: NF.sora(15),
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: '#RL-1A2B3C',
                            errorText: _seedError,
                            filled: true,
                            fillColor: NF.surface2,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          style: secondaryButton(),
                          onPressed: () {
                            final seed = parseSeedCode(_seed.text);
                            if (seed == null) {
                              setState(
                                () => _seedError =
                                    'That code doesn\'t look right',
                              );
                              return;
                            }
                            widget.controller.startLife(seed: seed);
                          },
                          child: const Text('Live this seed'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Lives run from birth to old age. Your world remembers every one.',
                    textAlign: TextAlign.center,
                    style: NF.sora(12, color: NF.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
