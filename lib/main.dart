//import 'package:cognigy_flutter_client/widgets/message.dart';
import 'package:cognigy_flutter_client/helper/message_helper.dart';
import 'package:cognigy_flutter_client/helper/notification_helper.dart';
import 'package:cognigy_flutter_client/models/message_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cognigy_flutter_client/widgets/configuration_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Import required files for Cognigy.AI connection
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:cognigy_flutter_client/cognigy/app_initializer.dart';
import 'package:cognigy_flutter_client/cognigy/dependency_injection.dart';
import 'package:cognigy_flutter_client/cognigy/socket_service.dart';

// Create Injector
Injector injector;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();


NotificationAppLaunchDetails notificationAppLaunchDetails;


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');
  // Note: permissions aren't requested here just to demonstrate that can be done later using the `requestPermissions()` method
  // of the `IOSFlutterLocalNotificationsPlugin` class
  var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
  );
  var initializationSettings = InitializationSettings(
      initializationSettingsAndroid, initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
    if (payload != null) {
      debugPrint('[Push Notification] payload was: $payload');
    }
  });

  DependencyInjection().initialise(Injector.getInjector());
  injector = Injector.getInjector();
  await AppInitializer().initialise(injector);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cognigy Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  FocusNode focusNode;
  List messages;
  double height, width;
  TextEditingController textController;
  ScrollController scrollController;
  ChatMessage cognigyMessage;
  bool isConnected;

  final SocketService socketService = injector.get<SocketService>();

  @override
  void initState() {
    //Initializing the message list
    messages = List();

    //Initializing the TextEditingController and ScrollController
    textController = TextEditingController();
    scrollController = ScrollController();
    isConnected = false;
    focusNode = FocusNode();

    handleCognigyConnection();

    // request notification permissions on IOS devices
    requestIOSPermissions(flutterLocalNotificationsPlugin);

    super.initState();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    focusNode.dispose();
    super.dispose();
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

            if (cognigyMessage != null) {
              this.setState(() =>
                  messages.add({'message': cognigyMessage, 'sender': 'bot'}));

              //Scrolldown the list to show the latest message
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: Duration(milliseconds: 600),
                curve: Curves.ease,
              );
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
      margin: const EdgeInsets.only(left: 40.0),
      decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: Colors.black12, width: 1.5),
          borderRadius: BorderRadius.circular(30.0)),
      child: Padding(
        padding: const EdgeInsets.only(left: 15.0),
        child: TextField(
          showCursor: false,
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
          },
          onEditingComplete: () {
            //Check if the textfield has text or not
            if (textController.text.isNotEmpty) {
              socketService.sendMessage(textController.text);

              setState(() {
                messages.add({
                  'message': new ChatMessage('text', textController.text, null),
                  'sender': 'user'
                });
              });

              textController.text = '';

              focusNode.unfocus();

              //Scrolldown the list to show the latest message
              scrollController.animateTo(
                scrollController.position.maxScrollExtent,
                duration: Duration(milliseconds: 600),
                curve: Curves.ease,
              );
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
        if (textController.text.isNotEmpty) {
          socketService.sendMessage(textController.text);

          setState(() {
            messages.add({
              'message': new ChatMessage('text', textController.text, null),
              'sender': 'user'
            });
          });

          textController.text = '';

          focusNode.unfocus();

          //Scrolldown the list to show the latest message
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 600),
            curve: Curves.ease,
          );
        }
      },
      child: Icon(
        Icons.send,
        size: 30,
        color: textController.text == '' ? Colors.black12 : Colors.black,
      ),
    );
  }

  Widget buildInputArea() {
    return Container(
      width: width,
      color: Colors.transparent,
      child: Row(
        children: <Widget>[
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
      backgroundColor: Colors.white,
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
        backgroundColor: Colors.white,
        title: Image(
          image: AssetImage('assets/images/logo.png'),
          width: 200,
        ),
      ),
      body: GestureDetector(
        onTap: () => focusNode.unfocus(),
        child: Column(
          children: <Widget>[
            Expanded(
                child: ListView.builder(
              controller: scrollController,
              itemCount: messages.length,
              itemBuilder: (BuildContext context, int index) {
                return buildMessage(index);
              },
            )),
            buildInputArea(),
            !focusNode.hasFocus
                ? SizedBox(
                    height: 20,
                    child: Container(
                      color: Colors.white,
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
    }
    return messageWidget;
  }

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

            setState(() {
              messages.add({
                'message': (new ChatMessage('text', qr['title'], null)),
                'sender': 'user'
              });
            });

            //Scrolldown the list to show the latest message
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
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

  Widget galleryMessage(int index, List elements, SocketService socketService) {
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
                socketService.sendMessage(b['payload']);

                setState(() {
                  messages.add({
                    'message': (new ChatMessage('text', b['title'], null)),
                    'sender': 'user'
                  });
                });
                break;
              case 'web_url':
                _launchUrl(b['url']);
            }

            //Scrolldown the list to show the latest message
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
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

                setState(() {
                  messages.add({
                    'message': (new ChatMessage('text', b['title'], null)),
                    'sender': 'user'
                  });
                });
                break;
              case 'web_url':
                _launchUrl(b['url']);
                break;
            }

            //Scrolldown the list to show the latest message
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 600),
              curve: Curves.ease,
            );
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
              color: Colors.grey[600],
              border: null,
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            ),
            child: Text(
              buttonText,
              style: TextStyle(color: Colors.white, fontSize: 15.0),
            ),
          ),
          Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: buttonWidgets),
        ],
      ),
    );
  }
}
