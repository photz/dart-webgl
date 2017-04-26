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
  static Buffer _buffer;

  RenderingContext get gl => _gl;
  Program get program => _program;
  int _x;
  int _y;
  double _angle = 0.0;
  Vector3 _color;
  
  int get x => _x;
  int get y => _y;
  double get angle => _angle;
  Vector3 get color => _color;

  Cube.create(RenderingContext gl, int x, int y, Vector3 color)
    : _color = color {

    if (_gl == null) {
      _gl = gl;
      String vshader = myLoadShader('cube.vert');
      String fshader = myLoadShader('cube.frag');
      _program = createProgram(_gl, vshader, fshader);
      _gl.useProgram(program);
      Model m = new Model.fromObj(myLoadModel('cube.obj'));


      _buffer = this._fillBufferWithModelData(m);
      this._setUpPointers();
    }

    assert(_gl.isProgram(_program));
    assert(_gl.isBuffer(_buffer));

    this._x = x;
    this._y = y;
  }


  Vector3 getWorldCoordinates() {
    double multiplier = 1.0;

    Vector3 worldCoordinates = new Vector3(
        this._x * multiplier + 0.5,
        0.0,
        this._y * multiplier + 0.5);

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

    gl.useProgram(this.program);    

    _setUpPointers();

    gl.uniform3fv(this._u('u_Color'), this._color.storage);
    gl.uniform3fv(this._u('u_LightColor'), lightColor.storage);
    gl.uniform3fv(this._u('u_LightPosition'), lightPosition.storage);
    this._setAmbientLightColor(ambientLightColor);

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

  Buffer _fillBufferWithModelData(Model model) {
    Float32List positionsNormals = model.positionsAndNormalsToArr();

    Buffer buffer = gl.createBuffer();

    gl.bindBuffer(ARRAY_BUFFER, buffer);
    gl.bufferData(ARRAY_BUFFER, positionsNormals, STATIC_DRAW);

    return buffer;
  }

  void _setUpPointers() {
    gl.bindBuffer(ARRAY_BUFFER, _buffer);
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
