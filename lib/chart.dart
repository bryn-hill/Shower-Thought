import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_circular_chart/flutter_circular_chart.dart';
import 'package:intl/intl.dart';

class AnimatedRadialChartExample extends StatefulWidget {
  final VoidCallback onTap;

  final BluetoothCharacteristic btValue;

  const AnimatedRadialChartExample({Key key, this.btValue, this.onTap})
      : super(key: key);

  @override
  _AnimatedRadialChartExampleState createState() {
    return new _AnimatedRadialChartExampleState(btValue);
  }
}

class _AnimatedRadialChartExampleState
    extends State<AnimatedRadialChartExample> {
  final GlobalKey<AnimatedCircularChartState> _chartKey =
      new GlobalKey<AnimatedCircularChartState>();

  final _chartSize = const Size(200.0, 200.0);

  double value = 0;
  Color labelColor = Colors.blue[200];
  double limit = 20;

  BluetoothCharacteristic _btValue;

  StreamSubscription<List<int>> getValueSub;

  _AnimatedRadialChartExampleState(BluetoothCharacteristic btValue) {
    _btValue = btValue;
  }
  var _result;

  void _increment() {
    print(_result);
    setState(() {
      limit += 10;
    });
    Firestore.instance
        .collection('me')
        .document('shower')
        .setData({'limit': limit}, merge: true);
    List<CircularStackEntry> data = _generateChartData(value);

    _chartKey.currentState.updateData(data);
  }

  void _decrement() {
    if (limit < 20) return;
    setState(() {
      limit -= 10;
    });
    Firestore.instance
        .collection('me')
        .document('shower')
        .setData({'limit': limit}, merge: true);
    List<CircularStackEntry> data = _generateChartData(value);
    _chartKey.currentState.updateData(data);
  }

  List<CircularStackEntry> _generateChartData(double value) {
    Color dialColor = Colors.blue[200];
    if (value < 0) {
      dialColor = Colors.red[200];
    } else if (value < limit) {
      dialColor = Colors.green[200];
    }
    labelColor = dialColor;

    List<CircularStackEntry> data = <CircularStackEntry>[
      new CircularStackEntry(
        <CircularSegmentEntry>[
          new CircularSegmentEntry(
            (value / limit) * 100,
            dialColor,
            rankKey: 'percentage',
          )
        ],
        rankKey: 'percentage',
      ),
    ];

    if (value > limit) {
      labelColor = Colors.red[200];

      data.add(new CircularStackEntry(
        <CircularSegmentEntry>[
          new CircularSegmentEntry(
            ((value - limit) / limit) * 100,
            Colors.red[200],
            rankKey: 'percentage',
          ),
        ],
        rankKey: 'percentage2',
      ));
    }

    return data;
  }

  @override
  void initState() {
    super.initState();

    Firestore.instance
        .collection('me')
        .document('shower')
        .get()
        .then((DocumentSnapshot ds) {
      if (limit == ds.data['limit'] || ds.data['limit'] == null) return;
      setState(() {
        limit = ds.data['limit'];
      });
      List<CircularStackEntry> data = _generateChartData(value);

      _chartKey.currentState.updateData(data);
    });

    _btValue.setNotifyValue(true).then((a) {
      getValueSub =
          // If we need to rebuild the widget with the resulting data,
          // make sure to use `setState`
          _btValue.value.listen((_value) {
        Uint8List input = Uint8List.fromList(_value);
        ByteData bd = input.buffer.asByteData();
        double converted = bd.getFloat32(0, Endian.little);
        if ((value == converted) || converted == null) return;
        setState(() {
          value = converted;
        });
        List<CircularStackEntry> data = _generateChartData(value);
        _chartKey.currentState.updateData(data);
      });
    });
  }

  @override
  void dispose() {
    getValueSub.cancel();
    var now = new DateTime.now();
    String formattedDate = new DateFormat('yyyy-MM-dd').format(now);
    Firestore.instance
        .collection('me')
        .document('shower')
        .setData({formattedDate: value}, merge: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle _labelStyle = Theme.of(context)
        .textTheme
        .title
        .merge(new TextStyle(color: labelColor));

    return new Container(
        margin: const EdgeInsets.all(50.0),
        height: 300.0,
        width: 500.0,
        child: Align(
          alignment: Alignment(100, 50),
          child: new Column(
            children: <Widget>[
              //FlutterBlueApp(),
              new Text(
                'Daily Water Usage',
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[200],
                    fontSize: 20),
              ),
              new Container(
                child: new AnimatedCircularChart(
                  key: _chartKey,
                  size: _chartSize,
                  initialChartData: _generateChartData(value),
                  chartType: CircularChartType.Radial,
                  edgeStyle: SegmentEdgeStyle.round,
                  percentageValues: true,
                  holeLabel: value.toStringAsFixed(2) + ' lt',
                  labelStyle: _labelStyle,
                ),
              ),
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  new RaisedButton(
                    onPressed: _decrement,
                    child: const Icon(Icons.remove),
                    shape: const CircleBorder(),
                    color: Colors.red[200],
                    textColor: Colors.white,
                  ),
                  new Text(
                    'Daily Limit:$limit lt',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.blue[200]),
                  ),
                  new RaisedButton(
                    onPressed: _increment,
                    child: const Icon(Icons.add),
                    shape: const CircleBorder(),
                    color: Colors.blue[200],
                    textColor: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ));
  }
}
