import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:keep_up/style.dart';

class AppChartDataPoint {
  final DateTime x;
  final double y;

  AppChartDataPoint({required this.x, required this.y});
}

class AppChart extends StatefulWidget {
  final String title;
  final String? description;
  final Color? backgroundColor;
  //final List<AppChartDataPoint> points;
  const AppChart({
    Key? key,
    required this.title,
    this.description,
    this.backgroundColor = AppColors.primaryColor,
    /*required this.points*/
  }) : super(key: key);

  @override
  _AppChartState createState() => _AppChartState();
}

class _AppChartState extends State<AppChart> {
  late List<Color> gradientColors;
  bool showAvg = false;

  @override
  void initState() {
    gradientColors = [widget.backgroundColor!];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final data = mainData();
    final columnWidth = 1.5 * data.lineBarsData.first.spots.length * 25;
    return Column(children: [
      Align(
          alignment: Alignment.centerLeft,
          child:
              Text(widget.title, style: Theme.of(context).textTheme.headline3)),
      if (widget.description != null) ...[
        SizedBox(height: 0.02 * size.height),
        Align(
            alignment: Alignment.centerLeft,
            child: Text(widget.description!,
                style: Theme.of(context).textTheme.subtitle2))
      ],
      SizedBox(height: 0.05 * size.height),
      SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: SizedBox(
                  height: 250,
                  width: columnWidth,
                  child: AspectRatio(
                    aspectRatio: 1.70,
                    child: LineChart(data),
                  ))))
    ]);
  }

  LineChartData mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: false,
        drawVerticalLine: true,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: SideTitles(showTitles: false),
        topTitles: SideTitles(showTitles: false),
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          interval: 1,
          getTextStyles: (context, value) => Theme.of(context)
              .textTheme
              .bodyText1!
              .copyWith(color: Color(0xff68737d)),
          getTitles: (value) => value.round().toString(),
          margin: 15,
        ),
        leftTitles: SideTitles(
          showTitles: false,
          interval: 10,
          getTextStyles: (context, value) => Theme.of(context)
              .textTheme
              .bodyText1!
              .copyWith(color: Color(0xff68737d)),
          getTitles: (value) => value.round().toString(),
          reservedSize: 32,
          margin: 15,
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 29,
      minY: 0,
      maxY: 30,
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(
              30,
              (value) =>
                  FlSpot(value.toDouble(), Random().nextInt(30).toDouble())),
          isCurved: true,
          colors: gradientColors,
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            colors:
                gradientColors.map((color) => color.withOpacity(0.3)).toList(),
          ),
        ),
      ],
    );
  }

  LineChartData avgData() {
    return LineChartData(
      lineTouchData: LineTouchData(enabled: false),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          getTextStyles: (context, value) => const TextStyle(
              color: Color(0xff68737d),
              fontWeight: FontWeight.bold,
              fontSize: 16),
          getTitles: (value) {
            switch (value.toInt()) {
              case 2:
                return 'MAR';
              case 5:
                return 'JUN';
              case 8:
                return 'SEP';
            }
            return '';
          },
          margin: 8,
          interval: 1,
        ),
        leftTitles: SideTitles(
          showTitles: true,
          getTextStyles: (context, value) => const TextStyle(
            color: Color(0xff67727d),
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
          getTitles: (value) {
            switch (value.toInt()) {
              case 1:
                return '10k';
              case 3:
                return '30k';
              case 5:
                return '50k';
            }
            return '';
          },
          reservedSize: 32,
          interval: 1,
          margin: 12,
        ),
        topTitles: SideTitles(showTitles: false),
        rightTitles: SideTitles(showTitles: false),
      ),
      borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1)),
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 6,
      lineBarsData: [
        LineChartBarData(
          spots: const [
            FlSpot(0, 3.44),
            FlSpot(2.6, 3.44),
            FlSpot(4.9, 3.44),
            FlSpot(6.8, 3.44),
            FlSpot(8, 3.44),
            FlSpot(9.5, 3.44),
            FlSpot(11, 3.44),
          ],
          isCurved: true,
          colors: [
            ColorTween(begin: gradientColors[0], end: gradientColors[1])
                .lerp(0.2)!,
            ColorTween(begin: gradientColors[0], end: gradientColors[1])
                .lerp(0.2)!,
          ],
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(show: true, colors: [
            ColorTween(begin: gradientColors[0], end: gradientColors[1])
                .lerp(0.2)!
                .withOpacity(0.1),
            ColorTween(begin: gradientColors[0], end: gradientColors[1])
                .lerp(0.2)!
                .withOpacity(0.1),
          ]),
        ),
      ],
    );
  }
}
