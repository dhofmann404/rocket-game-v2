import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class MeteoriteChunk extends PositionComponent {
  static const double gravity = 160.0;
  static const double lifetime = 1.4;

  final Vector2 velocity;
  final double radius;
  final Color color;
  double _age = 0;

  MeteoriteChunk({
    required Vector2 position,
    required this.velocity,
    required this.radius,
    required this.color,
  }) : super(
          position: position,
          anchor: Anchor.center,
          size: Vector2.all(radius * 2),
        );

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= lifetime) {
      removeFromParent();
      return;
    }
    velocity.y += gravity * dt;
    position += velocity * dt;
  }

  @override
  void render(Canvas canvas) {
    final opacity = (1.0 - _age / lifetime).clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      radius,
      Paint()..color = color.withOpacity(opacity),
    );
    // Highlight
    canvas.drawCircle(
      Offset(size.x * 0.35, size.y * 0.35),
      radius * 0.25,
      Paint()..color = Colors.white.withOpacity(opacity * 0.3),
    );
  }
}
