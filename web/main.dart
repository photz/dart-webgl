import 'package:vector_math/vector_math.dart';
import 'dart:typed_data';
import 'dart:html';
import 'dart:web_gl';
import 'web_gl_debug.dart';
import 'cube.dart';
import 'pyramid.dart';
import 'dart:math' as Math;


class WebGlApp {
  CanvasElement _canvas;
  RenderingContext _gl;
  List _scene;
  Vector3 _ambientLightColor;
  Vector3 _lightDirection;
  Vector3 _lightColor;

  WebGlApp(int width, int height) {

    this._canvas = new CanvasElement();

    this._canvas.width = width;
    this._canvas.height = height;


    this._gl = new DebugRenderingContext(this._canvas.getContext('webgl'));

    this._gl.clearColor(0, 0, 0, 1);

    this._scene = new List();

    document.body.onKeyDown.listen(this._onKeyDown);

    this.addObjectToScene(new Cube.create(this._gl, 1, 4));
    this.addObjectToScene(new Cube.create(this._gl, 1, 3));
    this.addObjectToScene(new Cube.create(this._gl, 2, 3));
    this.addObjectToScene(new Cube.create(this._gl, 4, 1));
    //this.addObjectToScene(new Pyramid(this._gl));

    this._gl.enable(DEPTH_TEST);

    this._ambientLightColor = new Vector3(0.05, 0.05, 0.05);
    this._lightDirection = new Vector3(0.5, 3.0, 4.0);
    this._lightColor = new Vector3(1.0, 1.0, 1.0);
  }

  void addObjectToScene(obj) {
    this._scene.add(obj);
  }

  void startLoop() {
    window.animationFrame.then(this._loop);
  }

  void _loop(x) {
    this._redraw(x);
    window.animationFrame.then(this._loop);
  }

  void _redraw(time) {
    this._gl.clear(COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT);
    double fovYRadians = 30.0;
    double aspectRatio = 1.0;
    double zNear = 1.0;
    double zFar = 100.0;
    Matrix4 m = makePerspectiveMatrix(fovYRadians,
        this._canvas.width / this._canvas.height, zNear, zFar);

    m = createPerspectiveMatrix(fovYRadians, zNear, zFar);

    Vector3 cameraPosition = new Vector3(18.0, 18.0, 18.0);

    Vector3 cameraFocusPosition = this._scene.first.getWorldCoordinates();

    Vector3 upDirection = new Vector3(0.0, 1.0, 0.0);

    Matrix4 v = makeViewMatrix(cameraPosition,
        cameraFocusPosition,
        upDirection);

    Matrix4 mvp = m * v;

    for (var obj in this._scene) {
      obj.draw(mvp, time,
          this._lightColor, this._lightDirection,
          this._ambientLightColor);
    }
  }

  Matrix4 createPerspectiveMatrix(double fov, double near, double far) {
    double s = 1 / (Math.tan((fov / 2) * (3.1414 / 180)));

    return new Matrix4.fromList([
      s, 0.0, 0.0, 0.0,
      0.0, s, 0.0, 0.0,
      0.0, 0.0, -far / (far - near), -1.0,
      0.0, 0.0, -(far * near) / (far - near), 0.0
    ]);
  }

  Element getElement() {
    return this._canvas;
  }

  void _onKeyDown(KeyboardEvent e) {
    var player = this._scene.first;


    switch (e.keyCode) {
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
    }
  }
}


void main() {
  WebGlApp a = new WebGlApp(640, 480);
  document.body.children.add(a.getElement());
  a.startLoop();
}
