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
  ViewMode _viewMode = ViewMode.THIRD_PERSON;
  scene.Scene _scene;
  var _player;
  int _lastAiUpdate = 0;
  MySphere _sphere;

  WebGlApp(int width, int height) {

    this._canvas = new CanvasElement();

    this._canvas.width = width;
    this._canvas.height = height;


    this._gl = new DebugRenderingContext(this._canvas.getContext('webgl'));

    final Vector4 skyBlue = new Vector4(197.0 / 255.0,
        224.0 / 255.0, 220.0 / 255.0, 0.0);

    this._gl.clearColor(skyBlue.x, skyBlue.y, skyBlue.z, skyBlue.w);

    this._scene = new scene.Scene();

    document.onVisibilityChange.listen(this._onVisibilityChange);
    document.body.onKeyUp.listen(this._onKeyUp);
    window.onKeyDown.listen(this._onKeyDown);
    document.body.onMouseMove.listen(this._onMouseMove);

    this._grid = new Grid.create(this._gl);

    _player = new Cube.create(this._gl, 1, 4,
        new Vector3(1.0, 0.0, 0.0));


    _scene.addToScene(_player);

    this._sphere = new MySphere.create(_scene, _gl, 5, 5,
        new Vector3(1.0, 1.0, 0.0));
    var sphere2 = new MySphere.create(_scene, _gl, 5, 5,
        new Vector3(0.0, 1.0, 1.0));
    _scene.addToScene(sphere2);
    _scene.addToScene(this._sphere);
    _scene.addToScene(new Cube.create(this._gl, 1, 3,
            new Vector3(0.0, 1.0, 0.0)));
    _scene.addToScene(new Cube.create(this._gl, 2, 3,
            new Vector3(0.0, 0.0, 1.0)));
    _scene.addToScene(new Cube.create(this._gl, 4, 1,
            new Vector3(1.0, 0.0, 1.0)));


    sphere2.navigate(50, 5);

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

  void _updateAis() {
    int now = (new DateTime.now()).microsecondsSinceEpoch;

    int min = 1000 * 1000;

    if (min < now - _lastAiUpdate) {
      _scene.forEachObject((o) => o.updateAi());
      _lastAiUpdate = now;
    }
  }

  void _redraw(time) {
    this._sphere.navigate(_player.x-1, _player.y);

    _updateAis();

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

  void _onKeyUp(KeyboardEvent e) {
    switch (e.keyCode) {
      case KeyCode.UP:
      case KeyCode.W:
        _player.stopMovingForward();
        break;

      case KeyCode.DOWN:
      case KeyCode.S:
        _player.stopMovingBackward();
        break;

      case KeyCode.LEFT:
      case KeyCode.A:
        _player.stopMovingLeft();
        break;

      case KeyCode.RIGHT:
      case KeyCode.D:
        _player.stopMovingRight();
        break;
    }
  }

  void _onKeyDown(KeyboardEvent e) {
    double angle = Math.PI / 2;
    switch (e.keyCode) {
      case KeyCode.UP:
      case KeyCode.W:
        _player.setMovingForward();
        break;

      case KeyCode.DOWN:
      case KeyCode.S:
        _player.setMovingBackward();
        break;

      case KeyCode.LEFT:
      case KeyCode.A:
        _player.setMovingLeft();
        break;

      case KeyCode.RIGHT:
      case KeyCode.D:
        _player.setMovingRight();
        break;

      case KeyCode.C:
        _createBlock();
        break;

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

      case KeyCode.P:
        this._running = !this._running;
        if (this._running) {
          this.startLoop();
        }
        break;
    }
  }

  /// Gets called when the player moves the mouse
  void _onMouseMove(e) {
    _player.setAngle(_player.angle - e.movement.x / 40);
  }

  // Gets called when the user switches tabs.
  void _onVisibilityChange(e) {
    switch (document.visibilityState) {
      case 'visible':
        break;

      case 'hidden':
        _running = false;
        break;
    }
  }
}

void main() {
  WebGlApp a = new WebGlApp(window.innerWidth, window.innerHeight);
  document.body.children.add(a.getElement());
  a.startLoop();
}
