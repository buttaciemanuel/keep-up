import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/screens/delete_profile_screen.dart';
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

  @override
  void dispose() {
    _fullnameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  _loadingSkeleton() {
    final size = MediaQuery.of(context).size;
    return AppLayout(children: [
      SizedBox(height: 0.05 * size.height),
      Row(children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Text('Modifica profilo',
                style: Theme.of(context).textTheme.headline2)),
        const Expanded(child: SizedBox()),
        IconButton(
            iconSize: 32.0,
            padding: EdgeInsets.zero,
            tooltip: 'Cancella',
            constraints: const BoxConstraints(),
            onPressed: () {},
            icon: const Icon(Icons.delete_forever, color: Colors.red))
      ]),
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
      Row(children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Text('Modifica profilo',
                style: Theme.of(context).textTheme.headline2)),
        const Expanded(child: SizedBox()),
        IconButton(
            iconSize: 32.0,
            padding: EdgeInsets.zero,
            tooltip: 'Cancella',
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (context) {
                        return const DeleteProfileScreen();
                      }))
                  .then((_) => setState(() {}));
            },
            icon: const Icon(Icons.delete_sweep, color: Colors.red))
      ]),
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
                user.fullname = _fullnameController.text.trim();
                final response = await KeepUp.instance.updateUser(user);
                if (response.error) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(_updateErrorSnackbar);
                } else {
                  Navigator.of(context).pop();
                }
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
