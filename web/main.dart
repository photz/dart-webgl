import 'dart:typed_data';
import 'dart:html';
import 'dart:web_gl';
import 'web_gl_debug.dart';
import 'dart:math' as Math;

import 'package:vector_math/vector_math.dart';

import 'package:webgltest/cube.dart';
import 'package:webgltest/networked.dart';
import 'package:webgltest/grid.dart';
import 'package:webgltest/scene.dart' as scene;
import 'package:webgltest/projectile.dart';
import 'package:webgltest/projectile_renderer.dart';


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
  final List<Projectile> _projectiles = [];
  ProjectileRenderer _projectileRenderer;
  Networked _nw;
  bool _upKeyPressed = false;
  bool _downKeyPressed = false;
  bool _leftKeyPressed = false;
  bool _rightKeyPressed = false;
  double _lastAngleTransmitted = 0.0;
  String _playerEntityId = '';

  WebGlApp(int width, int height) {

    _nw = new Networked('127.0.0.1', 4000, _onConnectionEstablished, _onGetState);

    this._canvas = new CanvasElement();

    this._canvas.width = width;
    this._canvas.height = height;


    this._gl = new DebugRenderingContext(this._canvas.getContext('webgl'));

    final Vector4 skyBlue = new Vector4(197.0 / 255.0,
        224.0 / 255.0, 220.0 / 255.0, 0.0);

    this._gl.clearColor(skyBlue.x, skyBlue.y, skyBlue.z, skyBlue.w);

    this._scene = new scene.Scene();


    this._grid = new Grid.create(this._gl);

    _player = new Cube.create(this._gl, 0, 0,
        new Vector3(1.0, 0.0, 0.0));

    _scene.addToScene('player-has-no-entity-id-yet', _player);

    _projectileRenderer = new ProjectileRenderer(_gl);

    this._gl.enable(DEPTH_TEST);

    this._ambientLightColor = new Vector3(0.05, 0.05, 0.05);
    this._lightDirection = new Vector3(0.5, 3.0, 4.0);
    this._lightColor = new Vector3(1.0, 1.0, 1.0);
  }

  void _onConnectionEstablished() {
    document.body.onMouseDown.listen(this._onMouseDown);
    document.onVisibilityChange.listen(this._onVisibilityChange);
    document.body.onKeyUp.listen(this._onKeyUp);
    window.onKeyDown.listen(this._onKeyDown);
    document.onPointerLockChange.listen(_onLockChange);
    document.onPointerLockError.listen(_onLockError);
    document.body.onMouseMove.listen(_onMouseMove);
  }

  void _onLockError(e) {
    // unable to lock the pointer
  }

  void _onLockChange(e) {
    // pointer lock was changed occured
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

        Vector4 testVec = new Vector4(0.0, 0.0, 1.0, 0.0);

        testVec = mat * testVec;

        cameraFocusPosition = playerCoords + testVec.xyz;
        break;
        
      case ViewMode.THIRD_PERSON:
        const double distance = 20.0;

        Vector4 test = new Vector4(0.0, 0.0, distance, 1.0);

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


    _projectiles.retainWhere((p) => p.coords.x.abs() < 100.0 &&
        p.coords.y.abs() < 100.0 &&
        p.coords.z.abs() < 100.0);
    _projectiles.forEach((p) => p.updatePosition());
    _projectileRenderer.render(mvp, _projectiles);

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

    _nw.createBlock(pos.x.round(),
        0,
        pos.z.round());
  }

  void _onKeyUp(KeyboardEvent e) {
    switch (e.keyCode) {
      case KeyCode.UP:
      case KeyCode.W:
        _nw.stopFrontal();
        _player.stopMovingForward();
        _upKeyPressed = false;
        break;

      case KeyCode.DOWN:
      case KeyCode.S:
        _nw.stopFrontal();
        _player.stopMovingBackward();
        _downKeyPressed = false;
        break;

      case KeyCode.LEFT:
      case KeyCode.A:
        _nw.stopLateral();
        _player.stopMovingLeft();
        _leftKeyPressed = false;
        break;

      case KeyCode.RIGHT:
      case KeyCode.D:
        _nw.stopLateral();
        _player.stopMovingRight();
        _rightKeyPressed = false;
        break;
    }
  }

  void _onKeyDown(KeyboardEvent e) {
    switch (e.keyCode) {
      case KeyCode.UP:
      case KeyCode.W:
        if (!_upKeyPressed) {
          _nw.forward();
          _player.setMovingForward();
          _upKeyPressed = true;
        }
        break;

      case KeyCode.DOWN:
      case KeyCode.S:
        if (!_downKeyPressed) {
          _nw.backward();
          _player.setMovingBackward();
          _downKeyPressed = true;
        }
        break;

      case KeyCode.LEFT:
      case KeyCode.A:
        if (!_leftKeyPressed) {
          _player.setMovingLeft();
          _leftKeyPressed = true;
          _nw.moveLeft();
        }
        break;

      case KeyCode.RIGHT:
      case KeyCode.D:
        if (!_rightKeyPressed) {
          _nw.moveRight();
          _player.setMovingRight();
          _rightKeyPressed = true;
        }
        break;

      case KeyCode.SPACE:
        _player.jump();
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
    var newAngle = _player.angle - e.movement.x / 40;

    _player.setAngle(newAngle);

    if (0.3 < (newAngle - _lastAngleTransmitted).abs()) {
      _nw.turn(newAngle);
    }
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

  void _updateEntities(pointMasses, orientations) {
    pointMasses.forEach((entityId, pointMass) {

      if (!(entityId is String)) {
        throw new Exception('entityId not a string');
      }

      var angle = orientations[entityId]['angle'];

      if (entityId == _playerEntityId) {

      }
      else if (_scene.entityIdExists(entityId)) {

        var entity = _scene.getByEntityId(entityId);
        entity.setWorldCoordinates(pointMass['position']['x'],
            pointMass['position']['z']);
        entity.setAngle(angle);
      }
      else {
        var newEntity = new Cube.create(_gl,
            pointMass['position']['x'],
            pointMass['position']['z'],
            new Vector3(1.0, 1.0, 0.8));

        newEntity.setAngle(angle);

        _scene.addToScene(entityId, newEntity);
      }
    });
  }

  void _onGetState(String entityId, pointMasses, orientations) {
    _playerEntityId = entityId;
    _updateEntities(pointMasses, orientations);
  }

  void _onMouseDown(MouseEvent e) {

    _canvas.requestPointerLock();

    Vector3 initialPos = _player.coords + new Vector3(0.0, 0.5, 0.0);

    Projectile p = new Projectile(_player,
        initialPos, _player.forward);

    _projectiles.add(p);
  }
}

void main() {
  WebGlApp a = new WebGlApp(window.innerWidth, window.innerHeight);
  document.body.children.add(a.getElement());
  a.startLoop();
}
