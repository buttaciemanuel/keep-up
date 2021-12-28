import 'package:flutter/material.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';
import 'package:keep_up/constant.dart';

class AppTimeTextField extends StatelessWidget {
  final String? hint;
  const AppTimeTextField({Key? key, this.hint}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            color: AppColors.fieldBackgroundColor,
            borderRadius: BorderRadius.circular(10)),
        child: TextFormField(
            textAlign: TextAlign.center,
            readOnly: true,
            style: Theme.of(context).textTheme.bodyText1,
            cursorColor: AppColors.primaryColor,
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder
                  .none, /*icon: const Icon(Icons.timer, color: AppColors.grey)*/
            )));
  }
}

class DefineEventScreen extends StatefulWidget {
  final KeepUpTask? fromTask;
  const DefineEventScreen({Key? key, this.fromTask}) : super(key: key);

  @override
  _DefineEventScreenState createState() => _DefineEventScreenState();
}

class _DefineEventScreenState extends State<DefineEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  int _selectedDay = 0;

  String? _eventNameValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Inserisci il nome dell\'attività';
    }
    return null;
  }

  @override
  void dispose() {
    _eventNameController.dispose();
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

  Widget editExistingEvent(BuildContext context) {
    Size size = MediaQuery.of(context).size;
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
                          inputType: TextInputType.name,
                          controller: _eventNameController),
                      SizedBox(height: 0.02 * size.height),
                      const AppTextField(
                          isTextArea: true,
                          hint: 'La descrizione dell\'attività'),
                      SizedBox(height: 0.04 * size.height),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              'Pianifica l\'attività durante la settimana.',
                              style: Theme.of(context).textTheme.subtitle1)),
                      SizedBox(height: 0.02 * size.height),
                      SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                              children: List.generate(weekDays.length, (index) {
                            return TextButton(
                                style: TextButton.styleFrom(
                                    side: _selectedDay == index
                                        ? const BorderSide(
                                            width: 3.0, color: AppColors.grey)
                                        : BorderSide.none,
                                    shape: const CircleBorder(),
                                    backgroundColor: AppColors.lightGrey),
                                onPressed: () =>
                                    setState(() => _selectedDay = index),
                                child: Text(weekDays[index][0].toUpperCase(),
                                    style:
                                        const TextStyle(color: Colors.white)));
                          }))),
                      SizedBox(height: 0.03 * size.height),
                      AppTimeTextField(hint: 'Ora di inizio'),
                      SizedBox(height: 0.02 * size.height),
                      AppTimeTextField(hint: 'Ora di fine')
                    ])),
                Expanded(child: SizedBox()),
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
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {}
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
