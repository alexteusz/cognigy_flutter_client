//import 'package:cognigy_flutter_client/widgets/message.dart';
import 'package:cognigy_flutter_client/helper/message_helper.dart';
import 'package:cognigy_flutter_client/models/message_model.dart';
import 'package:cognigy_flutter_client/providers/message_provider.dart';
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
  TextEditingController textController;
  ScrollController scrollController;
  //Message cognigyMessage;

  final SocketService socketService = injector.get<SocketService>();

  MessageProvider messageProvider;

  @override
  void initState() {
    super.initState();
    
    //MessageProvider msgProvider = new MessageProvider();

    //Initializing the TextEditingController and ScrollController
    textController = TextEditingController();
    scrollController = ScrollController();

    socketService.createSocketConnection();
  }

  Widget buildChatInput(MessageProvider messageProvider) {
    return Container(
      width: width * 0.7,
      constraints: BoxConstraints(minWidth: width * 0.7),
      padding: const EdgeInsets.all(2.0),
      margin: const EdgeInsets.only(left: 40.0),
      child: TextField(
        keyboardType: TextInputType.text,
        textInputAction: TextInputAction.send,
        autofocus: true,
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

            messageProvider.addMessage(
                new Message('text', textController.text, null), 'user');

            textController.text = '';
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
        if (textController.text.isNotEmpty) {
          socketService.sendMessage(textController.text);

          messageProvider.addMessage(
              new Message('text', textController.text, null), 'user');

          textController.text = '';
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
        color: textController.text == '' ? Colors.black12 : Colors.black45,
      ),
    );
  }

  Widget buildInputArea(MessageProvider messageProvider) {
    return Container(
      height: height * 0.1,
      width: width,
      constraints: BoxConstraints(minWidth: width, minHeight: height * 0.1),
      decoration: new BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black,
            blurRadius: 5.0, // has the effect of softening the shadow
            spreadRadius: 5.0, // has the effect of extending the shadow
            offset: Offset(
              10.0, // horizontal, move right 10
              10.0, // vertical, move down 10
            ),
          )
        ],
      ),
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
    return Consumer<MessageProvider>(builder: (context, messageProvider, child) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Image(
            image: AssetImage('assets/images/logo.png'),
            width: 200,
          ),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
                child: ListView.builder(
              controller: scrollController,
              itemCount: messageProvider.getLength,
              itemBuilder: (BuildContext context, int index) {
                return buildMessage(index, messageProvider);
              },
            )),
            buildInputArea(messageProvider)
          ],
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
        messageWidget = textMessage(index, sender, message.text);
        break;
      case 'quick_replies':
        messageWidget = quickRepliesMessage(
            index, message.data, message.text, socketService, messageProvider);
        break;
      case 'image_attachment':
        messageWidget = imageMessage(index, message.text);
        break;
      case 'gallery':
        messageWidget = galleryMessage(index, message.data, socketService, messageProvider);
        break;
    }
    return messageWidget;
  }
}
