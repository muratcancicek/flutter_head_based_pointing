import 'package:HeadPointing/Painting/PointingTaskBuilding/JeffTaskBuilder.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:HeadPointing/Painting/face_painter.dart';
import 'package:HeadPointing/CameraHandler.dart';
import 'package:HeadPointing/pointer.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';

class DemoScreen {
  Size _canvasSize = Size(420, 670); // manually detected size
  bool _drawingFacialLandmarks = true;
  GlobalKey _key = GlobalKey();
  CameraHandler _cameraHandler;
  dynamic _taskBuilder;
  List<Face> _faces;
  Pointer _pointer;
  var _context;

  DemoScreen(this._cameraHandler, {context}) {
    _context = context;
    _pointer = Pointer(_canvasSize, null);
    _taskBuilder = JeffTaskBuilder(_canvasSize, _pointer);
  }

  void _updateCanvasSize() {
    if (_key.currentContext != null) {
    final RenderBox render = _key.currentContext.findRenderObject();
      _canvasSize = render.size;
    }
  }

  void updateInput(dynamic result, {context, config}) {
    _context = context;
    _faces = result;
    _updateCanvasSize();
    _pointer.update(result, size: _canvasSize);
  }

  Text _getAppBarText() {
    return Text('Demo', textAlign: TextAlign.center);
  }

  AppBar getAppBar() {
    return AppBar(
      title: _getAppBarText(),
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
    _pointer.updateDrawer(targets: _taskBuilder.getTargets());
    return CustomPaint(painter: _pointer.getPainter());
  }

  CustomPaint _drawTargets() {
    return CustomPaint(painter: _taskBuilder.getPainter());
  }

  Stack getDemoScreenView() {
    List<Widget> screen = List<Widget>();
    screen.add(_cameraHandler.getCameraPreview());

    if (_drawingFacialLandmarks)
      screen.add(_drawFacialLandmarks());
    screen.add(_drawTargets());
    screen.add(_drawPointer());
    return Stack(fit: StackFit.expand, key: _key, children: screen);
  }

  void updateCanvasSize(Size size) {
    _canvasSize = size;
  }
}