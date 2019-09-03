import 'package:HeadPointing/Painting/PointingTaskBuilding/PointingTaskBuilder.dart';
import 'package:HeadPointing/pointer.dart';
class TestConfiguration {
  int id;
  PointingTaskType pointingTaskType;
  SelectionMode selectionMode;
  int amplitude;
  int targetWidth;
  int outerTargetCount;
  int trailCount;
  int blockCount;
  double angle;
  double pointerXSpeed;
  double pointerYSpeed;

  TestConfiguration.fromJSON(Map<String, dynamic> m) {
    id = m['ID'];
    for (SelectionMode mode in SelectionMode.values) {
      if (mode.toString().contains(m['SelectionMode'].toString().split('.').last)) {
        selectionMode = mode;
        break;
      }
    }
    for (PointingTaskType type in PointingTaskType.values) {
      if (type.toString().contains(m['PointingTaskType'].toString().split('.').last)) {
        pointingTaskType = type;
        break;
      }
    }
    amplitude = m['Amplitude'];
    targetWidth = m['TargetWidth'];
    outerTargetCount = m['OuterTargetCount'];
    trailCount = m['TrailCount'];
    blockCount = m['BlockCount'];
    angle = m['Angle'] + .0;
    pointerXSpeed = m['PointerXSpeed'] + .0;
    pointerYSpeed = m['PointerYSpeed'] + .0;
  }

  TestConfiguration(this.id, this.pointingTaskType, this.selectionMode,
      this.amplitude,this.targetWidth, this.outerTargetCount, this.blockCount,
      this.angle, this.pointerXSpeed, this.pointerYSpeed) {
    trailCount = 4 * outerTargetCount;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'ID': id,
    'SelectionMode': selectionMode,
    'PointingTaskType': pointingTaskType,
    'Amplitude': amplitude,
    'TargetWidth': targetWidth,
    'OuterTargetCount': outerTargetCount,
    'TrailCount': trailCount,
    'BlockCount': blockCount,
    'Angle': angle,
    'PointerXSpeed': pointerXSpeed,
    'PointerYSpeed': pointerYSpeed,
  };

  String toString() => toMap().toString();

  Map<String, dynamic> toJSON() => <String, dynamic>{
    'ID': id,
    'SelectionMode': selectionMode.toString().split('.').last,
    'PointingTaskType': pointingTaskType.toString().split('.').last,
    'Amplitude': amplitude,
    'TargetWidth': targetWidth,
    'OuterTargetCount': outerTargetCount,
    'TrailCount': trailCount,
    'BlockCount': blockCount,
    'Angle': angle,
    'PointerXSpeed': pointerXSpeed,
    'PointerYSpeed': pointerYSpeed,
  };

  void update(String key, dynamic value) {
    switch(key) {
      case 'SelectionMode':
        selectionMode = value; break;
      case 'PointingTaskType':
        pointingTaskType = value; break;
      case 'Amplitude':
        amplitude = int.parse(value); break;
      case 'TargetWidth':
        targetWidth = int.parse(value); break;
      case 'OuterTargetCount':
        outerTargetCount = int.parse(value);
        trailCount = 4 + 4 * 2 * outerTargetCount; break;
      case 'BlockCount':
        blockCount = int.parse(value); break;
      case 'Angle':
        angle = double.parse(value); break;
      case 'PointerXSpeed':
        pointerXSpeed = double.parse(value); break;
      case 'PointerYSpeed':
        pointerYSpeed = double.parse(value); break;
    }
  }
}
