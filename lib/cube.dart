import 'dart:typed_data';
import 'dart:web_gl';
import 'dart:math' as Math;

import 'package:vector_math/vector_math.dart';

import 'package:webgltest/load_shader.dart';
import 'package:webgltest/model.dart';
import 'package:webgltest/utils.dart';

class Cube {
  static const double distanceTravelledPerSecond = 1.0;
  static const double microsecondsPerSecond = 1000.0 * 1000.0;

  static RenderingContext _gl;
  static Program _program;
  static Buffer _buffer;
  
  RenderingContext get gl => _gl;
  Program get program => _program;
  double _angle = 0.0;
  Vector3 _color;
  Vector3 _coords;
  int _forwardDirection = 0;
  int _lastUpdateForward = 0;
  int _sidewaysDirection = 0;
  int _lastUpdateSideways = 0;
  bool _jumping = false;
  int _beganJumping = 0;

  int get x => _coords.x.round();
  int get y => _coords.z.round();
  double get angle => _angle;
  Vector3 get color => _color;
  Vector3 get forward => _getForwardVector();
  Vector3 get coords => getWorldCoordinates();

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

    _coords = new Vector3(x as double, 0.0, y as double);
  }

  Vector3 _getForwardVector() {
    Matrix4 mat = new Matrix4
      .rotationY(_angle);

    Vector4 testVec = new Vector4(0.0, 0.0, 1.0, 0.0);

    testVec = mat * testVec;

    return testVec.xyz;
  }

  void updateLocation() {
    if (_forwardDirection != 0) {
      int now = (new DateTime.now()).microsecondsSinceEpoch;

      int microsecondsPassed = now - _lastUpdateForward;

      double distanceTravelled =
        microsecondsPassed * distanceTravelledPerSecond / microsecondsPerSecond;

      Vector3 forwardVector = _getForwardVector();

      _coords.addScaled(forwardVector, _forwardDirection * distanceTravelled);

      _lastUpdateForward = now;
    }

    if (_sidewaysDirection != 0) {
      Matrix4 mat = new Matrix4
        .rotationY(_angle);

      Vector4 testVec = new Vector4(1.0, 0.0, 0.0, 0.0);

      testVec = mat * testVec;

      int now = (new DateTime.now()).microsecondsSinceEpoch;

      int microsecondsPassed = now - _lastUpdateSideways;

      double distanceTravelled =
        microsecondsPassed * distanceTravelledPerSecond / microsecondsPerSecond;

      _coords.addScaled(testVec.xyz, _sidewaysDirection * distanceTravelled);

      _lastUpdateSideways = now;
    }

    if (_jumping) {
      int now = (new DateTime.now()).microsecondsSinceEpoch;

      int microsecondsPassed = now - _beganJumping;

      double secondsPassed = microsecondsPassed / microsecondsPerSecond;

      double upSpeed = 3.0;

      double y = upSpeed * secondsPassed - 5.0 * Math.pow(secondsPassed, 2);

      _coords.y = Math.max(0.0, y);

      if (y < 0) {
        _jumping = false;
        _beganJumping = 0;
      }
    }
  }

  Vector3 getWorldCoordinates() {
    Vector3 worldCoordinates = new Vector3(
        _coords.x + 0.5,
        _coords.y,
        _coords.z + 0.5);

    return worldCoordinates;
  }

  void setAngle(double newAngle) {
    this._angle = newAngle;
  }

  void goTo(int x, int y) {
    _coords.x = x as double;
    _coords.z = y as double;
  }

  void draw(Matrix4 mvp, time, Vector3 lightColor,
      Vector3 lightDirection, Vector3 ambientLightColor,
      Vector3 lightPosition) {

    updateLocation();

    gl.useProgram(this.program);    

    _setUpPointers();

    gl.uniform3fv(this._u('u_Color'), this._color.storage);
    gl.uniform3fv(this._u('u_LightColor'), lightColor.storage);
    gl.uniform3fv(this._u('u_LightPosition'), lightPosition.storage);
    this._setAmbientLightColor(ambientLightColor);

    this._drawCube(mvp);
  }

  void updateAi() {

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

  void setMovingForward() {
    if (_forwardDirection != 1) {
      _lastUpdateForward = (new DateTime.now()).microsecondsSinceEpoch;
      _forwardDirection = 1;
    }
  }

  void setMovingBackward() {
    if (_forwardDirection != -1) {
      _lastUpdateForward = (new DateTime.now()).microsecondsSinceEpoch;
      _forwardDirection = -1;
    }
  }

  void setMovingLeft() {
    if (_sidewaysDirection != 1) {
      _sidewaysDirection = 1;
      _lastUpdateSideways = (new DateTime.now()).microsecondsSinceEpoch;
    }
  }

  void setMovingRight() {
    if (_sidewaysDirection != -1) {
      _sidewaysDirection = -1;
      _lastUpdateSideways = (new DateTime.now()).microsecondsSinceEpoch;
    }
  }

  stopMovingBackward() => _forwardDirection = 0;
  stopMovingForward() => _forwardDirection = 0;
  stopMovingLeft() => _sidewaysDirection = 0;
  stopMovingRight() => _sidewaysDirection = 0;

  void jump() {
    if (0 == _coords.y && !_jumping) {
      _jumping = true;
      _beganJumping = (new DateTime.now()).microsecondsSinceEpoch;
    }
  }

  void shoot() {
    print('shoot!');
    // TODO
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
