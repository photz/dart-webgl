import 'package:webgltest/heap.dart';


class Point {
  int x;
  int y;

  Point(this.x, this.y);

  String toString() {
    return '(${x}|${y})';
  }
}

class Record {
  Point location;
  Point cameFrom;
  int distance;
  bool explored;
  int fscore;
  Record(this.location,
      this.cameFrom, this.distance, this.explored, this.fscore);
}

class Grid {
  Map<int, Map<int, Record>> _grid;

  Grid() {
    this._grid = new Map();
  }

  void set(int x, int y, Record r) {
    var col = _grid[x];
    if (col == null) {
      col = new Map();
      _grid[x] = col;
    }
    col[y] = r;
  }

  bool containsKey(int x, int y) {
    return get(x, y) != null;
  }

  Record get(int x, int y) {
    var col = _grid[x];
    if (null == col) {
      return null;
    }
    var cell = col[y];
    return cell;
  }
}



class Scene {
  final List _objects;

  /// Creates a new scene with nothing in it.
  Scene() : _objects = new List();

  /// Adds the given object to the scene.
  void addToScene(obj) =>_objects.add(obj);


  /// Applies the given function to each object in the scene.
  void forEachObject(f) => _objects.forEach(f);

  
  /// Indicates if the field with the given coordinate is free.
  bool isFree(int x, int y) {
    return !_objects.any((o) => o.x == x && o.y == y);
  }

  /// Finds a path from the given origin to destination.
  List<Point> findPath(Point origin, Point dest) {
    Heap open = new Heap((record) => record.fscore);

    Grid grid = new Grid();

    Record originRec = new Record(origin, null, 0, false,
        _getFscore(origin, dest));

    open.insert(originRec);
    grid.set(0, 0, originRec);

    while (!open.isEmpty) {
      //open.sort((a, b) => a.distance.compareTo(b.distance));

      Record nextUp = open.pop();

      //print('now looking at ${nextUp.location.x}|${nextUp.location.y}');

      List<Point> neighbors = _getNeighbors(nextUp.location);

      for (Point neighbor in neighbors) {

        if (!isFree(neighbor.x, neighbor.y)) continue;

        Record r = grid.get(neighbor.x, neighbor.y);
        
        if (r == null) {
          r = new Record(neighbor, nextUp.location, nextUp.distance + 1, false, nextUp.distance + 1 + _getFscore(neighbor, dest));
          open.insert(r);
          grid.set(neighbor.x, neighbor.y, r);
        }
        else if (nextUp.distance + 1 < r.distance) {
          r.distance = nextUp.distance + 1;
          r.cameFrom = nextUp.location;
        }

        if (neighbor.x == dest.x && neighbor.y == dest.y) {
          return _getPath(grid, origin, dest);
        }
      }

      nextUp.explored = true;
    }

    return false;
  }

  List<Point> _getPath(Grid grid, Point origin, Point dest) {
    List<Point> path = [];

    Point current = dest;

    while (current.x != origin.x || current.y != origin.y) {
      Record r = grid.get(current.x, current.y);

      path.add(current);

      current = r.cameFrom;
    }

    return new List.from(path.reversed);
  }

  List<Point> _getNeighbors(Point p) {
    List<Point> ps = [];

    ps.add(new Point(p.x, p.y + 1));
    ps.add(new Point(p.x, p.y - 1));
    ps.add(new Point(p.x + 1, p.y));
    ps.add(new Point(p.x - 1, p.y));

    return ps;
  }

  int _getFscore(Point a, Point b) => ((a.x - a.y) + (b.x - b.y)).abs();
}
