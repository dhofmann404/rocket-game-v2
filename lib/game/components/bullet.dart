import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../rocket_game.dart';

class Bullet extends PositionComponent with HasGameRef<RocketGame> {
  static const double speed = 450.0;
  static const double radius = 5.0;

  Bullet({required Vector2 position})
      : super(
          position: position,
          anchor: Anchor.center,
          size: Vector2.all(radius * 2),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.y -= speed * dt;
    if (position.y < -radius) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    // Outer glow
    canvas.drawCircle(
      center,
      radius * 2.0,
      Paint()..color = const Color(0x44FFD700),
    );
    // Core
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = const Color(0xFFFFEB3B),
    );
    // Bright center
    canvas.drawCircle(
      center,
      radius * 0.5,
      Paint()..color = Colors.white,
    );
  }
}
