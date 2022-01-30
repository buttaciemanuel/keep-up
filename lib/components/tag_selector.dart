import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:keep_up/style.dart';

class AppTagSelectorController {
  Set<String> selectedItems = {};
}

class AppTagSelector extends StatefulWidget {
  final List<String> tags;
  final String? value;
  final Function(String)? onClicked;
  final AppTagSelectorController? controller;
  final int? maxSelectionCount;
  const AppTagSelector(
      {Key? key,
      required this.tags,
      this.value,
      this.onClicked,
      this.controller,
      this.maxSelectionCount})
      : super(key: key);

  @override
  State<AppTagSelector> createState() => _AppTagSelectorState();
}

class _AppTagSelectorState extends State<AppTagSelector> {
  late final List<bool> _selected = widget.tags.map((_) => false).toList();

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          child: Wrap(
              spacing: 10,
              runSpacing: 15,
              children: List.generate(widget.tags.length, (index) {
                return TextButton(
                    style: TextButton.styleFrom(
                        animationDuration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 15),
                        primary: _selected[index]
                            ? AppColors.primaryColor
                            : AppColors.fieldBackgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        backgroundColor: _selected[index]
                            ? AppColors.primaryColor
                            : AppColors.fieldBackgroundColor),
                    onPressed: () {
                      if (_selected[index]) {
                        widget.controller?.selectedItems
                            .remove(widget.tags[index]);
                        setState(() => _selected[index] = false);
                      } else if (widget.maxSelectionCount == null ||
                          _selected.where((e) => e).length <
                              widget.maxSelectionCount!) {
                        widget.controller?.selectedItems
                            .add(widget.tags[index]);
                        setState(() => _selected[index] = true);
                      }

                      if (widget.onClicked != null) {
                        widget.onClicked!(widget.tags[index]);
                      }
                    },
                    child: Text(widget.tags[index],
                        style: TextStyle(
                            color: _selected[index]
                                ? Colors.white
                                : AppColors.fieldTextColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)));
              }).toList()),
        ));
  }
}
