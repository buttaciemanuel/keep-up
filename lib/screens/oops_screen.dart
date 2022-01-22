import 'package:flutter/material.dart';
import 'package:keep_up/style.dart';

class OopsScreen extends StatelessWidget {
  final String? actionText;
  final Function()? action;
  static var _screenCount = 0;

  const OopsScreen({Key? key, this.actionText, this.action}) : super(key: key);

  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return AppLayout(children: [
      const Expanded(child: SizedBox()),
      Image.asset('assets/images/no_data.png',
          height: 0.4 * size.height, width: 0.7 * size.width),
      Text('Oops...', style: Theme.of(context).textTheme.headline3),
      SizedBox(height: 0.02 * size.height),
      Text('Sembra che si sia verificato qualche errore.',
          style: Theme.of(context).textTheme.subtitle2),
      SizedBox(height: 0.05 * size.height),
      const Expanded(child: SizedBox()),
      if (actionText != null && action != null) ...[
        Container(
          width: double.maxFinite,
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
          child: TextButton(
            onPressed: action,
            child: Center(
              child: Text(
                actionText!,
                style: Theme.of(context).textTheme.button!.copyWith(
                    color: Colors.white,
                    fontSize: Theme.of(context).textTheme.bodyText1?.fontSize),
              ),
            ),
          ),
        ),
        SizedBox(height: 0.05 * size.height)
      ]
    ]);
  }

  static Future<void> show(BuildContext context) {
    if (_screenCount > 0) return Future.value();

    ++_screenCount;

    return Future.microtask(() => Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) {
          return OopsScreen(
              actionText: 'Riprova',
              action: () {
                Navigator.of(context).pop();
                --_screenCount;
              });
        })));
  }
}
