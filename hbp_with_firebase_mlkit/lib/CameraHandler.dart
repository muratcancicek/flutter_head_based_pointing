import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:hbp_with_firebase_mlkit/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'utils.dart';

class CameraHandler {
  CameraLensDirection _direction = CameraLensDirection.front;
  MyMainViewState _viewState;
  bool _isDetecting = false;
  CameraController _camera;
  ImageRotation _rotation;

  CameraController _getCameraController(CameraDescription description) {
    final platform = defaultTargetPlatform == TargetPlatform.iOS
        ? ResolutionPreset.low
        : ResolutionPreset.medium;
    return CameraController(description, platform);
  }

  void _setStateForStreaming(dynamic result)  {
    _viewState.setStateForImageStreaming(result);
    _isDetecting = false;
  }

  void _streamImage(CameraImage image){
    if (_isDetecting)
      return;
    _isDetecting = true;
    detect(image, _faceDetector.processImage, _rotation)
        .then(_setStateForStreaming)
        .catchError((_) { _isDetecting = false; },
    );
  }

  void _initializeCamera() async {
    CameraDescription description = await getCamera(_direction);
    _rotation = rotationIntToImageRotation(description.sensorOrientation);
    _camera = _getCameraController(description);
    await _camera.initialize();
    _camera.startImageStream(_streamImage);
  }

  CameraHandler(this._viewState) {
    _initializeCamera();
  }

  final FaceDetector _faceDetector = FirebaseVision.instance.faceDetector(
      FaceDetectorOptions(
          enableClassification: true,
          enableLandmarks: true,
          enableTracking: true)
  );

  void toggleCameraDirection() async {
    if (_direction == CameraLensDirection.back)
      _direction = CameraLensDirection.front;
     else
      _direction = CameraLensDirection.back;
    await _camera.stopImageStream();
    await _camera.dispose();
    _camera = null;
    _initializeCamera();
  }

  CameraLensDirection getDirection() {
    return _direction;
  }

  bool isBackCamera() {
    return _direction == CameraLensDirection.back;
  }

  bool isCameraNull() {
    return  _camera == null;
  }

  Center getCameraInitializationView(){
    return  const Center(
      child: Text(
        'Initializing Camera...',
        style: TextStyle(
          color: Colors.green,
          fontSize: 30.0,
        ),
      ),
    );
  }

  bool isCameraEmpty() {
    return _camera == null || !_camera.value.isInitialized;
  }

  Size getCameraPreviewSize() {
    return Size(
      _camera.value.previewSize.height,
      _camera.value.previewSize.width,
    );
  }

  CameraPreview getCameraPreview() {
    return CameraPreview(_camera);
  }
}