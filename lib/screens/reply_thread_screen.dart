import 'package:flutter/material.dart';
import 'package:keep_up/components/switch_input_field.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class ReplyThreadScreen extends StatefulWidget {
  final KeepUpThread thread;
  const ReplyThreadScreen({Key? key, required this.thread}) : super(key: key);

  @override
  _ReplyThreadScreenState createState() => _ReplyThreadScreenState();
}

class _ReplyThreadScreenState extends State<ReplyThreadScreen> {
  static const _threadReplySnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Sembra ci sia un errore nel rispondere'));
  static const _formErrorSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Scegli almeno un tag per il tuo thread'));

  final _formKey = GlobalKey<FormState>();
  final _replyController = TextEditingController();
  bool _anonymousSelected = false;

  String? _replyValidator(String? text) {
    if (text == null || text.isEmpty) {
      return 'Inserisci la risposta';
    }
    return null;
  }

  @override
  void dispose() {
    _replyController.dispose();
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
            child:
                Text('Rispondi', style: Theme.of(context).textTheme.headline2)),
        SizedBox(height: 0.02 * size.height),
        Align(
            alignment: Alignment.centerLeft,
            child: Text('Dai la tua opinione.',
                style: Theme.of(context).textTheme.subtitle1)),
        SizedBox(height: 0.03 * size.height),
        Form(
            key: _formKey,
            child: Column(children: [
              SizedBox(height: 0.02 * size.height),
              AppTextField(
                  validator: _replyValidator,
                  controller: _replyController,
                  isTextArea: true,
                  label: 'Risposta',
                  hint: 'L\'esposizione dettagliata della tua risposta'),
              SizedBox(height: 0.02 * size.height),
              SwitchInputField(
                  label: 'Anonimo',
                  value: _anonymousSelected,
                  onChanged: (value) => setState(() {
                        _anonymousSelected = value!;
                      })),
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
                  final response = await KeepUp.instance.pulishThreadMessage(
                      threadId: widget.thread.id!,
                      body: _replyController.text.trim(),
                      anonymous: _anonymousSelected);

                  if (response.error) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(_threadReplySnackbar);
                  } else {
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('Rispondi'),
              style: TextButton.styleFrom(primary: AppColors.primaryColor),
            ),
          ),
        ]),
        SizedBox(height: 0.05 * size.height)
      ],
    );
  }
}
