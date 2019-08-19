import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/MDCTaskBuilder.dart';
import 'package:hbp_with_firebase_mlkit/pointer.dart';
import 'package:flutter/material.dart';

class MDCTaskRecorder {
  List<double> _subspaceSwitchingDurations = List<double>();
  List<List<List<double>>> _transitions = List<List<List<double>>>();
  List<List<List<double>>> _trails = List<List<List<double>>>();
  List<double> _trailDurations = List<double>();
  List<List<int>> _targetPoints = List<List<int>>();
  List<int> _selectionMoments = List<int>();
  List<String> _firedSelectionModes = List<String>();
  List<List<double>> _trailLogs = List<List<double>>();
  MDCTaskBuilder _taskBuilder;
  Pointer _pointer;

  List<double> offsetToList(Offset o) => [o.dx, o.dy];

  List<int> offsetToIntList(Offset o) => [o.dx.toInt(), o.dy.toInt()];

  List<double> sizeToList(Size s) => [s.width, s.height];

  List<List<List<double>>> listOfOffsetsToListOfList(List<List<Offset>> list) =>
      list.map((l) => (l.map((e) => offsetToList(e)).toList())).toList();

  Map<String, dynamic> logInformation() => {
    '"SelectionModes"': _firedSelectionModes, // dwelling, blinking record per selection
    '"SelectionMoments"': _selectionMoments,
    '"trailDurations"': _trailDurations,
    '"subspaceSwitchingDurations"': _subspaceSwitchingDurations,
    '"trails"': _trails, // frame by frame pointer logs with timestamps
    '"transitions"': _transitions, // pointer logs with timestamps between subspaces
  };

  Map<String, dynamic> blockInformation() => {
    '"Amplitude"': _taskBuilder.getAmplitude(),
    '"TargetWidth"': _taskBuilder.getTargetWidth(),
    '"OuterTargetCount"': _taskBuilder.getOuterTargetCount(), // ones on circumference
    '"SubspaceTargetCount"': _taskBuilder.getSubspaceTargetCount(), // in a subspace
    '"BlockTargetCount"': _taskBuilder.getBlockTargetCount(), // in the block (4 subspaces)
    '"OffsetToEdges"':  offsetToList(_taskBuilder.getOffsetToEdges()), // location of top-left center
    '"TargetLocations"': _targetPoints, // coordinates
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

  String enumToString(e) => '"' + e.toString() + '"';

  List<String> enumListToStringList(List list) =>
                          list.map((e) => enumToString(e)).toList();

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
//    '"BlockInformation"': blockInformation(),
//    '"PointerInformation"': pointerInformation(),
  };

  MDCTaskRecorder(this._pointer) {
    _selectionMoments.add(new DateTime.now().millisecondsSinceEpoch);
  }

  void updateTaskBuilder(MDCTaskBuilder taskBuilder) {
    _taskBuilder = taskBuilder;
  }

  void recordTargetPoints(List<Offset> targetPoints) {
    _targetPoints.addAll(targetPoints.map((o) => offsetToIntList(o)));
  }

  void _recordTrailDuration(currentTargetIndex, selectionMoment) {
    final trialDuration = (selectionMoment - _selectionMoments.last) / 1000;
    if (currentTargetIndex > 0) {
      _trailDurations.add(trialDuration);
      _trails.add(_trailLogs);
    } else {
      _subspaceSwitchingDurations.add(trialDuration);
      _transitions.add(_trailLogs);
    }
    _trailLogs = List<List<double>>();

  }

  void recordTrail(currentTargetIndex, {dwellTime}) {
    final selectionMoment = new DateTime.now().millisecondsSinceEpoch;
    _selectionMoments.add(selectionMoment);
    _recordTrailDuration(currentTargetIndex, selectionMoment);
    final selectionMode = _pointer.getLastFiredSelectionMode();
    _firedSelectionModes.add(enumToString(selectionMode));
    print(toJsonBasic());
//    print(jsonEncode(this));
  }

  void logPointer(pointer) {
    var pos = offsetToList(pointer.getPosition());
    pos.add((new DateTime.now().millisecondsSinceEpoch).toDouble());
    _trailLogs.add(pos);
  }

  double getLastMovementDuration() {
    if (_trailDurations.length > 0)
      return _trailDurations.last;
    else
      return 0;
  }
}