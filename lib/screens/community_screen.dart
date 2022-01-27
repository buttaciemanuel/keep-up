import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:keep_up/components/category_selector.dart';
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
  var _selectedTag = KeepUpThreadTags.values.first;

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

  static Future<List<KeepUpThread>> _fetchSearchTagThreads(
      {required String tag, required String filter}) async {
    final response =
        await KeepUp.instance.getThreadsByTags(tags: [tag], filter: filter);

    if (response.error) throw Future.error('');

    return response.result!;
  }

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
    return AppNavigationPageLayout(children: [
      SizedBox(height: 0.05 * size.height),
      Row(children: [
        Expanded(
            child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Community',
                    style: Theme.of(context).textTheme.headline1))),
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
      Align(
          alignment: Alignment.centerLeft,
          child:
              Text('Popolari', style: Theme.of(context).textTheme.headline3)),
      SizedBox(height: 0.03 * size.height),
      AppScrollCategorySelector(
          value: _selectedTag,
          categories: KeepUpThreadTags.values,
          onClicked: (tag) {
            setState(() => _selectedTag = tag);
          }),
      SizedBox(height: 0.03 * size.height),
      FutureBuilder<List<KeepUpThread>>(
        future: _fetchSearchTagThreads(
            tag: _selectedTag, filter: _searchTextController.text),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            OopsScreen.show(context);
            return _loadingUserThreads();
          } else if (!snapshot.hasData) {
            return _loadingUserThreads();
          } else if (snapshot.data!.isEmpty) {
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
                  Text('Ricerca a vuoto...',
                      style: Theme.of(context).textTheme.subtitle2)
                ]);
          } else {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.vertical,
              child: Column(
                children: snapshot.data!.map((t) {
                  return AppThreadCard(
                      author: t.authorName!,
                      creationDate: t.creationDate,
                      title: t.title,
                      viewsCount: t.viewsCount,
                      messagesCount: t.messagesCount!,
                      partecipantsCount: t.partecipantsCount!,
                      question: t.question!.body);
                }).toList(),
              ),
            );
          }
        },
      ),
    ]);
  }
}

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
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.vertical,
              child: Column(
                children: _userThreads.map((t) {
                  return AppThreadCard(
                      author: t.authorName!,
                      creationDate: t.creationDate,
                      title: t.title,
                      viewsCount: t.viewsCount,
                      messagesCount: t.messagesCount!,
                      partecipantsCount: t.partecipantsCount!,
                      question: t.question!.body);
                }).toList(),
              ),
            );
          }
        },
      ),
    ]);
  }
}

class AppThreadCard extends StatelessWidget {
  final String author;
  final String title;
  final String question;
  final DateTime creationDate;
  final int viewsCount;
  final int messagesCount;
  final int partecipantsCount;

  const AppThreadCard(
      {Key? key,
      required this.author,
      required this.creationDate,
      required this.title,
      required this.question,
      required this.viewsCount,
      required this.messagesCount,
      required this.partecipantsCount})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final titleStyle = TextStyle(
        fontSize: Theme.of(context).textTheme.subtitle1?.fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.black);
    final textStyle = TextStyle(
        fontSize: Theme.of(context).textTheme.bodyText2?.fontSize,
        fontWeight: FontWeight.w600,
        color: AppColors.fieldTextColor);
    final withOpacity = AppColors.fieldTextColor.withOpacity(0.3);
    final subtitleStyle = TextStyle(
        fontSize: Theme.of(context).textTheme.bodyText2?.fontSize,
        fontWeight: FontWeight.normal,
        color: withOpacity);
    final elapsedTime = DateTime.now().difference(creationDate);
    late String elapsedTimeString;

    if (elapsedTime.inDays >= 365) {
      elapsedTimeString = '${elapsedTime.inDays ~/ 365} anni fa';
    } else if (elapsedTime.inDays >= 30) {
      elapsedTimeString = '${elapsedTime.inDays ~/ 30} mesi fa';
    } else if (elapsedTime.inDays >= 7) {
      elapsedTimeString = '${elapsedTime.inDays ~/ 7} settimane fa';
    } else if (elapsedTime.inHours >= 24) {
      elapsedTimeString = '${elapsedTime.inHours ~/ 24} giorni fa';
    } else if (elapsedTime.inMinutes >= 60) {
      elapsedTimeString = '${elapsedTime.inMinutes ~/ 60} ore fa';
    } else if (elapsedTime.inSeconds >= 60) {
      elapsedTimeString = '${elapsedTime.inSeconds ~/ 60} minuti fa';
    } else {
      elapsedTimeString = '${elapsedTime.inSeconds} secondi fa';
    }

    return Center(
        child: Card(
            color: AppColors.fieldBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: titleStyle)),
                  const SizedBox(height: 15),
                  Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                    Icon(Icons.person, color: withOpacity, size: 20),
                    const SizedBox(width: 5),
                    Text(author, style: subtitleStyle),
                    const SizedBox(width: 20),
                    Icon(Icons.access_time, color: withOpacity, size: 20),
                    const SizedBox(width: 5),
                    Text(elapsedTimeString, style: subtitleStyle)
                  ]),
                  const SizedBox(height: 15),
                  Text(question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: textStyle),
                  const SizedBox(height: 15),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Icon(Icons.visibility, color: withOpacity, size: 20),
                          const SizedBox(width: 5),
                          Text('$viewsCount views', style: subtitleStyle)
                        ]),
                        Row(children: [
                          Icon(Icons.question_answer,
                              color: withOpacity, size: 20),
                          const SizedBox(width: 5),
                          Text('${messagesCount - 1} risposte',
                              style: subtitleStyle)
                        ]),
                        Row(children: [
                          Icon(Icons.people, color: withOpacity, size: 20),
                          const SizedBox(width: 5),
                          Text(
                              '$partecipantsCount ${partecipantsCount == 1 ? 'persona' : 'persone'}',
                              style: subtitleStyle)
                        ])
                      ]),
                ],
              ),
            )));
  }
}
