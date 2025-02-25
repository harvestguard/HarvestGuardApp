import 'package:flutter/material.dart';
import 'dart:async';

Future<BuildContext> showLoadingPopup(BuildContext context) async {
  final Completer<BuildContext> completer = Completer();

  showDialog(
    context: context,
    barrierDismissible: false, // Make the dialog not cancellable
    builder: (BuildContext dialogContext) {
      completer.complete(dialogContext); // Capture dialog's BuildContext
      return PopScope(
        canPop: false, // Disable back button
        child: const AlertDialog(
          title: Center(
            child: Text('Loading'),
          ),
          content: Center(
            heightFactor: 2,
            child: SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    },
  );

  return completer.future;
}