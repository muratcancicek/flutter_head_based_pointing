import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:collection';
import 'HeadToCursorMapping.dart';
import 'package:hbp_with_firebase_mlkit/Painting/PointerDrawer.dart';

class Pointer {
  HeadToCursorMapping _mapping;
  double _dwellingPercentage = 0;
  Queue<Offset> _dwellingQueue;
  int dwellingFrameCount = 40;
  double dwellingArea = 20;
  bool _dwelling = false;
  bool _pressed = false;
  bool _highlighting = false;
  PointerDrawer _pointerDrawer;
  PointerType _type;
  Offset _position;
  Size _imageSize;
  Face _face;

  Pointer(this._imageSize, this._face) {
    _pointerDrawer = PointerDrawer(this, _imageSize);
    _dwellingQueue = Queue();
    _mapping = HeadToCursorMapping(_imageSize, _face);
    for (var i = 0; i < dwellingFrameCount; i++)
      _dwellingQueue.addFirst(Offset(_imageSize.width/2, _imageSize.width/2));
  }

  void _dwell() {
    if (_dwellingQueue.length >= dwellingFrameCount) {
      _dwellingQueue.removeLast();
      bool dwelling = true;
      var dwellingFrames = 0;
      for (var p in _dwellingQueue) {
        if (_position == null)
          dwelling = false;
        else if ((p - _position).distance > dwellingArea)
          dwelling = false;
        else
          dwellingFrames++;
      }
      _dwelling = dwelling;
      _dwellingPercentage = dwellingFrames / dwellingFrameCount;
    }
    _dwellingQueue.addFirst(_position);
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

  void draw(Canvas canvas, {targets, type: PointerType.Circle}) {
    _type = type;
    _pointerDrawer.drawPointer(canvas,
        targets: targets, type: PointerType.Bubble);
  }

  Offset getPosition() {
    _position = _mapping.calculateHeadPointing();
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
//    else
//      _pressed = false;
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

}