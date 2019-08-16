import 'package:flutter/material.dart';
import 'Target.dart';
import 'dart:math';
import 'PointingTaskBuilder.dart';

class  MDCTaskBuilder extends PointingTaskBuilder {
  int _subspace = 0;
  int _targetWidth;
  int _amplitude;
  Offset _center;

  int _detectSubspace(center) {
    if (center.dx <= imageSize.width/2 && center.dy <= imageSize.height/2)
      return 0;
    else if (center.dx > imageSize.width/2 && center.dy <= imageSize.height/2)
      return 1;
    else if (center.dx <= imageSize.width/2 && center.dy > imageSize.height/2)
      return 2;
    else // if (center.dx > imageSize.width/2 && center.dy > imageSize.height/2)
      return 3;
  }

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

  List<double> _calculateTargetAngles(double angularDistance) {
    final arc = _getArcForSubspace(_subspace);
    double arcBegin = arc[0];
    double arcEnd = arc[1];
    List<double> angles = List<double>();
    for (double ang = arcBegin; ang <= arcEnd; ang += angularDistance)
      angles.add(ang * pi / 180);
    return angles;
  }

  List<Offset> _createArcPoints(double angularDistance) {
    List<Offset> targetPoints = List<Offset>();
    List<double> angles = _calculateTargetAngles(angularDistance);
    targetPoints.add(_center);
    for (double ang in angles) {
      double dx = targetPoints[0].dx + (_amplitude * cos(ang));
      double dy = targetPoints[0].dy + (_amplitude * sin(ang));
      targetPoints.add(Offset(dx, dy));
    }
    return targetPoints;
  }

  List<Offset> _createArc({int outerTargetCounter: 4, double angle}) {
    angle = angle == null ? (90.0 / (outerTargetCounter-1)) : angle;
    return _createArcPoints(angle);
  }

  void _createSubspace() {
    _center = Offset(200, 300);
    final targetPoints = _createArc();
    for (var point in targetPoints)
      targets.add(Target.fromCircle(point, _targetWidth.toDouble()));
  }

  void _switchToSubspace(int subspace) {
    _subspace = subspace;
    _createSubspace();
  }
  void _createMDCTargets(int distance, int width) {
//    _switchToSubspace(3);
    _amplitude = distance;
    _targetWidth = width;
    _createSubspace();
  }

  MDCTaskBuilder(imageSize, pointer) : super(imageSize, pointer){
      _createMDCTargets(160, 30);
  }

  void drawTargets(Canvas canvas) {
    for(var i = 0; i < targets.length; i++) {
      targets[i].draw(canvas, pointer);
      if (targets[i].pressed)
        targets.removeAt(i);
    }
    if (targets.length <= 0)
      _switchToSubspace(_subspace+1);
  }
}