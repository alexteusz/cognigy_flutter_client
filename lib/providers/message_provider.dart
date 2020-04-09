import 'package:cognigy_flutter_client/cognigy/socket_service.dart';
import 'package:cognigy_flutter_client/helper/message_helper.dart';
import 'package:cognigy_flutter_client/main.dart';
import 'package:cognigy_flutter_client/models/message_model.dart';
import 'package:flutter/material.dart';

class MessageProvider extends ChangeNotifier {
  
  SocketService socketService = injector.get<SocketService>();
  Message cognigyMessage;

  MessageProvider() {

    socketService.socket.on('output', (cognigyResponse) {
      //print('COGNIGY: $cognigyResponse');
      // process the cognigy output message
      cognigyMessage = processCognigyMessage(cognigyResponse);

      if (cognigyMessage != null) {

        addMessage(cognigyMessage, 'bot');
      }
    });

  }

  List _messages = List();

  void addMessage(Message message, String sender) {
    _messages.add({'message': message, 'sender': sender});
    notifyListeners();
  }

  List get getMessages => _messages;

  int get getLength => _messages.length;
}