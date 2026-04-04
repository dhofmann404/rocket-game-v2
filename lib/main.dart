import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/rocket_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    GameWidget<RocketGame>(
      game: RocketGame(),
      overlayBuilderMap: {
        'GameOver': (context, game) => _GameOverOverlay(game: game),
      },
    ),
  );
}

class _GameOverOverlay extends StatelessWidget {
  final RocketGame game;
  const _GameOverOverlay({required this.game});

  @override
  Widget build(BuildContext context) {
    final speedKmh = (game.speed * 3.6).round();
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xDD000020),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.redAccent, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('RAKETE EXPLODIERT',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
            const SizedBox(height: 16),
            Text('Score: ${game.score}',
                style: const TextStyle(color: Colors.white, fontSize: 22)),
            const SizedBox(height: 4),
            Text('Highscore: ${game.highscore}',
                style: const TextStyle(color: Color(0xFF90CAF9), fontSize: 18)),
            const SizedBox(height: 4),
            Text('Max Speed: $speedKmh km/h',
                style: const TextStyle(color: Colors.orange, fontSize: 16)),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
              ),
              onPressed: () {
                game.overlays.remove('GameOver');
                game.resetGame();
              },
              child: const Text('NOCHMAL',
                  style: TextStyle(fontSize: 18, letterSpacing: 2)),
            ),
          ],
        ),
      ),
    );
  }
}
