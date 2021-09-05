import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';
import 'dart:ui';

import 'package:ashira_flutter/model/Line.dart';
import 'package:ashira_flutter/model/Song.dart';
import 'package:ashira_flutter/utils/Parser.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock/wakelock.dart';
import 'package:wordpress_api/wordpress_api.dart' as wp;
// List<CameraDescription> cameras;

class Sing extends StatefulWidget {
  final List<Song> songs;
  final String id;

  Timestamp endTime;
  final String email;

  Sing(this.songs, this.id, this.endTime, this.email);

  // Sing({Key key, @required this.song}) : super(key: key);

  @override
  _SingState createState() => _SingState(songs, id, endTime, email);
}

class _SingState extends State<Sing> with WidgetsBindingObserver {
  int MAN = 0;
  int WOMAN = 1;
  int KID = 2;
  var songPicked = false;
  List<Song> songs = [];
  List<int> splits = [];
  AudioPlayer audioPlayer = AudioPlayer();
  bool loading = false;
  List<List<Line>> allLines = [];
  List<Line> lines = [];

  late Future parseFuture;

  final ScrollController listViewController = new ScrollController();
  int currentLineIndex = 0;
  Map<int, int> sizeOfLines = new Map();
  bool isPlaying = false;

  late Timer timer;

  bool songFinished = false;

  String id;

  String message = "";

  bool changed = false;

  bool paused = true;

  bool disposed = false;

  bool _accessDenied = false;

  bool personalMoishie = false;

  List<dynamic> backgroundPictures = [];

  String error = '';

  late TextEditingController _orderEditingController;

  bool _loading = false;

  String _errorMessage = "";

  Random random = new Random();
  num randomNumber = 0;

  Timestamp endTime;

  String email;

  bool amIHovering = false;

  _SingState(this.songs, this.id, this.endTime, this.email);

  Duration _progressValue = new Duration(seconds: 0);
  Duration songLength = new Duration(seconds: 1);
  int updateCounter = 0;

  int trackNumber = 0;

  // Wakelock.toggle(enable: isPlaying);

  @override
  Future<void> dispose() async {
    // TODO: implement dispose
    timer.cancel();
    disposed = true;
    if (audioPlayer.position.inSeconds > 0) {
      pause();
      await audioPlayer.stop();
    }
    audioPlayer.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    randomNumber = random.nextInt(5) + 1;
    WidgetsBinding.instance!.addObserver(this);
    parseFuture = _parseLines();
    _progressValue = new Duration(seconds: 0);
    int totalLength = 0;
    for (int i = 0; i < songs.length; i++) {
      splits.add(totalLength - (i > 0 ? 0 : 0));
      totalLength += songs[i].length - 0;
    }
    songLength = new Duration(milliseconds: totalLength - 150);
    // checkFirestorePermissions(false);
    if (this.id == 'מוישי') {
      personalMoishie = true;
    }
    createAllBackgroundPictureArray();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      //stop your audio player
      pause();
      timer.cancel();
    }

    // } else if (state == AppLifecycleState.resumed) {
    //   play();
    //   }
  }

  _parseLines() async {
    for (int i = 0; i < songs.length; i++) {
      Song song = songs[i];
      final response = await http.get(Uri.parse(song.textResourceFile));

      String lyrics = utf8.decode(response.bodyBytes);
      allLines.add(
          (new Parser()).parse((lyrics).split("\r\n"), this.id == 'מוישי'));
    }
    lines = allLines[0];
    return allLines[0];
    // return await http.read(Uri.parse(song.textResourceFile));
  }

  void backButton() {
    timer.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WillPopScope(
          onWillPop: () {
            timer.cancel();
            disposed = true;
            return Future.value(true);
          },
          child: Scaffold(
            body: Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                  gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  const Color(0xFF221A4D), // blue sky
                  const Color(0xFF000000), // yellow sun
                ],
              )),
              child: !_accessDenied
                  ? Padding(
                      padding:
                          const EdgeInsets.fromLTRB(15.0, 25.0, 15.0, 25.0),
                      child: Container(
                        decoration: BoxDecoration(
                            image: getImage(),
                            border: Border.all(color: Colors.purple),
                            borderRadius:
                                BorderRadius.all(new Radius.circular(20.0))),
                        child: Stack(children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(width: 390.0, height: 0.0),
                                  Center(
                                    child: SafeArea(
                                      child: Text(
                                        songs[trackNumber].title,
                                        style: TextStyle(
                                            fontSize: 18, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 390,
                                    height: 40,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Flexible(
                                          child: RichText(
                                            text: TextSpan(children: [
                                              TextSpan(
                                                  text: AppLocalizations.of(
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
                                                                !personalMoishie;
                                                          });
                                                        }),
                                            ]),
                                          ),
                                        ),
                                        Theme(
                                          data: ThemeData(
                                              unselectedWidgetColor:
                                                  Colors.black),
                                          child: Checkbox(
                                            //    <-- label
                                            value: !personalMoishie,
                                            onChanged: (newValue) {
                                              setState(() {
                                                personalMoishie =
                                                    !personalMoishie;
                                              });
                                            },
                                          ),
                                        ),
                                        Flexible(
                                          child: RichText(
                                            text: TextSpan(children: [
                                              TextSpan(
                                                  text: AppLocalizations.of(
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
                                                                !personalMoishie;
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
                                                personalMoishie =
                                                    !personalMoishie;
                                              });
                                            },
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),

                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .height /
                                              2,
                                          child: FutureBuilder(
                                            future: parseFuture,
                                            builder: (context, snapShot) {
                                              if (snapShot.hasData) {
                                                return buildListView(
                                                    (allLines[trackNumber]));
                                              } else if (snapShot.hasError) {
                                                return Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red,
                                                );
                                              } else {
                                                return Image(
                                                  fit: BoxFit.fill,
                                                  image: NetworkImage(
                                                      songs[trackNumber]
                                                          .imageResourceFile),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              0, 20, 0, 0),
                                          child: Container(
                                            width: isSmartphone()
                                                ? MediaQuery.of(context)
                                                        .size
                                                        .width -
                                                    60
                                                : personalMoishie
                                                    ? MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        2
                                                    : MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        3,
                                            height: 50,
                                            decoration: BoxDecoration(
                                                border: Border.all(
                                                    color: Colors.purple),
                                                borderRadius: BorderRadius.all(
                                                    new Radius.circular(30.0))),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      8.0, 4, 8, 4),
                                              child: Center(
                                                child: ProgressBar(
                                                  total: songLength,
                                                  progressBarColor: Colors.blue,
                                                  progress: _progressValue,
                                                  thumbColor: Colors.white,
                                                  timeLabelTextStyle: TextStyle(
                                                      color: Colors.white),
                                                  barHeight: 4,
                                                  thumbRadius: 9,
                                                  timeLabelLocation:
                                                      TimeLabelLocation.sides,
                                                  onSeek: (Duration duration) {
                                                    _progressValue = duration;
                                                    updateUI(duration, false,
                                                        true, trackNumber);
                                                    audioPlayer.seek(
                                                        new Duration(
                                                            milliseconds: duration
                                                                    .inMilliseconds -
                                                                splits[
                                                                    trackNumber]),
                                                        index: trackNumber);
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        isPlaying && !paused
                                            ? IconButton(
                                                iconSize: 50,
                                                icon: Icon(
                                                  Icons.pause,
                                                  color: Colors.white,
                                                ),
                                                onPressed: () {
                                                  pause();
                                                })
                                            : songFinished
                                                ? IconButton(
                                                    iconSize: 50,
                                                    icon: Icon(
                                                      Icons.replay_rounded,
                                                      color: Colors.white,
                                                    ),
                                                    onPressed: () {
                                                      restart();
                                                      setState(() {
                                                        songFinished = false;
                                                      });
                                                    })
                                                : IconButton(
                                                    iconSize: 50,
                                                    icon: Icon(
                                                      Icons.play_arrow,
                                                      color: Colors.white,
                                                    ),
                                                    onPressed: () {
                                                      play();
                                                    },
                                                  ),
                                        SizedBox(
                                          height: 20,
                                        )
                                      ],
                                    ),
                                    if (!personalMoishie && !isSmartphone())
                                      Center(
                                        child: Container(
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.purple),
                                              borderRadius: BorderRadius.all(
                                                  new Radius.circular(15))),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(15.0),
                                              child: Image(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    3,
                                                fit: BoxFit.fitWidth,
                                                image: NetworkImage(
                                                    songs[trackNumber]
                                                        .imageResourceFile),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                  ],
                                ),
                              ),
                              // Container(
                              //     height: MediaQuery.of(context).size.height - 300,
                              //     child: kIsWeb ? WebcamPage(number) : Icon(Icons.cloud))
                            ],
                          ),
                          if (!songPicked) tonePicker()
                        ]),
                      ),
                    )
                  : expireWording(),
            ),
          )),
    );
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
        //todo add box to enter order # and add link to get order #
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

  bool timesUp() {
    DateTime currentTime = DateTime.now().toUtc();
    DateTime myDateTime = endTime.toDate();
    return currentTime.compareTo(myDateTime) > 0;
  }

  void play() async {
    if (timesUp()) {
      setState(() {
        _accessDenied = true;
      });
    } else {
      audioPlayer.play();
      setState(() {
        Wakelock.enable();
        songFinished = false;
        isPlaying = true;
        paused = false;
      });

      audioPlayer.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) if (currentLineIndex ==
                    lines.length - 1 &&
                trackNumber == songs.length - 1
            // songTime * 1000 >= songs[trackNumber].length - 150
            ) {
          setState(() {
            Wakelock.disable();
            isPlaying = false;
            songFinished = true;
            timer.cancel();
          });
        }
      });

      timer = Timer.periodic(
          Duration(milliseconds: 100),
          (Timer t) => updateUI(
              audioPlayer.position, true, false, audioPlayer.currentIndex!));
    }
  }

  buildListView(List<Line> lines) {
    return Column(children: [
      Expanded(
        child: SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          width: isSmartphone()
              ? MediaQuery.of(context).size.width - 30
              : personalMoishie
                  ? MediaQuery.of(context).size.width - 60
                  : MediaQuery.of(context).size.width / 3,
          child: ListView.builder(
              controller: this.listViewController,
              itemCount: lines.length,
              itemBuilder: (BuildContext ctx, index) {
                return Container(
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: createTextWidget(index, line: lines[index]),
                );
              }),
        ),
      )
    ]);
  }

  createTextWidget(int index, {required Line line}) {
    double size = personalMoishie ? MediaQuery.of(context).size.height / 6 : 34;
    Color pastFontColor = personalMoishie ? Colors.green : Colors.white;
    Color futureFontColor = personalMoishie ? Colors.white : Colors.white30;
    FontWeight weight = personalMoishie ? FontWeight.bold : FontWeight.normal;
    return Container(
      height: personalMoishie
          ? (MediaQuery.of(context).size.height / 4).toDouble()
          : 41,
      child: Center(
        child: Stack(children: [
          RichText(
              text: TextSpan(
                  style: TextStyle(
                      fontSize: size, color: pastFontColor, fontWeight: weight),
                  children: [
                TextSpan(
                    text: line.past,
                    style: TextStyle(
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 3
                        ..color = Colors.purple,
                    )),
                TextSpan(
                    text: line.future,
                    style: TextStyle(
                        color: futureFontColor,
                        fontSize: size,
                        fontWeight: weight))
              ])),
          RichText(
              text: TextSpan(
                  style: TextStyle(
                      fontSize: size, color: pastFontColor, fontWeight: weight),
                  children: [
                TextSpan(
                    text: line.past,
                    style: TextStyle(color: pastFontColor, fontWeight: weight)),
                TextSpan(
                    text: line.future,
                    style: TextStyle(
                        color: futureFontColor,
                        fontSize: size,
                        fontWeight: weight))
              ]))
        ]),
      ),
    );
  }

  updateUI(Duration p, bool animation, bool seek, int track) {
    if (disposed || paused) {
      timer.cancel();
      return;
    }
    if (track != trackNumber) {
      return;
    }
    updateCounter++;
    if (seek) {
      for (int i = 0; i < splits.length; i++) {
        if (splits[i] > p.inMilliseconds) {
          int newTrack = i - 1;
          if (newTrack != trackNumber) {
            changeSong(newTrack);
          }
          resetRows(new Duration(
              milliseconds: p.inMilliseconds - splits[trackNumber]));
          break;
        } else if (i == splits.length - 1) {
          int newTrack = i;
          if (newTrack != trackNumber) {
            changeSong(newTrack);
          }
          resetRows(new Duration(
              milliseconds: p.inMilliseconds - splits[trackNumber]));
        }
      }
    } else {
      for (int i = splits.length - 1; i >= 0; i--) {
        if (splits[i] <= p.inMilliseconds + splits[trackNumber] + 200) {
          if (i > trackNumber) {
            int newTrack = i;
            changeSong(newTrack);
            changeAudio(newTrack);
            resetRows(new Duration(milliseconds: 1));
            p = new Duration(milliseconds: 1);
          }
          break;
        }
      }
    }
    double songTime =
        (p.inMilliseconds - (seek ? splits[trackNumber] : 0)) / 1000.toDouble();
    int playingTime = p.inMilliseconds + (seek ? 0 : splits[trackNumber]);

    updateLyrics(songTime, playingTime);
    // print(currentLineIndex.toString() + " " + track.toString());
    animateLyrics(animation);

    checkTimeToLowerVolume(songTime);
    if (updateCounter == 3)
      updateProgressBar(new Duration(milliseconds: playingTime.toInt()));
  }

  void updateProgressBar(Duration p) {
    setState(() {
      updateCounter = 0;
      _progressValue = p;
    });
  }

  pause() {
    audioPlayer.pause();
    timer.cancel();
    setState(() {
      Wakelock.disable();
      isPlaying = false;
      paused = true;
    });
  }

  void restart() {
    pause();
    changeSong(0);
    changeAudio(0);
    audioPlayer.seek(Duration(milliseconds: 1));
    resetLines(0.0);
    listViewController.animateTo(
      0.0,
      duration: new Duration(milliseconds: 100),
      curve: Curves.decelerate,
    );
    // checkFirestorePermissions(true);
    // play();
  }

  void resetLines(double time) {
    setState(() {
      //print("the lines were reset");
      for (Line line in lines) {
        line.resetLine(time, personalMoishie);
      }
    });
  }

  void resetAllLines() {
    setState(() {
      for (List<Line> songsLines in allLines)
        for (Line line in songsLines) {
          line.resetLine(0.0, personalMoishie);
        }
    });
  }

  void resetRows(Duration duration) {
    resetLines(duration.inSeconds.toDouble());
  }

  setSong(int person) {
    audioPlayer.setAudioSource(
      ConcatenatingAudioSource(
        // Start loading next item just before reaching it.
        useLazyPreparation: true, // default
        // Customise the shuffle algorithm.
        shuffleOrder: DefaultShuffleOrder(), // default
        // Specify the items in the playlist.
        children: [
          for (int i = 0; i < songs.length; i++)
            AudioSource.uri(Uri.parse(setUrl(person, songs[i]))),
        ],
      ),
      // Playback will be prepared to start from track1.mp3
      initialIndex: 0, // default
      // Playback will be prepared to start from position zero.
      initialPosition: Duration.zero, // default
    );
    // audio
    //     changed = false;
    // });
    setState(() {
      songPicked = true;
    });
  }

  String setUrl(int person, Song song) {
    if (person == MAN)
      return song.songResourceFile;
    else if (person == WOMAN)
      return song.womanToneResourceFile;
    else
      return song.kidToneResourceFile;
  }

  void changeSong(int newTrack) {
    // if (newTrack != trackNumber) {
    changed = true;
    setState(() {
      //   print("song was changed from " +
      //     trackNumber.toString() +
      //   " " +
      // newTrack.toString());
      trackNumber = newTrack;
      lines = allLines[trackNumber];
    });
  }

  tonePicker() {
    return Directionality(
      textDirection: TextDirection.rtl,
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
              Text(
                " באיזה טון אתה שר?",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(children: <Widget>[
                    Positioned.fill(
                      child: Container(
                        decoration: personalMoishie
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
                        decoration: personalMoishie
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
                        decoration: personalMoishie
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

  void changeAudio(int newTrack) {
    audioPlayer.seek(Duration(milliseconds: 1), index: newTrack);
  }

  void checkTimeToLowerVolume(double time) {
    if (songs[trackNumber].length - time * 1000 < 6000)
      audioPlayer.setVolume(
          max((songs[trackNumber].length / 1000 - time - 1) * 0.2, 0));
    // else if (trackNumber > 0 && time < 5)
    //   audioPlayer.setVolume(max(time * 0.2, 0));
    else
      audioPlayer.setVolume(1.0);
  }

  void updateLyrics(double songTime, int playingTime) {
    double time = songTime;
    // (p.inMilliseconds - (seek ? splits[trackNumber] : 0)) / 1000.toDouble();
    for (int j = 0; j < lines.length; j++) {
      Line line = lines[j];
      if (line.isIn(time)) {
        currentLineIndex = j;
        // if (line.needToUpdateLyrics(time)) {
        updateCounter = 0;
        if (!disposed)
          setState(() {
            _progressValue = new Duration(milliseconds: playingTime);
            line.updateLyrics(time, personalMoishie);
            isPlaying = true;
          });
        // }
        break;
      } else {
        if (line.isAfter(time)) {
          currentLineIndex = j - 1;
          break;
        }
        if (j == lines.length - 1) currentLineIndex = j;
      }
    }
  }

  void animateLyrics(bool animation) {
    listViewController.animateTo(
      personalMoishie
          ? currentLineIndex *
              (MediaQuery.of(context).size.height / 4).toDouble()
          : currentLineIndex * 41.toDouble(),
      duration: animation
          ? new Duration(milliseconds: 400)
          : new Duration(milliseconds: 20),
      curve: Curves.decelerate,
    );
  }

  createAllBackgroundPictureArray() async {
    // CollectionReference collectionRef =
    //     FirebaseFirestore.instance.collection('collectionName');
    final databaseReference = FirebaseFirestore.instance;

    try {
      var doc = databaseReference.collection('pictures').doc('backgroundPics');
      var picDoc = await doc.get();
      if (picDoc.exists) {
        setState(() {
          backgroundPictures = picDoc.get("pics");
          randomNumber = random.nextInt(backgroundPictures.length) + 1;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  bool isSmartphone() {
    final userAgent = html.window.navigator.userAgent.toString().toLowerCase();
    return (userAgent.contains("iphone") ||
        userAgent.contains("android") ||
        userAgent.contains("ipad") ||
        (html.window.navigator.platform!.toLowerCase().contains("macintel") &&
            html.window.navigator.maxTouchPoints! > 0));
  }

  getImage() {
    if (personalMoishie && backgroundPictures.length > 0) {
      return DecorationImage(
        fit: BoxFit.fill,
        image: NetworkImage(backgroundPictures[
            (((trackNumber + randomNumber) * randomNumber) %
                    backgroundPictures.length)
                .toInt()]),
      );
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
    endTime = Timestamp.fromDate(DateTime.now().add(Duration(hours: quantity)));
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
                  _loading = false;
                  id = newId;
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
