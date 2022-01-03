import 'package:flutter/material.dart';
import 'package:keep_up/style.dart';

class SliderInputField extends StatelessWidget {
  final String label;
  final double min;
  final double max;
  final double value;
  final Function(double)? onChanged;
  const SliderInputField(
      {Key? key,
      required this.label,
      required this.value,
      required this.min,
      required this.max,
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
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(label,
                      style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).hintColor,
                          fontSize: 16))),
              const Expanded(child: SizedBox()),
              Align(
                  alignment: Alignment.centerRight,
                  child: Text('${value.round()}',
                      style: Theme.of(context).textTheme.bodyText1)),
            ])),
        SizedBox(height: 0.01 * size.height),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: max.round() - min.round(),
          label: value.round().toString(),
          onChanged: onChanged,
        ),
      ]),
    );
  }
}
