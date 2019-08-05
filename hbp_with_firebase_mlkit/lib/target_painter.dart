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
      if (pointer.pressedDown() || pointer.clicked()) {
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
    Size _canvasSize = Size(640, 360);
    List<Target> _targets = List<Target>();

    List<double> detectSubspace(Offset center) {
     var subspace = 4.0;
     var arcBegin = 0.0;
     var arcEnd = 90.0;
     if (center.dx <= imageSize.width/2 && center.dy <= imageSize.height/2) {
      subspace = 1;
      arcBegin = 0;
      arcEnd = 90;
     }
     if (center.dx > imageSize.width/2 && center.dy <= imageSize.height/2) {
      subspace = 2;
      arcBegin = 90;
      arcEnd = 180;
     }
     if (center.dx <= imageSize.width/2 && center.dy > imageSize.height/2) {
      subspace = 3;
      arcBegin = 180;
      arcEnd = 270;
     }
     if (center.dx > imageSize.width/2 && center.dy > imageSize.height/2) {
      subspace = 4;
      arcBegin = 270;
      arcEnd = 360;
     }
     return [arcBegin, arcEnd, subspace];
    }

    List<Offset> createArcPoints(double d, {double w, Offset center, double angle}) {
     List<Offset> targetPoints = List<Offset>();
     targetPoints.add(center == null ? Offset(100, 100) : center);
     angle = angle == null ? 0.15 : angle;
     var i = 0;
     var arc = detectSubspace(center);
     var arcBegin = arc[0]; var arcEnd = arc[1];
     var a = (arcBegin + i * angle);
     while (a <= arcEnd) {
       print(a);
      var as = a * pi/180;
      double dx = targetPoints[0].dx + (d * cos(as));
      double dy = targetPoints[0].dy + (d * sin(as));
      targetPoints.add(Offset(dx, dy));
      a = (arcBegin + i++ * angle) * pi;
     }
    return targetPoints;
   }
    void createTargets(double d, double width, {Offset center, double angle}) {
     double range = 90.0 / (d / (width*0.5));
     angle = angle == null ? range : angle;
     final targetPoints = createArcPoints(d, w: width, center: center, angle: angle);
     for (var point in targetPoints)
      _targets.add(Target.fromCircle(point, width));
    }

    TargetBuilder(this.imageSize, this.pointer) {
     createTargets(330, 40, center: Offset(40, 100));
    }

    void _addCircle(Canvas canvas, Offset offset,
      {double radius: 0, Paint paint}) {
     if (paint == null) paint = Paint()
      ..color = Colors.yellow;
     if (radius == 0) radius = _canvasSize.width / 100;
     canvas.drawCircle(offset, radius, paint);
    }

    void _addPointer(Canvas canvas, Offset position) {
     final paintStyle = Paint()
      ..color = Colors.red
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke;

     double radius = _canvasSize.width / 20;
     _addCircle(canvas, position, radius: radius, paint: paintStyle);
    }

    void _addTargetGrid(Canvas canvas) {
     _targets.forEach((t) => t.draw(canvas, pointer));
    }

    void paint(Canvas canvas, Size size) {
     _canvasSize = size;
     _addTargetGrid(canvas);
     _addPointer(canvas, pointer.getPosition());
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