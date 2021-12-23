import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:keep_up/style.dart';

class StudentTimetableScreen extends StatefulWidget {
  const StudentTimetableScreen({Key? key}) : super(key: key);

  @override
  _StudentTimetableScreenState createState() => _StudentTimetableScreenState();
}

class _StudentTimetableScreenState extends State<StudentTimetableScreen> {
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
            SvgPicture.asset('assets/images/timetable.svg',
                height: size.height * 0.25),
            SizedBox(height: 0.03 * size.height),
          ],
        ),
      ),
    );
  }
}
