import 'package:vector_math/vector_math.dart';
import 'dart:typed_data';
import 'dart:web_gl';
import 'dart:math' as Math;
import 'package:webgltest/load_shader.dart';
import 'utils.dart';

class Grid {
  static RenderingContext _gl;
  static Program _program;
  static Buffer _gridDataBuffer;

  Grid.create(RenderingContext gl) {
    if (_gl == null) {
      _gl = gl;

      String vshader = myLoadShader('grid.vert');
      String fshader = myLoadShader('grid.frag');

      _program = createProgram(_gl, vshader, fshader);
      _gl.useProgram(_program);

      _gridDataBuffer = _createBufferAndFillWithGridData();

      
    }
  }

  void draw(Matrix4 viewMatrix, time) {
    _gl.useProgram(_program);

    const int nVertices = 10 * 10 * 2 * 3;

    _gl.uniformMatrix4fv(this._u('u_ViewMatrix'),
        false,
        viewMatrix.storage);

    _gl.bindBuffer(ARRAY_BUFFER, _gridDataBuffer);

    _gl.enableVertexAttribArray(this._a('a_Coords'));

    _gl.vertexAttribPointer(this._a('a_Coords'),
        3,
        FLOAT,
        false,
        0,
        0);

    _gl.enableVertexAttribArray(this._a('a_Coords'));

    _gl.drawArrays(TRIANGLES, 0, nVertices);
  }

  Buffer _createBufferAndFillWithGridData() {
    Buffer buffer = _gl.createBuffer();

    _gl.bindBuffer(ARRAY_BUFFER, buffer);

    Float32List gridData = _generateGrid(10, 10);

    _gl.bufferData(ARRAY_BUFFER, gridData, STATIC_DRAW);
  }

  Float32List _generateGrid(int rows, int columns) {

    List<int> triangleData = [];

    for (int row = 0; row < rows; row++) {

      for (int col = 0; col < columns; col++) {

        // first triangle
        triangleData.addAll([
          col, row, 0,
          col + 1, row, 0,
          col, row + 1, 0
        ]);

        // second triangle
        triangleData.addAll([
          col + 1, row, 0,
          col + 1, row + 1, 0,
          col, row + 1, 0
        ]);
      }

    }

    Float32List f = new Float32List.fromList(triangleData);

    return f;
  }

  int _a(String attribName) {
    final int attribLocation = _gl.getAttribLocation(_program,
        attribName);

    if (-1 == attribLocation) {
      throw new Exception('no such attribute: ' + attribName);
    }

    return attribLocation;
  }

  UniformLocation _u(String uniformName) {
    UniformLocation u = _gl.getUniformLocation(_program,
        uniformName);

    if (u == null) {
      throw new Exception("no such uniform: " + uniformName);
    }

    return u;
  }

}
