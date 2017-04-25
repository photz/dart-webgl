class Heap {
  final List _elements;

  var _compare;
  
  Heap()
    : _elements = new List();

  Heap.fromList(this._elements, );

  void insert(x) {
    _elements.add(x);
    int indexNewEl = _elements.length - 1;
    while (0 < indexNewEl) {
      int parentIndex = _parent(indexNewEl);
      if (_elements[indexNewEl] < _elements[parentIndex]) {
        var newEl = _elements[indexNewEl];
        _elements[indexNewEl] = _elements[parentIndex];
        _elements[parentIndex] = newEl;
        indexNewEl = parentIndex;
      }
      else {
        break;
      }
    }
  }

  pop() {
    var returnEl = _elements.first;

    var lastEl = _elements.removeAt(_elements.length - 1);

    _elements[0] = lastEl;

    int currentIndex = 0;

    while (_hasLeftChild(currentIndex)) {

      int leftChildIndex = _leftChild(currentIndex);
      //int rightChildIndex = _rightChild(currentIndex);

      var leftChild = _elements[leftChildIndex];

      if (leftChild < lastEl) {
        _elements[leftChildIndex] = lastEl;
        _elements[currentIndex] = leftChild;
        currentIndex = leftChildIndex;
      }
      else {
        break;
      }
    }    

    return returnEl;
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