import 'package:flutter/material.dart';
import 'pointer.dart';
import 'Target.dart';
import 'dart:math';

enum PointerType {
  Bubble,
  Circle,
}

class PointerDrawer {
  Pointer pointer;
  Size _canvasSize;
  double _radius;

  PointerDrawer(this.pointer, this._canvasSize) {
    _radius = _canvasSize.width / 20;    
  }

  void _addCircle(Canvas canvas, Offset offset,
      {double radius: 0, Paint paint}) {
    if (paint == null)
      paint = Paint()
        ..color = Colors.yellow;
    if (radius == 0) radius = _canvasSize.width / 100;
    canvas.drawCircle(offset, radius, paint);
  }

  void _addCirclePointer(Canvas canvas) {
    final paintStyle = Paint()
      ..color = Colors.red
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke;
    _addCircle(canvas, pointer.getPosition(),
        radius: _radius, paint: paintStyle);
  }


  void _addDwellingArc(Canvas canvas) {
    final paintStyle = Paint()
      ..color = Colors.deepOrange.withAlpha(190);
    var width = _radius*2;
    final maxWidth = _canvasSize.width / 6;
    width = width < maxWidth ? width : maxWidth;
    var l =  pointer.getPosition().dx - width/2;
    var t =  pointer.getPosition().dy - width/2;
    final paintStyle2 = Paint()
      ..color = Colors.yellowAccent;
    _addCircle(canvas, pointer.getPosition(), radius: width/2, paint: paintStyle2);
    canvas.drawArc(new Rect.fromLTWH(l, t, width, width),
        0, pointer.dwellingPercentage() * 2 * pi, true, paintStyle);

  }

  void _drawBubblePointer(Canvas canvas, targets) {
    if (targets.length > 0) {
      final paint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 4;
      canvas.drawLine(pointer.getPosition(), targets[0].center, paint);
    }
    final paintStyle = Paint()
      ..color = Colors.red.withAlpha(126)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    _addCircle(canvas, pointer.getPosition(), radius: _radius, paint: paintStyle);
    final paintStyle2 = Paint()
      ..color = Colors.red.withAlpha(30);
    _addCircle(canvas, pointer.getPosition(), radius: _radius, paint: paintStyle2);
    _addDwellingArc(canvas);
  }

  void _updateBubbleRadius(targets) {
    targets.sort((Target a, Target b) => ((
        a.getOuterDistanceFromPointer(pointer) - 
            b.getOuterDistanceFromPointer(pointer)).toInt()));
    var r =  _canvasSize.width/30;
    if (targets.length > 1) {
      var inD = targets[0].getInnerDistanceFromPointer(pointer);
      var space = _canvasSize.width/300;
      var outD = targets[1].getOuterDistanceFromPointer(pointer) - space;
      r = inD < outD ? inD : outD;
    } else if (targets.length == 1) {
      r = targets[0].getInnerDistanceFromPointer(pointer);
    }
    final maxR = 3 * _canvasSize.height / 8;
    final minR = _canvasSize.width / 20;
    r = r < maxR ? r : maxR;
    r = r > minR ? r : minR;
    _radius = r;

  }

  void drawPointer(Canvas canvas, {targets, type: PointerType.Circle}) {
   if (type == PointerType.Bubble) {
      if (targets != null)
        _updateBubbleRadius(targets);
      _drawBubblePointer(canvas, targets);
    } else // if (type == PointerType.Circle)
      _addCirclePointer(canvas);
  }

  double getRadius() {
    return _radius;
  }
}