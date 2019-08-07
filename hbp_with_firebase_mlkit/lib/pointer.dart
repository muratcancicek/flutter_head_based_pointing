import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:collection';

class Pointer {
  Size _imageSize;
  Face _face;
  Offset _position;
  Queue<Offset> _smoothingQueue;
  int smoothingFrameCount = 30;
  Queue<Offset> _dwellingQueue;
  int dwellingFrameCount = 40;
  double dwellingArea = 20;
  bool _dwelling = false;

  Pointer(this._imageSize, this._face) {
//    , {dwellingFrameCount=60, dwellingArea=15}
//    this.dwellingFrameCount = dwellingFrameCount;
//    this.dwellingArea = dwellingArea;
    _smoothingQueue = Queue();
    for (var i = 0; i < dwellingFrameCount; i++)
      _smoothingQueue.addFirst(Offset(_imageSize.width/2, _imageSize.width/2));
    _dwellingQueue = Queue();
    for (var i = 0; i < dwellingFrameCount; i++)
      _dwellingQueue.addFirst(Offset(_imageSize.width/2, _imageSize.width/2));
  }

//  double _calculateXFromCheeks() {
//    Offset nose = _face.getLandmark(FaceLandmarkType.noseBase).position;
//    Offset leftCheek = _face.getLandmark(FaceLandmarkType.leftCheek).position;
//    Offset rightCheek = _face.getLandmark(FaceLandmarkType.rightCheek).position;
//    if (rightCheek.dx < leftCheek.dx) {
//      Offset temp = rightCheek; rightCheek = leftCheek; leftCheek = temp;
//    }
//    double range = (rightCheek.dx - leftCheek.dx) / 2;
//    double minX = leftCheek.dx + range / 2;
//    double maxX = rightCheek.dx - range / 2;
//    double scaleX = (nose.dx - minX) / (maxX - minX);
//    return scaleX * _imageSize.width;
//  }

  double _calculateXFromHeadEulerAngleY() {
    double minX = -15;
    double maxX = 15;
    double scaleX = (_face.headEulerAngleY  - minX) / (maxX - minX);
    return scaleX * _imageSize.width;
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

  Offset _calculateHeadPointing() {
    double dx = _imageSize.width - _calculateXFromHeadEulerAngleY();
    double dy = _calculateY();
    return Offset(dx, dy);
  }

  void _updateCursor() {
    final headPointing = _calculateHeadPointing();
    _smoothingQueue.addLast(headPointing);
    _smoothingQueue.removeFirst();
    double x = 0, y = 0;
    for (var p in _smoothingQueue) {
      x += p.dx;
      y += p.dy;
    }
    _position = Offset(x/_smoothingQueue.length, y/_smoothingQueue.length);
  }

  void _dwell() {
    _dwellingQueue.removeFirst();
    bool dwelling = true;
    for (var p in _dwellingQueue) {
      if (_position == null)
        dwelling = false;
      else if ((p - _position).distance > dwellingArea)
        dwelling = false;
    }
    _dwelling = dwelling;
    _dwellingQueue.addLast(_position);
  }

  void _updateFace(List<Face> faces, {Size size, CameraLensDirection direction}) {
    bool differentFace = true;
    for (var face in faces) {
      if (face.trackingId == _face.trackingId) {
        _face = face;
        differentFace = false;
        break;
      }
    }
    if (differentFace) _face = faces[0];
    if (size != null) _imageSize = size;
  }
  void update(List<Face> faces, {Size size, CameraLensDirection direction}) {
    _updateFace(faces, size: size, direction: direction);
    _updateCursor();
    _dwell();
  }

  Offset getPosition() {
    return _position; // _position;
  }

  bool pressedDown() {
    return _face.smilingProbability > 0.9 || _face.leftEyeOpenProbability < 0.1;
  }
  bool dwelled() {
    return _dwelling;
  }
}