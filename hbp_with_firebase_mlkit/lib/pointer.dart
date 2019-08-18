import 'package:hbp_with_firebase_mlkit/Painting/PointerDrawer.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'HeadToCursorMapping.dart';
import 'dart:collection';

class Pointer {
  Queue<int> _dwellingTimestampQueue;
  double _dwellingPercentage = 0;
  Queue<Offset> _dwellingQueue;
  int _dwellTime = 800;
  double dwellingArea = 20;
  PointerDrawer _pointerDrawer;
  HeadToCursorMapping _mapping;
  bool _highlighting = false;
  bool _dwelling = false;
  bool _pressed = false;
  bool _updated = false;
  PointerType _type;
  Offset _position;
  Size _canvasSize;
  Face _face;

  Pointer(this._canvasSize, this._face) {
    _pointerDrawer = PointerDrawer(this, _canvasSize);
    _dwellingQueue = Queue();
    _dwellingTimestampQueue = Queue();
    _mapping = HeadToCursorMapping(_canvasSize, _face);
    _position = _mapping.calculateHeadPointing();
  }

  void _resetDwelling(int moment) {
    _dwellingQueue = Queue<Offset>();
    _dwellingTimestampQueue = Queue<int>();
    _dwellingQueue.addLast(_position);
    _dwellingTimestampQueue.addLast(moment);
    _dwelling = false;
  }

  bool _isDwellLoading(int moment) {
    for (var p in _dwellingQueue) {
      if (p == null || _position == null) {
        return false;
      } else if ((p - _position).distance > dwellingArea) {
        _resetDwelling(moment);
        return false;
      }
    }
    return true;
  }

  void _dwell() {
    final moment = new DateTime.now().millisecondsSinceEpoch;
    if (_dwellingTimestampQueue.length <= 0) {
      _resetDwelling(moment);
      return;
    }
    bool dwelling = _isDwellLoading(moment);
    if (dwelling) {
      _dwellingTimestampQueue.addLast(moment);
      _dwellingQueue.addLast(_position);
      _dwellingPercentage = (moment - _dwellingTimestampQueue.first) / _dwellTime;
      if (moment - _dwellingTimestampQueue.first > _dwellTime)
          _dwelling = true;
    }
  }

  double getExactDwellDuration() {
    return _dwellingPercentage * _dwellTime / 1000;
  }

  double getDwellTime() {
    return _dwellTime / 1000;
  }

  void _updateFace(List<Face> faces, {Size size}) {
    if (faces.length <= 0)
      return;
    bool differentFace = true;
    for (var face in faces) {
      if (face.trackingId == _face.trackingId) {
        _face = face;
        differentFace = false;
        break;
      }
    }
    if (differentFace) _face = faces[0];
  }

  void updatePosition() {
    _position = _mapping.calculateHeadPointing();
  }

  void update(List<Face> faces, {targets, Size size}) {
    _updated = true;
    _updateFace(faces, size: size);
    _mapping.update(_face, size: size);
    _pointerDrawer.update(targets: targets);
    updatePosition();
    _dwell();
  }

  void draw(Canvas canvas, {targets, type: PointerType.Circle}) {
    _type = type;
    _pointerDrawer.drawPointer(canvas, type: type);
  }

  Offset getPosition() {
    return _position;
  }

  double getRadius() {
    return _pointerDrawer.getRadius();
  }

  bool touches(Offset targetCenter, double targetWidth) {
    if (_type == PointerType.Bubble)
      return (_position - targetCenter).distance - getRadius() < targetWidth;
    else
      return (_position - targetCenter).distance < targetWidth;
  }

  void setHighlighting(bool highlighting) {
    _highlighting = highlighting;
  }

  bool highlights() {
    return _highlighting;
  }

  bool pressedDown() {
    if (!_pressed  && (_face.smilingProbability > 0.9 ||
                        _face.leftEyeOpenProbability < 0.1)) {
      _pressed = true;
    }
    return _pressed;
  }

  bool dwelling() {
    return _dwelling;
  }

  double dwellingPercentage() {
    return _dwellingPercentage;
  }

  void release() {
    _dwelling = false;
    _dwellingPercentage = 0;
    _dwellingQueue = Queue();
    _pressed = false;
  }

  PointerPainter getPainter() {
    return _pointerDrawer.getPainter();
  }

  PointerType getType() {
    return _type;
  }

  bool isUpdated() {
    final answer = _updated;
    _updated = false;
    return answer;
  }

  Queue<Offset> getDwellingQueue() {
    return _dwellingQueue;
  }

}