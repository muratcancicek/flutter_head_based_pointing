import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'face_painter.dart';
import 'utils.dart';
import 'pointer.dart';
import 'package:flutter/rendering.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: MyCamView(title: 'Head-based Pointing with Flutter'),
    );
  }
}

class MyCamView extends StatefulWidget {
  MyCamView({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyCamViewState createState() => _MyCamViewState();
}

class _MyCamViewState extends State<MyCamView> {
  final FaceDetector faceDetector = FirebaseVision.instance
      .faceDetector(FaceDetectorOptions(enableClassification: false, enableLandmarks: true, enableTracking: true));
  CameraController _camera;
  List<Face> faces;
  Pointer _pointer;
  FlatButton _flatButton;

  bool _isDetecting = false;
  CameraLensDirection _direction = CameraLensDirection.front;

  GlobalKey _buttonKey = GlobalKey();
  Container _ui;

  FlatButton _addFlatButton() {
    return FlatButton.icon(
      color: Colors.blue,
      icon: Icon(Icons.face), //`Icon` to display
      label: Text('Button'), //`Text` to display
      onPressed: () {
        //Code to execute when Floating Action Button is clicked
        //...
        print('You pressed the Button!');
        print(_pointer.getPosition());
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _flatButton = _addFlatButton();
    _ui = _buildUI();
    _initializeCamera();
  }

  void _initializeCamera() async {
    CameraDescription description = await getCamera(_direction);
    ImageRotation rotation = rotationIntToImageRotation(
      description.sensorOrientation,
    );

    _camera = CameraController(
      description,
      defaultTargetPlatform == TargetPlatform.iOS ? ResolutionPreset.low : ResolutionPreset.medium,
    );
    await _camera.initialize();

    _camera.startImageStream((CameraImage image) {
      if (_isDetecting) return;

      _isDetecting = true;

      detect(image, faceDetector.processImage, rotation).then(
        (dynamic result) {
          setState(() {
            faces = result;
            Size size = Size(image.width.toDouble(), image.height.toDouble());
            _pointer = Pointer(size, faces[0], _direction);
            BoxHitTestResult hitTest = BoxHitTestResult();
            final position = _pointer.getPosition();
            RendererBinding.instance.f
            GestureBinding.instance.hitTest(hitTest, position);
            // if (position.dy < 150 && position.dx > 400 && position.dx < 500) {
              // print('trying');
              // print(hitTest.path.skip(8) .take(5));
              GestureBinding.instance.dispatchEvent( PointerDownEvent(), hitTest);
              GestureBinding.instance.dispatchEvent( PointerUpEvent(), hitTest);
            // }
            // print(hitTest.path.first);
          });

          _isDetecting = false;
        },
      ).catchError(
        (_) {
          _isDetecting = false;
        },
      );
    });
  }

  Positioned _addPointerCoordinates(BuildContext context) {
    Iterable<HitTestEntry> entries;
    return Positioned(
      bottom: 0.0,
      left: 0.0,
      right: 0.0,
      child: Container(
        color: Colors.white,
        height: 200.0,
        child: entries == null
            ? Text('No entries')
            :
//        Text(entries.length.toString()),
            ListView(
                children: entries.map((e) => Text(e.toString())).toList(),
//            faces.map((face) => Text(positionRed.toString()))
//              .map((face) => Text(face.getLandmark(FaceLandmarkType.noseBase).position.toString()))
//              .toList(),
              ),
      ),
    );
  }

  Widget _buildResults() {
    const Text noResultsText = const Text('No results!');

    if (faces == null || _camera == null || !_camera.value.isInitialized) {
      return noResultsText;
    }

    CustomPainter painter;

    final Size imageSize = Size(
      _camera.value.previewSize.height,
      _camera.value.previewSize.width,
    );
//    final Size imageSize = Size(340, 700);
    if (faces is! List<Face>) return noResultsText;
    painter = FacePainter(imageSize, faces, _direction, _pointer);

    return CustomPaint(
      painter: painter,
    );
  }

  Container _buildUI() {
    return Container(
//      constraints: const BoxConstraints.expand(),
      child: Column(
        children: <Widget>[
          _flatButton,
          Text("text"),
        ],
      ),
    );
  }

  Widget _buildCamView(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(),
      child: _camera == null
          ? const Center(
              child: Text(
                'Initializing Camera...',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 30.0,
                ),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CameraPreview(_camera),
                _addPointerCoordinates(context),
                //         _ui,
                _buildUI(),
                _buildResults(),
              ],
            ),
    );
  }

  void _toggleCameraDirection() async {
    if (_direction == CameraLensDirection.back) {
      _direction = CameraLensDirection.front;
    } else {
      _direction = CameraLensDirection.back;
    }
    await _camera.stopImageStream();
    await _camera.dispose();
    setState(() {
      _camera = null;
    });
    _initializeCamera();
  }

  FloatingActionButton _addFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _toggleCameraDirection,
      child: _direction == CameraLensDirection.back ? const Icon(Icons.camera_front) : const Icon(Icons.camera_rear),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _buttonKey,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: _buildCamView(context),
      ),
      floatingActionButton: _addFloatingActionButton(),
    );
  }
}
