import 'package:flutter/material.dart';
import 'package:keep_up/components/elevated_card.dart';
import 'package:keep_up/style.dart';

class AppThreadCard extends StatelessWidget {
  final String author;
  final String title;
  final String question;
  final DateTime creationDate;
  final int viewsCount;
  final int messagesCount;
  final int partecipantsCount;
  final bool? wrap;
  final Function()? onTap;

  const AppThreadCard(
      {Key? key,
      required this.author,
      required this.creationDate,
      required this.title,
      required this.question,
      required this.viewsCount,
      required this.messagesCount,
      required this.partecipantsCount,
      this.wrap = true,
      this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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

    return AppElevatedCard(
      onTap: onTap,
      children: [
        Align(
            alignment: Alignment.centerLeft,
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: titleStyle)),
        const Divider(
            height: 30,
            color: Colors.black,
            thickness: 0.1,
            indent: 0,
            endIndent: 0),
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          const Icon(Icons.person, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 5),
          Text(author,
              style: subtitleStyle.copyWith(color: AppColors.primaryColor)),
          const SizedBox(width: 20),
          Icon(Icons.access_time, color: withOpacity, size: 20),
          const SizedBox(width: 5),
          Text(elapsedTimeString, style: subtitleStyle)
        ]),
        const SizedBox(height: 15),
        if (wrap!) ...[
          Align(
              alignment: Alignment.centerLeft,
              child: Text(question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: textStyle)),
          const SizedBox(height: 15)
        ] else ...[
          Text(question, style: textStyle),
          const SizedBox(height: 15)
        ],
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Icon(Icons.visibility, color: withOpacity, size: 20),
            const SizedBox(width: 5),
            Text('$viewsCount ${viewsCount == 1 ? 'visita' : 'visite'}',
                style: subtitleStyle)
          ]),
          Row(children: [
            Icon(Icons.question_answer, color: withOpacity, size: 20),
            const SizedBox(width: 5),
            Text(
                '${messagesCount - 1} ${messagesCount == 2 ? 'riposta' : 'risposte'}',
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
    );
  }
}

class AppThreadReplyCard extends StatelessWidget {
  final String sender;
  final String? title;
  final String reply;
  final DateTime creationDate;
  final int likes;
  final bool? isLiked;
  final Function()? onTap;
  final Function()? onTapLike;

  const AppThreadReplyCard(
      {Key? key,
      this.title,
      required this.sender,
      required this.creationDate,
      required this.reply,
      required this.likes,
      this.isLiked = false,
      this.onTap,
      this.onTapLike})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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

    return AppElevatedCard(
      onTap: onTap,
      children: [
        if (title != null) ...[
          Align(
              alignment: Alignment.centerLeft,
              child: Text(title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: titleStyle)),
          const Divider(
              height: 30,
              color: Colors.black,
              thickness: 0.1,
              indent: 0,
              endIndent: 0),
        ],
        Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          const Icon(Icons.person, color: AppColors.primaryColor, size: 20),
          const SizedBox(width: 5),
          Text(sender,
              style: subtitleStyle.copyWith(color: AppColors.primaryColor)),
          const SizedBox(width: 20),
          Icon(Icons.access_time, color: withOpacity, size: 20),
          const SizedBox(width: 5),
          Text(elapsedTimeString, style: subtitleStyle)
        ]),
        const SizedBox(height: 15),
        Align(
            alignment: Alignment.centerLeft,
            child: Text(reply, style: textStyle)),
        const SizedBox(height: 15),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            GestureDetector(
                child: Icon(Icons.thumb_up,
                    color: isLiked! ? Colors.green : withOpacity, size: 20),
                onTap: onTapLike),
            const SizedBox(width: 5),
            Text('$likes ${likes == 1 ? 'punto' : 'punti'}',
                style: subtitleStyle)
          ])
        ]),
      ],
    );
  }
}
