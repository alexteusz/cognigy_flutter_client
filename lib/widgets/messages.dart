import 'package:cognigy_flutter_client/cognigy/socket_service.dart';
import 'package:cognigy_flutter_client/models/message_model.dart';
import 'package:cognigy_flutter_client/providers/message_provider.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// method to open a url
_launchUrl(String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

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

Widget quickRepliesMessage(int index, quickReplies, String text,
    SocketService socketService, MessageProvider messageProvider) {
  List<Widget> quickReplyWidgets = List<Widget>();
  // build quick replies
  for (var qr in quickReplies) {
    quickReplyWidgets.add(Padding(
      padding: const EdgeInsets.all(8.0),
      child: OutlineButton(
        shape: new RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(30.0)),
        padding: EdgeInsets.all(10.0),
        child: Text(qr['title']),
        onPressed: () {
          socketService.sendMessage(qr['payload']);
          messageProvider.addMessage(
              new Message('text', qr['title'], null), 'user');

          //Scrolldown the list to show the latest message
          messageProvider.getScrollController.animateTo(
            messageProvider.getScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 600),
            curve: Curves.ease,
          );
        },
      ),
    ));
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

Widget imageMessage(int index, String url) {
  return Container(
    alignment: Alignment.centerLeft,
    child: Container(
        margin: const EdgeInsets.only(
            top: 10, bottom: 10.0, left: 20.0, right: 50.0),
        child: ClipRRect(
          child: Image.network(url),
          borderRadius: BorderRadius.circular(10.0),
        )),
  );
}

Widget galleryMessage(int index, List elements, SocketService socketService,
    MessageProvider messageProvider) {
  List<Widget> galleryButtons = List<Widget>();
  // build gallery buttons
  for (var e in elements) {
    for (var b in e['buttons'])
      galleryButtons.add(FlatButton(
        child: Text(
          b['title'].toUpperCase(),
          style: TextStyle(color: Colors.black),
        ),
        onPressed: () {
          switch (b['type']) {
            case 'postback':
              messageProvider.socketService.sendMessage(b['payload']);
              messageProvider.addMessage(
                  new Message('text', b['title'], null), 'user');
              break;
            case 'web_url':
              _launchUrl(b['url']);
          }

          //Scrolldown the list to show the latest message
          messageProvider.getScrollController.animateTo(
            messageProvider.getScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 600),
            curve: Curves.ease,
          );
        },
      ));
  }

  return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.symmetric(vertical: 20.0),
      height: 330,
      child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: elements.length,
          itemBuilder: (BuildContext context, int index) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              width: MediaQuery.of(context).size.width,
              child: Card(
                  color: Colors.white,
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: 250.0,
                        child: Stack(
                          children: <Widget>[
                            Positioned.fill(
                                child: Container(
                              color: Colors.black,
                              child: Opacity(
                                opacity: 0.5,
                                child: Image.network(
                                    elements[index]['image_url'],
                                    fit: BoxFit.cover),
                              ),
                            )),
                            Positioned(
                              bottom: 0.0,
                              left: 16.0,
                              right: 16.0,
                              child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        elements[index]['title'],
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 20),
                                      ),
                                      Text(
                                        elements[index]['subtitle'],
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15),
                                      )
                                    ],
                                  )),
                            )
                          ],
                        ),
                      ),
                      ButtonBarTheme(
                        data: ButtonBarThemeData(),
                        child: ButtonBar(
                          buttonPadding: EdgeInsets.symmetric(horizontal: 10),
                          alignment: MainAxisAlignment.end,
                          children: galleryButtons,
                        ),
                      )
                    ],
                  )),
            );
          }));
}
