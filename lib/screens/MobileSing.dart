import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:ashira_flutter/customWidgets/LoadingIndicator.dart';
import 'package:ashira_flutter/model/DisplayOptions.dart';
import 'package:ashira_flutter/model/Line.dart';
import 'package:ashira_flutter/model/Song.dart';
import 'package:ashira_flutter/utils/AppleSignIn.dart';
import 'package:ashira_flutter/utils/GenerateRandomString.dart';
import 'package:ashira_flutter/utils/Parser.dart';
import 'package:ashira_flutter/utils/firetools/FirebaseService.dart';
import 'package:ashira_flutter/utils/firetools/UserHandler.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show SystemChrome, rootBundle;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:flutter_ffmpeg/log.dart';
import 'package:flutter_ffmpeg/statistics.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:headset_connection_event/headset_event.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock/wakelock.dart';

import 'AllSongs.dart';
// List<CameraDescription> cameras;

class MobileSing extends StatefulWidget {
  final List<Song> songs;
  final String counter;

  MobileSing(this.songs, this.counter);

  // Sing({Key key, @required this.song}) : super(key: key);

  @override
  _MobileSingState createState() => _MobileSingState(songs, counter);
}

class _MobileSingState extends State<MobileSing> with WidgetsBindingObserver {
  int MAN = 0;
  int WOMAN = 1;
  int KID = 2;
  final Object? STAY_ON_PAGE = "stay on page";

  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  var songPicked = false;
  List<Song> songs = [];
  List<int> splits = [];
  AudioPlayer audioPlayer = AudioPlayer();
  bool loading = false;
  List<List<Line>> allLines = [];
  List<Line> lines = [];

  late Future parseFuture;

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  FirebaseService service = new FirebaseService();


  final ScrollController listViewController = new ScrollController();
  int currentLineIndex = 0;
  Map<int, int> sizeOfLines = new Map();
  bool isPlaying = false;

  Timer timer = Timer(new Duration(hours: 30), () {});

  bool songFinished = false;

  String message = "";

  bool changed = false;

  bool paused = true;

  bool disposed = false;

  List<dynamic> backgroundPictures = [];

  String error = '';

  bool _loading = false;

  Random random = new Random();
  num randomNumber = 0;

  bool amIHovering = false;

  var quantity = 0;

  var timeChanged = 0;

  num lastTimeChanged = 0;

  String counter;

  bool cameraReady = false;

  var songStarted = false;

  bool songStopped = false;

  String audioDownloadPath = "";

  double delay = 0;

  String concatedFile = "";

  int countdown = 0;

  Timer startTimer = Timer(new Duration(hours: 30), () {});

  bool playPressed = false;

  String watermarkPath = "";

  double _sliderValue = 0.0;

  bool waitingForDownloadToWatch = false;

  bool fileDownloaded = false;

  bool readyToDownload = false;

  CancelToken cancelToken = CancelToken();

  bool backButtonPressed = false;

  int wordsSung = 0;
  int silentWords = 0;

  bool noiseRecorded = false;

  late FirebaseAuth _firebaseAuth;

  _MobileSingState(this.songs, this.counter);

  Duration _progressValue = new Duration(seconds: 0);
  Duration songLength = new Duration(seconds: 1);
  int updateCounter = 0;

  int trackNumber = 0;

  List<CameraDescription> cameras = [];

  CameraController? controller;
  XFile? imageFile;
  XFile? videoFile;

  // VideoPlayerController? videoController;
  VoidCallback? videoPlayerListener;
  bool enableAudio = true;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _currentExposureOffset = 0.0;
  late AnimationController _flashModeControlRowAnimationController;
  late Animation<double> _flashModeControlRowAnimation;
  late AnimationController _exposureModeControlRowAnimationController;
  late Animation<double> _exposureModeControlRowAnimation;
  late AnimationController _focusModeControlRowAnimationController;
  late Animation<double> _focusModeControlRowAnimation;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  double popupHeight = 450;
  double popupWidth = 330;

  HeadsetEvent headsetPlugin = new HeadsetEvent();
  HeadsetState headsetEvent = HeadsetState.DISCONNECT;

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;

  final FlutterFFmpeg _flutterFFmpeg = new FlutterFFmpeg();
  final FlutterFFmpegConfig _flutterFFmpegConfig = new FlutterFFmpegConfig();

  final FlutterFFprobe _flutterFFprobe = new FlutterFFprobe();

  // Wakelock.toggle(enable: isPlaying);

  @override
  Future<void> dispose() async {
    if (timer.isActive) timer.cancel();
    if (startTimer.isActive) startTimer.cancel();
    disposed = true;
    if (isPlaying) {
      pause();
      await audioPlayer.stop();
    }
    if (controller != null) {
      controller!.dispose();
      controller = null;
    }
    cancelToken.cancel();
    audioPlayer.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    randomNumber = random.nextInt(7) + 1;
    WidgetsBinding.instance!.addObserver(this);
    parseFuture = _parseLines();
    _progressValue = new Duration(seconds: 0);
    int totalLength = 0;
    for (int i = 0; i < songs.length; i++) {
      splits.add(totalLength);
      totalLength += songs[i].length;
    }
    getCameras();
    songLength = new Duration(milliseconds: totalLength - 150);
    // checkFirestorePermissions(false);

    createAllBackgroundPictureArray();
    _flutterFFmpegConfig.enableStatisticsCallback(this.statisticsCallback);

    headsetPlugin.getCurrentState.then((_val) {
      setState(() {
        if (_val != null) headsetEvent = _val;
      });
    });

    /// Detect the moment headset is plugged or unplugged
    headsetPlugin.setListener((_val) {
      setState(() {
        print(_val);
        headsetEvent = _val;
      });
    });
  }

  void getCameras() async {
    print(" get here");
    try {
      WidgetsFlutterBinding.ensureInitialized();
      cameras = await availableCameras();
      controller = CameraController(
        cameras[1],
        ResolutionPreset.high,
        enableAudio: enableAudio,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      controller!.initialize().then((value) {
        setState(() {
          cameraReady = true;
        });
      });
    } on CameraException catch (e) {
      print("Error occured " + e.toString());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      //stop your audio player
      pause();
      timer.cancel();
    }
  }

  _parseLines() async {
    for (int i = 0; i < songs.length; i++) {
      Song song = songs[i];
      final response = await http.get(Uri.parse(song.textResourceFile));

      String lyrics = utf8.decode(response.bodyBytes);
      allLines
          .add((new Parser()).parse((lyrics).split("\r\n"), email == 'מוישי'));
    }
    // print(allLines);
    lines = allLines[0];
    return allLines[0];
  }

  void backButton() {
    backButtonPressed = true;
    timer.cancel();
    if (startTimer.isActive) startTimer.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    popupHeight = MediaQuery.of(context).size.height * 0.7;
    popupWidth = MediaQuery.of(context).size.width * 0.7;
    return phonePage();
  }

  phonePage() {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
                child: Stack(children: [
                  Column(
                    children: [
                      SafeArea(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            height: MediaQuery.of(context).size.height / 8,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      songs[trackNumber].artist,
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.white),
                                    ),
                                    Text(
                                      songs[trackNumber].title,
                                      style: TextStyle(
                                          fontSize: 18, color: Colors.white),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Image(
                                  fit: BoxFit.fitWidth,
                                  image: NetworkImage(
                                      songs[trackNumber].imageResourceFile),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Stack(
                        children: [
                          Container(
                            height: MediaQuery.of(context).size.height / 5,
                            width: MediaQuery.of(context).size.width - 30,
                            child: FutureBuilder(
                              future: parseFuture,
                              builder: (context, snapShot) {
                                if (snapShot.hasData) {
                                  return buildListView((allLines[trackNumber]));
                                } else if (snapShot.hasError) {
                                  return Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                  );
                                } else {
                                  return Image(
                                    fit: BoxFit.fill,
                                    image: NetworkImage(
                                        songs[trackNumber].imageResourceFile),
                                  );
                                }
                              },
                            ),
                          ),
                          if (!(playPressed || songStarted) &&
                              headsetEvent == HeadsetState.DISCONNECT)
                            Container(
                              color: Colors.black,
                              height: MediaQuery.of(context).size.height / 5,
                              width: MediaQuery.of(context).size.height - 30,
                              child: Center(
                                child: Text(
                                    AppLocalizations.of(context)!
                                        .attachEarphones,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 17)),
                              ),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 0, 8, 0),
                        child: Center(
                          child: ProgressBar(
                            total: songLength,
                            progressBarColor: Colors.blue,
                            progress: _progressValue,
                            thumbRadius: 1,
                            timeLabelTextStyle: TextStyle(color: Colors.white),
                            barHeight: 8,
                            timeLabelLocation: TimeLabelLocation.sides,
                          ),
                        ),
                      ),
                      if (cameraReady)
                        Expanded(
                            child: Container(
                                child: Align(
                                    alignment: Alignment.topCenter,
                                    child: _cameraPreviewWidget()))),
                    ],
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_sharp,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            backButton();
                          },
                        ),
                      ),
                    ),
                  ),
                  if (!playPressed)
                    Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _loading
                            ? new Container(
                                color: Colors.transparent,
                                width: 60.0,
                                height: 60.0,
                                child: new Padding(
                                    padding: const EdgeInsets.all(5.0),
                                    child: new Center(
                                        child:
                                            new CircularProgressIndicator())),
                              )
                            : isPlaying && !paused
                                ? IconButton(
                                    iconSize: 60,
                                    icon: Icon(
                                      Icons.pause,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      pause();
                                    })
                                : songStarted
                                    ? Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            iconSize: 80,
                                            icon: Icon(
                                              Icons.stop,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              // setState(() {
                                              //   songStopped = true;
                                              // });
                                              endOfSongMenu();
                                            },
                                          ),
                                          IconButton(
                                            iconSize: 80,
                                            icon: Icon(
                                              Icons.play_arrow,
                                              color: Colors.white,
                                            ),
                                            onPressed: () {
                                              if (songPicked) {
                                                play();
                                                setState(() {
                                                  playPressed = true;
                                                });
                                              }
                                            },
                                          )
                                        ],
                                      )
                                    : IconButton(
                                        iconSize: 80,
                                        icon: Icon(
                                          Icons.play_arrow,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          if (songPicked) {
                                            play();
                                            setState(() {
                                              playPressed = true;
                                            });
                                          }
                                        },
                                      ),
                      ),
                    ),
                  if (!songPicked) tonePicker(),
                  if (countdown > 0)
                    Center(
                      child: Text(
                        countdown.toString(),
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    )
                ])),
          )),
    );
  }

  void play() async {
    startDownloadingAudioFile();
    countdown = 3;
    startTimer = new Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        countdown--;
      });
      if (countdown == 1) {
        if (songStarted)
          controller!.resumeVideoRecording();
        else
          controller!.startVideoRecording();
      } else if (countdown == 0) {
        startTimer.cancel();
        startKaraokeSession();
      }
    });
  }

  void startKaraokeSession() {
    audioPlayer.play();
    setState(() {
      songStarted = true;
      Wakelock.enable();
      songFinished = false;
      isPlaying = true;
      paused = false;
      playPressed = false;
    });

    audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) if (currentLineIndex ==
              lines.length - 1 &&
          trackNumber == songs.length - 1) {
        setState(() {
          Wakelock.disable();
          isPlaying = false;
          songFinished = true;
          timer.cancel();
          endOfSongMenu();
        });
      } else if (state == ProcessingState.buffering ||
          state == ProcessingState.loading) {
        pause();
      }
    });

    timer = Timer.periodic(
        Duration(milliseconds: 100),
        (Timer t) => updateUI(
            audioPlayer.position, true, false, audioPlayer.currentIndex!));
  }

  buildListView(List<Line> lines) {
    return Column(children: [
      Expanded(
        child: SizedBox(
          height: MediaQuery.of(context).size.height / 6,
          width: MediaQuery.of(context).size.width - 30,
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
    double size = 32;
    Color pastFontColor = display == DisplayOptions.PERSONAL_MOISHIE
        ? Colors.green
        : Colors.white;
    Color futureFontColor = display == DisplayOptions.PERSONAL_MOISHIE
        ? Colors.white
        : Colors.white30;
    FontWeight weight = display == DisplayOptions.PERSONAL_MOISHIE
        ? FontWeight.bold
        : FontWeight.normal;
    return Container(
      height: 33,
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
                    text: display == DisplayOptions.PERSONAL_MOISHIE &&
                            line.past == "" &&
                            line.containsDots()
                        ? 3.toString()
                        : line.future,
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
                    text: display == DisplayOptions.PERSONAL_MOISHIE &&
                            line.past == "" &&
                            line.containsDots()
                        ? 3.toString()
                        : line.future,
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
    if (track != audioPlayer.currentIndex) {
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
          // changeImage(p.inMilliseconds - splits[trackNumber]);
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
            if (trackNumber == 0 ||
                (p.inMilliseconds - songs[trackNumber - 1].length).abs() >
                    1000) {
              // checking if changed didn't register yet
              // print(p.inMilliseconds + splits[trackNumber] + 200);
              // print("changed");
              // print(p.inMilliseconds);
              // int newTrack = i;
              changeAudio(i);
              changeSong(i);
              resetRows(new Duration(milliseconds: 1));
              p = new Duration(milliseconds: 1);
            }
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
    if (controller != null) controller!.pauseVideoRecording();
    timer.cancel();
    setState(() {
      Wakelock.disable();
      isPlaying = false;
      paused = true;
    });
  }

  void restart() {
    // pause();
    _progressValue = new Duration();
    changeSong(0);
    changeAudio(0);
    audioPlayer.seek(Duration(milliseconds: 1));
    resetLines(0.0);
    listViewController.animateTo(
      0.0,
      duration: new Duration(milliseconds: 100),
      curve: Curves.decelerate,
    );
    resetValues();
    // checkFirestorePermissions(true);
  }

  void resetValues() async {
    if (controller == null)
      getCameras();
    else
      await controller!.stopVideoRecording();
    videoFile = null;
    if (concatedFile != "") File(concatedFile).delete();
    concatedFile = "";
    delay = 0;
    _sliderValue = 0;
    setState(() {
      cameraReady = true;
      isPlaying = false;
    });
  }

  void resetLines(double time) {
    setState(() {
      //print("the lines were reset");
      for (Line line in lines) {
        line.resetLine(time, display == DisplayOptions.PERSONAL_MOISHIE);
      }
    });
  }

  void resetAllLines() {
    setState(() {
      for (List<Line> songsLines in allLines)
        for (Line line in songsLines) {
          line.resetLine(0.0, display == DisplayOptions.PERSONAL_MOISHIE);
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
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.all(new Radius.circular(50.0)),
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
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.all(new Radius.circular(60.0)),
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
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.all(new Radius.circular(60.0)),
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
        updateCounter = 0;
        if (!disposed)
          setState(() {
            _progressValue = new Duration(milliseconds: playingTime);
            line.updateLyrics(time, display == DisplayOptions.PERSONAL_MOISHIE);
            isPlaying = true;
          });
        // }
        return;
      } else {
        if (line.isAfter(time)) {
          currentLineIndex = j - 1;
          return;
        }
        if (j == lines.length - 1) currentLineIndex = j;
      }
    }
  }

  void animateLyrics(bool animation) {
    listViewController.animateTo(
      33.toDouble() * currentLineIndex,
      duration: animation
          ? new Duration(milliseconds: 400)
          : new Duration(milliseconds: 20),
      curve: Curves.decelerate,
    );
  }

  createAllBackgroundPictureArray() async {
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

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    // final CameraController? cameraController = controller;
    // print(cameras);
    if (controller == null || !controller!.value.isInitialized) {
      return const Icon(
        Icons.cloud,
        color: Colors.white,
      );
    } else {
      return Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        child: CameraPreview(
          controller!,
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              // onTapDown: (details) => onViewFinderTap(details, constraints),
            );
          }),
        ),
      );
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (controller == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await controller!.setZoomLevel(_currentScale);
  }

  endOfSongMenu(
      [String loadingWords = "",
      int totalProgress = 0,
      bool notEnoughNoise = false]) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0)),
            child: Container(
              height: popupHeight,
              width: popupWidth,
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
              child: Directionality(
                textDirection: Directionality.of(context),
                child: Stack(children: [
                  Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: popupHeight * 0.25,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                songFinished
                                    ? AppLocalizations.of(context)!.songFinished
                                    : AppLocalizations.of(context)!
                                        .stoppedInMiddle,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 30),
                              ),
                              if (totalProgress == 100)
                                Text(
                                  AppLocalizations.of(context)!
                                      .downloadFinished,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                              if (notEnoughNoise)
                                Text(
                                  AppLocalizations.of(context)!.notEnoughNoise,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Stack(children: <Widget>[
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.purple,
                                    // border: Border.all(color: Colors.tealAccent),
                                    borderRadius: BorderRadius.all(
                                        new Radius.circular(60.0)),
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
                                width: MediaQuery.of(context).size.width * 0.6,
                                child: TextButton(
                                    onPressed: () async {
                                      if (!(totalProgress > 0 &&
                                              totalProgress < 100) &&
                                          loadingWords == "") {
                                        endOfSongMenu(
                                            AppLocalizations.of(context)!
                                                .loading);
                                        await finishVideoRecording();
                                        shrinkFileAndDownload();
                                      }
                                    },
                                    child: Text(
                                      AppLocalizations.of(context)!.download +
                                          (totalProgress > 0
                                              ? (" $totalProgress%")
                                              : ""),
                                      style: TextStyle(
                                          fontSize: 22,
                                          color: Colors.white,
                                          letterSpacing: 1.5),
                                    )),
                              ),
                            ])),
                        Container(
                          child: TextButton(
                              onPressed: () async {
                                setState(() {
                                  cameraReady = false;
                                });
                                endOfSongMenu(
                                    AppLocalizations.of(context)!.loading);
                                if (videoFile == null)
                                  await finishVideoRecording();
                                if (concatedFile == "")
                                  await concatFiles(
                                      delay, new Duration(seconds: 0));
                                else
                                  watchRecording(
                                      delay, new Duration(seconds: 0));
                              },
                              child: Text(
                                AppLocalizations.of(context)!.watch,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  //letterSpacing: 1.5
                                ),
                              )),
                        ),
                        const Divider(
                          thickness: 1,
                          // thickness of the line
                          indent: 30,
                          // empty space to the leading edge of divider.
                          endIndent: 30,
                          // empty space to the trailing edge of the divider.
                          color: Colors
                              .white, // The color to use when painting the line.
                          // height: 20, // The divider's height extent.
                        ),
                        Container(
                          child: TextButton(
                              onPressed: () {
                                restart();
                                setState(() {
                                  songFinished = false;
                                  songStarted = false;
                                });
                                Navigator.of(context).pop(STAY_ON_PAGE);
                              },
                              child: Text(
                                AppLocalizations.of(context)!.playAgain,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  //    letterSpacing: 1.5
                                ),
                              )),
                        ),
                        const Divider(
                          thickness: 1,
                          // thickness of the line
                          indent: 30,
                          // empty space to the leading edge of divider.
                          endIndent: 30,
                          // empty space to the trailing edge of the divider.
                          color: Colors
                              .white, // The color to use when painting the line.
                          // height: 20, // The divider's height extent.
                        ),
                        Container(
                          child: TextButton(
                              onPressed: () async {
                                await finishVideoRecording();
                                signInOptions(false);
                              },
                              child: Text(
                                "Sign in",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  //    letterSpacing: 1.5
                                ),
                              )),
                        ),
                        const Divider(
                          thickness: 1,
                          // thickness of the line
                          indent: 30,
                          // empty space to the leading edge of divider.
                          endIndent: 30,
                          // empty space to the trailing edge of the divider.
                          color: Colors
                              .white, // The color to use when painting the line.
                          // height: 20, // The divider's height extent.
                        ),
                        Container(
                          child: TextButton(
                              onPressed: () {
                                songFinished = true;
                                Navigator.of(context).pop();
                                // backButton();
                              },
                              child: Text(
                                AppLocalizations.of(context)!.exit,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  //    letterSpacing: 1.5
                                ),
                              )),
                        ),
                      ]),
                  SafeArea(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          icon: Icon(
                            Icons.cancel_outlined,
                            color: Colors.white,
                          )),
                    ),
                  ),
                  if (loadingWords != "") loadingIndicator(loadingWords)
                ]),
              ),
            ),
          );
        }).then((value) {
      if (songFinished && value != STAY_ON_PAGE) backButton();
    });
  }

  signInOptions(bool signInLoading, [signInError = ""]) {
    double popupHeight = 450;
    double popupWidth = 330;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)),
              child: Container(
                height: popupHeight * 0.7,
                width: popupWidth * 0.7,
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
                child: Directionality(
                  textDirection: Directionality.of(context),
                  child: Stack(
                    children: [
                      SafeArea(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: Icon(
                                Icons.cancel_outlined,
                                color: Colors.white,
                              )),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              AppLocalizations.of(context)!.signInPrompt,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          if (signInError != "")
                            Text(
                              AppLocalizations.of(context)!.signInError,
                              style: TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),

                          // if (Platform.isIOS)
                          if (!signInLoading)
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Center(
                                child:
                                SignInWithAppleButton(onPressed: () async {
                                  AppleSignIn appleSignIn = AppleSignIn();
                                  await appleSignIn.signIn();
                                  addUserToFirebase();
                                }),
                              ),
                            ),
                          !signInLoading
                              ? SizedBox(
                            width: popupWidth * 0.65,
                            child: OutlinedButton.icon(
                              icon: FaIcon(FontAwesomeIcons.google),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                signInOptions(true);
                                try {
                                  await service.signInWithGoogle();
                                  if (firebaseAuth.currentUser != null &&
                                      firebaseAuth.currentUser!.email !=
                                          null) {
                                    addUserToFirebase();
                                  } else
                                    catchSignInError();
                                } catch (e) {
                                  if (e is FirebaseAuthException) {
                                    catchSignInError();
                                  }
                                }
                              },
                              label: Text(
                                AppLocalizations.of(context)!
                                    .googleSignIn,
                                style: TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.bold),
                              ),
                              style: ButtonStyle(
                                  backgroundColor:
                                  MaterialStateProperty.all<Color>(
                                      Colors.grey),
                                  side: MaterialStateProperty.all<
                                      BorderSide>(BorderSide.none)),
                            ),
                          )
                              : CircularProgressIndicator()
                        ],
                      ),
                      // if (signInLoading)
                      //   LoadingIndicator(
                      //       text: AppLocalizations.of(context)!.loading)
                    ],
                  ),
                ),
              ));
        });
  }

  catchSignInError() async {
    await service.signOutFromGoogle();
    Navigator.of(context).pop();
    signInOptions(
      false,
      AppLocalizations.of(context)!.signInError,
    );
  }

  void addUserToFirebase() async {
    String? userEmail = firebaseAuth.currentUser!.email;
    if (userEmail != null) {
      // Navigator.pushNamedAndRemoveUntil(context, Constants.homeNavigate, (route) => false);
      bool userAdded = await UserHandler().sendUserInfoToFirestore(
          userEmail,
          firebaseAuth.currentUser!.displayName,
          firebaseAuth.currentUser!.photoURL);
      if (userAdded) {
        mobileSignedIn = true;
        continueWithFunctionRequested();
      } else
        catchSignInError();
    } else
      catchSignInError();
  }

  Future<XFile> stopVideoRecording() async {
    songFinished = true;
    if (timer.isActive) timer.cancel();
    if (videoFile == null)
      return controller!.stopVideoRecording();
    else
      return videoFile!;
  }

  watchRecording(double initialDelay, Duration currentPosition,
      [bool syncing = false]) async {
    Navigator.of(context).pop(STAY_ON_PAGE); // removing the loading page

    VideoPlayerController _controller =
        VideoPlayerController.file(File(concatedFile));
    if (!syncing) {
      await _controller.initialize();
      _controller.seekTo(currentPosition);
      if (currentPosition.inSeconds > 0) _controller.play();
    }
    showDialog(
        // barrierDismissible: true,
        context: context,
        builder: (BuildContext context) {
          return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0)),
              child: Container(
                height: popupHeight * 1.1,
                width: popupWidth * 1.1,
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
                child: Directionality(
                  textDirection: Directionality.of(context),
                  child: Stack(
                    children: [
                      SafeArea(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: Icon(
                                Icons.cancel_outlined,
                                color: Colors.white,
                              )),
                        ),
                      ),
                      if (!syncing)
                        ClipRRect(
                            borderRadius: BorderRadius.circular(20.0),
                            child:
                                StatefulBuilder(builder: (context, setState) {
                              return VideoPlayer(_controller);
                            })),
                      if (!syncing)
                        StatefulBuilder(builder: (context, setState) {
                          return Center(
                            child: IconButton(
                              onPressed: () {
                                setState(() {
                                  _controller.value.isPlaying
                                      ? _controller.pause()
                                      : _controller.play();
                                });
                              },
                              iconSize: 50,
                              icon: Icon(
                                _controller.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.white,
                              ),
                            ),
                          );
                        }),
                      VideoProgressIndicator(_controller, allowScrubbing: true),
                      if (!syncing)
                        StatefulBuilder(
                          builder: (context, setState) {
                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 70,
                                child: Column(
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.sync,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Slider.adaptive(
                                      value: _sliderValue,
                                      min: -4,
                                      max: 4,
                                      label: "$_sliderValue",
                                      divisions: 8,
                                      onChangeEnd: (double value) async {
                                        if (value * 0.1 + initialDelay !=
                                            delay) {
                                          setState(() {
                                            _sliderValue = value;
                                          });
                                          watchRecording(0,
                                              new Duration(seconds: 0), true);
                                          delay = value * 0.1 + initialDelay;
                                          currentPosition =
                                              (await _controller.position)!;
                                          _controller.dispose();
                                          await concatFiles(
                                              initialDelay, currentPosition);
                                        }
                                      },
                                      onChanged: (double value) {
                                        setState(() {
                                          _sliderValue = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      if (syncing)
                        loadingIndicator(AppLocalizations.of(context)!.syncing)
                    ],
                  ),
                ),
              ));
        }).then((val) {
      _controller.dispose();
    });
  }

  void startDownloadingAudioFile() async {
    if (!fileDownloaded) {
      Dio dio = Dio();
      var dir = await getApplicationDocumentsDirectory();
      downloadFileToWatermarkPath(dir);
      audioDownloadPath = '${dir.path}/audio.mp3';
      bool fileExists = await File(audioDownloadPath).exists();
      if (fileExists) File(audioDownloadPath).delete();
      await dio.download(songs[0].songResourceFile, audioDownloadPath,
          onReceiveProgress: (received, total) {
        var progress = (received / total) * 100;
        // debugPrint('Rec: $received , Total: $total, $progress%');
        // print(received.toDouble() / total.toDouble());
        if (mounted)
          setState(() {
            // downloadProgress = received.toDouble() / total.toDouble();
          });
      }, cancelToken: cancelToken);
      fileDownloaded = true;
      if (waitingForDownloadToWatch)
        concatFiles(delay, new Duration(seconds: 0));
      else if (readyToDownload) shrinkFileAndDownload();
    }
  }

  Future<double> getDelay() async {
    if (delay == 0) {
      VideoPlayerController controller =
          VideoPlayerController.file(File(videoFile!.path));
      await controller.initialize();
      return (controller.value.duration.inMilliseconds -
              audioPlayer.position.inMilliseconds) /
          1000;
    } else
      return delay;
  }

  concatFiles(double initialDelay, Duration currentPosition) async {
    var dir = await getApplicationDocumentsDirectory();
    concatedFile = '${dir.path}/audio_.mp4';
    bool fileExists = await File(concatedFile).exists();
    if (fileExists) File(concatedFile).delete();
    waitingForDownloadToWatch = true;
    await checkIfVideoIsSung();
    if (noiseRecorded) {
      if (fileDownloaded)
        _flutterFFmpeg
            .execute("-ss " +
                delay.toString() +
                " -i " +
                videoFile!.path +
                " -i " +
                audioDownloadPath +
                " -filter_complex \"[1:a]volume=" +
                "0.8" +
                "[a1]; [0:a][a1]amerge=inputs=2[a]\" -map 0:v -map \"[a]\" -c:v copy -ac 2 -shortest " +
                concatedFile)
            .then((value) {
          watchRecording(initialDelay, currentPosition);
        });
    } else {
      Navigator.of(context).pop(STAY_ON_PAGE);
      endOfSongMenu("", 0, true);
    }
  }

  void logCallback(Log log) {
    try {
      if (log.message.contains(new RegExp(r'[0-9]'))) {
        if (log.message.contains('-')) {
          String subString = log.message.substring(1);
          double rms = -1 * double.parse(subString);
          if (rms > -35)
            wordsSung += 1;
          else
            silentWords += 1;
        }
      }
    } catch (Exception) {}
    noiseRecorded = wordsSung * 5 > silentWords + wordsSung;
  }

  void downloadConcatenatedFile(String shrinkedFileToDownload) {
    readyToDownload = false;
    GallerySaver.saveVideo(shrinkedFileToDownload).then((success) {
      if (mounted)
        setState(() {
          if (success!) {
          } else {
            // ScaffoldMessenger.of(context).showSnackBar(snackBar);
          }
        });
    });
    if (mounted) {
      Navigator.of(context).pop(STAY_ON_PAGE);
      endOfSongMenu("", 100);
    }
  }

  void downloadFileToWatermarkPath(Directory dir) async {
    watermarkPath = '${dir.path}/watermarkOutline.png';
    var data = await rootBundle.load('assets/ashiraOutline.png');
    await (File(watermarkPath)).writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  void shrinkFileAndDownload() async {
    readyToDownload = true;
    await checkIfVideoIsSung();
    if (noiseRecorded) {
      if (fileDownloaded) {
        var dir = await getApplicationDocumentsDirectory();
        var shrinkedFileToDownload = '${dir.path}/ashira_' +
            DateTime.now().millisecondsSinceEpoch.toString() +
            '.mp4';
        _flutterFFmpeg
            .execute("-ss " +
                delay.toString() +
                " -i " +
                videoFile!.path +
                " -i " +
                watermarkPath +
                " -i " +
                audioDownloadPath +
                " -filter_complex \"[1]scale=iw/2:-1[wm];[0:v][wm]overlay=main_w-overlay_w-5:main_h-overlay_h-5[v0];[2:a]volume=" +
                "0.5" +
                "[a2];[0:a][a2]amerge=inputs=2[a]\" -map \"[v0]\" -map \"[a]\" -ac 2 -shortest -b:v 1M " +
                shrinkedFileToDownload)
            .then((value) => downloadConcatenatedFile(shrinkedFileToDownload));
      }
    } else {
      Navigator.of(context).pop(STAY_ON_PAGE);
      endOfSongMenu("", 0, true);
    }
  }

  void statisticsCallback(Statistics statistics) {
    if (mounted && !backButtonPressed) if (readyToDownload) {
      var totalProgress =
          (statistics.time * 100) ~/ audioPlayer.position.inMilliseconds;
      // print("Statistics: executionId: ${statistics.executionId}, time: ${statistics.time}, size: ${statistics.size}, bitrate: ${statistics.bitrate}, speed: ${statistics.speed}, videoFrameNumber: ${statistics.videoFrameNumber}, videoQuality: ${statistics.videoQuality}, videoFps: ${statistics.videoFps}");
      if (0 < totalProgress && totalProgress <= 100) {
        Navigator.of(context).pop(STAY_ON_PAGE);
        endOfSongMenu("", totalProgress);
      }
    }
  }

  loadingIndicator(String text) {
    return LoadingIndicator(text: text);
  }

  finishVideoRecording() async {
    videoFile = await stopVideoRecording();
    if (controller != null) {
      controller!.dispose();
      controller = null;
    }
    delay = await getDelay();
  }

  checkIfVideoIsSung() async {
    _flutterFFmpegConfig.enableLogCallback(this.logCallback);
    await _flutterFFprobe.execute("-f lavfi -i amovie=" +
        videoFile!.path +
        ",astats=metadata=1:reset=1 -show_entries frame=pkt_pts_time:frame_tags=lavfi.astats.Overall.RMS_level -of csv=p=0");
    _flutterFFmpegConfig.disableLogs();
  }

  void sendUserInfoToFirestore(String email, String fullName) async {
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    Map<String, dynamic> firestoreDoc = new Map<String, dynamic>();
    firestoreDoc['id'] = GenerateRandomString().generateRandomString();
    firestoreDoc['userEmail'] = email;
    firestoreDoc['userName'] = fullName;
    firestoreDoc['expirationDate'] = "";

    Future<void> addUser() {
      return users
          .doc(email)
          .set(firestoreDoc)
          .then((value) => Navigator.of(context).pop(STAY_ON_PAGE))
          .catchError((error) => setState(() {
                _firebaseAuth.signOut();
                // _errorMessage = error.toString();
                _loading = false;
              }));
    }

    addUser();
  }

  void continueWithFunctionRequested() {}
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
