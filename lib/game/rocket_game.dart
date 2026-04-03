import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'components/rocket.dart';
import 'components/meteorite.dart';
import 'components/star_field.dart';
import 'components/hud.dart';

class RocketGame extends FlameGame with HasCollisionDetection {
  static const int maxLives = 3;
  static const double initialSpawnInterval = 2.5;

  late Rocket rocket;
  late HudComponent hud;

  int score = 0;
  int lives = maxLives;
  bool isGameOver = false;

  double _spawnTimer = 0;
  double _spawnInterval = initialSpawnInterval;
  double _difficulty = 1.0;
  final Random _random = Random();

  @override
  Color backgroundColor() => const Color(0xFF000015);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(StarField(count: 80));
    rocket = Rocket(position: Vector2(size.x / 2, size.y - 120));
    add(rocket);
    hud = HudComponent();
    add(hud);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver) return;

    _spawnTimer += dt;
    if (_spawnTimer >= _spawnInterval) {
      _spawnTimer = 0;
      _spawnMeteorite();
      _difficulty += 0.015;
      _spawnInterval =
          (initialSpawnInterval / _difficulty).clamp(0.5, initialSpawnInterval);
    }
  }

  void _spawnMeteorite() {
    final radius = 18.0 + _random.nextDouble() * 22;
    final x = radius + _random.nextDouble() * (size.x - radius * 2);
    final speed = (70.0 + _random.nextDouble() * 50) * _difficulty;
    add(Meteorite(
      position: Vector2(x, -radius),
      radius: radius,
      speed: speed,
    ));
  }

  void addScore(int points) {
    score += points;
    hud.updateScore(score);
  }

  void loseLife() {
    lives--;
    hud.updateLives(lives);
    if (lives <= 0) {
      isGameOver = true;
      overlays.add('GameOver');
    }
  }

  void resetGame() {
    score = 0;
    lives = maxLives;
    _spawnTimer = 0;
    _spawnInterval = initialSpawnInterval;
    _difficulty = 1.0;
    isGameOver = false;

    children
        .whereType<Meteorite>()
        .toList()
        .forEach((m) => m.removeFromParent());

    hud.updateScore(0);
    hud.updateLives(maxLives);
  }
}
