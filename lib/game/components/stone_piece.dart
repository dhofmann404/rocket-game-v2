import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;

class StonePiece extends Component with HasGameRef {
  Vector2 position;
  Vector2 velocity;
  double angle;
  double angularVelocity;
  final double scale;
  final List<Offset> shape;
  final Color color;

  static final List<StonePiece> all = [];

  double _age = 0;
  static const double _lifetime = 3.2;
  static const double _gravity = 260.0;
  static const double _airResistance = 0.22;

  StonePiece({
    required this.position,
    required this.velocity,
    required this.scale,
    required this.shape,
    required this.color,
    this.angle = 0,
    this.angularVelocity = 0,
  }) {
    all.add(this);
  }

  @override
  void onRemove() {
    all.remove(this);
    super.onRemove();
  }

  @override
  void update(double dt) {
    _age += dt;
    if (_age >= _lifetime) {
      removeFromParent();
      return;
    }

    // Gravity
    velocity.y += _gravity * dt;

    // Air resistance
    velocity.x *= (1 - _airResistance * dt);

    // Collision against ALL active stone pieces
    for (final other in all) {
      if (other == this) continue;
      final diff = position - other.position;
      final dist = diff.length;
      final minDist = (scale + other.scale) * 1.8;
      if (dist < minDist && dist > 0.5) {
        final normal = diff.normalized();
        final overlap = minDist - dist;

        position += normal * overlap * 0.5;
        other.position -= normal * overlap * 0.5;

        final relVel = velocity - other.velocity;
        final velAlongNormal = relVel.dot(normal);
        if (velAlongNormal < 0) {
          const restitution = 0.25;
          final impulse = normal * (-(1 + restitution) * velAlongNormal * 0.5);
          velocity += impulse;
          other.velocity -= impulse;
        }
      }
    }

    position += velocity * dt;
    angle += angularVelocity * dt;
    angularVelocity *= (1 - dt * 1.8);

    // Bounce off screen bottom
    final bottom = gameRef.size.y - 10;
    if (position.y > bottom) {
      position.y = bottom;
      velocity.y *= -0.35;
      velocity.x *= 0.65;
      angularVelocity *= -0.5;
    }

    // Remove if off screen sides
    if (position.x < -scale * 2 || position.x > gameRef.size.x + scale * 2) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    if (shape.isEmpty) return;

    final progress = _age / _lifetime;
    final opacity = (1.0 - progress * 0.75).clamp(0.0, 1.0);

    canvas.save();
    canvas.translate(position.x, position.y);
    canvas.rotate(angle);

    final path = Path();
    path.moveTo(shape[0].dx * scale, shape[0].dy * scale);
    for (int i = 1; i < shape.length; i++) {
      path.lineTo(shape[i].dx * scale, shape[i].dy * scale);
    }
    path.close();

    final bounds =
        Rect.fromCenter(center: Offset.zero, width: scale * 2, height: scale * 2);

    // Base fill
    canvas.drawPath(path, Paint()..color = color.withOpacity(opacity));

    // Top-left highlight
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.18 * opacity),
            Colors.transparent,
          ],
        ).createShader(bounds),
    );

    // Bottom-right shadow
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.35 * opacity),
          ],
        ).createShader(bounds),
    );

    // Outline
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withOpacity(0.55 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.restore();
  }
}
