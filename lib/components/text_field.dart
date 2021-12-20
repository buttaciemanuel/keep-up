import 'package:flutter/material.dart';
import 'package:keep_up/constants.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AppTextField extends StatefulWidget {
  final String hint;
  final FormFieldValidator<String>? validator;
  final IconData? icon;
  final bool? isPassword;
  final TextEditingController? controller;
  const AppTextField(
      {Key? key,
      this.icon,
      this.isPassword,
      required this.hint,
      this.validator,
      this.controller})
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
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
        width: size.width,
        decoration: BoxDecoration(
            color: kTextFieldColor, borderRadius: BorderRadius.circular(10)),
        child: TextFormField(
            validator: widget.validator,
            controller: widget.controller,
            obscureText: _obscureText,
            cursorColor: kPrimaryColor,
            decoration: InputDecoration(
                hintText: widget.hint,
                border: InputBorder.none,
                icon: widget.icon != null
                    ? Icon(widget.icon, color: kTextFieldTextColor)
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
                            color: kTextFieldTextColor))
                    : null)));
  }
}

class AppDropDownTextField extends StatefulWidget {
  final List<String> items;
  final String hint;
  final bool? showSearchBox;

  const AppDropDownTextField(
      {Key? key, required this.items, required this.hint, this.showSearchBox})
      : super(key: key);

  @override
  _AppDropDownTextFieldState createState() => _AppDropDownTextFieldState();
}

class _AppDropDownTextFieldState extends State<AppDropDownTextField> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        width: size.width,
        decoration: BoxDecoration(
            color: kTextFieldColor, borderRadius: BorderRadius.circular(10)),
        child: DropdownSearch<String>(
            emptyBuilder: (context, searchEntry) =>
                const Center(child: Text('Nessun risultato trovato')),
            showSelectedItems: false,
            showSearchBox: widget.showSearchBox ?? false,
            mode: Mode.BOTTOM_SHEET,
            searchFieldProps: TextFieldProps(
                cursorColor: kPrimaryColor,
                decoration: InputDecoration(
                    hintText: widget.hint,
                    border: InputBorder.none,
                    filled: true,
                    fillColor: kTextFieldColor,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 5, horizontal: 15))),
            items: widget.items,
            dropdownSearchDecoration: InputDecoration(
              hintText: widget.hint,
              border: InputBorder.none,
            ),
            onChanged: (text) {}));
  }
}
