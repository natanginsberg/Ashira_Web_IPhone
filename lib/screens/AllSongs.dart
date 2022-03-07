import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:ashira_flutter/customWidgets/GenreButton.dart';
import 'package:ashira_flutter/customWidgets/SongLayout.dart';
import 'package:ashira_flutter/model/DisplayOptions.dart';
import 'package:ashira_flutter/model/Song.dart';
import 'package:ashira_flutter/utils/AppleSignIn.dart';
import 'package:ashira_flutter/utils/WebFlow.dart';
import 'package:ashira_flutter/utils/firetools/FirebaseService.dart';
import 'package:ashira_flutter/utils/firetools/GetValues.dart';
import 'package:ashira_flutter/utils/firetools/IpHandler.dart';
import 'package:ashira_flutter/utils/firetools/MobileUserHandler.dart';
import 'package:ashira_flutter/utils/firetools/WebUserHandler.dart';
import 'package:ashira_flutter/utils/webPurchases/CheckForPurchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_ipify/dart_ipify.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import 'Sing.dart';

class AllSongs extends StatefulWidget {
  AllSongs();

  @override
  _AllSongsState createState() => _AllSongsState();
}

final GlobalKey<ScaffoldState> _scaffoldKey2 = GlobalKey<ScaffoldState>();

List<Song> songs = [];

List<String> genres = [""];

List<List<Song>> searchPath = [];
List<Song> gridSongs = [];

String email = "";
String id = "";
Timestamp endTime = Timestamp(10, 10);
DisplayOptions display = DisplayOptions.NORMAL;
int changeTime = 7;
List<String> slowSongs = [];
List<String> fastSongs = [];
List<String> slowSongsVideos = [];
List<String> fastSongsVideos = [];
List<dynamic> specialVideos = [];

class _AllSongsState extends State<AllSongs> {
  final TextEditingController controller = new TextEditingController();
  final TextEditingController timeController = new TextEditingController();
  bool _smartPhone = false;

  bool _showGenreBar = false;
  bool menuOpen = false;
  late bool onSearchTextChanged;

  String currentGenre = "";

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

  bool signedIn =
      // Platform.isIOS ? true :
      false;

  var openSignIn = false;

  List<String> demoSongNames = [];

  int songAccessDenied = -100;

  int quantity = 0;

  List<String> hebrewGenres = ["כל השירים"];
  List<String> englishGenres = ["All Songs"];

  String myLocale = "he";

  bool privacyShown = false;

  bool openPrivacyOptions = false;

  late Map<String, dynamic> deviceData;

  String ipAddress = "";

  bool noVideos = false;

  late StreamSubscription<dynamic> _subscription;

  FirebaseService service = new FirebaseService();

  var _isObscure = true;

  GetValues getValues = GetValues();

  Timer? startTimer;

  var userHandler;

  late WebFlow webFlow;

  bool addTimeHovering = false;

  _AllSongsState();

  void signInAnon() async {
    if (!service.isUserSignedIn())
      await firebaseAuth.signInAnonymously().then((value) => getFirebaseData());
    else {
      userHandler.setEmail(service.getEmail());
      endTime = await userHandler.getUserEndTime();
      if (!checkOvertime()) signedIn = true;
      // signedIn =true;
    }
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) initializeFirebase();

    if (!kIsWeb) receiveBillingInfo();

    if (kIsWeb)
      userHandler = WebUserHandler();
    else
      userHandler = MobileUserHandler();
    // setState(() {
    _mainController = ScrollController();
    _orderEditingController = TextEditingController(text: "");
    _couponEditingController = TextEditingController(text: "");
    _userNameEditingController = TextEditingController(text: "");
    signInAnon();
    _smartPhone = isSmartphone();
    timer =
        Timer.periodic(Duration(seconds: 1), (Timer t) => _getTimeRemaining());
    if (service.isUserSignedIn())
      WidgetsBinding.instance!.addPostFrameCallback((_) => getFirebaseData());
    if (kIsWeb)
      WidgetsBinding.instance!.addPostFrameCallback((_) => webFlow = WebFlow(
          buildContext: context,
          getValues: getValues,
          userHandler: userHandler,
          signInSuccessful: () {
            setState(() {
              _accessDenied = false;
              signedIn = true;
              openSignIn = false;
              gridSongs = new List.from(songs);
            });
          },
          close: () {
            setState(() {
              openSignIn = false;
            });
          }));
  }

  // VoidCallback signInSuccessful() {
  //   setState(() {
  //     _accessDenied = false;
  //     signedIn = true;
  //     openSignIn = false;
  //     gridSongs = new List.from(songs);
  //   });
  // }

  // VoidCallback closeSignIn

  receiveBillingInfo() async {
    final Stream purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (error) {
      // handle error here.
    });
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    bool productDelivered = false;
    purchaseDetailsList.forEach((PurchaseDetails purchaseDetails) async {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          // bool valid = await _verifyPurchase(purchaseDetails);
          // if (valid) {
          productDelivered = await _deliverProduct(purchaseDetails);
          // } else {
          //   _handleInvalidPurchase(purchaseDetails);
          // }
        }
        if (productDelivered && purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    });
  }

  void _readWebBrowserInfo() async {
    //         });
    ipAddress = await Ipify.ipv64(format: Format.TEXT)
        .catchError((error) => ipAddress = "");
    try {
      DocumentSnapshot documentSnapshot =
          await IpHandler().checkCurrentIpAddress(ipAddress);
      setState(() {
        signedIn = true;
        endTime = documentSnapshot.get("endTime");
        gridSongs = new List.from(songs);
        email = documentSnapshot.id;
      });
    } catch (error) {}
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

  openwhatsapp() async {
    var whatsapp = "+972535097848";
    var whatsappURl_android = "whatsapp://send?phone=" + whatsapp + "&text=Hi";
    var whatappURL_ios = "https://wa.me/$whatsapp?text=${Uri.parse("Hi")}";
    if (Platform.isIOS) {
      // for iOS phone only
      if (await canLaunch(whatappURL_ios)) {
        await launch(whatappURL_ios, forceSafariVC: false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: new Text("Whatsapp not installed")));
      }
    } else {
      // android , web
      if (await canLaunch(whatsappURl_android)) {
        await launch(whatsappURl_android);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: new Text("Whatsapp not installed")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // locale: Localizations.localeOf(context),
      home: Directionality(
        textDirection: Directionality.of(context),
        child: Scaffold(
            drawer: Drawer(
              // Add a ListView to the drawer. This ensures the user can scroll
              // through the options in the drawer if there isn't enough vertical
              // space to fit everything.
              child: ListView(
                // Important: Remove any padding from the ListView.
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                        gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        const Color(0xFF221A4D), // blue sky
                        const Color(0xFF000000),
                      ],
                    )),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.menu,
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.watsappUs,
                    ),
                    onTap: () {
                      //launch("https://wa.me/message/6CROFFTK7A5BE1");
                      openwhatsapp();
                      // Update the state of the app
                      // ...
                      // Then close the drawer
                      _scaffoldKey2.currentState!.openEndDrawer();
                    },
                  ),
                  ListTile(
                    title: Text(
                      AppLocalizations.of(context)!.language,
                    ),
                    onTap: () {
                      // Update the state of the app
                      // ...
                      // Then close the drawer
                      if (Localizations.localeOf(context).languageCode ==
                          "he") {
                        Locale newLocale = Locale('en', 'IL');
                        App.setLocale(context, newLocale);
                        setState(() {
                          genres = List.from(englishGenres);
                        });
                      } else {
                        Locale newLocale = Locale('he', 'US');
                        App.setLocale(context, newLocale);
                        setState(() {
                          genres = List.from(hebrewGenres);
                        });
                      }

                      _scaffoldKey2.currentState!.openEndDrawer();
                    },
                  ),
                  if (!kIsWeb && !privacyShown)
                    ListTile(
                      title: Text(
                        AppLocalizations.of(context)!.settings,
                      ),
                      onTap: () {
                        // Update the state of the app
                        // ...
                        // Then close the drawer
                        //todo need to deal with the policies
                        setState(() {
                          privacyShown = true;
                        });
                      },
                    ),
                  if (!kIsWeb && privacyShown)
                    ListTile(
                      title: Text(
                        AppLocalizations.of(context)!.privacyPolicy,
                      ),
                      onTap: () {
                        // Update the state of the app
                        // ...
                        // Then close the drawer
                        //todo need to deal with the policies
                        launch(
                            "https://ashira-music.com/%D7%AA%D7%A7%D7%A0%D7%95%D7%9F/");
                        _scaffoldKey2.currentState!.openEndDrawer();
                      },
                    ),
                  if (!kIsWeb && privacyShown)
                    ListTile(
                      title: Text(
                        AppLocalizations.of(context)!.about,
                      ),
                      onTap: () {
                        launch("https://ashira-music.com");
                        _scaffoldKey2.currentState!.openEndDrawer();
                        // Update the state of the app
                        // ...
                        // Then close the drawer
                        //todo need to deal with the policies
                      },
                    ),
                  if (!kIsWeb && service.isUserSignedIn())
                    ListTile(
                      title: Text(
                        AppLocalizations.of(context)!.signOut,
                      ),
                      onTap: () async {
                        _scaffoldKey2.currentState!.openEndDrawer();
                        await service.signOutFromGoogle();
                        setState(() {
                          signedIn = false;
                        });
                      },
                    )
                ],
              ),
            ),
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
                      // isTablet() ? Colors.green : Colors.pink,
                      const Color(0xFF000000),
                    ],
                  )),
                  child: Stack(children: [
                    Column(
                      children: [
                        SafeArea(
                          child: Container(
                            height: 45,
                            child: Directionality(
                              textDirection: Directionality.of(context),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                      icon: Icon(
                                        Icons.menu,
                                        color: Colors.white,
                                      ),
                                      onPressed: () => _scaffoldKey2
                                          .currentState!
                                          .openDrawer()),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        30.0, 10, 30, 10),
                                    child: Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Text(
                                        signedIn && kIsWeb
                                            // && !Platform.isIOS
                                            ? AppLocalizations.of(context)!
                                                    .timeRemaining +
                                                duration
                                            : "",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                        searchBar(),
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
                                        : buildGridView(
                                            //todo removed for web release
                                            // Platform.isIOS
                                            //     ? List.from(gridSongs.where(
                                            //         (element) => demoSongNames
                                            //             .contains(element.title)))
                                            //     :
                                            gridSongs)),
                              ),
                              if (kIsWeb &&
                                  !_smartPhone &&
                                  songsClicked.length > 0)
                                buildPlaylistWidget()
                            ],
                          ),
                        ),
                        if (kIsWeb && isTablet() && songsClicked.length > 0)
                          Container(
                            child: Column(
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
                                          MainAxisAlignment.center,
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
                                                            display =
                                                                DisplayOptions
                                                                    .NORMAL;
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
                                            value: display ==
                                                DisplayOptions.NORMAL,
                                            onChanged: (newValue) {
                                              setState(() {
                                                display = DisplayOptions.NORMAL;
                                              });
                                            },
                                          ),
                                        ),
                                        SizedBox(
                                          width: 25,
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
                                                            display = DisplayOptions
                                                                .PERSONAL_MOISHIE;
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
                                            value: display ==
                                                DisplayOptions.PERSONAL_MOISHIE,
                                            onChanged: (newValue) {
                                              setState(() {
                                                display = DisplayOptions
                                                    .PERSONAL_MOISHIE;
                                              });
                                            },
                                          ),
                                        )
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: RichText(
                                            text: TextSpan(children: [
                                              TextSpan(
                                                  text: AppLocalizations.of(
                                                          context)!
                                                      .cameraOn,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                  recognizer:
                                                      TapGestureRecognizer()
                                                        ..onTap = () {
                                                          setState(() {
                                                            display =
                                                                DisplayOptions
                                                                    .CAMERA_MODE;
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
                                            value: display ==
                                                DisplayOptions.CAMERA_MODE,
                                            onChanged: (newValue) {
                                              setState(() {
                                                display =
                                                    DisplayOptions.CAMERA_MODE;
                                              });
                                            },
                                          ),
                                        ),
                                        SizedBox(
                                          width: 25,
                                        ),
                                        if (!noVideos)
                                          Flexible(
                                            child: RichText(
                                              text: TextSpan(children: [
                                                TextSpan(
                                                    text: AppLocalizations.of(
                                                            context)!
                                                        .withClip,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                    recognizer:
                                                        TapGestureRecognizer()
                                                          ..onTap = () {
                                                            setState(() {
                                                              display =
                                                                  DisplayOptions
                                                                      .WITH_CLIP;
                                                            });
                                                          }),
                                              ]),
                                            ),
                                          ),
                                        if (!noVideos)
                                          Theme(
                                            data: ThemeData(
                                                unselectedWidgetColor:
                                                    Colors.red),
                                            child: Checkbox(
                                              //    <-- label
                                              value: display ==
                                                  DisplayOptions.WITH_CLIP,
                                              onChanged: (newValue) {
                                                setState(() {
                                                  display =
                                                      DisplayOptions.WITH_CLIP;
                                                });
                                              },
                                            ),
                                          )
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        if (!signedIn)
                          // ? placeNewOrder()
                          // :
                          Container(
                            height: 50,
                            color: Colors.black,
                            child: Directionality(
                              textDirection: Directionality.of(context),
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.enterSystem,
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
                                            padding: const EdgeInsets.fromLTRB(
                                                8.0, 4, 8.0, 4),
                                            child: TextButton(
                                                onPressed: () {
                                                  if (kIsWeb)
                                                    setState(() {
                                                      openSignIn = true;
                                                    });
                                                  else {
                                                    if (service
                                                        .isUserSignedIn())
                                                      buildMobilePayment(false);
                                                    else
                                                      signInOptions(false);
                                                  }
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
                    genreOptions(),
                    if (kIsWeb && _smartPhone) playButton()
                  ]),
                ),
              ),
              if (openSignIn)
                if (kIsWeb) webFlow.buildWebSignInPopup(isSmartphone()),
              // buildWebSignInPopup(),
              if (openPrivacyOptions)
                Center(
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
                        height: 150,
                        width: 150,
                        child: Column(
                          children: [
                            Text(""),
                            Text(""),
                            Text(""),
                          ],
                        )))
            ])),
      ),
    );
  }

  getFirebaseData() async {
    myLocale = Localizations.localeOf(context).languageCode;
    // getDemoSongs();
    demoSongNames = await getValues.getDemoSongs();
    getGenres();
    getSongs();
    if (kIsWeb) getBackgroundVideos();
  }

  getSongs() {
    if (kIsWeb) {
      _readWebBrowserInfo();
    }
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
          if (kIsWeb)
            for (String name in demoSongNames) {
              int index = songs.indexWhere((element) => element.title == name);
              if (index >= 0) {
                gridSongs.remove(songs[index]);
                gridSongs.insert(0, songs[index]);
              }
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
      child: ListView.builder(
          itemExtent: 50.0,
          shrinkWrap: true,
          itemCount: genres.length,
          itemBuilder: (BuildContext ctx, index) {
            return Container(
              color: Colors.transparent,
              alignment: Alignment.center,
              child: createElevateButton(genre: genres[index]),
            );
          }),
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
          if (genre == hebrewGenres[0] || genre == englishGenres[0]) {
            setState(() {
              gridSongs = new List.from(songs);
              controller.clear();
              previousValue = "";
              if (!signedIn)
                for (String name in demoSongNames) {
                  int index =
                      songs.indexWhere((element) => element.title == name);
                  if (index > -1) {
                    gridSongs.remove(songs[index]);
                    gridSongs.insert(0, songs[index]);
                  }
                }
            });
          } else if (currentGenre != genre) {
            setState(() {
              gridSongs = new List.from(songs
                  .where((element) =>
                      element.genre == hebrewGenres[genres.indexOf(genre)])
                  .toList());
              controller.clear();
              previousValue = "";
            });
          }
          setState(() {
            currentGenre = genre;
            _showGenreBar = false;
          });
        },
        child: Align(
          alignment: Alignment.center,
          child: Text(
            genre,
            style: TextStyle(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
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
      if (kIsWeb) {
        if (email == "הקלטותשלאשר") {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => Sing(songsPassed, "אשר")));
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => Sing(songsPassed, counter.toString())));
        }
      }
      // else {
      //   Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //           builder: (_) => MobileSing(songsPassed, counter.toString())));
      // }
      setState(() {
        songsClicked.clear();
      });
    }
  }

  buildSongLayout(Song song, int index) {
    return SongLayout(
      song: song,
      index: index,
      open: signedIn || demoSongNames.contains(song.title),
      clickedIndex: songsClicked.indexWhere(
              (element) => element.songResourceFile == song.songResourceFile) +
          1,
      onTapAction: () => _onSongPressed(song),
      isSmartphone: _smartPhone,
      memberText: AppLocalizations.of(context)!.membersOnly,
      demoSongWording: AppLocalizations.of(context)!.demoWording,
      demoSong: !signedIn && demoSongNames.contains(song.title),
    );
  }

  bool isSmartphone() {
    if (kIsWeb) {
      final userAgent =
          html.window.navigator.userAgent.toString().toLowerCase();
      return (userAgent.contains("iphone") ||
          userAgent.contains("android") ||
          userAgent.contains("ipad") ||
          (html.window.navigator.platform!.toLowerCase().contains("macintel") &&
              html.window.navigator.maxTouchPoints! > 0));
    } else
      return false;
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
    if (kIsWeb)
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
                child: Text(
                  AppLocalizations.of(context)!.addTime,
                  style: TextStyle(
                      fontFamily: 'SignInFont',
                      color: Colors.white,
                      wordSpacing: 5,
                      fontSize: 30,
                      height: 1.4,
                      letterSpacing: 1.6),
                ))
          ]);
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
    return checkOvertime();
  }

  bool checkOvertime() {
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
    // if (!Platform.isIOS)
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

  addTimeToFirebase(int quantity) async {
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
    userHandler.setEndTime(endTime);
    bool timeAdded = await userHandler.addTimeToUser();
    if (timeAdded)
      setState(() {
        _accessDenied = false;
        _errorMessage = "";
        _loading = false;
        signedIn = true;
        openSignIn = false;
        gridSongs = new List.from(songs);
      });
    else {
      setState(() {
        _loading = false;
      });
      printConnectionError();
    }
  }

  printConnectionError() {
    setState(() {
      _errorMessage = AppLocalizations.of(context)!.communicationError;
      _loading = false;
    });
  }

  void getPurchaseFromStore(bool newUser, bool timesUp) async {
    try {
      try {
        var res = await CheckForPurchase().getWooCommerceId(email);
        await addTimeToFirebase((res)["quantity"]!);
        CheckForPurchase().assignOrderAsCompleted((res)["id"]!);
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

  buildMobilePayment(bool loading, [String billingErrorMessage = ""]) async {
    String errorVal = billingErrorMessage;
    List<ProductDetails> products = [];
    if (!loading) {
      final bool available = await InAppPurchase.instance.isAvailable();
      if (!available) {
        errorVal = AppLocalizations.of(context)!.storeReachError;
      }
      const Set<String> _kIds = <String>{"daily_buy", "monthly_buy"};
      final ProductDetailsResponse response =
          await InAppPurchase.instance.queryProductDetails(_kIds);
      if (response.notFoundIDs.isNotEmpty) {
        // Handle the error.
      }
      products = response.productDetails;
    }
    showDialog(
        context: context,
        barrierDismissible: loading ? false : true,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Directionality(
              textDirection: Directionality.of(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                      child: Center(
                    child: Stack(children: [
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
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
                                  height:
                                      MediaQuery.of(context).size.height / 3.5,
                                  width:
                                      MediaQuery.of(context).size.height / 3.5,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage('assets/ashira.png'),
                                      fit: BoxFit.fill,
                                    ),
                                    shape: BoxShape.rectangle,
                                  ),
                                ),
                                Center(
                                    child: Text(
                                  errorVal == ""
                                      ? AppLocalizations.of(context)!
                                          .billingDisclaimer
                                      : errorVal,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: errorVal == ""
                                          ? Colors.white
                                          : Colors.red,
                                      fontSize: 12),
                                )),
                                if (!loading)
                                  Center(
                                    child: Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                2,
                                        height: 50,
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.purple),
                                            borderRadius: BorderRadius.all(
                                                new Radius.circular(10.0))),
                                        child: ElevatedButton(
                                          style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStateProperty
                                                      .all<Color>(errorVal == ""
                                                          ? Colors.blueAccent
                                                          : Colors.grey)),
                                          onPressed: () {
                                            if (errorVal == "")
                                              startPaymentFlow(products.last);
                                          },
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Flexible(
                                                    child: Container(
                                                  child: Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .monthlySub,
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                )),
                                                Container(
                                                  color: Colors.pink,
                                                  child: Text("50₪",
                                                      style: TextStyle(
                                                          color: Colors.white)),
                                                )
                                              ]),
                                        )),
                                  ),
                                if (!loading)
                                  Center(
                                    child: Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                2,
                                        height: 50,
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                                color: Colors.purple),
                                            borderRadius: BorderRadius.all(
                                                new Radius.circular(10.0))),
                                        child: ElevatedButton(
                                          style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStateProperty
                                                      .all<Color>(errorVal == ""
                                                          ? Colors.blueAccent
                                                          : Colors.grey)),
                                          onPressed: () {
                                            if (errorVal == "")
                                              startPaymentFlow(products.first);
                                          },
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Flexible(
                                                    child: Container(
                                                  child: Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .dailySub,
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                )),
                                                Container(
                                                  color: Colors.pink,
                                                  child: Text("10₪",
                                                      style: TextStyle(
                                                          color: Colors.white)),
                                                )
                                              ]),
                                        )),
                                  ),
                                if (loading) CircularProgressIndicator()
                              ],
                            ),
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: Icon(Icons.close),
                                color: Colors.white,
                                onPressed: () {
                                  Navigator.of(context).pop();
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
            ),
          );
        });
  }

  _onSongPressed(Song song) {
    if (signedIn || demoSongNames.contains(song.title)) {
      setState(() {
        songInSongsClicked(song)
            ? songsClicked.removeWhere(
                (element) => element.songResourceFile == song.songResourceFile)
            : songsClicked.add(song);
      });
      if (!kIsWeb) playSongs();
    } else {
      if (kIsWeb)
        setState(() {
          openSignIn = true;
        });
      else {
        if (service.isUserSignedIn())
          buildMobilePayment(false);
        else
          signInOptions(false);
      }
    }
  }

  buildPlaylistWidget() {
    return Center(
      child: Container(
        width: min(350, MediaQuery.of(context).size.width * 0.3),
        child: Column(
          children: [
            Text(
              AppLocalizations.of(context)!.display,
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Flexible(
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(
                              text: AppLocalizations.of(context)!.classic,
                              style: TextStyle(
                                color: Colors.white,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  setState(() {
                                    display = DisplayOptions.NORMAL;
                                  });
                                }),
                        ]),
                      ),
                    ),
                    Theme(
                      data: ThemeData(unselectedWidgetColor: Colors.red),
                      child: Checkbox(
                        //    <-- label
                        value: display == DisplayOptions.NORMAL,
                        onChanged: (newValue) {
                          setState(() {
                            display = DisplayOptions.NORMAL;
                          });
                        },
                      ),
                    ),
                    Flexible(
                      child: RichText(
                        text: TextSpan(children: [
                          TextSpan(
                              text: AppLocalizations.of(context)!.cameraOn,
                              style: TextStyle(
                                color: Colors.white,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  setState(() {
                                    display = DisplayOptions.CAMERA_MODE;
                                  });
                                }),
                        ]),
                      ),
                    ),
                    Theme(
                      data: ThemeData(unselectedWidgetColor: Colors.red),
                      child: Checkbox(
                        //    <-- label
                        value: display == DisplayOptions.CAMERA_MODE,
                        onChanged: (newValue) {
                          setState(() {
                            display = DisplayOptions.CAMERA_MODE;
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
            Container(
              width: min(275, MediaQuery.of(context).size.width * 0.25),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.purple),
                borderRadius: BorderRadius.circular(50),
                color: Colors.purple,
              ),
              child: IconButton(
                onPressed: () => checkTime(),
                icon: Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              AppLocalizations.of(context)!.playlist,
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            SizedBox(
              height: 15,
              child: Text(
                overTime() ? AppLocalizations.of(context)!.overtime : "",
                style: TextStyle(color: Colors.red),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
                AppLocalizations.of(context)!.totalTime +
                    " " +
                    getClickedSongsLength(),
                style:
                    TextStyle(color: overTime() ? Colors.red : Colors.white)),
            Expanded(
              child: SizedBox(
                width: min(350, MediaQuery.of(context).size.width * 0.3),
                child: ListView.builder(
                    itemCount: songsClicked.length,
                    itemBuilder: (BuildContext ctx, index) {
                      return Container(
                        color: Colors.transparent,
                        alignment: Alignment.center,
                        child: createSongLine(index, songsClicked[index]),
                      );
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void getGenres() async {
    bool finished = await getValues.getGenres();
    hebrewGenres = getValues.getHebrewGenres;
    englishGenres = getValues.getEnglishGenres;
    if (finished)
      myLocale == "he"
          ? genres = List.from(hebrewGenres)
          : genres = List.from(englishGenres);
  }

  searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 8.0),
      child: Container(
        width: _smartPhone || !kIsWeb
            ? MediaQuery.of(context).size.width * 0.9
            : MediaQuery.of(context).size.width * 0.6,
        height: 48,
        decoration: BoxDecoration(
            border: Border.all(color: Color(0xFF8D3C8E), width: 2),
            borderRadius: BorderRadius.circular(50),
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 4,
              colors: [
                const Color(0xFF221A4D), // blue sky
                const Color(0xFF000000), // yellow sun
              ],
            )),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
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
                    hintText: AppLocalizations.of(context)!.search,
                    hintStyle: TextStyle(color: Colors.white),
                    fillColor: Colors.transparent,
                  ),
                  onChanged: (String value) {
                    if (value != previousValue)
                      setState(() {
                        if (currentGenre != "" &&
                            currentGenre != hebrewGenres[0] &&
                            currentGenre != englishGenres[0]) {
                          gridSongs = songs
                              .where((element) =>
                                  (element.title.contains(value) ||
                                      element.artist.contains(value)) &&
                                  element.genre ==
                                      hebrewGenres[
                                          genres.indexOf(currentGenre)])
                              .toList();
                        } else {
                          gridSongs = songs
                              .where((element) =>
                                  element.title.contains(value) ||
                                  element.artist.contains(value))
                              .toList();
                        }
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
                gridSongs = List.from(songs);
                if (!signedIn)
                  for (String name in demoSongNames) {
                    int index =
                        songs.indexWhere((element) => element.title == name);
                    if (index > -1) {
                      gridSongs.remove(songs[index]);
                      gridSongs.insert(0, songs[index]);
                    }
                  }
              });
            },
          ),
        ]),
      ),
    );
  }

  genreOptions() {
    if (_showGenreBar)
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
              height: genres.length * 50,
              width: 200,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      bottomRight: Radius.circular(15.0),
                      bottomLeft: Radius.circular(15.0)),
                  gradient: LinearGradient(
                    colors: <Color>[Colors.pink, Colors.blue],
                  )),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildListView(),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Transform.rotate(
                      angle: 270 * pi / 180,
                      child: IconButton(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        onPressed: () {
                          setState(() {
                            _showGenreBar = false;
                          });
                        },
                        icon: const Icon(Icons.arrow_back_ios_rounded),
                        color: Colors.pink[300],
                      ),
                    ),
                  )
                ],
              )),
        ),
      );
    else
      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: GenreButton(
              height: 40,
              width: 200,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    currentGenre == ""
                        ? AppLocalizations.of(context)!.categoryChoice
                        : currentGenre,
                    style: TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  Icon(
                    Icons.arrow_back_ios_rounded,
                    color: Colors.pink[300],
                  ),
                ],
              ),
              gradient: LinearGradient(
                colors: <Color>[Colors.pink, Colors.blue],
              ),
              onPressed: () {
                setState(() {
                  _showGenreBar = true;
                });
              }),
        ),
      );
  }

  Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
    // FirebaseCrashlytics.instance.crash();
// Elsewhere in your code
  }

  bool computerOrTablet() {
    return !_smartPhone ||
        MediaQueryData.fromWindow(WidgetsBinding.instance!.window)
                .size
                .shortestSide >
            530;
  }

  bool isTablet() {
    return _smartPhone &&
        MediaQueryData.fromWindow(WidgetsBinding.instance!.window)
                .size
                .shortestSide >
            530;
  }

  playButton() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Align(
        alignment: Alignment.bottomRight,
        child: FloatingActionButton(
          onPressed: () => checkTime(),
          autofocus: true,
          child: Icon(Icons.play_arrow),
          backgroundColor:
              songsClicked.length > 0 ? Color(0xFF8D3C8E) : Colors.black,
        ),
      ),
    );
  }

  void getBackgroundVideos() async {
    final databaseReference = FirebaseFirestore.instance;
    try {
      var doc =
          databaseReference.collection('pictures').doc('backgroundVideos');
      var vidDoc = await doc.get();
      if (vidDoc.exists) {
        setState(() {
          fastSongs = List.from(vidDoc.get("שירים קצביים"));
          slowSongs = List.from(vidDoc.get("שירים שקטים"));
          fastSongsVideos = List.from(vidDoc.get("קצבי"));
          slowSongsVideos = List.from(vidDoc.get("שקט"));
          specialVideos = List.from(vidDoc.get('special'));
        });
      }
    } catch (e) {
      setState(() {
        noVideos = true;
      });
    }
  }

  signInOptions(bool signInLoading, [signInError = ""]) {
    double popupHeight = 450;
    double popupWidth = 330;
    showDialog(
        context: context,
        barrierDismissible: signInLoading ? false : true,
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
                      if (!signInLoading)
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
                                  Navigator.of(context).pop();
                                  signInOptions(true);
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

  void openBilling() async {
    Navigator.of(context).pop();
    userHandler.setEmail(email);
    endTime = await userHandler.getUserEndTime();
    if (!checkOvertime())
      setState(() {
        signedIn = true;
      });
    else
      // signedIn =true;
      buildMobilePayment(false);
  }

  void addUserToFirebase() async {
    String? userEmail = firebaseAuth.currentUser!.email;
    if (userEmail != null) {
      // Navigator.pushNamedAndRemoveUntil(context, Constants.homeNavigate, (route) => false);
      bool userAdded = await userHandler.sendUserInfoToFirestore(
          userEmail,
          firebaseAuth.currentUser!.displayName,
          firebaseAuth.currentUser!.photoURL);
      if (userAdded) {
        setState(() {
          email = userEmail;
        });
        openBilling();
      } else
        catchSignInError();
    } else
      catchSignInError();
  }

  _showPendingUI() {}

  _handleError(IAPError iapError) {
    Navigator.of(context).pop();
    buildMobilePayment(
      false,
      AppLocalizations.of(context)!.purchaseError,
    );
  }

  _verifyPurchase(PurchaseDetails purchaseDetails) {}

  Future<bool> _deliverProduct(PurchaseDetails purchaseDetails) async {
    bool timeAdded = false;

    if (purchaseDetails.productID == "daily_buy") {
      endTime = Timestamp.fromDate(DateTime.now().add(Duration(days: 1)));
    } else {
      endTime = Timestamp.fromDate(DateTime(
          DateTime.now().year,
          DateTime.now().month + 1,
          DateTime.now().day,
          DateTime.now().hour,
          DateTime.now().minute));
    }
    userHandler.setEmail(service.getEmail());
    userHandler.setEndTime(endTime);
    timeAdded = await userHandler.addTimeToUser();
    // timeAdded = await UserHandler().addTimeToUser(service.getEmail(), endTime);
    if (timeAdded) {
      Navigator.of(context).pop();
      setState(() {
        signedIn = true;
      });
    } else {
      endTime = Timestamp(10, 10);
      Navigator.of(context).pop();
      buildMobilePayment(
        false,
        AppLocalizations.of(context)!.purchaseError,
      );
    }
    return timeAdded;
  }

  _handleInvalidPurchase(PurchaseDetails purchaseDetails) {}

  void startPaymentFlow(ProductDetails productDetails) {
    Navigator.of(context).pop();
    buildMobilePayment(true);
    final PurchaseParam purchaseParam =
        PurchaseParam(productDetails: productDetails);
    InAppPurchase.instance.buyConsumable(purchaseParam: purchaseParam);
  }

  placeNewOrder() {
    return Container(
      height: 50,
      color: Colors.black,
      child: Directionality(
        textDirection: Directionality.of(context),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            AppLocalizations.of(context)!.addTime + " ",
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
                              color:
                                  amIHovering ? Colors.blue[300] : Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                launch(
                                    "https://ashira-music.com/checkout/?add-to-cart=1102&quantity=$quantity");
                              })),
                  ),
                ),
                SizedBox(
                  width: 15,
                ),
                Center(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (PointerEvent details) =>
                        setState(() => addTimeHovering = true),
                    onExit: (PointerEvent details) => setState(() {
                      addTimeHovering = false;
                    }),
                    child: RichText(
                        text: TextSpan(
                            text: AppLocalizations.of(context)!.add,
                            style: TextStyle(
                              fontSize: 18,
                              color: addTimeHovering
                                  ? Colors.green[300]
                                  : Colors.green,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                addTime();
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
        ]),
      ),
    );
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
