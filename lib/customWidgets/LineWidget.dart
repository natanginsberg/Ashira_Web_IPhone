import 'package:ashira_flutter/model/DisplayOptions.dart';
import 'package:ashira_flutter/model/Line.dart';
import 'package:ashira_flutter/screens/AllSongs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class LineWidget extends StatefulWidget {
  Line line;
  double size;

  LineWidget({
    required this.line,
    required this.size,
  });

  @override
  _LineState createState() => _LineState();
}

class _LineState extends State<LineWidget> {
  Color pastFontColor = (display == DisplayOptions.PERSONAL_MOISHIE ||
          display == DisplayOptions.WITH_CLIP)
      ? Colors.green
      : Colors.white;
  Color futureFontColor = (display == DisplayOptions.PERSONAL_MOISHIE ||
          display == DisplayOptions.WITH_CLIP)
      ? Colors.white
      : Colors.white30;
  FontWeight weight = (display == DisplayOptions.PERSONAL_MOISHIE ||
          display == DisplayOptions.WITH_CLIP)
      ? FontWeight.bold
      : FontWeight.normal;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: (display == DisplayOptions.PERSONAL_MOISHIE ||
              display == DisplayOptions.WITH_CLIP)
          ? (MediaQuery.of(context).size.height / 4).toDouble()
          : 41,
      child: Center(
        child: Stack(children: [
          RichText(
              text: TextSpan(
                  style: TextStyle(
                      fontFamily: 'SongFont',
                      fontSize: widget.size,
                      color: pastFontColor,
                      fontWeight: weight),
                  children: [
                TextSpan(
                    text: widget.line.past,
                    style: TextStyle(
                      fontFamily: 'SongFont',
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 3
                        ..color =
                            // (display == DisplayOptions.PERSONAL_MOISHIE || display == DisplayOptions.WITH_CLIP)
                            //     ? Colors.green
                            //     :
                            Colors.purple,
                    )),
                TextSpan(
                  text: (display == DisplayOptions.PERSONAL_MOISHIE ||
                              display == DisplayOptions.WITH_CLIP) &&
                          widget.line.past == "" &&
                          widget.line.containsDots()
                      ? 3.toString()
                      : widget.line.future,
                  style:
                      // (display == DisplayOptions.PERSONAL_MOISHIE || display == DisplayOptions.WITH_CLIP)
                      //     ? TextStyle(
                      //         fontFamily: 'SongFont',
                      //         fontSize: size,
                      //         fontWeight: weight,
                      //         foreground: Paint()
                      //           ..style = PaintingStyle.stroke
                      //           ..strokeWidth = 1
                      //           ..color = Colors.white,
                      //       )
                      //     :
                      TextStyle(
                          fontFamily: 'SongFont',
                          color: futureFontColor,
                          fontSize: widget.size,
                          fontWeight: weight),
                )
              ])),
          RichText(
              text: TextSpan(
                  style: TextStyle(
                      fontFamily: 'SongFont',
                      fontSize: widget.size,
                      color: pastFontColor,
                      fontWeight: weight),
                  children: [
                TextSpan(
                    text: widget.line.past,
                    style: TextStyle(
                        fontFamily: 'SongFont',
                        color: pastFontColor,
                        fontWeight: weight)),
                TextSpan(
                    text: (display == DisplayOptions.PERSONAL_MOISHIE ||
                                display == DisplayOptions.WITH_CLIP) &&
                            widget.line.past == "" &&
                            widget.line.containsDots()
                        ? 3.toString()
                        : widget.line.future,
                    style: TextStyle(
                        fontFamily: 'SongFont',
                        color: futureFontColor,
                        fontSize: widget.size,
                        fontWeight: weight))
              ]))
        ]),
      ),
    );
  }
}
