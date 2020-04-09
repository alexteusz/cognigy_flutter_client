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


Widget quickRepliesMessage(int index, List quickReplies, String text) {

  print(text);
  print(quickReplies);

  return Container(
    alignment: Alignment.centerLeft,
    child: Container(
      padding: const EdgeInsets.all(20.0),
      margin:
          const EdgeInsets.only(top: 10, bottom: 10.0, left: 20.0, right: 20.0),
      decoration: BoxDecoration(
        color: Colors.grey[600],
        border: null,
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: Colors.white,
            fontSize: 15.0),
      ),
    ),
  );
}
