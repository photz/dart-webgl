import 'package:vector_math/vector_math.dart';
import "dart:typed_data";
import "package:test/test.dart";
import '../web/model.dart';
import 'dart:io';

void main() {
//   test("Reads an object's faces", () {
//     Model m = new Model.fromObj("""
// # OBJ file created by ply_to_obj.c
// #
// g Object001

// v  0  0  0
// v  1  0  0
// v  1  1  0
// v  0  1  0
// v  0.5  0.5  1.6

// f  5  2  3
// f  4  5  3
// f  6  3  2
// f  5  6  2
// f  4  6  5
// f  6  4  3
// """);

//     expect(m.faces.length, equals(6));
//     expect(m.faces.first, equals([4, 1, 2]));
//     expect(m.faces.last, equals([5, 3, 2]));
//   });

//   test("Knows an object's vertices", () {
//     Model m = new Model.fromObj("""
// # OBJ file created by ply_to_obj.c
// #
// g Object001

// v  0  0  0
// v  1  0  0
// v  1  1  0
// v  0  1  0
// v  0.5  0.5  1.6

// f  5  2  3
// f  4  5  3
// f  6  3  2
// f  5  6  2
// f  4  6  5
// f  6  4  3
// """);

//     expect(m.vertices.length, equals(5));

//     List<double> arr = new List<double>(3);

//     m.vertices.first.copyIntoArray(arr);
//     expect(arr, equals([0.0, 0.0, 0.0]));

//     m.vertices.last.copyIntoArray(arr);
//     expect(arr, equals([0.5, 0.5, closeTo(1.6, 0.00001)]));
//   });

//   test("vertices", () {
//     Model m = new Model.fromObj("""
// # diamond.obj

// g Object001

// v 0.000000E+00 0.000000E+00 78.0000
// v 45.0000 45.0000 0.000000E+00
// v 45.0000 -45.0000 0.000000E+00
// v -45.0000 -45.0000 0.000000E+00
// v -45.0000 45.0000 0.000000E+00
// v 0.000000E+00 0.000000E+00 -78.0000

// f     1 2 3
// f     1 3 4
// f     1 4 5
// f     1 5 2
// f     6 5 4
// f     6 4 3
// f     6 3 2
// f     6 2 1
// f     6 1 5
// """);

//     List<double> arr = new List(3);

//     m.vertices.first.copyIntoArray(arr);
//     expect(arr, equals([0, 0, 78]));

//     m.vertices.last.copyIntoArray(arr);
//     expect(arr, equals([0, 0, -78]));

//     expect(m.faces.first, equals([0, 1, 2]));
//     expect(m.faces.last, equals([5, 0, 4]));
//   });

//   test("vertices as a Float32List", () {
//     Model m = new Model.fromObj("""
// # OBJ file created by ply_to_obj.c
// #
// g Object001

// v  0  -0.525731  0.850651
// v  0.850651  0  0.525731
// v  0.850651  0  -0.525731
// v  -0.850651  0  -0.525731
// v  -0.850651  0  0.525731
// v  -0.525731  0.850651  0
// v  0.525731  0.850651  0
// v  0.525731  -0.850651  0
// v  -0.525731  -0.850651  0
// v  0  -0.525731  -0.850651
// v  0  0.525731  -0.850651
// v  0  0.525731  0.850651

// f  2  3  7
// f  2  8  3
// f  4  5  6
// f  5  4  9
// f  7  6  12
// f  6  7  11
// f  10  11  3
// f  11  10  4
// f  8  9  10
// f  9  8  1
// f  12  1  2
// f  1  12  5
// f  7  3  11
// f  2  7  12
// f  4  6  11
// f  6  5  12
// f  3  8  10
// f  8  2  1
// f  4  10  9
// f  5  9  1
// """);

//     Float32List v = m.verticesAsArr();
    
//     const int numberOfVertices = 12;

//     expect(v.elementSizeInBytes, equals(4));
//     expect(v.buffer.lengthInBytes,
//         equals(4 * numberOfVertices * 3));

//     expect(v.length, equals(3 * numberOfVertices));
//     expect(v[0], equals(0));
//     expect(v.last, closeTo(0.850651, 0.001));
//   });

//   test("", () {
//     Model m = new Model.fromObj("""
// # OBJ file created by ply_to_obj.c
// #
// g Object001

// v  1  0  0
// v  0  -1  0
// v  -1  0  0
// v  0  1  0
// v  0  0  1
// v  0  0  -1

// f  2  1  5
// f  3  2  5
// f  4  3  5
// f  1  4  5
// f  1  2  6
// f  2  3  6
// f  3  4  6
// f  4  1  6
// """);

//     Uint8List indices = m.facesAsArr();

//     expect(indices.length, equals(3 * 8));
//     expect(indices.buffer.lengthInBytes, equals(3 * 8));
//     expect(indices.first, equals(1));
//     expect(indices.last, equals(5));
//   });

  test("vertex normals", () {
    var f = new File('models/cube.obj');

    String cube = f.readAsStringSync();
    Model m = new Model.fromObj(cube);

    var t = m.triangles[1];
    print('triangle: ' + t.toString());

    Vertex v = t.vertices[0];
    Vector3 n = v.normal;

    expect(n.x, equals(0));
    expect(n.y, equals(0));
    expect(n.z, equals(-1));

    t = m.triangles.last;
    v = t.vertices.first;
    n = v.normal;

    expect(n.x, equals(0));
    expect(n.y, equals(0));
    expect(n.z, equals(1));
  });


  test("buffer containing both position vectors and normals", () {
    var f = new File('models/cube.obj');

    String cube = f.readAsStringSync();
    Model m = new Model.fromObj(cube);

    Float32List l = m.positionsAndNormalsToArr();


  });

  
}
