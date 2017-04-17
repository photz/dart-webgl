import 'package:vector_math/vector_math.dart';
import 'dart:typed_data';
import 'dart:html';
import 'dart:web_gl';
import 'web_gl_debug.dart';
import 'cube.dart';
import 'pyramid.dart';

class WebGlApp {
  CanvasElement _canvas;
  RenderingContext _gl;
  List _scene;

  WebGlApp() {

    this._canvas = new CanvasElement();

    this._gl = new DebugRenderingContext(this._canvas.getContext('webgl'));

    this._gl.clearColor(0, 0, 0, 1);

    this._scene = new List();

    document.body.onKeyDown.listen(this._onKeyDown);

    this.addObjectToScene(new Cube(this._gl));
    this.addObjectToScene(new Pyramid(this._gl));
  }

  void addObjectToScene(obj) {
    this._scene.add(obj);
  }

  void setSize(int width, int height) {
    this._canvas.width = width;
    this._canvas.height = height;
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
    double zFar = 80.0;
    Matrix4 m = makePerspectiveMatrix(fovYRadians,
        aspectRatio, zNear, zFar);

    Matrix4 v = makeViewMatrix(new Vector3(18.0, 18.0, 42.0),
        new Vector3(0.0, 0.0, 0.0),
        new Vector3(0.0, 1.0, 0.0));

    Matrix4 mvp = m * v;

    for (var obj in this._scene) {
      obj.draw(mvp, time);
    }
  }

  Element getElement() {
    return this._canvas;
  }

  void _onKeyDown(KeyboardEvent e) {
    switch (e.keyCode) {
      case KeyCode.LEFT:
        
        break;

      case KeyCode.RIGHT:

        break;

      case KeyCode.UP:

        break;

      case KeyCode.DOWN:

        break;
    }
  }
}


void main() {
  WebGlApp a = new WebGlApp();
  a.setSize(700, 700);
  document.body.children.add(a.getElement());
  a.startLoop();
}