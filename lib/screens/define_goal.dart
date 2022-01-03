import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_up/components/color_selector.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/slider_input_field.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';
import 'package:keep_up/constant.dart';

class AppDateTextField extends StatelessWidget {
  final String? initialText;
  final String label;
  final String? hint;
  final double? width;
  final Function()? onTap;
  final TextEditingController? controller;
  final IconData? icon;
  final Function(DateTime)? onSelected;
  const AppDateTextField(
      {Key? key,
      required this.label,
      this.onSelected,
      this.hint,
      this.onTap,
      this.controller,
      this.initialText,
      this.width,
      this.icon})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SizedBox(
        width: width ?? size.width,
        child: TextFormField(
            initialValue: initialText,
            controller: controller,
            onTap: () async {
              final date = await showDatePicker(
                  context: context,
                  initialDatePickerMode: DatePickerMode.day,
                  fieldLabelText: label,
                  cancelText: 'Annulla',
                  confirmText: 'Salva',
                  fieldHintText: hint,
                  errorInvalidText: 'La data non è valida',
                  errorFormatText: 'La data non è valida',
                  helpText: label,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        dialogTheme: const DialogTheme(
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0)))),
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
                if (controller != null) {
                  controller!.text = DateFormat.yMMMM('it').format(date);
                }
                if (onSelected != null) onSelected!(date);
              }
            },
            textAlign: TextAlign.start,
            readOnly: true,
            style: Theme.of(context).textTheme.bodyText1,
            decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
                filled: true,
                fillColor: AppColors.fieldBackgroundColor,
                hintText: label,
                labelText: controller != null && controller!.text.isEmpty
                    ? null
                    : label,
                floatingLabelStyle:
                    const TextStyle(color: AppColors.primaryColor),
                border: UnderlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon: Icon(icon ?? Icons.calendar_today,
                    color: Theme.of(context).hintColor))));
  }
}

class AppCategorySelector extends StatelessWidget {
  final List<String> categories;
  final String? value;
  final Function(String) onClicked;
  const AppCategorySelector(
      {Key? key, required this.categories, this.value, required this.onClicked})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
          children: categories.map((category) {
        return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: TextButton(
                style: TextButton.styleFrom(
                    animationDuration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                    primary: category == value
                        ? AppColors.primaryColor
                        : AppColors.fieldBackgroundColor,
                    elevation: category == value ? 5 : 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: category == value
                        ? AppColors.primaryColor
                        : AppColors.fieldBackgroundColor),
                onPressed: () => onClicked(category),
                child: Text(category,
                    style: TextStyle(
                        color: category == value
                            ? Colors.white
                            : AppColors.fieldTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600))));
      }).toList()),
    );
  }
}

class DefineGoalScreen extends StatefulWidget {
  const DefineGoalScreen({Key? key}) : super(key: key);

  @override
  _DefineGoalScreenState createState() => _DefineGoalScreenState();
}

class _DefineGoalScreenState extends State<DefineGoalScreen> {
  static const _dateMismatchSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('La data inserita non ha molto senso'));
  static const _goalCreationSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Sembra ci sia un errore nel creare l\'obiettivo'));

  late KeepUpEvent _goal;
  final _formKey = GlobalKey<FormState>();
  final _goalNameController = TextEditingController();
  final _goalDescriptionController = TextEditingController();
  final _finishDatePickerController = TextEditingController();
  String? _category = null;
  DateTime? _finishDate = null;
  double _daysPerWeek = 3;
  double _hoursPerDay = 1;
  int _selectedColor = 0;

  String? _goalNameValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Inserisci il nome dell\'obiettivo';
    }
    return null;
  }

  @override
  void initState() {
    _goal = KeepUpEvent(
        title: '', startDate: DateTime.now(), color: AppColors.primaryColor);

    super.initState();
  }

  @override
  void dispose() {
    _goalNameController.dispose();
    _goalDescriptionController.dispose();
    _finishDatePickerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //if (widget.fromTask != null) return _editExistingEvent(context);
    return _createNewEventScreen(context);
  }

  // scarica l'evento dal database solo al primo caricamento di schermata,
  // ovvero lazy loading, e dopo lo riutilizza per un merge
  Future<bool> _getExistingEvent(String eventId) async {
    if (_goal.id != null) return true;

    final response = await KeepUp.instance.getEvent(eventId: eventId);

    if (response.error) return false;

    _goal = response.result as KeepUpEvent;

    return true;
  }

  Widget _createNewEventScreen(BuildContext context) {
    return _form(context, screenTitle: 'Pianifica l\'obiettivo');
  }

  /*Widget _editExistingEvent(BuildContext context) {
    const screenTitle = 'Modifica l\'attività';
    return FutureBuilder<bool>(
        future: _getExistingEvent(widget.fromTask!.eventId),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _goalNameController.text = _goal.title;

            if (_goal.description != null) {
              _goalDescriptionController.text = _goal.description!;
            }

            return _form(context, screenTitle: screenTitle);
          } else {
            return _loadingSkeleton(context, screenTitle: screenTitle);
          }
        });
  }*/

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
              const SkeletonLoader(
                  child: AppDateTextField(label: 'Realizzazione')),
              SizedBox(height: 0.03 * size.height),
              const SkeletonLoader(
                  child: AppTextField(
                      hint: 'Il nome dell\'obiettivo',
                      label: 'Obiettivo',
                      inputType: TextInputType.name)),
              SizedBox(height: 0.02 * size.height),
              const SkeletonLoader(
                  child: AppTextField(
                      isTextArea: true,
                      label: 'Descrizione',
                      hint: 'La descrizione dell\'obiettivo')),
            ])),
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
            child: Text('Proietta il tuo impegno nel futuro.',
                style: Theme.of(context).textTheme.subtitle1)),
        SizedBox(height: 0.03 * size.height),
        Form(
            key: _formKey,
            child: Column(children: [
              AppCategorySelector(
                  value: _category,
                  categories: ['Educazione', 'Sport', 'Altro'],
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
              AppDateTextField(
                  label: 'Realizzazione',
                  hint: 'Data di realizzazione',
                  icon: Icons.flag,
                  controller: _finishDatePickerController,
                  onSelected: (date) {
                    setState(() => _finishDate = date);
                  }),
              SizedBox(height: 0.02 * size.height),
              AppTextField(
                  validator: _goalNameValidator,
                  hint: 'Il nome dell\'obiettivo',
                  label: 'Obiettivo',
                  inputType: TextInputType.name,
                  controller: _goalNameController),
              SizedBox(height: 0.02 * size.height),
              AppTextField(
                  controller: _goalDescriptionController,
                  isTextArea: true,
                  label: 'Descrizione',
                  hint: 'La descrizione dell\'obiettivo'),
              SizedBox(height: 0.02 * size.height),
              SliderInputField(
                label: 'Giorni alla settimana',
                value: _daysPerWeek,
                min: 1,
                max: 7,
                onChanged: (value) => setState(() => _daysPerWeek = value),
              ),
              SizedBox(height: 0.02 * size.height),
              SliderInputField(
                label: 'Ore al giorno',
                value: _hoursPerDay,
                min: 1,
                max: 6,
                onChanged: (value) => setState(() => _hoursPerDay = value),
              ),
              SizedBox(height: 0.03 * size.height),
              ColorSelector(
                  selectedColorIndex: _selectedColor,
                  colors: AppEventColors.values,
                  onSelected: (index) {
                    setState(() {
                      _selectedColor = index;
                      _goal.color = AppEventColors.values[index];
                    });
                  })
            ])),
        Expanded(child: SizedBox(height: 0.03 * size.height)),
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
                  /*_goal.title = _goalNameController.text;
                  _goal.description = _goalDescriptionController.text;
                  final response = await KeepUp.instance.updateEvent(_goal);
                  if (response.error) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(_goalCreationSnackbar);
                  } else {
                    Navigator.of(context).pop();
                  }*/
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
