import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebrtcScreen extends StatefulWidget {
  const WebrtcScreen({super.key});

  @override
  State<WebrtcScreen> createState() => _WebrtcScreenState();
}

class _WebrtcScreenState extends State<WebrtcScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _offer = false;
  late RTCPeerConnection _peerConnection;
  late MediaStream _localStream;

  final TextEditingController _sdpController = TextEditingController();

  void initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<MediaStream> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = <String, dynamic>{
      'audio': false,
      'video': <String, String>{
        'facingMode': 'user',
      },
    };
    MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    _localRenderer.srcObject = stream;
    // _localRenderer.mirror = true;
    return stream;
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    Map<String, dynamic> configuration = <String, dynamic>{
      'iceServers': <Map<String, String>>[
        <String, String>{'url': 'stun:stun.l.google.com:19302'},
      ],
    };
    final Map<String, dynamic> offerSdpConstraints = <String, dynamic>{
      'mandatory': <String, bool>{
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': <dynamic>[],
    };
    _localStream = await _getUserMedia();
    RTCPeerConnection pc = await createPeerConnection(configuration);
    _localStream.getTracks().forEach((track) {
      pc.addTrack(track, _localStream);
    });
    pc.onIceCandidate = (RTCIceCandidate e) {
      print(e);
    };
    pc.onIceConnectionState = (RTCIceConnectionState e) {
      print(e);
    };
    pc.onTrack = (event) {
      print('onTrack: $event');
      _remoteRenderer.srcObject = event.streams[0];
    };
    return pc;
  }

  void _createOffer() async {
    RTCSessionDescription description = await _peerConnection.createOffer();
    print(description.sdp!);
    _offer = true;
    _peerConnection.setLocalDescription(description);
  }

  void _createAnswer() async {
    RTCSessionDescription description = await _peerConnection.createAnswer();
    print(description.sdp!);
    _peerConnection.setLocalDescription(description);
  }

  void _setRemoteDescription() async {
    String jsonString = _sdpController.text;
    dynamic session = await jsonDecode(jsonString);
    RTCSessionDescription description = RTCSessionDescription(session, _offer ? 'answer' : 'offer');
    print(description.toMap());
    await _peerConnection.setRemoteDescription(description);
  }

  void _setCandidate() async {
    String jsonString = _sdpController.text;
    dynamic session = await jsonDecode(jsonString);
    print(session['candidate']);
    final RTCIceCandidate candidate =
        RTCIceCandidate(session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
    await _peerConnection.addCandidate(candidate);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _sdpController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    initRenderers();
    _createPeerConnection().then((RTCPeerConnection pc) {
      _peerConnection = pc;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Webrtc'),
      ),
      body: Column(
        children: <Widget>[
          videoRenderers(),
          offerAndAnswerButtons(),
          sdpCandidateTF(),
          sdpCandidateButtons(),
        ],
      ),
    );
  }

  SizedBox videoRenderers() {
    return SizedBox(
      height: 210,
      child: Row(
        children: <Widget>[
          Flexible(
            child: Container(
              key: const Key('local'),
              margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
              decoration: const BoxDecoration(color: Colors.black),
              child: RTCVideoView(_localRenderer),
            ),
          ),
          Flexible(
            child: Container(
              key: const Key('remote'),
              margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
              decoration: const BoxDecoration(color: Colors.black),
              child: RTCVideoView(_remoteRenderer),
            ),
          ),
        ],
      ),
    );
  }

  Row offerAndAnswerButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        ElevatedButton(
          onPressed: _createOffer,
          child: const Text('Offer'),
        ),
        ElevatedButton(
          onPressed: _createAnswer,
          child: const Text('Answer'),
        ),
      ],
    );
  }

  Padding sdpCandidateTF() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _sdpController,
        keyboardType: TextInputType.multiline,
        maxLines: 4,
        maxLength: TextField.noMaxLength,
      ),
    );
  }

  Row sdpCandidateButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        ElevatedButton(
          onPressed: _setRemoteDescription,
          child: const Text('Set Remote Desc'),
        ),
        ElevatedButton(
          onPressed: _setCandidate,
          child: const Text('Set Candidate'),
        ),
      ],
    );
  }
}

// ********************** OLD API *************************
// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:sdp_transform/sdp_transform.dart';
//
// class WebrtcScreen extends StatefulWidget {
//   const WebrtcScreen({super.key});
//
//   @override
//   State<WebrtcScreen> createState() => _WebrtcScreenState();
// }
//
// class _WebrtcScreenState extends State<WebrtcScreen> {
//   final _localRenderer = RTCVideoRenderer();
//   final _remoteRenderer = RTCVideoRenderer();
//   bool _offer = false;
//   late RTCPeerConnection _peerConnection;
//   late MediaStream _localStream;
//
//   final sdpController = TextEditingController();
//
//   void initRenderers() async {
//     await _localRenderer.initialize();
//     await _remoteRenderer.initialize();
//   }
//
//   Future<MediaStream> _getUserMedia() async {
//     final Map<String, dynamic> mediaConstraints = {
//       'audio': false,
//       'video': {
//         'facingMode': 'user',
//       },
//     };
//     MediaStream stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
//     _localRenderer.srcObject = stream;
//     // _localRenderer.mirror = true;
//     return stream;
//   }
//
//   Future<RTCPeerConnection> _createPeerConnection() async {
//     Map<String, dynamic> configuration = {
//       'iceServers': [
//         {'url': 'stun:stun.l.google.com:19302'},
//       ]
//     };
//     final Map<String, dynamic> offerSdpConstraints = {
//       'mandatory': {
//         'OfferToReceiveAudio': true,
//         'OfferToReceiveVideo': true,
//       },
//       'optional': [],
//     };
//     _localStream = await _getUserMedia();
//     RTCPeerConnection pc = await createPeerConnection(configuration, offerSdpConstraints);
//     pc.addStream(_localStream);
//     pc.onIceCandidate = (e) {
//       if (e.candidate != null) {
//         print(json.encode({
//           'candidate': e.candidate.toString(),
//           'sdpMid': e.sdpMid.toString(),
//           'sdpMlineIndex': e.sdpMLineIndex,
//         }));
//       }
//     };
//     pc.onIceConnectionState = (e) {
//       print(e);
//     };
//     pc.onAddStream = (stream) {
//       print('addStream: ${stream.id}');
//       _remoteRenderer.srcObject = stream;
//     };
//     return pc;
//   }
//
//   void _createOffer() async {
//     RTCSessionDescription description =
//     await _peerConnection.createOffer({'offerToReceiveVideo': 1});
//     var session = parse(description.sdp!);
//     print(json.encode(session));
//     _offer = true;
//     _peerConnection.setLocalDescription(description);
//   }
//
//   void _createAnswer() async {
//     RTCSessionDescription description =
//     await _peerConnection.createAnswer({'offerToReceiveVideo': 1});
//     var session = parse(description.sdp!);
//     print(json.encode(session));
//     _peerConnection.setLocalDescription(description);
//   }
//
//   void _setRemoteDescription() async {
//     String jsonString = sdpController.text;
//     dynamic session = await jsonDecode(jsonString);
//     String sdp = write(session, null);
//     RTCSessionDescription description = RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');
//     print(description.toMap());
//     await _peerConnection.setRemoteDescription(description);
//   }
//
//   void _setCandidate() async {
//     String jsonString = sdpController.text;
//     dynamic session = await jsonDecode(jsonString);
//     print(session['candidate']);
//     final candidate =
//     RTCIceCandidate(session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
//     await _peerConnection.addCandidate(candidate);
//   }
//
//   @override
//   void dispose() {
//     _localRenderer.dispose();
//     _remoteRenderer.dispose();
//     sdpController.dispose();
//     super.dispose();
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     initRenderers();
//     _createPeerConnection().then((pc) {
//       _peerConnection = pc;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: const Text('Flutter WebRTC'),
//       ),
//       body: Column(
//         children: [
//           videoRenderers(),
//           offerAndAnswerButtons(),
//           sdpCandidateTF(),
//           sdpCandidateButtons(),
//         ],
//       ),
//     );
//   }
//
//   SizedBox videoRenderers() {
//     return SizedBox(
//       height: 210,
//       child: Row(
//         children: [
//           Flexible(
//             child: Container(
//               key: const Key('local'),
//               margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
//               decoration: const BoxDecoration(color: Colors.black),
//               child: RTCVideoView(_localRenderer),
//             ),
//           ),
//           Flexible(
//             child: Container(
//               key: const Key('remote'),
//               margin: const EdgeInsets.fromLTRB(5, 5, 5, 5),
//               decoration: const BoxDecoration(color: Colors.black),
//               child: RTCVideoView(_remoteRenderer),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Row offerAndAnswerButtons() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         ElevatedButton(
//           onPressed: _createOffer,
//           child: const Text('Offer'),
//         ),
//         ElevatedButton(
//           onPressed: _createAnswer,
//           child: const Text('Answer'),
//         ),
//       ],
//     );
//   }
//
//   Padding sdpCandidateTF() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: TextField(
//         controller: sdpController,
//         keyboardType: TextInputType.multiline,
//         maxLines: 4,
//         maxLength: TextField.noMaxLength,
//       ),
//     );
//   }
//
//   Row sdpCandidateButtons() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         ElevatedButton(
//           onPressed: _setRemoteDescription,
//           child: const Text('Set Remote Desc'),
//         ),
//         ElevatedButton(
//           onPressed: _setCandidate,
//           child: const Text('Set Candidate'),
//         ),
//       ],
//     );
//   }
// }
