import 'package:vector_math/vector_math.dart';
import 'dart:typed_data';
import 'dart:html';
import 'dart:web_gl';
import 'dart:web_gl' as WebGL;
import 'dart:mirrors';
import 'dart:async';

class RenderingErrorEvent {
  /// The [WebGL] error code.
  final int error;
  /// The name of the method whose call resulted in the [error].
  final String methodName;

  RenderingErrorEvent._internal(_error, _methodName) : error = _error, methodName = _methodName {
    print('constructor called');
  }

  RenderingErrorEvent(this.error, this.methodName);

  /// Retrieves a human readable error message.
  String get message {
    var errorMessage;

    switch (error) {
      case WebGL.INVALID_ENUM:
        errorMessage = 'An unacceptable value is specified for an enumerated argument. The offending command is ignored and has no other side effect than to set the error flag.';
        break;
      case WebGL.INVALID_VALUE:
        errorMessage = 'A numeric argument is out of range. The offending command is ignored and has no other side effect than to set the error flag.';
        break;
      case WebGL.INVALID_OPERATION:
        errorMessage = 'The specified operation is not allowed in the current state. The offending command is ignored and has no other side effect than to set the error flag.';
        break;
      case WebGL.INVALID_FRAMEBUFFER_OPERATION:
        errorMessage = 'The framebuffer object is not complete. The offending command is ignored and has no other side effect than to set the error flag.';
        break;
      case WebGL.OUT_OF_MEMORY:
        errorMessage = 'There is not enough memory left to execute the command. The state of the GL is undefined, except for the state of the error flags, after this error is recorded.';
        break;
      default:
        errorMessage = 'An unknown error occurred';
        break;
    }

    return '${methodName}: ${errorMessage}';
  }
}

class DebugRenderingContext implements WebGL.RenderingContext {
  final StreamController<RenderingErrorEvent> _onErrorController;
  final WebGL.RenderingContext _gl;

  DebugRenderingContext(WebGL.RenderingContext gl)
      : _gl = gl
      , _onErrorController = new StreamController<RenderingErrorEvent>();

  Stream<RenderingErrorEvent> get onError => _onErrorController.stream;

  dynamic noSuchMethod(Invocation invocation) {
    // Invoke the method and get the result
    var mirror = reflect(_gl);
    var result = mirror.delegate(invocation);

    // See if there was an error
    var errorCode = _gl.getError();

    // Multiple errors can occur with a single call to WebGL so continue to
    // loop until WebGL doesn't return an error
    while (errorCode != WebGL.NO_ERROR) {
      if (!_onErrorController.isPaused) {
        // Query the symbol name
        var methodName = MirrorSystem.getName(invocation.memberName);

        // Put the error in the stream
        _onErrorController.add(new RenderingErrorEvent._internal(errorCode, methodName));
      }

      errorCode = _gl.getError();
    }

    return result;
  }
}

class Cube {
  Program _program;

  static const String vshader = """
attribute vec4 a_Position;
attribute vec4 a_Color;
uniform mat4 u_MvpMatrix;
varying vec4 v_Color;
void main() {
  gl_Position = u_MvpMatrix * a_Position;
  v_Color = a_Color;
}
""";

  static const String fshader = """
#ifdef GL_ES
precision mediump float;
#endif
varying vec4 v_Color;
void main() {
  gl_FragColor = v_Color;
}
""";

  RenderingContext _gl;

  Cube(RenderingContext gl) {
    this._gl = gl;

    this._program = _createProgram(this._gl,
        Cube.vshader, Cube.fshader);

    this._gl.useProgram(this._program);

    _initVertexBuffers(this._gl, this._program);

  }

  UniformLocation _u(String uniformName) {
    UniformLocation u = this._gl.getUniformLocation(this._program,
        uniformName);

    if (u == null) {
      throw new Exception("no such uniform: " + uniformName);
    }

    return u;
  }

  void draw(Matrix4 mvp) {
    this._gl.useProgram(this._program);
    this._drawCube(mvp);
    print(this._gl.getProgramInfoLog(this._program));
  }

  void _drawCube(Matrix4 mvp) {
    this._gl.uniformMatrix4fv(this._u('u_MvpMatrix'),
        false,
        mvp.storage);

    this._gl.drawElements(TRIANGLES, 36, UNSIGNED_BYTE, 0);
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

  static Program _createProgram(RenderingContext gl,
      String vShaderSource, String fShaderSource) {

    Shader vShader = _loadShader(gl, RenderingContext.VERTEX_SHADER,
        vShaderSource);

    Shader fShader = _loadShader(gl, RenderingContext.FRAGMENT_SHADER,
        fShaderSource);

    Program program = gl.createProgram();

    gl.attachShader(program, vShader);
    gl.attachShader(program, fShader);
    gl.linkProgram(program);
    return program;
  }

  static Shader _loadShader(RenderingContext gl, int type, String source) {
    Shader shader = gl.createShader(type);
    gl.shaderSource(shader, source);
    gl.compileShader(shader);
    print(gl.getShaderInfoLog(shader));
    return shader;
  }


}

class WebGlApp {
  CanvasElement _canvas;
  RenderingContext _gl;
  List _scene;

  WebGlApp() {

    this._canvas = new CanvasElement();

    this._gl = new DebugRenderingContext(this._canvas.getContext('webgl'));

    this._gl.clearColor(0, 0, 0, 1);

    this._scene = new List();

    this.addObjectToScene(new Cube(this._gl));
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
    this._redraw();
    //window.animationFrame.then(this._loop);
  }

  void _redraw() {
    this._gl.clear(COLOR_BUFFER_BIT | DEPTH_BUFFER_BIT);
    //Matrix4 m = makePerspectiveMatrix(30.0, 1.0, 1.0, 100.0);

    Matrix4 m = new Matrix4.fromList([
      3.7, 0.0, 0.0, 0.0,
      0.0, 3.7, 0.0, 0.0,
      0.0, 0.0, -1.0, -1.0,
      0.0, 0.0, -2.0, 0.0
    ]);

    Matrix4 v = makeViewMatrix(new Vector3(18.0, 18.0, 42.0),
        new Vector3(0.0, 0.0, 0.0),
        new Vector3(0.0, 1.0, 0.0));

    Matrix4 mvp = m * v;

    for (var obj in this._scene) {
      obj.draw(mvp);
    }
  }


  Element getElement() {
    return this._canvas;
  }
}


void main() {
  WebGlApp a = new WebGlApp();
  a.setSize(700, 700);
  document.body.children.add(a.getElement());
  a.startLoop();
}