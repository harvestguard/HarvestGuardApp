


import 'package:flutter/material.dart';

void showLoadingPopup(BuildContext context) {
  showDialog(
        context: context,
        barrierDismissible: false, // Make the dialog not cancellable
        builder: (BuildContext context) {
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

}
