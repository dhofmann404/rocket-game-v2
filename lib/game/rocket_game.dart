import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'components/rocket.dart';
import 'components/meteorite.dart';
import 'components/star_field.dart';
import 'components/hud.dart';

class RocketGame extends FlameGame with HasCollisionDetection {
  static const double initialSpeed = 80.0;
  static const double speedIncreaseRate = 55.0;
  static const double initialSpawnInterval = 2.5;

  late Rocket rocket;
  late HudComponent hud;

  double speed = initialSpeed;
  int score = 0;
  int highscore = 0;
  bool isGameOver = false;

  double _spawnTimer = 0;
  final Random _random = Random();

  @override
  Color backgroundColor() => const Color(0xFF000015);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(StarField(count: 80));
    rocket = Rocket(position: Vector2(size.x / 2, size.y * 0.88));
    add(rocket);
    hud = HudComponent();
    add(hud);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    speed += speedIncreaseRate * dt;

    final spawnInterval =
        (initialSpawnInterval * (initialSpeed / speed)).clamp(0.4, initialSpawnInterval);
    _spawnTimer += dt;
    if (_spawnTimer >= spawnInterval) {
      _spawnTimer = 0;
      _spawnMeteorite();
    }

    hud.updateSpeed(speed);
  }

  void _spawnMeteorite() {
    final radius = 16.0 + _random.nextDouble() * 30;
    final x = radius + _random.nextDouble() * (size.x - radius * 2);
    final fallSpeed = 27.0 + _random.nextDouble() * 20 + speed * 0.1;
    add(Meteorite(
      position: Vector2(x, -radius),
      radius: radius,
      fallSpeed: fallSpeed,
    ));
  }

  void addScore(int points) {
    score += points;
    if (score > highscore) highscore = score;
    hud.updateScore(score, highscore);
  }

  void applySpeedPenalty(double amount) {
    speed = (speed - amount).clamp(initialSpeed * 0.4, double.infinity);
  }

  void triggerGameOver() {
    if (isGameOver) return;
    isGameOver = true;
    if (score > highscore) highscore = score;
    overlays.add('GameOver');
  }

  void resetGame() {
    score = 0;
    speed = initialSpeed;
    _spawnTimer = 0;
    isGameOver = false;

    children.whereType<Meteorite>().toList().forEach((m) => m.removeFromParent());

    // Reset rocket position
    rocket.position = Vector2(size.x / 2, size.y * 0.88);

    hud.updateScore(0, highscore);
    hud.updateSpeed(initialSpeed);
  }
}
