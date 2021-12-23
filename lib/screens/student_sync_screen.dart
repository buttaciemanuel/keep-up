import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:keep_up/screens/student_timetable_screen.dart';
import 'package:keep_up/style.dart';
import 'package:keep_up/components/text_field.dart';

class StudentSyncScreen extends StatefulWidget {
  final String userName;
  const StudentSyncScreen({Key? key, required this.userName}) : super(key: key);

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
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return AppBackground(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Salta'),
                style: TextButton.styleFrom(primary: AppColors.grey),
              ),
            ),
            SvgPicture.asset('assets/images/students.svg',
                height: size.height * 0.25),
            SizedBox(height: 0.03 * size.height),
            Align(
                alignment: Alignment.centerLeft,
                child: Text("Ciao, ${widget.userName.split(' ')[0]}",
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
                      items: ['Politecnico di Torino'],
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
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const StudentTimetableScreen()));
                          }
                        },
                        child: const Text('Avanti')),
                  )
                ]))
          ],
        ),
      ),
    );
  }
}
