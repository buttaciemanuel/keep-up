import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/screens/begin_thread_screen.dart';
import 'package:keep_up/screens/oops_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _memoizer = AsyncMemoizer();
  final _searchTextController = TextEditingController();
  late List<KeepUpThread> _userThreads;

  @override
  void initState() {
    super.initState();
    _searchTextController.addListener(() {});
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  _fetchUserThreads() => _memoizer.runOnce(() async {
        final response = await KeepUp.instance.getUserThreads(asCreator: true);

        if (response.error) return Future.error('');

        _userThreads = response.result!;
      });

  _loadingUserThreads() {
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
            children: List.generate(3, (_) {
          return const SkeletonLoader(
              child: SizedBox(height: 200, width: 200, child: Card()));
        })));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AppNavigationPageLayout(children: [
      SizedBox(height: 0.05 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child:
              Text('Community', style: Theme.of(context).textTheme.headline1)),
      SizedBox(height: 0.02 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Trova le risposte che cerchi.',
              style: Theme.of(context).textTheme.subtitle1)),
      SizedBox(height: 0.03 * size.height),
      AppSearchTextField(
        onChanged: (value) {
          setState(() {});
        },
        hint: 'Cerca',
        controller: _searchTextController,
      ),
      SizedBox(height: 0.05 * size.height),
      Row(children: [
        Expanded(
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('I tuoi thread',
                    style: Theme.of(context).textTheme.headline3))),
        IconButton(
            iconSize: 32.0,
            padding: EdgeInsets.zero,
            tooltip: 'Aggiungi',
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (context) {
                        return const BeginThreadScreen();
                      }))
                  .then((_) => setState(() {}));
            },
            icon: const Icon(Icons.add, color: AppColors.primaryColor))
      ]),
      SizedBox(height: 0.03 * size.height),
      FutureBuilder(
        future: _fetchUserThreads(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loadingUserThreads();
          } else if (snapshot.hasError) {
            OopsScreen.show(context);
            return _loadingUserThreads();
          } else if (_userThreads.isEmpty) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/question.png',
                      height: 0.2 * size.height, width: 0.7 * size.width),
                  SizedBox(height: 0.01 * size.height),
                  Text('Nessun thread',
                      style: Theme.of(context).textTheme.headline4),
                  SizedBox(height: 0.01 * size.height),
                  Text('Fai qualche domanda ora!',
                      style: Theme.of(context).textTheme.subtitle2)
                ]);
          } else {
            return Text('to be implemented');
          }
        },
      ),
      SizedBox(height: 0.05 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child:
              Text('Popolari', style: Theme.of(context).textTheme.headline3)),
      SizedBox(height: 0.03 * size.height),
    ]);
  }
}
