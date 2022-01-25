import 'package:flutter/material.dart';
import 'package:keep_up/components/switch_input_field.dart';
import 'package:keep_up/components/tag_selector.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class BeginThreadScreen extends StatefulWidget {
  final KeepUpGoal? fromGoal;
  const BeginThreadScreen({Key? key, this.fromGoal}) : super(key: key);

  @override
  _BeginThreadScreenState createState() => _BeginThreadScreenState();
}

class _BeginThreadScreenState extends State<BeginThreadScreen> {
  static const _threadCreationSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Sembra ci sia un errore nell\'avviare il thread'));
  static const _formErrorSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Scegli almeno un tag per il tuo thread'));

  final _formKey = GlobalKey<FormState>();
  final _threadTitleController = TextEditingController();
  final _threadBodyController = TextEditingController();
  final _tagsController = AppTagSelectorController();
  bool _anonymousSelected = false;

  String? _threadTitleValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Inserisci il titolo del thread';
    }
    return null;
  }

  String? _threadBodyValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Inserisci la domanda iniziale del thread';
    }
    return null;
  }

  @override
  void dispose() {
    _threadTitleController.dispose();
    _threadBodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AppLayout(
      children: [
        SizedBox(height: 0.05 * size.height),
        Align(
            alignment: Alignment.centerLeft,
            child: Text('Avvia un thread',
                style: Theme.of(context).textTheme.headline2)),
        SizedBox(height: 0.02 * size.height),
        Align(
            alignment: Alignment.centerLeft,
            child: Text('Esponi il tuo dubbio.',
                style: Theme.of(context).textTheme.subtitle1)),
        SizedBox(height: 0.03 * size.height),
        Form(
            key: _formKey,
            child: Column(children: [
              SizedBox(height: 0.02 * size.height),
              AppTextField(
                  validator: _threadTitleValidator,
                  hint: 'Il titolo del thread',
                  label: 'Titolo',
                  inputType: TextInputType.name,
                  controller: _threadTitleController),
              SizedBox(height: 0.02 * size.height),
              AppTextField(
                  validator: _threadBodyValidator,
                  controller: _threadBodyController,
                  isTextArea: true,
                  label: 'Domanda',
                  hint: 'L\'esposizione dettagliata del tuo problema'),
              SizedBox(height: 0.02 * size.height),
              SwitchInputField(
                  label: 'Anonimo',
                  value: _anonymousSelected,
                  onChanged: (value) => setState(() {
                        _anonymousSelected = value!;
                      })),
              SizedBox(height: 0.02 * size.height),
              AppTagSelector(
                tags: KeepUpTags.values,
                controller: _tagsController,
                maxSelectionCount: 3,
              ),
              SizedBox(height: 0.02 * size.height),
            ])),
        Expanded(child: SizedBox(height: 0.03 * size.height)),
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
                  if (_tagsController.selectedItems.isEmpty) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(_formErrorSnackbar);
                    return;
                  }

                  final response = await KeepUp.instance.beginThread(
                      title: _threadTitleController.text.trim(),
                      body: _threadBodyController.text.trim(),
                      tags: _tagsController.selectedItems.toList(),
                      anonymous: _anonymousSelected);

                  if (response.error) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(_threadCreationSnackbar);
                  } else {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Avvia'),
              style: TextButton.styleFrom(primary: AppColors.primaryColor),
            ),
          ),
        ]),
        SizedBox(height: 0.05 * size.height)
      ],
    );
  }
}
