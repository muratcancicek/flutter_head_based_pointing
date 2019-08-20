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
  bool _headPointingActive = false;
  bool _blockCompleted = false;
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

  void updateInput(dynamic result)  {
    if (_headPointingActive) {
      _faces = result;
      _pointer.update(_faces, size: _canvasSize);
      _recorder.logPointerNow();
    }
  }

  RaisedButton getMainButton() {
    final buttonText = _headPointingActive ? Text('Pause') : Text('Resume');
    return RaisedButton(
      elevation: 4.0,
      color: Colors.purple,
      textColor: Colors.white,
      child: buttonText,
      splashColor: Colors.blueGrey,
      onPressed: () {
        print('Done');
        _headPointingActive = !_headPointingActive;
      },
    );
  }
  List<Widget> getHeaderUIComponents() {
    return  <Widget>[
      Container(
        padding: const EdgeInsets.all(8.0),
        child: Text(_outputToDisplay, textAlign: TextAlign.center),
      ),
      Container(
        child:  getMainButton(),
      ),
    ];
  }
  Container displayOutput() {
    _outputToDisplay = _recorder.getLastMovementDuration().toString() + ' seconds';
    return Container(
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8.0),
        children: getHeaderUIComponents(),
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

  Widget _drawPointer() {
    _pointer.updateDrawer(targets: _targetBuilder.getTargets());
    return CustomPaint(painter: _pointer.getPainter());
  }

  CustomPaint _drawTargets() {
    return CustomPaint(painter: _targetBuilder.getPainter());
  }

  Stack getTaskScreenView() {
    List<Widget> screen = List<Widget>();
    if (_blockCompleted) {
      _displaySummaryScreen();
    } else {
      screen.add(_drawTargets());
      screen.add(_drawPointer());
      if (_drawingFacialLandmarks)
        screen.add(_drawFacialLandmarks());
    }
    return Stack(fit: StackFit.expand, children: screen);
  }

}