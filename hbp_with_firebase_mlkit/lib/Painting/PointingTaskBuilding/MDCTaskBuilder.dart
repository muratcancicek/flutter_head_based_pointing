import 'package:flutter/material.dart';
import 'Target.dart';
import 'dart:math';
import 'PointingTaskBuilder.dart';

class  MDCTaskBuilder extends PointingTaskBuilder {
  double arcBegin = 0;
  double arcEnd = 90;
  int _subspace = 0;
  int _targetWidth;
  int _amplitude;
  Offset _center;

  List<double> _getArcForSubspace(subspace) {
    switch (subspace) {
      def: case 0: {
        return [0.0, 90.0];
      }
      case 1: {
        return [90.0, 180.0];
      }
      case 2: {
        return [180, 270.0];
      }
      case 3: {
        return [270.0, 360.0];
      }
      default:
        continue def;
    }
    return [0.0, 90.0];
  }

  int detectSubspace(center) {
    if (center.dx <= imageSize.width/2 && center.dy <= imageSize.height/2)
      return 0;
    else if (center.dx > imageSize.width/2 && center.dy <= imageSize.height/2)
      return 1;
    else if (center.dx <= imageSize.width/2 && center.dy > imageSize.height/2)
      return 2;
    else // if (center.dx > imageSize.width/2 && center.dy > imageSize.height/2)
      return 3;
  }

  List<Offset> createArcPoints(double angle) {
    List<Offset> targetPoints = List<Offset>();
    targetPoints.add(_center);
    var i = 0;
    var a = (arcBegin + i * angle);
    while (a <= arcEnd) {
//       print(a);
      var as = a * pi/180;
      double dx = targetPoints[0].dx + (_amplitude * cos(as));
      double dy = targetPoints[0].dy + (_amplitude * sin(as));
      targetPoints.add(Offset(dx, dy));
      a = (arcBegin + i++ * angle) * pi;
    }
    return targetPoints;
  }

  List<Offset> createArc({double angle: 5}) {
//    double range = 90.0 / (_amplitude / (_targetWidth*0.5));
//    angle = angle == null ? range : angle;
    _subspace = detectSubspace(_center);
    return createArcPoints(angle);
  }

  void _createSubspace() {
    _center = Offset(50, 100);
    final targetPoints = createArc();
    for (var point in targetPoints)
      targets.add(Target.fromCircle(point, _targetWidth.toDouble()));
  }

  void _switchToSubspace(int subspace) {
    _subspace = subspace;
    final arc = _getArcForSubspace(_subspace);
    arcBegin = arc[0];
    arcEnd = arc[1];
  }
  void _createMDCTargets(int distance, int width) {
    _switchToSubspace(0);
    _amplitude = distance;
    _targetWidth = width;
    _createSubspace();
  }

  MDCTaskBuilder(imageSize, pointer) : super(imageSize, pointer){
      _createMDCTargets(330, 40);
  }

  void addTargetGrid(Canvas canvas) {
    targets.forEach((t) => (t.draw(canvas, pointer)));
  }
}