import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:math';

import 'package:ashira_flutter/model/Line.dart';
import 'package:ashira_flutter/model/Song.dart';
import 'package:ashira_flutter/utils/Parser.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// import 'package:audioplayers/audioplayers.dart';
import 'package:just_audio/just_audio.dart';

// List<CameraDescription> cameras;

class Sing extends StatefulWidget {
  final List<Song> songs;
  final String number;

  Sing(this.songs, this.number);

  // Sing({Key key, @required this.song}) : super(key: key);

  @override
  _SingState createState() => _SingState(songs, number);
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

  String number;

  bool changed = false;

  bool paused = true;

  bool disposed = false;

  _SingState(this.songs, this.number);

  Duration _progressValue = new Duration(seconds: 0);
  Duration songLength = new Duration(seconds: 1);
  int updateCounter = 0;

  int trackNumber = 0;

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

    WidgetsBinding.instance!.addObserver(this);
    parseFuture = _parseLines();
    _progressValue = new Duration(seconds: 0);
    int totalLength = 0;
    for (int i = 0; i < songs.length; i++) {
      splits.add(totalLength - (i > 0 ? 0 : 0));
      totalLength += songs[i].length - 0;
    }
    songLength = new Duration(milliseconds: totalLength - 150);
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
      allLines.add((new Parser()).parse((lyrics).split("\r\n")));
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
        // {
        //   backButton();
        //   return Future.value(false);
        // },
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
            child: Padding(
              padding: const EdgeInsets.all(25.0),
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.purple),
                    borderRadius: BorderRadius.all(new Radius.circular(20.0))),
                child: Stack(children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: SafeArea(
                          child: Text(
                            songs[trackNumber].title,
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),

                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height:
                                      MediaQuery.of(context).size.height / 3,
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
                                          image: NetworkImage(songs[trackNumber]
                                              .imageResourceFile),
                                        );
                                      }
                                    },
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 20, 0, 0),
                                  child: Container(
                                    width:
                                        MediaQuery.of(context).size.width / 3,
                                    height: 50,
                                    decoration: BoxDecoration(
                                        border:
                                            Border.all(color: Colors.purple),
                                        borderRadius: BorderRadius.all(
                                            new Radius.circular(30.0))),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          8.0, 4, 8, 4),
                                      child: Center(
                                        child: ProgressBar(
                                          total: songLength,
                                          progressBarColor: Colors.blue,
                                          progress: _progressValue,
                                          thumbColor: Colors.white,
                                          timeLabelTextStyle:
                                              TextStyle(color: Colors.white),
                                          barHeight: 4,
                                          thumbRadius: 9,
                                          timeLabelLocation:
                                              TimeLabelLocation.sides,
                                          onSeek: (Duration duration) {
                                            _progressValue = duration;
                                            updateUI(duration, false, true,
                                                trackNumber);
                                            audioPlayer.seek(
                                                new Duration(
                                                    milliseconds: duration
                                                            .inMilliseconds -
                                                        splits[trackNumber]),
                                                index: trackNumber);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                isPlaying && !paused
                                    ? IconButton(
                                        iconSize: 32,
                                        icon: Icon(
                                          Icons.pause,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          pause();
                                        })
                                    : songFinished
                                        ? IconButton(
                                            iconSize: 32,
                                            icon: Icon(
                                              Icons.replay_rounded,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              restart();
                                            })
                                        : IconButton(
                                            iconSize: 32,
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
                            Center(
                              child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.purple),
                                    borderRadius: BorderRadius.all(
                                        new Radius.circular(15))),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(15.0),
                                    child: Image(
                                      width:
                                          MediaQuery.of(context).size.width / 3,
                                      fit: BoxFit.fitWidth,
                                      image: NetworkImage(
                                          songs[trackNumber].imageResourceFile),
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
            ),
          ),
        ),
      ),
    );
  }

  void play() async {
    // getRichTextSize();
    audioPlayer.play();
    // Future<int> duration = audioPlayer.getDuration();
    // duration.then((value) =>
    // songLength = value);

    // if (result == 1) {
    setState(() {
      songFinished = false;
      isPlaying = true;
      paused = false;
    });

    // audioPlayer.currentIndexStream.listen((event) {
    //   if (!changed)
    //     setState(() {
    //       trackNumber = event!.ceil();
    //       lines = allLines[trackNumber];
    //       resetRows(new Duration(milliseconds: 1));
    //     });
    //   else
    //     changed = false;
    // });
    audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed)
        if (currentLineIndex == lines.length - 1 &&
            trackNumber == songs.length - 1
        // songTime * 1000 >= songs[trackNumber].length - 150
        ) {
          setState(() {
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

    // audioPlayer.onAudioPositionChanged.listen((Duration p) => {updateUI(p)});
  }

  buildListView(List<Line> lines) {
    return Column(children: [
      Expanded(
        child: SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          width: MediaQuery.of(context).size.width / 3,
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
    return Container(
      height: 41,
      child: Center(
        child: Stack(children: [
          RichText(
              text: TextSpan(
                  style: TextStyle(fontSize: 34, color: Colors.white),
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
                    style: TextStyle(color: Colors.white30, fontSize: 34))
              ])),
          RichText(
              text: TextSpan(
                  style: TextStyle(fontSize: 34, color: Colors.white),
                  children: [
                TextSpan(
                    text: line.past, style: TextStyle(color: Colors.white)),
                TextSpan(
                    text: line.future,
                    style: TextStyle(color: Colors.white30, fontSize: 34))
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
          if (newTrack != trackNumber) changeSong(newTrack);
          resetRows(new Duration(
              milliseconds: p.inMilliseconds - splits[trackNumber]));
          break;
        } else if (i == splits.length - 1) {
          int newTrack = i;
          if (newTrack != trackNumber) changeSong(newTrack);
          resetRows(new Duration(
              milliseconds: p.inMilliseconds - splits[trackNumber]));
        }
      }
    } else {
      for (int i = splits.length - 1; i >= 0; i--) {
        if (splits[i] <= p.inMilliseconds + splits[trackNumber] + 200) {
          if (i > trackNumber) {
            int newTrack = i;
            changeAudio(newTrack);
            changeSong(newTrack);
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
    print(currentLineIndex.toString() + " " + track.toString());
    animateLyrics(animation);
    print("this is the songtime " + songTime.toString() + " this is the progress " + songs[trackNumber].length.toString());
    // if (currentLineIndex == lines.length - 1 &&
    //     trackNumber == songs.length - 1 && audioPlayer.processingStateStream == ProcessingState.completed
    //     // songTime * 1000 >= songs[trackNumber].length - 150
    // ) {
    //   setState(() {
    //     isPlaying = false;
    //     songFinished = true;
    //     timer.cancel();
    //   });
    // }
    // lines.first.past = "hello";
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
    play();
  }

  void resetLines(double time) {
    setState(() {
      print("the lines were reset");
      for (Line line in lines) {
        line.resetLine(time);
      }
    });
  }

  void resetAllLines() {
    setState(() {
      for (List<Line> songsLines in allLines)
        for (Line line in songsLines) {
          line.resetLine(0.0);
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
      print("song was changed from " +
          trackNumber.toString() +
          " " +
          newTrack.toString());
      trackNumber = newTrack;
      lines = allLines[trackNumber];
    });
  }

  tonePicker() {
    return Center(
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
              " באיזה טון אתה שר",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(children: <Widget>[
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            Color(0xFF0D47A1),
                            Color(0xFF1976D2),
                            Color(0xFF42A5F5),
                          ],
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
                        child: const Text(
                          "גבר",
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              letterSpacing: 1.5),
                        )),
                  ),
                ])),
            ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(children: <Widget>[
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            Color(0xFF630DA1),
                            Color(0xFF7A37E5),
                            Color(0xFFB47DF1),
                          ],
                        ),
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
                        child: const Text(
                          "אשה",
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              letterSpacing: 1.5),
                        )),
                  ),
                ])),
            ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(children: <Widget>[
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            Color(0xFF0D47A1),
                            Color(0xFF19D247),
                            Color(0xFFF5AD42),
                          ],
                        ),
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
                        child: const Text(
                          "ילד",
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              letterSpacing: 1.5),
                        )),
                  ),
                ])),
          ],
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

  void  updateLyrics(double songTime, int playingTime) {
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
            line.updateLyrics(time);
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
      currentLineIndex * 41.toDouble(),
      duration: animation
          ? new Duration(milliseconds: 400)
          : new Duration(milliseconds: 20),
      curve: Curves.decelerate,
    );
  }
}

// class WebcamPage extends StatefulWidget {
//   String number;
//
//   WebcamPage(this.number);
//
//   @override
//   _WebcamPageState createState() => _WebcamPageState(number);
// }
//
// class _WebcamPageState extends State<WebcamPage> {
//   // Webcam widget to insert into the tree
//   late Widget _webcamWidget;
//
//   // VideoElement
//   VideoElement _webcamVideoElement = VideoElement();
//
//   String number;
//
//   _WebcamPageState(this.number);
//
//   @override
//   void dispose() {
//     switchCameraOff();
//     super.dispose();
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     // size = MediaQuery.of(context).size;
//     // deviceRatio = size.width / size.height;
//     // Create a video element which will be provided with stream source
//     _webcamVideoElement = VideoElement();
//     _webcamWidget = HtmlElementView(key: UniqueKey(), viewType: number);
//
//     // Register an webcam
//     if (!ui.platformViewRegistry.registerViewFactory(number,
//         (int viewId) => _webcamVideoElement)) // return _webcamVideoElement;
//       print("this is still causeing an issue" + number);
//
//     window.navigator.mediaDevices!
//         .getUserMedia({"video": true}).then((MediaStream stream) {
//       _webcamVideoElement
//         ..srcObject = stream
//         ..autoplay = true;
//       return _webcamVideoElement;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) => Scaffold(
//           body: Center(
//         child: Container(
//             decoration: BoxDecoration(
//                 gradient: RadialGradient(
//               center: Alignment.center,
//               radius: 0.8,
//               colors: [
//                 const Color(0xFF221A4D), // blue sky
//                 const Color(0xFF000000), // yellow sun
//               ],
//             )),
//             width: MediaQuery.of(context).size.width,
//             height: MediaQuery.of(context).size.height - 300,
//             child: _webcamWidget),
//       ));
//
//   switchCameraOff() {
//     if (_webcamVideoElement.srcObject!.active!) {
//       var tracks = _webcamVideoElement.srcObject!.getTracks();
//
//       //stopping tracks and setting srcObject to null to switch camera off
//       _webcamVideoElement.srcObject = null;
//
//       tracks.forEach((track) {
//         track.stop();
//       });
//     }
//   }
// }
