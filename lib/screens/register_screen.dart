import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:email_validator/email_validator.dart';
import 'package:keep_up/style.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/screens/login_screen.dart';
import 'package:keep_up/screens/student_sync_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _fullnameValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Inserisci il tuo nome';
    } else if (!RegExp(r'^[a-z A-Z,.\-]+$').hasMatch(text)) {
      return 'Inserisci un nome valido';
    }
    return null;
  }

  String? _emailValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Inserisci la tua email';
    } else if (!EmailValidator.validate(text)) {
      return 'Inserisci una email valida';
    }
    return null;
  }

  String? _passwordValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Scegli la tua password';
    } else if (!RegExp(
            r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$')
        .hasMatch(text)) {
      return 'Scegli una password di almeno 8 caratteri';
    }
    return null;
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
            SvgPicture.asset('assets/images/schedule.svg',
                height: size.height * 0.25),
            SizedBox(height: 0.05 * size.height),
            Align(
                alignment: Alignment.centerLeft,
                child: Text('Benvenuto!',
                    style: Theme.of(context).textTheme.headline1)),
            SizedBox(height: 0.02 * size.height),
            Align(
              alignment: Alignment.centerLeft,
              child: RichText(
                textAlign: TextAlign.left,
                text: TextSpan(children: [
                  TextSpan(
                      text: "Hai già un account? ",
                      style: Theme.of(context).textTheme.subtitle1),
                  TextSpan(
                    text: "Accedi",
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => const LoginScreen()));
                      },
                    style: Theme.of(context).textTheme.button,
                  )
                ]),
              ),
            ),
            SizedBox(height: 0.04 * size.height),
            Form(
                key: _formKey,
                child: Column(children: [
                  AppTextField(
                      validator: _fullnameValidator,
                      hint: 'Il tuo nome',
                      icon: Icons.person,
                      controller: _fullnameController),
                  SizedBox(height: 0.02 * size.height),
                  AppTextField(
                      validator: _emailValidator,
                      hint: 'La tua email',
                      icon: Icons.email,
                      controller: _emailController),
                  SizedBox(height: 0.02 * size.height),
                  AppTextField(
                      validator: _passwordValidator,
                      hint: 'La tua password',
                      icon: Icons.lock,
                      isPassword: true,
                      controller: _passwordController),
                  SizedBox(height: 0.04 * size.height),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (context) => StudentSyncScreen(
                                      userName: _fullnameController.text)));
                        }
                      },
                      child: const Text('Registrati'),
                      style:
                          TextButton.styleFrom(primary: AppColors.primaryColor),
                    ),
                  )
                ]))
          ],
        ),
      ),
    );
  }
}
