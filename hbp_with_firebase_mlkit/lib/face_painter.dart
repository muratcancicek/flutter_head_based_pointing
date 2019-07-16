import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'pointer.dart';
import 'utils.dart';

class FacePaint extends CustomPaint {
  final CustomPainter painter;

  FacePaint({this.painter}) : super(painter: painter);
}

class FacePainter extends CustomPainter {
  final Size imageSize;
  final List<Face> faces;
  final CameraLensDirection _direction;
  final Pointer _pointer;

  FacePainter(this.imageSize, this.faces, this._direction, this._pointer);

  void addRect(Canvas canvas, Rect boundingBox, Size size) {
    final paintRectStyle = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 10.0
      ..style = PaintingStyle.stroke;

    //Scale rect to image size
    final rect = scaleRect(
      rect: flipRectBasedOnCam(
          boundingBox, _direction, imageSize.width),
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

  void addLandmark(Canvas canvas, FaceLandmark landmark, Size size) {
    Offset position = scaleOffset(
        offset: landmark.position,
        imageSize: imageSize,
        widgetSize: size
    );
    addCircle(canvas, position, size);
  }

  void addAllLandmarks(Canvas canvas, Face face, Size size) {
    for (var landmark in FaceLandmarkType.values) {
      addLandmark(canvas, face.getLandmark(landmark), size);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < faces.length; i++) {
      addRect(canvas, faces[i].boundingBox, size);
      addAllLandmarks(canvas, faces[i], size);
    }
    _pointer.updateFace(faces, size: size, direction: _direction);
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return imageSize != oldDelegate.imageSize || faces != oldDelegate.faces;
  }
}

