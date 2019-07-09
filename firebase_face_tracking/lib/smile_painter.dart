import 'dart:math' as Math;
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class FacePaint extends CustomPaint {
  final CustomPainter painter;

  FacePaint({this.painter}) : super(painter: painter);
}

class SmilePainterLiveCamera extends CustomPainter {
  final Size imageSize;
  final List<Face> faces;
  final CameraLensDirection _direction;

  SmilePainterLiveCamera(this.imageSize, this.faces, this._direction);

  @override
  void paint(Canvas canvas, Size size) {
//    final paintRectStyle = Paint()
//      ..color = Colors.red
//      ..strokeWidth = 10.0
//      ..style = PaintingStyle.stroke;

    final paint = Paint()..color = Colors.yellow;

    for (var i = 0; i < faces.length; i++) {
      double left = imageSize.width - faces[i].boundingBox.right;
      double right = imageSize.width - faces[i].boundingBox.left;

      if (_direction == CameraLensDirection.back) {
        left = faces[i].boundingBox.left;
        right = faces[i].boundingBox.right;
      }


      final reversedRect =  Rect.fromLTRB(
          left,
          faces[i].boundingBox.top,
          right,
          faces[i].boundingBox.bottom);
      //Scale rect to image size
      final rect = _scaleRect(
        rect: reversedRect,
        // rect: faces[i].boundingBox,
        imageSize: imageSize,
        widgetSize: size,
      );

      //Radius for smile circle
      final radius = size.width / 16;
////
      final FaceLandmark nose =
      faces[i].getLandmark(FaceLandmarkType.noseBase);
     // print(nose.position);
      //Center of face rect
      // final Offset center = nose.position;
       final Offset center = rect.center;

      //Draw rect border
      //canvas.drawRect(rect, paintRectStyle);

      //Draw body
      canvas.drawCircle(center, radius, paint);

    }
  }

  @override
  bool shouldRepaint(SmilePainterLiveCamera oldDelegate) {
    return imageSize != oldDelegate.imageSize || faces != oldDelegate.faces;
  }
}

Rect _scaleRect({
  @required Rect rect,
  @required Size imageSize,
  @required Size widgetSize,
}) {
  final double scaleX = widgetSize.width / imageSize.width;
  final double scaleY = widgetSize.height / imageSize.height;

  return Rect.fromLTRB(
    rect.left.toDouble() * scaleX,
    rect.top.toDouble() * scaleY,
    rect.right.toDouble() * scaleX,
    rect.bottom.toDouble() * scaleY,
  );
}