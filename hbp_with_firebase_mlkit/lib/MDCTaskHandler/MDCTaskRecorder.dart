import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/PointingTaskBuilder.dart';
import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/MDCTaskBuilder.dart';
import 'package:hbp_with_firebase_mlkit/MDCTaskHandler/MDCTest.dart';
import 'package:hbp_with_firebase_mlkit/pointer.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

final configs = [
  <String, dynamic>{
    'PointingTaskType': PointingTaskType.MDC,
    'Amplitude': 150,
    'TargetWidth': 80,
    'OuterTargetCount': 0,
    'Angle': 30.0
  },
  <String, dynamic>{
    'PointingTaskType': PointingTaskType.MDC,
    'Amplitude': 150,
    'TargetWidth': 40,
    'OuterTargetCount': 2,
    'Angle': 30.0
  },
//  <String, dynamic>{
//    'PointingTaskType': PointingTaskType.MDC,
//    'Amplitude': 450,
//    'TargetWidth': 80,
//    'OuterTargetCount': 3,
//    'Angle': 15.0
//  },
//  <String, dynamic>{
//    'PointingTaskType': PointingTaskType.MDC,
//    'Amplitude': 450,
//    'TargetWidth': 40,
//    'OuterTargetCount': 3,
//    'Angle': 15.0
//  },
];

class MDCTaskRecorder {
  List<Map> _tests = List<Map>();
  String _nextActionText = 'Start';
  String _titleToDisplay = '';
  Function _nextAction;
  int _testCount = 2;
  int _testID = 1;
  int _subjectID = 1;
  var _canvasSize;
  MDCTest _test;
  Pointer _pointer;

  Map<String, dynamic> subjectInformation() => {
    '"SubjectID"': _subjectID,
    '"TestCount"': _testCount,
    '"Tests"': _tests,
  };

  void saveJsonFile({Directory dir, String fileName: 'BlockOne'}) async {
    fileName += (new DateTime.now().millisecondsSinceEpoch).toString();
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String path = appDocDir.path + "/" + fileName+'.json';
    print("Creating file to $path!");
    File file = new File(path);
    final json = subjectInformation().toString();
    file.createSync();
    file.writeAsStringSync(json);
  }

  void _createTest({config}) {
    final now = new DateTime.now().millisecondsSinceEpoch;
    _test = MDCTest(_canvasSize, _testID, _pointer, now, config: config);
  }

  MDCTaskRecorder(this._canvasSize, this._pointer) {
    _createTest(config: configs[_testID-1]);
    _nextAction = _test.start;
  }

  void switchNextTest() {
    _tests.add(_test.testInformation());
    print('New test!');
    _testID++;
    if (_testID > _testCount) {
      saveJsonFile();
      return;
    }
    _pointer.reset();
    _createTest(config: configs[_testID-1]);
  }

  void update() {
    _test.update(new DateTime.now().millisecondsSinceEpoch);
    switch(_test.getState()) {
      case TestState.BlockNotStarted:
        _nextAction = _test.start;
        _nextActionText = 'START!';
        _titleToDisplay = _test.getDynamicTitleToDisplay(prefix: 'Start');
        break;
      case TestState.BlockRunning:
        _nextAction = _test.pause;
        _nextActionText = 'PAUSE!';
        _titleToDisplay = _test.getCurrentStatusToDisplay();
        break;
      case TestState.BlockPaused:
        _nextAction = _test.resume;
        _nextActionText = 'RESUME!';
        _titleToDisplay = _test.getDynamicTitleToDisplay(prefix: 'Resume');
        break;
      case TestState.BlockCompleted:
        _nextAction = _test.switchNextBlock;
        _nextActionText = 'NEXT!';
        _titleToDisplay = _test.getDynamicTitleToDisplay(prefix: 'Results of');
        break;
      case TestState.TestCompleted:
        _nextAction = switchNextTest;
        _nextActionText = 'NEXT TEST!';
        _titleToDisplay = _test.getDynamicTitleToDisplay(prefix: 'Results of');
        break;
      default:
        _nextAction = _test.start;
        _nextActionText = 'RUN!';
        _titleToDisplay = 'Head-based Pointing with Flutter';
    }
  }

  MDCTest getCurrentTest() => _test;

  MDCTaskBuilder getTaskBuilder() => _test.getTaskBuilder();

  String getTitleToDisplay() => _titleToDisplay;

  Function getNextAction() => _nextAction;

  String getNextActionString() => _nextActionText;
}