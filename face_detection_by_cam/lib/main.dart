import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mlkit/mlkit.dart';
import 'dart:async';


import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final cam = cameras[0];

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: cam,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  final CameraDescription camera;

  const TakePictureScreen({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  File _file;
  List<VisionFace> _face = <VisionFace>[];
  VisionFaceDetectorOptions options = new VisionFaceDetectorOptions(
      modeType: VisionFaceDetectorMode.Accurate,
      landmarkType: VisionFaceDetectorLandmark.All,
      classificationType: VisionFaceDetectorClassification.All,
      minFaceSize: 0.15,
      isTrackingEnabled: true);
  FirebaseVisionFaceDetector detector = FirebaseVisionFaceDetector.instance;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body:
      FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),

      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Construct the path where the image should be saved using the
            // pattern package.
            final path = join(
              // Store the picture in the temp directory.
              // Find the temp directory using the `path_provider` plugin.
              (await getTemporaryDirectory()).path,
              '${DateTime.now()}.png',
            );

            // Attempt to take a picture and log where it's been saved.
            await _controller.takePicture(path);

            var file = File(path);
            setState(() {
              _file = file;
            });
            var face =
            await detector.detectFromBinary(_file?.readAsBytesSync(), options);
            setState(() {
              if (face == null) {
                print('No face detected');
              } else {
                _face = face;
              }
            });

            // If the picture was taken, display it on a new screen.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(imagePath: path),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;
  List<VisionFace> _face = <VisionFace>[];

  DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: showBody(),/*
     Image.file(File(imagePath)), */
    );
  }


  Widget showBody() {
    return new Container(
      child: new Stack(
        children: <Widget>[
          _buildImage(),
          _showDetails(_face),
        ],
      ),
    );
  }
  Widget _buildImage() {
    return new SizedBox(
      height: 500.0,
      child: new Center(
        child: imagePath == null
            ? new Text('Select image using Floating Button...')
            : new FutureBuilder<Size>(
          future: _getImageSize(Image.file(File(imagePath), fit: BoxFit.fitWidth)),
          builder: (BuildContext context, AsyncSnapshot<Size> snapshot) {
            if (snapshot.hasData) {
              return Container(
                  foregroundDecoration:
                  TextDetectDecoration(_face, snapshot.data),
                  child: Image.file(File(imagePath), fit: BoxFit.fitWidth));
            } else {
              return new Text('Please wait...');
            }
          },
        ),
      ),
    );
  }
}

class TextDetectDecoration extends Decoration {
  final Size _originalImageSize;
  final List<VisionFace> _texts;
  TextDetectDecoration(List<VisionFace> texts, Size originalImageSize)
      : _texts = texts,
        _originalImageSize = originalImageSize;
  @override
  BoxPainter createBoxPainter([VoidCallback onChanged]) {
    return new _TextDetectPainter(_texts, _originalImageSize);
  }
}
Future _getImageSize(Image image) {
  Completer<Size> completer = new Completer<Size>();
  image.image.resolve(new ImageConfiguration()).addListener(
          (ImageInfo info, bool _) => completer.complete(
          Size(info.image.width.toDouble(), info.image.height.toDouble())));
  return completer.future;
}
Widget _showDetails(List<VisionFace> faceList) {
  if (faceList == null || faceList.length == 0) {
    return new Text('', textAlign: TextAlign.center);
  }
  return new Container(
    child: new ListView.builder(
      padding: const EdgeInsets.all(10.0),
      itemCount: faceList.length,
      itemBuilder: (context, i) {
        checkData(faceList);
        return _buildRow(
            faceList[0].hasLeftEyeOpenProbability,
            faceList[0].headEulerAngleY,
            faceList[0].headEulerAngleZ,
            faceList[0].leftEyeOpenProbability,
            faceList[0].rightEyeOpenProbability,
            faceList[0].smilingProbability,
            faceList[0].trackingID);
      },
    ),
  );
}
//For checking and printing different variables from Firebase
void checkData(List<VisionFace> faceList) {
  final double uncomputedProb = -1.0;
  final int uncompProb = -1;
  for (int i = 0; i < faceList.length; i++) {
    Rect bounds = faceList[i].rect;
    print('Rectangle : $bounds');
    VisionFaceLandmark landmark =
    faceList[i].getLandmark(FaceLandmarkType.LeftEar);
    if (landmark != null) {
      VisionPoint leftEarPos = landmark.position;
      print('Left Ear Pos : $leftEarPos');
    }
    if (faceList[i].smilingProbability != uncomputedProb) {
      double smileProb = faceList[i].smilingProbability;
      print('Smile Prob : $smileProb');
    }
    if (faceList[i].rightEyeOpenProbability != uncomputedProb) {
      double rightEyeOpenProb = faceList[i].rightEyeOpenProbability;
      print('RightEye Open Prob : $rightEyeOpenProb');
    }
    if (faceList[i].trackingID != uncompProb) {
      int tID = faceList[i].trackingID;
      print('Tracking ID : $tID');
    }
  }
}
/*
    HeadEulerY : Head is rotated to right by headEulerY degrees
    HeadEulerZ : Head is tilted sideways by headEulerZ degrees
    LeftEyeOpenProbability : left Eye Open Probability
    RightEyeOpenProbability : right Eye Open Probability
    SmilingProbability : Smiling probability
    Tracking ID : If face tracking is enabled
  */
Widget _buildRow(
    bool leftEyeProb,
    double headEulerY,
    double headEulerZ,
    double leftEyeOpenProbability,
    double rightEyeOpenProbability,
    double smileProb,
    int tID) {
  return ListTile(
    title: new Text(
      "\nLeftEyeProb: $leftEyeProb \nHeadEulerY : $headEulerY \nHeadEulerZ : $headEulerZ \nLeftEyeOpenProbability : $leftEyeOpenProbability \nRightEyeOpenProbability : $rightEyeOpenProbability \nSmileProb : $smileProb \nFaceTrackingEnabled : $tID",
    ),
    dense: true,
  );
}
class _TextDetectPainter extends BoxPainter {
  final List<VisionFace> _faceLabels;
  final Size _originalImageSize;
  _TextDetectPainter(faceLabels, originalImageSize)
      : _faceLabels = faceLabels,
        _originalImageSize = originalImageSize;
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final paint = new Paint()
      ..strokeWidth = 2.0
      ..color = Colors.red
      ..style = PaintingStyle.stroke;
    final _heightRatio = _originalImageSize.height / configuration.size.height;
    final _widthRatio = _originalImageSize.width / configuration.size.width;
    for (var faceLabel in _faceLabels) {
      final _rect = Rect.fromLTRB(
          offset.dx + faceLabel.rect.left / _widthRatio,
          offset.dy + faceLabel.rect.top / _heightRatio,
          offset.dx + faceLabel.rect.right / _widthRatio,
          offset.dy + faceLabel.rect.bottom / _heightRatio);
      canvas.drawRect(_rect, paint);
    }
  }
}