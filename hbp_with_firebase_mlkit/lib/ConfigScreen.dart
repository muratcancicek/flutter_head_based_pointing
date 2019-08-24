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
  double angle;
  double pointerXSpeed;
  double pointerYSpeed;

  TestConfiguration(this.id, this.pointingTaskType, this.selectionMode,
      this.amplitude,this.targetWidth, this.outerTargetCount,
      this.angle, this.pointerXSpeed, this.pointerYSpeed) {
     trailCount = outerTargetCount;
   }

   Map<String, dynamic> toMap() => <String, dynamic>{
     'ID': id,
     'SelectionMode': selectionMode,
     'PointingTaskType': pointingTaskType,
     'Amplitude': amplitude,
     'TargetWidth': targetWidth,
     'OuterTargetCount': outerTargetCount,
     'TrailCount': trailCount,
     'Angle': angle,
     'PointerXSpeed': pointerXSpeed,
     'PointerYSpeed': pointerYSpeed,
   };

  Map<String, dynamic> toJSON() => <String, dynamic>{
    'ID': id,
    'SelectionMode': selectionMode.toString().split('.').last,
    'PointingTaskType': pointingTaskType.toString().split('.').last,
    'Amplitude': amplitude,
    'TargetWidth': targetWidth,
    'OuterTargetCount': outerTargetCount,
    'TrailCount': trailCount,
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
        outerTargetCount = int.parse(value); break;
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
  bool _loaded = false;
  List documents;
  int testID;
  String key;
  dynamic value;
  TestConfiguration dummyConfig = TestConfiguration(
    0, // id
    PointingTaskType.MDC, //pointingTaskType,
    SelectionMode.Blinking,//selectionMode,
    150, // amplitude,
    80, // targetWidth,
    0, // outerTargetCount,
    30, // angle,
    6, // pointerYSpeed
    8, // pointerXSpeed,
  );

  List<TestConfiguration> configs;

  ConfigScreen() {
    configs = List<TestConfiguration>();
    configs.add(dummyConfig);
  }

  Center displayConfigScreen() {
    return Center(
      child: Container(
          child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: <Widget>[
          Text('Summary',
              style: TextStyle(
                color: Colors.green,
                fontSize: 30.0,
              )),
        ],
      )),
    );
  }

  Map parse(DocumentSnapshot document) {
    return document.data;
  }

  List l(List documents) {
    return documents.map((d) => new Text(d['test'])).toList();
  }

  Widget m(AsyncSnapshot<QuerySnapshot> snapshot) {
    documents = snapshot.data.documents.map(parse).toList();
    _loaded = true;
    return new ListView(children: l(documents));
  }

  Widget builder(BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.hasError)
      return new Text('Error: ${snapshot.error}');
    switch (snapshot.connectionState) {
      case ConnectionState.waiting:
        return new Text('Loading...');
      default:
        return m(snapshot);
    }
  }

  StreamBuilder<QuerySnapshot> streamBuilder() {
   Stream<QuerySnapshot> stream = Firestore.instance.collection('Experiments').snapshots();
    return StreamBuilder<QuerySnapshot>(stream: stream, builder: builder);
  }

  Center w() {
    return Center(
      child: Container(
          padding: const EdgeInsets.all(10.0),
          child: _loaded ?  new ListView(children: l(documents)) : streamBuilder(),
        )
      );
  }

  void editField(int id, String k, dynamic value) {
    print('$id $k $value');
    configs[id].update(k, value);
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
          Container(width: 80, child: Text(value.toString())),
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
        return getNumberField(id, key, value);
      case 'Angle':
      case 'PointerXSpeed':
      case 'PointerYSpeed':
        return getNumberField(id, key, value, decimal: true);
      default:
        return Text(value.toString(), textAlign: TextAlign.center);
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
    final m=config.toMap().map((k, v) => testFeatureText(config.id, k, v)).values;
    m.forEach((e) => list.add(e));
//    forEach((Stlistring k, var v) => list.add(t));
//    list.add(testEditButton());
    return list;
  }

  ExpansionTile getTestTile(TestConfiguration config) {
    final id = config.id;
    return ExpansionTile(
      title: Text('Test $id'),
      trailing: Icon(Icons.keyboard_arrow_down),
      children: testDetails(config),
//      onExpansionChanged: (bool c) => {if (c){testID = config.id}},
    );
  }

  ListView getTestListView() {
    return ListView(children: configs.map(getTestTile).toList());
  }

  Center getConfigsScreenView() {
    return Center(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: getTestListView(),
        )
    );
  }

  void save() {
    final m = {'test': 'timeer'};
    String date = new DateTime.now().toIso8601String().replaceAll(':', '-');
    date = date.split('.').first;
    Firestore.instance.document('Test_$date');
    Firestore.instance.collection('Test_$date').document('how').setData(m);
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

  List<Map<String, dynamic>> getFinalConfiguration() {
    return configs.map((TestConfiguration c) => c.toJSON()).toList();
  }
}
