import 'package:flutter/material.dart';

import 'game_controller.dart';
import 'theme.dart';
import 'ui/hub_screen.dart';
import 'ui/new_life_screen.dart';
import 'ui/recap_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RelivableApp(controller: GameController()..load()));
}

class RelivableApp extends StatelessWidget {
  const RelivableApp({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Relivable',
      debugShowCheckedModeBanner: false,
      theme: NF.theme(),
      home: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.loading) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (controller.engine == null) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Something went wrong loading the game.\n${controller.loadError ?? ''}',
                      textAlign: TextAlign.center),
                ),
              ),
            );
          }
          if (controller.life == null) return NewLifeScreen(controller: controller);
          if (controller.sliceFinished) return RecapScreen(controller: controller);
          return HubScreen(controller: controller);
        },
      ),
    );
  }
}
