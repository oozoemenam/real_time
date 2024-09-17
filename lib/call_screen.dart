import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart';

import 'signaling_service.dart';

class CallScreen extends StatefulWidget {
  final String fromId;
  final String toId;
  final dynamic offer;

  const CallScreen({
    super.key,
    required this.fromId,
    required this.toId,
    this.offer,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final Socket _socket = SignalingService.instance.socket!;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  late MediaStream _localStream;
  late RTCPeerConnection _rtcPeerConnection;
  final List<RTCIceCandidate> _rtcIceCandidates = <RTCIceCandidate>[];

  bool isAudioOn = true;
  bool isVideoOn = true;
  bool isFrontCameraSelected = true;

  setupPeerConnection() async {
    _rtcPeerConnection = await createPeerConnection(<String, dynamic>{
      'iceServers': <Map<String, List<String>>>[
        <String, List<String>>{
          'urls': <String>[
            'stun:stun1.l.google.com:19302',
            'stun:stun2.l.google.com:19302',
          ],
        }
      ],
    });
    _rtcPeerConnection.onTrack = (RTCTrackEvent event) {
      _remoteRenderer.srcObject = event.streams[0];
      setState(() {});
    };
    _localStream = await navigator.mediaDevices.getUserMedia(<String, dynamic>{
      'audio': isAudioOn,
      'video': isVideoOn
          ? <String, String>{'facingMode': isFrontCameraSelected ? 'user' : 'environment'}
          : false,
    });
    _localStream.getTracks().forEach((MediaStreamTrack track) {
      _rtcPeerConnection.addTrack(track, _localStream);
    });
    _localRenderer.srcObject = _localStream;
    setState(() {});

    if (widget.offer != null) {
      _socket.on('IceCandidate', (data) {
        final String candidate = data['iceCandidate']['candidate'];
        final String sdpMid = data['iceCandidate']['id'];
        final int sdpMLineIndex = data['iceCandidate']['label'];
        _rtcPeerConnection.addCandidate(RTCIceCandidate(candidate, sdpMid, sdpMLineIndex));
      });
      await _rtcPeerConnection.setRemoteDescription(
        RTCSessionDescription(widget.offer['sdp'], widget.offer['type']),
      );
      final RTCSessionDescription answer = await _rtcPeerConnection.createAnswer();
      _rtcPeerConnection.setLocalDescription(answer);
      _socket.emit('answerCall', <String, dynamic>{
        'fromId': widget.fromId,
        'sdpAnswer': answer.toMap(),
      });
    } else {
      _rtcPeerConnection.onIceCandidate = (RTCIceCandidate candidate) {
        _rtcIceCandidates.add(candidate);
      };
      _socket.on('callAnswered', (data) async {
        await _rtcPeerConnection.setRemoteDescription(
          RTCSessionDescription(
            data['sdpAnswer']['sdp'],
            data['sdpAnswer']['type'],
          ),
        );
        for (RTCIceCandidate candidate in _rtcIceCandidates) {
          _socket.emit('IceCandidate', <String, Object>{
            'toId': widget.toId,
            'iceCandidate': <String, Object?>{
              'id': candidate.sdpMid,
              'label': candidate.sdpMLineIndex,
              'candidate': candidate.candidate,
            },
          });
        }
      });

      final RTCSessionDescription offer = await _rtcPeerConnection.createOffer();
      await _rtcPeerConnection.setLocalDescription(offer);
      _socket.emit('makeCall', <String, dynamic>{
        'toId': widget.toId,
        'sdpOffer': offer.toMap(),
      });
    }
  }

  leaveCall() {
    Navigator.pop(context);
  }

  toggleMic() {
    isAudioOn = !isAudioOn;
    _localStream.getAudioTracks().forEach((MediaStreamTrack track) {
      track.enabled = isAudioOn;
    });
    setState(() {});
  }

  toggleCamera() {
    isVideoOn = !isVideoOn;
    _localStream.getVideoTracks().forEach((MediaStreamTrack track) {
      track.enabled = isVideoOn;
    });
    setState(() {});
  }

  switchCamera() {
    isFrontCameraSelected = !isFrontCameraSelected;
    _localStream.getVideoTracks().forEach((MediaStreamTrack track) {
      Helper.switchCamera(track);
    });
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _localRenderer.initialize();
    _remoteRenderer.initialize();
    setupPeerConnection();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _localStream.dispose();
    _rtcPeerConnection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('P2P Call App')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                children: <Widget>[
                  RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: SizedBox(
                      height: 150,
                      width: 120,
                      child: RTCVideoView(
                        _localRenderer,
                        mirror: isFrontCameraSelected,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  IconButton(
                    onPressed: toggleMic,
                    icon: Icon(
                      isAudioOn ? Icons.mic : Icons.mic_off,
                      color: isAudioOn ? Colors.blue : Colors.red,
                    ),
                  ),
                  IconButton(
                    onPressed: leaveCall,
                    icon: const Icon(Icons.call_end, size: 30, color: Colors.red),
                  ),
                  IconButton(
                    onPressed: switchCamera,
                    icon: const Icon(Icons.cameraswitch),
                  ),
                  IconButton(
                    onPressed: toggleCamera,
                    icon: Icon(isVideoOn ? Icons.videocam : Icons.videocam_off),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
