import 'package:hbp_with_firebase_mlkit/MDCTaskHandler/TaskScreen.dart';
import 'package:hbp_with_firebase_mlkit/CameraHandler.dart';
import 'package:hbp_with_firebase_mlkit/ConfigScreen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Remove the back/home/etc. buttons at the bottom of the screen
    SystemChrome.setEnabledSystemUIOverlays([]);

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
      ),
      home: MyMainView(title: 'Head-based Pointing with Flutter'),
    );
  }
}

class MyMainView extends StatefulWidget {
  MyMainView({Key key, this.title}) : super(key: key);
  final String title;

  @override
  MyMainViewState createState() => MyMainViewState();
}

class MyMainViewState extends State<MyMainView> {
  CameraHandler _cameraHandler;
  TaskScreen _taskScreen;
  ConfigScreen _configScreen;

  void setStateForImageStreaming(dynamic result)  {
    setState(() {_taskScreen.updateInput(result); });
  }

  @override
  void initState() {
    super.initState();
    _configScreen = ConfigScreen();
    _cameraHandler = CameraHandler(this);
    _taskScreen = TaskScreen(_cameraHandler);
  }

  Widget _buildMainView() {
    return Container(
      constraints: const BoxConstraints.expand(),
      child: _cameraHandler.isCameraNull()
          ? _cameraHandler.getCameraInitializationView()
          : _configScreen.f()//_taskScreen.getTaskScreenView(), //
    );
  }

  FloatingActionButton addFloatingActionButton() {
    Icon icon = const Icon(Icons.camera_front);
    if (_cameraHandler.isBackCamera())
      icon = const Icon(Icons.camera_rear);
    return FloatingActionButton(
      onPressed: _cameraHandler.toggleCameraDirection,
      child: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: _taskScreen.getAppBar(),
    body: Center(
      child:  _buildMainView(),
    ),
//      floatingActionButton: _addFloatingActionButton(),
  );
  }
}