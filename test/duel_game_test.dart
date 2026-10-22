import 'package:flutter_test/flutter_test.dart';
import 'package:tap_duel/game/duel_game.dart';

Duration ms(int v) => Duration(milliseconds: v);

void main() {
  group('single taps', () {
    test('each spaced-out tap adds +1', () {
      final g = DuelGame();
      g.tap(Player.kohli, ms(0));
      g.tap(Player.kohli, ms(300));
      g.tap(Player.kohli, ms(600));
      expect(g.score(Player.kohli), 3);
    });

    test('players score independently', () {
      final g = DuelGame();
      g.tap(Player.kohli, ms(0));
      g.tap(Player.rohit, ms(50)); // close in time, but a different player
      expect(g.score(Player.kohli), 1);
      expect(g.score(Player.rohit), 1);
    });
  });

  group('double tap', () {
    test('a pair inside the window nets -1', () {
      final g = DuelGame();
      for (var i = 0; i < 5; i++) {
        g.tap(Player.kohli, ms(i * 300));
      }
      expect(g.score(Player.kohli), 5);
      g.tap(Player.kohli, ms(2000)); // +1 -> 6
      final o = g.tap(Player.kohli, ms(2150)); // double -> 4
      expect(o.isDoubleTap, isTrue);
      expect(o.delta, -2);
      expect(g.score(Player.kohli), 4);
    });

    test('a third fast tap starts a new pair instead of chaining', () {
      final g = DuelGame()
        ..tap(Player.kohli, ms(0)) // 1
        ..tap(Player.kohli, ms(100)) // double -> 0
        ..tap(Player.kohli, ms(200)); // new single -> 1
      expect(g.score(Player.kohli), 1);
    });

    test('score never goes below zero', () {
      final g = DuelGame()
        ..tap(Player.rohit, ms(0))
        ..tap(Player.rohit, ms(100));
      expect(g.score(Player.rohit), 0);
    });

    test('a tap just outside the window is a normal +1', () {
      final g = DuelGame()
        ..tap(Player.kohli, ms(0))
        ..tap(Player.kohli, ms(201));
      expect(g.score(Player.kohli), 2);
    });
  });

  group('winning', () {
    test('first to target wins and further taps are ignored', () {
      final g = DuelGame(target: 3);
      g.tap(Player.kohli, ms(0));
      g.tap(Player.kohli, ms(300));
      final o = g.tap(Player.kohli, ms(600));
      expect(o.wonGame, isTrue);
      expect(g.winner, Player.kohli);
      g.tap(Player.rohit, ms(900));
      expect(g.score(Player.rohit), 0);
    });
  });

  group('danger meter', () {
    test('relaxed rhythm is 0, double-tap rhythm is 1', () {
      final g = DuelGame()
        ..tap(Player.kohli, ms(0))
        ..tap(Player.kohli, ms(600));
      expect(g.danger(Player.kohli), 0);
      g.tap(Player.kohli, ms(700));
      expect(g.danger(Player.kohli), 1);
    });
  });
}
