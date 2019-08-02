import 'package:flutter/material.dart';
import 'pointer.dart';
import 'dart:math';

class TargetPaint extends CustomPaint {
  final CustomPainter painter;

  TargetPaint({this.painter}) : super(painter: painter);
}

enum TargetShape {
  RectTarget,
  CircleTarget,
}

class Target {
  Paint _style;
  TargetShape _targetShape;
  var _shape;
  var _switched = false;
  var _pressed = false;
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

  void draw(Canvas canvas, pointer) {
    if (contains(pointer)) {
      if (pointer.pressedDown()) {
        if (!_switched)
          _pressed = !_pressed;
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
    if (this._pressed)
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

class TargetBuilder {
  final Size imageSize;
  final Pointer pointer;
  List<Target> _targets = List<Target>();

  void createTargets() {
    var r = 300;
    Offset pos1 = Offset(100, 100);
    Offset pos2 = Offset(pos1.dx + (r * cos(0.5 * pi)), pos1.dx + (r * sin(0.5 * pi)));
    Offset pos3 = Offset(pos1.dx + (r * cos(0.35 * pi)), pos1.dx + (r * sin(0.35 * pi)));
    Offset pos4 = Offset(pos1.dx + (r * cos(0.20 * pi)), pos1.dx + (r * sin(0.20 * pi)));

    _targets.add(Target.fromCircle(pos1, 60));
    _targets.add(Target.fromCircle(pos2,  60));
    _targets.add(Target.fromCircle(pos3,  60));
    _targets.add(Target.fromCircle(pos4,  60));
  }

  TargetBuilder(this.imageSize, this.pointer) {
    createTargets();
  }

  void _addCircle(Canvas canvas, Offset offset, Size size,
      {double radius: 0, Paint paint}) {
    if (paint == null) paint = Paint()
      ..color = Colors.yellow;
    if (radius == 0) radius = size.width / 100;
    canvas.drawCircle(offset, radius, paint);
  }

  void _addPointer(Canvas canvas, Offset position, Size size) {
    final paintStyle = Paint()
      ..color = Colors.red
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke;

    double radius = size.width / 20;
    _addCircle(canvas, position, size, radius: radius, paint: paintStyle);
  }

  void _addTargetGrid(Canvas canvas, Size size) {
    _targets.forEach((t) => t.draw(canvas, pointer));
  }

  void paint(Canvas canvas, Size size) {
    _addTargetGrid(canvas, size);
    _addPointer(canvas, pointer.getPosition(), size);
  }

  bool shouldRepaint(TargetBuilder oldDelegate) {
    return imageSize != oldDelegate.imageSize || pointer != oldDelegate.pointer;
  }

  TargetPainter getPainter() {
    return TargetPainter(this);
  }
}

class TargetPainter extends CustomPainter {
  TargetBuilder _targetBuilder;

  TargetPainter(this._targetBuilder);

  @override
  void paint(Canvas canvas, Size size) {
    _targetBuilder.paint(canvas, size);
  }

  @override
  bool shouldRepaint(TargetPainter oldDelegate) {
    return _targetBuilder.shouldRepaint(oldDelegate.getTargetBuilder());
  }

  TargetBuilder getTargetBuilder() {
    return _targetBuilder;
  }
}
