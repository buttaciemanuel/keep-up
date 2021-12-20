import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:email_validator/email_validator.dart';
import 'package:keep_up/components/background.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/constants.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
        body: AppBackground(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/images/schedule.svg',
                height: size.height * 0.25),
            SizedBox(height: 0.05 * size.height),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('Benvenuto!',
                    style:
                        TextStyle(fontWeight: FontWeight.w900, fontSize: 36))),
            SizedBox(height: 0.03 * size.height),
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
                  SizedBox(height: 0.03 * size.height),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (context) => HelloScreen(
                                      userName: _fullnameController.text)));
                        }
                      },
                      child:
                          const Text('Avanti', style: TextStyle(fontSize: 20)),
                      style: TextButton.styleFrom(primary: kPrimaryColor),
                    ),
                  )
                ]))
          ],
        ),
      ),
    ));
  }
}

class HelloScreen extends StatefulWidget {
  final String userName;
  const HelloScreen({Key? key, required this.userName}) : super(key: key);

  @override
  _HelloScreenState createState() => _HelloScreenState();
}

class _HelloScreenState extends State<HelloScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _universityController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
        body: AppBackground(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/images/students.svg',
                height: size.height * 0.25),
            SizedBox(height: 0.05 * size.height),
            Align(
                alignment: Alignment.centerLeft,
                child: Text("Ciao, ${widget.userName.split(' ')[0]}",
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 36))),
            SizedBox(height: 0.01 * size.height),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('Aiutami a recuperare i tuoi orari.',
                    style:
                        TextStyle(fontWeight: FontWeight.w300, fontSize: 22))),
            SizedBox(height: 0.03 * size.height),
            Form(
                key: _formKey,
                child: Column(children: [
                  const AppDropDownTextField(
                      showSearchBox: true,
                      items: ["Politecnico di Torino", "Università di Torino"],
                      hint: "La tua università"),
                  SizedBox(height: 0.02 * size.height),
                  const AppDropDownTextField(
                      showSearchBox: true,
                      items: [
                        "Architettura",
                        "Ingegneria Informatica",
                        "Design"
                      ],
                      hint: "Il tuo corso di studi"),
                  SizedBox(height: 0.02 * size.height),
                  const AppDropDownTextField(
                      items: ["Primo anno", "Secondo anno", "Terzo anno"],
                      hint: "Il tuo anno"),
                  SizedBox(height: 0.03 * size.height),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {}
                      },
                      child:
                          const Text('Avanti', style: TextStyle(fontSize: 20)),
                      style: TextButton.styleFrom(primary: kPrimaryColor),
                    ),
                  )
                ]))
          ],
        ),
      ),
    ));
  }
}
