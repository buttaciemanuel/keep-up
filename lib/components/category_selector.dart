import 'package:flutter/material.dart';
import 'package:keep_up/style.dart';

class AppScrollCategorySelector extends StatelessWidget {
  final List<String> categories;
  final String? value;
  final Function(String) onClicked;
  const AppScrollCategorySelector(
      {Key? key, required this.categories, this.value, required this.onClicked})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
          children: categories.map((category) {
        return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: TextButton(
                style: TextButton.styleFrom(
                    animationDuration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 15),
                    primary: category == value
                        ? AppColors.primaryColor
                        : AppColors.fieldBackgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: category == value
                        ? AppColors.primaryColor
                        : AppColors.fieldBackgroundColor),
                onPressed: () => onClicked(category),
                child: Text(category,
                    style: TextStyle(
                        color: category == value
                            ? Colors.white
                            : AppColors.fieldTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600))));
      }).toList()),
    );
  }
}

class AppCategorySelector extends StatelessWidget {
  final List<String> categories;
  final Set<String>? disabledCategories;
  final String? value;
  final Function(String) onClicked;
  const AppCategorySelector(
      {Key? key,
      required this.categories,
      this.value,
      required this.onClicked,
      this.disabledCategories})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
          children: categories.map((category) {
        return Expanded(
            child: Container(
                margin: EdgeInsets.only(
                    left: categories.indexOf(category) > 0 ? 5 : 0,
                    right: categories.indexOf(category) < categories.length - 1
                        ? 5
                        : 0),
                child: TextButton(
                    style: TextButton.styleFrom(
                        animationDuration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 15),
                        primary: category == value
                            ? AppColors.primaryColor
                            : AppColors.fieldBackgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: category == value
                            ? AppColors.primaryColor
                            : AppColors.fieldBackgroundColor),
                    onPressed: () => onClicked(category),
                    child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(category,
                            style: TextStyle(
                                color: disabledCategories != null &&
                                        disabledCategories!.contains(category)
                                    ? AppColors.fieldTextColor.withOpacity(.2)
                                    : category == value
                                        ? Colors.white
                                        : AppColors.fieldTextColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600))))));
      }).toList()),
    );
  }
}
