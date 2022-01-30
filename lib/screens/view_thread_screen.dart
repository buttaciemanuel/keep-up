import 'package:flutter/material.dart';
import 'package:keep_up/components/skeleton_loader.dart';
import 'package:keep_up/components/thread_card.dart';
import 'package:keep_up/screens/oops_screen.dart';
import 'package:keep_up/screens/reply_thread_screen.dart';
import 'package:keep_up/services/keep_up_api.dart';
import 'package:keep_up/style.dart';

class ViewThreadScreen extends StatefulWidget {
  final KeepUpThread thread;
  const ViewThreadScreen({Key? key, required this.thread}) : super(key: key);

  @override
  _ViewThreadScreenState createState() => _ViewThreadScreenState();
}

class _ViewThreadScreenState extends State<ViewThreadScreen> {
  Future<List<KeepUpThreadMessage>> _fetchThreadMessages() async {
    final messagesResponse =
        await KeepUp.instance.getThreadMessages(threadId: widget.thread.id!);

    if (messagesResponse.error) return Future.error('');

    return messagesResponse.result!;
  }

  _loadingViewThread() {
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
    return AppLayout(
        floatingActionButton: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            width: double.maxFinite,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (context) {
                          return ReplyThreadScreen(thread: widget.thread);
                        }))
                    .then((_) => setState(() {}));
              },
              backgroundColor: AppColors.primaryColor,
              label: Text('Rispondi',
                  style: Theme.of(context)
                      .textTheme
                      .button!
                      .copyWith(color: Colors.white, fontSize: 16)),
              icon: const Icon(Icons.send, size: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            )),
        children: [
          SizedBox(height: 0.05 * size.height),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Align(
                alignment: Alignment.centerLeft,
                child: Text('Visualizza',
                    style: Theme.of(context).textTheme.headline1)),
            IconButton(
                iconSize: 32.0,
                padding: EdgeInsets.zero,
                tooltip: 'Chiudi',
                constraints: const BoxConstraints(),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: AppColors.grey))
          ]),
          SizedBox(height: 0.03 * size.height),
          FutureBuilder<List<KeepUpThreadMessage>>(
            future: _fetchThreadMessages(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                OopsScreen.show(context);
                return _loadingViewThread();
              } else if (!snapshot.hasData) {
                return _loadingViewThread();
              } else {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.vertical,
                  child: Column(children: [
                    AppThreadReplyCard(
                        title: widget.thread.title,
                        sender: snapshot.data!.first.senderName!,
                        creationDate: snapshot.data!.first.creationDate,
                        reply: snapshot.data!.first.body,
                        likes: snapshot.data!.first.likes!,
                        isLiked: snapshot.data!.first.isLiked,
                        onTapLike: () {
                          KeepUp.instance
                              .likeThreadMessage(
                                  messageId: snapshot.data!.first.id!)
                              .then((_) {
                            setState(() {});
                          });
                        }),
                    SizedBox(height: 0.03 * size.height),
                    if (snapshot.data!.length == 1) ...[
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Nessuna risposta',
                              style: Theme.of(context).textTheme.headline3)),
                      SizedBox(height: 0.02 * size.height),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Nessuno si è ancora sbilanciato.',
                              style: Theme.of(context).textTheme.subtitle2))
                    ] else ...[
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Risposte (${snapshot.data!.length - 1})',
                              style: Theme.of(context).textTheme.headline3)),
                      SizedBox(height: 0.03 * size.height),
                      // le risposte sono stampate dalla più recente alla meno recente
                      ...snapshot.data!.reversed
                          .take(snapshot.data!.length - 1)
                          .map((m) {
                        return AppThreadReplyCard(
                            sender: m.senderName!,
                            creationDate: m.creationDate,
                            reply: m.body,
                            likes: m.likes!,
                            isLiked: m.isLiked,
                            onTapLike: () {
                              KeepUp.instance
                                  .likeThreadMessage(messageId: m.id!)
                                  .then((_) {
                                setState(() {});
                              });
                            });
                      }).toList()
                    ]
                  ]),
                );
              }
            },
          ),
          SizedBox(height: 0.1 * size.height),
        ]);
  }
}
