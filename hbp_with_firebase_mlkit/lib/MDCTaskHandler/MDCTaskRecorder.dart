import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/MDCTaskBuilder.dart';
import 'package:hbp_with_firebase_mlkit/MDCTaskHandler/MDCTest.dart';
import 'package:hbp_with_firebase_mlkit/pointer.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MDCTaskRecorder {
  String _titleToDisplay = '';
  String _nextActionText = 'Start';
  Function _nextAction;
  int _testID = 1;
  MDCTest _test;

  void saveJsonFile({Directory dir, String fileName: 'BlockOne'}) async {
    fileName += (new DateTime.now().millisecondsSinceEpoch).toString();
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String path = appDocDir.path + "/" + fileName+'.json';
    print("Creating file to $path!");
    File file = new File(path);
    final json = _test.toJsonBasic().toString();
    file.createSync();
    file.writeAsStringSync(json);
  }

  void _createTest(Pointer pointer) {
    _test = MDCTest(_testID, pointer, new DateTime.now().millisecondsSinceEpoch);
  }

  MDCTaskRecorder(Pointer pointer) {
    _createTest(pointer);
    _nextAction = _test.start;
  }

  void update() {
    _test.update(new DateTime.now().millisecondsSinceEpoch);
    print(_test.getState());
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
        _nextAction = _createTest;
        _nextActionText = 'NEXT!';
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