import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/MDCTaskBuilder.dart';
import 'package:hbp_with_firebase_mlkit/pointer.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MDCTaskRecorder {
  List<Offset> _targetPoints = List<Offset>();
  List<Map> _missedSelections = List<Map>();
  List<Map> _selections = List<Map>();
  List<Map> _trailLogs = List<Map>();
  List<Map> _transitions = List<Map>();
  List<Map> _trails = List<Map>();
  bool _blockStarted = false;
  bool _blockCompleted = false;
  bool _blockPaused = false;
  double _lastMovementDuration = 0;
  double _totalPauseDuration = 0;
  double _pauseDuration = 0;
  double _blockDuration = 0;
  int _blockPauseMoment = 0;
  int _blockStartMoment = 0;
  int _lastSelectionMoment = 1;
  int _missedSelectionID = 1;
  int _selectionID = 1;
  int _transitionID = 1;
  int _targetID = 0;
  int _trailID = 1;
  int _blockID = 1;
  int _testID = 1;
  int _now = 1;
  MDCTaskBuilder _taskBuilder;
  Pointer _pointer;

  List<double> offsetToList(Offset o) => [o.dx, o.dy];

  List<int> offsetToIntList(Offset o) => [o.dx.toInt(), o.dy.toInt()];

  List<double> sizeToList(Size s) => [s.width, s.height];

  List<List<List<double>>> listOfOffsetsToListOfList(List<List<Offset>> list) =>
      list.map((l) => (l.map((e) => offsetToList(e)).toList())).toList();

  String enumToString(e) => '"' + e.toString() + '"';

  List<String> enumListToStringList(List list) =>
      list.map((e) => enumToString(e)).toList();

  Map<String, dynamic> pointerLog(Offset pos, int moment) => {
    '"Moment"': moment,
    '"Position"': offsetToList(pos),
  };

  Map<String, dynamic> trailLog(id, double duration, List<Map> trail, Offset target) => {
    '"ID"': id,
    '"Duration"': duration,
    '"Start"':  trail.first,
    '"End"': trail.last,
    '"Logs"': trail,
    '"TargetID"': _targetID,
    '"TargetLocation"': offsetToList(target),
  };

  Map<String, dynamic> selectionLog(id, int moment, Offset pos, mode, Offset target) => {
    '"ID"': id,
    '"Moment"': moment,
    '"Coordinates"': offsetToList(pos),
    '"Mode"': enumToString(mode),
    '"TargetID"': _targetID,
    '"TargetLocation"': offsetToList(target),
  };

  Map<String, dynamic> logInformation() => {
    '"CorrectSelections"':  _selections,
    '"MissedSelections"':  _missedSelections,
    '"trails"': _trails, // frame by frame pointer logs with timestamps
    '"transitions"': _transitions, // pointer logs with timestamps between subspaces
  };

  Map<String, dynamic> blockInformation(id) => {
    '"ID"': id,
    '"Amplitude"': _taskBuilder.getAmplitude(),
    '"TargetWidth"': _taskBuilder.getTargetWidth(),
    '"BlockTrailCount"': _taskBuilder.getBlockTrailCount(),
    '"OuterTargetCount"': _taskBuilder.getOuterTargetCount(), // ones on circumference
    '"SubspaceTargetCount"': _taskBuilder.getSubspaceTargetCount(), // in a subspace
    '"BlockTargetCount"': _taskBuilder.getBlockTargetCount(), // in the block (4 subspaces)
    '"OffsetToEdges"':  offsetToList(_taskBuilder.getOffsetToEdges()), // location of top-left center
    '"TargetLocations"': _targetPoints.map((o) => offsetToIntList(o)).toList(), // coordinates
    '"TaskBuilderCanvasSize"': sizeToList(_taskBuilder.getCanvasSize()),
    '"LogInformation"': logInformation(), // lists of important timestamps and pointer logs
  };
  
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

  Map<String, dynamic> toJsonBasic() => {
    '"BlockInformation"': blockInformation(_blockID++),
    '"PointerInformation"': pointerInformation(),
  };

  void saveJsonFile({Directory dir, String fileName: 'BlockOne'}) async {
    fileName += (new DateTime.now().millisecondsSinceEpoch).toString();
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String path = appDocDir.path + "/" + fileName+'.json';
    print("Creating file to $path!");
    File file = new File(path);
//    print(appDocDir);
    file.createSync();
    file.writeAsStringSync(toJsonBasic().toString());
  }

  MDCTaskRecorder(this._pointer);

  void updateTaskBuilder(MDCTaskBuilder taskBuilder) {
    _taskBuilder = taskBuilder;
  }

  void recordTargetPoints(List<Offset> targetPoints) {
    _targetPoints.addAll(targetPoints);
  }

  void _recordTrailLog(currentTargetIndex, selectionMoment, target) {
    _lastMovementDuration = (selectionMoment - _lastSelectionMoment) / 1000;
    if (currentTargetIndex > 0) {
      final log = trailLog(_trailID, _lastMovementDuration, _trailLogs, target);
      _trails.add(log);
      _trailID++;
    } else {
      final log = trailLog(_trailID, _lastMovementDuration, _trailLogs, target);
      _transitions.add(log);
      _transitionID++;
    }
    _trailLogs = List<Map>();
  }
  void _recordSelection(currentTargetIndex, selectionMoment, target) {
    final mode = _pointer.getLastFiredSelectionMode();
    final p = _pointer.getPosition();
    final log = selectionLog(_selectionID, selectionMoment, p, mode, target);
    _selections.add(log);
    _selectionID++;
    _targetID++;
  }

  void recordTrail(currentTargetIndex, {dwellTime}) {
    final selectionMoment = _now;
    final target = _targetPoints[_targetID]; // Target Index
    _recordTrailLog(currentTargetIndex, selectionMoment, target);
    _recordSelection(currentTargetIndex, selectionMoment, target);
    _lastSelectionMoment = selectionMoment;
//    print(toJsonBasic());
//    saveJsonFile();
//    print(jsonEncode(this));
  }

  void _recordIfMissedSelection(selectionMoment, position) {
    if (_pointer.pressingDown()) {
      final targetWidth = _taskBuilder.getTargetWidth().toDouble();
      final target = _targetPoints[_targetID]; // Target Index
      if (!_pointer.touches(target, targetWidth)) {
        final selectionMode = _pointer.getLastFiredSelectionMode();
        final log = selectionLog(_missedSelectionID, selectionMoment, position, selectionMode, target);
        _missedSelections.add(log);
        _missedSelectionID++;
      }
    }
  }

  void logPointerNow() {
    final pos = _pointer.getPosition();
    final log = pointerLog(pos, _now);
    _trailLogs.add(log);
    _recordIfMissedSelection(_now, pos);
  }

  void logTime() {
    _now = new DateTime.now().millisecondsSinceEpoch;
//    print((_now - _blockStartMoment) / 1000);
    if (_blockStarted) {
      if (_blockPaused)
        _pauseDuration = (_now - _blockPauseMoment) / 1000;
      else
        _blockDuration =
            (_now - _blockStartMoment) / 1000 - _totalPauseDuration;
    }
  }

  void start() {
    print(_blockStartMoment);
    _blockStarted = true;
    _blockStartMoment = _now;
    _lastSelectionMoment = _blockStartMoment;
    print(_now);
  }

  void pause() {
    _blockPauseMoment = _now;
    _blockPaused = true;
  }

  void resume() {
    print('Resumed block!');
    _blockPauseMoment = _now;
    _totalPauseDuration += _pauseDuration;
    print(_totalPauseDuration);
    _blockPaused = false;
  }

  bool isBlockStarted() => _blockStarted;

  bool isBlockPaused() => _blockPaused;

  bool isBlockCompleted() => _blockCompleted;

  bool isTestRunning() => _blockStarted && !_blockPaused;

  double getLastMovementDuration() => _lastMovementDuration;

  String _doubleToPrettyString(double d, {int padding: 4, int frictions: 0}) {
    return d.toStringAsFixed(frictions).padLeft(padding, '0');
  }

  String _getBlockOutputToDisplay() {
    final target = _targetID.toString().padLeft(2, '0');
    final count = _taskBuilder.getBlockTargetCount().toString().padLeft(2, '0');
    final duration = _doubleToPrettyString(_blockDuration);
    return 'Ts: $_testID B: $_blockID T: $target/$count D: $duration';
  }

  String _getDynamicTitleToDisplay({String prefix: 'Start'}) {
    return '$prefix Block $_blockID of Test $_testID:';
  }

  String getTitleToDisplay() {
    if (isTestRunning())
      return _getBlockOutputToDisplay();
    else if (!_blockStarted)
      return _getDynamicTitleToDisplay();
    else if (_blockPaused)
      return _getDynamicTitleToDisplay(prefix: 'Resume');
    else if (_blockCompleted)
      return _getDynamicTitleToDisplay(prefix: 'Summary of');
    else
      return 'Head-based Pointing with Flutter';
  }
}