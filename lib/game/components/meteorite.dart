import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../rocket_game.dart';
import 'bullet.dart';
import 'rocket.dart';
import 'meteorite_chunk.dart';

class Meteorite extends PositionComponent
    with HasGameRef<RocketGame>, CollisionCallbacks {
  final double radius;
  final double speed;

  bool _destroyed = false;
  final Random _random = Random();

  late Color _color;
  late List<_Crater> _craters;

  static const List<Color> _colors = [
    Color(0xFF795548),
    Color(0xFF8D6E63),
    Color(0xFF9E9E9E),
    Color(0xFF6D4C41),
  ];

  Meteorite({
    required Vector2 position,
    required this.radius,
    required this.speed,
  }) : super(
          position: position,
          anchor: Anchor.center,
          size: Vector2.all(radius * 2),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _color = _colors[_random.nextInt(_colors.length)];
    _craters = List.generate(
      2 + _random.nextInt(3),
      (_) => _Crater(
        dx: _random.nextDouble() * 0.7 - 0.35,
        dy: _random.nextDouble() * 0.7 - 0.35,
        r: 0.08 + _random.nextDouble() * 0.12,
      ),
    );
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_destroyed) return;
    position.y += speed * dt;
    if (position.y > gameRef.size.y + radius) {
      gameRef.loseLife();
      removeFromParent();
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    if (_destroyed) return;

    if (other is Bullet) {
      _destroyed = true;
      gameRef.addScore(10);
      _explode();
      other.removeFromParent();
      removeFromParent();
    } else if (other is Rocket) {
      _destroyed = true;
      gameRef.loseLife();
      _explode();
      removeFromParent();
    }
  }

  void _explode() {
    final count = 6 + _random.nextInt(4);
    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * pi + _random.nextDouble() * 0.6;
      final spd = 80.0 + _random.nextDouble() * 130;
      final chunkR = radius * (0.18 + _random.nextDouble() * 0.32);
      gameRef.add(MeteoriteChunk(
        position: position.clone(),
        velocity: Vector2(cos(angle) * spd, sin(angle) * spd - 60),
        radius: chunkR,
        color: _color,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    final c = Offset(radius, radius);

    // Body
    canvas.drawCircle(c, radius, Paint()..color = _color);

    // Dark shading on right/bottom
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.4),
          ],
        ).createShader(
          Rect.fromCircle(center: c, radius: radius),
        ),
    );

    // Craters
    final craterPaint = Paint()
      ..color = Color.lerp(_color, Colors.black, 0.35)!;
    for (final crater in _craters) {
      canvas.drawCircle(
        Offset(c.dx + crater.dx * radius, c.dy + crater.dy * radius),
        crater.r * radius,
        craterPaint,
      );
    }

    // Highlight
    canvas.drawCircle(
      Offset(radius * 0.6, radius * 0.45),
      radius * 0.28,
      Paint()..color = Colors.white.withOpacity(0.12),
    );
  }
}

class _Crater {
  final double dx, dy, r;
  _Crater({required this.dx, required this.dy, required this.r});
}
