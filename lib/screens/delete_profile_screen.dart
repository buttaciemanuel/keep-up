import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/screens/login_screen.dart';
import 'package:keep_up/screens/oops_screen.dart';
import 'package:keep_up/screens/profile_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class DeleteProfileScreen extends StatefulWidget {
  const DeleteProfileScreen({Key? key}) : super(key: key);

  @override
  _DeleteProfileScreenState createState() => _DeleteProfileScreenState();
}

class _DeleteProfileScreenState extends State<DeleteProfileScreen> {
  static const _deleteErrorSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Sembra ci sia un errore nell\'eliminare il profilo'));

  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String? _reasonValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Aiutaci con una spiegazione valida';
    }
    return null;
  }

  _form() {
    final size = MediaQuery.of(context).size;
    return AppLayout(children: [
      SizedBox(height: 0.05 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Elimina profilo',
              style: Theme.of(context).textTheme.headline2)),
      SizedBox(height: 0.02 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Attenzione! Muoviti con cautela.',
              style: Theme.of(context).textTheme.subtitle1)),
      SizedBox(height: 0.05 * size.height),
      Form(
          key: _formKey,
          child: Column(children: [
            AppTextField(
                isTextArea: true,
                validator: _reasonValidator,
                hint: 'Aiutaci a capire cosa non ha funzionato',
                label: 'Ragione dell\'eliminazione',
                textInputAction: TextInputAction.next,
                inputType: TextInputType.name,
                controller: _reasonController),
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
                AppBottomDialog.showBottomDialog(
                    context: context,
                    title: 'Elimina il profilo',
                    body: 'Sei sicuro di eliminare il profilo per sempre?',
                    confirmText: 'Si',
                    confirmColor: Colors.red,
                    confirmPressed: () async {
                      final response = await KeepUp.instance
                          .deleteUser(reason: _reasonController.text);
                      Navigator.of(context, rootNavigator: true).pop();
                      if (response.error) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(_deleteErrorSnackbar);
                      } else {
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (c) => const LoginScreen()),
                            (route) => false);
                      }
                    },
                    cancelText: 'Annulla');
              }
            },
            child: const Text('Elimina'),
            style: TextButton.styleFrom(primary: Colors.red),
          ),
        ),
      ]),
      SizedBox(height: 0.05 * size.height),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return _form();
  }
}
