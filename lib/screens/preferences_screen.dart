import 'dart:developer';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_up/components/category_selector.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/switch_input_field.dart';
import 'package:keep_up/components/time_text_field.dart';
import 'package:keep_up/screens/oops_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class PreferencesSettingsScreen extends StatefulWidget {
  final Function()? onScheduleScreen;
  const PreferencesSettingsScreen({Key? key, this.onScheduleScreen})
      : super(key: key);

  @override
  _PreferencesSettingsScreenState createState() =>
      _PreferencesSettingsScreenState();
}

class _PreferencesSettingsScreenState extends State<PreferencesSettingsScreen> {
  static const _timeMismatchSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('L\'orario inserito non ha molto senso'));
  static const _dayParts = ['Mattina', 'Pomeriggio', 'Sera'];
  static const _updateErrorSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Sembra ci sia un errore nel modificare le preferenze'));

  final _formKey = GlobalKey<FormState>();
  final _memoizer = AsyncMemoizer();
  KeepUpUser? _user;
  final _sleepStartTimeEditController = TextEditingController();
  final _sleepEndTimeEditController = TextEditingController();

  _fetchData() => _memoizer.runOnce(() async {
        _user = await KeepUp.instance.getUser();
        _sleepStartTimeEditController.text = _user!.sleepStartTime!.toString();
        _sleepEndTimeEditController.text = _user!.sleepEndTime!.toString();
      });

  _loadingSkeleton() {
    final size = MediaQuery.of(context).size;
    return AppLayout(children: [
      SizedBox(height: 0.05 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child:
              Text('Preferenze', style: Theme.of(context).textTheme.headline2)),
      SizedBox(height: 0.02 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Crea le tue abitudini da zero.',
              style: Theme.of(context).textTheme.subtitle1)),
      SizedBox(height: 0.05 * size.height),
      Form(
          key: _formKey,
          child: Column(children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text('Quando preferisci riposare?',
                    style: Theme.of(context).textTheme.subtitle2)),
            SizedBox(height: 0.02 * size.height),
            Row(children: [
              SkeletonLoader(
                  child: AppTimeTextField(
                      hint: 'Inizio', width: size.width / 2.5, onTap: null)),
              const Expanded(child: SizedBox()),
              SkeletonLoader(
                  child: AppTimeTextField(
                      hint: 'Fine', width: size.width / 2.5, onTap: null)),
            ]),
            SizedBox(height: 0.03 * size.height),
            Align(
                alignment: Alignment.centerLeft,
                child: Text('Quando preferisci studiare?',
                    style: Theme.of(context).textTheme.subtitle2)),
            SizedBox(height: 0.02 * size.height),
            SkeletonLoader(
                child: AppCategorySelector(
                    categories: _dayParts, onClicked: (_) {})),
            SizedBox(height: 0.03 * size.height),
            Align(
                alignment: Alignment.centerLeft,
                child: Text('Quando preferisci fare sport?',
                    style: Theme.of(context).textTheme.subtitle2)),
            SizedBox(height: 0.02 * size.height),
            SkeletonLoader(
                child: AppCategorySelector(
                    categories: _dayParts, onClicked: (_) {})),
          ])),
      Expanded(child: SizedBox(height: size.height * 0.03)),
      Row(children: [
        Expanded(
            child: Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
            style: TextButton.styleFrom(primary: AppColors.grey),
          ),
        )),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () async {},
            child: const Text('Salva'),
            style: TextButton.styleFrom(primary: AppColors.primaryColor),
          ),
        ),
      ]),
      SizedBox(height: 0.05 * size.height),
    ]);
  }

  _form() {
    final size = MediaQuery.of(context).size;
    return AppLayout(children: [
      SizedBox(height: 0.05 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child:
              Text('Preferenze', style: Theme.of(context).textTheme.headline2)),
      SizedBox(height: 0.02 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Crea le tue abitudini da zero.',
              style: Theme.of(context).textTheme.subtitle1)),
      SizedBox(height: 0.05 * size.height),
      Form(
          key: _formKey,
          child: Column(children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text('Quando preferisci riposare?',
                    style: Theme.of(context).textTheme.subtitle2)),
            SizedBox(height: 0.02 * size.height),
            Row(children: [
              AppTimeTextField(
                  hint: 'Inizio',
                  controller: _sleepStartTimeEditController,
                  width: size.width / 2.5,
                  onTap: () async {
                    final _startTime = await showTimePicker(
                        context: context,
                        initialTime: _user!.sleepStartTime!.toTimeOfDay(),
                        initialEntryMode: TimePickerEntryMode.input,
                        helpText: 'Inizio',
                        errorInvalidText: 'L\'orario non è valido',
                        hourLabelText: 'Ora',
                        minuteLabelText: 'Minuto',
                        confirmText: 'Continua',
                        cancelText: 'Annulla');

                    if (_startTime == null) return;

                    _sleepStartTimeEditController.text =
                        _startTime.format(context);

                    final _endTime = await showTimePicker(
                        context: context,
                        initialTime: _user!.sleepEndTime!.toTimeOfDay(),
                        initialEntryMode: TimePickerEntryMode.input,
                        helpText: 'Fine',
                        errorInvalidText: 'L\'orario non è valido',
                        hourLabelText: 'Ora',
                        minuteLabelText: 'Minuto',
                        confirmText: 'Salva',
                        cancelText: 'Annulla');

                    if (_endTime == null) return;

                    _sleepEndTimeEditController.text = _endTime.format(context);

                    setState(() {
                      _user!.sleepStartTime =
                          KeepUpDayTime.fromTimeOfDay(_startTime);
                      _user!.sleepEndTime =
                          KeepUpDayTime.fromTimeOfDay(_endTime);
                    });
                  }),
              const Expanded(child: SizedBox()),
              AppTimeTextField(
                  hint: 'Fine',
                  controller: _sleepEndTimeEditController,
                  width: size.width / 2.5,
                  onTap: () async {
                    final _endTime = await showTimePicker(
                        context: context,
                        initialTime: _user!.sleepEndTime!.toTimeOfDay(),
                        initialEntryMode: TimePickerEntryMode.input,
                        helpText: 'Fine',
                        errorInvalidText: 'L\'orario non è valido',
                        hourLabelText: 'Ora',
                        minuteLabelText: 'Minuto',
                        confirmText: 'Salva',
                        cancelText: 'Annulla');

                    if (_endTime == null) return;

                    _sleepEndTimeEditController.text = _endTime.format(context);

                    if (_sleepEndTimeEditController.text.isEmpty) {
                      return;
                    }

                    setState(() {
                      _user!.sleepStartTime = KeepUpDayTime.fromDateTime(
                          DateFormat("h:mm")
                              .parse(_sleepStartTimeEditController.text));
                      _user!.sleepEndTime =
                          KeepUpDayTime.fromTimeOfDay(_endTime);
                    });
                  })
            ]),
            SizedBox(height: 0.03 * size.height),
            Align(
                alignment: Alignment.centerLeft,
                child: Text('Quando preferisci studiare?',
                    style: Theme.of(context).textTheme.subtitle2)),
            SizedBox(height: 0.02 * size.height),
            AppCategorySelector(
                value: _dayParts[_user!.studyDayPart!],
                categories: _dayParts,
                onClicked: (mode) => setState(() {
                      _user!.studyDayPart = _dayParts.indexOf(mode);
                    })),
            SizedBox(height: 0.03 * size.height),
            Align(
                alignment: Alignment.centerLeft,
                child: Text('Quando preferisci fare sport?',
                    style: Theme.of(context).textTheme.subtitle2)),
            SizedBox(height: 0.02 * size.height),
            AppCategorySelector(
                value: _dayParts[_user!.sportDayPart!],
                categories: _dayParts,
                onClicked: (mode) => setState(() {
                      _user!.sportDayPart = _dayParts.indexOf(mode);
                    })),
          ])),
      Expanded(child: SizedBox(height: size.height * 0.03)),
      if (widget.onScheduleScreen != null) ...[
        Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final response = await KeepUp.instance.updateUser(_user!);
                  if (response.error) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(_updateErrorSnackbar);
                  } else {
                    widget.onScheduleScreen!();
                  }
                }
              },
              child: const Text('Pianifica'),
              style: TextButton.styleFrom(primary: AppColors.primaryColor),
            ))
      ] else ...[
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annulla'),
            style: TextButton.styleFrom(primary: AppColors.grey),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final response = await KeepUp.instance.updateUser(_user!);
                if (response.error) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(_updateErrorSnackbar);
                } else {
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Salva'),
            style: TextButton.styleFrom(primary: AppColors.primaryColor),
          ),
        ])
      ],
      SizedBox(height: 0.05 * size.height),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
        future: _fetchData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loadingSkeleton();
          } else if (snapshot.hasError) {
            OopsScreen.show(context);
            return _loadingSkeleton();
          } else {
            return _form();
          }
        });
  }
}
