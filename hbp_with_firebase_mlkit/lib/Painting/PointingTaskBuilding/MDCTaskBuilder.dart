import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/PointingTaskBuilder.dart';
import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/Target.dart';
import 'package:hbp_with_firebase_mlkit/MDCTaskRecorder.dart';
import 'package:flutter/material.dart';
import 'dart:math';

enum Subspace {
  TopLeftCorner,
  TopRightCorner,
  BottomRightCorner,
  BottomLeftCorner,
  Center
}

class  MDCTaskBuilder extends PointingTaskBuilder {
  List<Target> _subspaceTargets = List<Target>();
  Subspace _subspace = Subspace.TopLeftCorner;
  Offset _offsetToEdges = Offset(50, 50);
  int _currentTargetIndex = 0;
  int _outerTargetCount = 2;
  MDCTaskRecorder _recorder;
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

  Offset _createOuterPoint(Offset center, double angle) {
    return Offset(center.dx + (_amplitude * cos(angle)),
                  center.dy + (_amplitude * sin(angle)));
  }

  List<Offset> _createArcPoints(double angularDistance) {
    List<Offset> targetPoints = List<Offset>();
    List<double> angles = _calculateTargetAngles(angularDistance);
    targetPoints.add(_center);
    for (double ang in angles) {
      Offset target = _createOuterPoint(_center, ang);
      targetPoints.add(target);
      targetPoints.add(_center);
    }
    return targetPoints;
  }

  List<Offset> _createArc({int outerTargetCounter, double angle}) {
    if (outerTargetCounter ==  null)
      outerTargetCounter = _outerTargetCount;
    angle = angle == null ? (90.0 / (outerTargetCounter-1)) : angle;
    return _createArcPoints(angle);
  }

  void _createSubspace() {
    _subspaceTargets = List<Target>();
    _center = _getCenterForSubspace(_subspace);
    _currentTargetIndex = 0;
    final targetPoints = _createArc();
    _recorder.recordTargetPoints(targetPoints);
    for (var i = 0; i < targetPoints.length; i++)
      _subspaceTargets.add(
          Target.fromCircle(targetPoints[i], _targetWidth.toDouble()));
    targets.add(_subspaceTargets[0]);
  }

  void _createMDCTargets(int amplitude, int targetWidth) {
    _amplitude = amplitude;
    _targetWidth = targetWidth;
    _createSubspace();
  }

  MDCTaskBuilder(imageSize, pointer, recorder,
      {int amplitude: 160, int targetWidth: 30})
      : super(imageSize, pointer) {
    _recorder = recorder;
    _createMDCTargets(amplitude, targetWidth);
  }

  void _switchToSubspace(Subspace subspace) {
    _subspace = subspace;
    _createSubspace();
  }

  void _switchToNextSubspace() {
    _subspaceID++;
    if (_subspaceID > 3) {
      _subspaceID = 0;
//      _recorder.saveJsonFile();
    }
    _subspace = Subspace.values[_subspaceID];
    _switchToSubspace(_subspace);
  }

  void _switchToNextTarget() {
    _recorder.recordTrail(_currentTargetIndex,
        dwellTime: pointer.getExactDwellDuration());
    targets.removeLast();
    _currentTargetIndex++;
    if (_currentTargetIndex < _subspaceTargets.length) {
      Target nextTarget = _subspaceTargets[_currentTargetIndex];
      targets.add(nextTarget);
    }
    else
      _switchToNextSubspace();
  }

  void drawTargets(Canvas canvas) {
    if (targets.length > 0) {
      if (targets[0].pressed)
        _switchToNextTarget();
      else
        targets[0].draw(canvas, pointer);
    }
  }

  int getAmplitude() => _amplitude;

  int getTargetWidth() => _targetWidth;

  int getOuterTargetCount() => _outerTargetCount;

  int getSubspaceTargetCount() => _subspaceTargets.length;

  int getBlockTargetCount() => 4 * _subspaceTargets.length;

  int getBlockTrailCount() => 4 * (_subspaceTargets.length - 1);

  Offset getOffsetToEdges() => _offsetToEdges;

  Size getCanvasSize() => canvasSize;
}