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
  List<List<double>> _trailLogs = List<List<double>>();
  MDCTaskBuilder _taskBuilder;
  Pointer _pointer;

  List<double> offsetToList(Offset o) => [o.dx, o.dy];

  List<int> offsetToIntList(Offset o) => [o.dx.toInt(), o.dy.toInt()];

  List<double> sizeToList(Size s) => [s.width, s.height];

  List<List<List<double>>> listOfOffsetsToListOfList(List<List<Offset>> list) =>
      list.map((l) => (l.map((e) => offsetToList(e)).toList())).toList();

  Map<String, dynamic> toJsonBasic() => {
    '\"Amplitude\"': _taskBuilder.getAmplitude(),
    '\"TargetWidth\"': _taskBuilder.getTargetWidth(),
    '\"OuterTargetCount\"': _taskBuilder.getOuterTargetCount(),
    '\"SubspaceTargetCount\"': _taskBuilder.getSubspaceTargetCount(),
    '\"BlockTargetCount\"': _taskBuilder.getBlockTargetCount(),
    '\"OffsetToEdges\"':  offsetToList(_taskBuilder.getOffsetToEdges()),
    '\"TargetLocations\"': _targetPoints,
    '\"TaskBuilderCanvasSize\"': sizeToList(_taskBuilder.getCanvasSize()),
    '\"DwellTime\"': _pointer.getDwellTime(),
    '\"DwellRadius\"': _pointer.getDwellRadius(),
    '\"PointerRadius\"': _pointer.getRadius(),
    '\"PointerType\"': '\"'+_pointer.getType().toString()+'\"',
    '\"PointerCanvasSize\"': sizeToList(_pointer.getCanvasSize()),
    '\"SelectionMoments\"': _selectionMoments,
    '\"trailDurations\"': _trailDurations,
    '\"subspaceSwitchingDurations\"': _subspaceSwitchingDurations,
    '\"trails\"': _trails,
    '\"transitions\"': _transitions,
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

  void recordTrailDuration(currentTargetIndex, {dwellTime}) {
    final selectionMoment = new DateTime.now().millisecondsSinceEpoch;
    final trialDuration = (selectionMoment - _selectionMoments.last) / 1000;
    if (currentTargetIndex > 0) {
      _trailDurations.add(trialDuration);
      _trails.add(_trailLogs);
    } else {
      _subspaceSwitchingDurations.add(trialDuration);
      _transitions.add(_trailLogs);
    }
    _selectionMoments.add(selectionMoment);
    _trailLogs = List<List<double>>();
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