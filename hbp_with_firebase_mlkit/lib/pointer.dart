import 'package:hbp_with_firebase_mlkit/Painting/PointerDrawer.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'HeadToCursorMapping.dart';
import 'dart:collection';

enum SelectionMode {
  Dwelling,
  Blinking,
  LeftWinking,
  RightWinking,
  Smalling,
}

class Pointer {
  List<SelectionMode> _enabledSelectionModes;
  SelectionMode _lastFiredSelectionMode;
  Queue<int> _dwellingTimestampQueue;
  double _dwellingPercentage = 0;
  Queue<Offset> _dwellingQueue;
  int _dwellTime = 800;
  double _dwellingArea = 20;
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

  Pointer(this._canvasSize, this._face,
      {PointerType type: PointerType.Circle,
        List<SelectionMode> enabledSelectionModes}) {
    _enabledSelectionModes = enabledSelectionModes == null
        ? SelectionMode.values : enabledSelectionModes;
    _mapping = HeadToCursorMapping(_canvasSize, _face);
    _position = _mapping.calculateHeadPointing();
    _pointerDrawer = PointerDrawer(this, _canvasSize);
    _dwellingTimestampQueue = Queue();
    _dwellingQueue = Queue();
    _type = type;
  }

  void _updateFace(List<Face> faces, {Size size}) {
    if (faces.length <= 0)
      return;
    bool differentFace = true;
    if (_face == null) {
      _face = faces[0];
    }
    for (var face in faces) {
      if (face.trackingId == _face.trackingId) {
        _face = face;
        differentFace = false;
        break;
      }
    }
    if (differentFace) _face = faces[0];
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
      } else if ((p - _position).distance > _dwellingArea) {
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

  void updatePosition() {
    _position = _mapping.calculateHeadPointing();
  }

  void update(List<Face> faces, {targets, Size size}) {
    _updated = true;
    if (faces != null)
      if (faces.length > 0) {
        _updateFace(faces, size: size);
        _mapping.update(_face, size: size);
        _pointerDrawer.update(targets: targets);
        updatePosition();
        _dwell();
      }
  }

  void draw(Canvas canvas, {targets, type: PointerType.Circle}) {
    _type = type;
    _pointerDrawer.drawPointer(canvas, type: type);
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

  bool isDwelling() => _dwelling;

  bool isLeftWinking() =>
      _face.leftEyeOpenProbability < 0.1 && _face.rightEyeOpenProbability > 0.5;

  bool isRightWinking() =>
      _face.rightEyeOpenProbability < 0.1 && _face.leftEyeOpenProbability > 0.5;

  bool isBlinking() =>
      _face.leftEyeOpenProbability < 0.1 && _face.rightEyeOpenProbability < 0.1;

  bool isSmiling() => _face.smilingProbability > 0.9;

  bool fireSelection() {
    if (_pressed)
      return false;
    bool select = false;
    if (_enabledSelectionModes.contains(SelectionMode.LeftWinking))
      if (isLeftWinking()) {
        select = true;
        _lastFiredSelectionMode = SelectionMode.LeftWinking;
      }
    if (_enabledSelectionModes.contains(SelectionMode.RightWinking))
      if (isLeftWinking()) {
        select = true;
        _lastFiredSelectionMode = SelectionMode.RightWinking;
      }
    if (_enabledSelectionModes.contains(SelectionMode.Blinking))
      if (isBlinking()) {
        select = true;
        _lastFiredSelectionMode = SelectionMode.Blinking;
      }
    if (_enabledSelectionModes.contains(SelectionMode.Smalling))
      if (isSmiling()) {
        select = true;
        _lastFiredSelectionMode = SelectionMode.Smalling;
      }
    if (_enabledSelectionModes.contains(SelectionMode.Dwelling))
      if (isDwelling()) {
        select = true;
        _lastFiredSelectionMode = SelectionMode.Dwelling;
      }
    _pressed = select;
    return _pressed;
  }

  void release() {
    _dwelling = false;
    _dwellingPercentage = 0;
    _dwellingQueue = Queue();
    _pressed = false;
  }

  bool isUpdated() {
    final answer = _updated;
    _updated = false;
    return answer;
  }

  PointerType getType() => _type;

  Offset getPosition() => _position;

  bool highlights() => _highlighting;

  Size getCanvasSize() => _canvasSize;

  double getRadius() => _pointerDrawer.getRadius();

  PointerPainter getPainter() => _pointerDrawer.getPainter();

  SelectionMode getLastFiredSelectionMode() => _lastFiredSelectionMode;

  List<SelectionMode> getEnabledSelectionModes() => _enabledSelectionModes;

  double getDwellRadius() => _dwellingArea;

  double getDwellTime() => _dwellTime / 1000;

  Queue<Offset> getDwellingQueue() => _dwellingQueue;

  double getDwellingPercentage() => _dwellingPercentage;

  double getExactDwellDuration()  => _dwellingPercentage * _dwellTime / 1000;

  List<double> _offsetToList(Offset o) => [o.dx, o.dy];

  Map<String, dynamic> mappingInformation() => {
    '"PointerSpeed"': _offsetToList(_mapping.getSpeed()),
    '"MotionThreshold"': _offsetToList(_mapping.getMotionThreshold()),
    '"DownSamplingRate"': _mapping.getDownSamplingRate(),
    '"SmoothingFrameCount"': _mapping.getSmoothingFrameCount(),
    '"XAxisMode"': '"'+_mapping.getXAxisMode().toString()+'"',
    '"YAxisMode"': '"'+_mapping.getYAxisMode().toString()+'"',
  };
}