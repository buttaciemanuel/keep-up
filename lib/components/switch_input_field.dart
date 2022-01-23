import 'package:flutter/material.dart';
import 'package:keep_up/style.dart';

class SwitchInputField extends StatelessWidget {
  final String label;
  final String? description;
  final bool value;
  final Function(bool?)? onChanged;
  const SwitchInputField(
      {Key? key,
      required this.label,
      required this.value,
      this.description,
      this.onChanged})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.fieldBackgroundColor),
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: Row(children: [
              SizedBox(
                  width: size.width * 0.6,
                  child: Column(children: [
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text(label,
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).hintColor,
                                fontSize: 16))),
                    if (description != null) ...[
                      SizedBox(height: 5),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text(description!,
                              style: TextStyle(
                                  fontWeight: FontWeight.w400,
                                  color: Theme.of(context).hintColor,
                                  fontSize: 13)))
                    ]
                  ])),
              const Expanded(child: SizedBox(width: 10)),
              SizedBox(
                height: 24.0,
                width: 24.0,
                child: Transform.scale(
                    scale: 1.3,
                    child: Checkbox(
                        fillColor: value
                            ? MaterialStateProperty.all(AppColors.primaryColor)
                            : Theme.of(context).checkboxTheme.fillColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        value: value,
                        onChanged: onChanged)),
              )
            ])),
      ]),
    );
  }
}
