import 'dart:async';
import 'dart:convert';

// import 'dart:html';
import 'dart:math';

import 'package:ashira_flutter/model/Line.dart';
import 'package:ashira_flutter/model/Song.dart';
import 'package:ashira_flutter/utils/FakeUi.dart'
    if (dart.library.html) 'dart:ui' as ui;
import 'package:ashira_flutter/utils/Parser.dart';
import '../utils/webPurchases/WpHelper.dart' as wph;
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock/wakelock.dart';
import 'package:wordpress_api/wordpress_api.dart' as wp;

import 'AllSongsTablet.dart';
// List<CameraDescription> cameras;

class SingTablet extends StatefulWidget {
  final List<Song> songs;
  final String counter;

  SingTablet(this.songs, this.counter);

  // Sing({Key key, @required this.song}) : super(key: key);

  @override
  _SingTabletState createState() => _SingTabletState(songs, counter);
}

class _SingTabletState extends State<SingTablet> with WidgetsBindingObserver {
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

  Timer timer = Timer(new Duration(hours: 30), () {});

  bool songFinished = false;

  String message = "";

  bool changed = false;

  bool paused = true;

  bool disposed = false;

  bool _accessDenied = false;

  // bool personalMoishie = false;

  List<dynamic> backgroundPictures = [];

  String error = '';

  late TextEditingController _orderEditingController;

  bool _loading = false;
  bool _isSmartphone = true; //todo tablet change to true

  String _errorMessage = "";

  Random random = new Random();
  num randomNumber = 0;

  // todo tablet additions
  // Timestamp endTime;

  // String email;

  bool amIHovering = false;

  var quantity = 0;

  var timeChanged = 0;

  num lastTimeChanged = 0;

  String counter;

  bool cameraReady = false;

  var songStarted = false;

  int secondCounter = 0;

  late Orientation orientation;

  _SingTabletState(this.songs, this.counter);

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

  // Counting pointers (number of user fingers on screen)
  int _pointers = 0;

  // Wakelock.toggle(enable: isPlaying);

  @override
  Future<void> dispose() async {
    timer.cancel();
    disposed = true;
    if (isPlaying) {
      pause();
      await audioPlayer.stop();
    }
    if (controller != null) {
      controller!.dispose();
      controller = null;
    }
    audioPlayer.dispose();
    WidgetsBinding.instance!.removeObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    randomNumber = random.nextInt(7) + 1;
    WidgetsBinding.instance!.addObserver(this);
    parseFuture = _parseLines();
    _progressValue = new Duration(seconds: 0);
    int totalLength = 0;
    for (int i = 0; i < songs.length; i++) {
      splits.add(totalLength);
      totalLength += songs[i].length;
    }
    songLength = new Duration(milliseconds: totalLength - 150);
    // checkFirestorePermissions(false);
    createAllBackgroundPictureArray();
    //todo tablet comment _isSmartphone = isSmartphone();
    getCameras();
  }

  //todo tablet addittion
  void getCameras() async {
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
      // logError(e.code, e.description);
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
    timer.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (personalMoishie)
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
      ]);
    return OrientationBuilder(
      builder: (context, orientation) {
        this.orientation = orientation;
        if (tabletOrientationLandscape() &&
            orientation == Orientation.portrait) {
          return portraitMobile();
        } else
          return webPage();
      },
    );
  }

  portraitMobile() {
    secondCounter += 1;
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
                child: Container(
                  decoration: BoxDecoration(
                      image: getPreviousImage(),
                      border: Border.all(color: Colors.purple),
                      borderRadius:
                          BorderRadius.all(new Radius.circular(20.0))),
                  child: Container(
                    decoration: BoxDecoration(
                        image: getImage(),
                        border: Border.all(color: Colors.purple),
                        borderRadius:
                            BorderRadius.all(new Radius.circular(20.0))),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          songs[trackNumber].artist,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white),
                                        ),
                                        Text(
                                          songs[trackNumber].title,
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.white),
                                        ),
                                      ],
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
                          Expanded(
                            child: Container(
                              height: cameraMode
                                  ? MediaQuery.of(context).size.height / 4
                                  : MediaQuery.of(context).size.height,
                              width: MediaQuery.of(context).size.width - 30,
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
                                          songs[trackNumber].imageResourceFile),
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8.0, 0, 8, 0),
                            child: Center(
                              child: ProgressBar(
                                total: songLength,
                                progressBarColor: Colors.blue,
                                progress: _progressValue,
                                thumbRadius: 9,
                                thumbColor: Colors.white,
                                timeLabelTextStyle:
                                    TextStyle(color: Colors.white),
                                barHeight: 8,
                                timeLabelLocation: TimeLabelLocation.sides,
                                onSeek: (Duration duration) {
                                  _progressValue = duration;
                                  updateUI(duration, false, true, trackNumber);
                                  audioPlayer.seek(
                                      new Duration(
                                          milliseconds:
                                              duration.inMilliseconds -
                                                  splits[trackNumber]),
                                      index: trackNumber);
                                },
                              ),
                            ),
                          ),
                          if (cameraMode)
                            Expanded(
                                child: Container(
                                    child: Align(
                                        alignment: Alignment.topCenter,
                                        child:
                                            // todo tablet WebcamPage(counter +
                                            //     secondCounter.toString())))),
                                            _cameraPreviewWidget())))
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
                      Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: Align(
                            alignment: Alignment.bottomCenter,
                            child: playPauseAndRestartIcons()),
                      ),
                      if (!songPicked) tonePicker(),
                    ]),
                  ),
                )),
          )),
    );
  }

  webPage() {
    secondCounter += 1;

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
                            image: getPreviousImage(),
                            border: Border.all(color: Colors.purple),
                            borderRadius:
                                BorderRadius.all(new Radius.circular(20.0))),
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
                                SafeArea(
                                  child: Text(
                                    songs[trackNumber].title,
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.white),
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                          if (!(isPlaying && counter == "אשר"))
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                      0, 20, 0, 0),
                                              child: Container(
                                                width: _isSmartphone &&
                                                        !tabletOrientationLandscape()
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
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            new Radius.circular(
                                                                30.0))),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.fromLTRB(
                                                          8.0, 4, 8, 4),
                                                  child: Center(
                                                    child: ProgressBar(
                                                      total: songLength,
                                                      progressBarColor:
                                                          Colors.blue,
                                                      progress: _progressValue,
                                                      thumbColor: Colors.white,
                                                      timeLabelTextStyle:
                                                          TextStyle(
                                                              color:
                                                                  Colors.white),
                                                      barHeight: 4,
                                                      thumbRadius: 9,
                                                      timeLabelLocation:
                                                          TimeLabelLocation
                                                              .sides,
                                                      onSeek:
                                                          (Duration duration) {
                                                        _progressValue =
                                                            duration;
                                                        updateUI(
                                                            duration,
                                                            false,
                                                            true,
                                                            trackNumber);
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
                                          if (!(isPlaying && counter == "אשר"))
                                            playPauseAndRestartIcons()
                                        ],
                                      ),
                                      if (!personalMoishie &&
                                          (!_isSmartphone ||
                                              tabletOrientationLandscape()))
                                        Container(
                                          decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.purple),
                                              borderRadius: BorderRadius.all(
                                                  new Radius.circular(15))),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: cameraMode
                                                ? Container(
                                                    color: Colors.transparent,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            2.7,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            2.7,
                                                    child:
                                                        _cameraPreviewWidget())
                                                //todo tablet WebcamPage(counter +
                                                //     secondCounter
                                                //         .toString()))
                                                : ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            15.0),
                                                    child: Image(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              3,
                                                      fit: BoxFit.fitWidth,
                                                      image: NetworkImage(songs[
                                                              trackNumber]
                                                          .imageResourceFile),
                                                    ),
                                                  ),
                                          ),
                                        )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (!songPicked) tonePicker(),
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
                          ]),
                        ),
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
        Directionality(
          textDirection: Directionality.of(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                      quantity.toString() +
                          " " +
                          AppLocalizations.of(context)!.hours,
                      style: TextStyle(color: Colors.white)),
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
              SizedBox(
                width: 20,
              ),
              Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (PointerEvent details) =>
                      setState(() => amIHovering = true),
                  onExit: (PointerEvent details) => setState(() {
                    amIHovering = false;
                  }),
                  child: RichText(
                      text: TextSpan(
                          text: AppLocalizations.of(context)!.placeOrder,
                          style: TextStyle(
                            fontSize: 18,
                            color: amIHovering ? Colors.blue[300] : Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              launch(
                                  "https://ashira-music.com/checkout/?add-to-cart=1102&quantity=$quantity");
                            })),
                ),
              ),
            ],
          ),
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
    if (email == "") return false;
    DateTime currentTime = DateTime.now().toUtc();
    DateTime myDateTime = endTime.toDate();
    return currentTime.compareTo(myDateTime) > 0;
  }

  void play() async {
    if (timesUp()) {
      setState(() {
        // _accessDenied = true;
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
            trackNumber == songs.length - 1) {
          setState(() {
            Wakelock.disable();
            isPlaying = false;
            songFinished = true;
            timer.cancel();
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
  }

  buildListView(List<Line> lines) {
    return Column(children: [
      Expanded(
        child: SizedBox(
          height: MediaQuery.of(context).size.height / 3,
          width: _isSmartphone &&
                  (!tabletOrientationLandscape() ||
                      orientation == Orientation.portrait)
              ? MediaQuery.of(context).size.width - 40
              : personalMoishie
                  ? MediaQuery.of(context).size.width - 45
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
    double size = personalMoishie
        ?
        //todo tablet comment MediaQuery.of(context).size.height / 6
        MediaQuery.of(context).size.height / 7
        : _isSmartphone
            ? 28
            : 34;
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
                    text: personalMoishie &&
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
                    text: personalMoishie &&
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

  void changeImage(int i) {
    if (personalMoishie) if ((i / 1000 - lastTimeChanged).abs() > changeTime) {
      lastTimeChanged = i / 1000;
      setState(() {
        timeChanged += 1;
      });
    }
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
    // checkFirestorePermissions(true);
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
    changed = true;
    setState(() {
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
                        decoration: personalMoishie || _isSmartphone
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
                        decoration: personalMoishie || _isSmartphone
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
                        decoration: personalMoishie || _isSmartphone
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
        updateCounter = 0;
        if (!disposed)
          setState(() {
            _progressValue = new Duration(milliseconds: playingTime);
            line.updateLyrics(time, personalMoishie);
            isPlaying = true;
          });
        // }
        return;
      } else {
        if (line.isAfter(time)) {
          currentLineIndex = j - 1;
          changeImage(playingTime);
          return;
        }
        if (j == lines.length - 1) currentLineIndex = j;
      }
    }
    changeImage(playingTime);
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
            (((timeChanged + randomNumber) * randomNumber) %
                    backgroundPictures.length)
                .toInt()]),
      );
    }
  }

  addTime() async {
    setState(() {
      _loading = true;
    });
    try {
      getPurchaseFromStore(true);
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
        // print("ret");
        // print(ret.runtimeType);

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

  void getPurchaseFromStore(bool newUser) async {
    wph.WordPressAPI api = wph.WordPressAPI('https://ashira-music.com');
    try {
      try {
        var res = await getWooCommerceId(api, email);

        await addTimeToFirebase((res)["quantity"]!, email);
        assignOrderAsCompleted(api, (res)["id"]!);
      } catch (error) {
        if (error.toString() == "No document") {
          setState(() {
            _errorMessage = AppLocalizations.of(context)!.noOrderNumberError;
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

  addTimeToFirebase(int quantity, String newId) {
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
    firestoreDoc['endTime'] = endTime;
    firestoreDoc['email'] = email;

    CollectionReference users =
        FirebaseFirestore.instance.collection('internetUsers');

    Future<void> addUser() {
      return users
          .doc(newId)
          .set(firestoreDoc)
          .then((value) => setState(() {
                _accessDenied = false;
                _errorMessage = "";
                _loading = false;
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

  getPreviousImage() {
    if (personalMoishie && backgroundPictures.length > 0) {
      if (timeChanged == 0)
        return DecorationImage(
          fit: BoxFit.fill,
          image: NetworkImage(backgroundPictures[
              (((timeChanged + randomNumber) * randomNumber) %
                      backgroundPictures.length)
                  .toInt()]),
        );
      return DecorationImage(
        fit: BoxFit.fill,
        image: NetworkImage(backgroundPictures[
            (((timeChanged - 1 + randomNumber) * randomNumber) %
                    backgroundPictures.length)
                .toInt()]),
      );
    }
  }

  bool tabletOrientationLandscape() {
    return _isSmartphone && (personalMoishie || cameraMode);
  }

  playPauseAndRestartIcons() {
    return _loading
        ? new Container(
            color: Colors.transparent,
            width: 50.0,
            height: 50.0,
            child: new Padding(
                padding: const EdgeInsets.all(5.0),
                child: new Center(child: new CircularProgressIndicator())),
          )
        : isPlaying && !paused
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
                      if (songPicked) play();
                    },
                  );
  }
}

class WebcamPage extends StatefulWidget {
  String number;

  WebcamPage(this.number);

  @override
  _WebcamPageState createState() => _WebcamPageState(number);
}

class _WebcamPageState extends State<WebcamPage> {
  // Webcam widget to insert into the tree
  late Widget _webcamWidget;

  // VideoElement
  html.VideoElement _webcamVideoElement = html.VideoElement();

  String number;

  _WebcamPageState(this.number);

  @override
  void dispose() {
    switchCameraOff();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // size = MediaQuery.of(context).size;
    // deviceRatio = size.width / size.height;
    // Create a video element which will be provided with stream source
    _webcamVideoElement = html.VideoElement();
    _webcamWidget = HtmlElementView(key: UniqueKey(), viewType: number);
    // Register an webcam
    if (!ui.platformViewRegistry.registerViewFactory(number,
        (int viewId) => _webcamVideoElement)) // return _webcamVideoElement;
      print("this is still causeing an issue" + number);

    html.window.navigator.mediaDevices!
        .getUserMedia({"video": true}).then((html.MediaStream stream) {
      _webcamVideoElement
        ..srcObject = stream
        ..autoplay = true;
      return _webcamVideoElement;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(new Radius.circular(20.0)),
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [
                    const Color(0xFF221A4D), // blue sky
                    const Color(0xFF000000), // yellow sun
                  ],
                )),
            width: MediaQuery.of(context).size.width,
            child: _webcamWidget),
      ));

  switchCameraOff() {
    try {
      if (_webcamVideoElement.srcObject!.active!) {
        var tracks = _webcamVideoElement.srcObject!.getTracks();

        //stopping tracks and setting srcObject to null to switch camera off
        _webcamVideoElement.srcObject = null;

        tracks.forEach((track) {
          // todo took off for mobile
          // track.stop();
        });
      }
    } catch (error) {}
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
