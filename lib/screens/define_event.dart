import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';
import 'package:keep_up/constant.dart';

class AppTimeTextField extends StatelessWidget {
  final String? initialText;
  final String? hint;
  final double? width;
  final Function()? onTap;
  final TextEditingController? controller;
  const AppTimeTextField(
      {Key? key,
      this.hint,
      this.onTap,
      this.controller,
      this.initialText,
      this.width})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SizedBox(
        width: width ?? size.width,
        child: TextFormField(
            initialValue: initialText,
            controller: controller,
            onTap: onTap,
            textAlign: TextAlign.start,
            readOnly: true,
            style: Theme.of(context).textTheme.bodyText1,
            decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
                filled: true,
                fillColor: AppColors.fieldBackgroundColor,
                hintText: hint,
                labelText: hint,
                floatingLabelStyle:
                    const TextStyle(color: AppColors.primaryColor),
                border: UnderlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon:
                    Icon(Icons.timer, color: Theme.of(context).hintColor))));
  }
}

class DefineEventScreen extends StatefulWidget {
  final KeepUpTask? fromTask;
  DefineEventScreen({Key? key, this.fromTask}) : super(key: key);

  @override
  _DefineEventScreenState createState() => _DefineEventScreenState();
}

class _DefineEventScreenState extends State<DefineEventScreen> {
  static const _timeMismatchSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('L\'orario inserito non ha molto senso'));
  static const _eventCreationSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Sembra ci sia un errore nel creare l\'attività'));

  late KeepUpEvent _event;
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _timePickerController = TextEditingController();
  final _startTimePickerController = TextEditingController();
  final _endTimePickerController = TextEditingController();
  int _selectedDay = 0;

  String? _eventNameValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Inserisci il nome dell\'attività';
    }
    return null;
  }

  @override
  void initState() {
    _event = KeepUpEvent(title: '', startDate: DateTime.now());
    super.initState();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _timePickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fromTask != null) return editExistingEvent(context);
    return createNewEventScreen(context);
  }

  Widget createNewEventScreen(BuildContext context) {
    return Text('NOT YET IMPLEMENTED');
  }

  KeepUpRecurrence? _scheduleInWeekDay(int weekDay) {
    for (final recurrence in _event.recurrences) {
      if (recurrence.weekDay == weekDay) {
        return recurrence;
      }
    }

    return null;
  }

  Widget editExistingEvent(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final dayRecurrence = _scheduleInWeekDay(_selectedDay);
    if (dayRecurrence != null) {
      _timePickerController.text =
          '${dayRecurrence.startTime.toTimeOfDay().format(context)} - ${dayRecurrence.endTime!.toTimeOfDay().format(context)}';
    } else {
      _timePickerController.clear();
    }

    return FutureBuilder<KeepUpResponse>(
        future: KeepUp.instance.getEvent(eventId: widget.fromTask!.eventId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return AppLayout(
              children: [
                SizedBox(height: 0.05 * size.height),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Crea l\'attività',
                        style: Theme.of(context).textTheme.headline2)),
                SizedBox(height: 0.04 * size.height),
                Form(
                    key: _formKey,
                    child: Column(children: [
                      AppTextField(
                          validator: _eventNameValidator,
                          hint: 'Il nome dell\'attività',
                          label: 'Attività',
                          inputType: TextInputType.name,
                          controller: _eventNameController),
                      SizedBox(height: 0.02 * size.height),
                      AppTextField(
                          controller: _eventDescriptionController,
                          isTextArea: true,
                          label: 'Descrizione',
                          hint: 'La descrizione dell\'attività'),
                      SizedBox(height: 0.04 * size.height),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              'Pianifica l\'attività durante la settimana.',
                              style: Theme.of(context).textTheme.subtitle1)),
                      SizedBox(height: 0.03 * size.height),
                      SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                              children: List.generate(weekDays.length, (index) {
                            return TextButton(
                                style: TextButton.styleFrom(
                                    side: _selectedDay == index
                                        ? const BorderSide(
                                            width: 3.0,
                                            color: AppColors.lightGrey)
                                        : BorderSide.none,
                                    shape: const CircleBorder(),
                                    backgroundColor:
                                        _scheduleInWeekDay(index) != null
                                            ? AppColors.primaryColor
                                            : Colors.black.withOpacity(0.15)),
                                onPressed: () =>
                                    setState(() => _selectedDay = index),
                                child: Text(weekDays[index][0].toUpperCase(),
                                    style:
                                        const TextStyle(color: Colors.white)));
                          }))),
                      SizedBox(height: 0.03 * size.height),
                      /*AppTimeTextField(
                          controller: _timePickerController,
                          hint: 'Scegli l\'orario',
                          onTap: () async {
                            final _startTime = await showTimePicker(
                                context: context,
                                initialTime: dayRecurrence != null
                                    ? dayRecurrence.startTime.toTimeOfDay()
                                    : TimeOfDay.now(),
                                initialEntryMode: TimePickerEntryMode.input,
                                helpText: 'Orario di inizio',
                                errorInvalidText: 'L\'orario non è valido',
                                hourLabelText: 'Ora',
                                minuteLabelText: 'Minuto',
                                confirmText: 'Continua',
                                cancelText: 'Annulla');

                            if (_startTime == null) return;

                            final _endTime = await showTimePicker(
                                context: context,
                                initialTime: dayRecurrence != null
                                    ? (dayRecurrence.endTime != null
                                        ? dayRecurrence.endTime!.toTimeOfDay()
                                        : dayRecurrence.startTime.toTimeOfDay())
                                    : TimeOfDay.now(),
                                initialEntryMode: TimePickerEntryMode.input,
                                helpText: 'Orario di fine',
                                errorInvalidText: 'L\'orario non è valido',
                                hourLabelText: 'Ora',
                                minuteLabelText: 'Minuto',
                                confirmText: 'Salva',
                                cancelText: 'Annulla');

                            if (_endTime == null) return;

                            final startTime =
                                KeepUpDayTime.fromTimeOfDay(_startTime);
                            final endTime =
                                KeepUpDayTime.fromTimeOfDay(_endTime);

                            if (startTime.compareTo(endTime) >= 0) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(_timeMismatchSnackbar);
                              return;
                            }

                            _timePickerController.text =
                                '${_startTime.format(context)} - ${_endTime.format(context)}';

                            setState(() {
                              _event.addWeeklySchedule(
                                  weekDay: _selectedDay,
                                  startTime: startTime,
                                  endTime: endTime);
                            });
                          })
                    */
                    ])),
                Row(children: [
                  AppTimeTextField(
                      hint: 'Inizio',
                      controller: _startTimePickerController,
                      width: 170,
                      onTap: () async {
                        final _startTime = await showTimePicker(
                            context: context,
                            initialTime: dayRecurrence != null
                                ? dayRecurrence.startTime.toTimeOfDay()
                                : TimeOfDay.now(),
                            initialEntryMode: TimePickerEntryMode.input,
                            helpText: 'Inizio',
                            errorInvalidText: 'L\'orario non è valido',
                            hourLabelText: 'Ora',
                            minuteLabelText: 'Minuto',
                            confirmText: 'Continua',
                            cancelText: 'Annulla');

                        if (_startTime == null) return;

                        _startTimePickerController.text =
                            _startTime.format(context);

                        final _endTime = await showTimePicker(
                            context: context,
                            initialTime: dayRecurrence != null
                                ? (dayRecurrence.endTime != null
                                    ? dayRecurrence.endTime!.toTimeOfDay()
                                    : dayRecurrence.startTime.toTimeOfDay())
                                : TimeOfDay.now(),
                            initialEntryMode: TimePickerEntryMode.input,
                            helpText: 'Fine',
                            errorInvalidText: 'L\'orario non è valido',
                            hourLabelText: 'Ora',
                            minuteLabelText: 'Minuto',
                            confirmText: 'Salva',
                            cancelText: 'Annulla');

                        if (_endTime == null) return;

                        _endTimePickerController.text =
                            _endTime.format(context);

                        final startTime =
                            KeepUpDayTime.fromTimeOfDay(_startTime);
                        final endTime = KeepUpDayTime.fromTimeOfDay(_endTime);

                        if (startTime.compareTo(endTime) >= 0) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(_timeMismatchSnackbar);
                          return;
                        }

                        setState(() {
                          _event.addWeeklySchedule(
                              weekDay: _selectedDay,
                              startTime: startTime,
                              endTime: endTime);
                        });
                      }),
                  const Expanded(child: SizedBox()),
                  AppTimeTextField(
                      hint: 'Fine',
                      controller: _endTimePickerController,
                      width: 170,
                      onTap: () async {
                        final _endTime = await showTimePicker(
                            context: context,
                            initialTime: dayRecurrence != null
                                ? (dayRecurrence.endTime != null
                                    ? dayRecurrence.endTime!.toTimeOfDay()
                                    : dayRecurrence.startTime.toTimeOfDay())
                                : TimeOfDay.now(),
                            initialEntryMode: TimePickerEntryMode.input,
                            helpText: 'Fine',
                            errorInvalidText: 'L\'orario non è valido',
                            hourLabelText: 'Ora',
                            minuteLabelText: 'Minuto',
                            confirmText: 'Salva',
                            cancelText: 'Annulla');

                        if (_endTime == null) return;

                        _endTimePickerController.text =
                            _endTime.format(context);

                        if (_startTimePickerController.text.isEmpty) return;

                        final startTime = KeepUpDayTime.fromDateTime(
                            DateFormat("h:mm")
                                .parse(_startTimePickerController.text));
                        final endTime = KeepUpDayTime.fromTimeOfDay(_endTime);

                        if (startTime.compareTo(endTime) >= 0) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(_timeMismatchSnackbar);
                          return;
                        }

                        setState(() {
                          _event.addWeeklySchedule(
                              weekDay: _selectedDay,
                              startTime: startTime,
                              endTime: endTime);
                        });
                      })
                ]),
                const Expanded(child: SizedBox()),
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
                          _event.title = _eventNameController.text;
                          _event.description = _eventDescriptionController.text;
                          final response =
                              await KeepUp.instance.createEvent(_event);
                          if (response.error) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(_eventCreationSnackbar);
                          } else {
                            Navigator.of(context).pop();
                          }
                        }
                      },
                      child: const Text('Salva'),
                      style:
                          TextButton.styleFrom(primary: AppColors.primaryColor),
                    ),
                  ),
                ]),
                SizedBox(height: 0.05 * size.height)
              ],
            );
          } else {
            return Text('NOT YET IMPLEMENTED');
          }
        });
  }
}
