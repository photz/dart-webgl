import 'dart:convert';
import 'dart:html';

class Networked {

  String _host;
  int _port;
  WebSocket _ws;
  var _onGetStateCb;
  var _onOpenCb;

  Networked(this._host, this._port, this._onOpenCb, this._onGetStateCb) {
    _ws = new WebSocket('ws://${_host}:${_port}');
    _ws.onOpen.listen(_onOpen);
  }

  void _onOpen(e) {
    _onOpenCb();
    _ws.onMessage.listen(_onMessage);
  }

  void _onMessage(MessageEvent e) {
    var data = JSON.decode(e.data);

    var entityId = data['entity_id'];
    var pointMasses = data['point_masses'];
    var orientations = data['orientations'];

    _onGetStateCb(entityId.toString(), pointMasses, orientations);
  }

  void _sendAsJson(obj) {
    String json = JSON.encode(obj);
    _ws.send(json);
  }

  void moveLeft() {
    _sendAsJson({
      'msg_type': 'left'
    });
  }

  void moveRight() {
    _sendAsJson({
      'msg_type': 'right'
    });
  }

  void forward() {
    _sendAsJson({
      'msg_type': 'forward'
    });
  }

  void backward() {
    _sendAsJson({
      'msg_type': 'backward'
    });
  }

  void stopFrontal() {
    _sendAsJson({
      'msg_type': 'stop_frontal'
    });
  }

  void stopLateral() {
    _sendAsJson({
      'msg_type': 'stop_lateral'
    });
  }

  void turn(absoluteAngle) {
    _sendAsJson({
      'msg_type': 'turn',
      'angle': absoluteAngle
    });
  }
}
