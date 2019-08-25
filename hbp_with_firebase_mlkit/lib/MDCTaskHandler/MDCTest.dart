import 'package:flutter/material.dart';
import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/MDCTaskBuilder.dart';
import 'package:hbp_with_firebase_mlkit/MDCTaskHandler/MDCTestBlock.dart';
import 'package:hbp_with_firebase_mlkit/pointer.dart';

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
      '"PointerSpeed"': mappingInfo['"PointerSpeed"'],
      '"MotionThreshold"': mappingInfo['"MotionThreshold"'],
      '"DownSamplingRate"': mappingInfo['"DownSamplingRate"'],
      '"SmoothingFrameCount"': mappingInfo['"SmoothingFrameCount"'],
      '"XAxisMode"': mappingInfo['"XAxisMode"'],
      '"YAxisMode"': mappingInfo['"YAxisMode"'],
    };
  }

  Map<String, dynamic> pointerInformation() => {
    '"PointerType"': enumToString(_pointer.getType()),
    '"EnabledSelectionModes"':
    enumListToStringList(_pointer.getEnabledSelectionModes()),
    '"PointerRadius"': _pointer.getRadius(),
    '"DwellRadius"': _pointer.getDwellRadius(), // size of area dwelling keeps counting
    '"DwellTime"': _pointer.getDwellTime(),
    '"PointerCanvasSize"': sizeToList(_pointer.getCanvasSize()),
    '"PointerMappingInformation"': pointerMappingInformation(),
  };

  Map<String, dynamic> testInformation() => {
    '"TestID"': _testID,
    '"Blocks"': _blocks,
    '"BlockCount"': _blockCount,
    '"PointerInformation"': pointerInformation(),
  };

  void _createBlock({Map config}) {
    _block = MDCTestBlock(_canvasSize, _blockID, _pointer, _now, config: config);
  }

  MDCTest(this._canvasSize, this._testID, this._pointer, this._now, {Map config, context}) {
    _context = context;
    if (config != null)
      _blockCount = config['BlockCount'];
    _config = config;
    _createBlock(config: config);
  }

  void completeBlock() {
    if (_state == TestState.TestCompleted) return;
    print('Completed block!');
    _state = TestState.BlockCompleted;
//    }
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

  void switchNextBlock() {
    print('Switching to the block $_blockID!');
    if (_blockID+1 > _blockCount) {
      _state = TestState.TestCompleted;
      return;
    } else {
      _blocks.add(_block.blockInformation());
      print('New block!');
      _blockID++;
      _pointer.reset();
      _block = MDCTestBlock(_canvasSize, _blockID, _pointer, _now, config: _config);
      _state = TestState.BlockNotStarted;
    }
  }

  Future<bool> isUserSure() async {
    return await showDialog(
        context: _context,
        child: new SimpleDialog(
          title: new Text('Are you sure?'),
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
    if (await isUserSure()) {
      print('Repeat last block!');
      _blockID--;
      _state = TestState.BlockNotStarted;
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

  bool isTestRunning() => _state == TestState.BlockRunning;

  double getLastMovementDuration() => _block.getLastMovementDuration();
}