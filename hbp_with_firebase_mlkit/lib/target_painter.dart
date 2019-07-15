import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'pointer.dart';
import 'utils.dart';

class TargetPaint extends CustomPaint {
  final CustomPainter painter;

  TargetPaint({this.painter}) : super(painter: painter);
}

class TargetPainter extends CustomPainter {
  final Size imageSize;
  final CameraLensDirection _direction;
  final Pointer _pointer;

 TargetPainter(this.imageSize, this._direction, this._pointer);

  void addRect(Canvas canvas, Rect boundingBox, Size size) {
    final paintRectStyle = Paint()
      ..color = Colors.purple;
//      ..strokeWidth = 10.0
//      ..style = PaintingStyle.stroke;

    //Scale rect to image size
    final rect = scaleRect(
      rect: flipRectBasedOnCam(boundingBox, _direction, imageSize.width),
      imageSize: imageSize,
      widgetSize: size,
    );
    canvas.drawRect(rect, paintRectStyle);
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
    if(rect.contains(_pointer.getPosition()))
      print("Pointer on the target");
    addRect(canvas, rect, size);
  }

  @override
  bool shouldRepaint(TargetPainter oldDelegate) {
    return imageSize != oldDelegate.imageSize || _pointer != oldDelegate._pointer;
  }
}
