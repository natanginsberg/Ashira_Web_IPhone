import 'dart:async';
import 'dart:html';
import 'dart:math';
import 'dart:ui';

import 'package:ashira_flutter/model/Song.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:wordpress_api/wordpress_api.dart' as wp;

import 'Sing.dart';

class AllSongs extends StatefulWidget {
  String id;
  Timestamp endTime;
  String email;

  AllSongs(this.id, this.endTime, this.email);

  @override
  _AllSongsState createState() => _AllSongsState(id, endTime, email);
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

List<Song> songs = [];

List<String> genres = ["All Songs", "hebrew"];

List<List<Song>> searchPath = [];
List<Song> gridSongs = [];

class _AllSongsState extends State<AllSongs> {
  // Locale _locale = Locale.fromSubtags(languageCode: "he");
  final TextEditingController controller = new TextEditingController();
  bool _smartPhone = false;

  bool _showGenreBar = false;
  bool menuOpen = false;
  late bool onSearchTextChanged;

  String id;
  Timestamp endTime;
  String email;

  String currentGenre = "All Songs";

  String previousValue = "";

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  List<Song> songsClicked = [];

  bool _accessDenied = false;

  bool _overtime = false;

  late Timer timer;

  String duration = "";

  late TextEditingController _orderEditingController;

  bool _loading = false;

  String _errorMessage = "";

  bool amIHovering = false;

  late ScrollController _mainController;
  final FocusNode _focusNode = FocusNode();

  _AllSongsState(this.id, this.endTime, this.email);

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
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          body: RawKeyboardListener(
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              openWebsite();
                            },
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                          ),
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
                                          padding: const EdgeInsets.symmetric(
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
                          // todo change receive functions
                          Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.addTime + " ",
                                  style: TextStyle(
                                      fontFamily: 'SignInFont',
                                      color: Colors.white,
                                      wordSpacing: 5,
                                      height: 1.4,
                                      letterSpacing: 1.6),
                                ),
                                Container(
                                  height: 30,
                                  width: 150,
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.purple),
                                      borderRadius: BorderRadius.all(
                                          new Radius.circular(10.0))),
                                  child: TextField(
                                    onSubmitted: (value) {
                                      if (!_loading) checkOrderNumber();
                                    },
                                    textAlign: TextAlign.center,
                                    decoration: new InputDecoration(
                                      hintText: AppLocalizations.of(context)!
                                          .orderNumber,
                                      hintStyle:
                                          TextStyle(color: Color(0xFF787676)),
                                      fillColor: Colors.transparent,
                                    ),
                                    style: TextStyle(
                                        color: _errorMessage == ""
                                            ? Colors.white
                                            : Colors.red),
                                    autofocus: true,
                                    controller: _orderEditingController,
                                  ),
                                ),
                                SizedBox(
                                  width: 15,
                                ),
                                _loading
                                    ? new Container(
                                        color: Colors.transparent,
                                        width: 50.0,
                                        height: 60.0,
                                        child: new Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: new Center(
                                                child:
                                                    new CircularProgressIndicator())),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.all(
                                                new Radius.circular(10))),
                                        child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                8.0, 4, 8.0, 4),
                                            child: TextButton(
                                                onPressed: checkOrderNumber,
                                                child: Directionality(
                                                  textDirection:
                                                      TextDirection.ltr,
                                                  child: Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .submit,
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                )))),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(15, 0, 15, 0),
                                  child: MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    onEnter: (PointerEvent details) =>
                                        setState(() => amIHovering = true),
                                    onExit: (PointerEvent details) =>
                                        setState(() {
                                      amIHovering = false;
                                    }),
                                    child: RichText(
                                        text: TextSpan(
                                            text: AppLocalizations.of(context)!
                                                .placeOrder,
                                            style: TextStyle(
                                              color: amIHovering
                                                  ? Colors.blue[300]
                                                  : Colors.blue,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                launch(
                                                    'https://ashira-music.com/product/karaoke/');
                                              })),
                                  ),
                                ),
                              ]),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(30.0, 0, 30, 0),
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                AppLocalizations.of(context)!.timeRemaining +
                                    duration,
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 8.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.6,
                        height: 48,
                        decoration: BoxDecoration(
                            border:
                                Border.all(color: Color(0xFF8D3C8E), width: 2),
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
                                width: MediaQuery.of(context).size.width * 0.5,
                                height: 48,
                                child: Center(
                                  child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: TextField(
                                      style: TextStyle(color: Colors.white),
                                      textAlign: TextAlign.center,
                                      controller: controller,
                                      decoration: new InputDecoration(
                                        hintText: AppLocalizations.of(context)!
                                            .search,
                                        hintStyle:
                                            TextStyle(color: Colors.white),
                                        fillColor: Colors.transparent,
                                      ),
                                      onChanged: (String value) {
                                        if (value != previousValue)
                                          setState(() {
                                            // searchPath.add(new List.from(gridSongs));
                                            gridSongs = value.length >
                                                    previousValue.length
                                                ? getNextSong(value)
                                                : getLastSong();
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
                                    const Color(0xFF221A4D), // blue sky
                                    const Color(0xFF000000), // yellow sun
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
                                      AppLocalizations.of(context)!.playlist,
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 20),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
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
                                                child: createSongLine(
                                                    index, songsClicked[index]),
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
          )),
    );
  }

  getSongs() {
    incrementFirebaseByOne();
    FirebaseFirestore.instance
        .collection('songs')
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
        if (songs.length > 0) gridSongs = new List.from(songs);
      });
    });
  }

  void incrementFirebaseByOne() async {
    int j = 0;
    // FirebaseFirestore.instance
    //     .collection('websiteEntrances')
    //     .get()
    //     .then((QuerySnapshot querySnapshot) {
    //       querySnapshot.docs.forEach((element) {j = element.data()['entries'] + 1;
    // });});
    FirebaseFirestore.instance
        .collection('websiteEntrances')
        .doc('entries')
        .update({'entries': FieldValue.increment(1)});

    // .update({'entries': FieldValue.increment(1)});
  }

  buildGridView(List<Song> songs) {
    return GridView.builder(
        controller: _mainController,
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: _smartPhone ? 0.75 : 0.6,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20),
        itemCount: songs.length,
        itemBuilder: (BuildContext ctx, index) {
          return Container(
              alignment: Alignment.center, child: buildSongLayout(songs[index])
              // SongLayout(
              //   song: songs[index],
              //   index: index,

              );
        });
  }

  getLastSong() {
    return searchPath.removeLast().toList();
  }

  getNextSong(String value) {
    List<Song> searchedSongs = gridSongs
        .where((element) =>
            element.title.contains(value) || element.artist.contains(value))
        .toList();
    // ignore: unnecessary_statements
    searchPath.add(List.from(gridSongs));
    return searchedSongs;
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
            if (genre == "All Songs")
              gridSongs = new List.from(songs);
            else if (currentGenre != genre) {
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
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => Sing(songsPassed, id, endTime, email)));
      setState(() {
        songsClicked.clear();
      });
    }
  }

  buildSongLayout(Song song) {
    return ElevatedButton(
      style: ButtonStyle(backgroundColor:
          MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        return Colors.transparent;
      })),
      onPressed: () {
        setState(() {
          songInSongsClicked(song)
              ? songsClicked.removeWhere((element) =>
                  element.songResourceFile == song.songResourceFile)
              : songsClicked.add(song);
        });
      },
      child: Container(
        decoration: songInSongsClicked(song)
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                color: Color(0xFF8D3C8E),
                backgroundBlendMode: BlendMode.plus)
            : BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                color: Color(0xFF0A999A),
                backgroundBlendMode: BlendMode.colorDodge),
        child: Column(
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
            )
          ],
        ),
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
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
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
          Container(
            height: 40,
            width: 160,
            decoration: BoxDecoration(
                border: Border.all(color: Colors.purple),
                borderRadius: BorderRadius.all(new Radius.circular(10.0))),
            child: TextField(
              onSubmitted: (value) {
                if (!_loading) checkOrderNumber();
              },
              textAlign: TextAlign.center,
              decoration: new InputDecoration(
                hintText: AppLocalizations.of(context)!.orderNumber,
                hintStyle: TextStyle(color: Color(0xFF787676)),
                fillColor: Colors.transparent,
              ),
              style: TextStyle(fontSize: 15, color: Colors.white),
              autofocus: true,
              controller: _orderEditingController,
            ),
          ),
          SizedBox(
            width: 15,
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
                      borderRadius: BorderRadius.all(new Radius.circular(10))),
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(8.0, 4, 8.0, 4),
                      child: TextButton(
                          onPressed: checkOrderNumber,
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              AppLocalizations.of(context)!.enter,
                              style:
                                  TextStyle(fontSize: 15, color: Colors.white),
                            ),
                          ))))
        ]),
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
    if (timesUp())
      setState(() {
        _accessDenied = true;
      });
    else if (overTime()) {
      setState(() {
        _overtime = true;
      });
    } else
      playSongs();

    // collectionRef.document()
    // FirebaseFirestore.instance
    //     .collection('internetUsers')
    //     .get()
    //     .then((QuerySnapshot querySnapshot) {
    //   querySnapshot.docs.forEach((doc) {
    //     Map<String, dynamic> data = doc.data();
    //     if (email == data['email']) {
    //       valid = true;
    //       playSongs();
    //       return;
    //     }
    //   });
    //   if (!valid)
    //     setState(() {
    //       accessDenied = true;
    //     });
    // });
  }

  bool overTime() {
    DateTime currentTime = DateTime.now()
        .toUtc()
        .add(new Duration(milliseconds: getTotalLength()));
    DateTime myDateTime = endTime.toDate();
    return currentTime.compareTo(myDateTime) > 0;
  }

  bool timesUp() {
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

  void checkOrderNumber() async {

    setState(() {
      _loading = true;
    });
    String newId = _orderEditingController.text.toLowerCase();
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await checkFirebaseId(newId);
      if (doc.exists) {
        if (doc.get("email") != email) {
          setState(() {
            _errorMessage = AppLocalizations.of(context)!.matchError;
            _loading = false;
          });
          return;
        }
        if (!timeIsStillAllocated(doc)) {
          setState(() {
            _errorMessage = AppLocalizations.of(context)!.outOfTimeError;
            _loading = false;
          });
          return;
        } else {
          _accessDenied = false;
          _loading = false;
          _errorMessage = "";
          id = newId;
          return;
        }
      } else {
        try {
          final wp.WPResponse res =
              await api.fetch('orders/' + newId, namespace: "wc/v2");
          if (res.data['billing']['email'].toString().toLowerCase() == email) {
            await addTimeToFirebase(res, newId);
          } else {
            setState(() {
              _errorMessage = AppLocalizations.of(context)!.matchError;
              _loading = false;
            });
          }
          return;
        } catch (e) {
          try {
            final wp.WPResponse res =
                await api.fetch('orders', namespace: "wc/v2");
            setState(() {
              _errorMessage = AppLocalizations.of(context)!.noOrderNumberError;
              _loading = false;
            });
          } catch (e) {
            printConnectionError();
          }
        }
      }
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

  bool timeIsStillAllocated(DocumentSnapshot<Map<String, dynamic>> doc) {
    DateTime currentTime = DateTime.now().toUtc();
    endTime = doc.get("endTime");
    DateTime myDateTime = endTime.toDate();
    return currentTime.compareTo(myDateTime) < 0;
  }

  addTimeToFirebase(wp.WPResponse res, String newId) {
    int quantity = 0;
    Map<String, dynamic> json = (res.data);
    var itemObjsJson = json['line_items'] as List;
    List<Item> items =
        itemObjsJson.map((itemJson) => Item.fromJson(itemJson)).toList();
    for (Item item in items) {
      if (item.sku == '110011') {
        quantity = item.quantity;
      }
    }
    Map<String, dynamic> firestoreDoc = new Map<String, dynamic>();
    if (timesUp())
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
    email = res.data['billing']['email'];
    firestoreDoc['endTime'] = endTime;
    firestoreDoc['email'] = email;

    CollectionReference users =
        FirebaseFirestore.instance.collection('internetUsers');

    Future<void> addUser() {
      return users
          .doc(newId)
          .set(firestoreDoc)
          .then((value) => () {
                setState(() {
                  _accessDenied = false;
                  _errorMessage = "";
                  id = newId;
                  _loading = false;
                });
              })
          .catchError((error) => () {
                setState(() {
                  _errorMessage = error.toString();
                });
              });
    }

    addUser();
  }

  printConnectionError() {
    setState(() {
      _errorMessage = AppLocalizations.of(context)!.communicationError;
      _loading = false;
    });
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
