import 'package:flutter/material.dart';

Widget textMessage(int index, String sender, String text) {
  if (text == null) return Container();

  return Container(
    alignment: sender == 'bot' ? Alignment.centerLeft : Alignment.centerRight,
    child: Container(
      padding: const EdgeInsets.all(20.0),
      margin:
          const EdgeInsets.only(top: 10, bottom: 10.0, left: 20.0, right: 20.0),
      decoration: BoxDecoration(
        color: sender == 'bot' ? Colors.grey[600] : Colors.grey[200],
        border: null,
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: sender == 'bot' ? Colors.white : Colors.grey[900],
            fontSize: 15.0),
      ),
    ),
  );
}

Widget quickRepliesMessage(int index, quickReplies, String text) {

  List<Widget> quickReplyWidgets = List<Widget>();
  // build quick replies
  for (var qr in quickReplies) {
    quickReplyWidgets.add(
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: OutlineButton(
          
          shape: new RoundedRectangleBorder(borderRadius: new BorderRadius.circular(30.0)),
          padding: EdgeInsets.all(10.0),
          child: Text(qr['title']),
          onPressed: () {},
        ),
      )
    );
  }

  return Container(
    alignment: Alignment.centerLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(20.0),
          margin: const EdgeInsets.only(
              top: 10, bottom: 10.0, left: 20.0, right: 20.0),
          decoration: BoxDecoration(
            color: Colors.grey[600],
            border: null,
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: Text(
            text,
            style: TextStyle(color: Colors.white, fontSize: 15.0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Wrap(children: quickReplyWidgets),
        )
      ],
    ),
  );
}
