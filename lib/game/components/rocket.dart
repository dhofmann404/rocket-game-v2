import 'dart:async' as async;
import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../rocket_game.dart';
import 'bullet.dart';

class Rocket extends PositionComponent
    with HasGameRef<RocketGame>, CollisionCallbacks {
  static const double tiltSensitivity = 55.0;
  static const double shootInterval = 0.38;

  double _tilt = 0.0;
  double _shootTimer = 0;
  double _flameTimer = 0;
  bool _destroyed = false;

  async.StreamSubscription<AccelerometerEvent>? _accelSub;
  final Random _random = Random();

  Rocket({required Vector2 position})
      : super(
          position: position,
          anchor: Anchor.center,
          size: Vector2(44, 64),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox(
      size: Vector2(28, 52),
      anchor: Anchor.center,
      position: size / 2,
    ));
    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SamplingPeriod.game,
      ).listen((event) {
        // Invert x: tilting right = positive event.x → move right
        _tilt = -event.x;
      });
    } catch (_) {
      // No accelerometer (emulator/desktop) — rocket stays centered
    }
  }

  @override
  void onRemove() {
    _accelSub?.cancel();
    super.onRemove();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_destroyed) return;

    _flameTimer += dt;

    // Move left/right
    position.x += _tilt * tiltSensitivity * dt;
    position.x = position.x.clamp(size.x / 2, gameRef.size.x - size.x / 2);

    // Auto-shoot
    _shootTimer += dt;
    if (_shootTimer >= shootInterval) {
      _shootTimer = 0;
      _shoot();
    }
  }

  void _shoot() {
    gameRef.add(Bullet(
      position: Vector2(position.x, position.y - size.y / 2 + 4),
    ));
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // --- Engine flame (animated flicker) ---
    final flameHeight = 14.0 + sin(_flameTimer * 18) * 4;
    final flamePaint = Paint()..color = const Color(0xCCFF6600);
    final innerFlamePaint = Paint()..color = const Color(0xEEFFD700);

    final outerFlame = Path()
      ..moveTo(w * 0.28, h * 0.78)
      ..lineTo(w * 0.5, h * 0.78 + flameHeight)
      ..lineTo(w * 0.72, h * 0.78)
      ..close();
    canvas.drawPath(outerFlame, flamePaint);

    final innerFlame = Path()
      ..moveTo(w * 0.36, h * 0.78)
      ..lineTo(w * 0.5, h * 0.78 + flameHeight * 0.65)
      ..lineTo(w * 0.64, h * 0.78)
      ..close();
    canvas.drawPath(innerFlame, innerFlamePaint);

    // --- Left fin ---
    final finPaint = Paint()..color = const Color(0xFF37474F);
    final leftFin = Path()
      ..moveTo(w * 0.12, h * 0.52)
      ..lineTo(0, h * 0.78)
      ..lineTo(w * 0.28, h * 0.76)
      ..close();
    canvas.drawPath(leftFin, finPaint);

    // --- Right fin ---
    final rightFin = Path()
      ..moveTo(w * 0.88, h * 0.52)
      ..lineTo(w, h * 0.78)
      ..lineTo(w * 0.72, h * 0.76)
      ..close();
    canvas.drawPath(rightFin, finPaint);

    // --- Rocket body ---
    final bodyPaint = Paint()..color = const Color(0xFF546E7A);
    final body = Path()
      ..moveTo(w * 0.5, 0) // nose tip
      ..lineTo(w * 0.08, h * 0.76)
      ..lineTo(w * 0.92, h * 0.76)
      ..close();
    canvas.drawPath(body, bodyPaint);

    // Body shading (right side darker)
    final shadePaint = Paint()
      ..shader = LinearGradient(
        colors: [Colors.white.withOpacity(0.08), Colors.black.withOpacity(0.2)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(body, shadePaint);

    // --- Cockpit window ---
    final windowPaint = Paint()..color = const Color(0xFF29B6F6);
    canvas.drawCircle(Offset(w * 0.5, h * 0.32), w * 0.13, windowPaint);
    canvas.drawCircle(
      Offset(w * 0.44, h * 0.29),
      w * 0.05,
      Paint()..color = Colors.white.withOpacity(0.5),
    );

    // --- Engine nozzle ---
    final nozzlePaint = Paint()..color = const Color(0xFF263238);
    final nozzle = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.28, h * 0.74, w * 0.44, h * 0.07),
      const Radius.circular(3),
    );
    canvas.drawRRect(nozzle, nozzlePaint);
  }
}
