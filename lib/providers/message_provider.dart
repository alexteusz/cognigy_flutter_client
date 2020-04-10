import 'package:cognigy_flutter_client/cognigy/socket_service.dart';
import 'package:cognigy_flutter_client/helper/message_helper.dart';
import 'package:cognigy_flutter_client/main.dart';
import 'package:cognigy_flutter_client/models/message_model.dart';
import 'package:flutter/material.dart';

class MessageProvider extends ChangeNotifier {
  
  SocketService socketService = injector.get<SocketService>();
  Message cognigyMessage;
  List _messages = List();
  TextEditingController _textController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  String _socketUrl;
  String _urlToken;

  MessageProvider() {

    socketService.socket.on('output', (cognigyResponse) {

      // process the cognigy output message
      cognigyMessage = processCognigyMessage(cognigyResponse);

      if (cognigyMessage != null) {

        addMessage(cognigyMessage, 'bot');
      }
    });

  }

  void addMessage(Message message, String sender) {
    _messages.add({'message': message, 'sender': sender});
    notifyListeners();
  }

  List get getMessages => _messages;

  int get getLength => _messages.length;

  void deleteMessages() {
    _messages.clear();
    notifyListeners();
  }

  void setUserInputText(String text) {
    _textController.text = text;
    notifyListeners();
  }

  String get getUserInputText => _textController.text;

  TextEditingController get getUserInputTextController => _textController;

  ScrollController get getScrollController => _scrollController;

  void setSocketUrl(String socketUrl) {
    _socketUrl = socketUrl;
    notifyListeners();
  }

  String get getSocketUrl => _socketUrl;

  void setURLToken(String urlToken) {
    _urlToken = urlToken;
    notifyListeners();
  }

  String get getUrlToken => _urlToken;
}