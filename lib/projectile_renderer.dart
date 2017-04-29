import 'dart:typed_data';
import 'dart:web_gl';

import 'package:vector_math/vector_math.dart';

import 'package:webgltest/load_shader.dart';
import 'package:webgltest/projectile.dart';
import 'package:webgltest/model.dart';
import 'package:webgltest/utils.dart';

class ProjectileRenderer {
  final RenderingContext _gl;
  Program _program;
  Buffer _buffer;

  ProjectileRenderer(RenderingContext this._gl) {
    String vshader = myLoadShader('sphere.vert');
    String fshader = myLoadShader('sphere.frag');

    _program = createProgram(_gl, vshader, fshader);
    _gl.useProgram(_program);
    Model model = new Model.fromObj(myLoadModel('sphere.obj'));
    _buffer = _fillBufferWithModelData(model);
    _setUpPointers();

    assert(_gl.isProgram(_program));
    assert(_gl.isBuffer(_buffer));
  }

  /// Renders projectiles 
  void render(Matrix4 viewMatrix, List<Projectile> projectiles) {
    _gl.useProgram(_program);
    _setUpPointers();

    _gl.uniform3fv(_u('u_Color'),
        (new Vector3(1.0, 0.0, 0.0)).storage);
    _gl.uniform3fv(_u('u_LightColor'),
        (new Vector3(1.0, 1.0, 1.0)).storage);
    _gl.uniform3fv(_u('u_LightPosition'),
        (new Vector3(10.0, 0.0, 0.0)).storage);
    _gl.uniform3fv(_u('u_AmbientLight'),
        (new Vector3(1.0, 1.0, 1.0)).storage);
    _gl.uniformMatrix4fv(_u('u_ViewMatrix'),
        false,
        viewMatrix.storage);

    projectiles.forEach(_renderProjectile);
  }

  /// Renders a single projectile
  void _renderProjectile(Projectile projectile) {
    Matrix4 modelMatrix = new Matrix4.translation(projectile.coords);
    
    modelMatrix.scale(0.2);

    _gl.uniformMatrix4fv(_u('u_ModelMatrix'),
        false, modelMatrix.storage);


    Matrix4 normalMatrix = new Matrix4.inverted(modelMatrix);
    normalMatrix.transpose();

    UniformLocation u_NormalMatrix = _u('u_NormalMatrix');


    _gl.uniformMatrix4fv(u_NormalMatrix,
        false, normalMatrix.storage);


    const int nFaces = 224;
    _gl.drawArrays(TRIANGLES, 0, nFaces * 3);
  }

  Buffer _fillBufferWithModelData(Model model) {
    Float32List positionsNormals = model.positionsAndNormalsToArr();

    Buffer buffer = _gl.createBuffer();

    _gl.bindBuffer(ARRAY_BUFFER, buffer);
    _gl.bufferData(ARRAY_BUFFER, positionsNormals, STATIC_DRAW);

    return buffer;
  }

  void _setUpPointers() {
    _gl.bindBuffer(ARRAY_BUFFER, _buffer);
    _gl.vertexAttribPointer(this._a('a_Position'),
        3,
        FLOAT,
        false,
        6 * Float32List.BYTES_PER_ELEMENT,
        0);
    _gl.enableVertexAttribArray(this._a('a_Position'));

    _gl.vertexAttribPointer(this._a('a_Normal'),
        3,
        FLOAT,
        false,
        6 * Float32List.BYTES_PER_ELEMENT,
        3 * Float32List.BYTES_PER_ELEMENT);
    _gl.enableVertexAttribArray(this._a('a_Normal'));
  }

  int _a(String attribName) {
    final int attribLocation = _gl.getAttribLocation(_program,
        attribName);

    if (-1 == attribLocation) {
      throw new Exception('no such attribute: ' + attribName);
    }

    return attribLocation;
  }

  UniformLocation _u(String uniformName) {
    UniformLocation u = _gl.getUniformLocation(_program,
        uniformName);

    if (u == null) {
      throw new Exception("no such uniform: " + uniformName);
    }

    return u;
  }

}
