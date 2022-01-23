import 'package:flutter/material.dart';
import 'package:keep_up/style.dart';

class AppTimeTextField extends StatelessWidget {
  final String? initialText;
  final String? hint;
  final double? width;
  final Function()? onTap;
  final TextEditingController? controller;
  const AppTimeTextField(
      {Key? key,
      this.hint,
      this.onTap,
      this.controller,
      this.initialText,
      this.width})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SizedBox(
        width: width ?? size.width,
        child: TextFormField(
            initialValue: initialText,
            controller: controller,
            onTap: onTap,
            textAlign: TextAlign.start,
            readOnly: true,
            style: Theme.of(context).textTheme.bodyText1,
            decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
                filled: true,
                fillColor: AppColors.fieldBackgroundColor,
                hintText: hint,
                labelText: controller != null && controller!.text.isEmpty
                    ? null
                    : hint,
                floatingLabelStyle:
                    const TextStyle(color: AppColors.primaryColor),
                border: UnderlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon:
                    Icon(Icons.timer, color: Theme.of(context).hintColor))));
  }
}
