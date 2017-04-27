import 'package:vector_math/vector_math.dart';

enum OctreePos {
  upperFrontLeft,
  upperFrontRight,
  upperBackLeft,
  upperBackRight,
  lowerFrontLeft,
  lowerFrontRight,
  lowerBackLeft,
  lowerBackRight,
}

class NoMatchingSubtreeError extends StateError {
  NoMatchingSubtreeError(String msg) : super(msg);
}

class Octree {
  static const int _maxObjectsPerLeaf = 16000000000000;
  final Map<OctreePos, Octree> _children;
  final Aabb3 _box;
  final Octree _parent;
  List _objects;
  bool _isLeaf = true;

  bool get _isRoot => _parent == null;

  Octree(this._box, [Octree this._parent])
    : _children = new Map(),
      _objects = [];

  Iterable getObjectsIntersectingWithAabb3(Aabb3 box) {
    if (_box.intersectsWithAabb3(box)) {
      if (_isLeaf) {
        return _objects.where((o) => box.intersectsWithAabb3(o.box));
      }
      else {
        List results = [];

        for (Octree child in _children.values) {
          var moreResults = child.getObjectsIntersectingWithAabb3(box);
          results.addAll(moreResults);
        }

        var yetMoreResults = _objects
          .where((o) => box.intersectsWithAabb3(o.box));

        results.addAll(yetMoreResults);

        return results;
      }
    }
    else {
      return [];
    }
  }

  void _updateObj(obj) {
    if (_box.containsAabb3(obj.box)) {
      
    }
  }


  void inspect([int level = 0]) {
    print('${level} - ${_objects.length} direct elements');
    if (_objects.length == 1) {
      print(_objects);
    }
    for (var child in _children.values) {
      child.inspect(level + 1);
    }
  }

  void notify(obj) {
    assert(_objects.contains(obj));
    
    if (_box.containsAabb3(obj.box)) {
      if (!_isLeaf) {
        try {
          OctreePos pos = _getPosFor(obj);
          _insertIntoSubtree(pos, obj);
          _removeFromLocalList(obj);
        } on NoMatchingSubtreeError {
          // do nothing
          // apparently the object still intersects
          // with the subspaces belonging to two or more
          // subtrees
        }
      }
    }
    else {
      
      if (_isRoot) {
        throw new StateError('apparently an object is not full contained in the subspace of the root tree node');
      }

      // relinquish this object
      // and yield to parent
      _removeFromLocalList(obj);
      _parent.acceptFromChild(obj);
    }
  }

  void acceptFromChild(obj) {
    if (_box.containsAabb3(obj.box)) {
      if (_isLeaf) {
        _addToLocalList(obj);
      }
      else {
        try {
          OctreePos pos = _getPosFor(obj);
          _insertIntoSubtree(pos, obj);
        } on NoMatchingSubtreeError {
          _addToLocalList(obj);
        }
      }
    }
    else {
      if (_isRoot) {
        throw new StateError('apparently an object is not full contained in the subspace of the root tree node');
      }

      // and yield to parent
      _parent.acceptFromChild(obj);
    }
  }

  OctreePos _getPosFor(thingy) {
    assert(OctreePos.values != null);
    for (OctreePos pos in OctreePos.values) {
      Aabb3 subtreeBox = _getBoundingBoxForSubtree(pos);
      assert(thingy.box != null);
      if (subtreeBox.containsAabb3(thingy.box)) {
        return pos;
      }
    }
    throw new NoMatchingSubtreeError('');
  }

  void _insertIntoSubtree(OctreePos pos, thingy) {
    Octree subtree = _children[pos];
    
    if (null == subtree) {
      subtree = new Octree(_getBoundingBoxForSubtree(pos), this);
      _children[pos] = subtree;
    }

    subtree.insert(thingy);
  }



  void _transformIntoNode() {
    assert(_objects != null);
    _isLeaf = false;
    List tmpObjects = _objects;
    _objects = [];
    tmpObjects.forEach((o) => o.unregisterObserver(this));
    tmpObjects.forEach((o) => insert(o));
  }

  void _removeFromLocalList(obj) {
    _objects.remove(obj);
    obj.unregisterObserver(this);
  }

  void _addToLocalList(obj) {
    _objects.add(obj);
    obj.registerObserver(this);
  }

  void insert(thingy) {
    if (_isLeaf) {
      _addToLocalList(thingy);

      if (_maxObjectsPerLeaf < _objects.length) {
        _transformIntoNode();
      }
    }
    else {
      try {
        var pos = _getPosFor(thingy);
        _insertIntoSubtree(pos, thingy);
      } on NoMatchingSubtreeError {
        _addToLocalList(thingy);
      }
    }
  }

  Aabb3 _getBoundingBoxForSubtree(OctreePos pos) {
    double size = (_box.max.z - _box.min.z).abs() / 2.0;

    Vector3 m;

    switch (pos) {
      case OctreePos.upperFrontLeft:
        m = new Vector3(size, size, size);
        break;

      case OctreePos.upperFrontRight:
        m = new Vector3(-size, size, size);
        break;
        
      case OctreePos.upperBackLeft:
        m = new Vector3(size, size, -size);
        break;
        
      case OctreePos.upperBackRight:
        m = new Vector3(-size, size, -size);
        break;

      case OctreePos.lowerFrontLeft:
        m = new Vector3(size, -size, size);
        break;

      case OctreePos.lowerFrontRight:
        m = new Vector3(-size, -size, size);
        break;
        
      case OctreePos.lowerBackLeft:
        m = new Vector3(size, -size, -size);
        break;
        
      case OctreePos.lowerBackRight:
        m = new Vector3(-size, -size, -size);
        break;

      default:
        throw StateError('invalid arg');
    }

    assert(m != null);

    Vector3 centerCopy = new Vector3.copy(_box.center);

    Aabb3 box = new Aabb3();

    centerCopy = centerCopy + m * 0.5;

    box.setCenterAndHalfExtents(centerCopy,
        new Vector3(size / 2, size / 2, size / 2));

    return box;
 }
}