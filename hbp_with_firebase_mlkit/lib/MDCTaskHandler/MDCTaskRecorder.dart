import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/MDCTaskBuilder.dart';
import 'package:hbp_with_firebase_mlkit/MDCTaskHandler/MDCTest.dart';
import 'package:hbp_with_firebase_mlkit/pointer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MDCTaskRecorder {
  List<Map<String, dynamic>> configs;
  Map<String, dynamic> _tests = Map<String, dynamic>();
  String _exitActionTest = 'Exit\nStudy';
  String _backActionText = 'Discard';
  String _nextActionText = 'Start';
  String _titleToDisplay = '';
  Function _closeAction;
  Function _nextAction;
  Function _backAction;
  Function _exitAction;
  int _testCount = 2;
  String _experimentID;
  String _subjectID;
  Pointer _pointer;
  int _testID = 1;
  var _canvasSize;
  var _context;
  MDCTest _test;
  bool _completed = false;
  bool _currentTestUploaded = false;

  Map<String, dynamic> subjectInformation({bool completedSuccessfully: true}) => {
    'ExperimentID': _experimentID,
    'SubjectID': _subjectID,
    'Status': completedSuccessfully ? 'Complete' : 'Incomplete',
    'TestCount': _testCount,
    'Tests': _tests,
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
    _currentTestUploaded = false;
  }

  MDCTaskRecorder(this._canvasSize, this._pointer, this._experimentID, this._subjectID, {Function exitAction, context}) {
    _context = context;
    _closeAction = exitAction;
    _createTest(); //config: configs[_testID-1]
    _nextAction = _test.start;
  }

  void _applyCurrentConfiguration() {
    final currentConfig = configs[_testID-1];
    _testCount = configs.length;
    _pointer.updateSelectionMode(currentConfig['SelectionMode']);
    _pointer.updateYSpeed(currentConfig['PointerXSpeed']);
    _pointer.updateYSpeed(currentConfig['PointerYSpeed']);
    _test.setConfiguration(currentConfig);
  }

  void updateTestInfoOnCloud(completedSuccessfully) {
    final expInfo = subjectInformation(completedSuccessfully: completedSuccessfully);
    Firestore.instance.collection(_experimentID).document('Test Logs').setData(expInfo);
  }

  void _restartTest() async {
    if (await _test.isUserSure()) {
      print('Restart test!');
      _pointer.reset();
      _createTest(config: configs[_testID - 1]);
      _applyCurrentConfiguration();
    }
  }

  Future<bool> saveTestIfWanted(completedSuccessfully, {exp: false}) async {
    if (await _test.isUserSure(text: 'Save Test $_testID?')) {
      final info = _test.testInformation(completedSuccessfully: exp);
//      if (_tests.length > 0)
//        if (_currentTestUploaded)
//          _tests.removeLast();
      _tests[_testID.toString()] = info;
      updateTestInfoOnCloud(completedSuccessfully);
      return true;
    }
    else
      return false;
  }

  void switchNextTest() async {
    if (_testID+1 > _testCount) {
      _test.completeStudy();
      await saveTestIfWanted(true, exp: true);
      return;
    }
    await saveTestIfWanted(true);
    print('New test!');
    _testID++;
    _pointer.reset();
    _createTest(config: configs[_testID-1]);
    _applyCurrentConfiguration();
  }

  void _repeatTest() async {
    final testID = _testID - 1;
    if (await _test.isUserSure(text: 'Delete Test $testID records and replay?')) {
      print('Repeat last test!');
//      if (_tests.length > 0)
//        _tests.removeLast();
      if (_testID > 1 && _testID < _testCount)
        _testID--;
      _pointer.reset();
      _createTest(config: configs[_testID - 1]);
      _applyCurrentConfiguration();
    }
  }

  void switchNextBlock() async {
    if (_completed) {
      return;
    }
    final saved = await _test.switchNextBlock();
    print(_test.getState());
    if (saved) {
//      if (_tests.length > 0)
//        _tests.removeLast();
      _tests[_testID.toString()] = _test.testInformation(completedSuccessfully: false);
      updateTestInfoOnCloud(false);
      _currentTestUploaded = true;
    }
  }

  void update({context}) {
    _context = context;
    if (_completed) {
      _nextAction = _exitAction;
      _nextActionText = 'NEXT\nSubject!';
      _titleToDisplay = 'ALL DONE!';
      return;
    }
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
        _nextAction = switchNextBlock;
        _nextActionText = 'NEXT!';
        _titleToDisplay = _test.getDynamicTitleToDisplay();
        break;
      case TestState.TestCompleted:
        _exitAction = _closeAction;
        _exitActionTest = 'End\nExp.';
        _backAction = _restartTest;
        _backActionText = 'Restart\nTest';
        _nextAction = switchNextTest;
        _nextActionText = 'NEXT\nTEST!';
        _titleToDisplay = 'End of T$_testID:';
        break;
      case TestState.StudyCompleted:
        _completed = true;
        _nextAction = _exitAction;
        _nextActionText = 'NEXT\nSubject!';
        _titleToDisplay = 'ALL DONE!';
        saveTestIfWanted(true);
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