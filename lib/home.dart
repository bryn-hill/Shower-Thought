import 'dart:ffi';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeSeriesBar extends StatelessWidget {
  final List<TimeSeriesWater> seriesList;
  final bool animate;

  TimeSeriesBar(this.seriesList, {this.animate});

  @override
  Widget build(BuildContext context) {
    var seriesData = [
      new charts.Series<TimeSeriesWater, DateTime>(
        id: 'Water Consumption',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeSeriesWater water, _) => water.time,
        measureFn: (TimeSeriesWater water, _) =>
            int.tryParse(water.waterConsumption),
        data: seriesList,
      )
    ];
    print(seriesData);
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        Container(
            height: 300,
            color: Colors.white,
            child: new charts.TimeSeriesChart(
              seriesData,
              animate: animate,
              // Set the default renderer to a bar renderer.
              // This can also be one of the custom renderers of the time series chart.
              defaultRenderer: new charts.BarRendererConfig<DateTime>(),
              // It is recommended that default interactions be turned off if using bar
              // renderer, because the line point highlighter is the default for time
              // series chart.
              defaultInteractions: false,
              // If default interactions were removed, optionally add select nearest
              // and the domain highlighter that are typical for bar charts.
              behaviors: [
                new charts.SelectNearest(),
                new charts.DomainHighlighter()
              ],
            )),
        Container(
          height: 450,
          color: Colors.grey[100],
          child: new Items(seriesList),
        ),
      ],
    );
  }
}

class Items extends StatelessWidget {
  final List<TimeSeriesWater> items;
  Items(this.items);

  Widget _buildProductItem(BuildContext context, int index) {
    return ListView(
      shrinkWrap: true,
      children: <Widget>[
        ListTile(
            title: Text(new DateFormat('yyyy-MM-dd').format(items[index].time),
                style: TextStyle(color: Colors.deepPurple)),
            subtitle: Text(items[index].waterConsumption,
                style: TextStyle(color: Colors.deepPurple)))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: _buildProductItem,
      itemCount: items.length,
    );
  }
}

/// Sample time series data type.
class TimeSeriesWater {
  final DateTime time;
  final String waterConsumption;

  TimeSeriesWater(this.time, this.waterConsumption);
}
