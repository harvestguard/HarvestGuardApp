import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State createState() => HomeState();
}

class HomeState extends State<Home> {
  final ScrollController _scrollController = ScrollController();
  late double height;

  @override
  void initState() {
    height = 50.0;
    // _scrollController.addListener(_maybeUpdateSize);
    super.initState();
  }

  void _maybeUpdateSize() {
    final ScrollPosition position = _scrollController.position;
    if (position.pixels >= 0.0 && position.pixels <= 150.0) {
      setState((){
        height = 200.0 - position.pixels;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('demo'),
      ),
      body: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.all(8),
        itemCount: 50,
        itemBuilder: (BuildContext context, int index) {
          return SizedBox(
            height: 50,
            child: Center(child: Text('Entry $index')),
          );
        }
      )
    );
  }
}