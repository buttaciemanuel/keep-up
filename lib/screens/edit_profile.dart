import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/screens/login_screen.dart';
import 'package:keep_up/screens/oops_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _updateErrorSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Sembra ci sia un errore nel modificare il profilo'));

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

  _loadingSkeleton() {
    final size = MediaQuery.of(context).size;
    return AppLayout(children: [
      SizedBox(height: 0.05 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Modifica profilo',
              style: Theme.of(context).textTheme.headline2)),
      SizedBox(height: 0.02 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Aggiorna i tuoi dati.',
              style: Theme.of(context).textTheme.subtitle1)),
      SizedBox(height: 0.05 * size.height),
      Form(
          key: _formKey,
          child: Column(children: [
            SkeletonLoader(
                child: AppTextField(
                    validator: _fullnameValidator,
                    hint: 'Il tuo nome e cognome',
                    label: 'Nome e cognome',
                    textInputAction: TextInputAction.next,
                    icon: Icons.person,
                    inputType: TextInputType.name,
                    controller: _fullnameController)),
            SizedBox(height: 0.02 * size.height),
            SkeletonLoader(
                child: AppTextField(
                    validator: _emailValidator,
                    hint: 'La tua email',
                    label: 'Email',
                    textInputAction: TextInputAction.next,
                    inputType: TextInputType.emailAddress,
                    icon: Icons.email,
                    controller: _emailController)),
            /*SizedBox(height: 0.02 * size.height),
            SkeletonLoader(
                child: AppTextField(
                    validator: _passwordValidator,
                    hint: 'Almeno 8 caratteri',
                    label: 'Password',
                    textInputAction: TextInputAction.done,
                    icon: Icons.lock,
                    isPassword: true,
                    controller: _passwordController)),*/
          ])),
      Expanded(child: SizedBox(height: size.height * 0.03)),
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
            onPressed: () async {},
            child: const Text('Salva'),
            style: TextButton.styleFrom(primary: AppColors.primaryColor),
          ),
        ),
      ]),
      SizedBox(height: 0.05 * size.height),
    ]);
  }

  _form(KeepUpUser user) {
    final size = MediaQuery.of(context).size;

    _fullnameController.text = user.fullname;
    _emailController.text = user.email;

    return AppLayout(children: [
      SizedBox(height: 0.05 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Modifica profilo',
              style: Theme.of(context).textTheme.headline2)),
      SizedBox(height: 0.02 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Aggiorna i tuoi dati.',
              style: Theme.of(context).textTheme.subtitle1)),
      SizedBox(height: 0.05 * size.height),
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
                enabled: false,
                validator: _emailValidator,
                hint: 'La tua email',
                label: 'Email',
                textInputAction: TextInputAction.next,
                inputType: TextInputType.emailAddress,
                icon: Icons.email,
                controller: _emailController),
            /*SizedBox(height: 0.02 * size.height),
            AppTextField(
                validator: _passwordValidator,
                hint: 'Almeno 8 caratteri',
                label: 'Password',
                textInputAction: TextInputAction.done,
                icon: Icons.lock,
                isPassword: true,
                controller: _passwordController),*/
          ])),
      Expanded(child: SizedBox(height: size.height * 0.03)),
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
                user.fullname = _fullnameController.text;
                final response = await KeepUp.instance.updateUser(user);
                if (response.error) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(_updateErrorSnackbar);
                }
                Navigator.of(context).pop();
              }
            },
            child: const Text('Salva'),
            style: TextButton.styleFrom(primary: AppColors.primaryColor),
          ),
        ),
      ]),
      SizedBox(height: 0.05 * size.height),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<KeepUpUser?>(
        future: KeepUp.instance.getUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loadingSkeleton();
          } else if (snapshot.hasError) {
            OopsScreen.show(context);
            return _loadingSkeleton();
          } else {
            return _form(snapshot.data!);
          }
        });
  }
}
