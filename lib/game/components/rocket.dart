import 'dart:async' as async;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../rocket_game.dart';

class Rocket extends PositionComponent
    with HasGameRef<RocketGame>, CollisionCallbacks {
  static const double tiltSensitivity = 130.0;
  static const double _restY = 0.0; // set in onLoad relative to screen

  double _tilt = 0.0;
  double _time = 0;
  bool _exploded = false;

  // Y-axis physics (push-down / recoil)
  double _yVelocity = 0;
  double _baseY = 0;

  // X-axis impact shake
  double _xVelocity = 0;

  async.StreamSubscription<AccelerometerEvent>? _accelSub;

  Rocket({required Vector2 position})
      : super(
          position: position,
          anchor: Anchor.center,
          size: Vector2(44, 64),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _baseY = position.y;
    add(RectangleHitbox(
      size: Vector2(28, 52),
      anchor: Anchor.center,
      position: size / 2,
    ));
    try {
      _accelSub = accelerometerEventStream().listen((event) {
        _tilt = -event.x;
      });
    } catch (_) {}
  }

  @override
  void onRemove() {
    _accelSub?.cancel();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_exploded) return;
    _time += dt;

    // Left/right tilt
    position.x += (_tilt * tiltSensitivity + _xVelocity) * dt;
    position.x = position.x.clamp(size.x / 2, gameRef.size.x - size.x / 2);
    _xVelocity *= (1 - dt * 6);

    // Y spring physics: always pulls rocket back to base Y
    final distFromBase = position.y - _baseY;
    _yVelocity -= distFromBase * 18; // spring force toward base
    _yVelocity *= (1 - dt * 5.5);   // damping
    _yVelocity = _yVelocity.clamp(-900, 900);
    position.y += _yVelocity * dt;

    // Clamp Y range
    position.y = position.y.clamp(size.y / 2, gameRef.size.y + size.y * 2);

    // Game over: rocket pushed off bottom
    if (position.y > gameRef.size.y + size.y * 0.5) {
      _exploded = true;
      gameRef.triggerGameOver();
    }
  }

  /// Called by Meteorite on collision
  void applyImpact({required bool upward, required double strength}) {
    if (upward) {
      // Fast hit: rocket recoils upward briefly (satisfying kick)
      _yVelocity = -strength * 3.5;
    } else {
      // Slow hit: rocket gets pushed DOWN hard
      _yVelocity = strength * 4.5;
    }
    // Slight random X shake
    _xVelocity = (_tilt >= 0 ? -1 : 1) * strength * 0.5;
  }

  void applyTapImpulse(double direction) {
    if (_exploded) return;
    _xVelocity += direction * 400.0;
  }

  void triggerExplosion() {
    _exploded = true;
  }

  @override
  void render(Canvas canvas) {
    if (_exploded) return;

    final w = size.x;
    final h = size.y;

    final speedFactor = ((gameRef.speed - 80) / 420).clamp(0.0, 1.0);
    final flicker = 0.92 + 0.08 * ((_time * 22).remainder(1.0) > 0.5 ? 1 : -1);
    final flameH = (16.0 + speedFactor * 55.0) * flicker;

    // Outer flame
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.18, h * 0.78)
        ..lineTo(w * 0.5, h * 0.78 + flameH)
        ..lineTo(w * 0.82, h * 0.78)
        ..close(),
      Paint()..color = const Color(0xCCFF5500),
    );

    // Inner flame (yellow)
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.30, h * 0.78)
        ..lineTo(w * 0.5, h * 0.78 + flameH * 0.70)
        ..lineTo(w * 0.70, h * 0.78)
        ..close(),
      Paint()..color = const Color(0xEEFFD000),
    );

    // White hot core at high speed
    if (speedFactor > 0.1) {
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.40, h * 0.78)
          ..lineTo(w * 0.5, h * 0.78 + flameH * 0.40)
          ..lineTo(w * 0.60, h * 0.78)
          ..close(),
        Paint()..color = Colors.white.withOpacity(0.9 * speedFactor),
      );
    }

    // Fins
    final finPaint = Paint()..color = const Color(0xFF8B0000);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.12, h * 0.52)
        ..lineTo(0, h * 0.78)
        ..lineTo(w * 0.28, h * 0.76)
        ..close(),
      finPaint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.88, h * 0.52)
        ..lineTo(w, h * 0.78)
        ..lineTo(w * 0.72, h * 0.76)
        ..close(),
      finPaint,
    );

    // Body
    final body = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.08, h * 0.76)
      ..lineTo(w * 0.92, h * 0.76)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFFE53935));
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.08),
            Colors.black.withOpacity(0.2)
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Cockpit
    canvas.drawCircle(
        Offset(w * 0.5, h * 0.32), w * 0.13, Paint()..color = const Color(0xFFFF8A80));
    canvas.drawCircle(Offset(w * 0.44, h * 0.29), w * 0.05,
        Paint()..color = Colors.white.withOpacity(0.5));

    // Nozzle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.28, h * 0.74, w * 0.44, h * 0.13),
          const Radius.circular(3)),
      Paint()..color = const Color(0xFF4A0000),
    );
  }
}
