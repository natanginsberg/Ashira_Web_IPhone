import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'dart:ui';

import 'package:ashira_flutter/model/Song.dart';
import 'package:ashira_flutter/utils/WpHelper.dart' as wph;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:wordpress_api/wordpress_api.dart' as wp;

import 'Sing.dart';

class AllSongs extends StatefulWidget {
  AllSongs();

  @override
  _AllSongsState createState() => _AllSongsState();
}

final GlobalKey<ScaffoldState> _scaffoldKey2 = GlobalKey<ScaffoldState>();

List<Song> songs = [];

List<String> genres = ["All Songs", "hebrew"];

List<List<Song>> searchPath = [];
List<Song> gridSongs = [];

String email = "";
String id = "";
Timestamp endTime = Timestamp(10, 10);
bool personalMoishie = false;
bool cameraMode = false;
int changeTime = 7;

class _AllSongsState extends State<AllSongs> {
  // Locale _locale = Locale.fromSubtags(languageCode: "he");
  final TextEditingController controller = new TextEditingController();
  final TextEditingController timeController = new TextEditingController();
  bool _smartPhone = false;

  bool _showGenreBar = false;
  bool menuOpen = false;
  late bool onSearchTextChanged;

  String currentGenre = "All Songs";

  String previousValue = "";

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  List<Song> songsClicked = [];

  bool _accessDenied = false;

  bool _overtime = false;

  late Timer timer;

  String duration = "";

  int counter = 0;

  late TextEditingController _orderEditingController;
  late TextEditingController _couponEditingController;
  late TextEditingController _userNameEditingController;

  bool _loading = false;

  String _errorMessage = "";

  bool amIHovering = false;

  bool amIWatsAppHovering = false;

  late ScrollController _mainController;
  final FocusNode _focusNode = FocusNode();

  bool signedIn = false;

  var openSignIn = false;

  List<String> demoSongNames = [];

  int songAccessDenied = -100;

  var _passwordVisible = false;

  int quantity = 0;

  _AllSongsState();

  void signInAnon() async {
    await firebaseAuth.signInAnonymously().then((value) => getSongs());
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // setState(() {
    _mainController = ScrollController();
    _orderEditingController = TextEditingController(text: "");
    _couponEditingController = TextEditingController(text: "");
    _userNameEditingController = TextEditingController(text: "");
    signInAnon();
    _smartPhone = isSmartphone();
    timer =
        Timer.periodic(Duration(seconds: 1), (Timer t) => _getTimeRemaining());
    // });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _focusNode.dispose();
    timer.cancel();
    _mainController.dispose();
    _userNameEditingController.dispose();
    _couponEditingController.dispose();
    _orderEditingController.dispose();
    super.dispose();
  }

  void _handleKeyEvent(RawKeyEvent event) {
    var offset = _mainController.offset;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        if (kReleaseMode) {
          _mainController.animateTo(offset - 80,
              duration: Duration(milliseconds: 30), curve: Curves.ease);
        } else {
          _mainController.animateTo(offset - 80,
              duration: Duration(milliseconds: 30), curve: Curves.ease);
        }
      });
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        if (kReleaseMode) {
          _mainController.animateTo(offset + 80,
              duration: Duration(milliseconds: 30), curve: Curves.ease);
        } else {
          _mainController.animateTo(offset + 80,
              duration: Duration(milliseconds: 30), curve: Curves.ease);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          key: _scaffoldKey2,
          backgroundColor: Colors.transparent,
          body: Stack(children: [
            RawKeyboardListener(
              autofocus: true,
              focusNode: _focusNode,
              onKey: _handleKeyEvent,
              child: Container(
                decoration: BoxDecoration(
                    gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    const Color(0xFF221A4D), // blue sky
                    const Color(0xFF000000),
                  ],
                )),
                child: Stack(children: [
                  Column(
                    children: [
                      SafeArea(
                        child: Directionality(
                          textDirection: Directionality.of(context),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_showGenreBar)
                                Container(
                                    height: 150,
                                    width: 110,
                                    decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                      colors: <Color>[Colors.pink, Colors.blue],
                                    )),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        buildListView(),
                                        Align(
                                          alignment: Alignment.topCenter,
                                          child: Transform.rotate(
                                            angle: 270 * pi / 180,
                                            child: IconButton(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4.0),
                                              onPressed: () {
                                                setState(() {
                                                  _showGenreBar = false;
                                                });
                                              },
                                              icon: const Icon(
                                                  Icons.arrow_back_ios_rounded),
                                              color: Colors.pink[300],
                                            ),
                                          ),
                                        ),
                                      ],
                                    )),
                              if (signedIn)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      30.0, 10, 30, 10),
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      AppLocalizations.of(context)!
                                              .timeRemaining +
                                          duration,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                )
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 15.0, horizontal: 8.0),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.6,
                          height: 48,
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: Color(0xFF8D3C8E), width: 2),
                              borderRadius: BorderRadius.circular(50),
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 4,
                                colors: [
                                  const Color(0xFF221A4D), // blue sky
                                  const Color(0xFF000000), // yellow sun
                                ],
                              )),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.search,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.5,
                                  height: 48,
                                  child: Center(
                                    child: Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: TextField(
                                        style: TextStyle(color: Colors.white),
                                        textAlign: TextAlign.center,
                                        controller: controller,
                                        decoration: new InputDecoration(
                                          hintText:
                                              AppLocalizations.of(context)!
                                                  .search,
                                          hintStyle:
                                              TextStyle(color: Colors.white),
                                          fillColor: Colors.transparent,
                                        ),
                                        onChanged: (String value) {
                                          if (value != previousValue)
                                            setState(() {
                                              // searchPath.add(new List.from(gridSongs));
                                              gridSongs = songs
                                                  .where((element) =>
                                                      element.title
                                                          .contains(value) ||
                                                      element.artist
                                                          .contains(value))
                                                  .toList();
                                              previousValue = value;
                                            });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: new Icon(
                                    Icons.cancel,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    controller.clear();
                                    previousValue = "";
                                    setState(() {
                                      gridSongs = List.from(searchPath.first);
                                      searchPath.clear();
                                    });
                                  },
                                ),
                              ]),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                  decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                    center: Alignment.center,
                                    radius: 0.8,
                                    colors: [
                                      const Color(0xFF221A4D),
                                      // blue sky
                                      const Color(0xFF000000),
                                      // yellow sun
                                    ],
                                  )),
                                  margin: const EdgeInsets.fromLTRB(
                                      20.0, 0.0, 20.0, 0.0),
                                  child: _accessDenied
                                      ? expireWording()
                                      : buildGridView(gridSongs)),
                            ),
                            if (!_smartPhone && songsClicked.length > 0)
                              Center(
                                child: Container(
                                  width: 350,
                                  child: Column(
                                    // mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        AppLocalizations.of(context)!.display,
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 20),
                                      ),
                                      Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Flexible(
                                                child: RichText(
                                                  text: TextSpan(children: [
                                                    TextSpan(
                                                        text:
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .classic,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                        recognizer:
                                                            TapGestureRecognizer()
                                                              ..onTap = () {
                                                                setState(() {
                                                                  personalMoishie =
                                                                      false;
                                                                });
                                                              }),
                                                  ]),
                                                ),
                                              ),
                                              Theme(
                                                data: ThemeData(
                                                    unselectedWidgetColor:
                                                        Colors.red),
                                                child: Checkbox(
                                                  //    <-- label
                                                  value: !personalMoishie &&
                                                      !cameraMode,
                                                  onChanged: (newValue) {
                                                    setState(() {
                                                      personalMoishie = false;
                                                      cameraMode = false;
                                                    });
                                                  },
                                                ),
                                              ),
                                              Flexible(
                                                child: RichText(
                                                  text: TextSpan(children: [
                                                    TextSpan(
                                                        text:
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .advanced,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                        recognizer:
                                                            TapGestureRecognizer()
                                                              ..onTap = () {
                                                                setState(() {
                                                                  personalMoishie =
                                                                      true;
                                                                  cameraMode =
                                                                      false;
                                                                });
                                                              }),
                                                  ]),
                                                ),
                                              ),
                                              Theme(
                                                data: ThemeData(
                                                    unselectedWidgetColor:
                                                        Colors.red),
                                                child: Checkbox(
                                                  //    <-- label
                                                  value: personalMoishie,
                                                  onChanged: (newValue) {
                                                    setState(() {
                                                      personalMoishie = true;
                                                      cameraMode = false;
                                                    });
                                                  },
                                                ),
                                              )
                                            ],
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Flexible(
                                                child: RichText(
                                                  text: TextSpan(children: [
                                                    TextSpan(
                                                        text:
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .cameraOn,
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                        ),
                                                        recognizer:
                                                            TapGestureRecognizer()
                                                              ..onTap = () {
                                                                setState(() {
                                                                  cameraMode =
                                                                      true;
                                                                  personalMoishie =
                                                                      false;
                                                                });
                                                              }),
                                                  ]),
                                                ),
                                              ),
                                              Theme(
                                                data: ThemeData(
                                                    unselectedWidgetColor:
                                                        Colors.red),
                                                child: Checkbox(
                                                  //    <-- label
                                                  value: cameraMode,
                                                  onChanged: (newValue) {
                                                    setState(() {
                                                      cameraMode = true;
                                                      personalMoishie = false;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                        AppLocalizations.of(context)!.playlist,
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 20),
                                      ),
                                      // if (personalMoishie)
                                      //   Container(
                                      //     width: 60,
                                      //     height: 48,
                                      //     decoration: BoxDecoration(
                                      //         border: Border.all(
                                      //             color: Color(0xFF8D3C8E),
                                      //             width: 2),
                                      //         borderRadius:
                                      //             BorderRadius.circular(50),
                                      //         gradient: RadialGradient(
                                      //           center: Alignment.center,
                                      //           radius: 4,
                                      //           colors: [
                                      //             const Color(0xFF221A4D),
                                      //             // blue sky
                                      //             const Color(0xFF000000),
                                      //             // yellow sun
                                      //           ],
                                      //         )),
                                      //     child: Row(
                                      //         mainAxisAlignment:
                                      //             MainAxisAlignment
                                      //                 .spaceBetween,
                                      //         children: [
                                      //           SizedBox(
                                      //             width: 55,
                                      //             height: 48,
                                      //             child: Center(
                                      //               child: Directionality(
                                      //                 textDirection:
                                      //                     TextDirection.rtl,
                                      //                 child: TextField(
                                      //                     style: TextStyle(
                                      //                         color:
                                      //                             Colors.white),
                                      //                     textAlign:
                                      //                         TextAlign.center,
                                      //                     controller:
                                      //                         timeController,
                                      //                     decoration:
                                      //                         new InputDecoration(
                                      //                       fillColor: Colors
                                      //                           .transparent,
                                      //                     ),
                                      //                     onChanged:
                                      //                         (String value) {
                                      //                       if (value != "")
                                      //                         changeTime =
                                      //                             int.parse(
                                      //                                 value);
                                      //                       else
                                      //                         changeTime = 0;
                                      //                     }),
                                      //               ),
                                      //             ),
                                      //           ),
                                      //         ]),
                                      //   ),
                                      SizedBox(
                                        height: 15,
                                        child: Text(
                                          overTime()
                                              ? AppLocalizations.of(context)!
                                                  .overtime
                                              : "",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      ),
                                      Text(
                                          AppLocalizations.of(context)!
                                                  .totalTime +
                                              " " +
                                              getClickedSongsLength(),
                                          style: TextStyle(
                                              color: overTime()
                                                  ? Colors.red
                                                  : Colors.white)),
                                      Expanded(
                                        child: SizedBox(
                                          width: 350,
                                          child: ListView.builder(
                                              itemCount: songsClicked.length,
                                              itemBuilder:
                                                  (BuildContext ctx, index) {
                                                return Container(
                                                  color: Colors.transparent,
                                                  alignment: Alignment.center,
                                                  child: createSongLine(index,
                                                      songsClicked[index]),
                                                );
                                              }),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),
                      Container(
                        height: 50,
                        color: Colors.black,
                        child: Directionality(
                          textDirection: Directionality.of(context),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: signedIn
                                  ? [
                                      Text(
                                        AppLocalizations.of(context)!.addTime +
                                            " ",
                                        style: TextStyle(
                                            fontFamily: 'SignInFont',
                                            color: Colors.white,
                                            wordSpacing: 5,
                                            height: 1.4,
                                            letterSpacing: 1.6),
                                      ),
                                      _loading
                                          ? new Container(
                                              color: Colors.transparent,
                                              width: 50.0,
                                              height: 60.0,
                                              child: new Padding(
                                                  padding:
                                                      const EdgeInsets.all(5.0),
                                                  child: new Center(
                                                      child:
                                                          new CircularProgressIndicator())),
                                            )
                                          : Container(
                                              decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius:
                                                      BorderRadius.all(
                                                          new Radius.circular(
                                                              10))),
                                              child: Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          8.0, 4, 8.0, 4),
                                                  child: TextButton(
                                                      onPressed: addTime,
                                                      child: Directionality(
                                                        textDirection:
                                                            TextDirection.ltr,
                                                        child: Text(
                                                          AppLocalizations.of(
                                                                  context)!
                                                              .submit,
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                      )))),
                                      Directionality(
                                        textDirection:
                                            Directionality.of(context),
                                        child: Row(
                                          children: [
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.remove,
                                                    color: Colors.white,
                                                  ),
                                                  onPressed: () {
                                                    if (quantity > 0)
                                                      setState(() {
                                                        quantity -= 1;
                                                      });
                                                  },
                                                ),
                                                Text(
                                                  quantity.toString(),
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.add,
                                                    color: Colors.white,
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      quantity += 1;
                                                    });
                                                  },
                                                ),
                                              ],
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      15, 0, 15, 0),
                                              child: MouseRegion(
                                                cursor:
                                                    SystemMouseCursors.click,
                                                onEnter:
                                                    (PointerEvent details) =>
                                                        setState(() =>
                                                            amIHovering = true),
                                                onExit:
                                                    (PointerEvent details) =>
                                                        setState(() {
                                                  amIHovering = false;
                                                }),
                                                child: RichText(
                                                    text: TextSpan(
                                                        text:
                                                            AppLocalizations.of(
                                                                    context)!
                                                                .placeOrder,
                                                        style: TextStyle(
                                                          color: amIHovering
                                                              ? Colors.blue[300]
                                                              : Colors.blue,
                                                          decoration:
                                                              TextDecoration
                                                                  .underline,
                                                        ),
                                                        recognizer:
                                                            TapGestureRecognizer()
                                                              ..onTap = () {
                                                                launch(
                                                                    'https://ashira-music.com/product/karaoke/');
                                                              })),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ]
                                  : [
                                      Text(
                                        AppLocalizations.of(context)!
                                            .enterSystem,
                                        style: TextStyle(
                                            fontFamily: 'SignInFont',
                                            color: Colors.white,
                                            wordSpacing: 5,
                                            height: 1.4,
                                            letterSpacing: 1.6),
                                      ),
                                      SizedBox(
                                        width: 15,
                                      ),
                                      Container(
                                          decoration: BoxDecoration(
                                              color: Colors.blue,
                                              borderRadius: BorderRadius.all(
                                                  new Radius.circular(10))),
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      8.0, 4, 8.0, 4),
                                              child: TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      openSignIn = true;
                                                    });
                                                  },
                                                  child: Directionality(
                                                    textDirection:
                                                        TextDirection.ltr,
                                                    child: Text(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .enter,
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  )))),
                                    ]),
                        ),
                      )
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Align(
                      alignment: Alignment.bottomRight,
                      child: FloatingActionButton(
                        onPressed: () => checkTime(),
                        autofocus: true,
                        child: Icon(Icons.play_arrow),
                        backgroundColor: songsClicked.length > 0
                            ? Color(0xFF8D3C8E)
                            : Colors.black,
                      ),
                    ),
                  )
                ]),
              ),
            ),
            if (openSignIn) buildSignInPopup()
          ])),
    );
  }

  // updateDocument(title) {
  //   Map<String, dynamic> stringsToAdd = Map();
  //
  //   stringsToAdd["imageResourceFile"] =
  //       "https://s3.wasabisys.com/playbacks/Update Background/expiredpng.png";
  //   stringsToAdd["textResourceFile"] = "";
  //   stringsToAdd["artist"] = "יש לעדכן את האפליקציה";
  //   stringsToAdd["date"] = "";
  //   stringsToAdd["timesPlayed"] = 0;
  //   var collection = FirebaseFirestore.instance.collection('songs');
  //   collection
  //       .doc(title) // <-- Doc ID where data should be updated.
  //       .update(stringsToAdd);
  // }

  getSongs() {
    getDemoSongs();
    incrementFirebaseByOne();
    FirebaseFirestore.instance
        .collection('songsNew')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        songs.add(new Song(
            artist: doc.get('artist'),
            title: doc.get("title"),
            imageResourceFile: doc.get("imageResourceFile"),
            genre: doc.get("genre"),
            songResourceFile: doc.get("songResourceFile"),
            textResourceFile: doc.get("textResourceFile"),
            womanToneResourceFile: doc.get("womanToneResourceFile"),
            kidToneResourceFile: doc.get("kidToneResourceFile"),
            length: doc.get("length")));
      });
      setState(() {
        if (songs.length > 0) {
          gridSongs = new List.from(songs);
          for (String name in demoSongNames) {
            int index = songs.indexWhere((element) => element.title == name);
            gridSongs.remove(songs[index]);
            gridSongs.insert(0, songs[index]);
          }
        }
      });
    });
  }

  Future<void> addSong(demoSongs) {
    Map<String, dynamic> song = Map();
    song["songs"] = demoSongs;
    CollectionReference s =
        FirebaseFirestore.instance.collection('randomFields');
    return s.doc("phoneDemoSongs").set(song);
  }

  void incrementFirebaseByOne() async {
    FirebaseFirestore.instance
        .collection('websiteEntrances')
        .doc('entries')
        .update({'entries': FieldValue.increment(1)});
  }

  buildGridView(List<Song> songs) {
    return GridView.builder(
        controller: _mainController,
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: _smartPhone ? 0.71 : 0.6,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20),
        itemCount: songs.length,
        itemBuilder: (BuildContext ctx, index) {
          return Container(
              alignment: Alignment.center,
              child: buildSongLayout(songs[index], index)
              // SongLayout(
              //   song: songs[index],
              //   index: index,

              );
        });
  }

  buildListView() {
    return Expanded(
      child: Column(children: [
        Expanded(
          child: ListView.builder(
              itemCount: genres.length,
              itemBuilder: (BuildContext ctx, index) {
                return Container(
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: createElevateButton(genre: genres[index]),
                );
              }),
        )
      ]),
    );
  }

  createElevateButton({required String genre}) {
    return ElevatedButton(
        style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
              return Colors.transparent;
            }),
            elevation: MaterialStateProperty.resolveWith<double>(
                (Set<MaterialState> states) {
              return 0.0;
            }),
            padding: MaterialStateProperty.resolveWith((states) =>
                EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0))),
        //adds padding inside the button),
        onPressed: () {
          setState(() {
            if (genre == "All Songs") {
              gridSongs = new List.from(songs);
              for (String name in demoSongNames) {
                gridSongs.insert(
                    0,
                    songs[
                        songs.indexWhere((element) => element.title == name)]);
              }
            } else if (currentGenre != genre) {
              gridSongs = new List.from(
                  songs.where((element) => element.genre == genre).toList());
            }
            currentGenre = genre;
            _showGenreBar = false;
          });
        },
        child: Text(
          genre,
          style: TextStyle(color: Colors.white),
        ));
  }

  void openWebsite() async {
    final url = "https://ashira-music.com/";
    if (await canLaunch(url)) {
      await launch(
        url,
      );
    }
  }

  playSongs() {
    if (songsClicked.length > 0) {
      List<Song> songsPassed = [];
      for (Song song in this.songsClicked) {
        songsPassed.add(song);
      }
      counter += 1;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => Sing(songsPassed, counter.toString())));
      setState(() {
        songsClicked.clear();
      });
    }
  }

  buildSongLayout(Song song, int index) {
    return ElevatedButton(
      style: ButtonStyle(backgroundColor:
          MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        return Colors.transparent;
      })),
      onPressed: () {
        if (signedIn || demoSongNames.contains(song.title))
          setState(() {
            songInSongsClicked(song)
                ? songsClicked.removeWhere((element) =>
                    element.songResourceFile == song.songResourceFile)
                : songsClicked.add(song);
          });
        else {
          setState(() {
            openSignIn = true;
          });
        }
      },
      child: Container(
        decoration: songInSongsClicked(song)
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                color: Color(0xFF8D3C8E),
                backgroundBlendMode: BlendMode.plus)
            : signedIn || demoSongNames.contains(song.title)
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
                            image: NetworkImage(song.imageResourceFile)))),
              ),
              Expanded(
                flex: _smartPhone ? 1 : 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        song.title,
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Normal',
                            fontSize: 15),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Center(
                        child: Text(
                          song.artist,
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Normal',
                              fontSize: 15),
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
                    songInSongsClicked(song)
                        ? (songsClicked.indexWhere((element) =>
                                    element.songResourceFile ==
                                    song.songResourceFile) +
                                1)
                            .toString()
                        : "",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              if (_smartPhone &&
                  !signedIn &&
                  !demoSongNames.contains(song.title))
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (PointerEvent details) =>
                          setState(() => amIHovering = true),
                      onExit: (PointerEvent details) => setState(() {
                        amIHovering = false;
                      }),
                      child: RichText(
                          text: TextSpan(
                              text: AppLocalizations.of(context)!.membersOnly,
                              style: TextStyle(
                                color:
                                    amIHovering ? Colors.red[300] : Colors.red,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  setState(() {
                                    openSignIn = true;
                                  });
                                })),
                    ),
                  ),
                )
            ],
          ),
          if (!signedIn && !demoSongNames.contains(song.title))
            Padding(
              padding: EdgeInsets.all(10),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (PointerEvent details) =>
                      setState(() => amIHovering = true),
                  onExit: (PointerEvent details) => setState(() {
                    amIHovering = false;
                  }),
                  child: RichText(
                      text: TextSpan(
                          text: AppLocalizations.of(context)!.membersOnly,
                          style: TextStyle(
                            color: amIHovering ? Colors.red[300] : Colors.red,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              setState(() {
                                openSignIn = true;
                              });
                            })),
                ),
              ),
            )
        ]),
      ),
    );
  }

  bool isSmartphone() {
    final userAgent = html.window.navigator.userAgent.toString().toLowerCase();
    return (userAgent.contains("iphone") ||
        userAgent.contains("android") ||
        userAgent.contains("ipad") ||
        (html.window.navigator.platform!.toLowerCase().contains("macintel") &&
            html.window.navigator.maxTouchPoints! > 0));
  }

  songInSongsClicked(Song song) {
    if (songsClicked.length > 0)
      for (int i = 0; i < songsClicked.length; i++) {
        if (song.songResourceFile == songsClicked[i].songResourceFile)
          return true;
      }
    return false;
  }

  expireWording() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
            child: Text(
          AppLocalizations.of(context)!.outOfTimeError,
          style: TextStyle(
              fontFamily: 'SignInFont',
              color: Colors.yellow,
              wordSpacing: 5,
              fontSize: 40,
              height: 1.4,
              letterSpacing: 1.6),
        )),
        Directionality(
          textDirection: Directionality.of(context),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(
              AppLocalizations.of(context)!.addTime + " ",
              style: TextStyle(
                  fontFamily: 'SignInFont',
                  color: Colors.white,
                  wordSpacing: 5,
                  fontSize: 30,
                  height: 1.4,
                  letterSpacing: 1.6),
            ),
            _loading
                ? new Container(
                    color: Colors.transparent,
                    width: 70.0,
                    height: 70.0,
                    child: new Padding(
                        padding: const EdgeInsets.all(5.0),
                        child:
                            new Center(child: new CircularProgressIndicator())),
                  )
                : Container(
                    decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius:
                            BorderRadius.all(new Radius.circular(10))),
                    child: Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 4, 8.0, 4),
                        child: TextButton(
                            onPressed: addTime,
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                AppLocalizations.of(context)!.enter,
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              ),
                            ))))
          ]),
        ),
        SizedBox(
          height: 15,
        ),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (PointerEvent details) => setState(() => amIHovering = true),
          onExit: (PointerEvent details) => setState(() {
            amIHovering = false;
          }),
          child: RichText(
              text: TextSpan(
                  text: AppLocalizations.of(context)!.placeOrder,
                  style: TextStyle(
                    fontSize: 25,
                    color: amIHovering ? Colors.blue[300] : Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launch('https://ashira-music.com/product/karaoke/');
                    })),
        ),
        SizedBox(
          height: 15,
        ),
        Text(
          _errorMessage,
          style: TextStyle(color: Colors.red, fontSize: 20),
        )
      ],
    );
  }

  checkTime() async {
    if (signedIn && timesUp())
      setState(() {
        _accessDenied = true;
      });
    else if (overTime()) {
      setState(() {
        _overtime = true;
      });
    } else
      playSongs();
  }

  bool overTime() {
    if (!signedIn) return false;
    DateTime currentTime = DateTime.now()
        .toUtc()
        .add(new Duration(milliseconds: getTotalLength()));
    DateTime myDateTime = endTime.toDate();
    return currentTime.compareTo(myDateTime) > 0;
  }

  bool timesUp() {
    if (!signedIn) return false;
    DateTime currentTime = DateTime.now().toUtc();
    DateTime myDateTime = endTime.toDate();
    return currentTime.compareTo(myDateTime) > 0;
  }

  getClickedSongsLength() {
    int totalLength = getTotalLength();
    return getDurationStringFromLength(totalLength, true);
  }

  getTotalLength() {
    int totalLength = 0;
    for (int i = 0; i < songsClicked.length; i++) {
      totalLength += songs[i].length;
    }
    return totalLength;
  }

  createSongLine(int index, Song song) {
    return Container(
      width: 200,
      height: 50,
      decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
        color: Colors.white,
      ))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: Icon(Icons.cancel),
              color: Colors.white,
              onPressed: () {
                setState(() {
                  songsClicked.removeAt(index);
                  _overtime = false;
                });
              }),
          Text(song.title,
              style: TextStyle(color: _overtime ? Colors.red : Colors.white)),
          Text(getDurationStringFromLength(song.length, false),
              style: TextStyle(color: _overtime ? Colors.red : Colors.white))
        ],
      ),
    );
  }

  getDurationStringFromLength(int totalLength, bool hours) {
    Duration duration = new Duration(milliseconds: totalLength);
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    String twoDigitHours = hours ? "${twoDigits(duration.inHours)}:" : "";
    return twoDigitHours + "$twoDigitMinutes:$twoDigitSeconds";
  }

  _getTimeRemaining() {
    if (signedIn) {
      if (timesUp()) {
        setState(() {
          _accessDenied = true;
        });
      } else {
        Duration timeLeft = endTime.toDate().difference(DateTime.now().toUtc());
        String twoDigits(int n) => n.toString().padLeft(2, "0");
        String twoDigitMinutes = twoDigits(timeLeft.inMinutes.remainder(60));
        String twoDigitSeconds = twoDigits(timeLeft.inSeconds.remainder(60));
        String twoDigitHours = "${twoDigits(timeLeft.inHours)}:";
        setState(() {
          duration = twoDigitHours + "$twoDigitMinutes:$twoDigitSeconds";
        });
      }
    }
  }

  void addTime() async {
    setState(() {
      _loading = true;
    });
    try {
      getPurchaseFromStore(false, false);
    } catch (e) {
      printConnectionError();
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> checkFirebaseId(
      String id) async {
    try {
      var collection = FirebaseFirestore.instance.collection('internetUsers');

      var doc = await collection.doc(id).get();

      return doc;
    } catch (e) {
      printConnectionError();
      throw e;
    }
  }

  Future<List<String>> getCouponCode() async {
    var collection = FirebaseFirestore.instance.collection('randomFields');

    var doc = await collection.doc("coupon").get();

    return List.from(doc.get("code"));
  }

  bool timeIsStillAllocated(DocumentSnapshot<Map<String, dynamic>> doc) {
    DateTime currentTime = DateTime.now().toUtc();
    endTime = doc.get("endTime");
    DateTime myDateTime = endTime.toDate();
    return currentTime.compareTo(myDateTime) < 0;
  }

  addTimeToFirebase(int quantity) {
    Map<String, dynamic> firestoreDoc = new Map<String, dynamic>();
    if (!signedIn || timesUp())
      setState(() {
        endTime =
            Timestamp.fromDate(DateTime.now().add(Duration(hours: quantity)));
      });
    else
      setState(() {
        endTime = Timestamp.fromDate(DateTime.now()
            .add(Duration(hours: quantity))
            .add(endTime.toDate().difference(DateTime.now().toUtc())));
      });
    firestoreDoc['endTime'] = endTime;
    firestoreDoc['email'] = email;

    CollectionReference users =
        FirebaseFirestore.instance.collection('internetUsers');

    Future<void> addUser() {
      return users
          .doc(email)
          .set(firestoreDoc)
          .then((value) => setState(() {
                _accessDenied = false;
                _errorMessage = "";
                _loading = false;
                signedIn = true;
                openSignIn = false;
                gridSongs = new List.from(songs);
              }))
          .catchError((error) => setState(() {
                _errorMessage = error.toString();
                _loading = false;
              }));
    }

    addUser();
  }

  printConnectionError() {
    setState(() {
      _errorMessage = AppLocalizations.of(context)!.communicationError;
      _loading = false;
    });
  }

  buildSignInPopup() {
    return Directionality(
      textDirection: Directionality.of(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
              child: Center(
            child: Stack(children: [
              Center(
                child: Container(
                  height: MediaQuery.of(context).size.height - 40,
                  width: isSmartphone()
                      ? MediaQuery.of(context).size.width
                      : MediaQuery.of(context).size.width / 3,
                  decoration: BoxDecoration(
                      // gradient: RadialGradient(
                      //   center: Alignment.center,
                      //   radius: 0.8,
                      //   colors: [
                      //     const Color(0xFF2C2554),
                      //     const Color(0xFF17131F),
                      //   ],
                      // ),
                      color: Colors.black,
                      border: Border.all(color: Colors.purple),
                      borderRadius:
                          BorderRadius.all(new Radius.circular(20.0))),
                  child: Stack(children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: MediaQuery.of(context).size.height / 3.5,
                          width: MediaQuery.of(context).size.height / 3.5,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/ashira.png'),
                              fit: BoxFit.fill,
                            ),
                            shape: BoxShape.rectangle,
                          ),
                        ),
                        // Center(
                        //     child: Directionality(
                        //   textDirection: Directionality.of(context),
                        //   child: Text(
                        //     AppLocalizations.of(context)!.enterPrompt,
                        //     style: TextStyle(fontSize: 17, color: Colors.white),
                        //   ),
                        // )),
                        // Center(
                        //     child: Directionality(
                        //   textDirection: Directionality.of(context),
                        //   child: Text(
                        //     AppLocalizations.of(context)!.secondPrompt,
                        //     style: TextStyle(fontSize: 17, color: Colors.white),
                        //   ),
                        // )),
                        // Directionality(
                        //   textDirection: Directionality.of(context),
                        //   child: Row(
                        //     mainAxisAlignment: MainAxisAlignment.center,
                        //     children: [
                        //       Row(
                        //         children: [
                        //           IconButton(
                        //             icon: Icon(
                        //               Icons.remove,
                        //               color: Colors.white,
                        //             ),
                        //             onPressed: () {
                        //               if (quantity > 0)
                        //                 setState(() {
                        //                   quantity -= 1;
                        //                 });
                        //             },
                        //           ),
                        //           Text(
                        //               quantity.toString() +
                        //                   " " +
                        //                   AppLocalizations.of(context)!.hours,
                        //               style: TextStyle(color: Colors.white)),
                        //           IconButton(
                        //             icon: Icon(
                        //               Icons.add,
                        //               color: Colors.white,
                        //             ),
                        //             onPressed: () {
                        //               setState(() {
                        //                 quantity += 1;
                        //               });
                        //             },
                        //           ),
                        //         ],
                        //       ),
                        //       SizedBox(
                        //         width: 20,
                        //       ),
                        //       Center(
                        //         child: MouseRegion(
                        //           cursor: SystemMouseCursors.click,
                        //           onEnter: (PointerEvent details) =>
                        //               setState(() => amIHovering = true),
                        //           onExit: (PointerEvent details) =>
                        //               setState(() {
                        //             amIHovering = false;
                        //           }),
                        //           child: RichText(
                        //               text: TextSpan(
                        //                   text: AppLocalizations.of(context)!
                        //                       .placeOrder,
                        //                   style: TextStyle(
                        //                     fontSize: 18,
                        //                     color: amIHovering
                        //                         ? Colors.blue[300]
                        //                         : Colors.blue,
                        //                     decoration:
                        //                         TextDecoration.underline,
                        //                   ),
                        //                   recognizer: TapGestureRecognizer()
                        //                     ..onTap = () {
                        //                       launch(
                        //                           "https://ashira-music.com/checkout/?add-to-cart=1102&quantity=$quantity");
                        //                     })),
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        // ),
                        Center(
                          child: Container(
                              width: isSmartphone()
                                  ? MediaQuery.of(context).size.width / 2
                                  : MediaQuery.of(context).size.width / 4,
                              height: 50,
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.purple),
                                  borderRadius: BorderRadius.all(
                                      new Radius.circular(20.0))),
                              child: Center(
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: TextField(
                                    onSubmitted: (value) {
                                      if (!_loading) checkEmailAndContinue();
                                    },
                                    textAlign: TextAlign.center,
                                    decoration: new InputDecoration(
                                      hintText:
                                          AppLocalizations.of(context)!.email,
                                      hintStyle:
                                          TextStyle(color: Color(0xFF787676)),
                                      fillColor: Colors.transparent,
                                    ),
                                    style: TextStyle(
                                        fontSize: 15, color: Colors.white),
                                    autofocus: true,
                                    controller: _userNameEditingController,
                                  ),
                                ),
                              )),
                        ),
                        Center(
                          child: Container(
                              width: isSmartphone()
                                  ? MediaQuery.of(context).size.width / 2
                                  : MediaQuery.of(context).size.width / 4,
                              height: 50,
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.purple),
                                  borderRadius: BorderRadius.all(
                                      new Radius.circular(20.0))),
                              child: Center(
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: TextField(
                                    onSubmitted: (value) {
                                      if (!_loading) checkEmailAndContinue();
                                    },
                                    textAlign: TextAlign.center,
                                    decoration: new InputDecoration(
                                      hintText:
                                          AppLocalizations.of(context)!.coupon,
                                      hintStyle:
                                          TextStyle(color: Color(0xFF787676)),
                                      fillColor: Colors.transparent,
                                    ),
                                    style: TextStyle(
                                        fontSize: 15, color: Colors.white),
                                    autofocus: true,
                                    controller: _couponEditingController,
                                  ),
                                ),
                              )),
                        ),
                        !_loading
                            ? Container(
                                decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.all(
                                        new Radius.circular(10))),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(8.0, 4, 8.0, 4),
                                  child: TextButton(
                                      onPressed: checkEmailAndContinue,
                                      child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: Text(
                                          AppLocalizations.of(context)!.enter,
                                          style: TextStyle(
                                              fontSize: 20,
                                              color: Colors.white),
                                        ),
                                      )),
                                ),
                              )
                            : new Align(
                                child: new Container(
                                  color: Colors.transparent,
                                  width: 70.0,
                                  height: 70.0,
                                  child: new Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: new Center(
                                          child:
                                              new CircularProgressIndicator())),
                                ),
                                alignment: FractionalOffset.center,
                              ),
                        if (_errorMessage != "")
                          Center(
                              child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              _errorMessage,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 20,
                              ),
                            ),
                          )),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Center(
                            //     child: Directionality(
                            //   textDirection: TextDirection.rtl,
                            //   child: Text(
                            //     AppLocalizations.of(context)!.personalUse,
                            //     // data,
                            //     style: TextStyle(
                            //       //   fontFamily: 'SignInFont',
                            //       color: Colors.white,
                            //       //wordSpacing: 5,
                            //       fontSize: 20,
                            //       //height: 1.4,
                            //       //letterSpacing: 1.6
                            //     ),
                            //   ),
                            // )),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                  child: Text(
                                AppLocalizations.of(context)!.publicUse,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  //fontFamily: 'SignInFont',
                                  color: Colors.white,
                                  // wordSpacing: 5,
                                  fontSize: 20,
                                  height: 1.5,

                                  //height: 1.4,
                                  // letterSpacing: 1.6
                                ),
                              )),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Center(
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onEnter: (PointerEvent details) =>
                                      setState(() => amIWatsAppHovering = true),
                                  onExit: (PointerEvent details) =>
                                      setState(() {
                                    amIWatsAppHovering = false;
                                  }),
                                  child: RichText(
                                      text: TextSpan(
                                          text: AppLocalizations.of(context)!
                                              .watsappNumber,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: amIWatsAppHovering
                                                ? Colors.green[300]
                                                : Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              launch(
                                                  "https://wa.me/message/6CROFFTK7A5BE1");
                                            })),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Center(
                                  child: Text(
                                AppLocalizations.of(context)!.emailUsAt,
                                style: TextStyle(
                                  //fontFamily: 'SignInFont',
                                  color: Colors.white,
                                  //wordSpacing: 5,
                                  fontSize: 20,
                                  // height: 1.4,
                                  //letterSpacing: 1.6
                                ),
                              )),
                            ),
                          ],
                        )
                      ],
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(Icons.close),
                        color: Colors.white,
                        onPressed: () {
                          setState(() {
                            openSignIn = false;
                          });
                        },
                      ),
                    ),
                  ]),
                ),
              ),
            ]),
          )),
        ],
      ),
    );
  }

  checkEmailAndContinue() async {
    setState(() {
      _loading = true;
    });
    String coupon = _couponEditingController.text.toLowerCase();
    List<String> code = new List.empty();
    if (coupon != "") code = await getCouponCode();
    email = _userNameEditingController.text.toLowerCase();
    if (email == "") {
      setState(() {
        _errorMessage = AppLocalizations.of(context)!.emailEmptyError;
        _loading = false;
      });
      return;
    }
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await checkFirebaseId(email);
      if (doc.exists) {
        if (!timeIsStillAllocated(doc)) {
          if (coupon == "") {
            getPurchaseFromStore(true, true);
          } else {
            validateCoupon(code, coupon);
          }
        } else {
          setState(() {
            gridSongs = new List.from(songs);
            signedIn = true;
            _loading = false;
            openSignIn = false;
          });
          return;
        }
      } else if (coupon != "") {
        validateCoupon(code, coupon);
      } else {
        getPurchaseFromStore(true, false);
      }
    } catch (error) {
      printConnectionError();
    }
  }

  Future<Map<String, int>> getWooCommerceId(
      wph.WordPressAPI api, String email) async {
    try {
      Map<String, dynamic> pageArgs = new Map();
      pageArgs["per_page"] = 50;
      pageArgs["status"] = "processing";
      final wp.WPResponse res =
          await api.fetch('orders', namespace: "wc/v2", args: pageArgs);
      try {
        Map<String, int> ret = checkForIdInData(email, res.data);
        print("ret");
        print(ret.runtimeType);

        return ret;
      } catch (error) {
        if (error.toString() == "No document") {
          int pages = res.meta!.totalPages!;
          for (int i = 2; i <= pages; i++) {
            pageArgs["page"] = i;
            final wp.WPResponse res =
                await api.fetch('orders', namespace: "wc/v2", args: pageArgs);
            try {
              return checkForIdInData(email, res.data);
            } catch (error) {
              if (error.toString() == "No document") {
                continue;
              } else {
                rethrow;
              }
            }
          }

          throw "No document";
        } else {
          rethrow;
        }
      }
    } catch (error) {
      rethrow;
    }
  }

  void assignOrderAsCompleted(wph.WordPressAPI api, int id) {
    Map<String, dynamic> params = new Map();
    params["status"] = "completed";
    api.put('orders/$id', namespace: "wc/v2", args: params);
    setState(() {
      _loading = true;
    });
  }

  void getDemoSongs() async {
    try {
      var demoCollection =
          FirebaseFirestore.instance.collection('randomFields');

      var demoName = await demoCollection.doc("allDemoSongs").get();

      demoSongNames = List.from(demoName.get("songs"));
    } catch (e) {
      demoSongNames = [];
    }
  }

  checkForIdInData(email, data) {
    for (var d in data) {
      if (d["billing"]["email"].toString().toLowerCase() == email) {
        Map<String, int> returnArgs = new Map();
        returnArgs["id"] = d["id"];
        returnArgs["quantity"] = getQuantity(d);
        return returnArgs;
      }
    }
    throw "No document";
  }

  int getQuantity(json) {
    int quantity = 0;
    var itemObjsJson = json['line_items'] as List;
    List<Item> items =
        itemObjsJson.map((itemJson) => Item.fromJson(itemJson)).toList();
    for (Item item in items) {
      if (item.sku == '110011') {
        quantity = item.quantity;
      }
    }
    return quantity;
  }

  void getPurchaseFromStore(bool newUser, bool timesUp) async {
    wph.WordPressAPI api = wph.WordPressAPI('https://ashira-music.com');
    try {
      try {
        var res = await getWooCommerceId(api, email);
        await addTimeToFirebase((res)["quantity"]!);
        assignOrderAsCompleted(api, (res)["id"]!);
      } catch (error) {
        if (error.toString() == "No document") {
          setState(() {
            _errorMessage = timesUp
                ? AppLocalizations.of(context)!.outOfTimeError
                : AppLocalizations.of(context)!.noOrderNumberError;
            _loading = false;
          });
          if (newUser) email = "";
        } else {
          printConnectionError();
        }
      }
    } catch (e) {
      printConnectionError();
    }
  }

  void validateCoupon(List<String> code, String coupon) {
    for (int i = 0; i < code.length; i++) {
      String c = code[i];
      if (coupon.contains(c) && c.length == coupon.length) {
        addTimeToFirebase(i + 1);
        return;
      }
    }
    setState(() {
      _errorMessage = AppLocalizations.of(context)!.couponError;
      _loading = false;
    });
    email = "";
    return;
  }
}

class Item {
  String sku;
  int quantity;

  Item(this.sku, this.quantity);

  factory Item.fromJson(dynamic json) {
    return Item(json['sku'] as String, json['quantity'] as int);
  }

  @override
  String toString() {
    return '{ ${this.sku}, ${this.quantity} }';
  }
}
