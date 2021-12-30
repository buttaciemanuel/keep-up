import 'package:flutter/material.dart';
import 'package:keep_up/style.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AppTextField extends StatefulWidget {
  final String? hint;
  final String? label;
  final String? helper;
  final FormFieldValidator<String>? validator;
  final IconData? icon;
  final bool? isPassword;
  final TextEditingController? controller;
  final TextInputType? inputType;
  final bool? isTextArea;
  const AppTextField(
      {Key? key,
      this.icon,
      this.isPassword,
      this.hint,
      this.label,
      this.helper,
      this.validator,
      this.controller,
      this.inputType,
      this.isTextArea})
      : super(key: key);

  @override
  _AppTextFieldState createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = false;

  @override
  void initState() {
    _obscureText = widget.isPassword ?? false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SizedBox(
        width: size.width,
        child: TextFormField(
            maxLines: (widget.isTextArea ?? false) ? 4 : 1,
            minLines: (widget.isTextArea ?? false) ? 4 : 1,
            keyboardType: widget.inputType ??
                ((widget.isTextArea ?? false)
                    ? TextInputType.multiline
                    : TextInputType.text),
            style: Theme.of(context).textTheme.bodyText1,
            validator: widget.validator,
            controller: widget.controller,
            obscureText: _obscureText,
            cursorColor: AppColors.primaryColor,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
                filled: true,
                fillColor: AppColors.fieldBackgroundColor,
                helperText: widget.helper,
                labelText: widget.label,
                alignLabelWithHint: (widget.isTextArea ?? false),
                floatingLabelStyle:
                    const TextStyle(color: AppColors.primaryColor),
                hintText: widget.hint,
                border: UnderlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon: widget.icon != null
                    ? Icon(widget.icon, color: AppColors.fieldTextColor)
                    : null,
                suffixIcon: widget.isPassword ?? false
                    ? IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                        icon: Icon(
                            _obscureText
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: AppColors.fieldTextColor))
                    : null)));
  }
}

class AppDropDownTextField extends StatefulWidget {
  final List<String> items;
  final String hint;
  final String? label;
  final Function(String?)? onChanged;
  final bool? showSearchBox;

  const AppDropDownTextField(
      {Key? key,
      required this.items,
      required this.hint,
      this.label,
      this.showSearchBox,
      this.onChanged})
      : super(key: key);

  @override
  _AppDropDownTextFieldState createState() => _AppDropDownTextFieldState();
}

class _AppDropDownTextFieldState extends State<AppDropDownTextField> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final hintStyle = TextStyle(
        color: Theme.of(context).hintColor,
        fontSize: Theme.of(context).textTheme.bodyText1?.fontSize);
    final itemStyle = TextStyle(
        fontSize: Theme.of(context).textTheme.bodyText1?.fontSize,
        fontWeight: Theme.of(context).textTheme.subtitle1?.fontWeight);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        width: size.width,
        decoration: BoxDecoration(
            color: AppColors.fieldBackgroundColor,
            borderRadius: BorderRadius.circular(10)),
        child: DropdownSearch<String>(
            popupItemBuilder: (context, item, isSelected) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                child: Text(item, style: itemStyle),
              );
            },
            dropdownSearchBaseStyle: Theme.of(context).textTheme.bodyText1,
            dropdownBuilder: (context, selectedItem) {
              if (selectedItem == null) {
                return Text(widget.hint, style: hintStyle);
              }
              return Text(selectedItem,
                  style: Theme.of(context).textTheme.bodyText1);
            },
            emptyBuilder: (context, searchEntry) =>
                const Center(child: Text('Nessun risultato trovato')),
            showSelectedItems: false,
            showSearchBox: widget.showSearchBox ?? false,
            mode: Mode.BOTTOM_SHEET,
            onChanged: widget.onChanged,
            searchFieldProps: TextFieldProps(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                style: Theme.of(context).textTheme.bodyText1,
                cursorColor: AppColors.primaryColor,
                decoration: InputDecoration(
                    floatingLabelStyle:
                        const TextStyle(color: AppColors.primaryColor),
                    labelText: widget.label,
                    hintText: widget.hint,
                    border: InputBorder.none,
                    filled: true,
                    fillColor: AppColors.fieldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 5, horizontal: 15))),
            items: widget.items,
            dropdownSearchDecoration: InputDecoration(
              hintText: widget.hint,
              border: InputBorder.none,
            )));
  }
}
