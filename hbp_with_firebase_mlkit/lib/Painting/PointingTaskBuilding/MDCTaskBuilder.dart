import 'package:flutter/material.dart';
import 'Target.dart';
import 'dart:math';
import 'PointingTaskBuilder.dart';

enum Subspace {
  TopLeftCorner,
  TopRightCorner,
  BottomRightCorner,
  BottomLeftCorner,
  Center
}
class  MDCTaskBuilder extends PointingTaskBuilder {
  Subspace _subspace = Subspace.TopLeftCorner;
  Offset _offsetToEdges = Offset(50, 50);
  int _outerTargetCounter = 2;
  int _subspaceID = 0;
  int _targetWidth;
  int _amplitude;
  Offset _center;


  Subspace detectSubspace({center}) {
    if (center == null) center = _center;
    if (center.dx < canvasSize.width/2 && center.dy < canvasSize.height/2)
      return Subspace.TopLeftCorner;
    else if (center.dx > canvasSize.width/2 && center.dy < canvasSize.height/2)
      return  Subspace.TopRightCorner;
    else if (center.dx > canvasSize.width/2 && center.dy > canvasSize.height/2)
      return  Subspace.BottomRightCorner;
    else if (center.dx > canvasSize.width/2 && center.dy > canvasSize.height/2)
      return  Subspace.BottomLeftCorner;
    else
      return  Subspace.Center;
  }

  List<double> _getArcForSubspace(subspace) {
    switch (subspace) {
      def: case  Subspace.TopLeftCorner:
        return [0.0, 90.0];
      case  Subspace.TopRightCorner:
        return [90.0, 180.0];
      case  Subspace.BottomRightCorner:
        return [180, 270.0];
      case  Subspace.BottomLeftCorner:
        return [270.0, 360.0];
      case  Subspace.Center:
        return [0.0, 360.0];
      default:
        continue def;
    }
    return [0.0, 90.0];
  }

  Offset _getCenterForSubspace(subspace) {
    switch (subspace) {
      def: case  Subspace.TopLeftCorner:
        return Offset(_offsetToEdges.dx, _offsetToEdges.dy);
      case  Subspace.TopRightCorner:
        return  Offset(canvasSize.width - _offsetToEdges.dx, _offsetToEdges.dy);
      case  Subspace.BottomRightCorner:
        return Offset(canvasSize.width - _offsetToEdges.dx,
                      canvasSize.height - _offsetToEdges.dy);
      case  Subspace.BottomLeftCorner:
        return Offset(_offsetToEdges.dx, canvasSize.height - _offsetToEdges.dy);
      case  Subspace.Center:
        return Offset(canvasSize.width / 2, canvasSize.width / 2);
      default:
        continue def;
    }
    return Offset(canvasSize.width / 2, canvasSize.width / 2);
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

  List<Offset> _createArc({int outerTargetCounter, double angle}) {
    if (outerTargetCounter ==  null)
      outerTargetCounter = _outerTargetCounter;
    angle = angle == null ? (90.0 / (outerTargetCounter-1)) : angle;
    return _createArcPoints(angle);
  }

  void _createSubspace() {
    _center = _getCenterForSubspace(_subspace);
    final targetPoints = _createArc();
    for (var point in targetPoints)
      targets.add(Target.fromCircle(point, _targetWidth.toDouble()));
  }

  void _createMDCTargets(int distance, int width) {
    _amplitude = distance;
    _targetWidth = width;
    _createSubspace();
  }

  MDCTaskBuilder(imageSize, pointer) : super(imageSize, pointer){
      _createMDCTargets(160, 30);
  }

  void _switchToSubspace(Subspace subspace) {
    _subspace = subspace;
    _createSubspace();
  }

  void _switchToNextSubspace() {
    _subspaceID++;
    if (_subspaceID > 3)
      _subspaceID = 0;
    _subspace = Subspace.values[_subspaceID];
    _switchToSubspace(_subspace);
  }

  void drawTargets(Canvas canvas) {
    for(var i = 0; i < targets.length; i++) {
      targets[i].draw(canvas, pointer);
      if (targets[i].pressed)
        targets.removeAt(i);
    }
    if (targets.length <= 0)
      _switchToNextSubspace();
  }
}