
import 'package:flutter/material.dart';

showMyDialog(BuildContext context, String title, String message) async {
  var result = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.pop(context, 'OK');
            },
          ),
        ],
      );
    },
  );
  return result;
}

showMySnackBar(BuildContext context, String message, Color color, int duration) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration: Duration(milliseconds: duration),
      content: Text(message),
      backgroundColor: color,
    )
  );
}