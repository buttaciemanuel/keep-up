import 'package:flutter/material.dart';
import 'package:async/async.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/thread_card.dart';
import 'package:keep_up/screens/oops_screen.dart';
import 'package:keep_up/screens/view_thread_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class UserThreadsScreen extends StatefulWidget {
  const UserThreadsScreen({Key? key}) : super(key: key);

  @override
  _UserThreadsScreenState createState() => _UserThreadsScreenState();
}

class _UserThreadsScreenState extends State<UserThreadsScreen> {
  final _memoizer = AsyncMemoizer();
  late List<KeepUpThread> _userThreads;

  _fetchUserThreads() => _memoizer.runOnce(() async {
        final response = await KeepUp.instance.getUserThreads(asCreator: true);

        if (response.error) return Future.error('');

        _userThreads = response.result!;

        return true;
      });

  _loadingUserThreads() {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
            children: List.generate(3, (_) {
          return SkeletonLoader(
              child: AppThreadCard(
                  author: '',
                  creationDate: DateTime.now(),
                  title: '',
                  question: '',
                  viewsCount: 0,
                  messagesCount: 0,
                  partecipantsCount: 0));
        })));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AppLayout(children: [
      SizedBox(height: 0.05 * size.height),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Text('I tuoi thread',
                style: Theme.of(context).textTheme.headline1)),
        IconButton(
            iconSize: 32.0,
            padding: EdgeInsets.zero,
            tooltip: 'Chiudi',
            constraints: const BoxConstraints(),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.grey))
      ]),
      SizedBox(height: 0.02 * size.height),
      Align(
          alignment: Alignment.centerLeft,
          child: Text('Dai uno sguardo alle tue domande.',
              style: Theme.of(context).textTheme.subtitle1)),
      SizedBox(height: 0.03 * size.height),
      FutureBuilder(
        future: _fetchUserThreads(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _loadingUserThreads();
          } else if (snapshot.hasError) {
            OopsScreen.show(context);
            return _loadingUserThreads();
          } else if (!snapshot.hasData) {
            return _loadingUserThreads();
          } else if (_userThreads.isEmpty) {
            return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 0.05 * size.height),
                  Image.asset('assets/images/question.png',
                      height: 0.3 * size.height, width: 0.7 * size.width),
                  SizedBox(height: 0.01 * size.height),
                  Text('Nessun thread',
                      style: Theme.of(context).textTheme.headline4),
                  SizedBox(height: 0.01 * size.height),
                  Text('Fai qualche domanda ora!',
                      style: Theme.of(context).textTheme.subtitle2)
                ]);
          } else {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.vertical,
              child: Column(
                children: _userThreads.map((t) {
                  return AppThreadCard(
                      author: t.authorName!,
                      creationDate: t.creationDate,
                      title: t.title,
                      viewsCount: t.viewsCount!,
                      messagesCount: t.messagesCount!,
                      partecipantsCount: t.partecipantsCount!,
                      question: t.question!.body,
                      onTap: () {
                        Navigator.of(context)
                            .push(MaterialPageRoute(
                                fullscreenDialog: true,
                                builder: (context) {
                                  return ViewThreadScreen(thread: t);
                                }))
                            .then((_) => setState(() {}));
                      });
                }).toList(),
              ),
            );
          }
        },
      ),
    ]);
  }
}
