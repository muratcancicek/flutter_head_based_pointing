import 'package:hbp_with_firebase_mlkit/Painting/face_painter.dart';
import 'package:hbp_with_firebase_mlkit/MDCTaskHandler/MDCTaskRecorder.dart';
import 'package:hbp_with_firebase_mlkit/CameraHandler.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:hbp_with_firebase_mlkit/pointer.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

class TaskScreen {
  Size _canvasSize = Size(420, 670); // manually detected size
  bool _drawingFacialLandmarks = false;
  CameraHandler _cameraHandler;
  MDCTaskRecorder _recorder;
  List<Face> _faces;
  Pointer _pointer;

  TaskScreen(this._cameraHandler) {
    _pointer = Pointer(_canvasSize, null);
    _recorder = MDCTaskRecorder(_pointer);
  }

  void updateInput(dynamic result) {
    if (_recorder.getCurrentTest().isTestRunning()) {
      _pointer.update(result, size: _canvasSize);
    }
    _recorder.update();
  }

  RaisedButton getAppBarButton() {
    return RaisedButton(
      elevation: 4.0,
      color: Colors.purple,
      textColor: Colors.white,
      child: Text(_recorder.getNextActionString()),
      splashColor: Colors.blueGrey,
      onPressed: _recorder.getNextAction(),
    );
  }

  Text getAppBarText() {
    return Text(_recorder.getTitleToDisplay(), textAlign: TextAlign.center);
  }

  Center _displaySummaryScreen() {
    return Center(
      child: Container(
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: <Widget>[
            Text(
              'Summary',
              style: TextStyle(
                color: Colors.green,
                fontSize: 30.0,
              )
            ),
          ],
        )
      ),
    );
  }

  Widget _drawFacialLandmarks() {
    const Text noResultsText = const Text('No results!');
    if (_faces == null || _cameraHandler.isCameraEmpty() || _faces is! List<Face>)
      return noResultsText;
    Size _imageSize = _cameraHandler.getCameraPreviewSize();
    var direction = _cameraHandler.getDirection();
    CustomPainter painter = FacePainter(_imageSize, _faces, direction);
    return CustomPaint(painter: painter);
  }

  CustomPaint _drawTargets() {
    return CustomPaint(painter: _recorder.getTaskBuilder().getPainter());
  }

  Widget _drawPointer() {
    _pointer.updateDrawer(targets: _recorder.getTaskBuilder().getTargets());
    return CustomPaint(painter: _pointer.getPainter());
  }

  Stack getTaskScreenView() {
    List<Widget> screen = List<Widget>();
    if (_recorder.getCurrentTest().isBlockCompleted()) {
      screen.add(_displaySummaryScreen());
    } else if (_recorder.getCurrentTest().isBlockStarted()) { //
      if (_drawingFacialLandmarks)
        screen.add(_drawFacialLandmarks());
      screen.add(_drawTargets());
      screen.add(_drawPointer());
    }
    return Stack(fit: StackFit.expand, children: screen);
  }
}