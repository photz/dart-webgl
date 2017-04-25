class Heap {
  final List _elements;
  var _score = (x) => x;
  
  Heap([int score(x)])
    : _elements = new List() {
    if (score != null) {
      _score = score;
    }
  }

  Heap.fromList(this._elements, [int score(x)]) {
    if (score != null) {
      _score = score;
    }
  }

  void insert(x) {
    _elements.add(x);
    int indexNewEl = _elements.length - 1;
    _bubbleUp(indexNewEl);
  }

  pop() {
    var returnEl = _elements.first;

    var lastEl = _elements.removeAt(_elements.length - 1);

    _elements[0] = lastEl;

    _sinkDown(0);

    return returnEl;
  }

  _sinkDown(int index) {
    var lastEl = _elements[index];

    int currentIndex = index;

    while (_hasLeftChild(currentIndex)) {

      int leftChildIndex = _leftChild(currentIndex);
      //int rightChildIndex = _rightChild(currentIndex);

      var leftChild = _elements[leftChildIndex];

      if (_score(leftChild) < _score(lastEl)) {
        _swap(leftChildIndex, currentIndex);
        currentIndex = leftChildIndex;
      }
      else {
        break;
      }
    }    
  }

  _bubbleUp(int index) {
    while (0 < index) {
      int parentIndex = _parent(index);
      if (_score(_elements[index]) < _score(_elements[parentIndex])) {
        var newEl = _elements[index];
        _swap(index, parentIndex);
        index = parentIndex;
      }
      else {
        break;
      }
    }
  }

  _swap(int aIndex, int bIndex) {
    var a = _elements[aIndex];
    _elements[aIndex] = _elements[bIndex];
    _elements[bIndex] = a;
  }

  bool _hasLeftChild(int parentIndex) {
    return _leftChild(parentIndex) < _elements.length;
  }

  bool _hasRightChild(int parentIndex) {
    return _rightChild(parentIndex) < _elements.length;
  }

  int _leftChild(int parentIndex) {
    int parentPos = parentIndex + 1;
    int leftChildPos = 2 * parentPos;
    int leftChildIndex = leftChildPos - 1;
    return leftChildIndex;
  }

  int _rightChild(int parentIndex) {
    assert(0 =< parentIndex);
    assert(parentIndex < _elements.length);

    int parentPos = parentIndex + 1;
    int rightChildPos = 2 * parentPos + 1;
    int rightChildIndex = rightChildPos - 1;
    return rightChildIndex;
  }

  int _parent(int childIndex) {
    int childPos = childIndex + 1;
    int parentPos = (childPos ~/ 2).floor();
    int parentIndex = parentPos - 1;
    return parentIndex;
  }
}