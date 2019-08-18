import 'package:flutter/material.dart';

class MDCTaskRecorder {
  List<double> _subspaceSwitchingDurations = List<double>();
  List<double> _trialDurations = List<double>();
  List<Offset> _targetPoints = List<Offset>();
  List<List<Offset>> _trails = List<List<Offset>>();
  List<List<Offset>> _transitions = List<List<Offset>>();
  List<Offset> _trialLogs = List<Offset>();
  List<int> _selectionMoments = List<int>();
  int _currentTargetWidth;
  int _outerTargetCount;
  int _currentAmplitude;
  double _dwellTime;

  MDCTaskRecorder() {
    _selectionMoments.add(new DateTime.now().millisecondsSinceEpoch);
  }

  void recordBlockConstants(int amplitude, int targetWidth,
            int outerTargetCount, double dwellTime) {
    _currentAmplitude = amplitude;
    _currentTargetWidth = targetWidth;
    _outerTargetCount = outerTargetCount;
    _dwellTime = dwellTime;
  }

  void recordTargetPoints(List<Offset> targetPoints) {
    _targetPoints.addAll(targetPoints);
  }

  void recordTrialDuration(currentTargetIndex, {dwellTime}) {
    final selectionMoment = new DateTime.now().millisecondsSinceEpoch;
    final trialDuration = (selectionMoment - _selectionMoments.last) / 1000;
    if (currentTargetIndex > 0) {
      _trialDurations.add(trialDuration);
      _trails.add(_trialLogs);
    } else {
      _subspaceSwitchingDurations.add(trialDuration);
      _transitions.add(_trialLogs);
    }
    _selectionMoments.add(selectionMoment);
    _trialLogs = List<Offset>();
  }

  void logPointer(pointer) {
    _trialLogs.add(pointer.getPosition());
  }

  double getLastMovementDuration() {
    if (_trialDurations.length > 0)
      return _trialDurations.last;
    else
      return 0;
  }
}