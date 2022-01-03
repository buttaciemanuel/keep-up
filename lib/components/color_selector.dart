import 'package:flutter/material.dart';

class ColorSelector extends StatelessWidget {
  final List<Color> colors;
  final int selectedColorIndex;
  final Function(int) onSelected;
  const ColorSelector(
      {Key? key,
      required this.colors,
      this.selectedColorIndex = 0,
      required this.onSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
            children: List.generate(colors.length, (index) {
          return SizedBox(
              width: size.width / 8.5,
              child: TextButton(
                  style: TextButton.styleFrom(
                      animationDuration: const Duration(milliseconds: 300),
                      primary: colors[index],
                      elevation: selectedColorIndex == index ? 5 : 0,
                      fixedSize: selectedColorIndex == index
                          ? const Size.fromHeight(50)
                          : const Size.fromHeight(40),
                      shape: const CircleBorder(),
                      backgroundColor: colors[index]),
                  onPressed: () => onSelected(index),
                  child: selectedColorIndex == index
                      ? Transform.scale(
                          scale: 1.3,
                          child: const Icon(Icons.check, color: Colors.white))
                      : const Icon(null)));
        })));
  }
}
