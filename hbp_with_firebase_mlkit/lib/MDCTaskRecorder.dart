import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/MDCTaskBuilder.dart';
import 'package:hbp_with_firebase_mlkit/pointer.dart';
import 'package:flutter/material.dart';

class MDCTaskRecorder {
  List<double> _subspaceSwitchingDurations = List<double>();
  List<List<List>> _transitions = List<List<List>>();
  List<List<List>> _trails = List<List<List>>();
  List<double> _trailDurations = List<double>();
  List<Offset> _targetPoints = List<Offset>();
  List<int> _selectionMoments = List<int>();
  List<List> _missedSelections = List<List>();
  List<String> _firedSelectionModes = List<String>();
  List<List> _trailLogs = List<List>();
  int _trailID = 0;
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

  Map<String, dynamic> logInformation() => {
    '"SelectionModes"': _firedSelectionModes, // dwelling, blinking record per selection
    '"SelectionMoments"': _selectionMoments,
    '"MissedSelections"':  _missedSelections,
    '"trailDurations"': _trailDurations,
    '"subspaceSwitchingDurations"': _subspaceSwitchingDurations,
    '"trails"': _trails, // frame by frame pointer logs with timestamps
    '"transitions"': _transitions, // pointer logs with timestamps between subspaces
  };

  Map<String, dynamic> blockInformation() => {
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
    '"BlockInformation"': blockInformation(),
    '"PointerInformation"': pointerInformation(),
  };

  MDCTaskRecorder(this._pointer) {
    _selectionMoments.add(new DateTime.now().millisecondsSinceEpoch);
  }

  void updateTaskBuilder(MDCTaskBuilder taskBuilder) {
    _taskBuilder = taskBuilder;
  }

  void recordTargetPoints(List<Offset> targetPoints) {
    _targetPoints.addAll(targetPoints);
  }

  void _recordTrailDuration(currentTargetIndex, selectionMoment) {
    final trialDuration = (selectionMoment - _selectionMoments.last) / 1000;
    _selectionMoments.add(selectionMoment);
    if (currentTargetIndex > 0) {
      _trailDurations.add(trialDuration);
      _trails.add(_trailLogs);
    } else {
      _subspaceSwitchingDurations.add(trialDuration);
      _transitions.add(_trailLogs);
    }
    _trailLogs = List<List>();
  }

  void recordTrail(currentTargetIndex, {dwellTime}) {
    final selectionMoment = new DateTime.now().millisecondsSinceEpoch;
    _recordTrailDuration(currentTargetIndex, selectionMoment);
    final selectionMode = _pointer.getLastFiredSelectionMode();
    _firedSelectionModes.add(enumToString(selectionMode));
    _trailID++;
    print(toJsonBasic());
//    print(jsonEncode(this));
  }

  void _recordIfMissedSelection(log) {
    if (_pointer.pressingDown()) {
      final targetWidth = _taskBuilder.getTargetWidth().toDouble();
      if (!_pointer.touches(_targetPoints[_trailID], targetWidth)) {
        final selectionMode = _pointer.getLastFiredSelectionMode();
        var newLog = List<dynamic>();
        newLog.add(enumToString(selectionMode));
        newLog.addAll(log);
        _missedSelections.add(newLog);
      }
    }
  }

  void logPointerNow() {
    final now = new DateTime.now().millisecondsSinceEpoch;
    final pos = offsetToList(_pointer.getPosition());
    final log = [pos, now];
    _trailLogs.add(log);
    _recordIfMissedSelection(log);
  }

  double getLastMovementDuration() {
    if (_trailDurations.length > 0)
      return _trailDurations.last;
    else
      return 0;
  }
}