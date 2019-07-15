
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class Pointer {
  Size _imageSize;
  Face _face;
  Offset _position;

  Pointer(this._imageSize, this._face);

  void updateFace(List<Face> faces, {Size size, CameraLensDirection direction}) {
    bool differentFace = true;
    for (var face in faces) {
      if (face.trackingId == _face.trackingId) {
        _face = face;
        differentFace = false;
        break;
      }
    }
    if (differentFace) _face = faces[0];
    if (size != null) _imageSize = size;

  }

  double calculateXFromCheeks() {
    Offset nose = _face.getLandmark(FaceLandmarkType.noseBase).position;
    Offset leftCheek = _face.getLandmark(FaceLandmarkType.leftCheek).position;
    Offset rightCheek = _face.getLandmark(FaceLandmarkType.rightCheek).position;
    if (rightCheek.dx < leftCheek.dx) {
      Offset temp = rightCheek; rightCheek = leftCheek; leftCheek = temp;
    }
    double range = (rightCheek.dx - leftCheek.dx) / 2;
    double minX = leftCheek.dx + range / 2;
    double maxX = rightCheek.dx - range / 2;
    double scaleX = (nose.dx - minX) / (maxX - minX);
    return scaleX * _imageSize.width;
  }

  double calculateY() {
    Offset nose = _face.getLandmark(FaceLandmarkType.noseBase).position;
    Offset leftEye = _face.getLandmark(FaceLandmarkType.leftEye).position;
    Offset rightEye = _face.getLandmark(FaceLandmarkType.rightEye).position;
    double topY = (leftEye.dy + rightEye.dy) / 2;
    Offset mouth = _face.getLandmark(FaceLandmarkType.bottomMouth).position;
    double range = (mouth.dy - topY) / 2;
    double minY = topY + range / 2;
    double maxY = mouth.dy - range / 2;
    double scaleY = (nose.dy - minY) / (maxY - minY);
    //   return nose.dy;
    return scaleY * _imageSize.height;
  }

  Offset getPosition() {
    double dx = calculateXFromCheeks();
    double dy = calculateY();

    _position = Offset(dx, dy);
    return _position;
  }
}