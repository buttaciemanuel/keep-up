import 'dart:developer';
import 'dart:math';

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

abstract class AppChartDisplayMode {
  static const daily = 0;
  static const weekly = 1;
  static const monthly = 2;
}

typedef AppChartDataSet = List<AppChartDataPoint>;

class AppChart extends StatefulWidget {
  final String title;
  final String? description;
  final Color? backgroundColor;
  final bool? isLoading;
  final int? displayMode;
  final List<AppChartDataPoint> points;
  bool? scrollToLast;
  AppChart(
      {Key? key,
      required this.title,
      this.description,
      this.backgroundColor = AppColors.primaryColor,
      this.isLoading = false,
      required this.points,
      this.displayMode = AppChartDisplayMode.daily,
      this.scrollToLast = true})
      : super(key: key);

  @override
  _AppChartState createState() => _AppChartState();
}

class _AppChartState extends State<AppChart> {
  static const defaultPointWidth = 1.5 * 35;
  var _xPointWidth = 0.0;
  late final _yearFormatter =
      DateFormat.y(Localizations.localeOf(context).toLanguageTag());
  late final _monthYearFormatter =
      DateFormat.yMMMM(Localizations.localeOf(context).toLanguageTag());
  late final List<Color> _gradientColors = [widget.backgroundColor!];
  static const _weekOrdinal = ['I', 'II', 'III', 'IV', 'V'];
  final _controller = ScrollController();
  late DateTime _currentDate = widget.points.last.x;

  void _scrollListener() {
    setState(() {
      final index = (_controller.offset ~/ _xPointWidth)
          .clamp(0, widget.points.length - 1);
      _currentDate = widget.points[index].x;
    });
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scrollListener);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final xAxisWidth = max(
        widget.points.length * defaultPointWidth * (1 << widget.displayMode!),
        size.width);
    const yAxisHeight = 250.0;
    _xPointWidth = xAxisWidth / widget.points.length;

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      if (widget.scrollToLast! && _controller.hasClients) {
        _controller.jumpTo(_controller.position.maxScrollExtent);
        widget.scrollToLast = false;
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
                      child: LineChart(_buildData()),
                    ))),
          ),
        ),
        Align(
            alignment: Alignment.center,
            child: Text(
                widget.displayMode == AppChartDisplayMode.monthly
                    ? _yearFormatter.format(_currentDate).capitalize()
                    : _monthYearFormatter.format(_currentDate).capitalize(),
                style: Theme.of(context).textTheme.bodyText1!.copyWith(
                    color: AppColors.fieldTextColor,
                    fontWeight: FontWeight.bold))),
      ]
    ]);
  }

  String _buildPointTitle(double x) {
    if (x.round() <= 0 || x.round() >= widget.points.length - 1) return '';
    return widget.displayMode == AppChartDisplayMode.daily
        ? widget.points[x.round()].x.day.toString()
        : widget.displayMode == AppChartDisplayMode.weekly
            ? widget.points[x.round()].x.weekOfYear
                .toString() //_weekOrdinal[widget.points[x.round()].x.day ~/ 7]
            : _monthYearFormatter
                .format(widget.points[x.round()].x)
                .substring(0, 3);
  }

  LineChartData _buildData() {
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
          getTitles: _buildPointTitle,
          margin: 20,
        ),
        leftTitles: SideTitles(showTitles: false),
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

extension MyDateTimeExtension on DateTime {
  int get weekOfYear {
    int daysToAdd = DateTime.thursday - weekday;
    DateTime thursdayDate = daysToAdd > 0
        ? add(Duration(days: daysToAdd))
        : subtract(Duration(days: daysToAdd.abs()));
    int dayOfYearThursday = thursdayDate.dayOfYear;
    return 1 + ((dayOfYearThursday - 1) / 7).floor();
  }

  int get dayOfYear {
    return difference(DateTime(year, 1, 1)).inDays;
  }
}
