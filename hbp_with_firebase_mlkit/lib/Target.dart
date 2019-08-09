import 'package:flutter/material.dart';

enum TargetShape {
  RectTarget,
  CircleTarget,
}

class Target {
  Paint _style;
  TargetShape _targetShape;
  var _shape;
  var _switched = false;
  var pressed = false;
  var _highlighted = false;
  Target.fromRect(Rect rect, {Paint givenStyle}) {
    _targetShape = TargetShape.RectTarget;
    _shape = rect;
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
    if (givenStyle == null) {
      _style = Paint()
        ..color = Colors.lightGreen;
    } else {
      _style = givenStyle;
    }
  }

  bool contains(pointer) {
    if (_targetShape == TargetShape.RectTarget)
      return _shape.contains(pointer.getPosition());
    else if (_targetShape == TargetShape.CircleTarget) {
      return (pointer.getPosition() - _shape[0]).distance < _shape[1];
    }
    else
      return false;
  }

  void _updateState(pointer) {
    if (contains(pointer)) {
      if (pointer.dwelled()) {// {|| pointer.pressedDown())
        if (!_switched)
          pressed = !pressed;
        _switched = true;
        _highlighted = false;
      }
      else
        _highlighted = true;
    }
    else {
      _highlighted = false;
      _switched = false;
    }
  }

  void draw(Canvas canvas, pointer) {
    _updateState(pointer);
    if (this.pressed)
      _style.color = Colors.blue;
    else
      _style.color = Colors.lightGreen;
    if (!_switched && _highlighted)
      _style.color = Colors.white;
    if (_targetShape == TargetShape.RectTarget)
      canvas.drawRect(_shape, _style);
    else if (_targetShape == TargetShape.CircleTarget)
      canvas.drawCircle(_shape[0], _shape[1], _style);
  }
}