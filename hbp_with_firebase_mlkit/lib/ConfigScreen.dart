import 'package:hbp_with_firebase_mlkit/Painting/PointingTaskBuilding/PointingTaskBuilder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hbp_with_firebase_mlkit/pointer.dart';
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
     'SelectionMode': selectionMode,
     'PointingTaskType': PointingTaskType.MDC,
     'Amplitude': amplitude,
     'TargetWidth': targetWidth,
     'OuterTargetCount': outerTargetCount,
     'TrailCount': trailCount,
     'Angle': angle,
     'PointerXSpeed': pointerXSpeed,
     'PointerXSpeed': pointerYSpeed,
   };
}

class ConfigScreen {
  bool _loaded = false;
  List documents;
  TestConfiguration dummyConfig = TestConfiguration(
    99, // id
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
//    final m = {'test': 'timeer'};
//    Firestore.instance.collection('Experiments').document('how').setData(m);
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

  void showTest() {

  }

  MapEntry testFeatureText(String k, dynamic v) {
    return MapEntry(k, Row(
      children: <Widget>[
        Container(
          width: 150,
          child: Text('$k: '),
        ),
        Container(
//          width: 140,
          child: Text(v.toString()),
        ),
//        testEditButton(),
      ],
    ),
    );
  }
  RaisedButton testEditButton() => RaisedButton(child: Icon(Icons.settings), onPressed: showTest);

  List<Widget> testDetails(TestConfiguration config) {
    List<Widget> list = List<Widget>();
    final m=config.toMap().map(testFeatureText).values ;
    m.forEach((e) => list.add(e));
//    forEach((Stlistring k, var v) => list.add(t));
//    list.add(testEditButton());
    return list;
  }
  ExpansionTile testTile(TestConfiguration config) {
    final id = config.id;
    return ExpansionTile(
      title: Text('Test $id'),
      trailing: Icon(Icons.keyboard_arrow_down),
      children: testDetails(config),
    );
  }
  ListView mk() {
    return ListView(children: configs.map(testTile).toList());
  }
  Center f() {
    return Center(
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: mk(),
        )
    );
  }
}
