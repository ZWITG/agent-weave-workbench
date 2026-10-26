import 'package:flutter/material.dart';

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
  String? _gender;
  String? _country;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NF.bg,
      body: GlowBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 28),
                  NFCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel('Or build a life', color: NF.blue),
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
                        Text('Country', style: NF.sora(13, color: NF.muted)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('Random'),
                              selected: _country == null,
                              onSelected: (_) =>
                                  setState(() => _country = null),
                            ),
                            for (final c in countries)
                              ChoiceChip(
                                label: Text(c.name),
                                selected: _country == c.name,
                                onSelected: (v) => setState(
                                  () => _country = v ? c.name : null,
                                ),
                              ),
                          ],
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
                          ),
                          child: const Text('Be born'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Prototype: lives run from birth to age 30.',
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
