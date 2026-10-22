import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/match_screen.dart';
import 'ui/sound_bank.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SoundBank.instance.load();
  runApp(const TapDuelApp());
}

class TapDuelApp extends StatelessWidget {
  const TapDuelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap Duel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
      home: const MatchScreen(),
    );
  }
}
