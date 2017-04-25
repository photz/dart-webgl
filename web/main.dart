import 'package:vector_math/vector_math.dart';
import 'dart:typed_data';
import 'dart:html';
import 'dart:web_gl';
import 'web_gl_debug.dart';
import 'package:webgltest/cube.dart';
import 'dart:math' as Math;
import 'package:webgltest/grid.dart';
import 'package:webgltest/sphere.dart';
import 'package:webgltest/scene.dart' as scene;

enum ViewMode {
  FIRST_PERSON,
  THIRD_PERSON
}

class WebGlApp {
  CanvasElement _canvas;
  RenderingContext _gl;
  Vector3 _ambientLightColor;
  Vector3 _lightDirection;
  Vector3 _lightColor;
  Grid _grid;
  bool _running = false;
  ViewMode _viewMode = ViewMode.FIRST_PERSON;
  scene.Scene _scene;
  var _player;

  WebGlApp(int width, int height) {

    this._canvas = new CanvasElement();

    this._canvas.width = width;
    this._canvas.height = height;


    this._gl = new DebugRenderingContext(this._canvas.getContext('webgl'));

    final Vector4 skyBlue = new Vector4(197.0 / 255.0,
        224.0 / 255.0, 220.0 / 255.0, 0.0);

    this._gl.clearColor(skyBlue.x, skyBlue.y, skyBlue.z, skyBlue.w);

    this._scene = new scene.Scene();

    document.body.onKeyDown.listen(this._onKeyDown);

    this._grid = new Grid.create(this._gl);

    _player = new MySphere.create(this._gl, 5, 5,
        new Vector3(1.0, 1.0, 0.0));

    _scene.addToScene(_player);
    _scene.addToScene(new Cube.create(this._gl, 1, 4,
            new Vector3(1.0, 0.0, 0.0)));
    _scene.addToScene(new Cube.create(this._gl, 1, 3,
            new Vector3(0.0, 1.0, 0.0)));
    _scene.addToScene(new Cube.create(this._gl, 2, 3,
            new Vector3(0.0, 0.0, 1.0)));
    _scene.addToScene(new Cube.create(this._gl, 4, 1,
            new Vector3(1.0, 0.0, 1.0)));


    this._gl.enable(DEPTH_TEST);

    this._ambientLightColor = new Vector3(0.05, 0.05, 0.05);
    this._lightDirection = new Vector3(0.5, 3.0, 4.0);
    this._lightColor = new Vector3(1.0, 1.0, 1.0);
  }

  startLoop() async {
    _running = true;
    while (_running) {
      var time = await window.animationFrame;
      this._redraw(time);
    }
  }

  Matrix4 _getViewMatrix() {
    Vector3 cameraPosition;
    Vector3 cameraFocusPosition;

    switch (this._viewMode) {

      case ViewMode.FIRST_PERSON:

        Vector3 playerCoords = _player.getWorldCoordinates();

        cameraPosition = playerCoords;

        Matrix4 mat = new Matrix4
          .rotationY(_player.angle);

        Vector4 testVec = new Vector4(1.0, 0.0, 0.0, 0.0);

        testVec = mat * testVec;

        cameraFocusPosition = playerCoords + testVec.xyz;
        break;
        
      case ViewMode.THIRD_PERSON:
        const double distance = 20.0;

        Vector4 test = new Vector4(distance, 0.0, 0.0, 1.0);

        Matrix4 mat = new Matrix4.rotationY(_player.angle);

        test = mat * test;

        cameraPosition = _player.getWorldCoordinates() - test.xyz + new Vector3(0.0, 18.0, 0.0);

        cameraFocusPosition = _player.getWorldCoordinates();
        break;
    }

    Vector3 upDirection = new Vector3(0.0, 1.0, 0.0);

    Matrix4 v = makeViewMatrix(cameraPosition,
        cameraFocusPosition,
        upDirection);

    return v;
  }

  void _redraw(time) {
    this._gl.clear(COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT);
    double fovYRadians = 30.0 * degrees2Radians;
    double aspectRatio = this._canvas.width / this._canvas.height;
    double zNear = 1.0;
    double zFar = 100.0;
    Matrix4 m = makePerspectiveMatrix(fovYRadians,
        aspectRatio, zNear, zFar);

    Matrix4 mvp = m * _getViewMatrix();

    this._lightDirection.normalize();

    final Vector3 lightPosition = new Vector3(10.0, 10.0, 10.0);

    this._grid.draw(mvp, time);

    _scene.forEachObject((obj) {
      obj.draw(mvp, time,
          this._lightColor, this._lightDirection,
          this._ambientLightColor, lightPosition);
    });
  }

  Element getElement() {
    return this._canvas;
  }

  void _createBlock() {

    var test = new Vector4(1.0, 0.0, 0.0, 1.0);

    var m = new Matrix4.rotationY(_player.angle);

    test = m * test;

    var pos = _player.getWorldCoordinates() + test.xyz;

    _scene.addToScene(new Cube.create(this._gl, pos.x.round(), pos.z.round(),
            new Vector3(1.0, 0.0, 1.0)));
  }

  void _onKeyDown(KeyboardEvent e) {
    double angle = Math.PI / 2;

    switch (e.keyCode) {
      case KeyCode.V:
        switch (_viewMode) {
          case ViewMode.FIRST_PERSON:
            _viewMode = ViewMode.THIRD_PERSON;
            break;
          case ViewMode.THIRD_PERSON:
            _viewMode = ViewMode.FIRST_PERSON;
            break;
        }
        break;

      case KeyCode.SPACE:
        _createBlock();
        break;

      case KeyCode.LEFT:
        _player.goTo(_player.x-1, _player.y);
        break;

      case KeyCode.RIGHT:
        _player.goTo(_player.x+1, _player.y);
        break;

      case KeyCode.UP:
        _player.goTo(_player.x, _player.y-1);
        break;

      case KeyCode.DOWN:
        _player.goTo(_player.x, _player.y+1);
        break;

      case KeyCode.Q:
        _player.setAngle(_player.angle + angle);
        break;
      case KeyCode.E:
        _player.setAngle(_player.angle - angle);
        break;

      case KeyCode.P:
        this._running = !this._running;
        if (this._running) {
          //this.startLoop();
        }
        break;
    }

    this._redraw(0.1);
  }
}

void main() {
  WebGlApp a = new WebGlApp(window.innerWidth, window.innerHeight);
  document.body.children.add(a.getElement());
  //a.startLoop();
}
