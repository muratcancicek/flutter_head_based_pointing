import 'package:HeadPointing/Painting/PointingTaskBuilding/PointingTaskBuilder.dart';
import 'package:HeadPointing/MDCTaskHandler/TestConfiguration.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:HeadPointing/pointer.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

class ConfigScreen {
  List documents;
  int testID;
  String key;
  dynamic value;
  var _context;

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

  List<dynamic> configs;
  List<dynamic> _finalConfigs;

  void _saveConfigFile(config) async {
    final fileName = 'LocalConfiguration';
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String path = appDocDir.path + "/" + fileName+'.json';
    print("Creating file to $path!");
    File file = new File(path);
    final jsonStr = json.encode(config);
    file.createSync();
    file.writeAsStringSync(jsonStr);
  }

  Future<List<TestConfiguration>> loadLastConfigurations() async {
    configs = List<TestConfiguration>();
    final col = Firestore.instance.collection('LastestConfiguration');
    final data = (await col.getDocuments()).documents.first.data;
    if (data.containsKey('Tests')) {
      _saveConfigFile(data['Tests']);
      final tests = data['Tests'].map((c) =>
          TestConfiguration.fromJSON(new Map<String, dynamic>.from(c))).toList();
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
    return _finalConfigs;
  }
  void _loadLocalConfigFile() async {
    final fileName = 'LocalConfiguration';
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String path = appDocDir.path + "/" + fileName+'.json';
    File file = new File(path);
    if (await file.exists()) {
      print("Reading file from $path!");
      final list = json.decode(await file.readAsString());
      configs = list.map((c) => TestConfiguration.fromJSON(c)).toList();
      _finalConfigs = configs;
    } else {
     loadLastConfigurations();
    }
  }

  ConfigScreen({context})  {
    _context = context;
    _loadLocalConfigFile();
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

  ExpansionTile getTestTile(dynamic config) {
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

  Text _getAppBarText() {
    return Text('', textAlign: TextAlign.center);
  }

  List<dynamic> getFinalConfiguration() {
    return _finalConfigs.map((c) => c.toJSON()).toList();
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

  Future _download() async {
    if (await isUserSure(text: 'Overwrite the current test configurations'
        ' with the global configurations?')) {
      loadLastConfigurations();
    }
  }

  RaisedButton _getDownloadButton() {
    return RaisedButton(
      elevation: 4.0,
      color: Colors.purpleAccent,
      textColor: Colors.white,
      child: Text('Download\nGlobal\nConfig'),
      splashColor: Colors.blueGrey,
      onPressed: _download,
    );
  }

  Future _save() async {
    if (await isUserSure(text: 'Save the test configurations locally?')) {
      _finalConfigs = configs;
      final config = getFinalConfiguration();
      print('Updated local config with $config');
      _saveConfigFile(config);
    }
  }

  RaisedButton _getLocalSaveButton() {
    return RaisedButton(
      elevation: 4.0,
      color: Colors.purple,
      textColor: Colors.white,
      child: Text('Save\nConfig\nLocally'),
      splashColor: Colors.blueGrey,
      onPressed: _save,
    );
  }

  Future _upload() async {
    if (await isUserSure(text: 'Overwrite the global test configurations'
        ' with these?')) {
      _finalConfigs = configs;
      final config = getFinalConfiguration();
      final col = Firestore.instance.collection('LastestConfiguration');
      col.document('Configuration').setData({'Tests': config});
      print('Updated global config with $config');
    }
  }

  RaisedButton _getUploadButton() {
    return RaisedButton(
      elevation: 4.0,
      color: Colors.deepPurpleAccent,
      textColor: Colors.white,
      child: Text('Update\nGlobal\nConfig'),
      splashColor: Colors.blueGrey,
      onPressed: _upload,
    );
  }

  AppBar getAppBar(RaisedButton backButton) {
    return AppBar(
      title: _getAppBarText(),
      actions: <Widget>[_getDownloadButton(), _getLocalSaveButton(),
        _getUploadButton(), backButton],
    );
  }

  void reset() {
    print(_finalConfigs);
    configs = List<TestConfiguration>();
    _finalConfigs.forEach((c) =>
        configs.add(TestConfiguration.fromJSON(c.toJSON())));
  }
}
