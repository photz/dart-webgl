import 'package:test/test.dart';
import 'package:webgltest/heap.dart';

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
}