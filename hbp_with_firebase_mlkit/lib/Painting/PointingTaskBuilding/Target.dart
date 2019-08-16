import 'package:flutter/material.dart';

enum TargetShape {
  RectTarget,
  CircleTarget,
}

class Target {
  Paint _style;
  TargetShape _targetShape;
  var _shape;
  var center;
  var width;
  var _switched = false;
  var pressed = false;
  var highlighted = false;

  Target.fromRect(Rect rect, {Paint givenStyle}) {
    _targetShape = TargetShape.RectTarget;
    _shape = rect;
    center = rect.center;
    width = rect.width < rect.height ? rect.width : rect.height;
    if (givenStyle == null) {
      _style = Paint()
        ..color = Colors.purple;
    } else {
      _style = givenStyle;
    }
  }

  Target.fromCircle(Offset position, double radius, {Paint givenStyle}) {
    _targetShape = TargetShape.CircleTarget;
    _shape = [position, radius];
    center = position;
    width = radius;
    if (givenStyle == null) {
      _style = Paint()
        ..color = Colors.lightGreen;
    } else {
      _style = givenStyle;
    }
  }

  double getDistanceFromPointer(pointer) {
    return (pointer.getPosition() - center).distance;
  }

  double getInnerDistanceFromPointer(pointer) {
    return (pointer.getPosition() - center).distance + width;
  }

  double getOuterDistanceFromPointer(pointer) {
    return (pointer.getPosition() - center).distance - width;
  }

  bool contains(pointer) {
    if (_targetShape == TargetShape.RectTarget)
      return _shape.contains(pointer.getPosition());
    else if (_targetShape == TargetShape.CircleTarget) {
      return pointer.touches(_shape[0], _shape[1]);
    }
    else
      return false;
  }

  void _updateState(pointer) {
    if (contains(pointer)) {
      if (pointer.dwelling() || pointer.pressedDown()){//) {
        if (!_switched)
          pressed = !pressed;
        _switched = true;
        highlighted = false;
        pointer.release();
      }
      else
        highlighted = true;
    }
    else {
      highlighted = false;
      _switched = false;
    }
  }

  void draw(Canvas canvas, pointer, {pointerRadius}) {
    _updateState(pointer);
    if (this.pressed)
      _style.color = Colors.blue;
    else
      _style.color = Colors.lightGreen;
    if (!_switched && highlighted)
      _style.color = Colors.grey;
    if (_targetShape == TargetShape.RectTarget)
      canvas.drawRect(_shape, _style);
    else if (_targetShape == TargetShape.CircleTarget)
      canvas.drawCircle(_shape[0], _shape[1], _style);
  }
}