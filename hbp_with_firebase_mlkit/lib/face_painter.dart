import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'utils.dart';
import 'pointer.dart';

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
    final rect = _scaleRect(
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
    Offset position = _scaleOffset(
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
  void addPointer(Canvas canvas, Offset position, Size size) {
    final paintStyle = Paint()
    ..color = Colors.red
    ..strokeWidth = 10.0
    ..style = PaintingStyle.stroke;

    position = _scaleOffset(
        offset: position,
        imageSize: imageSize,
        widgetSize: size
    );
    double radius = size.width / 20;
    addCircle(canvas, position, size, radius: radius, paint: paintStyle);
  }

@override
  bool hitTest(Offset position) {
    // TODO: implement hitTest
    return false;
  }
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < faces.length; i++) {
      addRect(canvas, faces[i].boundingBox, size);
      addAllLandmarks(canvas, faces[i], size);
    }
    _pointer.updateFace(faces, size: size, direction: _direction);
    addPointer(canvas, _pointer.getPosition(), size);
//    addPointer(canvas, faces[0].getLandmark(FaceLandmarkType.noseBase).position, size);
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
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

Offset _scaleOffset({
  @required Offset offset,
  @required Size imageSize,
  @required Size widgetSize,
}) {
  final double scaleX = widgetSize.width / imageSize.width;
  final double scaleY = widgetSize.height / imageSize.height;

  return Offset(offset.dx * scaleX, offset.dy * scaleY);
}