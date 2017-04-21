import 'package:vector_math/vector_math.dart';
import 'dart:typed_data';
import 'dart:web_gl';
import 'dart:math' as Math;
import 'model.dart';

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
  print(gl.getProgramInfoLog(program));
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
#ifdef GL_ES
precision mediump float;
#endif

attribute vec4 a_Position;
//attribute vec4 a_Color;
attribute vec4 a_Normal;

//uniform vec3 u_AmbientLightColor;
//uniform vec3 u_LightDirection;

uniform mat4 u_ViewMatrix;
uniform mat4 u_ModelMatrix;
uniform mat4 u_NormalMatrix;

varying vec3 v_Normal;
varying vec3 v_Position;
varying vec4 v_Color;


void main() {
  gl_Position = (u_ViewMatrix * u_ModelMatrix) * a_Position;

  v_Position = vec3(u_ModelMatrix * a_Position);

  v_Normal = normalize(vec3(u_NormalMatrix * a_Normal));

  v_Color = vec4(1.0, 0.0, 0.0, 1.0);
}
""";

  static const String fshader = """
#ifdef GL_ES
precision mediump float;
#endif
uniform vec3 u_LightColor;
uniform vec3 u_LightPosition;
uniform vec3 u_AmbientLight;

varying vec3 v_Normal;
varying vec3 v_Position;
varying vec4 v_Color;

void main() {
  vec3 normal = normalize(v_Normal);

  vec3 lightDirection = normalize(u_LightPosition - v_Position);

  float d = max(dot(lightDirection, normal), 0.0);

  vec3 diffuse = u_LightColor * v_Color.rgb * d;

  vec3 ambient = u_AmbientLight * v_Color.rgb;

  gl_FragColor = vec4(diffuse + ambient, v_Color.a) + (vec4(0.1 * u_LightColor, 0.0));
}
""";

  RenderingContext get gl => _gl;
  Program get program => _program;
  int _x;
  int _y;
  double _angle = 0.0;
  
  int get x => _x;
  int get y => _y;
  double get angle => _angle;

  Vector3 getWorldCoordinates() {
    double multiplier = 2.0;

    Vector3 worldCoordinates = new Vector3(this._x * multiplier,
        0.0, this._y * multiplier);

    return worldCoordinates;
  }

  void setAngle(double newAngle) {
    this._angle = newAngle;
  }

  Cube.create(RenderingContext gl, int x, int y) {
    if (_gl == null) {
      _gl = gl;
      _program = createProgram(_gl, vshader, fshader);
      _gl.useProgram(program);
      //_initVertexBuffers(gl, program);
      //_initNormalsBuffer(gl, program);
          Model m = new Model.fromObj("""
# cube.obj
#
 
g cube
 
v  0.0  0.0  0.0
v  0.0  0.0  1.0
v  0.0  1.0  0.0
v  0.0  1.0  1.0
v  1.0  0.0  0.0
v  1.0  0.0  1.0
v  1.0  1.0  0.0
v  1.0  1.0  1.0

vn  0.0  0.0  1.0
vn  0.0  0.0 -1.0
vn  0.0  1.0  0.0
vn  0.0 -1.0  0.0
vn  1.0  0.0  0.0
vn -1.0  0.0  0.0
 
f  1//2  7//2  5//2
f  1//2  3//2  7//2
f  1//6  4//6  3//6   
f  1//6  2//6  4//6
f  3//3  8//3  7//3
f  3//3  4//3  8//3
f  5//5  7//5  8//5
f  5//5  8//5  6//5
f  1//4  5//4  6//4
f  1//4  6//4  2//4
f  2//1  6//1  8//1
f  2//1  8//1  4//1 
""");
          this._load(m);
          //this._loadVertices(m);
          //this._loadFaces(m);
    }

    this._x = x;
    this._y = y;
  }

  void _setAmbientLightColor(Vector3 ambientLightColor) {
    gl.uniform3fv(this._u('u_AmbientLight'),
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
      Vector3 lightDirection, Vector3 ambientLightColor,
      Vector3 lightPosition) {

    gl.uniform3fv(this._u('u_LightColor'), lightColor.storage);
    //gl.uniform3fv(this._u('u_LightDirection'), lightDirection.storage);
    gl.uniform3fv(this._u('u_LightPosition'), lightPosition.storage);
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

    modelMatrix.rotateY(this._angle);

    this.gl.uniformMatrix4fv(this._u('u_ModelMatrix'),
        false,
        modelMatrix.storage);


    Matrix4 normalMatrix = new Matrix4.inverted(modelMatrix);
    normalMatrix.transpose();

    UniformLocation u_NormalMatrix = this._u('u_NormalMatrix');

    this.gl.uniformMatrix4fv(u_NormalMatrix,
        false,
        normalMatrix.storage);

    //this.gl.drawElements(TRIANGLES, 20 * 3, UNSIGNED_BYTE, 0);

    this.gl.drawArrays(TRIANGLES, 0, 6 * 2 * 3);
  }

  int _a(String attribName) {
    final int attribLocation = gl.getAttribLocation(_program,
        attribName);

    if (-1 == attribLocation) {
      throw new Exception('no such attribute: ' + attribName);
    }

    return attribLocation;
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

  void _load(Model model) {
    Float32List positionsNormals = model.positionsAndNormalsToArr();

    Buffer buffer = gl.createBuffer();

    gl.bindBuffer(ARRAY_BUFFER, buffer);
    gl.bufferData(ARRAY_BUFFER, positionsNormals, STATIC_DRAW);

    gl.vertexAttribPointer(this._a('a_Position'),
        3,
        FLOAT,
        false,
        6 * Float32List.BYTES_PER_ELEMENT,
        0);
    gl.enableVertexAttribArray(this._a('a_Position'));

    gl.vertexAttribPointer(this._a('a_Normal'),
        3,
        FLOAT,
        false,
        6 * Float32List.BYTES_PER_ELEMENT,
        3 * Float32List.BYTES_PER_ELEMENT);
    gl.enableVertexAttribArray(this._a('a_Normal'));

  }
}
