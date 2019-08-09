import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:collection';
import 'HeadToCursorMapping.dart';

class Pointer {
  Size _imageSize;
  Face _face;
  HeadToCursorMapping _mapping;
  Offset _position;
  double _radius;
  Queue<Offset> _dwellingQueue;
  int dwellingFrameCount = 40;
  double dwellingArea = 20;
  bool _dwelling = false;

  Pointer(this._imageSize, this._face) {
    _dwellingQueue = Queue();
    _mapping = HeadToCursorMapping(_imageSize, _face);
    _radius = _imageSize.width / 20;
    for (var i = 0; i < dwellingFrameCount; i++)
      _dwellingQueue.addFirst(Offset(_imageSize.width/2, _imageSize.width/2));
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
  }
  void update(List<Face> faces, {Size size, CameraLensDirection direction}) {
    _updateFace(faces, size: size, direction: direction);
    _mapping.update(_face, size: _imageSize);
    _dwell();
  }

  Offset getPosition() {
    _position = _mapping.calculateHeadPointing();
    return _position;
  }

  void updateRadius(double radius) {
    _radius = radius;
  }

  double getRadius() {
    return _radius;
  }

  bool pressedDown() {
    return _face.smilingProbability > 0.9 || _face.leftEyeOpenProbability < 0.1;
  }
  bool dwelled() {
    return _dwelling;
  }
}