import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TonePicker extends StatelessWidget {
  final int MAN = 0;
  final int WOMAN = 1;
  final int KID = 2;

  final bool colorful;
  final Function(int) setSong;

  TonePicker({
    required this.colorful,
    required this.setSong,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Center(
        child: Container(
          height: 450,
          width: 330,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.purple),
              borderRadius: BorderRadius.all(new Radius.circular(20.0)),
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  const Color(0xFF221A4D), // blue sky
                  const Color(0xFF000000), // yellow sun
                ],
              )),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.toneQuestion,
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    AppLocalizations.of(context)!.toneExplanation,
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ],
              ),
              ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(children: <Widget>[
                    Positioned.fill(
                      child: Container(
                        decoration: colorful
                            ? BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(new Radius.circular(50.0)),
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    Color(0xFF0D47A1),
                                    Color(0xFF1976D2),
                                    Color(0xFF42A5F5),
                                  ],
                                ),
                              )
                            : BoxDecoration(
                                color: Colors.purple,
                                // border: Border.all(color: Colors.tealAccent),
                                borderRadius:
                                    BorderRadius.all(new Radius.circular(60.0)),
                                gradient: RadialGradient(
                                  colors: <Color>[
                                    Colors.purple.shade200,
                                    Colors.purple.shade800,
                                    Colors.purple.shade500,
                                  ],
                                  stops: [0.2, 0.7, 1],
                                  center: Alignment(0.1, 0.3),
                                  focal: Alignment(-0.1, 0.6),
                                  focalRadius: 2,
                                ),
                              ),
                      ),
                    ),
                    Container(
                      height: 50,
                      width: 130,
                      child: TextButton(
                          onPressed: () {
                            setSong(MAN);
                          },
                          child: Text(
                            AppLocalizations.of(context)!.man,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              // letterSpacing: 1.5
                            ),
                          )),
                    ),
                  ])),
              ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(children: <Widget>[
                    Positioned.fill(
                      child: Container(
                        decoration: colorful
                            ? BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(new Radius.circular(60.0)),
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    Color(0xFF630DA1),
                                    Color(0xFF7A37E5),
                                    Color(0xFFB47DF1),
                                  ],
                                ),
                              )
                            : BoxDecoration(
                                gradient: RadialGradient(
                                  colors: <Color>[
                                    Colors.purple.shade200,
                                    Colors.purple.shade800,
                                    Colors.purple.shade500,
                                  ],
                                  stops: [0.2, 0.7, 1],
                                  center: Alignment(0.1, 0.3),
                                  focal: Alignment(-0.1, 0.6),
                                  focalRadius: 3,
                                ),
                                borderRadius:
                                    BorderRadius.all(new Radius.circular(75.0)),
                              ),
                      ),
                    ),
                    Container(
                      height: 50,
                      width: 130,
                      child: TextButton(
                          onPressed: () {
                            setSong(WOMAN);
                          },
                          child: Text(
                            AppLocalizations.of(context)!.woman,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              //letterSpacing: 1.5
                            ),
                          )),
                    ),
                  ])),
              ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(children: <Widget>[
                    Positioned.fill(
                      child: Container(
                        decoration: colorful
                            ? BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(new Radius.circular(60.0)),
                                gradient: LinearGradient(
                                  colors: <Color>[
                                    Color(0xFF0D47A1),
                                    Color(0xFF19D247),
                                    Color(0xFFF5AD42),
                                  ],
                                ),
                              )
                            : BoxDecoration(
                                gradient: RadialGradient(
                                  colors: <Color>[
                                    Colors.purple.shade200,
                                    Colors.purple.shade800,
                                    Colors.purple.shade500,
                                  ],
                                  stops: [0.2, 0.7, 1],
                                  center: Alignment(0.1, 0.3),
                                  focal: Alignment(-0.1, 0.6),
                                  focalRadius: 4,
                                ),
                                borderRadius:
                                    BorderRadius.all(new Radius.circular(90.0)),
                              ),
                      ),
                    ),
                    Container(
                      height: 50,
                      width: 130,
                      child: TextButton(
                          onPressed: () {
                            setSong(KID);
                          },
                          child: Text(
                            AppLocalizations.of(context)!.kid,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              //    letterSpacing: 1.5
                            ),
                          )),
                    ),
                  ])),
            ],
          ),
        ),
      ),
    );
  }
}
