import 'package:cognigy_flutter_client/helper/config_helper.dart';
import 'package:cognigy_flutter_client/providers/message_provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:uuid/uuid.dart';
//import 'package:cognigy_flutter_client/cognigy/config.dart' as config;

class SocketService {
  IO.Socket socket;
  bool connected = false;

  final sessionId = Uuid().v1(); // time-based
  final userId = Uuid().v4(); // random

  sendMessage(String text) async {

    var config = await getCognigyConfig();

    if (connected) {
      socket.emit('processInput', {
        'URLToken': config['urlToken'],
        'text': text,
        'userId': userId,
        'sessionId': sessionId,
        'channel': 'flutter',
        'data': null,
        'source': 'device',
      });
    } else {
      print('[SocketClient] Unable to directly send your message since we are not connected.');
    }
  }

  createSocketConnection() async {
    print("[SocketClient] try to connect to Cognigy.AI");

    // get config data from persistent storage
    var config = await getCognigyConfig();

    MessageProvider messageProvider = new MessageProvider();

    socket = IO.io(config['socketUrl'], <String, dynamic>{
      'transports': ['websocket'],
      'extraHeaders': {
        'URLToken': config['urlToken']
      }
    });


    this.socket.on("connect", (_) {
      print("[SocketClient] connection established");
      connected = true;

      messageProvider.setSocketConnected(true);
    });

    this.socket.on("disconnect", (_) {
      print("[SocketClient] disconnected");

      messageProvider.setSocketConnected(false);
    }); 
  }
}