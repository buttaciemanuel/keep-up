import 'package:flutter/material.dart';
import 'package:keep_up/components/category_selector.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/text_field.dart';
import 'package:keep_up/components/thread_card.dart';
import 'package:keep_up/screens/begin_thread_screen.dart';
import 'package:keep_up/screens/oops_screen.dart';
import 'package:keep_up/screens/view_thread_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({Key? key}) : super(key: key);

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
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
      SizedBox(height: 0.03 * size.height),
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
                      height: 0.3 * size.height, width: 0.7 * size.width),
                  SizedBox(height: 0.01 * size.height),
                  Text('Nessun thread',
                      style: Theme.of(context).textTheme.headline4),
                  SizedBox(height: 0.01 * size.height),
                  Text('Nulla corrisponde alla ricerca...',
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
