import 'dart:developer';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:keep_up/components/category_selector.dart';
import 'package:keep_up/components/chart.dart';
import 'package:keep_up/components/navigator.dart';
import 'package:keep_up/constant.dart';
import 'package:keep_up/screens/daily_survey_screen.dart';
import 'package:keep_up/screens/oops_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class PersonalGrowthScreen extends StatefulWidget {
  const PersonalGrowthScreen({Key? key}) : super(key: key);

  @override
  State<PersonalGrowthScreen> createState() => _PersonalGrowthScreenState();
}

class _PersonalGrowthScreenState extends State<PersonalGrowthScreen> {
  static const _diplayModeLabels = ['Giorni', 'Settimane', 'Mesi'];
  final _disabledLabels = <String>{};
  final _currentDate = DateTime.now().getDateOnly();
  late final _fromDate = _currentDate.subtract(const Duration(days: 90));
  int _chartDisplayMode = AppChartDisplayMode.daily;
  List<List<AppChartDataSet>>? _dataSets;
  final _memoizer = AsyncMemoizer();
  static const _minDataSetSize = 4;

  static List<List<AppChartDataSet>> _buildDataSets(
      List<KeepUpDailyTrace> traces, DateTime startDate, DateTime endDate) {
    final dailySets = <AppChartDataSet>[[], []];
    final weeklySets = <AppChartDataSet>[[], []];
    final monthlySets = <AppChartDataSet>[[], []];

    if (traces.isEmpty) return [dailySets, weeklySets, monthlySets];

    assert(startDate.compareTo(endDate) <= 0);

    startDate = traces.first.date;
    endDate = traces.last.date;

    // fa un merge per costruire il datasets su tutti i giorni
    DateTime current = startDate.getDateOnly();
    int j = 0;

    while (current.compareTo(endDate.getDateOnly()) <= 0) {
      if (current.compareTo(traces[j].date) == 0) {
        dailySets[0].add(AppChartDataPoint(
            x: current, y: traces[j].completedTasks.length.toDouble()));
        dailySets[1].add(
            AppChartDataPoint(x: current, y: traces[j].mood?.toDouble() ?? 0));
        ++j;
        current = current.add(const Duration(days: 1));
      } else if (current.compareTo(traces[j].date) < 0) {
        dailySets[0].add(AppChartDataPoint(x: current, y: 0));
        dailySets[1].add(AppChartDataPoint(x: current, y: 0));
        current = current.add(const Duration(days: 1));
      }
    }

    // ora costruisce il dataset su ogni settimana
    current = startDate
        .getDateOnly()
        .subtract(Duration(days: startDate.getDateOnly().weekday - 1));
    j = 0;

    while (j < dailySets.first.length) {
      var mean = [0.0, 0.0];
      var count = 0;
      final nextWeek = current.add(const Duration(days: 7));
      while (j < dailySets.first.length &&
          dailySets.first[j].x.compareTo(nextWeek) < 0) {
        mean[0] += dailySets.first[j].y;
        mean[1] += dailySets.last[j].y;
        ++j;
        ++count;
      }
      // aggiunge la media settimanale
      weeklySets[0].add(AppChartDataPoint(x: current, y: mean[0] / count));
      weeklySets[1].add(AppChartDataPoint(x: current, y: mean[1] / count));
      // prosegue alla settimana successiva
      current = nextWeek;
    }

    // infine il dataset su ogni mese
    current = startDate
        .getDateOnly()
        .subtract(Duration(days: startDate.getDateOnly().day - 1));
    j = 0;

    while (j < dailySets.first.length) {
      var mean = [0.0, 0.0];
      var count = 0;
      var nextMonth = current.add(const Duration(days: 31));
      nextMonth = nextMonth.subtract(Duration(days: nextMonth.day - 1));
      while (j < dailySets.first.length &&
          dailySets.first[j].x.compareTo(nextMonth) < 0) {
        mean[0] += dailySets.first[j].y;
        mean[1] += dailySets.last[j].y;
        ++j;
        ++count;
      }
      // aggiunge la media settimanale
      monthlySets[0].add(AppChartDataPoint(x: current, y: mean[0] / count));
      monthlySets[1].add(AppChartDataPoint(x: current, y: mean[1] / count));
      // prosegue alla settimana successiva
      current = nextMonth;
    }

    for (final w in weeklySets[0]) {
      print('[week] ${w.x.toString()}');
    }

    return [dailySets, weeklySets, monthlySets];
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _fetchData() => _memoizer.runOnce(() async {
        final response = await KeepUp.instance
            .getDailyTraces(until: _currentDate, from: _fromDate);
        if (response.error) {
          return Future.error('');
        } else {
          _dataSets = _buildDataSets(response.result!, _fromDate, _currentDate);
          // disabilita i label per cui non ci sono sufficienti dati
          const minDataSetSize = 3;
          if (_dataSets![0][0].length < minDataSetSize) {
            _disabledLabels.add(_diplayModeLabels[0]);
          }
          if (_dataSets![1][0].length < minDataSetSize) {
            _disabledLabels.add(_diplayModeLabels[1]);
          }
          if (_dataSets![2][0].length < minDataSetSize) {
            _disabledLabels.add(_diplayModeLabels[2]);
          }
        }
      });

  Widget _loading() {
    final size = MediaQuery.of(context).size;
    return Column(children: [
      AppChart(
          title: 'Performance',
          backgroundColor: AppEventColors.lightBlue,
          isLoading: true,
          points: const []),
      SizedBox(height: 0.05 * size.height),
      AppChart(
          title: 'Umore',
          backgroundColor: AppEventColors.purple,
          isLoading: true,
          points: const [])
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AppNavigationPageLayout(children: [
      SizedBox(height: 0.05 * size.height),
      Row(children: [
        Expanded(
          child: Align(
              alignment: Alignment.centerLeft,
              child: Text('La tua crescita',
                  style: Theme.of(context).textTheme.headline1)),
        ),
        IconButton(
            iconSize: 32.0,
            padding: EdgeInsets.zero,
            tooltip: 'Calendario',
            constraints: const BoxConstraints(),
            onPressed: () => _loadCalendarOfProgress(),
            icon: const Icon(Icons.date_range, color: AppColors.primaryColor))
      ]),
      SizedBox(height: 0.02 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Dai uno sguardo ai tuoi progressi.',
              style: Theme.of(context).textTheme.subtitle1)),
      SizedBox(height: 0.03 * size.height),
      FutureBuilder<void>(
          future: _fetchData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _loading();
            } else if (snapshot.hasError) {
              OopsScreen.show(context).then((value) {
                Future.delayed(
                    const Duration(seconds: 5), () => setState(() {}));
              });
              return _loading();
            } else if (_dataSets!.first.first.length < _minDataSetSize) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 0.05 * size.height),
                    Image.asset('assets/images/no_plot.png',
                        height: 0.25 * size.height, width: 0.7 * size.width),
                    SizedBox(height: 0.05 * size.height),
                    Text('Registra i tuoi progressi!',
                        style: Theme.of(context).textTheme.headline3),
                    SizedBox(height: 0.02 * size.height),
                    Text('Completa qualche task e torna a vedere.',
                        style: Theme.of(context).textTheme.subtitle2)
                  ]);
            } else {
              return Column(children: [
                AppCategorySelector(
                    value: _diplayModeLabels[_chartDisplayMode],
                    categories: _diplayModeLabels,
                    disabledCategories: _disabledLabels,
                    onClicked: (mode) => setState(() {
                          if (!_disabledLabels.contains(mode)) {
                            _chartDisplayMode = _diplayModeLabels.indexOf(mode);
                          }
                        })),
                SizedBox(height: 0.03 * size.height),
                AppChart(
                    displayMode: _chartDisplayMode,
                    title: 'Performance',
                    backgroundColor: AppEventColors.lightBlue,
                    points: _dataSets![_chartDisplayMode][0],
                    scrollToLast: true),
                SizedBox(height: 0.05 * size.height),
                AppChart(
                    displayMode: _chartDisplayMode,
                    title: 'Umore',
                    backgroundColor: AppEventColors.purple,
                    points: _dataSets![_chartDisplayMode][1],
                    scrollToLast: true)
              ]);
            }
          })
    ]);
  }

  _loadCalendarOfProgress() async {
    var today = DateTime.now();
    final date = await showDatePicker(
        context: context,
        initialDatePickerMode: DatePickerMode.day,
        fieldLabelText: 'Progresso',
        cancelText: 'Annulla',
        confirmText: 'Scegli',
        fieldHintText: 'Data del progresso',
        errorInvalidText: 'La data non è valida',
        errorFormatText: 'La data non è valida',
        helpText: 'Progresso',
        initialDate: today.subtract(const Duration(days: 1)),
        firstDate: today.subtract(const Duration(days: 90)),
        lastDate: today.subtract(const Duration(days: 1)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              dialogTheme: const DialogTheme(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)))),
              colorScheme: const ColorScheme.light(
                primary: AppColors.primaryColor,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        });

    if (date != null) {
      Navigator.of(context)
          .push(MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => DailySurveyScreen(
                  inDate: date,
                  fromNavigatorPage: AppNavigator.personalGrowthPage)))
          .then((_) => setState(() {}));
    }
  }
}
