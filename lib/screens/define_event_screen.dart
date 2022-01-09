import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/components/color_selector.dart';
import 'package:keep_up/screens/define_goal_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';
import 'package:keep_up/constant.dart';

class DefineEventScreen extends StatefulWidget {
  final KeepUpTask? fromTask;
  final int fromDayIndex;
  final DateTime? fromDate;
  final bool showOnlyForDay;
  const DefineEventScreen(
      {Key? key,
      this.fromTask,
      required this.fromDayIndex,
      this.fromDate,
      this.showOnlyForDay = false})
      : super(key: key);

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
  final _startTimePickerController = TextEditingController();
  final _endTimePickerController = TextEditingController();
  int _selectedDayIndex = 0;
  int _selectedColor = 0;
  String? _category;
  bool _justToday = false;

  String? _eventNameValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Inserisci il nome dell\'attività';
    }
    return null;
  }

  @override
  void initState() {
    _event = KeepUpEvent(
        title: '', startDate: DateTime.now(), color: AppColors.primaryColor);

    _selectedDayIndex = widget.fromDayIndex;

    if (widget.fromTask != null) {
      _justToday = widget.fromTask!.recurrenceType == KeepUpRecurrenceType.none;
      _selectedColor = AppEventColors.values.indexOf(widget.fromTask!.color);
    }

    super.initState();
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    _startTimePickerController.dispose();
    _endTimePickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fromTask != null) return _editExistingEvent(context);
    return _createNewEventScreen(context);
  }

  // scarica l'evento dal database solo al primo caricamento di schermata,
  // ovvero lazy loading, e dopo lo riutilizza per un merge
  Future<bool> _getExistingEvent(String eventId) async {
    if (_event.id != null) return true;

    final response = await KeepUp.instance.getEvent(eventId: eventId);

    if (response.error) return false;

    _event = response.result as KeepUpEvent;

    return true;
  }

  KeepUpRecurrence? _scheduleInWeekDay(int index) {
    for (final recurrence in _event.recurrences) {
      if (recurrence.type == KeepUpRecurrenceType.daily ||
          (recurrence.type == KeepUpRecurrenceType.weekly &&
              recurrence.weekDay == index + 1)) {
        return recurrence;
      }
    }

    return null;
  }

  KeepUpRecurrence? _scheduleInDay(DateTime date) {
    for (final recurrence in _event.recurrences) {
      if (recurrence.type == KeepUpRecurrenceType.none &&
          recurrence.day == date.day &&
          recurrence.month == date.month &&
          recurrence.year == date.year) {
        return recurrence;
      }
    }

    return null;
  }

  Widget _createNewEventScreen(BuildContext context) {
    return _form(context, screenTitle: 'Crea l\'attività');
  }

  Widget _editExistingEvent(BuildContext context) {
    const screenTitle = 'Modifica l\'attività';
    return FutureBuilder<bool>(
        future: _getExistingEvent(widget.fromTask!.eventId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _eventNameController.text = _event.title;
            _category = _event.category;

            if (_event.description != null) {
              _eventDescriptionController.text = _event.description!;
            }

            return _form(context, screenTitle: screenTitle);
          } else {
            return _loadingSkeleton(context, screenTitle: screenTitle);
          }
        });
  }

  Widget _loadingSkeleton(BuildContext context, {required String screenTitle}) {
    final size = MediaQuery.of(context).size;
    return AppLayout(
      children: [
        SizedBox(height: 0.05 * size.height),
        Align(
            alignment: Alignment.centerLeft,
            child: Text(screenTitle,
                style: Theme.of(context).textTheme.headline2)),
        SizedBox(height: 0.02 * size.height),
        Align(
            alignment: Alignment.centerLeft,
            child: Text('Pianifica l\'attività durante la settimana.',
                style: Theme.of(context).textTheme.subtitle1)),
        SizedBox(height: 0.03 * size.height),
        Form(
            key: _formKey,
            child: Column(children: [
              if (widget.showOnlyForDay) ...[
                const SkeletonLoader(
                    child:
                        SwitchInputField(label: 'Solo per oggi', value: false)),
                SizedBox(height: 0.03 * size.height),
              ],
              if (!_justToday) ...[
                SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                        children: List.generate(weekDays.length, (index) {
                      return SizedBox(
                          width: size.width / 8.5,
                          child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                  side: BorderSide.none,
                                  shape: const CircleBorder(),
                                  backgroundColor:
                                      Colors.black.withOpacity(0.15)),
                              child: const Text('')));
                    }))),
                SizedBox(height: 0.03 * size.height),
              ],
              Row(children: [
                SkeletonLoader(
                    child: AppTimeTextField(
                        hint: 'Inizio', width: size.width / 2.5)),
                const Expanded(child: SizedBox()),
                SkeletonLoader(
                    child:
                        AppTimeTextField(hint: 'Fine', width: size.width / 2.5))
              ]),
              SizedBox(height: 0.03 * size.height),
              AppCategorySelector(
                  categories: KeepUpEventCategory.values, onClicked: (_) {}),
              SizedBox(height: 0.02 * size.height),
              const SkeletonLoader(
                  child: AppTextField(
                      hint: 'Il nome dell\'attività',
                      label: 'Attività',
                      inputType: TextInputType.name)),
              SizedBox(height: 0.02 * size.height),
              const SkeletonLoader(
                  child: AppTextField(
                      isTextArea: true,
                      label: 'Descrizione',
                      hint: 'La descrizione dell\'attività')),
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
              onPressed: () {},
              child: const Text('Salva'),
              style: TextButton.styleFrom(primary: AppColors.primaryColor),
            ),
          ),
        ]),
        SizedBox(height: 0.05 * size.height)
      ],
    );
  }

  Widget _form(BuildContext context, {required String screenTitle}) {
    final size = MediaQuery.of(context).size;
    final dayRecurrence = _justToday
        ? _scheduleInDay(widget.fromDate!)
        : _scheduleInWeekDay(_selectedDayIndex);

    if (dayRecurrence != null) {
      _startTimePickerController.text =
          dayRecurrence.startTime.toTimeOfDay().format(context);
      if (dayRecurrence.endTime == null) {
        _endTimePickerController.clear();
      } else {
        _endTimePickerController.text =
            dayRecurrence.endTime!.toTimeOfDay().format(context);
      }
    } else {
      _startTimePickerController.clear();
      _endTimePickerController.clear();
    }

    return AppLayout(
      children: [
        SizedBox(height: 0.05 * size.height),
        Align(
            alignment: Alignment.centerLeft,
            child: Text(screenTitle,
                style: Theme.of(context).textTheme.headline2)),
        SizedBox(height: 0.02 * size.height),
        Align(
            alignment: Alignment.centerLeft,
            child: Text('Pianifica l\'attività durante la settimana.',
                style: Theme.of(context).textTheme.subtitle1)),
        SizedBox(height: 0.03 * size.height),
        Form(
            key: _formKey,
            child: Column(children: [
              if (widget.showOnlyForDay) ...[
                SwitchInputField(
                    label: 'Solo per oggi',
                    value: _justToday,
                    onChanged: (value) => setState(() {
                          _justToday = value!;
                          if (value) {
                            _startTimePickerController.clear();
                            _endTimePickerController.clear();
                          }
                        })),
                SizedBox(height: 0.03 * size.height),
              ],
              if (!_justToday) ...[
                AppWeekDaySelector(
                    selectedDay: _selectedDayIndex,
                    isScheduled: (index) {
                      return _scheduleInWeekDay(index) != null;
                    },
                    onSelected: (index) {
                      setState(() => _selectedDayIndex = index);
                    }),
                SizedBox(height: 0.03 * size.height)
              ],
              Row(children: [
                AppTimeTextField(
                    hint: 'Inizio',
                    controller: _startTimePickerController,
                    width: size.width / 2.5,
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

                      _endTimePickerController.text = _endTime.format(context);

                      final startTime = KeepUpDayTime.fromTimeOfDay(_startTime);
                      final endTime = KeepUpDayTime.fromTimeOfDay(_endTime);

                      if (startTime.compareTo(endTime) >= 0) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(_timeMismatchSnackbar);
                        return;
                      }

                      setState(() {
                        if (_justToday) {
                          _event.addSchedule(
                              day: widget.fromDate!.day,
                              month: widget.fromDate!.month,
                              year: widget.fromDate!.year,
                              startTime: startTime,
                              endTime: endTime);
                        } else {
                          _event.addWeeklySchedule(
                              weekDay: _selectedDayIndex + 1,
                              startTime: startTime,
                              endTime: endTime);
                        }
                      });
                    }),
                const Expanded(child: SizedBox()),
                AppTimeTextField(
                    hint: 'Fine',
                    controller: _endTimePickerController,
                    width: size.width / 2.5,
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

                      _endTimePickerController.text = _endTime.format(context);

                      if (_startTimePickerController.text.isEmpty) {
                        return;
                      }

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
                        if (_justToday) {
                          _event.addSchedule(
                              day: widget.fromDate!.day,
                              month: widget.fromDate!.month,
                              year: widget.fromDate!.year,
                              startTime: startTime,
                              endTime: endTime);
                        } else {
                          _event.addWeeklySchedule(
                              weekDay: _selectedDayIndex + 1,
                              startTime: startTime,
                              endTime: endTime);
                        }
                      });
                    })
              ]),
              SizedBox(height: 0.03 * size.height),
              AppCategorySelector(
                  value: _category,
                  categories: KeepUpEventCategory.values,
                  onClicked: (category) {
                    setState(() {
                      if (_category != category) {
                        _category = category;
                      } else {
                        _category = null;
                      }
                    });
                  }),
              SizedBox(height: 0.02 * size.height),
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
              SizedBox(height: 0.03 * size.height),
              ColorSelector(
                  selectedColorIndex: _selectedColor,
                  colors: AppEventColors.values,
                  onSelected: (index) {
                    setState(() {
                      _selectedColor = index;
                      _event.color = AppEventColors.values[index];
                    });
                  })
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
                  _event.title = _eventNameController.text;
                  _event.description = _eventDescriptionController.text;
                  _event.category = _category ?? KeepUpEventCategory.other;
                  if (_justToday &&
                      widget.fromTask != null &&
                      widget.fromTask!.recurrenceType !=
                          KeepUpRecurrenceType.none) {
                    _event.recurrences.where((recurrence) {
                      return (recurrence.type == KeepUpRecurrenceType.weekly &&
                              recurrence.weekDay == widget.fromDate!.weekday) ||
                          recurrence.type == KeepUpRecurrenceType.daily;
                    }).forEach((recurrence) {
                      recurrence.addException(
                          onDate: (widget.fromDate ?? DateTime.now())
                              .getDateOnly());
                    });
                  }

                  KeepUpResponse response;

                  if (_event.id == null) {
                    response = await KeepUp.instance.createEvent(_event);
                  } else {
                    response = await KeepUp.instance.updateEvent(_event);
                  }

                  if (response.error) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(_eventCreationSnackbar);
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
        SizedBox(height: 0.05 * size.height)
      ],
    );
  }
}

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
                labelText: controller != null && controller!.text.isEmpty
                    ? null
                    : hint,
                floatingLabelStyle:
                    const TextStyle(color: AppColors.primaryColor),
                border: UnderlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon:
                    Icon(Icons.timer, color: Theme.of(context).hintColor))));
  }
}

class AppWeekDaySelector extends StatelessWidget {
  final int selectedDay;
  final bool Function(int) isScheduled;
  final Function(int) onSelected;
  const AppWeekDaySelector(
      {Key? key,
      this.selectedDay = 0,
      required this.isScheduled,
      required this.onSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
            children: List.generate(weekDays.length, (index) {
          bool isDayScheduled = isScheduled(index);
          return SizedBox(
              width: size.width / 8.5,
              child: TextButton(
                  style: TextButton.styleFrom(
                      animationDuration: const Duration(milliseconds: 200),
                      primary: isDayScheduled
                          ? AppColors.primaryColor
                          : AppColors.fieldBackgroundColor,
                      elevation: selectedDay == index ? 5 : 0,
                      fixedSize: selectedDay == index
                          ? const Size.fromHeight(50)
                          : const Size.fromHeight(40),
                      shape: const CircleBorder(),
                      backgroundColor: isDayScheduled
                          ? AppColors.primaryColor
                          : AppColors.fieldBackgroundColor),
                  onPressed: () => onSelected(index),
                  child: Text(weekDays[index][0].toUpperCase(),
                      style: TextStyle(
                          color: isDayScheduled
                              ? Colors.white
                              : AppColors.fieldTextColor))));
        })));
  }
}

class SwitchInputField extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool?)? onChanged;
  const SwitchInputField(
      {Key? key, required this.label, required this.value, this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.fieldBackgroundColor),
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(children: [
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).hintColor,
                          fontSize: 16))),
              const Expanded(child: SizedBox(width: 10)),
              SizedBox(
                height: 24.0,
                width: 24.0,
                child: Transform.scale(
                    scale: 1.3,
                    child: Checkbox(
                        fillColor: value
                            ? MaterialStateProperty.all(AppColors.primaryColor)
                            : Theme.of(context).checkboxTheme.fillColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        value: value,
                        onChanged: onChanged)),
              )
            ])),
      ]),
    );
  }
}
