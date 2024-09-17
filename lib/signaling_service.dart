import 'package:socket_io_client/socket_io_client.dart';

class SignalingService {
  Socket? socket;

  SignalingService._();

  static final SignalingService instance = SignalingService._();

  init({required String socketUrl, required String selfCallerId}) {
    socket = io(socketUrl, <String, Object>{
      'transports': <String>['websocket'],
      'query': <String, String>{'fromId': selfCallerId},
    });
    socket!.onConnect((data) {
      print('socket connected');
    });
    socket!.onConnectError((data) {
      print('connection error: $data');
    });
    socket!.connect();
  }
}
