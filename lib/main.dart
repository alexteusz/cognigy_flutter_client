//import 'package:cognigy_flutter_client/widgets/message.dart';
import 'package:cognigy_flutter_client/helper/message_helper.dart';
import 'package:cognigy_flutter_client/models/message_model.dart';
import 'package:cognigy_flutter_client/providers/message_provider.dart';
import 'package:cognigy_flutter_client/widgets/main_appBar.dart';
import 'package:cognigy_flutter_client/widgets/messages.dart';
import 'package:flutter/material.dart';

// Import required files for Cognigy.AI connection
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:cognigy_flutter_client/cognigy/app_initializer.dart';
import 'package:cognigy_flutter_client/cognigy/dependency_injection.dart';
import 'package:cognigy_flutter_client/cognigy/socket_service.dart';
import 'package:provider/provider.dart';

// Create Injector
Injector injector;

void main() async {
  DependencyInjection().initialise(Injector.getInjector());
  injector = Injector.getInjector();
  await AppInitializer().initialise(injector);
  // Run App with Provider
  runApp(ChangeNotifierProvider<MessageProvider>(
      create: (_) => MessageProvider(), child: MyApp()));
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
  double height, width;

  final SocketService socketService = injector.get<SocketService>();
  FocusNode focusNode;

  @override
  void initState() {
    super.initState();

    socketService.createSocketConnection();
    focusNode = FocusNode();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    focusNode.dispose();

    super.dispose();
  }

  Widget buildChatInput(MessageProvider messageProvider) {
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
          focusNode: focusNode,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.send,
          autofocus: false,
          autocorrect: true,
          enableSuggestions: true,
          onChanged: (value) {
            messageProvider.setUserInputText(value);
          },
          onEditingComplete: () {
            //Check if the textfield has text or not
            if (messageProvider.getUserInputText.isNotEmpty) {
              socketService.sendMessage(messageProvider.getUserInputText);

              messageProvider.addMessage(
                  new Message('text', messageProvider.getUserInputText, null),
                  'user');

              messageProvider.setUserInputText('');

              focusNode.unfocus();

              //Scrolldown the list to show the latest message
              messageProvider.getScrollController.animateTo(
                messageProvider.getScrollController.position.maxScrollExtent,
                duration: Duration(milliseconds: 600),
                curve: Curves.ease,
              );
            }
          },
          decoration: InputDecoration.collapsed(
            hintText: 'Send a message...',
          ),
          controller: messageProvider.getUserInputTextController,
        ),
      ),
    );
  }

  Widget buildSendButton(MessageProvider messageProvider) {
    return FloatingActionButton(
      backgroundColor: Colors.transparent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      onPressed: () {
        //Check if the textfield has text or not
        if (messageProvider.getUserInputText.isNotEmpty) {
          socketService.sendMessage(messageProvider.getUserInputText);

          messageProvider.addMessage(
              new Message('text', messageProvider.getUserInputText, null),
              'user');

          //textController.text = '';
          messageProvider.setUserInputText('');

          focusNode.unfocus();

          //Scrolldown the list to show the latest message
          messageProvider.getScrollController.animateTo(
            messageProvider.getScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 600),
            curve: Curves.ease,
          );
        }
      },
      child: Icon(
        Icons.send,
        size: 30,
        color: messageProvider.getUserInputText == ''
            ? Colors.black12
            : Colors.black,
      ),
    );
  }

  Widget buildInputArea(MessageProvider messageProvider) {
    return Container(
      width: width,
      color: Colors.transparent,
      child: Row(
        children: <Widget>[
          buildChatInput(messageProvider),
          buildSendButton(messageProvider),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return Consumer<MessageProvider>(
        builder: (context, messageProvider, child) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: MainAppBar(messageProvider: messageProvider,),
        body: GestureDetector(
          onTap: () => focusNode.unfocus(),
          child: Column(
            children: <Widget>[
              Expanded(
                  child: ListView.builder(
                controller: messageProvider.getScrollController,
                itemCount: messageProvider.getLength,
                itemBuilder: (BuildContext context, int index) {
                  return buildMessage(index, messageProvider);
                },
              )),
              buildInputArea(messageProvider),
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
    });
  }

  Widget buildMessage(int index, MessageProvider messageProvider) {
    Widget messageWidget;

    List messages = messageProvider.getMessages;

    String sender = messages[index]['sender'];
    Message message = messages[index]['message'];

    switch (message.type) {
      case 'text':
        messageWidget = textMessage(index, sender, message.text, messageProvider);
        break;
      case 'quick_replies':
        messageWidget = quickRepliesMessage(
            index, message.data, message.text, socketService, messageProvider);
        break;
      case 'image_attachment':
        messageWidget = imageMessage(index, message.text);
        break;
      case 'gallery':
        messageWidget =
            galleryMessage(index, message.data, socketService, messageProvider);
        break;
      case 'video':
        break;
    }
    return messageWidget;
  }
}
