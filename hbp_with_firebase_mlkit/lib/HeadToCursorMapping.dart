import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'dart:collection';

double abs(double a) {
  return a >= 0 ? a: -a;
}
enum xAxisMode {
  fromCheeks,
  fromHeadEulerY,
  fromNose
}

enum yAxisMode {
  fromEyeMouthSquare,
  fromNose
}

class HeadToCursorMapping {
  int _frames = 0;
  int _downSamplingRate = 1;
  int _smoothingFrameCount = 3;
  Queue<Offset> _smoothingQueue;
  Queue<Offset> _velocityQueue;
  Queue<Offset> _noseQueue;
  Offset _smoothedPrevNose;
  Offset _smoothedNose;
  Offset _headPointing;
  Offset _position;
  Size _canvasSize;
  Offset _speed = Offset(6.0, 8.0);
  Offset _motionThreshold = Offset(5.0, 5.0);
  xAxisMode _xAxisMode = xAxisMode.fromNose;
  yAxisMode _yAxisMode = yAxisMode.fromNose;
  Face _face;

  HeadToCursorMapping(this._canvasSize, this._face) {
    _position = Offset(_canvasSize.width/2, _canvasSize.height/2);
    _headPointing = _position;
    _smoothingQueue = Queue();
    for (var i = 0; i < _smoothingFrameCount; i++)
      _smoothingQueue.addFirst(_position);
    _noseQueue = Queue();
    for (var i = 0; i < _smoothingFrameCount; i++)
      _noseQueue.addFirst(_position);
    _velocityQueue = Queue();
    for (var i = 0; i < _smoothingFrameCount; i++)
      _velocityQueue.addFirst(Offset(0, 0));
  }

  Offset _smoothNoseInput() {
    Offset nose = _face.getLandmark(FaceLandmarkType.noseBase).position;
    _noseQueue.removeLast();
    double x = nose.dx, y = nose.dy;
    for (var p in _noseQueue) { x += p.dx; y += p.dy; }
    _smoothedPrevNose = _noseQueue.first;
    final length = _noseQueue.length + 1;
    _noseQueue.addFirst(Offset(x/length, y/length));
    _smoothedNose = _noseQueue.first;
    return _smoothedNose;
  }

  double _calculateXFromCheeks() {
    Offset nose = _smoothedNose;// _face.getLandmark(FaceLandmarkType.noseBase).position;
    Offset leftCheek = _face.getLandmark(FaceLandmarkType.leftCheek).position;
    Offset rightCheek = _face.getLandmark(FaceLandmarkType.rightCheek).position;
    if (rightCheek.dx < leftCheek.dx) {
      Offset temp = rightCheek; rightCheek = leftCheek; leftCheek = temp;
    }
    double range = (rightCheek.dx - leftCheek.dx) / 2;
    double minX = leftCheek.dx + range / 2;
    double maxX = rightCheek.dx - range / 2;
    double scaleX = (nose.dx - minX) / (maxX - minX);
    return scaleX * _canvasSize.width;
  }

  double _calculateXFromHeadEulerAngleY({angle: 9.0}) {
    double minX = -angle, maxX = angle;
    double scaleX = (_face.headEulerAngleY  - minX) / (maxX - minX);
    return scaleX * _canvasSize.width;
  }

  double _calculateXFromNose() {
    double diff = _smoothedNose.dx - _smoothedPrevNose.dx;
    diff = (diff / _face.boundingBox.width) * _canvasSize.width;
    diff *= - _speed.dx;
    return _headPointing.dx + diff;
  }

  double _calculateX({method}) {
    _xAxisMode = method == null ? _xAxisMode : method;
    switch (_xAxisMode) {
      case xAxisMode.fromCheeks:
        return _canvasSize.width - _calculateXFromCheeks();
      case xAxisMode.fromHeadEulerY:
        return _canvasSize.width - _calculateXFromHeadEulerAngleY();
      case xAxisMode.fromNose:
        return _calculateXFromNose();
      default:
        return _calculateXFromNose();
    }
  }

  double _calculateYFromEyeMouthSquare() {
    Offset nose = _smoothedNose; // _face.getLandmark(FaceLandmarkType.noseBase).position;
    Offset leftEye = _face.getLandmark(FaceLandmarkType.leftEye).position;
    Offset rightEye = _face.getLandmark(FaceLandmarkType.rightEye).position;
    double topY = (leftEye.dy + rightEye.dy) / 2;
    Offset mouth = _face.getLandmark(FaceLandmarkType.bottomMouth).position;
    double range = (mouth.dy - topY) / 2;
    double minY = topY + range / 2;
    double maxY = mouth.dy - range / 2;
    double scaleY = (nose.dy - minY) / ((maxY - minY)/1.6);
    return scaleY * _canvasSize.height;
  }

  double _calculateYFromNose() {
    double diff = _smoothedNose.dy - _smoothedPrevNose.dy;
    diff = (diff / _face.boundingBox.height) * _canvasSize.height;
//    print(diff.toString()+' '+_headPointing.dy.toString());
    diff *= _speed.dy;
    return _headPointing.dy + diff;
  }

  double _calculateY({method}) {
    _yAxisMode = method == null ? _yAxisMode : method;
    switch (_yAxisMode) {
      case yAxisMode.fromEyeMouthSquare:
       return _canvasSize.height - _calculateYFromEyeMouthSquare();
      case yAxisMode.fromNose:
        return _calculateYFromNose();
      default:
        return _calculateYFromNose();
    }
  }

  Offset _applyMotionThreshold(Offset newPointing) {
    var dx = newPointing.dx;
    if (abs(newPointing.dx - _headPointing.dx) < _motionThreshold.dx)
      dx = _headPointing.dx;
    var dy = newPointing.dy;
    if (abs(newPointing.dy - _headPointing.dy) < _motionThreshold.dy)
      dy = _headPointing.dy;
    return Offset(dx, dy);
  }

  Offset _limitPosition(Offset newPosition) {
    var dx = newPosition.dx;
    if (dx >= _canvasSize.width)
      dx = _canvasSize.width;
    else if (newPosition.dx < 0)
      dx = 0;
    var dy = newPosition.dy;
    if (dy >= _canvasSize.height)
      dy = _canvasSize.height;
    else if (newPosition.dy < 0)
      dy = 0;
    return Offset(dx, dy);
  }

  Offset _smoothHeadPointing(Offset newHeadPointing) {
    _smoothingQueue.addLast(newHeadPointing);
    _smoothingQueue.removeFirst();
    double x = 0, y = 0;
    for (var p in _smoothingQueue) {
      x += p.dx;
      y += p.dy;
    }
    return Offset(x/_smoothingQueue.length, y/_smoothingQueue.length);
  }

  Offset addAcceleration(velocity) {
    _velocityQueue.addLast(velocity);
    _velocityQueue.removeFirst();
    double x = 0, y = 0;
    var i = 0;
    for (var v in _velocityQueue) {
      x += (i*1.2/_velocityQueue.length) * v.dx;
      y += (i*1.2/_velocityQueue.length) * v.dy;
      i++;
    }
    return Offset(x/_velocityQueue.length, y/_velocityQueue.length);
  }

  Offset calculateHeadPointing() {
    if (_face != null) {
      _smoothNoseInput();
      var newHeadPointing = Offset(_calculateX(), _calculateY());
      newHeadPointing = _limitPosition(newHeadPointing);
      newHeadPointing = _applyMotionThreshold(newHeadPointing);
      _headPointing = _smoothHeadPointing(newHeadPointing);
//    final velocity = newHeadPointing - _headPointing;
//    final acceleratedVelocity = addAcceleration(velocity);
//    newHeadPointing = _headPointing + acceleratedVelocity;
      _position = _headPointing;
    }
    return _position;
  }

  void update(Face face, {Size size}) {
    if (_frames++ == _downSamplingRate) {
      _face = face;
      _frames = 0;
    }
  }

  Offset getSpeed() => _speed;

  Offset getMotionThreshold() => _motionThreshold;

  int getDownSamplingRate() => _downSamplingRate;

  int getSmoothingFrameCount() => _smoothingFrameCount;

  xAxisMode getXAxisMode() => _xAxisMode;

  yAxisMode getYAxisMode() => _yAxisMode;
}