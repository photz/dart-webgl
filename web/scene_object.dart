import 'dart:web_gl';

class SceneObject {

  final RenderingContext _gl;
  Program _program;

  Program get program => _program;
  RenderingContext get gl => _gl;

  SceneObject(RenderingContext gl, String vshader, String fshader) : _gl = gl {
    this._program = _createProgram(gl, vshader, fshader);
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