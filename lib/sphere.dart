import 'dart:math' as Math;
import 'dart:typed_data';
import 'dart:web_gl';

import 'package:vector_math/vector_math.dart';

import 'package:webgltest/utils.dart';
import 'package:webgltest/model.dart';
import 'package:webgltest/load_shader.dart';
import 'package:webgltest/scene.dart' as scene;



class MySphere {

  static RenderingContext _gl;
  static Program _program;
  static Buffer _buffer;
  static scene.Scene _scene;

  RenderingContext get gl => _gl;
  Program get program => _program;

  /// The current position of the object in the world
  int _x;

  /// The current position of the object in the world
  int _y;

  /// The orientation of the object in radians
  double _angle = 0.0;

  /// The color of the object
  Vector3 _color;

  /// The current goal or destination the object is trying to get to
  scene.Point _goal;

  /// Timestamp of the last update in microseconds
  int _lastNavUpdate = 0;

  /// The route the object is currently following
  List<scene.Point> _path = [];
  
  int get x => _x;
  int get y => _y;
  double get angle => _angle;
  bool _goalChanged = false;

  MySphere.create(scene.Scene scene, RenderingContext gl, int x, int y, Vector3 color)
    : _color = color {

    if (_gl == null) {
      _scene = scene;
      _gl = gl;
      String vshader = myLoadShader('sphere.vert');
      String fshader = myLoadShader('sphere.frag');
      _program = createProgram(_gl, vshader, fshader);
      _gl.useProgram(program);
      String modelData = myLoadModel('sphere.obj');
      Model m = new Model.fromObj(modelData);


      _buffer = this._fillBufferWithModelData(m);
      this._setUpPointers();
    }

    this._x = x;
    this._y = y;
  }


  Vector3 getWorldCoordinates() {
    double multiplier = 1.0;


    Vector3 worldCoordinates = new Vector3(
        this._x * multiplier + 0.5,
        0.5,
        this._y * multiplier + 0.5);

    if (!_path.isEmpty) {
      scene.Point nextPoint = _path.first;

      Vector3 nextVector = new Vector3(
          nextPoint.x * multiplier + 0.5,
          0.5,
          nextPoint.y * multiplier + 0.5);

      Vector direction = nextVector - worldCoordinates;

      int now = (new DateTime.now()).microsecondsSinceEpoch;

      // 1 second
      int fullStepInterval = 1000 * 1000;      

      int timeSinceUpdate = now - _lastNavUpdate;

      var scale = timeSinceUpdate / fullStepInterval;

      worldCoordinates.addScaled(direction, scale);
    }



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

    _updateNav();

    gl.uniform3fv(this._u('u_Color'), this._color.storage);
    gl.uniform3fv(this._u('u_LightColor'), lightColor.storage);
    gl.uniform3fv(this._u('u_LightPosition'), lightPosition.storage);
    this._setAmbientLightColor(ambientLightColor);

    this._drawMySphere(mvp);
  }

  void _updateNav() {
    if (null == _goal || _path.isEmpty) return;

    int now = (new DateTime.now()).microsecondsSinceEpoch;

    // 1 second
    int min = 1000 * 1000;

    if (min < now - _lastNavUpdate) {
      var next = _path.removeAt(0);
      _x = next.x;
      _y = next.y;
      _lastNavUpdate = now;
    }
  }

  void updateAi() {
    if (_goal != null) {

      if (_goalChanged || !_isPathFree(_path)) {
        scene.Point currentPos = new scene.Point(x, y);

        try {
          _path = _scene.findPath(currentPos, _goal);
        } on scene.NoPathToDestination {
          // currently unable to go there
          _path = [];
        }

        _goalChanged = false;
      }
    }
  }

  void _drawMySphere(Matrix4 viewMatrix) {
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

    const int nFaces = 224;
    this.gl.drawArrays(TRIANGLES, 0, nFaces * 3);
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

  void navigate(int x, int y) {
    _goal = new scene.Point(x, y);
    _goalChanged = true;
  }

  /// Checks if the given path is free of obstacles
  bool _isPathFree(List<scene.Point> path) =>
      path.every((p) => _scene.isFree(p.x, p.y));
}

