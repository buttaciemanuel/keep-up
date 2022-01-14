import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:keep_up/screens/home_screen.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/style.dart';

class AppChartDataPoint {
  final DateTime x;
  final double y;

  AppChartDataPoint({required this.x, required this.y});
}

typedef AppChartDataSet = List<AppChartDataPoint>;

class AppChart extends StatefulWidget {
  final String title;
  final String? description;
  final Color? backgroundColor;
  final bool? isLoading;
  List<AppChartDataPoint> points;
  AppChart(
      {Key? key,
      required this.title,
      this.description,
      this.backgroundColor = AppColors.primaryColor,
      this.isLoading = false,
      required this.points})
      : super(key: key);

  @override
  _AppChartState createState() => _AppChartState();
}

class _AppChartState extends State<AppChart> {
  static const _xPointWidth = 1.5 * 35;
  late final List<Color> _gradientColors = [widget.backgroundColor!];
  final _controller = ScrollController();
  late DateTime _currentDate = widget.points.last.x;
  bool _init = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        final index = (_controller.offset ~/ _xPointWidth)
            .clamp(0, widget.points.length - 1);
        _currentDate = widget.points[index].x;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final _monthYearFormatter =
        DateFormat.yMMMM(Localizations.localeOf(context).toLanguageTag());
    final size = MediaQuery.of(context).size;
    final xAxisWidth = widget.points.length * _xPointWidth;
    const yAxisHeight = 250.0;
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (!_init) {
        _controller.jumpTo(_controller.position.maxScrollExtent);
        _init = true;
      }
    });
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
      if (widget.isLoading!) ...[
        const SkeletonLoader(
            child: Card(child: SizedBox(width: double.infinity, height: 250)))
      ] else ...[
        SizedBox(
          width: size.width,
          height: yAxisHeight,
          child: OverflowBox(
            minWidth: size.width,
            maxWidth: size.width,
            minHeight: 0.0,
            maxHeight: yAxisHeight,
            child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                controller: _controller,
                padding: const EdgeInsets.symmetric(vertical: 35),
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                    height: yAxisHeight,
                    width: xAxisWidth,
                    child: AspectRatio(
                      aspectRatio: 1.70,
                      child: LineChart(buildData()),
                    ))),
          ),
        ),
        Align(
            alignment: Alignment.center,
            child: Text(_monthYearFormatter.format(_currentDate).capitalize(),
                style: Theme.of(context).textTheme.bodyText1!.copyWith(
                    color: AppColors.fieldTextColor,
                    fontWeight: FontWeight.bold))),
      ]
    ]);
  }

  LineChartData buildData() {
    final textStyle = Theme.of(context)
        .textTheme
        .bodyText1!
        .copyWith(color: AppColors.fieldTextColor, fontWeight: FontWeight.bold);
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
          getTextStyles: (context, value) => textStyle,
          getTitles: (value) =>
              (value.toInt() == 0 || value.toInt() == widget.points.length - 1)
                  ? ''
                  : widget.points[value.round()].x.day.toString(),
          margin: 20,
        ),
        leftTitles: SideTitles(
          showTitles: false,
          interval: 10,
          getTextStyles: (context, value) => textStyle,
          getTitles: (value) => widget.points[value.round()].x.day.toString(),
          reservedSize: 32,
          margin: 20,
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: widget.points.length.toDouble() - 1,
      minY: 0,
      maxY: widget.points.reduce((value, element) {
            return element.y.compareTo(value.y) > 0 ? element : value;
          }).y +
          1,
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(widget.points.length, (index) {
            return FlSpot(index.toDouble(), widget.points[index].y);
          }),
          isCurved: true,
          colors: _gradientColors,
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            colors:
                _gradientColors.map((color) => color.withOpacity(0.5)).toList(),
          ),
        ),
      ],
    );
  }
}
