import 'dart:math' as math;

import 'package:vector_math/vector_math.dart';
import 'package:test/test.dart';

import 'package:webgltest/octree.dart';

class Thingy {
  final List _observers;
  Aabb3 _box;
  Aabb3 get box => _box;
  Thingy(this._box) : _observers = [];
  unregisterObserver(observer) => _observers.remove(observer);
  registerObserver(observer) => _observers.add(observer);
  _notifyObservers() => _observers.forEach((o) => o.notify(this));
  /// Changes the bounding box.
  /// Subsequently notifies any subscribers.
  changeBoundingBox(Aabb3 newBoundingBox) {
    _box = newBoundingBox;
    _notifyObservers();
  }
  String toString() {
    return _box.center.toString();
  }
}

populateWithRandomlyPositionedThingies(Octree octree, int n, double size) {
  var rand = new math.Random(123);

  var randPos = () => rand.nextDouble() * size - size / 2;

  // fill the octree with lots of thingies
  for (int i = 0; i < n; i++) {
    var center = new Vector3(randPos(), randPos(), randPos());

    var newThingy = new Thingy(new Aabb3.centerAndHalfExtents(
            center,
            new Vector3(0.5, 0.5, 0.5)));

    octree.insert(newThingy);
  }
}

main() {
  test("creating an octree and inserting some objects", () {
    var thingy1 = new Thingy(new Aabb3.centerAndHalfExtents(
            new Vector3(15.0, 15.0, 15.0),
            new Vector3(0.5, 0.5, 0.5)));

    double size = 32.0;

    var aabb = new Aabb3.centerAndHalfExtents(new Vector3.zero(),
        new Vector3(size / 2, size / 2, size / 2));

    var octree = new Octree(aabb);
    octree.insert(thingy1);

    var box = new Aabb3.centerAndHalfExtents(
        new Vector3(15.0, 15.0, 15.0),
        new Vector3(1.0, 1.0, 1.0));
        
    var results = new List.from(octree.getObjectsIntersectingWithAabb3(box));

    expect(results.length, equals(1));
  });

  test("inserting a lot of overlapping objects", () {
    double size = 32.0;

    var aabb = new Aabb3.centerAndHalfExtents(new Vector3.zero(),
        new Vector3(size / 2, size / 2, size / 2));

    var octree = new Octree(aabb);

    List thingies = [];

    for (int i = 0; i < 100; i++) {
      var newThingy = new Thingy(new Aabb3.centerAndHalfExtents(
              new Vector3(15.0, 15.0, 15.0),
              new Vector3(0.5, 0.5, 0.5)));

      thingies.add(newThingy);
      octree.insert(newThingy);
    }

    var box = new Aabb3.centerAndHalfExtents(
        new Vector3(15.0, 15.0, 15.0),
        new Vector3(1.0, 1.0, 1.0));
        
    var results = new List.from(octree.getObjectsIntersectingWithAabb3(box));

    expect(results.length, equals(thingies.length));
  });

  test("retrieving in element at the center of the tree", () {
    double size = 32.0;
    var aabb = new Aabb3.centerAndHalfExtents(new Vector3.zero(),
        new Vector3(size / 2, size / 2, size / 2));

    var octree = new Octree(aabb);
    
    List thingies = [];

    for (int i = 0; i < 100; i++) {
      var newThingy = new Thingy(new Aabb3.centerAndHalfExtents(
              new Vector3(15.0, 15.0, 15.0),
              new Vector3(0.5, 0.5, 0.5)));

      thingies.add(newThingy);
      octree.insert(newThingy);
    }

    octree.insert(new Thingy(new Aabb3.centerAndHalfExtents(
                new Vector3(0.0, 0.0, 0.0),
                new Vector3(0.5, 0.5, 0.5))));

    var box = new Aabb3.centerAndHalfExtents(
        new Vector3(0.0, 0.0, 0.0),
        new Vector3(1.0, 1.0, 1.0));
        
    var results = new List.from(octree.getObjectsIntersectingWithAabb3(box));

    expect(results.length, equals(1));    
  });

  test("updates itself when an object moves", () {
    double size = 64.0;
    var aabb = new Aabb3.centerAndHalfExtents(new Vector3.zero(),
        new Vector3(size / 2, size / 2, size / 2));

    var octree = new Octree(aabb);

    populateWithRandomlyPositionedThingies(octree, 1000, size);

    var thingyBox = new Aabb3.centerAndHalfExtents(new Vector3(10.0, 10.0, 10.0),
        new Vector3(0.5, 0.5, 0.5));
    var thingy = new Thingy(thingyBox);

    octree.insert(thingy);

    populateWithRandomlyPositionedThingies(octree, 1000, size);

    thingy.changeBoundingBox(new Aabb3.centerAndHalfExtents(
            new Vector3(-10.0, -10.0, -10.0),
            new Vector3(0.5, 0.5, 0.5)));

    List results = new List.from(
        octree.getObjectsIntersectingWithAabb3(
            new Aabb3.centerAndHalfExtents(new Vector3(-10.0, -10.0, -10.0),
                new Vector3(1.0, 1.0, 1.0))));

    expect(results, contains(thingy));
  });

  test("moving around a lot of objects", () {
    double size = 64.0;
    var aabb = new Aabb3.centerAndHalfExtents(new Vector3.zero(),
        new Vector3(size / 2, size / 2, size / 2));

    var octree = new Octree(aabb);

    List thingies = [];

    for (int i = 0; i < 10000; i++) {
      var thingyBox = new Aabb3.centerAndHalfExtents(new Vector3(10.0, 10.0, 10.0),
          new Vector3(0.5, 0.5, 0.5));
      var thingy = new Thingy(thingyBox);
      octree.insert(thingy);
      thingies.add(thingy);
    }

    thingies.forEach((thingy) => 
      thingy.changeBoundingBox(new Aabb3.centerAndHalfExtents(
              new Vector3(-10.0, -10.0, -10.0),
              new Vector3(0.5, 0.5, 0.5))));

    List results = new List.from(
        octree.getObjectsIntersectingWithAabb3(
            new Aabb3.centerAndHalfExtents(new Vector3(-10.0, -10.0, -10.0),
                new Vector3(1.0, 1.0, 1.0))));

    expect(results.length, equals(10000));
  });
}
