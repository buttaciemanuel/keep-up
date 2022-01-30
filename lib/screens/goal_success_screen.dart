import 'package:flutter/material.dart';
import 'package:keep_up/components/navigator.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class GoalSuccessScreen extends StatelessWidget {
  static const _updateErrorSnackbar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text('Sembra ci sia un errore ad aggiornare l\'obiettivo'));

  final String goalMetadataId;

  const GoalSuccessScreen({Key? key, required this.goalMetadataId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return AppLayout(children: [
      SizedBox(height: 0.05 * size.height),
      Align(
          alignment: Alignment.centerRight,
          child: IconButton(
              iconSize: 32.0,
              padding: EdgeInsets.zero,
              tooltip: 'Chiudi',
              constraints: const BoxConstraints(),
              onPressed: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => const AppNavigator(
                        initialPage: AppNavigator.goalsPage)));
              },
              icon: const Icon(Icons.close, color: AppColors.grey))),
      const Expanded(child: SizedBox()),
      Image.asset('assets/images/success.png',
          height: 0.4 * size.height, width: 0.7 * size.width),
      Text('Alla grande!', style: Theme.of(context).textTheme.headline3),
      SizedBox(height: 0.02 * size.height),
      Text('Hai raggiunto il tuo obiettivo.',
          style: Theme.of(context).textTheme.subtitle2),
      SizedBox(height: 0.05 * size.height),
      const Expanded(child: SizedBox()),
      Container(
        width: double.maxFinite,
        decoration: const BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        child: TextButton(
          onPressed: () async {
            final response = await KeepUp.instance.setGoalCompletion(
                goalMetadataId: goalMetadataId,
                date: DateTime.now().getDateOnly());

            if (response.error) {
              ScaffoldMessenger.of(context).showSnackBar(_updateErrorSnackbar);
            } else {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (context) =>
                      const AppNavigator(initialPage: AppNavigator.goalsPage)));
            }
          },
          child: Center(
            child: Text(
              'Fatto',
              style: Theme.of(context).textTheme.button!.copyWith(
                  color: Colors.white,
                  fontSize: Theme.of(context).textTheme.bodyText1?.fontSize),
            ),
          ),
        ),
      ),
      SizedBox(height: 0.05 * size.height)
    ]);
  }
}
