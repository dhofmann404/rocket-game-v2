import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
import '../rocket_game.dart';
import 'rocket.dart';
import 'stone_piece.dart';
import 'stone_shapes.dart';

class Meteorite extends PositionComponent
    with HasGameRef<RocketGame>, CollisionCallbacks {
  final double radius;
  final double fallSpeed;

  // Minimum rocket speed to destroy this rock
  double get minDestroySpeed => radius * 7.0;

  bool _destroyed = false;
  final Random _rng = Random();
  late final List<_StoneCell> _cells;

  static final List<Meteorite> active = [];

  Meteorite({
    required Vector2 position,
    required this.radius,
    required this.fallSpeed,
  }) : super(
          position: position,
          anchor: Anchor.center,
          size: Vector2.all(radius * 2),
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _cells = _generateCells();
    add(CircleHitbox(radius: radius));
    active.add(this);
  }

  @override
  void onRemove() {
    active.remove(this);
    super.onRemove();
  }

  List<_StoneCell> _generateCells() {
    final cells = <_StoneCell>[];
    final count = 4 + _rng.nextInt(3); // 4–6 pieces
    final cellScale = radius * 0.48;

    // Colors: earthy rock tones with slight variation per cell
    final baseHue = 20.0 + _rng.nextDouble() * 30; // brown-grey range
    final baseSat = 0.15 + _rng.nextDouble() * 0.2;
    final baseLum = 0.30 + _rng.nextDouble() * 0.15;
    Color baseColor = HSLColor.fromAHSL(1, baseHue, baseSat, baseLum).toColor();

    // Center piece
    cells.add(_StoneCell(
      shapeIndex: _rng.nextInt(kStoneShapes.length),
      localOffset: Offset.zero,
      scale: cellScale,
      rotation: _rng.nextDouble() * pi * 2,
      color: baseColor,
    ));

    // Surrounding pieces
    for (int i = 1; i < count; i++) {
      final angle = (i / (count - 1)) * pi * 2 + _rng.nextDouble() * 0.8;
      final dist = radius * (0.28 + _rng.nextDouble() * 0.32);
      final lumVar = baseLum + (_rng.nextDouble() - 0.5) * 0.12;
      cells.add(_StoneCell(
        shapeIndex: _rng.nextInt(kStoneShapes.length),
        localOffset: Offset(cos(angle) * dist, sin(angle) * dist),
        scale: cellScale * (0.7 + _rng.nextDouble() * 0.5),
        rotation: _rng.nextDouble() * pi * 2,
        color: HSLColor.fromAHSL(1, baseHue, baseSat, lumVar.clamp(0.2, 0.6)).toColor(),
      ));
    }
    return cells;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_destroyed) return;
    position.y += fallSpeed * dt;
    if (position.y > gameRef.size.y + radius) {
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

    if (other is Rocket) {
      _destroyed = true;
      final rocketSpeed = gameRef.speed;

      if (rocketSpeed >= minDestroySpeed) {
        // Fast enough: rock shatters, rocket gets slight upward kick
        gameRef.addScore((radius / 5).round() * 10);
        _explode(rocketSpeed, destroyed: true);
        other.applyImpact(upward: true, strength: radius * 0.8);
        // Small speed penalty
        gameRef.applySpeedPenalty(radius * 0.05);
      } else {
        // Too slow: pieces scatter weakly, rocket gets pushed DOWN
        _explode(rocketSpeed, destroyed: false);
        other.applyImpact(upward: false, strength: radius * 3.5 + 60);
        gameRef.applySpeedPenalty(radius * 0.2);
      }
      removeFromParent();
    }
  }

  void chainExplode() {
    if (_destroyed) return;
    _destroyed = true;
    _explode(80.0, destroyed: true);
    gameRef.addScore((radius / 5).round() * 5);
    removeFromParent();
  }

  void _explode(double rocketSpeed, {required bool destroyed}) {
    final explosionForce = destroyed
        ? (35.0 + rocketSpeed * 0.12)
        : (15.0 + rocketSpeed * 0.05);

    for (final cell in _cells) {
      final worldPos = Vector2(
        position.x + cell.localOffset.dx,
        position.y + cell.localOffset.dy,
      );

      Vector2 baseDir;
      if (cell.localOffset.dx.abs() < 1 && cell.localOffset.dy.abs() < 1) {
        final a = _rng.nextDouble() * pi * 2;
        baseDir = Vector2(cos(a), sin(a));
      } else {
        baseDir = Vector2(cell.localOffset.dx, cell.localOffset.dy).normalized();
      }

      final spread = (_rng.nextDouble() - 0.5) * pi * 0.35;
      final dir = Vector2(
        baseDir.x * cos(spread) - baseDir.y * sin(spread),
        baseDir.x * sin(spread) + baseDir.y * cos(spread),
      );

      final speed = explosionForce * (0.7 + _rng.nextDouble() * 0.6);
      final upBias = destroyed ? -50.0 : 20.0;

      gameRef.add(StonePiece(
        position: worldPos,
        velocity: Vector2(dir.x * speed, dir.y * speed + upBias),
        scale: cell.scale,
        shape: kStoneShapes[cell.shapeIndex],
        color: cell.color,
        angle: cell.rotation,
        angularVelocity: (_rng.nextDouble() - 0.5) * 8,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    // Danger tint: red glow when rocket too slow for this rock
    final minSpd = minDestroySpeed;
    final danger = gameRef.speed < minSpd
        ? ((minSpd - gameRef.speed) / minSpd).clamp(0.0, 0.7)
        : 0.0;

    canvas.save();
    canvas.translate(radius, radius); // center of component

    for (final cell in _cells) {
      canvas.save();
      canvas.translate(cell.localOffset.dx, cell.localOffset.dy);
      canvas.rotate(cell.rotation);

      final shape = kStoneShapes[cell.shapeIndex];
      final s = cell.scale;
      final bounds =
          Rect.fromCenter(center: Offset.zero, width: s * 2, height: s * 2);

      final path = Path();
      path.moveTo(shape[0].dx * s, shape[0].dy * s);
      for (int i = 1; i < shape.length; i++) {
        path.lineTo(shape[i].dx * s, shape[i].dy * s);
      }
      path.close();

      // Base color
      canvas.drawPath(path, Paint()..color = cell.color);

      // Highlight
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withOpacity(0.15), Colors.transparent],
          ).createShader(bounds),
      );

      // Shadow
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
          ).createShader(bounds),
      );

      // Danger tint
      if (danger > 0) {
        canvas.drawPath(
          path,
          Paint()..color = Colors.red.withOpacity(danger * 0.45),
        );
      }

      // Outline
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.black.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      canvas.restore();
    }

    canvas.restore();
  }
}

class _StoneCell {
  final int shapeIndex;
  final Offset localOffset;
  final double scale;
  final double rotation;
  final Color color;

  const _StoneCell({
    required this.shapeIndex,
    required this.localOffset,
    required this.scale,
    required this.rotation,
    required this.color,
  });
}
