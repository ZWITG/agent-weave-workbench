import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'game_controller.dart';
import 'theme.dart';
import 'ui/intro.dart';
import 'ui/hub_screen.dart';
import 'ui/new_life_screen.dart';
import 'ui/recap_screen.dart';
import 'ui/update_prompt.dart';
import 'ui/colour_modes.dart';
import 'ui/lockdown.dart';
import 'ui/invitation.dart';
import 'engine/elite.dart' show upperEchelon;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // The fonts' SIL Open Font License, shown with the other licences.
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Sora',
      'Caveat',
      'Stardos Stencil',
      'Playfair Display',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  runApp(RelivableApp(controller: GameController()..load()));
}

class RelivableApp extends StatelessWidget {
  const RelivableApp({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => _app(),
    );
  }

  Widget _app() {
    final p = controller.profile;
    // In prison the whole game wears Yard Time (theme.dart, yard_time.dart).
    final l = controller.life;
    // In the upper echelon it wears Gilded (black and molten gold).
    NF.look(
      prison: l != null && l.alive && l.prison != null,
      rich: l != null && l.alive && upperEchelon(l),
    );
    return MaterialApp(
      title: 'Relivable',
      debugShowCheckedModeBanner: false,
      theme: NF.theme(),
      // Text size and reduce motion from Settings (plan SOC-SE-003/005).
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(p.textScale),
          disableAnimations: p.reduceMotion,
        ),
        // Colour-vision mode applies to the whole app (plan UX §8.3), and
        // the ZWITG / Relivable opening plays over it.
        // Going in or coming out of prison plays Lockdown (lockdown.dart):
        // one look consuming the other.
        child: IntroGate(
          reduceMotion: p.reduceMotion,
          child: Builder(
            builder: (context) {
              final game = Lockdown(
                controller: controller,
                reduceMotion: p.reduceMotion,
                // Crossing into the upper echelon, and each tier after it,
                // plays the Invitation (invitation.dart).
                child: Ascension(
                  controller: controller,
                  reduceMotion: p.reduceMotion,
                  child: child!,
                ),
              );
              return colourMatrices[p.colourMode] == null
                  ? game
                  : ColorFiltered(
                      colorFilter: ColorFilter.matrix(
                        colourMatrices[p.colourMode]!,
                      ),
                      child: game,
                    );
            },
          ),
        ),
      ),
      home: UpdateGate(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (controller.loading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (controller.engine == null) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Something went wrong loading the game.\n${controller.loadError ?? ''}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () {
                            controller.loading = true;
                            controller.loadError = null;
                            controller.notifyListeners();
                            controller.load();
                          },
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            if (controller.life == null) {
              return NewLifeScreen(controller: controller);
            }
            if (controller.sliceFinished) {
              return RecapScreen(controller: controller);
            }
            return HubScreen(controller: controller);
          },
        ),
      ),
    );
  }
}
