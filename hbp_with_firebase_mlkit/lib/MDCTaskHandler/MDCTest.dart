import 'package:HeadPointing/Painting/PointingTaskBuilding/MDCTaskBuilder.dart';
import 'package:HeadPointing/MDCTaskHandler/MDCTestBlock.dart';
import 'package:HeadPointing/pointer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TestState {
  BlockNotStarted,
  BlockRunning,
  BlockPaused,
  BlockCompleted,
  TestCompleted,
  StudyCompleted,
}

class MDCTest {
  TestState _state = TestState.BlockNotStarted;
  List<Map> _blocks = List<Map>();
  String _experimentID;
  int _blockCount = 3;
  int _blockID = 1;
  var _canvasSize;
  int _testID = 1;
  int _now = 1;
  var _context;
  Map _config;

  MDCTestBlock _block;
  Pointer _pointer;



  Map<String, dynamic> pointerMappingInformation() {
    final mappingInfo = _pointer.mappingInformation();
    return {
      'PointerSpeed': mappingInfo['PointerSpeed'],
      'MotionThreshold': mappingInfo['MotionThreshold'],
      'DownSamplingRate': mappingInfo['DownSamplingRate'],
      'SmoothingFrameCount': mappingInfo['SmoothingFrameCount'],
      'XAxisMode': mappingInfo['XAxisMode'],
      'YAxisMode': mappingInfo['YAxisMode'],
    };
  }

  Map<String, dynamic> pointerInformation() => {
    'PointerType': enumToString(_pointer.getType()),
    'EnabledSelectionModes':
    enumListToStringList(_pointer.getEnabledSelectionModes()),
    'PointerRadius': _pointer.getRadius(),
    'DwellRadius': _pointer.getDwellRadius(), // size of area dwelling keeps counting
    'DwellTime': _pointer.getDwellTime(),
    'PointerCanvasSize': sizeToList(_pointer.getCanvasSize()),
    'PointerMappingInformation': pointerMappingInformation(),
  };

  Map<String, dynamic> testInformation({bool completedSuccessfully}) => {
    'TestID': _testID,
    'Status': completedSuccessfully ? 'Complete' : 'Incomplete',
    'Blocks': _blocks,
    'BlockCount': _blockCount,
    'PointerInformation': pointerInformation(),
  };

  void _createBlock({Map config}) {
    _block = MDCTestBlock(_canvasSize, _blockID, _pointer, _now, config: config);
  }

  MDCTest(this._canvasSize, this._testID, this._pointer, this._experimentID, this._now, {Map config, context}) {
    _context = context;
    if (config != null)
      _blockCount = config['BlockCount'];
    _config = config;
    _createBlock(config: config);
  }

  void completeBlock() {
    if (_state == TestState.TestCompleted || _state == TestState.StudyCompleted)
      return;
    print('Completed block!');
    _state = TestState.BlockCompleted;
  }

  void update(now, {context}) {
    _context = context;
    _now = now;
    if (_state == TestState.BlockPaused)
    _block.keepPaused(now);
    else if (_state == TestState.BlockRunning)
     _block.log(now);
    if (_block.isCompleted() && _state != TestState.BlockCompleted)
      completeBlock();
  }

  void start() {
    _state = TestState.BlockRunning;
    _block.start(_now);
  }

  void pause() {
    _state = TestState.BlockPaused;
  }

  void resume() {
    print('Resumed block!');
    _state = TestState.BlockRunning;
  }

  void completeStudy() {
    _state = TestState.StudyCompleted;
  }


  void addBlockInfoOnCloud() {
    final blockName = 'T$_testID-B$_blockID';
    final blockInfo = _block.logInformationWithPath(_blockID, _testID);
    CollectionReference col = Firestore.instance.collection(_experimentID);
    col.document(blockName).setData(blockInfo);
  }
  Future<bool> saveBlockIfWanted() async {
    if (await isUserSure(text: 'Save this block?')) {
      addBlockInfoOnCloud();
      _blocks.add(_block.blockInformation(completedSuccessfully: true));
      return true;
    }
    else
      return false;
  }

  Future<bool> switchNextBlock() async {
    if (_blockID+1 > _blockCount) {
      _state = TestState.TestCompleted;
      print(_state);
      return await saveBlockIfWanted();
    }
    else {
      print('New block!');
      final saved = await saveBlockIfWanted();
      _blockID++;
      print('Switching to the block-$_blockID!');
      _pointer.reset();
      _block = MDCTestBlock(_canvasSize, _blockID, _pointer, _now, config: _config);
      _state = TestState.BlockNotStarted;
      return saved;
    }
  }

  Future<bool> isUserSure({String text}) async {
    if (text == null)
      text = 'Are you sure?';
    return await showDialog(
        context: _context,
        builder: (_) => new SimpleDialog(
          title: new Text(text),
          children: <Widget>[
            new SimpleDialogOption(
              child: new Text('YES'),
              onPressed: (){Navigator.pop(_context, true);},
            ),
            new SimpleDialogOption(
              child: new Text('NO'),
              onPressed: (){Navigator.pop(_context, false);},
            ),
          ],
        )
    );
  }
  void restartBlock() async {
    if (await isUserSure()) {
      print('Restart block!');
      _state = TestState.BlockNotStarted;
      _block =
          MDCTestBlock(_canvasSize, _blockID, _pointer, _now, config: _config);
    }
  }

  void repeatBlock() async {
    final blockID = _blockID - 1;
    if (await isUserSure(text: 'Delete Block $blockID records and replay?')) {
      print('Repeat last block!');
      _blockID--;
      _state = TestState.BlockNotStarted;
      _blocks.removeLast();
      _block =
          MDCTestBlock(_canvasSize, _blockID, _pointer, _now, config: _config);
    }
  }

  String getDynamicTitleToDisplay({String prefix}) {
    if (prefix == null)
      return 'B$_blockID of T$_testID:';
    else
      return '$prefix B$_blockID of T$_testID:';
  }

  String getCurrentStatusToDisplay() {
    return _block.getCurrentStatusToDisplay(_testID);
  }

  void setConfiguration(Map<String, dynamic> config) {
    _config = config;
    _blockCount = config['BlockCount'];
    _block = MDCTestBlock(_canvasSize, _blockID, _pointer, _now, config: config);
  }

  MDCTaskBuilder getTaskBuilder() => _block.getTaskBuilder();

  TestState getState() => _state;

  bool isFirstBlock() => _blockID == 1;

  bool isBlockStarted() => _state != TestState.BlockNotStarted;

  bool isBlockPaused() => _state == TestState.BlockPaused;

  bool isBlockCompleted() => _state == TestState.BlockCompleted;

  bool isTestCompleted() => _state == TestState.TestCompleted;

  bool isTestRunning() => _state == TestState.BlockRunning;

  double getLastMovementDuration() => _block.getLastMovementDuration();
}