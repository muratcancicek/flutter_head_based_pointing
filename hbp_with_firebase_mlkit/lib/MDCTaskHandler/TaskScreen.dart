import 'package:HeadPointing/MDCTaskHandler/MDCTaskRecorder.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:HeadPointing/Painting/face_painter.dart';
import 'package:HeadPointing/CameraHandler.dart';
import 'package:HeadPointing/pointer.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

class TaskScreen {
  Size _canvasSize = Size(420, 670); // manually detected size
  bool _drawingFacialLandmarks = false;
  GlobalKey _key = GlobalKey();
  CameraHandler _cameraHandler;
  bool _studyStarted = false;
  MDCTaskRecorder _recorder;
  String _experimentID;
  String _subjectID;
  List<Face> _faces;
  Pointer _pointer;
  var _context;

  TaskScreen(this._cameraHandler, this._experimentID, this._subjectID,
      {Function exitAction, context}) {
    _context = context;
    _pointer = Pointer(_canvasSize, null);
    _recorder = MDCTaskRecorder(_canvasSize, _pointer, _experimentID, _subjectID,
        exitAction: exitAction, context: _context);
  }

  void _updateCanvasSize() {
    if (_key.currentContext != null) {
    final RenderBox render = _key.currentContext.findRenderObject();
      _canvasSize = render.size;
    }
  }

  void updateInput(dynamic result, {context, config}) {
    _context = context;
    _updateCanvasSize();
    _recorder.getTaskBuilder().canvasSize = _canvasSize;
    _recorder.getTutorialBuilder().canvasSize = _canvasSize;
    if (!_recorder.isPaused())
      _pointer.update(result, size: _canvasSize);
    _recorder.update(context: _context);
  }

  Text _getAppBarText() {
    return Text(_recorder.getTitleToDisplay(), textAlign: TextAlign.center);
  }

  RaisedButton _getExitButton() {
    return RaisedButton(
      elevation: 4.0,
      color: Colors.pink,
      textColor: Colors.white,
      child: Text(_recorder.getExitActionString()),
      splashColor: Colors.blueGrey,
      onPressed: _recorder.getExitAction(),
    );
  }

  RaisedButton _getBackButton() {
    return RaisedButton(
      elevation: 4.0,
      color: Colors.purpleAccent,
      textColor: Colors.white,
      child: Text(_recorder.getBackActionString()),
      splashColor: Colors.blueGrey,
      onPressed: _recorder.getBackAction(),
    );
  }
  RaisedButton _getPrimaryButton() {
    return RaisedButton(
      elevation: 4.0,
      color: Colors.purple,
      textColor: Colors.white,
      child: Text(_recorder.getNextActionString()),
      splashColor: Colors.blueGrey,
      onPressed: _recorder.getNextAction(),
    );
  }

  AppBar getAppBar() {
    List<Widget> actions = <Widget>[];
    if (_recorder.getExitAction() != null)
      actions.add(_getExitButton());
    if (_recorder.getBackAction() != null)
      actions.add(_getBackButton());
    actions.add(_getPrimaryButton());
    return AppBar(
      title: _getAppBarText(),
      actions: actions,
    );
  }

  Center _displaySummaryScreen() {
    return Center(
      child: Container(
        child: Text(
            'Completed the test block!',
            style: TextStyle(
              color: Colors.green,
              fontSize: 30.0,
            )
        ),//
      ),
    );
  }

  Center _displayTutorialScreen() {
    final text1 = 'Here, please practice Head Pointing before the study starts.'
        '\n\nMove your head both sides and up and down until you get familiar '
        'with the behavior of the cursor.'
        '\n\nThen, try to select the target (green circle) by holding the cursor'
        ' still on the target.'
        '\n\nAll of the existing selection methods are enabled for practice.'
        '\n\nYou do not need to complete the targets on this screen and '
        'please start the study whenever you feel ready.';

    final modes = _pointer.getEnabledSelectionModes();
    final m = modes.first.toString().split('.').last;
    final text2 = 'Here, please practice the next test with $m selection mode '
        'before the following test starts. '
        '\n\nYou do not need to complete the targets on this screen and '
        'please start the test whenever you feel ready.'
        '\n\nDuring the actual test,\nyou will be seeing the targets with '
        'the same size and in the same order within this screen.'
        '\n\nAlso, you are allowed use only one selection method during the test'
        'which is allowed here.'
        '\n\nOn the test, please select the targets precisely and as faster as '
        'you can.';

    final text3 = 'Here, you may take a break or keep practicing the same test '
        'until you feel you are ready to start the next block of the test.';

    final isFirstBlock = _recorder.getCurrentTest().isFirstBlock();
    final text = !_studyStarted ? text1 : (isFirstBlock ? text2 : text3);
    return Center(
      child: Container(
        width: 350,
        child: Text(text,
            textAlign: TextAlign.justify,
            style: TextStyle(
              color: Colors.black,
              fontSize: 20.0,
            )
         ),
      )
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

  CustomPaint _drawTutorial() {
    return CustomPaint(painter: _recorder.getTutorialBuilder().getPainter());
  }

  Widget _drawPointer() {
    _pointer.updateDrawer(targets: _recorder.getTaskBuilder().getTargets());
    if (!_recorder.getCurrentTest().isBlockStarted())
    _pointer.updateDrawer(targets: _recorder.getTutorialBuilder().getTargets());
    return CustomPaint(painter: _pointer.getPainter());
  }

  Stack getTaskScreenView() {
    List<Widget> screen = List<Widget>();
    if (_recorder.isStudyCompleted()) {
      screen.add(_displaySummaryScreen());
    } else if (_recorder.getCurrentTest().isBlockCompleted()) {
      screen.add(_displaySummaryScreen());
    } else if (_recorder.getCurrentTest().isBlockStarted()) { //
      if (_drawingFacialLandmarks)
        screen.add(_drawFacialLandmarks());
      screen.add(_drawTargets());
    } else {
      screen.add(_drawTutorial());
      screen.add(_displayTutorialScreen());
    }
    screen.add(_drawPointer());
    return Stack(fit: StackFit.expand, key: _key, children: screen);
  }

  void updateCanvasSize(Size size) {
    _canvasSize = size;
  }

  void setUpdate(String experimentID, Map<String, dynamic> configs) {
    _experimentID = experimentID;
  }

  void setConfiguration(List<Map<String, dynamic>> finalConfiguration) {
    _recorder.setConfiguration(finalConfiguration);
  }

  void startStudyScreen() {
    _studyStarted = true;
  }

  void endStudyScreen() {
    _studyStarted = false;
  }

  bool isStudyStarted() => _studyStarted;

  bool isStudyCompleted() => _recorder.isStudyCompleted();

  dynamic getCurrentTest() => _recorder.getCurrentTest();
}