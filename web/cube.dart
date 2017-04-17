import 'package:vector_math/vector_math.dart';
import 'dart:typed_data';
import 'dart:web_gl';

Program createProgram(RenderingContext gl,
    String vShaderSource, String fShaderSource) {

  print('creating a new program');

  Shader vShader = loadShader(gl, RenderingContext.VERTEX_SHADER,
      vShaderSource);

  Shader fShader = loadShader(gl, RenderingContext.FRAGMENT_SHADER,
      fShaderSource);

  Program program = gl.createProgram();

  gl.attachShader(program, vShader);
  gl.attachShader(program, fShader);
  gl.linkProgram(program);
  return program;
}

Shader loadShader(RenderingContext gl, int type, String source) {
  Shader shader = gl.createShader(type);
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  print(gl.getShaderInfoLog(shader));
  return shader;
}

class Cube {

  static RenderingContext _gl;
  static Program _program;

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

  RenderingContext get gl => _gl;
  Program get program => _program;
  int _x;
  int _y;

  int get x => _x;
  int get y => _y;

  Cube.create(RenderingContext gl, int x, int y) {
    if (_gl == null) {
      _gl = gl;
      _program = createProgram(_gl, vshader, fshader);
      _gl.useProgram(program);
      _initVertexBuffers(gl, program);
    }

    this._x = x;
    this._y = y;
  }

  UniformLocation _u(String uniformName) {
    UniformLocation u = gl.getUniformLocation(program,
        uniformName);

    if (u == null) {
      throw new Exception("no such uniform: " + uniformName);
    }

    return u;
  }

  void goTo(int x, int y) {
    this._x = x;
    this._y = y;
  }

  void draw(Matrix4 mvp, time) {
    gl.useProgram(this.program);
    this._drawCube(mvp);
  }

  void _drawCube(Matrix4 mvp) {
    Matrix4 m = new Matrix4.copy(mvp);
    double multiplier = 1.5;
    m.translate(this._x * multiplier,
        0.0,
        this.y * multiplier);

    this.gl.uniformMatrix4fv(this._u('u_MvpMatrix'),
        false,
        m.storage);

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