import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/switch_input_field.dart';
import 'package:keep_up/components/time_text_field.dart';
import 'package:keep_up/screens/oops_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  _NotificationSettingsScreenState createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const _defaultSurveyNotifyTime = '20:00';
  static const _updateErrorSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Sembra ci sia un errore nel modificare il profilo'));

  final _formKey = GlobalKey<FormState>();
  final _memoizer = AsyncMemoizer();
  KeepUpUser? _user;
  final _surveyTimeEditController = TextEditingController();

  _fetchData() => _memoizer.runOnce(() async {
        _user = await KeepUp.instance.getUser();
        _surveyTimeEditController.text =
            _user?.notifySurveyTime?.toTimeOfDay().format(context) ??
                _defaultSurveyNotifyTime;
      });

  _loadingSkeleton() {
    final size = MediaQuery.of(context).size;
    return AppLayout(children: [
      SizedBox(height: 0.05 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child:
              Text('Notifiche', style: Theme.of(context).textTheme.headline2)),
      SizedBox(height: 0.02 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Decidi quando venire avvertito.',
              style: Theme.of(context).textTheme.subtitle1)),
      SizedBox(height: 0.05 * size.height),
      Form(
          key: _formKey,
          child: Column(children: [
            const SkeletonLoader(
                child: SwitchInputField(
                    label: 'Survey',
                    description: 'Registra i tuoi progressi',
                    value: false)),
            SizedBox(height: size.height * 0.02),
            const SkeletonLoader(
                child: SwitchInputField(
                    label: 'Attività',
                    description: 'Ricorda le tue attività',
                    value: false)),
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
              Text('Notifiche', style: Theme.of(context).textTheme.headline2)),
      SizedBox(height: 0.02 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Decidi quando venire avvertito.',
              style: Theme.of(context).textTheme.subtitle1)),
      SizedBox(height: 0.05 * size.height),
      Form(
          key: _formKey,
          child: Column(children: [
            SwitchInputField(
                label: 'Survey',
                description: 'Registra i tuoi progressi',
                value: _user!.notifySurveyTime != null,
                onChanged: (newValue) {
                  setState(() {
                    if (newValue!) {
                      _user!.notifySurveyTime = KeepUpDayTime.fromDateTime(
                          DateFormat.Hm(Localizations.localeOf(context)
                                  .toLanguageTag())
                              .parse(_surveyTimeEditController.text));
                    } else {
                      _user!.notifySurveyTime = null;
                    }
                  });
                }),
            SizedBox(height: size.height * 0.02),
            if (_user!.notifySurveyTime != null) ...[
              AppTimeTextField(
                  hint: 'Orario survey',
                  controller: _surveyTimeEditController,
                  width: double.maxFinite,
                  onTap: () async {
                    final _selectedTime = await showTimePicker(
                        context: context,
                        initialTime: _user!.notifySurveyTime!.toTimeOfDay(),
                        initialEntryMode: TimePickerEntryMode.input,
                        helpText: 'Orario survey',
                        errorInvalidText: 'L\'orario non è valido',
                        hourLabelText: 'Ora',
                        minuteLabelText: 'Minuto',
                        confirmText: 'Salva',
                        cancelText: 'Annulla');

                    if (_selectedTime == null) return;

                    setState(() {
                      _user!.notifySurveyTime =
                          KeepUpDayTime.fromTimeOfDay(_selectedTime);
                      _surveyTimeEditController.text = _user!.notifySurveyTime!
                          .toTimeOfDay()
                          .format(context);
                    });
                  }),
              SizedBox(height: size.height * 0.02),
            ],
            SwitchInputField(
                label: 'Attività',
                description: 'Ricorda le tue attività',
                value: _user!.notifyTasks,
                onChanged: (newValue) {
                  setState(() {
                    _user!.notifyTasks = newValue!;
                  });
                }),
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
        ),
      ]),
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
