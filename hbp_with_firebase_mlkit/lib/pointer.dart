import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:collection';

class Pointer {
  Size _imageSize;
  Face _face;
  Offset _position;
  Queue<Offset> _queue;

  Pointer(this._imageSize, this._face) {
    _queue = Queue();
    for (var i = 0; i < 50; i++)
      _queue.addFirst(Offset(_imageSize.width/2, _imageSize.width/2));
  }

  void updateFace(List<Face> faces, {Size size, CameraLensDirection direction}) {
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

  double calculateXFromCheeks() {
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

  double calculateXFromHeadEulerAngleY() {
    double minX = -15;
    double maxX = 15;
    double scaleX = (_face.headEulerAngleY - minX) / (maxX - minX);
    return scaleX * _imageSize.width;
  }

  double calculateY() {
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

  Offset _smoothPosition(Offset position) {
    _queue.addLast(position);
    _queue.removeFirst();
    double x = 0, y = 0;
    for (var p in _queue) {
      x += p.dx;
      y += p.dy;
    }
    return Offset(x/_queue.length, y/_queue.length);

  }
  Offset getPosition() {
    double dx = _imageSize.width - calculateXFromHeadEulerAngleY();
    double dy = calculateY();
    _position = Offset(dx, dy);
    return _smoothPosition(_position); // _position;
  }

  bool pressedDown() {
    return _face.smilingProbability > 0.9;
  }
  bool clicked() {
    return _face.leftEyeOpenProbability < 0.1;
  }
}