import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'pointer.dart';
import 'utils.dart';

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

  Target.fromRect(Rect rect, Size size, {Paint givenStyle}) {
    _targetShape = TargetShape.RectTarget;
    _shape = rect;
    if (givenStyle == null) {
        _style = Paint()
        ..color = Colors.purple;
    } else {
      _style = givenStyle;
    }
  }

  bool contains(pointer) {
    if (_targetShape == TargetShape.RectTarget)
      return _shape.contains(pointer.getPosition());
    else if (_targetShape == TargetShape.CircleTarget) {
      // TODO: implement the logic for circles
      return false;
    }
    else
      return false;
  }
  void draw(Canvas canvas, pointer) {
    if(contains(pointer))
      _style.color = Colors.white;
    if (_targetShape == TargetShape.RectTarget)
      canvas.drawRect(_shape, _style);
  }
}

class TargetPainter extends CustomPainter {
  final Size imageSize;
  final CameraLensDirection _direction;
  final Pointer _pointer;

 TargetPainter(this.imageSize, this._direction, this._pointer);

  Rect addRect(Canvas canvas, Rect boundingBox, Size size) {
    //Scale rect to image size
    return scaleRect(
      rect: flipRectBasedOnCam(
          boundingBox, _direction, imageSize.width),
      imageSize: imageSize,
      widgetSize: size,
    );
  }
  void addCircle(Canvas canvas, Offset offset, Size size,
      {double radius: 0, Paint paint}) {
    if (paint == null) paint = Paint()..color = Colors.yellow;
    offset = flipOffsetBasedOnCam(offset, _direction, size.width);
    if (radius == 0) radius = size.width / 100;
    canvas.drawCircle(offset, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Rect rect = Rect.fromLTRB(150, 100, 250, 200);
    rect = flipRectBasedOnCam(rect, _direction, size.width);
    Target target = Target.fromRect(rect, size);
    target.draw(canvas, _pointer);
  }

  @override
  bool shouldRepaint(TargetPainter oldDelegate) {
    return imageSize != oldDelegate.imageSize || _pointer != oldDelegate._pointer;
  }
}
