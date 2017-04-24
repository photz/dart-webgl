import 'package:vector_math/vector_math.dart';
import 'dart:typed_data';
import 'dart:html';
import 'dart:web_gl';
import 'web_gl_debug.dart';
import 'package:webgltest/cube.dart';
import 'dart:math' as Math;
import 'package:webgltest/grid.dart';
import 'package:webgltest/sphere.dart';

enum ViewMode {
  FIRST_PERSON,
  THIRD_PERSON
}

class WebGlApp {
  CanvasElement _canvas;
  RenderingContext _gl;
  List _scene;
  Vector3 _ambientLightColor;
  Vector3 _lightDirection;
  Vector3 _lightColor;
  Grid _grid;
  bool _running = false;
  ViewMode _viewMode = ViewMode.FIRST_PERSON;

  WebGlApp(int width, int height) {

    this._canvas = new CanvasElement();

    this._canvas.width = width;
    this._canvas.height = height;


    this._gl = new DebugRenderingContext(this._canvas.getContext('webgl'));

    this._gl.clearColor(0, 0, 0, 1);

    this._scene = new List();

    document.body.onKeyDown.listen(this._onKeyDown);

    this._grid = new Grid.create(this._gl);

    this.addObjectToScene(new MySphere.create(this._gl, 5, 5,
            new Vector3(1.0, 1.0, 0.0)));
    this.addObjectToScene(new Cube.create(this._gl, 1, 4,
            new Vector3(1.0, 0.0, 0.0)));
    this.addObjectToScene(new Cube.create(this._gl, 1, 3,
            new Vector3(0.0, 1.0, 0.0)));
    this.addObjectToScene(new Cube.create(this._gl, 2, 3,
            new Vector3(0.0, 0.0, 1.0)));
    this.addObjectToScene(new Cube.create(this._gl, 4, 1,
            new Vector3(1.0, 0.0, 1.0)));
    //this.addObjectToScene(new Pyramid(this._gl));

    this._gl.enable(DEPTH_TEST);

    this._ambientLightColor = new Vector3(0.05, 0.05, 0.05);
    this._lightDirection = new Vector3(0.5, 3.0, 4.0);
    this._lightColor = new Vector3(1.0, 1.0, 1.0);
  }

  void addObjectToScene(obj) {
    this._scene.add(obj);
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

        Vector3 playerCoords = this._scene.first.getWorldCoordinates();

        cameraPosition = playerCoords;

        Matrix4 mat = new Matrix4
          .rotationY(this._scene.first.angle);

        Vector4 testVec = new Vector4(1.0, 0.0, 0.0, 0.0);

        testVec = mat * testVec;

        cameraFocusPosition = playerCoords + testVec.xyz;
        break;
        
      case ViewMode.THIRD_PERSON:
        cameraPosition = new Vector3(18.0, 18.0, 18.0);
        cameraFocusPosition = this._scene.first.getWorldCoordinates();
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

    for (var obj in this._scene) {
      obj.draw(mvp, time,
          this._lightColor, this._lightDirection,
          this._ambientLightColor, lightPosition);
    }
  }

  Element getElement() {
    return this._canvas;
  }

  void _onKeyDown(KeyboardEvent e) {
    var player = this._scene.first;

    double angle = Math.PI / 10;

    switch (e.keyCode) {
      case KeyCode.SPACE:
        switch (_viewMode) {
          case ViewMode.FIRST_PERSON:
            _viewMode = ViewMode.THIRD_PERSON;
            break;
          case ViewMode.THIRD_PERSON:
            _viewMode = ViewMode.FIRST_PERSON;
            break;
        }
        break;

      case KeyCode.LEFT:
        player.goTo(player.x-1, player.y);
        break;

      case KeyCode.RIGHT:
        player.goTo(player.x+1, player.y);
        break;

      case KeyCode.UP:
        player.goTo(player.x, player.y-1);
        break;

      case KeyCode.DOWN:
        player.goTo(player.x, player.y+1);
        break;

      case KeyCode.Q:
        player.setAngle(player.angle + angle);
        break;
      case KeyCode.E:
        player.setAngle(player.angle - angle);
        break;

      case KeyCode.P:
        this._running = !this._running;
        if (this._running) {
          this.startLoop();
        }
        break;
    }
  }
}

void main() {
  WebGlApp a = new WebGlApp(window.innerWidth, window.innerHeight);
  document.body.children.add(a.getElement());
  a.startLoop();
}
