import 'package:vector_math/vector_math.dart';
import 'dart:typed_data';
import 'dart:web_gl';
import 'scene_object.dart';

class Cube extends SceneObject {
  static const String vshader = """
attribute vec4 a_Position;
attribute vec4 a_Color;
uniform mat4 u_MvpMatrix;
varying vec4 v_Color;
void main() {
  gl_Position = u_MvpMatrix * a_Position;
  v_Color = a_Color;
}
""";

  static const String fshader = """
#ifdef GL_ES
precision mediump float;
#endif
varying vec4 v_Color;
void main() {
  gl_FragColor = v_Color;
}
""";

  Cube(RenderingContext gl) : super(gl, vshader, fshader) {

    //this._program = SceneObject._createProgram(this._gl,
    //Cube.vshader, Cube.fshader);

    gl.useProgram(program);

    _initVertexBuffers(gl, program);

  }

  UniformLocation _u(String uniformName) {
    UniformLocation u = gl.getUniformLocation(program,
        uniformName);

    if (u == null) {
      throw new Exception("no such uniform: " + uniformName);
    }

    return u;
  }


  void draw(Matrix4 mvp, time) {
    gl.useProgram(this.program);
    this._drawCube(mvp);
  }

  void _drawCube(Matrix4 mvp) {
    this.gl.uniformMatrix4fv(this._u('u_MvpMatrix'),
        false,
        mvp.storage);

    this.gl.drawElements(TRIANGLES, 36, UNSIGNED_BYTE, 0);
  }

  static void _initVertexBuffers(RenderingContext gl, Program program) {

    final Float32List verticesColors = new Float32List.fromList([
      1.0,  1.0,  1.0,     1.0,  1.0,  1.0,  // v0 White
        -1.0,  1.0,  1.0,     1.0,  0.0,  1.0,  // v1 Magenta
        -1.0, -1.0,  1.0,     1.0,  0.0,  0.0,  // v2 Red
      1.0, -1.0,  1.0,     1.0,  1.0,  0.0,  // v3 Yellow
      1.0, -1.0, -1.0,     0.0,  1.0,  0.0,  // v4 Green
      1.0,  1.0, -1.0,     0.0,  1.0,  1.0,  // v5 Cyan
        -1.0,  1.0, -1.0,     0.0,  0.0,  1.0,  // v6 Blue
        -1.0, -1.0, -1.0,     0.0,  0.0,  0.0   // v7 Black
    ]);

    final Buffer vertexColorBuffer = gl.createBuffer();
    gl.bindBuffer(ARRAY_BUFFER, vertexColorBuffer);
    gl.bufferData(ARRAY_BUFFER, verticesColors, STATIC_DRAW);

    // a_Position
    final int a_Position = gl.getAttribLocation(program, 'a_Position');
    gl.vertexAttribPointer(a_Position,
        3,
        FLOAT,
        false,
        6 * Float32List.BYTES_PER_ELEMENT,
        0);
    gl.enableVertexAttribArray(a_Position);

    // a_Color
    final int a_Color = gl.getAttribLocation(program, 'a_Color');
    gl.vertexAttribPointer(a_Color,
        3,
        FLOAT,
        false,
        6 * Float32List.BYTES_PER_ELEMENT,
        3 * Float32List.BYTES_PER_ELEMENT);
    gl.enableVertexAttribArray(a_Color);

    final Uint8List indices = new Uint8List.fromList([
      0, 1, 2,   0, 2, 3,    // front
      0, 3, 4,   0, 4, 5,    // right
      0, 5, 6,   0, 6, 1,    // up
      1, 6, 7,   1, 7, 2,    // left
      7, 4, 3,   7, 3, 2,    // down
      4, 7, 6,   4, 6, 5     // back
    ]);
    final Buffer indexBuffer = gl.createBuffer();
    gl.bindBuffer(ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl.bufferData(ELEMENT_ARRAY_BUFFER, indices, STATIC_DRAW);
  }



}
