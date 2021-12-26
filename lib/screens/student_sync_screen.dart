import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:keep_up/screens/student_timetable_screen.dart';
import 'package:keep_up/services/polito_api.dart';
import 'package:keep_up/style.dart';
import 'package:keep_up/components/text_field.dart';

abstract class UniversityItem {
  static const polito = 'Politenico di Torino';
}

class StudentSyncScreen extends StatefulWidget {
  final String username;
  const StudentSyncScreen({Key? key, required this.username}) : super(key: key);

  @override
  _StudentSyncScreenState createState() => _StudentSyncScreenState();
}

class _StudentSyncScreenState extends State<StudentSyncScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _studentPasswordController =
      TextEditingController();
  String? _selectedUniversity;

  String? _studentIdValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Inserisci la tua matricola studente';
    }
    return null;
  }

  String? _studentPasswordValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Inserisci la tua password studente';
    }
    return null;
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _studentPasswordController.dispose();
    super.dispose();
  }

  Future<void> _downloadUniversitySchedule() async {
    const unsupportedUniversitySnackBar = SnackBar(
        padding: EdgeInsets.all(20),
        content: Text('L\'università scelta non è supportata'));
    const unauthorizedUniversitySnackBar = SnackBar(
        padding: EdgeInsets.all(20),
        content: Text('La matricola o la password non corrisponde'));
    const errorUniversitySnackBar = SnackBar(
        padding: EdgeInsets.all(20),
        content: Text('Non riesco a scaricare i tuoi orari'));
    switch (_selectedUniversity) {
      case UniversityItem.polito:
        // avvia il client di connessione all'università
        await PolitoClient.instance.init();
        // accesso all'account istituzionale
        await PolitoClient.instance
            .loginUser(_studentIdController.text.trim(),
                _studentPasswordController.text.trim())
            .onError((error, stackTrace) {
          ScaffoldMessenger.of(context)
              .showSnackBar(unauthorizedUniversitySnackBar);
        });
        // scaricamento degli orari dall'account dell'università
        final lectures = await PolitoClient.instance
            .getWeekSchedule(inDate: DateTime(2021, 12, 1))
            .onError((error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(errorUniversitySnackBar);
        });
        // scrittura delle lezioni su server

        // logout da account istituzionale
        await PolitoClient.instance.logoutUser();
        break;
      default:
        ScaffoldMessenger.of(context)
            .showSnackBar(unsupportedUniversitySnackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return AppLayout(
      children: [
        SizedBox(height: 0.05 * size.height),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text('Salta'),
            style: TextButton.styleFrom(primary: AppColors.grey),
          ),
        ),
        Expanded(child: SvgPicture.asset('assets/images/students.svg')),
        SizedBox(height: 0.05 * size.height),
        Align(
            alignment: Alignment.centerLeft,
            child: Text("Ciao, ${widget.username.split(' ')[0]}",
                style: Theme.of(context).textTheme.headline1)),
        SizedBox(height: 0.02 * size.height),
        Align(
            alignment: Alignment.centerLeft,
            child: Text('Collegati al tuo account studente!',
                style: Theme.of(context).textTheme.subtitle1)),
        SizedBox(height: 0.04 * size.height),
        Form(
            key: _formKey,
            child: Column(children: [
              AppDropDownTextField(
                  showSearchBox: true,
                  onChanged: (university) {
                    setState(() => _selectedUniversity = university);
                  },
                  items: const [UniversityItem.polito],
                  hint: "La tua università"),
              SizedBox(height: 0.02 * size.height),
              if (_selectedUniversity != null) ...[
                AppTextField(
                    validator: _studentIdValidator,
                    hint: 'La tua matricola studente',
                    icon: Icons.person,
                    controller: _studentIdController),
                SizedBox(height: 0.02 * size.height),
                AppTextField(
                    validator: _studentPasswordValidator,
                    hint: 'La tua password studente',
                    icon: Icons.lock,
                    isPassword: true,
                    controller: _studentPasswordController)
              ],
              SizedBox(height: 0.04 * size.height),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _downloadUniversitySchedule();

                        /*Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (context) =>
                                const StudentTimetableScreen()));*/
                      }
                    },
                    child: const Text('Avanti')),
              ),
              SizedBox(height: 0.05 * size.height),
            ]))
      ],
    );
  }
}
