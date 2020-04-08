import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:uuid/uuid.dart';
import 'package:cognigy_flutter_client/cognigy/config.dart' as config;

class SocketService {
  IO.Socket socket;
  bool connected = false;

  final sessionId = Uuid().v1(); // time-based
  final userId = Uuid().v4(); // random

  sendMessage(String text) {

    if (connected) {
      socket.emit('processInput', {
        'URLToken': '849de509618869b1cf5d14855354b7b81ceb43bd5f5d4a6e72080ddaed9bc3ea',
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

  createSocketConnection() {
    print('calling socket service');
    socket = IO.io(config.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'extraHeaders': {
        'URLToken': config.urlToken
      }
    });


    this.socket.on("connect", (_) {
      print("[SocketClient] connection established");
      connected = true;
    });

    this.socket.on("disconnect", (_) => print("[SocketClient] disconnected"));
  }
}