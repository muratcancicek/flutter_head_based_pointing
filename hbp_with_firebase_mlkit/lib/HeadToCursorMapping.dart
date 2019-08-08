import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'dart:collection';

class HeadToCursorMapping {
  Size _imageSize;
  Face _face;
  Offset _headPointing;
  Offset _position;
  Queue<Offset> _smoothingQueue;
  Queue<Offset> _velocityQueue;
  int smoothingFrameCount = 60;

  HeadToCursorMapping(this._imageSize, this._face) {
    _imageSize = Size(420, 690); // manually detected size
    _position = Offset(_imageSize.width/2, _imageSize.width/2);
    _headPointing = _position;
    _smoothingQueue = Queue();
    for (var i = 0; i < smoothingFrameCount; i++)
      _smoothingQueue.addFirst(_position);
    _velocityQueue = Queue();
    for (var i = 0; i < smoothingFrameCount; i++)
      _velocityQueue.addFirst(Offset(0, 0));
  }

  double _calculateXFromCheeks() {
    Offset nose = _face.getLandmark(FaceLandmarkType.noseBase).position;
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

  double _calculateX({bool useHeadEulerAngleY = true}) {
    if (useHeadEulerAngleY)
      return _imageSize.width - _calculateXFromHeadEulerAngleY();
    else
      return _imageSize.width - _calculateXFromCheeks();
  }

  double _calculateY() {
    Offset nose = _face.getLandmark(FaceLandmarkType.noseBase).position;
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
    var newHeadPointing = Offset(_calculateX(), _calculateY());
//    final velocity = newHeadPointing - _headPointing;
//    final acceleratedVelocity = addAcceleration(velocity);
//    newHeadPointing = _headPointing + acceleratedVelocity;
    _headPointing = _smoothHeadPointing(newHeadPointing);
    final newPosition = _headPointing;
    _position = _limitPosition(newPosition);
    return _position;
  }

  void update(Face face, {Size size}) {
    _face = face;
  }
}