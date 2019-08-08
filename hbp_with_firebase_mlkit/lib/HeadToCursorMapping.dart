import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'dart:collection';

class HeadToCursorMapping {
  Size _imageSize;
  Face _face;
  Offset _position;
  Queue<Offset> _smoothingQueue;
  int smoothingFrameCount = 30;

  HeadToCursorMapping(this._imageSize, this._face) {
    _smoothingQueue = Queue();
    for (var i = 0; i < smoothingFrameCount; i++)
      _smoothingQueue.addFirst(Offset(_imageSize.width/2, _imageSize.width/2));
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

  double _calculateXFromHeadEulerAngleY() {
    double minX = -15;
    double maxX = 15;
    double scaleX = (_face.headEulerAngleY  - minX) / (maxX - minX);
    return scaleX * _imageSize.width;
  }

  double _calculateX({bool useHeadEulerAngleY = false}) {
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
    double scaleY = (nose.dy - minY) / (maxY - minY);
    return scaleY * _imageSize.height;
  }

  Offset calculateHeadPointing() {
    final headPointing = Offset(_calculateX(), _calculateY());
    _smoothingQueue.addLast(headPointing);
    _smoothingQueue.removeFirst();
    double x = 0, y = 0;
    for (var p in _smoothingQueue) {
      x += p.dx;
      y += p.dy;
    }
    _position = Offset(x/_smoothingQueue.length, y/_smoothingQueue.length);
    return _position;
  }

  void update(Face face, {Size size}) {
    _face = face;
//    if (size != null) _imageSize = size;
//    _calculateHeadPointing();
  }
}