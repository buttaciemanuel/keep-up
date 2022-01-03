import 'dart:developer';
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:keep_up/constant.dart';
import 'package:keep_up/screens/student_timetable_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/services/polito_api.dart';
import 'package:keep_up/style.dart';
import 'package:keep_up/components/text_field.dart';

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

  Future<void> _downloadUniversitySchedule(
      {required Function onComplete}) async {
    const unsupportedUniversitySnackBar = SnackBar(
        padding: EdgeInsets.all(20),
        content: Text('L\'università scelta non è supportata'));
    const unauthorizedUniversitySnackBar = SnackBar(
        padding: EdgeInsets.all(20),
        content: Text('La matricola o la password non corrisponde'));
    const downloadUniversitySnackBar = SnackBar(
        padding: EdgeInsets.all(20),
        content: Text('Non riesco a scaricare i tuoi orari'));
    const uploadUniversitySnackBar = SnackBar(
        padding: EdgeInsets.all(20),
        content: Text('Non riesco a caricare i tuoi orari sull\'app'));
    switch (_selectedUniversity) {
      case UniversityItem.polito:
        // avvia il client di connessione all'università
        await PolitoClient.instance.init();
        // accesso all'account istituzionale
        var response = await PolitoClient.instance.loginUser(
            _studentIdController.text.trim(),
            _studentPasswordController.text.trim());
        // controlla che non siano avvenuti errori
        if (response.error) {
          ScaffoldMessenger.of(context)
              .showSnackBar(unauthorizedUniversitySnackBar);
          return;
        }
        // scaricamento degli orari ordinati dall'account dell'università
        response = await PolitoClient.instance
            .getWeekSchedule(inDate: DateTime(2021, 12, 1));
        // logout da account istituzionale
        await PolitoClient.instance.logoutUser();
        // controlla che non siano avvenuti errori
        if (response.error) {
          ScaffoldMessenger.of(context)
              .showSnackBar(downloadUniversitySnackBar);
          return;
        }
        // scrittura delle lezioni su server
        final events = HashMap<String, KeepUpEvent>();
        final lectures = response.result as List<PolitoLecture>;
        // creazione di eventi settimanali a partire dalle lezioni
        for (final lecture in lectures) {
          if (events.containsKey(lecture.subject)) {
            events.update(lecture.subject, (event) {
              event.addWeeklySchedule(
                  weekDay: lecture.startDateTime.weekday,
                  startTime: KeepUpDayTime.fromDateTime(lecture.startDateTime),
                  endTime: KeepUpDayTime.fromDateTime(lecture.endDateTime));
              return event;
            });
          } else {
            final event = KeepUpEvent(
                title: lecture.subject,
                startDate: lecture.startDateTime,
                color: AppEventColors.fromEvent(lecture.subject));
            event.addWeeklySchedule(
                weekDay: lecture.startDateTime.weekday,
                startTime: KeepUpDayTime.fromDateTime(lecture.startDateTime),
                endTime: KeepUpDayTime.fromDateTime(lecture.endDateTime));
            events.putIfAbsent(lecture.subject, () => event);
          }
        }
        // scrittura degli eventi sul database
        for (final event in events.values) {
          KeepUpResponse response = await KeepUp.instance.createEvent(event);
          // controlla se sono avvenuti errori
          if (response.error) {
            ScaffoldMessenger.of(context)
                .showSnackBar(uploadUniversitySnackBar);
            return;
          }
        }
        // prosegue alla prossima schemata
        onComplete();
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
        Expanded(
            child: Image.asset('assets/images/students.png',
                height: 0.25 * size.height, width: 0.9 * size.width)),
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
                  label: 'Università',
                  hint: "La tua università"),
              SizedBox(height: 0.02 * size.height),
              if (_selectedUniversity != null) ...[
                AppTextField(
                    validator: _studentIdValidator,
                    hint: 'La tua matricola studente',
                    label: 'Matricola studente',
                    textInputAction: TextInputAction.next,
                    icon: Icons.person,
                    controller: _studentIdController),
                SizedBox(height: 0.02 * size.height),
                AppTextField(
                    validator: _studentPasswordValidator,
                    hint: 'La tua password studente',
                    label: 'Password studente',
                    textInputAction: TextInputAction.done,
                    icon: Icons.lock,
                    isPassword: true,
                    controller: _studentPasswordController)
              ],
              SizedBox(height: 0.04 * size.height),
              Row(children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) =>
                              const StudentTimetableScreen()));
                    },
                    child: const Text('Salta'),
                    style: TextButton.styleFrom(primary: AppColors.grey),
                  ),
                ),
                const Expanded(child: SizedBox()),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _downloadUniversitySchedule(onComplete: () {
                            Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const StudentTimetableScreen()));
                          });
                        }
                      },
                      child: const Text('Avanti')),
                ),
              ]),
              SizedBox(height: 0.05 * size.height),
            ]))
      ],
    );
  }
}
