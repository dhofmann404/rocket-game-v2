import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../rocket_game.dart';

class HudComponent extends Component with HasGameRef<RocketGame> {
  int _score = 0;
  int _lives = RocketGame.maxLives;

  void updateScore(int score) => _score = score;
  void updateLives(int lives) => _lives = lives;

  @override
  void render(Canvas canvas) {
    _drawScore(canvas);
    _drawLives(canvas);
  }

  void _drawScore(Canvas canvas) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'SCORE  $_score',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Color(0xFF2196F3), blurRadius: 10)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(14, 14));
  }

  void _drawLives(Canvas canvas) {
    for (int i = 0; i < _lives; i++) {
      final tp = TextPainter(
        text: const TextSpan(
          text: '♥',
          style: TextStyle(
            color: Colors.red,
            fontSize: 24,
            shadows: [Shadow(color: Colors.redAccent, blurRadius: 8)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(gameRef.size.x - 38 - i * 30.0, 10));
    }
  }
}
