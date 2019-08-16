import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/JeffTaskBuilder.dart';
import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/MDCTaskBuilder.dart';
import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/PointingTaskBuilder.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:hbp_with_firebase_mlkit/Painting/face_painter.dart';
import 'pointer.dart';
import 'utils.dart';

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

enum PointingTaskType {
  Jeff,
  MDC,
}

class _MyCamViewState extends State<MyCamView> {
  final FaceDetector _faceDetector = FirebaseVision.instance.faceDetector(
      FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
          enableTracking: true));
  PointingTaskType _pointingTaskType = PointingTaskType.MDC ;
  PointingTaskBuilder _targetBuilder;
  CameraController _camera;
  Size _imageSize;
  List<Face> _faces;
  Pointer _pointer;

  bool _isDetecting = false;
  CameraLensDirection _direction = CameraLensDirection.front;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    CameraDescription description = await getCamera(_direction);
    ImageRotation rotation = rotationIntToImageRotation(
      description.sensorOrientation,
    );

    _camera = CameraController(
      description,
      defaultTargetPlatform == TargetPlatform.iOS
          ? ResolutionPreset.low
          : ResolutionPreset.medium,
    );
    await _camera.initialize();

    _camera.startImageStream((CameraImage image) {
      if (_isDetecting) return;

      _isDetecting = true;

      detect(image, _faceDetector.processImage, rotation).then(
            (dynamic result) {
          setState(() {
            _faces = result;
            Size size = Size(image.width.toDouble(), image.height.toDouble());
            if (_pointer == null)
              _pointer = Pointer(size, _faces[0]);
            else
              _pointer.update(_faces, size: size);
//            _targetBuilder.pointer = _pointer;
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

  Positioned _addPointerCoordinates() {
    return Positioned(
      bottom: 0.0,
      left: 0.0,
      right: 0.0,
      child: Container(
        color: Colors.white,
        height: 30.0,
        child:
        Text(_pointer.getPosition().toString()),
      ),
    );
  }

  Widget _buildResults() {
    const Text noResultsText = const Text('No results!');
    if (_faces == null ||
        _camera == null ||
        !_camera.value.isInitialized) {
      return noResultsText;
    }
    CustomPainter painter;
    final Size imageSize = Size(
      _camera.value.previewSize.height,
      _camera.value.previewSize.width,
    );

    if (_faces is! List<Face>) return noResultsText;
    painter = FacePainter(imageSize, _faces, _direction);
    return CustomPaint(painter: painter);
  }

  CustomPaint _drawPointer() {
    _pointer.update(_faces, size: _imageSize, direction: _direction);
    return CustomPaint(painter: _pointer.getPainter());
  }

  CustomPaint _addTargets() {
    if (_targetBuilder == null) {
      _imageSize = Size(
        _camera.value.previewSize.height,
        _camera.value.previewSize.width,
      );
      if (_pointingTaskType == PointingTaskType.Jeff)
        _targetBuilder = JeffTaskBuilder(_imageSize, _pointer);
      else if (_pointingTaskType == PointingTaskType.MDC)
        _targetBuilder = MDCTaskBuilder(_imageSize, _pointer);
    }
//    _pointer.update(_faces, size: _imageSize, direction: _direction);
    return CustomPaint(painter: _targetBuilder.getPainter());
  }

  Widget _buildCamView() {
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
//          CameraPreview(_camera),
//          _buildResults(),
          _drawPointer(),
          _addTargets(),
          _addPointerCoordinates(),
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
      child: _direction == CameraLensDirection.back
          ? const Icon(Icons.camera_front)
          : const Icon(Icons.camera_rear),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child:  _buildCamView(),
      ),
      floatingActionButton: _addFloatingActionButton(),
    );
  }
}