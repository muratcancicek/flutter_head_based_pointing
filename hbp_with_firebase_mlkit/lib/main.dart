import 'package:hbp_with_firebase_mlkit/MDCTaskHandler/TaskScreen.dart';
import 'package:hbp_with_firebase_mlkit/CameraHandler.dart';
import 'package:hbp_with_firebase_mlkit/ConfigScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  test
}

class MyMainViewState extends State<MyMainView> {
  AppState _state = AppState.welcome;
  MODE _runningMode = MODE.DEBUG;
  CameraHandler _cameraHandler;
  ConfigScreen _configScreen;
  TaskScreen _taskScreen;
  String _experimentID;

  void setStateForImageStreaming(dynamic result)  {
    setState(() {_taskScreen.updateInput(result); });
  }

  dynamic doesUserWantToSaveLogs() async {
    return await showDialog(
        context: context,
        child: new SimpleDialog(
          title: new Text('Do you like to save the experiment logs on cloud?'),
          children: <Widget>[
            new SimpleDialogOption(
              child: new Text('YES'),
              onPressed: (){Navigator.pop(context, Answers.YES);},
            ),
            new SimpleDialogOption(
              child: new Text('NO'),
              onPressed: (){Navigator.pop(context, Answers.NO);},
            ),
          ],
        )
    );
  }

  @override
  void initState() {
    super.initState();
    _configScreen = ConfigScreen();
    _cameraHandler = CameraHandler(this);
    _taskScreen = TaskScreen(_cameraHandler, exitAction: _setAppStateWelcome);
  }

  void _setAppStateWelcome() {
    _state = AppState.welcome;
    _configScreen.reset();
    _taskScreen = TaskScreen(_cameraHandler, exitAction: _setAppStateWelcome);
  }

  void _setAppStateConfigure() {
    _state = AppState.configure;
  }

  String getUniqueExperimentID() {
    String date = new DateTime.now().toIso8601String().replaceAll(':', '-');
    date = date.split('.').first;
    if (_runningMode == MODE.DEBUG)
      date = date.split('T').last;
    return 'Exp_$date';
  }

  void addExperimentDocumentData(String path, Map<String, dynamic> data) {
    CollectionReference exp = Firestore.instance.collection(_experimentID);
    exp.document(path).setData(data);
  }

  Future _startSavingLogsIfWanted() async {
    if (await doesUserWantToSaveLogs() == Answers.YES) {
      _experimentID = getUniqueExperimentID();
      Firestore.instance.document(_experimentID);
      addExperimentDocumentData('ID', {'ID': _experimentID});
      final configs = _configScreen.getFinalConfiguration();
      addExperimentDocumentData('TestConfigurations', {'Tests': configs});
      print('Starting $_experimentID');
    }
  }

  void _setAppStateTesting() {
    _startSavingLogsIfWanted();
    _state = AppState.test;
    _taskScreen.setConfiguration(_configScreen.getFinalConfiguration());
  }

  RaisedButton _getAppBarButton(String text, Function onPressed, Color color) {
    return RaisedButton(
      elevation: 4.0,
      color: color,
      textColor: Colors.white,
      child: Text(text),
      splashColor: Colors.blueGrey,
      onPressed: onPressed,
    );
  }

  List<Widget> _getAppBarButtonList() {
    return <Widget>[
      _getAppBarButton('Edit\nTests', _setAppStateConfigure, Colors.purpleAccent),
      _getAppBarButton('Start', _setAppStateTesting, Colors.purple),
    ];
  }


  AppBar getAppBar() {
    RaisedButton backButton = _getAppBarButton('Back', _setAppStateWelcome, Colors.red);
    switch(_state) {
      case AppState.configure:
        return _configScreen.getAppBar(backButton);
      case AppState.test:
        return _taskScreen.getAppBar();
      case AppState.welcome:
      default:
        return  AppBar(
          title: Text('Head Pointing Test'),
          actions: _getAppBarButtonList(),
        );
    }
  }

  Widget _buildMainView() {
    if (_taskScreen.isStudyCompleted())
      _setAppStateWelcome();
    Widget child;
    if (_cameraHandler.isCameraNull())
      child = _cameraHandler.getCameraInitializationView();
    else {
      switch(_state) {
        case AppState.configure:
          child = _configScreen.getConfigsScreenView();
          break;
        case AppState.test:
        case AppState.welcome:
        default:
          child = _taskScreen.getTaskScreenView();
          break;
      }
    }
    return Container(constraints: const BoxConstraints.expand(), child: child);
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