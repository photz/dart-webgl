import 'package:vector_math/vector_math.dart';


class Projectile {

  // Distance travelled by a projectile per second
  static const double speed = 5.0;

  static const double microsecondsPerSecond = 1.0e6;

  // The actor who fired off the projectile
  final _fireman;
  
  // Vector representing the direction the projectile is flying into
  final Vector3 _forward;

  // Current position of the projectile
  Vector3 _coords;

  // Timestamp of the last update in microseconds
  int _lastUpdate;

  get fireman => _fireman;
  Vector3 get coords => _coords;
  Vector3 get forward => _forward;

  Projectile(this._fireman, coords, Vector3 forward)
    : _coords = new Vector3.copy(coords),
      _forward = forward.normalized() {

    _lastUpdate = (new DateTime.now()).microsecondsSinceEpoch;
  }

  void updatePosition() {
    int now = (new DateTime.now()).microsecondsSinceEpoch;
    int microsecondsElapsed = now - _lastUpdate;
    double distanceTravelled =
      speed * microsecondsElapsed / microsecondsPerSecond;
    _coords.addScaled(_forward, distanceTravelled);
  }
}
