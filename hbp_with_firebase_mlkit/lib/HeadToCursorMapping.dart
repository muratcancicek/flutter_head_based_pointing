import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'dart:collection';

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
  int smoothingFrameCount = 60;
  Queue<Offset> _smoothingQueue;
  Queue<Offset> _velocityQueue;
  Queue<Offset> _noseQueue;
  Offset _smoothedPrevNose;
  Offset _smoothedNose;
  Offset _headPointing;
  Offset _position;
  Size _imageSize;
  Offset _speed = Offset(1000.0, 30000.0);
  Face _face;

  HeadToCursorMapping(this._imageSize, this._face) {
    _imageSize = Size(420, 690); // manually detected size
    _position = Offset(_imageSize.width/2, _imageSize.width/2);
    _headPointing = _position;
    _smoothingQueue = Queue();
    for (var i = 0; i < smoothingFrameCount; i++)
      _smoothingQueue.addFirst(_position);
    _noseQueue = Queue();
    for (var i = 0; i < smoothingFrameCount; i++)
      _noseQueue.addFirst(_position);
    _velocityQueue = Queue();
    for (var i = 0; i < smoothingFrameCount; i++)
      _velocityQueue.addFirst(Offset(0, 0));
  }

  Offset _smoothNoseInput() {
    Offset nose = _face.getLandmark(FaceLandmarkType.noseBase).position;
    var xDdifference = (_noseQueue.first.dx - nose.dx);
    var yDdifference = (_noseQueue.first.dy - nose.dy);
//    print(difference);
    if (xDdifference*xDdifference < 0.0)
      return _noseQueue.first;
    else {
      _noseQueue.removeLast();
      double x = nose.dx, y = nose.dy;
      for (var p in _noseQueue) { x += p.dx; y += p.dy; }
      _smoothedPrevNose = _noseQueue.first;
      final length = _noseQueue.length + 1;
      _noseQueue.addFirst(Offset(x/length, y/length));
      _smoothedNose = _noseQueue.first;

    }
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
    return scaleX * _imageSize.width;
  }

  double _calculateXFromHeadEulerAngleY({angle: 9.0}) {
    double minX = -angle, maxX = angle;
    double scaleX = (_face.headEulerAngleY  - minX) / (maxX - minX);
    return scaleX * _imageSize.width;
  }

  double _calculateXFromNose() {
    double diff = _smoothedNose.dx - _smoothedPrevNose.dx;
//    print(diff.toString()+'o'+_headPointing.dx.toString());
    diff *= - _speed.dx;
    return _headPointing.dx + diff;
  }

  double _calculateX({method}) {
    switch (method) {
      case xAxisMode.fromCheeks:
        return _imageSize.width - _calculateXFromCheeks();
      case xAxisMode.fromHeadEulerY:
        return _imageSize.width - _calculateXFromHeadEulerAngleY();
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
    return scaleY * _imageSize.height;
  }

  double _calculateYFromNose() {
    double diff = _smoothedNose.dy - _smoothedPrevNose.dy;
    diff *= - _speed.dy;
    return _headPointing.dy + diff;
  }

  double _calculateY({method: false}) {
    switch (method) {
      case yAxisMode.fromEyeMouthSquare:
       return _imageSize.height - _calculateYFromEyeMouthSquare();
      case yAxisMode.fromNose:
        return _imageSize.height - _calculateYFromNose();
      default:
        return _imageSize.height - _calculateYFromNose();
    }
  }

  Offset _limitPosition(Offset newPosition) {
    var dx = newPosition.dx;
    if (dx >= _imageSize.width)
      dx = _imageSize.width;
    else if (newPosition.dx < 0)
      dx = 0;
    var dy = newPosition.dy;
    if (dy >= _imageSize.height)
      dy = _imageSize.height;
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
    _smoothNoseInput();
    var newHeadPointing = Offset(_calculateX(), _calculateY());
    newHeadPointing = _limitPosition(newHeadPointing);
    _headPointing = _smoothHeadPointing(newHeadPointing);
//    final velocity = newHeadPointing - _headPointing;
//    final acceleratedVelocity = addAcceleration(velocity);
//    newHeadPointing = _headPointing + acceleratedVelocity;

    _position = _headPointing;
    return _position;
  }

  void update(Face face, {Size size}) {
    _face = face;
  }
}