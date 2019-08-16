import 'package:flutter/material.dart';
import 'Target.dart';
import 'dart:math';
import 'PointingTaskBuilder.dart';

class  MDCTaskBuilder extends PointingTaskBuilder {

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

  void _createMDCTargets(double d, double width, {Offset center, double angle}) {
    double range = 90.0 / (d / (width*0.5));
    angle = angle == null ? range : angle;
    final targetPoints = createArcPoints(d, w: width, center: center, angle: angle);
    for (var point in targetPoints)
      targets.add(Target.fromCircle(point, width));
  }

  MDCTaskBuilder(imageSize, pointer) : super(imageSize, pointer){
      _createMDCTargets(330, 40, center: Offset(40, 100));
  }

  void addTargetGrid(Canvas canvas) {
    targets.forEach((t) => (t.draw(canvas, pointer)));
  }
}