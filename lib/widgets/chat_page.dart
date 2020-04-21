import 'package:cognigy_flutter_client/helper/message_helper.dart';
import 'package:cognigy_flutter_client/helper/notification_helper.dart';
import 'package:cognigy_flutter_client/main.dart';
import 'package:cognigy_flutter_client/models/message_model.dart';
import 'package:cognigy_flutter_client/widgets/configuration_dialog.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cognigy_flutter_client/cognigy/socket_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

// voice input
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => new _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  FocusNode focusNode;
  List messages;
  double height, width;
  TextEditingController textController;
  ScrollController scrollController;
  ChatMessage cognigyMessage;
  bool isConnected;
  AppLifecycleState appLifecycleState;
  bool isRecordingVoice;
  bool _hasSpeech;

  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final SocketService socketService = injector.get<SocketService>();
  final SpeechToText speech = SpeechToText();

  @override
  void initState() {
    //Initializing the message list
    messages = List();

    //Initializing the TextEditingController and ScrollController
    textController = TextEditingController();
    scrollController = ScrollController();
    isConnected = false;
    isRecordingVoice = false;
    _hasSpeech = false;
    focusNode = FocusNode();

    handleCognigyConnection();

    // request notification permissions on IOS devices
    requestIOSPermissions(flutterLocalNotificationsPlugin);

    // check if the application is in foreground or not
    WidgetsBinding.instance.addObserver(this);

    // initialize speech service
    initSpeechState();

    super.initState();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      appLifecycleState = state;
    });
  }

  Future<void> initSpeechState() async {
    bool hasSpeech =
        await speech.initialize(onError: (SpeechRecognitionError error) {
      print('[VoiceInput] error: $error');
    }, onStatus: (String status) {
      print('[VoiceInput] status: $status');
    });

    if (!mounted) return;
    setState(() {
      _hasSpeech = hasSpeech;
    });
  }

  addMessageToChat(ChatMessage message, String sender) {
    // get index to insert message
    var messageIndex = messages.length;

    // add message to list
    messages.add({'message': message, 'sender': sender});

    // add message to animated list in UI
    _listKey.currentState
        .insertItem(messageIndex, duration: Duration(milliseconds: 300));

    //Scrolldown the list to show the latest message
    scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 600),
      curve: Curves.ease,
    );
  }

  handleCognigyConnection() {
    if (!isConnected) {
      // Connect to Cognigy.AI Socket.IO Endpoint
      socketService.createSocketConnection().then((socket) {
        if (socket != null) {
          socket.on("connect", (_) {
            setState(() {
              isConnected = true;
            });
          });

          socket.on("disconnect", (_) {
            setState(() {
              isConnected = false;
            });
          });

          socket.on('output', (cognigyResponse) {
            // process the cognigy output message
            cognigyMessage = processCognigyMessage(cognigyResponse);

            try {
              if (appLifecycleState.index == 1 ||
                  appLifecycleState.index == 2) {
                showNotification(
                    cognigyMessage.text, flutterLocalNotificationsPlugin);
              }
            } catch (_) {}

            if (cognigyMessage != null) {
              addMessageToChat(cognigyMessage, 'bot');
            }
          });
        }
      });
    }
  }

  Widget buildChatInput() {
    return Container(
      width: width * 0.7,
      constraints: BoxConstraints(minWidth: width * 0.7),
      //padding: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
          color: Theme.of(context).accentColor,
          //border: Border.all(color: Colors.black12, width: 1.5),
          borderRadius: BorderRadius.circular(30.0)),
      child: Padding(
        padding: const EdgeInsets.only(left: 15.0),
        child: TextField(
          showCursor: true,
          cursorRadius: Radius.circular(30),
          cursorColor: Theme.of(context).primaryColor,
          focusNode: focusNode,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.send,
          autofocus: false,
          autocorrect: true,
          enableSuggestions: true,
          onChanged: (value) {
            setState(() {
              textController.text = value;
            });

            // set the cursor position
            String text = textController.text;
            textController.value = textController.value.copyWith(
                text: text,
                selection: TextSelection(
                    baseOffset: text.length, extentOffset: text.length),
                composing: TextRange.empty);
          },
          onEditingComplete: () {
            //Check if the textfield has text or not
            if (textController.text.isNotEmpty) {
              socketService.sendMessage(textController.text);

              addMessageToChat(
                  new ChatMessage('text', textController.text, null), 'user');

              textController.text = '';

              focusNode.unfocus();
            }
          },
          decoration: InputDecoration.collapsed(
            hintText: 'Send a message...',
          ),
          controller: textController,
        ),
      ),
    );
  }

  Widget buildSendButton() {
    return FloatingActionButton(
      backgroundColor: Colors.transparent,
      
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      onPressed: () {
        //Check if the textfield has text or not
        if (textController.text.isNotEmpty && !isRecordingVoice) {
          socketService.sendMessage(textController.text);

          addMessageToChat(
              new ChatMessage('text', textController.text, null), 'user');

          textController.text = '';

          focusNode.unfocus();
        }
      },
      child: Icon(
        Icons.send,
        size: 30,
        color: textController.text == '' ? Colors.black12 : Colors.black,
      ),
    );
  }

  Widget buildVoiceInputButton() {
    return FloatingActionButton(
      backgroundColor: Colors.transparent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      onPressed: () {
        setState(() {
          isRecordingVoice = isRecordingVoice != true;
        });

        // start recording the user's voice
        if (isRecordingVoice) {
          speech.listen(onResult: (SpeechRecognitionResult result) {
            textController.text = result.recognizedWords;
          });
        } else if (!isRecordingVoice) {
          speech.stop();
        }
      },
      child: Icon(
        isRecordingVoice ? Icons.mic_off : Icons.mic,
        size: 30,
        color: isRecordingVoice ? Colors.black : Colors.black12,
      ),
    );
  }

  Widget buildInputArea() {
    return Container(
      width: width,
      color: Colors.transparent,
      child: Row(
        children: <Widget>[
          buildVoiceInputButton(),
          buildChatInput(),
          buildSendButton(),
        ],
      ),
    );
  }

  _configurationDialog(BuildContext context) async {
    bool _isConnected = await showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return ConfigurationDialog();
        });

    if (!_isConnected) {
      this.setState(() {
        isConnected = _isConnected;
        // clear messages if new connection is configured
        messages.clear();
      });

      socketService.socket.disconnect();
      handleCognigyConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.black,
            ),
            onPressed: () => _configurationDialog(context)),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 15.0),
            child: Icon(
              Icons.brightness_1,
              color: isConnected ? Colors.green : Colors.red,
              size: 10,
            ),
          )
        ],
        backgroundColor: Theme.of(context).backgroundColor,
        title: GestureDetector(
          onTap: () => launch('https://www.cognigy.com'),
          child: Image(
            image: MediaQuery.of(context).platformBrightness == Brightness.dark
                ? AssetImage('assets/images/logo_white.png')
                : AssetImage('assets/images/logo.png'),
            width: 200,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => focusNode.unfocus(),
        child: Column(
          children: <Widget>[
            Expanded(
                child: AnimatedList(
              key: _listKey,
              controller: scrollController,
              initialItemCount: 0,
              itemBuilder:
                  (BuildContext context, int index, Animation animation) {
                return SlideTransition(
                  child: buildMessage(index),
                  position: Tween<Offset>(
                    begin: messages[index]['sender'] == 'bot'
                        ? Offset(-1.0, 0.0)
                        : Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                );
              },
            )),
            buildInputArea(),
            !focusNode.hasFocus
                ? SizedBox(
                    height: 20,
                    child: Container(
                      color: Theme.of(context).backgroundColor,
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget buildMessage(int index) {
    Widget messageWidget;

    String sender = messages[index]['sender'];
    ChatMessage message = messages[index]['message'];

    switch (message.type) {
      case 'text':
        messageWidget = textMessage(index, sender, message.text);
        break;
      case 'quick_replies':
        messageWidget = quickRepliesMessage(
            index, message.data, message.text, socketService);
        break;
      case 'image_attachment':
        messageWidget = imageMessage(index, message.text);
        break;
      case 'gallery':
        messageWidget = galleryMessage(index, message.data, socketService);
        break;
      case 'buttons':
        messageWidget =
            buttonsMessage(index, message.text, message.data, socketService);
        break;
      case 'list':
        messageWidget = listMessage(index, message.data, socketService);
    }
    return messageWidget;
  }

  Widget textMessage(int index, String sender, String text) {
    if (text == null) return Container();

    return GestureDetector(
      onTap: () => sender == 'user' ? textController.text = text : null,
      child: Container(
        alignment:
            sender == 'bot' ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
            padding: const EdgeInsets.all(20.0),
            margin: const EdgeInsets.only(
                top: 10, bottom: 10.0, left: 20.0, right: 20.0),
            decoration: BoxDecoration(
              color: sender == 'bot'
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).accentColor,
              border: null,
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: Html(
              data: text,
              defaultTextStyle: TextStyle(
                  color: sender == 'bot'
                      ? Theme.of(context).textTheme.body1.color
                      : Colors.grey[900],
                  fontSize: Theme.of(context).textTheme.body1.fontSize),
              shrinkToFit: true,
              linkStyle: TextStyle(
                  color: Theme.of(context).textTheme.body1.color,
                  decorationColor: Theme.of(context).textTheme.body1.color,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600),
              onLinkTap: (url) {
                launch(url);
              },
            )),
      ),
    );
  }

  Widget quickRepliesMessage(
      int index, quickReplies, String text, SocketService socketService) {
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

            addMessageToChat(
                new ChatMessage('text', qr['title'], null), 'user');
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
                color: Theme.of(context).primaryColor,
                border: null,
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: Html(
                data: text,
                defaultTextStyle: Theme.of(context).textTheme.body1,
                shrinkToFit: true,
                linkStyle: TextStyle(
                    color: Theme.of(context).textTheme.body1.color,
                    decorationColor: Theme.of(context).textTheme.body1.color,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600),
                onLinkTap: (url) {
                  launch(url);
                },
              )),
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

  Widget galleryMessage(int index, List elements, SocketService socketService) {
    return Container(
        alignment: Alignment.centerLeft,
        margin: EdgeInsets.symmetric(vertical: 20.0),
        height: 330,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: elements.length,
            itemBuilder: (BuildContext context, int itemIndex) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10.0),
                width: MediaQuery.of(context).size.width,
                child: Card(
                    color: MediaQuery.of(context).platformBrightness ==
                            Brightness.dark
                        ? Theme.of(context).primaryColor
                        : Colors.white,
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
                                      elements[itemIndex]['image_url'],
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
                                          elements[itemIndex]['title'],
                                          style:
                                              Theme.of(context).textTheme.title,
                                        ),
                                        Text(
                                          elements[itemIndex]['subtitle'],
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle,
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
                            children: <Widget>[
                              if (elements[itemIndex]['buttons'] != null)
                                for (var b in elements[itemIndex]['buttons'])
                                  FlatButton(
                                    child: Text(
                                      b['title'].toUpperCase(),
                                      style: TextStyle(color: Colors.black),
                                    ),
                                    onPressed: () {
                                      switch (b['type']) {
                                        case 'postback':
                                          socketService
                                              .sendMessage(b['payload']);

                                          addMessageToChat(
                                              new ChatMessage(
                                                  'text', b['title'], null),
                                              'user');

                                          break;
                                        case 'web_url':
                                          launchUrl(b['url']);
                                      }

                                      //Scrolldown the list to show the latest message
                                      scrollController.animateTo(
                                        scrollController
                                            .position.maxScrollExtent,
                                        duration: Duration(milliseconds: 600),
                                        curve: Curves.ease,
                                      );
                                    },
                                  )
                            ],
                          ),
                        )
                      ],
                    )),
              );
            }));
  }

  Widget buttonsMessage(
      int index, String buttonText, List buttons, SocketService socketService) {
    List<Widget> buttonWidgets = List<Widget>();
    // build buttons
    for (var b in buttons) {
      buttonWidgets.add(
        FlatButton(
          padding: EdgeInsets.all(10.0),
          child: Text(
            b['title'],
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
          ),
          onPressed: () {
            switch (b['type']) {
              case 'postback':
                socketService.sendMessage(b['payload']);

                addMessageToChat(
                    new ChatMessage('text', b['title'], null), 'user');

                break;
              case 'web_url':
                launchUrl(b['url']);
                break;
            }
          },
        ),
      );
    }

    return Container(
      alignment: Alignment.centerLeft,
      margin:
          const EdgeInsets.only(top: 10, bottom: 10.0, left: 20.0, right: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              border: null,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: Html(
                data: buttonText,
                defaultTextStyle: Theme.of(context).textTheme.body1,
                shrinkToFit: true,
                linkStyle: TextStyle(
                    color: Theme.of(context).textTheme.body1.color,
                    decorationColor: Theme.of(context).textTheme.body1.color,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600)),
          ),
          Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: buttonWidgets),
        ],
      ),
    );
  }

  Widget listMessage(int index, dynamic data, SocketService socketService) {
    List items = data['listItems'];
    List buttons = data['listButtons'];

    List<Widget> listWidgets = List<Widget>();

    for (var item in items) {
      listWidgets.add(Card(
          color: MediaQuery.of(context).platformBrightness == Brightness.dark
              ? Theme.of(context).primaryColor
              : Colors.white,
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
                        opacity:
                            item['image_url'].toString().isNotEmpty ? 0.5 : 1,
                        child: item['image_url'].toString().isNotEmpty
                            ? Image.network(item['image_url'],
                                fit: BoxFit.cover)
                            : Container(
                                color:
                                    MediaQuery.of(context).platformBrightness ==
                                            Brightness.dark
                                        ? Theme.of(context).primaryColor
                                        : Colors.white,
                              ),
                      ),
                    )),
                    Positioned(
                      bottom: 16.0,
                      left: 16.0,
                      right: 16.0,
                      child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                item['title'],
                                style: TextStyle(
                                    color:
                                        item['image_url'].toString().isNotEmpty
                                            ? Colors.white
                                            : Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20),
                              ),
                              Text(
                                item['subtitle'],
                                style: TextStyle(
                                    color:
                                        item['image_url'].toString().isNotEmpty
                                            ? Colors.white
                                            : Colors.black,
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
                  children: <Widget>[
                    if (item['buttons'] != null)
                      for (var b in item['buttons'])
                        if (b['type'] != 'element_share')
                          FlatButton(
                            child: Text(
                              b['title'].toString().toUpperCase(),
                              style: TextStyle(color: Colors.black),
                            ),
                            onPressed: () {
                              switch (b['type']) {
                                case 'postback':
                                  socketService.sendMessage(b['payload']);

                                  addMessageToChat(
                                      new ChatMessage('text', b['title'], null),
                                      'user');

                                  break;
                                case 'web_url':
                                  launchUrl(b['url']);
                              }
                            },
                          )
                  ],
                ),
              )
            ],
          )));
    }

    return Container(
      alignment: Alignment.centerLeft,
      margin:
          const EdgeInsets.only(top: 10, bottom: 10.0, left: 20.0, right: 20.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: listWidgets),
    );
  }
}
