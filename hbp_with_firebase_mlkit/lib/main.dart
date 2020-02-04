import 'package:HeadPointing/Demo/DemoScreen.dart';
import 'package:HeadPointing/CameraHandler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:screen/screen.dart';

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
enum MODE {
  DEBUG,
  RELEASE
}

enum Answers{
  YES,
  NO
}

enum AppState {
  welcome,
  configure,
  test,
  demo
}

class MyMainViewState extends State<MyMainView> {
  CameraHandler _cameraHandler;
  DemoScreen _demoScreen;

  void setStateForImageStreaming(dynamic result)  {
    setState(() {//_taskScreen.updateInput(result, context: context);
    _demoScreen.updateInput(result, context: context);
    });
  }

  @override
  void initState() {
    super.initState();
    Screen.keepOn(true);
    _cameraHandler = CameraHandler(this);
    _demoScreen = DemoScreen(_cameraHandler, context: context);
//    setTaskScreenConfiguration();
  }

  AppBar getAppBar() {
    return  AppBar(
      title: Text('Head Pointing Demo'),
    );
  }

  Widget _buildMainView() {
    return Container(constraints: const BoxConstraints.expand(), child: _demoScreen.getDemoScreenView());
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
      appBar: getAppBar(),
      body: Center(
        child:  _buildMainView(),
      ),
  //      floatingActionButton: _addFloatingActionButton(),
    );
  }
}