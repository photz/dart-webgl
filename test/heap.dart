import 'package:test/test.dart';
import 'package:webgltest/heap.dart';

class Bag {
  int weight;
  Bag(this.weight);
}

main() {
  test("using the heap", () {

    var heap = new Heap();

    heap.insert(3);
    heap.insert(2);
    heap.insert(8);
    heap.insert(4);
    heap.insert(5);
    heap.insert(6);
    heap.insert(7);

    expect(heap.pop(), equals(2));
  });

  test("using the heap again", () {
    var heap = new Heap.fromList([3, 4, 5, 6, 8, 7]);

    heap.insert(2);

    expect(heap.pop(), equals(2));
  });

  test("and once more using the heap", () {
    var heap = new Heap.fromList([2, 3, 5, 4, 8, 7, 6]);

    expect(heap.pop(), equals(2));
    expect(heap.pop(), equals(3));
    expect(heap.pop(), equals(4));
  });

  test("providing a score function", () {

    var score = (bag) => bag.weight;

    var heap = new Heap.fromList([
      new Bag(2),
      new Bag(3),
      new Bag(5),
      new Bag(4),
      new Bag(8),
      new Bag(7),
      new Bag(6)
    ], score);

    expect(heap.pop().weight, equals(2));
    expect(heap.pop().weight, equals(3));
    expect(heap.pop().weight, equals(4));
  });
}