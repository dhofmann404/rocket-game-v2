import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class StarField extends Component with HasGameRef {
  final int count;
  final List<_Star> _stars = [];
  final Random _random = Random();

  StarField({this.count = 80});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (int i = 0; i < count; i++) {
      _stars.add(_Star(
        x: _random.nextDouble() * gameRef.size.x,
        y: _random.nextDouble() * gameRef.size.y,
        radius: 0.6 + _random.nextDouble() * 1.6,
        speed: 12 + _random.nextDouble() * 35,
        opacity: 0.25 + _random.nextDouble() * 0.75,
      ));
    }
  }

  @override
  void update(double dt) {
    for (final star in _stars) {
      star.y += star.speed * dt;
      if (star.y > gameRef.size.y + 2) {
        star.y = -2;
        star.x = _random.nextDouble() * gameRef.size.x;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    for (final star in _stars) {
      canvas.drawCircle(
        Offset(star.x, star.y),
        star.radius,
        Paint()..color = Colors.white.withOpacity(star.opacity),
      );
    }
  }
}

class _Star {
  double x, y;
  final double radius, speed, opacity;
  _Star({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
  });
}
