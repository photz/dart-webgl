import 'package:vector_math/vector_math.dart';
import 'dart:typed_data';
import 'dart:web_gl';

Program createProgram(RenderingContext gl,
    String vShaderSource, String fShaderSource) {

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
attribute vec4 a_Normal;
uniform vec3 u_AmbientLightColor;
uniform vec3 u_LightColor;
uniform vec3 u_LightDirection;
uniform mat4 u_ViewMatrix;
uniform mat4 u_ModelMatrix;
varying vec4 v_Color;
void main() {
  gl_Position = (u_ViewMatrix * u_ModelMatrix) * a_Position;;

  vec3 normal = normalize(a_Normal.xyz);
  float nDotL = max(dot(u_LightDirection, normal), 0.0);
  vec3 diffuse = u_LightColor * a_Color.rgb * nDotL;
  v_Color = vec4(diffuse + u_AmbientLightColor, a_Color.a);  
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

  Vector3 getWorldCoordinates() {
    double multiplier = 2.0;

    Vector3 worldCoordinates = new Vector3(this._x * multiplier,
        0.0, this._y * multiplier);

    return worldCoordinates;
  }

  Cube.create(RenderingContext gl, int x, int y) {
    if (_gl == null) {
      _gl = gl;
      _program = createProgram(_gl, vshader, fshader);
      _gl.useProgram(program);
      _initVertexBuffers(gl, program);
      _initNormalsBuffer(gl, program);
    }

    this._x = x;
    this._y = y;
  }

  void _setAmbientLightColor(Vector3 ambientLightColor) {
    gl.uniform3fv(this._u('u_AmbientLightColor'),
        ambientLightColor.storage);
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

  void draw(Matrix4 mvp, time, Vector3 lightColor,
      Vector3 lightDirection, Vector3 ambientLightColor) {

    gl.uniform3fv(this._u('u_LightColor'), lightColor.storage);
    gl.uniform3fv(this._u('u_LightDirection'), lightDirection.storage);
    this._setAmbientLightColor(ambientLightColor);

    gl.useProgram(this.program);
    this._drawCube(mvp);
  }


  void _drawCube(Matrix4 viewMatrix) {
    this.gl.uniformMatrix4fv(this._u('u_ViewMatrix'),
        false,
        viewMatrix.storage);

    Vector3 worldCoordinates = this.getWorldCoordinates();
    
    Matrix4 modelMatrix = new Matrix4.translation(worldCoordinates);

    this.gl.uniformMatrix4fv(this._u('u_ModelMatrix'),
        false,
        modelMatrix.storage);


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


  static void _initNormalsBuffer(RenderingContext gl, Program program) {
    final Float32List normals = new Float32List.fromList([
    0.0, 0.0, 1.0,   0.0, 0.0, 1.0,   0.0, 0.0, 1.0,   0.0, 0.0, 1.0,  // v0-v1-v2-v3 front
    1.0, 0.0, 0.0,   1.0, 0.0, 0.0,   1.0, 0.0, 0.0,   1.0, 0.0, 0.0,  // v0-v3-v4-v5 right
    0.0, 1.0, 0.0,   0.0, 1.0, 0.0,   0.0, 1.0, 0.0,   0.0, 1.0, 0.0,  // v0-v5-v6-v1 up
   -1.0, 0.0, 0.0,  -1.0, 0.0, 0.0,  -1.0, 0.0, 0.0,  -1.0, 0.0, 0.0,  // v1-v6-v7-v2 left
    0.0,-1.0, 0.0,   0.0,-1.0, 0.0,   0.0,-1.0, 0.0,   0.0,-1.0, 0.0,  // v7-v4-v3-v2 down
    0.0, 0.0,-1.0,   0.0, 0.0,-1.0,   0.0, 0.0,-1.0,   0.0, 0.0,-1.0,   // v4-v7-v6-v5 back
    ]);

    final Buffer normalsBuffer = gl.createBuffer();

    final int a_Normal = gl.getAttribLocation(program, 'a_Normal');

    gl.bindBuffer(ARRAY_BUFFER, normalsBuffer);

    gl.bufferData(ARRAY_BUFFER, normals, STATIC_DRAW);

    gl.vertexAttribPointer(a_Normal,
        3,
        FLOAT,
        false,
        0,
        0);

    gl.enableVertexAttribArray(a_Normal);

    gl.bindBuffer(ARRAY_BUFFER, null);
  }
}
