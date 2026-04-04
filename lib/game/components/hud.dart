import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../rocket_game.dart';

class HudComponent extends Component with HasGameRef<RocketGame> {
  int _score = 0;
  int _highscore = 0;
  double _speed = RocketGame.initialSpeed;

  void updateScore(int score, int highscore) {
    _score = score;
    _highscore = highscore;
  }

  void updateSpeed(double speed) => _speed = speed;

  @override
  void render(Canvas canvas) {
    _drawText(canvas, 'SCORE  $_score', const Offset(14, 14), 20,
        const Color(0xFF2196F3));
    _drawText(canvas, 'BEST  $_highscore',
        Offset(14, 42), 16, const Color(0xFF90CAF9));
    _drawSpeed(canvas);
  }

  void _drawText(
      Canvas canvas, String text, Offset offset, double fontSize, Color glowColor) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: glowColor, blurRadius: 10)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  void _drawSpeed(Canvas canvas) {
    final speedKmh = (_speed * 3.6).round(); // fun conversion
    final label = 'SPEED  $speedKmh km/h';

    // Speed bar background
    final barW = 120.0;
    final barH = 10.0;
    final barX = gameRef.size.x - barW - 14;
    final barY = 40.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(barX, barY, barW, barH),
          const Radius.circular(5)),
      Paint()..color = Colors.white.withOpacity(0.15),
    );

    final fill = ((_speed - RocketGame.initialSpeed) / 470).clamp(0.0, 1.0);
    final fillColor = Color.lerp(const Color(0xFF4CAF50), Colors.red, fill)!;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barX, barY, barW * fill, barH), const Radius.circular(5)),
      Paint()..color = fillColor,
    );

    // Speed text
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: fillColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: fillColor, blurRadius: 8)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(barX, barY - 22));
  }
}
