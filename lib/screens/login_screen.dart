import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:keep_up/style.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _emailValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Inserisci la tua email';
    }
    return null;
  }

  String? _passwordValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Scegli la tua password';
    }
    return null;
  }

  @override
  void dispose() {
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
                child: Text('Bentornato!',
                    style: Theme.of(context).textTheme.headline1)),
            SizedBox(height: 0.02 * size.height),
            Align(
              alignment: Alignment.centerLeft,
              child: RichText(
                textAlign: TextAlign.left,
                text: TextSpan(children: [
                  TextSpan(
                      text: "Non hai un account? ",
                      style: Theme.of(context).textTheme.subtitle1),
                  TextSpan(
                    text: "Registrati",
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => const RegisterScreen()));
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
                          print('OPEN HOME (TODAY) PAGE');
                        }
                      },
                      child: const Text('Accedi'),
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