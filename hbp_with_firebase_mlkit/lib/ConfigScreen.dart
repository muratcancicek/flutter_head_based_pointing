import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/PointingTaskBuilder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hbp_with_firebase_mlkit/pointer.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

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

class ConfigScreen {
  List documents;
  int testID;
  String key;
  dynamic value;
  TestConfiguration dummyConfig = TestConfiguration(
    1, // id
    PointingTaskType.MDC, //pointingTaskType,
    SelectionMode.Blinking,//selectionMode,
    150, // amplitude,
    40, // targetWidth,
    3, // outerTargetCount,
    3, // blockCount
    10, // angle,
    6, // pointerYSpeed
    8, // pointerXSpeed,
  );

  List<TestConfiguration> configs;
  List<TestConfiguration> _finalConfigs;

  void loadLastConfigurations() async {
    configs = List<TestConfiguration>();
    final col = Firestore.instance.collection('LastestConfiguration');
    final data = (await col.getDocuments()).documents.first.data;
    if (data.containsKey('Tests')) {
      final tests = data['Tests'].map((c) =>
          TestConfiguration.fromJSON(new Map<String, dynamic>.from(c))).toList();
      print(tests.runtimeType);
      for (var c in tests)
        configs.add(c);
      print('Loaded the following test variables from cloud: $configs');
    }
    if (configs.length == 0) {
      configs.add(dummyConfig);
    }
    _finalConfigs = List<TestConfiguration>();
    configs.forEach((c) =>
        _finalConfigs.add(TestConfiguration.fromJSON(c.toJSON())));
  }

  ConfigScreen() {
    loadLastConfigurations();
  }


  void editField(int id, String k, dynamic value) {
    print('$id $k $value');
    configs[id-1].update(k, value);
  }

  DropdownMenuItem<dynamic> toDropdownMenuItem(dynamic value) {
    return DropdownMenuItem(
        value: value,
        child: Text(value.toString().split('.').last),
      );
  }
  List<DropdownMenuItem<dynamic>> listToDropdownMenuItem(List list) {
    return list.map(toDropdownMenuItem).toList();
  }

  DropdownButton<dynamic> getDropdownButtonFor(List list, int id, String key, dynamic value) {
    return DropdownButton<dynamic>(
        value: value,
        items: listToDropdownMenuItem(list),
        onChanged: (e) => editField(id, key, e)
    );
  }

  Row getNumberField(int id, String key, dynamic value, {bool decimal: false}) {
    return new Row(children: <Widget>[
          Container(width: 80, child: Text(value.toString()), alignment: Alignment(0.0, 0.0),),
          Container(
              width: 80,
              child: TextField(
                keyboardType: TextInputType.numberWithOptions(decimal: decimal),
                inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
                onChanged: (e) =>  editField(id, key, e),
                onSubmitted: (e) => editField(id, key, e),
              )
        )
      ],
    );
  }

  Widget testEditButton(int id, String key, dynamic value) {
    switch(key) {
      case 'SelectionMode':
        return getDropdownButtonFor(SelectionMode.values, id, key, value);
      case 'PointingTaskType':
        return getDropdownButtonFor(PointingTaskType.values, id, key, value);
      case 'Amplitude':
      case 'TargetWidth':
      case 'OuterTargetCount':
      case 'BlockCount':
        return getNumberField(id, key, value);
      case 'Angle':
      case 'PointerXSpeed':
      case 'PointerYSpeed':
        return getNumberField(id, key, value, decimal: true);
      default:
        return Container(
          width: 70,
          child: Text(value.toString(), textAlign: TextAlign.center),
          alignment: Alignment(0.0, 0.0),
        );
    }
  }

  MapEntry testFeatureText(int id, String k, dynamic v) {
    String s = v.toString();
    if (s.contains('.'))
      s = s.split('.').last;
    return MapEntry(k, Row(
      children: <Widget>[
          Container(
            width: 150,
            child: Text('$k: '),
          ),
          Container(
            height: 40,
            child: testEditButton(id, k, v),
          )
        ],
      ),
    );
  }

  List<Widget> testDetails(TestConfiguration config) {
    List<Widget> list = List<Widget>();
    var m=config.toMap().map((k, v) => testFeatureText(config.id, k, v));
    m.remove('PointingTaskType');
    m.values.forEach((e) => list.add(e));
    final lambda = () {
      configs.removeAt(config.id - 1);
      for (int i = 0; i < configs.length; i++)
        configs[i].id = i + 1;
    };
    list.add(_getAddButton('Delete Test', lambda, Colors.red));
    return list;
  }

  ExpansionTile getTestTile(TestConfiguration config) {
    final id = config.id;
    return ExpansionTile(
      title: Text('Test $id'),
      trailing: Icon(Icons.keyboard_arrow_down),
      children: testDetails(config),
    );
  }

  ExpansionTile _getAddButton(String text, Function onPressed, Color color) {
    return ExpansionTile(
        title: RaisedButton(
          elevation: 4.0,
          color: color,
          textColor: Colors.white,
          child: Text(text),
          splashColor: Colors.blueGrey,
          onPressed: onPressed,
        ),
        trailing: null,
    );
  }

  ListView getTestListView() {
    List<Widget> children = configs.map(getTestTile).toList();
    final lambda = (){
      final last = configs.length > 0 ? configs.last : dummyConfig;
      TestConfiguration c = TestConfiguration.fromJSON(last.toMap());
      c.id = configs.length + 1;
      configs.add(c);
    };
    children.add(_getAddButton('Add Test', lambda, Colors.lightGreen));
    return ListView(children: children);
  }

  Center getConfigsScreenView() {
    return Center(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: getTestListView(),
        )
    );
  }

  List<Map<String, dynamic>> getFinalConfiguration() {
    return _finalConfigs
        .map((TestConfiguration c) => c.toJSON()).toList();
  }

  void save() {
    _finalConfigs = configs;
    final config = getFinalConfiguration();
    final col = Firestore.instance.collection('LastestConfiguration');
    col.document('Configuration').setData({'Tests': config});
    print('Updated config with $config');
  }

  RaisedButton _getAppBarButton() {
    return RaisedButton(
      elevation: 4.0,
      color: Colors.purple,
      textColor: Colors.white,
      child: Text('Save'),
      splashColor: Colors.blueGrey,
      onPressed: save,
    );
  }

  Text _getAppBarText() {
    return Text('Edit Test Variables', textAlign: TextAlign.center);
  }

  AppBar getAppBar(RaisedButton backButton) {
    return AppBar(
      title: _getAppBarText(),
      actions: <Widget>[_getAppBarButton(), backButton],
    );
  }

  void reset() {
    print(_finalConfigs);
    configs = List<TestConfiguration>();
    _finalConfigs.forEach((c) =>
        configs.add(TestConfiguration.fromJSON(c.toJSON())));
  }
}
