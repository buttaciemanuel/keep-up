import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:keep_up/components/category_selector.dart';
import 'package:keep_up/components/color_selector.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/slider_input_field.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';
import 'package:keep_up/constant.dart';

class AppDateTextField extends StatelessWidget {
  static final formatter = DateFormat.yMMMM('it');
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
                  controller!.text = formatter.format(date);
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

class DefineGoalScreen extends StatefulWidget {
  final KeepUpGoal? fromGoal;
  const DefineGoalScreen({Key? key, this.fromGoal}) : super(key: key);

  @override
  _DefineGoalScreenState createState() => _DefineGoalScreenState();
}

class _DefineGoalScreenState extends State<DefineGoalScreen> {
  static const _goalCreationSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Sembra ci sia un errore nel creare l\'obiettivo'));
  static const _goalUpdateSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Sembra ci sia un errore nel modificare l\'obiettivo'));
  static const _formErrorSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Scegli almeno una categoria di obiettivo'));
  static const _formFinishErrorSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Scegli almeno una data di completamento'));

  final _formKey = GlobalKey<FormState>();
  final _goalNameController = TextEditingController();
  final _goalDescriptionController = TextEditingController();
  final _finishDatePickerController = TextEditingController();
  DateTime? _finishDate;
  int _selectedColor = 0;
  double _daysPerWeek = 3;
  double _hoursPerDay = 1;
  String? _category;

  String? _goalNameValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Inserisci il nome dell\'obiettivo';
    }
    return null;
  }

  @override
  void initState() {
    if (widget.fromGoal != null) {
      _goalNameController.text = widget.fromGoal!.title;
      if (widget.fromGoal!.description != null) {
        _goalDescriptionController.text = widget.fromGoal!.description!;
      }
      if (widget.fromGoal!.endDate != null) {
        _finishDate = widget.fromGoal!.endDate;
        _finishDatePickerController.text =
            AppDateTextField.formatter.format(widget.fromGoal!.endDate!);
      }
      _selectedColor = AppEventColors.values.indexOf(widget.fromGoal!.color);
      _daysPerWeek = widget.fromGoal!.daysPerWeek.roundToDouble();
      _hoursPerDay = widget.fromGoal!.hoursPerDay.roundToDouble();
      _category = widget.fromGoal!.category;
    }

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
    if (widget.fromGoal != null) {
      return _form(context, screenTitle: 'Modifica l\'obiettivo');
    }

    return _form(context, screenTitle: 'Pianifica l\'obiettivo');
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
            child: Text('Proietta il tuo impegno nel futuro.',
                style: Theme.of(context).textTheme.subtitle1)),
        SizedBox(height: 0.03 * size.height),
        Form(
            key: _formKey,
            child: Column(children: [
              AppScrollCategorySelector(
                  categories: KeepUpEventCategory.values, onClicked: (_) {}),
              SizedBox(height: 0.02 * size.height),
              SkeletonLoader(
                  child: AppDateTextField(
                      label: 'Realizzazione',
                      hint: 'Data di realizzazione',
                      icon: Icons.flag,
                      onSelected: (_) {})),
              SizedBox(height: 0.02 * size.height),
              SkeletonLoader(
                  child: AppTextField(
                      hint: 'Il nome dell\'obiettivo',
                      label: 'Obiettivo',
                      inputType: TextInputType.name,
                      controller: _goalNameController)),
              SizedBox(height: 0.02 * size.height),
              const SkeletonLoader(
                  child: AppTextField(
                      isTextArea: true,
                      label: 'Descrizione',
                      hint: 'La descrizione dell\'obiettivo')),
              SizedBox(height: 0.02 * size.height),
              SkeletonLoader(
                child: SliderInputField(
                    label: 'Giorni alla settimana',
                    value: _daysPerWeek,
                    min: 1,
                    max: 7,
                    onChanged: (_) {}),
              ),
              SizedBox(height: 0.02 * size.height),
              SkeletonLoader(
                  child: SliderInputField(
                label: 'Ore al giorno',
                value: _hoursPerDay,
                min: 1,
                max: 6,
                onChanged: (value) => setState(() => _hoursPerDay = value),
              )),
              SizedBox(height: 0.03 * size.height),
              SkeletonLoader(
                  child: ColorSelector(
                      selectedColorIndex: _selectedColor,
                      colors: AppEventColors.values,
                      onSelected: (_) {}))
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
              AppScrollCategorySelector(
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
                    setState(() => _selectedColor = index);
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
                  if (_category == null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(_formErrorSnackbar);
                  } else if (_finishDate == null) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(_formFinishErrorSnackbar);
                  } else if (widget.fromGoal == null) {
                    final newGoal = KeepUpGoal(
                        title: _goalNameController.text,
                        description: _goalDescriptionController.text,
                        startDate: DateTime.now(),
                        endDate: _finishDate,
                        color: AppEventColors.values[_selectedColor],
                        daysPerWeek: _daysPerWeek.round(),
                        hoursPerDay: _hoursPerDay.round(),
                        category: _category!);

                    final response = await KeepUp.instance.createGoal(newGoal);

                    if (response.error) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(_goalCreationSnackbar);
                    } else {
                      Navigator.of(context).pop();
                    }
                  } else {
                    widget.fromGoal!.title = _goalNameController.text;
                    widget.fromGoal!.description =
                        _goalDescriptionController.text;
                    widget.fromGoal!.endDate = _finishDate;
                    widget.fromGoal!.color =
                        AppEventColors.values[_selectedColor];
                    widget.fromGoal!.daysPerWeek = _daysPerWeek.round();
                    widget.fromGoal!.hoursPerDay = _hoursPerDay.round();
                    widget.fromGoal!.category = _category!;

                    final response =
                        await KeepUp.instance.updateGoal(widget.fromGoal!);

                    if (response.error) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(_goalUpdateSnackbar);
                    } else {
                      Navigator.of(context).pop();
                    }
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
