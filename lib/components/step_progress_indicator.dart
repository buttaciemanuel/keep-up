import 'package:flutter/material.dart';
import 'package:keep_up/style.dart';

class StepProgressIndicator extends StatelessWidget {
  final int stepsCount;
  final int selectedStepsCount;
  final Color? selectedStepColor;
  final Color? unselectedStepColor;
  final double? stepHeight;
  const StepProgressIndicator(
      {Key? key,
      required this.stepsCount,
      required this.selectedStepsCount,
      this.selectedStepColor = AppColors.primaryColor,
      this.unselectedStepColor = AppColors.notSelectedColor,
      this.stepHeight = 12})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: stepHeight,
      child: Row(
          children: List.generate(stepsCount, (index) {
        return Expanded(
            child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
              color: index < selectedStepsCount
                  ? selectedStepColor
                  : unselectedStepColor,
              borderRadius: BorderRadius.circular(10)),
        ));
      })),
    );
  }
}
