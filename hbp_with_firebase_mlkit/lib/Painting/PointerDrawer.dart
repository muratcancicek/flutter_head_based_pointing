import 'package:HeadPointing/Painting/PointingTaskBuilding/Target.dart';
import 'package:HeadPointing/pointer.dart';
import 'package:flutter/material.dart';
import 'dart:math';

enum PointerType {
  Bubble,
  Circle,
}

class PointerDrawer {
  Pointer pointer;
  Size canvasSize;
  double _radius;
  var _targets;

  PointerDrawer(this.pointer, this.canvasSize) {
    _radius = canvasSize.width / 30;
  }

  void _drawCircle(Canvas canvas, Offset offset,
      {double radius: 0, Paint paint}) {
    if (paint == null)
      paint = Paint()
        ..color = Colors.yellow;
    if (radius == 0) radius = canvasSize.width / 100;
    canvas.drawCircle(offset, radius, paint);
  }

  void _drawDwellingArcBackground(Canvas canvas, double width) {
    final paintBack = Paint()
    ..color = Colors.yellowAccent.withAlpha(80)
    ..strokeWidth = 1;
    _drawCircle(canvas, pointer.getPosition(), radius: width/2, paint: paintBack);
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1;
    final c = pointer.getPosition();
    final top = Offset(c.dx, c.dy-width/2), bottom = Offset(c.dx, c.dy+width/2);
    final left = Offset(c.dx-width/2, c.dy), right = Offset(c.dx+width/2, c.dy);
    canvas.drawLine(top, bottom, paint);
    canvas.drawLine(left, right, paint);
  }

  void _drawDwellingArc(Canvas canvas, double width) {
    final paintStyle = Paint()..color = Colors.deepOrange.withAlpha(80);
    var l =  pointer.getPosition().dx - width/2;
    var t =  pointer.getPosition().dy - width/2;
    canvas.drawArc(new Rect.fromLTWH(l, t, width, width),
        0, pointer.getDwellingPercentage() * 2 * pi, true, paintStyle);
  }

  void _drawBubbleCenter(Canvas canvas) {
    var width = _radius * 2;
    final maxWidth = canvasSize.width / 10;
    width = width < maxWidth ? width : maxWidth;
    _drawDwellingArcBackground(canvas, width);
    if (_targets != null)
      if (_targets.length > 0)
        pointer.setHighlighting(_targets[0].highlighted);
    if (pointer.highlights())
      _drawDwellingArc(canvas, width);
  }

  void _drawCircleEdge(Canvas canvas) {
    final paintStyle = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final scale = pointer.getType() == PointerType.Bubble ? 20 : 10;
    final maxWidth = canvasSize.width / scale;
    var width = _radius*2 < maxWidth ? _radius : maxWidth;
    _drawCircle(canvas, pointer.getPosition(),
        radius: width, paint: paintStyle);
  }

  void _drawCirclePointer(Canvas canvas) {
    if (_targets != null)
      _targets.sort((Target a, Target b) => ((
        a.getDistanceFromPointer(pointer) -
            b.getDistanceFromPointer(pointer)).toInt()));
    _drawBubbleCenter(canvas);
    _drawCircleEdge(canvas);
  }

  void _updateBubbleRadius() {
    if (_targets == null)
      return;
    _targets.sort((Target a, Target b) => ((
        a.getOuterDistanceFromPointer(pointer) -
            b.getOuterDistanceFromPointer(pointer)).toInt()));
    var r =  canvasSize.width/30;
    if (_targets.length > 1) {
      var inD = _targets[0].getInnerDistanceFromPointer(pointer);
      var space = canvasSize.width/30;
      var outD = _targets[1].getOuterDistanceFromPointer(pointer) - space;
      r = inD < outD ? inD : outD;
    } else if (_targets.length == 1) {
      r = _targets[0].getInnerDistanceFromPointer(pointer);
    }
    final maxR = 3 * canvasSize.height / 8;
    final minR = canvasSize.width / 20;
    r = r < maxR ? r : maxR;
    r = r > minR ? r : minR;
    _radius = r;
  }

  void _drawPathToNearestTarget(Canvas canvas) {
    if (_targets.length > 0) {
      if (_targets[0].highlighted) {
        final paint = Paint()
          ..color = Colors.blue
          ..strokeWidth = 4;
        canvas.drawLine(pointer.getPosition(), _targets[0].center, paint);
      }
    }
  }

  void _drawBubbleEdge(Canvas canvas) {
    final paintStyle = Paint()
      ..color = Colors.red.withAlpha(126)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    _drawCircle(canvas, pointer.getPosition(),
        radius: _radius, paint: paintStyle);
  }

  void _drawBubbleBody(Canvas canvas) {
    final paintStyle = Paint()
      ..color = Colors.red.withAlpha(30);
    _drawCircle(canvas, pointer.getPosition(), radius: _radius, paint: paintStyle);
  }

  void _drawBubbleRange(Canvas canvas) {
    _drawBubbleBody(canvas);
    _drawBubbleEdge(canvas);
  }

  void _drawBubblePointer(Canvas canvas) {
      _updateBubbleRadius();
    _drawBubbleRange(canvas);
    _drawPathToNearestTarget(canvas);
    _drawBubbleCenter(canvas);
  }

  void drawPointer(Canvas canvas, {type: PointerType.Circle}) {
    if (type == PointerType.Bubble) {
      _drawBubblePointer(canvas);
    } else // if (type == PointerType.Circle)
      _drawCirclePointer(canvas);
  }

  void update({targets}) {
    _targets = targets;
  }

  double getRadius() {
    return _radius;
  }

  bool shouldRepaint(PointerDrawer oldDelegate) {
    return canvasSize != oldDelegate.canvasSize || pointer != oldDelegate.pointer;
  }

  PointerPainter getPainter() {
    return PointerPainter(this);
  }
}

class PointerPainter extends CustomPainter {
  PointerDrawer _pointerDrawer;

  PointerPainter(this._pointerDrawer);

  @override
  void paint(Canvas canvas, Size size) {
    _pointerDrawer.drawPointer(canvas);
  }

  @override
  bool shouldRepaint(PointerPainter oldDelegate) {
    return _pointerDrawer.pointer.isUpdated();
  }

  PointerDrawer getTargetBuilder() {
    return _pointerDrawer;
  }
}