import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final String text;

  const LoadingIndicator({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: new Container(
        decoration: BoxDecoration(color: Colors.grey[600], shape: BoxShape.rectangle, borderRadius: BorderRadius.all(Radius.circular(20))),
        width: 150.0,
        height: 100.0,
        child: Column(children: [
          new Padding(
              padding: const EdgeInsets.all(5.0),
              child: new Center(
                  child: new Text(
                text,
                style: TextStyle(
                    color: Colors.black, letterSpacing: 1.5, fontSize: 16),
              ))),
          Center(
              child: CircularProgressIndicator(
                valueColor:AlwaysStoppedAnimation<Color>(Colors.white),
          ))
        ]),
      ),
    );
  }
}
