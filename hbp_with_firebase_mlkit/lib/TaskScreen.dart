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
  Size _canvasSize = Size(420, 720); // manually detected size
  bool _drawingFacialLandmarks = false;
  String _outputToDisplay = '';
  CameraHandler _cameraHandler;
  MDCTaskRecorder _recorder;
  var _targetBuilder;
  List<Face> _faces;
  Pointer _pointer;

  TaskScreen(this._cameraHandler) {
    _pointer = Pointer(_canvasSize, null);
    _recorder = MDCTaskRecorder(_pointer);
    if (_pointingTaskType == PointingTaskType.Jeff)
      _targetBuilder = JeffTaskBuilder(_canvasSize, _pointer);
    else if (_pointingTaskType == PointingTaskType.MDC)
      _targetBuilder = MDCTaskBuilder(_canvasSize, _pointer, _recorder);
    _recorder.updateTaskBuilder(_targetBuilder);
  }

  void updateInput(dynamic result) {
    _recorder.logTime();
    if (_recorder.isTestRunning()) {
      _faces = result;
      _pointer.update(_faces, size: _canvasSize);
      _recorder.logPointerNow();
    }
  }

  void _onPressedAppBarButton() {
    if (_recorder.isBlockStarted())
      if (_recorder.isTestRunning())
        _recorder.pause();
      else
        _recorder.resume();
    else
      _recorder.start();
  }

  RaisedButton _getAppBarButton() {
    var text = _recorder.isBlockCompleted() ? Text('Next') : Text('Start');
    if (_recorder.isBlockStarted())
      text = _recorder.isTestRunning() ? Text('Pause') : Text('Resume');
    return RaisedButton(
      elevation: 4.0,
      color: Colors.purple,
      textColor: Colors.white,
      child: text,
      splashColor: Colors.blueGrey,
      onPressed: _onPressedAppBarButton,
    );
  }
  Text _getAppBarText() {
    _outputToDisplay = _recorder.getOutputToDisplay();
    return Text(_outputToDisplay, textAlign: TextAlign.center);
  }

  List<Widget> _getAppBarUIComponents() {
    return <Widget>[
      Container(child: _getAppBarText(), padding: const EdgeInsets.all(8.0)),
      Container(child: _getAppBarButton(), alignment: Alignment.bottomRight),
    ];
  }

  Container getAppBarUI() {
    return Container(
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8.0),
        children: _getAppBarUIComponents(),
      )
    );
  }

  Center _displaySummaryScreen() {
    return Center(
      child: Container(
        height: 150.0,
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: <Widget>[
            Text('Summary')
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
    return CustomPaint(painter: _targetBuilder.getPainter());
  }

  Widget _drawPointer() {
    _pointer.updateDrawer(targets: _targetBuilder.getTargets());
    return CustomPaint(painter: _pointer.getPainter());
  }

  Stack getTaskScreenView() {
    List<Widget> screen = List<Widget>();
    if (_recorder.isBlockCompleted()) {
      _displaySummaryScreen();
    } else {
      if (_drawingFacialLandmarks)
        screen.add(_drawFacialLandmarks());
      screen.add(_drawTargets());
      screen.add(_drawPointer());
    }
    return Stack(fit: StackFit.expand, children: screen);
  }
}