import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class GenreButton extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final double width;
  final double height;
  final Function onPressed;

  const GenreButton({
    required this.child,
    required this.gradient,
    this.width = double.infinity,
    required this.height,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(15.0),
              bottomLeft: Radius.circular(15.0)),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              offset: Offset(0.0, 1.5),
              blurRadius: 1.5,
            ),
          ]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
            onTap: () => onPressed(),
            child: Center(
              child: child,
            )),
      ),
    );
  }
}
