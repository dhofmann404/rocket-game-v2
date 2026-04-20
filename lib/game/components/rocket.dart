import 'dart:async' as async;
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../rocket_game.dart';

class Rocket extends PositionComponent
    with HasGameRef<RocketGame>, CollisionCallbacks {
  static const double tiltSensitivity = 130.0;

  double _tilt = 0.0;
  double _time = 0;
  bool _exploded = false;
  bool _tapMode = false;

  double _yVelocity = 0;
  double _baseY = 0;
  double _xVelocity = 0;

  async.StreamSubscription<AccelerometerEvent>? _accelSub;

  Rocket({required Vector2 position})
      : super(
          position: position,
          anchor: Anchor.center,
          size: Vector2(60, 54),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _baseY = position.y;
    add(RectangleHitbox(
      size: Vector2(48, 42),
      anchor: Anchor.center,
      position: size / 2,
    ));
    if (!kIsWeb) {
      try {
        _accelSub = accelerometerEventStream().listen((event) {
          _tilt = -event.x;
        });
      } catch (_) {}
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
    if (_exploded) return;
    _time += dt;

    position.x += ((_tapMode ? 0.0 : _tilt * tiltSensitivity) + _xVelocity) * dt;
    position.x = position.x.clamp(size.x / 2, gameRef.size.x - size.x / 2);
    _xVelocity *= (1 - dt * 6);

    final distFromBase = position.y - _baseY;
    _yVelocity -= distFromBase * 18;
    _yVelocity *= (1 - dt * 5.5);
    _yVelocity = _yVelocity.clamp(-900, 900);
    position.y += _yVelocity * dt;

    position.y = position.y.clamp(size.y / 2, gameRef.size.y + size.y * 2);

    if (position.y > gameRef.size.y + size.y * 0.5) {
      _exploded = true;
      gameRef.triggerGameOver();
    }
  }

  void applyImpact({required bool upward, required double strength}) {
    if (upward) {
      _yVelocity = -strength * 3.5;
    } else {
      _yVelocity = strength * 4.5;
    }
    _xVelocity = (_tilt >= 0 ? -1 : 1) * strength * 0.5;
  }

  void applyTapImpulse(double direction) {
    if (_exploded) return;
    _tapMode = true;
    _tilt = 0.0;
    _xVelocity += direction * 400.0;
  }

  void resetTapMode() {
    _tapMode = false;
  }

  void triggerExplosion() {
    _exploded = true;
  }

  @override
  void render(Canvas canvas) {
    if (_exploded) return;

    final w = size.x;
    final h = size.y;
    final rect = Rect.fromLTWH(0, 0, w, h);

    final speedFactor = ((gameRef.speed - 80) / 420).clamp(0.0, 1.0);
    final flicker = 0.92 + 0.08 * ((_time * 22).remainder(1.0) > 0.5 ? 1 : -1);
    final flameH = (14.0 + speedFactor * 48.0) * flicker;

    // ── Dual engine flames ──────────────────────────────────────────────
    // Left engine — outer blue cone
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.18, h * 0.84)
        ..lineTo(w * 0.27, h * 0.84 + flameH)
        ..lineTo(w * 0.36, h * 0.84)
        ..close(),
      Paint()..color = const Color(0xCC0077FF),
    );
    // Left engine — inner cyan core
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.21, h * 0.84)
        ..lineTo(w * 0.27, h * 0.84 + flameH * 0.55)
        ..lineTo(w * 0.33, h * 0.84)
        ..close(),
      Paint()..color = const Color(0xEE88DDFF),
    );
    // Right engine — outer blue cone
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.64, h * 0.84)
        ..lineTo(w * 0.73, h * 0.84 + flameH)
        ..lineTo(w * 0.82, h * 0.84)
        ..close(),
      Paint()..color = const Color(0xCC0077FF),
    );
    // Right engine — inner cyan core
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.67, h * 0.84)
        ..lineTo(w * 0.73, h * 0.84 + flameH * 0.55)
        ..lineTo(w * 0.79, h * 0.84)
        ..close(),
      Paint()..color = const Color(0xEE88DDFF),
    );
    // White-hot cores at high speed
    if (speedFactor > 0.15) {
      final corePaint = Paint()..color = Colors.white.withOpacity(0.85 * speedFactor);
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.24, h * 0.84)
          ..lineTo(w * 0.27, h * 0.84 + flameH * 0.30)
          ..lineTo(w * 0.30, h * 0.84)
          ..close(),
        corePaint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(w * 0.70, h * 0.84)
          ..lineTo(w * 0.73, h * 0.84 + flameH * 0.30)
          ..lineTo(w * 0.76, h * 0.84)
          ..close(),
        corePaint,
      );
    }

    // ── Swept wings ─────────────────────────────────────────────────────
    final wingColor = const Color(0xFF546E7A);
    // Left wing
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.14, h * 0.36)
        ..lineTo(0, h * 0.80)
        ..lineTo(w * 0.22, h * 0.78)
        ..lineTo(w * 0.24, h * 0.32)
        ..close(),
      Paint()..color = wingColor,
    );
    // Right wing
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.86, h * 0.36)
        ..lineTo(w, h * 0.80)
        ..lineTo(w * 0.78, h * 0.78)
        ..lineTo(w * 0.76, h * 0.32)
        ..close(),
      Paint()..color = wingColor,
    );
    // Wing orange tip accent — left
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.02, h * 0.72)
        ..lineTo(0, h * 0.80)
        ..lineTo(w * 0.22, h * 0.78)
        ..lineTo(w * 0.20, h * 0.72)
        ..close(),
      Paint()..color = const Color(0xFFFF8F00),
    );
    // Wing orange tip accent — right
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.98, h * 0.72)
        ..lineTo(w, h * 0.80)
        ..lineTo(w * 0.78, h * 0.78)
        ..lineTo(w * 0.80, h * 0.72)
        ..close(),
      Paint()..color = const Color(0xFFFF8F00),
    );

    // ── Main body (hexagonal fuselage) ───────────────────────────────────
    final body = Path()
      ..moveTo(w * 0.50, h * 0.02)   // nose tip
      ..lineTo(w * 0.74, h * 0.12)   // right shoulder bevel
      ..lineTo(w * 0.82, h * 0.30)   // right side
      ..lineTo(w * 0.82, h * 0.84)   // right bottom
      ..lineTo(w * 0.18, h * 0.84)   // left bottom
      ..lineTo(w * 0.18, h * 0.30)   // left side
      ..lineTo(w * 0.26, h * 0.12)   // left shoulder bevel
      ..close();

    // Body base — metallic silver
    canvas.drawPath(body, Paint()..color = const Color(0xFF78909C));
    // Metallic sheen
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.22),
            Colors.transparent,
            Colors.black.withOpacity(0.22),
          ],
          stops: const [0.0, 0.45, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );

    // ── Orange accent stripe ─────────────────────────────────────────────
    canvas.drawRect(
      Rect.fromLTWH(w * 0.18, h * 0.54, w * 0.64, h * 0.044),
      Paint()..color = const Color(0xFFFF8F00),
    );

    // ── Cockpit window ───────────────────────────────────────────────────
    final cockpitRect =
        Rect.fromLTWH(w * 0.30, h * 0.08, w * 0.40, h * 0.26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cockpitRect, const Radius.circular(5)),
      Paint()..color = const Color(0xFF0D47A1),
    );
    // Blue interior glow
    canvas.drawRRect(
      RRect.fromRectAndRadius(cockpitRect, const Radius.circular(5)),
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0x990055FF), Colors.transparent],
          center: Alignment.topLeft,
          radius: 1.3,
        ).createShader(cockpitRect),
    );
    // Cockpit glass highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, h * 0.10, w * 0.16, h * 0.10),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.white.withOpacity(0.38),
    );

    // ── Engine housings ──────────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.17, h * 0.78, w * 0.20, h * 0.08),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF1C313A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.63, h * 0.78, w * 0.20, h * 0.08),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF1C313A),
    );

    // ── Panel detail lines ───────────────────────────────────────────────
    final panelPaint = Paint()
      ..color = Colors.black.withOpacity(0.28)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(w * 0.38, h * 0.30), Offset(w * 0.38, h * 0.78), panelPaint);
    canvas.drawLine(Offset(w * 0.62, h * 0.30), Offset(w * 0.62, h * 0.78), panelPaint);
    canvas.drawLine(Offset(w * 0.18, h * 0.44), Offset(w * 0.82, h * 0.44), panelPaint);

    // ── Engine glow rings (speed effect) ────────────────────────────────
    if (speedFactor > 0.05) {
      final glowPaint = Paint()
        ..color = const Color(0xFF0088FF).withOpacity(0.35 * speedFactor)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset(w * 0.27, h * 0.84), w * 0.10, glowPaint);
      canvas.drawCircle(Offset(w * 0.73, h * 0.84), w * 0.10, glowPaint);
    }
  }
}
