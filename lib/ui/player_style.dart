import 'package:flutter/material.dart';

import '../game/duel_game.dart';

/// Look and feel for one side of the duel.
class PlayerStyle {
  const PlayerStyle({
    required this.name,
    required this.jersey,
    required this.photo,
    required this.primary,
    required this.deep,
    required this.accent,
  });

  final String name;
  final String jersey;
  final String photo;
  final Color primary;
  final Color deep;
  final Color accent;

  static const kohli = PlayerStyle(
    name: 'KOHLI',
    jersey: '18',
    photo: 'assets/players/kohli.png',
    primary: Color(0xFFE0161E),
    deep: Color(0xFF3D0306),
    accent: Color(0xFFF5C542),
  );

  static const rohit = PlayerStyle(
    name: 'ROHIT',
    jersey: '45',
    photo: 'assets/players/rohit.png',
    primary: Color(0xFF0A5BD6),
    deep: Color(0xFF020F33),
    accent: Color(0xFFF5C542),
  );

  static PlayerStyle of(Player p) => p == Player.kohli ? kohli : rohit;
}
