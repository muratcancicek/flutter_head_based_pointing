import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/JeffTaskBuilder.dart';
import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/MDCTaskBuilder.dart';
import 'package:hbp_with_firebase_mlkit/Painting/face_painter.dart';
import 'package:hbp_with_firebase_mlkit/MDCTaskRecorder.dart';
import 'package:hbp_with_firebase_mlkit/CameraHandler.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'pointer.dart';

enum PointingTaskType {
  Jeff,
  MDC,
}

class TaskScreen {
  PointingTaskType _pointingTaskType = PointingTaskType.MDC;
  Size _canvasSize = Size(420, 690); // manually detected size
  String _outputToDisplay = '';
  CameraHandler _cameraHandler;
  MDCTaskRecorder _recorder;
  var _targetBuilder;
  List<Face> _faces;
  Pointer _pointer;

  TaskScreen(this._cameraHandler) {
    _pointer = Pointer(_canvasSize, null);
    _recorder = MDCTaskRecorder();
  }

  void updateInput(dynamic result)  {
//    print(result.length);
    _faces = result;
    _pointer.update(_faces, size: _canvasSize);
    _recorder.logPointer(_pointer);
  }

  Positioned _displayOutput() {
    _outputToDisplay = _recorder.getLastMovementDuration().toString() + ' seconds';
    return Positioned(
      bottom: 0.0,
      left: 0.0,
      right: 0.0,
      child: Container(
        color: Colors.white,
        height: 30.0,
        child:
        Text(_outputToDisplay),
      ),
    );
  }

  Widget _buildResults() {
    const Text noResultsText = const Text('No results!');
    if (_faces == null || _cameraHandler.isCameraEmpty() || _faces is! List<Face>)
      return noResultsText;
    Size _imageSize = _cameraHandler.getCameraPreviewSize();
    var direction = _cameraHandler.getDirection();
    CustomPainter painter = FacePainter(_imageSize, _faces, direction);
    return CustomPaint(painter: painter);
  }

  Widget _drawPointer() {
    _pointer.update(_faces, targets: _targetBuilder.getTargets(), size: _canvasSize);
    _recorder.logPointer(_pointer);
    return CustomPaint(painter: _pointer.getPainter());
  }

  CustomPaint _addTargets() {
    if (_targetBuilder == null) {
      if (_pointingTaskType == PointingTaskType.Jeff)
        _targetBuilder = JeffTaskBuilder(_canvasSize, _pointer);
      else if (_pointingTaskType == PointingTaskType.MDC)
        _targetBuilder = MDCTaskBuilder(_canvasSize, _pointer, _recorder);
    }
    return CustomPaint(painter: _targetBuilder.getPainter());
  }

  Stack getTaskScreenView() {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
//        _cameraHandler.getCameraPreview(),
//        _buildResults(),
        _displayOutput(),
        _addTargets(),
        _drawPointer(),
      ],
    );
  }

}