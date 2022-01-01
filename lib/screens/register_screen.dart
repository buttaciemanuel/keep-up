import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:email_validator/email_validator.dart';
import 'package:keep_up/style.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/screens/login_screen.dart';
import 'package:keep_up/screens/student_sync_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

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
    const snackBar = SnackBar(
        padding: EdgeInsets.all(20),
        content: Text('Non riesco a registrare il tuo account'));
    return AppLayout(
      children: [
        SizedBox(height: 0.05 * size.height),
        Expanded(
            child: Image.asset('assets/images/schedule.png',
                height: 0.25 * size.height, width: 0.7 * size.width)),
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
                  hint: 'Il tuo nome e cognome',
                  label: 'Nome e cognome',
                  textInputAction: TextInputAction.next,
                  icon: Icons.person,
                  inputType: TextInputType.name,
                  controller: _fullnameController),
              SizedBox(height: 0.02 * size.height),
              AppTextField(
                  validator: _emailValidator,
                  hint: 'La tua email',
                  label: 'Email',
                  textInputAction: TextInputAction.next,
                  inputType: TextInputType.emailAddress,
                  icon: Icons.email,
                  controller: _emailController),
              SizedBox(height: 0.02 * size.height),
              AppTextField(
                  validator: _passwordValidator,
                  hint: 'Almeno 8 caratteri',
                  label: 'Password',
                  textInputAction: TextInputAction.done,
                  icon: Icons.lock,
                  isPassword: true,
                  controller: _passwordController),
              SizedBox(height: 0.04 * size.height),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      KeepUp.instance
                          .register(
                              _fullnameController.text.trim(),
                              _emailController.text.trim(),
                              _passwordController.text.trim())
                          .then((value) {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(
                            builder: (context) => StudentSyncScreen(
                                username: _fullnameController.text)));
                      }).onError((error, stackTrace) {
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      });
                    }
                  },
                  child: const Text('Registrati'),
                  style: TextButton.styleFrom(primary: AppColors.primaryColor),
                ),
              ),
              SizedBox(height: 0.05 * size.height)
            ]))
      ],
    );
  }
}
