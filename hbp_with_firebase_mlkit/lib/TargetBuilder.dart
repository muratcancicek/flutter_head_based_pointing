import 'package:flutter/material.dart';
import 'pointer.dart';
import 'Target.dart';
import 'dart:math';

class TargetPaint extends CustomPaint {
    final CustomPainter painter;

    TargetPaint({this.painter}) : super(painter: painter);
}

class TargetBuilder {
    final Size imageSize;
    final Pointer pointer;
    Size _canvasSize = Size(640, 360);
    List<Target> _targets = List<Target>();
    var _jeffTaskWidth = 80.0;
    var _jeffTaskEdge = 100.0;
    var _pointerRadius = 100.0;


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
//       print(a);
      var as = a * pi/180;
      double dx = targetPoints[0].dx + (d * cos(as));
      double dy = targetPoints[0].dy + (d * sin(as));
      targetPoints.add(Offset(dx, dy));
      a = (arcBegin + i++ * angle) * pi;
     }
    return targetPoints;
   }

    void _createTargets(double d, double width, {Offset center, double angle}) {
     double range = 90.0 / (d / (width*0.5));
     angle = angle == null ? range : angle;
     final targetPoints = createArcPoints(d, w: width, center: center, angle: angle);
     for (var point in targetPoints)
      _targets.add(Target.fromCircle(point, width));
    }

    void _createJeffTask(double width,{double e = 100}) { // e: edge
      Size size = Size(420, 690); // manually detected size
      _targets.add(Target.fromCircle(Offset(e, e), width));
      _targets.add(Target.fromCircle(Offset(size.width-e, e), width));
      _targets.add(Target.fromCircle(Offset(size.width/2, size.height/2), width));
      _targets.add(Target.fromCircle(Offset(e, size.height-e), width));
      _targets.add(Target.fromCircle(Offset(size.width-e, size.height-e), width));
    }

    TargetBuilder(this.imageSize, this.pointer) {
//     _createTargets(330, 40, center: Offset(40, 100));
       _createJeffTask(_jeffTaskWidth, e: _jeffTaskEdge);
    }

    void _addCircle(Canvas canvas, Offset offset,
      {double radius: 0, Paint paint}) {
     if (paint == null) paint = Paint()
      ..color = Colors.yellow;
     if (radius == 0) radius = _canvasSize.width / 100;
//     offset = scaleOffset(offset: offset, imageSize: imageSize, widgetSize: _canvasSize);
     canvas.drawCircle(offset, radius, paint);
    }

    void _addPointer(Canvas canvas) {
     final paintStyle = Paint()
      ..color = Colors.red
      ..strokeWidth = 30.0
      ..style = PaintingStyle.stroke;
     _addCircle(canvas, pointer.getPosition(), radius: pointer.getRadius(), paint: paintStyle);
    }

    void _addJeffTask(Canvas canvas) {
      List<double> distances = List();
      for(var i = 0; i < _targets.length; i++) {
        _targets[i].draw(canvas, pointer);
        if (_targets[i].pressed)
          _targets.removeAt(i);
        distances.add(_targets[i].getDistanceFromPointer(pointer));
      }
      distances.sort();
      var r = distances.length > 1 ? distances[1] : 3*_canvasSize.width/4;
      pointer.updateRadius(r/2);
    }

    void _addTargetGrid(Canvas canvas) {
      if (_targets.length <= 0) {
        _jeffTaskEdge *= 0.75;
        _jeffTaskWidth *= 0.75;
        _createJeffTask(_jeffTaskWidth, e: _jeffTaskEdge);
      }
      _addJeffTask(canvas);
    }

    void paint(Canvas canvas, Size size) {
     _canvasSize = size;
     _addTargetGrid(canvas);
     _addPointer(canvas);
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