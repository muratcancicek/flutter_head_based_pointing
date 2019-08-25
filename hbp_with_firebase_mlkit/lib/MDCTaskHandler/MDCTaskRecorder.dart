import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/MDCTaskBuilder.dart';
import 'package:hbp_with_firebase_mlkit/MDCTaskHandler/MDCTest.dart';
import 'package:hbp_with_firebase_mlkit/pointer.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MDCTaskRecorder {
  List<Map<String, dynamic>> configs;
  List<Map> _tests = List<Map>();
  String _exitActionTest = 'Exit\nStudy';
  String _backActionText = 'Discard';
  String _nextActionText = 'Start';
  String _titleToDisplay = '';
  Function _closeAction;
  Function _nextAction;
  Function _backAction;
  Function _exitAction;
  int _testCount = 2;
  int _subjectID = 1;
  Pointer _pointer;
  int _testID = 1;
  var _canvasSize;
  var _context;
  MDCTest _test;


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
    _test = MDCTest(_canvasSize, _testID, _pointer, now);
    _backAction = _test.restartBlock;
  }

  MDCTaskRecorder(this._canvasSize, this._pointer, {Function exitAction, context}) {
    _context = context;
    _closeAction = exitAction;
    _createTest(); //config: configs[_testID-1]
    _nextAction = _test.start;
  }

  void _applyCurrentConfiguration() {
    final currentConfig = configs[_testID-1];
    _pointer.updateSelectionMode(currentConfig['SelectionMode']);
    _pointer.updateYSpeed(currentConfig['PointerXSpeed']);
    _pointer.updateYSpeed(currentConfig['PointerYSpeed']);
    _test.setConfiguration(currentConfig);
  }

  void _restartTest() async {
    if (await _test.isUserSure()) {
      print('Restart test!');
      _pointer.reset();
      _createTest(config: configs[_testID - 1]);
      _applyCurrentConfiguration();
    }
  }

  void switchNextTest() {
    if (_testID > _testCount) {
      return;
    }
    _tests.add(_test.testInformation());
    print('New test!');
    _testID++;
    _pointer.reset();
    _createTest(config: configs[_testID-1]);
    _applyCurrentConfiguration();
  }

  void _repeatTest() async {
    if (await _test.isUserSure()) {
      print('Repeat last !');
      _testID--;
      _pointer.reset();
      _createTest(config: configs[_testID - 1]);
      _applyCurrentConfiguration();
    }
  }

  void update({context}) {
    _context = context;
    _test.update(new DateTime.now().millisecondsSinceEpoch, context: _context);
    switch(_test.getState()) {
      case TestState.BlockNotStarted:
        _exitAction = _closeAction;
        _exitActionTest = 'End\nExp.';
        if (_test.isFirstBlock()) {
          if (_testID > 1) {
            _backAction = _repeatTest;
            _backActionText = 'Repeat\nLast\nTest';
          } else
            _backAction = null;
        } else {
          _backAction = _test.repeatBlock;
          _backActionText = 'Repeat\nLast\nBlock';
        }
        _nextAction = _test.start;
        _nextActionText = 'START!';
        _titleToDisplay = _test.getDynamicTitleToDisplay();
        break;
      case TestState.BlockRunning:
        _exitAction = null;
        _backAction = null;
        _nextAction = _test.pause;
        _nextActionText = 'PAUSE!';
        _titleToDisplay = _test.getCurrentStatusToDisplay();
        break;
      case TestState.BlockPaused:
        _exitAction = _closeAction;
        _exitActionTest = 'End\nExp.';
        _backAction = _test.restartBlock;
        _backActionText = 'Restart\nBlock';
        _nextAction = _test.resume;
        _nextActionText = 'RESUME!';
        _titleToDisplay = _test.getDynamicTitleToDisplay();
        break;
      case TestState.BlockCompleted:
        _exitAction = _closeAction;
        _exitActionTest = 'End\nExp.';
        _backAction = _test.restartBlock;
        _backActionText = 'Restart\nBlock';
        _nextAction = _test.switchNextBlock;
        _nextActionText = 'NEXT!';
        _titleToDisplay = _test.getDynamicTitleToDisplay();
        break;
      case TestState.TestCompleted:
        _exitAction = _closeAction;
        _exitActionTest = 'End\nExp.';
        _backAction = _restartTest;
        _backActionText = 'Restart\nTest';
        if (_testID < _testCount) {
          _nextAction = switchNextTest;
          _nextActionText = 'NEXT\nTEST!';
          _titleToDisplay = 'End of T$_testID:';
        }
        else {
          _nextAction = _exitAction;
          _nextActionText = 'NEXT\nSubject!';
          _titleToDisplay = 'ALL DONE!';
        }
        break;
      default:
        _backAction = _exitAction;
        _backActionText = 'Back';
        _nextAction = _test.start;
        _nextActionText = 'RUN!';
        _titleToDisplay = 'Head-based Pointing with Flutter';
    }
  }

  void setConfiguration(List<Map<String, dynamic>> finalConfiguration) {
    configs = finalConfiguration;
    _applyCurrentConfiguration();
  }

  MDCTest getCurrentTest() => _test;

  MDCTaskBuilder getTaskBuilder() => _test.getTaskBuilder();

  String getTitleToDisplay() => _titleToDisplay;

  Function getNextAction() => _nextAction;

  String getNextActionString() => _nextActionText;

  Function getExitAction() => _exitAction;

  String getExitActionString() => _exitActionTest;

  Function getBackAction() => _backAction;

  String getBackActionString() => _backActionText;

  bool isStudyCompleted() => _testID > _testCount;

  bool isPaused() => _test.isBlockPaused();
}