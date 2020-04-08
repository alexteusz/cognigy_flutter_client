import 'package:flutter/material.dart';

// Import required files for Cognigy.AI connection
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:cognigy_flutter_client/cognigy/app_initializer.dart';
import 'package:cognigy_flutter_client/cognigy/dependency_injection.dart';
import 'package:cognigy_flutter_client/cognigy/socket_service.dart';

// Create Injector
Injector injector;

void main() async {
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
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Cognigy Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List messages;
  double height, width;
  TextEditingController textController;
  ScrollController scrollController;

  final SocketService socketService = injector.get<SocketService>();

  @override
  void initState() {
    //Initializing the message list
    messages = List();

    //Initializing the TextEditingController and ScrollController
    textController = TextEditingController();
    scrollController = ScrollController();

    // Connect to Cognigy.AI Socket.IO Endpoint
    socketService.createSocketConnection();

    socketService.socket.on('output', (jsonData) {
      //Convert the JSON data received into a Map

      this.setState(() => messages.add({
            'message': jsonData['data']['text'],
            'data': jsonData['data']['data'],
            'sender': 'bot'
          }));
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 600),
        curve: Curves.ease,
      );
    });

    super.initState();
  }

  void _sendMessage() {
    //Check if the textfield has text or not
    if (textController.text.isNotEmpty) {
      socketService.sendMessage(textController.text);

      this.setState(() => messages
          .add({'message': textController.text, 'data': {}, 'sender': 'user'}));
      textController.text = '';
      //Scrolldown the list to show the latest message
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 600),
        curve: Curves.ease,
      );
    }
  }

  Widget buildSingleMessage(int index) {
    //print('Message: ${messages[index]}');

    var sender = messages[index]['sender'];
    var message = messages[index]['message'];

    if (message == null) return Container();

    return Container(
      alignment: sender == 'bot' ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        margin: const EdgeInsets.only(bottom: 20.0, left: 20.0, right: 20.0),
        decoration: BoxDecoration(
          color: sender == 'bot' ? Colors.grey[600] : Colors.grey[200],
          border: null,
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Text(
          message,
          style: TextStyle(
              color: sender == 'bot' ? Colors.white : Colors.grey[900],
              fontSize: 15.0),
        ),
      ),
    );
  }

  Widget buildMessageList() {
    return Container(
      height: height * 0.8,
      width: width,
      child: ListView.builder(
        controller: scrollController,
        itemCount: messages.length,
        itemBuilder: (BuildContext context, int index) {
          return buildSingleMessage(index);
        },
      ),
    );
  }

  Widget buildChatInput() {
    return Container(
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
      padding: const EdgeInsets.only(top: 2.0, left: 40),
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

            this.setState(() => messages.add({
                  'message': textController.text,
                  'data': {},
                  'sender': 'user'
                }));
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

  @override
  Widget build(BuildContext context) {
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SizedBox(height: height * 0.1),
            buildMessageList(),
            buildChatInput(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _sendMessage,
        tooltip: 'Send Message',
        child: Icon(Icons.send),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
