import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:flutter_circular_chart/flutter_circular_chart.dart';

class AnimatedRadialChartExample extends StatefulWidget {
  const AnimatedRadialChartExample({Key key, String btValue, this.onTap})
      : super(key: key);

  final VoidCallback onTap;
  final String btValue;
  @override
  _AnimatedRadialChartExampleState createState() {
    return new _AnimatedRadialChartExampleState();
  }
}

class _AnimatedRadialChartExampleState
    extends State<AnimatedRadialChartExample> {
  final GlobalKey<AnimatedCircularChartState> _chartKey =
      new GlobalKey<AnimatedCircularChartState>();

  _AnimatedRadialChartExampleState();

  final _chartSize = const Size(200.0, 200.0);

  double value = 100.0;
  Color labelColor = Colors.blue[200];
  double limit = 100.0;

  void _increment() {
    setState(() {
      limit += 10;
      List<CircularStackEntry> data = _generateChartData(value);

      _chartKey.currentState.updateData(data);
    });
  }

  void _decrement() {
    setState(() {
      if (limit < 20) return;
      limit -= 10;
      List<CircularStackEntry> data = _generateChartData(value);
      _chartKey.currentState.updateData(data);
    });
  }

  List<CircularStackEntry> _generateChartData(double value) {
    Color dialColor = Colors.blue[200];
    if (value < 0) {
      dialColor = Colors.red[200];
    } else if (value < limit) {
      dialColor = Colors.green[200];
    }
    labelColor = dialColor;
    print(this.btValue);
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
                  holeLabel: '$value lt',
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
