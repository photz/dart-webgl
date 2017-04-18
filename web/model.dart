import 'package:vector_math/vector_math.dart';
import 'dart:typed_data';

class Model {
  List<Vector3> _vertices;
  List<List<int>> _faces;

  List<Vector3> get vertices => _vertices;
  List<List<int>> get faces => _faces;
  

  Model.fromObj(String objFile) {

    List<String> lines = objFile.split("\n");

    this._faces = new List.from(lines.where(_isFaceDef).map(_faceDefToFace));

    this._vertices = new List.from(lines.where(_isVertexDef).map(_vertexDefToVertex));

  }


  Float32List verticesAsArr() {
    const l = 3;

    Float32List arr = new Float32List(l * this._vertices.length);

    int i = 0;

    for (Vector3 v in this._vertices) {
      v.copyIntoArray(arr, i * l);
      i++;
    }

    return arr;
  }

  Uint8List facesAsArr() {
    const int l = 3;

    Uint8List arr = new Uint8List(l * this._faces.length);

    int i = 0;

    for (List<int> face in this._faces) {
      arr.setAll(l * i, face);
      i++;
    }

    return arr;
  }

  static bool _isVertexDef(String line) {
    return line.startsWith("v ");
  }

  static bool _isFaceDef(String line) {
    return line.startsWith("f ");
  }

  static List<int> _faceDefToFace(String faceDef) {
    RegExp e = new RegExp(r" +");
    return new List.from(faceDef.split(e).skip(1).map(int.parse));
  }

  static Vector3 _vertexDefToVertex(String vertexDef) {
    RegExp e = new RegExp(r" +");
    List<double> components = new List.from(vertexDef.split(e).skip(1).map(double.parse));

    return new Vector3.array(components);
  }

}
