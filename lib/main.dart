import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'join_screen.dart';
import 'signaling_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final String socketUrl = kIsWeb ? 'http://127.0.0.1:5000' : 'http://10.0.2.2:5000';
  final String selfCallerId = Random().nextInt(999999).toString().padLeft(6, '0');

  @override
  Widget build(BuildContext context) {
    SignalingService.instance.init(socketUrl: socketUrl, selfCallerId: selfCallerId);
    return MaterialApp(
      title: 'Flutter Real Time Com',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData.dark(
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: JoinScreen(selfCallerId: selfCallerId),
    );
  }
}
