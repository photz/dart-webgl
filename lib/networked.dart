import 'dart:convert';
import 'dart:html';

class Networked {

  String _host;
  int _port;
  WebSocket _ws;
  var _onGetStateCb;

  Networked(this._host, this._port, this._onGetStateCb) {
    _ws = new WebSocket('ws://${_host}:${_port}');
    _ws.onOpen.listen(_onOpen);
  }

  void _onOpen(e) {
    _ws.onMessage.listen(_onMessage);
  }

  void _onMessage(MessageEvent e) {
    var data = JSON.decode(e.data);
    var x = data['x'];
    var z = data['z'];
    var angle = data['angle'];
    _onGetStateCb(x, z, angle);
  }

  void _sendAsJson(obj) {
    String json = JSON.encode(obj);
    _ws.send(json);
  }

  void moveLeft() {
    _sendAsJson({
      'type': 'left'
    });
  }

  void moveRight() {
    _sendAsJson({
      'type': 'right'
    });
  }

  void forward() {
    _sendAsJson({
      'type': 'forward'
    });
  }

  void backward() {
    _sendAsJson({
      'type': 'backward'
    });
  }

  void stopFrontal() {
    _sendAsJson({
      'type': 'stop_frontal'
    });
  }

  void stopLateral() {
    _sendAsJson({
      'type': 'stop_lateral'
    });
  }

  void turn(absoluteAngle) {
    _sendAsJson({
      'type': 'turn',
      'angle': absoluteAngle
    });
  }
}
