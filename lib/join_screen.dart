import 'package:flutter/material.dart';

import 'call_screen.dart';
import 'signaling_service.dart';

class JoinScreen extends StatefulWidget {
  final String selfCallerId;

  const JoinScreen({super.key, required this.selfCallerId});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  dynamic incomingSdpOffer;
  final TextEditingController remoteCallerIdTextController = TextEditingController();

  joinCall({required String fromId, required String toId, dynamic offer}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CallScreen(
          fromId: fromId,
          toId: toId,
          offer: offer,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    SignalingService.instance.socket?.on('newCall', (data) {
      setState(() => incomingSdpOffer = data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P2P Call App'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    TextField(
                      controller: TextEditingController(
                        text: widget.selfCallerId,
                      ),
                      readOnly: true,
                      textAlign: TextAlign.center,
                      enableInteractiveSelection: false,
                      decoration: InputDecoration(
                        labelText: 'Your Caller Id',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: remoteCallerIdTextController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Remote Caller Id',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        joinCall(
                          fromId: widget.selfCallerId,
                          toId: remoteCallerIdTextController.text,
                        );
                      },
                      child: const Text(
                        'Invite',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (incomingSdpOffer != null)
              Positioned(
                child: ListTile(
                  title: Text(
                    'Incoming call from ${incomingSdpOffer['fromId']}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        onPressed: () => setState(() => incomingSdpOffer = null),
                        color: Colors.redAccent,
                        icon: const Icon(Icons.call_end),
                      ),
                      IconButton(
                        onPressed: () {
                          joinCall(
                            fromId: incomingSdpOffer['fromId'],
                            toId: widget.selfCallerId,
                            offer: incomingSdpOffer['sdpOffer'],
                          );
                        },
                        color: Colors.greenAccent,
                        icon: const Icon(Icons.call),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
