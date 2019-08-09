import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'TargetBuilder.dart';
import 'face_painter.dart';
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

class _MyCamViewState extends State<MyCamView> {
  final FaceDetector faceDetector = FirebaseVision.instance.faceDetector(
      FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
          enableTracking: true));
  CameraController _camera;
  List<Face> faces;
  Pointer _pointer;
  var _targetBuilder;

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

      detect(image, faceDetector.processImage, rotation).then(
            (dynamic result) {
          setState(() {
            faces = result;
            Size size = Size(image.width.toDouble(), image.height.toDouble());
            if (_pointer == null)
              _pointer = Pointer(size, faces[0]);
            else
              _pointer.update(faces, size: size);
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
    if (faces == null ||
        _camera == null ||
        !_camera.value.isInitialized) {
      return noResultsText;
    }
    CustomPainter painter;
    final Size imageSize = Size(
      _camera.value.previewSize.height,
      _camera.value.previewSize.width,
    );

    if (faces is! List<Face>) return noResultsText;
    painter = FacePainter(imageSize, faces, _direction, _pointer);
    return CustomPaint(painter: painter);
  }

  CustomPaint _addTargets() {
    if (_targetBuilder == null) {
      final Size imageSize = Size(
        _camera.value.previewSize.height,
        _camera.value.previewSize.width,
      );
      _targetBuilder = TargetBuilder(imageSize, _pointer);
    }
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
          CameraPreview(_camera),
          _buildResults(),
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