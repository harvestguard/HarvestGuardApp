import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:harvest_guard/custom/listener.dart';
import 'package:harvest_guard/firebase_options.dart';
import 'package:provider/provider.dart';
Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => ChatDatabase(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: EventScreen(),
    );
  }
}

class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventNotifier = Provider.of<ChatDatabase>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Event Notifier Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Text('Chat Messages:\n${const JsonEncoder.withIndent('  ').convert(eventNotifier.chatsMap)}'),
                ),
              ),
            ],
          
        ),
      ),
    );
  }
}
