import 'package:flutter/material.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/screens/oops_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  static const _updateErrorSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Sembra ci sia un errore nel modificare la password'));

  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  String? _oldPasswordValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Inserisci la tua password attuale';
    } else {}
    return null;
  }

  String? _newPasswordValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Scegli la tua nuova password';
    } else if (!RegExp(
            r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$')
        .hasMatch(text)) {
      return 'Scegli una password di almeno 8 caratteri';
    }
    return null;
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  _loadingSkeleton() {
    final size = MediaQuery.of(context).size;
    return AppLayout(children: [
      SizedBox(height: 0.05 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Cambia password',
              style: Theme.of(context).textTheme.headline2)),
      SizedBox(height: 0.02 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Scegli una nuova password.',
              style: Theme.of(context).textTheme.subtitle1)),
      SizedBox(height: 0.05 * size.height),
      Form(
          key: _formKey,
          child: Column(children: [
            SkeletonLoader(
                child: AppTextField(
                    validator: _oldPasswordValidator,
                    hint: 'Almeno 8 caratteri',
                    label: 'Password',
                    textInputAction: TextInputAction.done,
                    icon: Icons.lock,
                    isPassword: true,
                    controller: _oldPasswordController)),
            SizedBox(height: 0.02 * size.height),
            SkeletonLoader(
                child: AppTextField(
                    validator: _newPasswordValidator,
                    hint: 'Almeno 8 caratteri',
                    label: 'Nuova password',
                    textInputAction: TextInputAction.done,
                    icon: Icons.lock,
                    isPassword: true,
                    controller: _newPasswordController)),
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
    return AppLayout(children: [
      SizedBox(height: 0.05 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Cambia password',
              style: Theme.of(context).textTheme.headline2)),
      SizedBox(height: 0.02 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Scegli una nuova password.',
              style: Theme.of(context).textTheme.subtitle1)),
      SizedBox(height: 0.05 * size.height),
      Form(
          key: _formKey,
          child: Column(children: [
            AppTextField(
                validator: _oldPasswordValidator,
                hint: 'Almeno 8 caratteri',
                label: 'Password',
                textInputAction: TextInputAction.done,
                icon: Icons.lock,
                isPassword: true,
                controller: _oldPasswordController),
            SizedBox(height: 0.02 * size.height),
            AppTextField(
                validator: _newPasswordValidator,
                hint: 'Almeno 8 caratteri',
                label: 'Nuova password',
                textInputAction: TextInputAction.done,
                icon: Icons.lock,
                isPassword: true,
                controller: _newPasswordController),
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
                final response = await KeepUp.instance.changePassword(
                    _oldPasswordController.text.trim(),
                    _newPasswordController.text.trim());
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
