import 'package:ashira_flutter/model/Song.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class SongLayout extends StatefulWidget {
  final Song song;
  final int index;
  bool open;
  int clickedIndex;
  final VoidCallback onTapAction;

  bool isSmartphone;

  String memberText;

  SongLayout(
      {required this.song,
      required this.index,
      required this.open,
      required this.clickedIndex,
      required this.onTapAction,
      required this.isSmartphone,
      required this.memberText});

  @override
  _SongLayoutState createState() => _SongLayoutState();
}

class _SongLayoutState extends State<SongLayout> {
  bool amIHovering = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ElevatedButton(
        style: ButtonStyle(backgroundColor:
            MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
          return Colors.transparent;
        })),
        onPressed: () {
          widget.onTapAction();
        },
        child: Container(
          decoration: widget.clickedIndex > 0
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  color: Color(0xFF8D3C8E),
                  backgroundBlendMode: BlendMode.plus)
              : widget.open
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      color: Color(0xFF0A999A),
                      backgroundBlendMode: BlendMode.colorDodge)
                  : BoxDecoration(
                      borderRadius: BorderRadius.circular(15.0),
                      color: Color(0xFF656666)),
          child: Stack(children: [
            Column(
              children: [
                Expanded(
                  flex: 4,
                  child: Container(
                      margin: EdgeInsets.all(5.0),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(15.0),
                          child: Image(
                              fit: BoxFit.fill,
                              image: NetworkImage(
                                  widget.song.imageResourceFile)))),
                ),
                Expanded(
                  flex: kIsWeb && widget.isSmartphone ? 1 : 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Text(
                          widget.song.title,
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Normal',
                              fontSize: kIsWeb ? 15 : 12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Center(
                          child: Text(
                            widget.song.artist,
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Normal',
                                fontSize: kIsWeb ? 15 : 12),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      widget.clickedIndex > 0
                          ? widget.clickedIndex.toString()
                          : "",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                // if (!widget.open)
                //   Padding(
                //     padding: EdgeInsets.all(10),
                //     child: Align(
                //       alignment: Alignment.bottomCenter,
                //       child: MouseRegion(
                //         cursor: SystemMouseCursors.click,
                //         onEnter: (PointerEvent details) => amIHovering = true,
                //         onExit: (PointerEvent details) => amIHovering = false,
                //         child: RichText(
                //             text: TextSpan(
                //                 text: widget.memberText,
                //                 style: TextStyle(
                //                   color: amIHovering
                //                       ? Colors.red[300]
                //                       : Colors.red,
                //                   decoration: TextDecoration.underline,
                //                 ),
                //                 recognizer: TapGestureRecognizer()
                //                   ..onTap = () {
                //                     widget.onTapAction();
                //                   })),
                //       ),
                //     ),
                //   )
              ],
            ),
            if (!widget.open)
              Padding(
                padding: EdgeInsets.all(10),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (PointerEvent details) {
                      setState(() {
                        amIHovering = true;
                      });
                    },
                    onExit: (PointerEvent details) {
                      setState(() {
                        amIHovering = false;
                      });
                    },
                    child: RichText(
                        text: TextSpan(
                            text: widget.memberText,
                            style: TextStyle(
                              color: amIHovering ? Colors.red[300] : Colors.red,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                widget.onTapAction();
                              })),
                  ),
                ),
              )
          ]),
        ),
      ),
    );
  }

  hovering() {
    amIHovering = true;
  }

  notHovering() {
    amIHovering = false;
  }
}
