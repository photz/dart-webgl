import 'package:vector_math/vector_math.dart';
import 'dart:typed_data';
import 'dart:web_gl';
import 'dart:math' as Math;
import 'model.dart';
import 'package:webgltest/load_shader.dart';
import 'utils.dart';

class Cube {

  static RenderingContext _gl;
  static Program _program;

  RenderingContext get gl => _gl;
  Program get program => _program;
  int _x;
  int _y;
  double _angle = 0.0;
  Vector3 _color;
  
  int get x => _x;
  int get y => _y;
  double get angle => _angle;

  Cube.create(RenderingContext gl, int x, int y, Vector3 color)
    : _color = color {

    if (_gl == null) {
      _gl = gl;
      String vshader = myLoadShader('cube.vert');
      String fshader = myLoadShader('cube.frag');
      _program = createProgram(_gl, vshader, fshader);
      _gl.useProgram(program);
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
    }

    this._x = x;
    this._y = y;
  }


  Vector3 getWorldCoordinates() {
    double multiplier = 1.0;

    Vector3 worldCoordinates = new Vector3(this._x * multiplier,
        0.0, this._y * multiplier);

    return worldCoordinates;
  }

  void setAngle(double newAngle) {
    this._angle = newAngle;
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

    gl.uniform3fv(this._u('u_Color'), this._color.storage);
    gl.uniform3fv(this._u('u_LightColor'), lightColor.storage);
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
    
    worldCoordinates = worldCoordinates - new Vector3(-0.5, 0.5, -0.5);
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
