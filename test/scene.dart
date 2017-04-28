import "package:test/test.dart";
import 'package:webgltest/scene.dart';
import 'dart:collection';
import 'dart:developer' as developer;

main() {

  test("finding a path", () {
    Scene scene = new Scene();
    List<Point> path = scene.findPath(new Point(0, 0), new Point(2, 1));
    expect(path.length, equals(3));
  });

  test("finding another path", () {
    Scene scene = new Scene();
    List<Point> path = scene.findPath(new Point(0, 0), new Point(-400, -400));
    expect(path.length, equals(800));
  });

}