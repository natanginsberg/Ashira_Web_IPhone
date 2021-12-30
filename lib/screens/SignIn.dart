import 'dart:html';
import 'dart:ui';

import 'package:ashira_flutter/model/Song.dart';
import 'package:ashira_flutter/screens/Sing.dart';
import 'package:ashira_flutter/utils/WpHelper.dart' as wph;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:wordpress_api/wordpress_api.dart' as wp;

import 'AllSongs.dart';

class SignIn extends StatefulWidget {
  @override
  _SignIn createState() => _SignIn();
}

final GlobalKey<ScaffoldState> _scaffoldKey1 = GlobalKey<ScaffoldState>();

const appleType = "apple";
const androidType = "android";
const desktopType = "desktop";

String id = "";
Timestamp endTime = Timestamp(10, 10);
String email = "";

class _SignIn extends State<SignIn> {
  bool hebrew = true;

  late DocumentReference dr;
  wph.WordPressAPI api = wph.WordPressAPI('https://ashira-music.com');

  String errorMessage = "";

  bool amIHoveringOrder = false;
  bool amIHoveringDemo = false;

  var _loading = false;

  @override
  void initState() {
    super.initState();
    _passwordEditingController = TextEditingController(text: "");
    _userNameEditingController = TextEditingController(text: "");
  }

  @override
  void dispose() {
    _userNameEditingController.dispose();
    _passwordEditingController.dispose();
    super.dispose();
  }

  late TextEditingController _passwordEditingController;
  late TextEditingController _userNameEditingController;

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
          key: _scaffoldKey1,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                  child: Center(
                child: Container(
                    width: MediaQuery.of(context).size.width,
                    // decoration: BoxDecoration(
                    //     image: DecorationImage(
                    //   image: AssetImage('assets/compBack.jpg'),
                    //   fit: BoxFit.fill,
                    // )),
                    child: Stack(children: [
                      Center(
                        child: Container(
                          height: MediaQuery.of(context).size.height - 40,
                          width: isSmartphone()
                              ? MediaQuery.of(context).size.width
                              : MediaQuery.of(context).size.width / 3,
                          decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 0.8,
                                colors: [
                                  const Color(0xFF2C2554),
                                  const Color(0xFF17131F),
                                ],
                              ),
                              border: Border.all(color: Colors.purple),
                              borderRadius:
                                  BorderRadius.all(new Radius.circular(20.0))),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 40.0, 0, 0),
                                child: Column(
                                  children: [
                                    Center(
                                      child: Text(
                                        // 'ברוכים הבאים',
                                        AppLocalizations.of(context)!.welcome,
                                        style: TextStyle(
                                            fontFamily: 'SignInFont',
                                            fontSize:
                                                tabletOrComputerFontSize(25),
                                            color: Colors.white),
                                      ),
                                    ),
                                    Center(
                                        child: Text(
                                      AppLocalizations.of(context)!
                                          .ashiraSystems,
                                      style: TextStyle(
                                          fontFamily: 'SignInFont',
                                          fontSize:
                                              tabletOrComputerFontSize(25),
                                          color: Colors.white),
                                    )),
                                    Center(
                                        child: Text(
                                      AppLocalizations.of(context)!.slogan,
                                      style: TextStyle(
                                          fontFamily: 'SignInFont',
                                          fontSize:
                                              tabletOrComputerFontSize(25),
                                          color: Colors.white),
                                    ))
                                  ],
                                ),
                              ),
                              Center(
                                  child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  AppLocalizations.of(context)!.enterPrompt,
                                  style: TextStyle(
                                      fontSize: 17, color: Colors.white),
                                ),
                              )),
                              Center(
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onEnter: (PointerEvent details) =>
                                      setState(() => amIHoveringOrder = true),
                                  onExit: (PointerEvent details) =>
                                      setState(() {
                                    amIHoveringOrder = false;
                                  }),
                                  child: RichText(
                                      text: TextSpan(
                                          text: AppLocalizations.of(context)!
                                              .placeOrder,
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: amIHoveringOrder
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
                              Center(
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  onEnter: (PointerEvent details) =>
                                      setState(() => amIHoveringDemo = true),
                                  onExit: (PointerEvent details) =>
                                      setState(() {
                                    amIHoveringDemo = false;
                                  }),
                                  child: RichText(
                                      text: TextSpan(
                                          text: AppLocalizations.of(context)!
                                              .demo,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: amIHoveringDemo
                                                ? Colors.green[300]
                                                : Colors.green,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                          recognizer: TapGestureRecognizer()
                                            ..onTap = () {
                                              startDemo();
                                            })),
                                ),
                              ),
                              Center(
                                child: Container(
                                    width: isSmartphone()
                                        ? MediaQuery.of(context).size.width / 2
                                        : MediaQuery.of(context).size.width / 4,
                                    height: tabletOrComputerFontSize(50),
                                    decoration: BoxDecoration(
                                        border:
                                            Border.all(color: Colors.purple),
                                        borderRadius: BorderRadius.all(
                                            new Radius.circular(20.0))),
                                    child: Center(
                                      child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: TextField(
                                          onSubmitted: (value) {
                                            if (!_loading)
                                              checkEmailAndContinue();
                                          },
                                          textAlign: TextAlign.center,
                                          decoration: new InputDecoration(
                                            hintText:
                                                AppLocalizations.of(context)!
                                                    .email,
                                            hintStyle: TextStyle(
                                                color: Color(0xFF787676)),
                                            fillColor: Colors.transparent,
                                          ),
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.white),
                                          autofocus: true,
                                          controller:
                                              _userNameEditingController,
                                        ),
                                      ),
                                    )),
                              ),
                              Center(
                                child: Container(
                                    width: isSmartphone()
                                        ? MediaQuery.of(context).size.width / 2
                                        : MediaQuery.of(context).size.width / 4,
                                    height: tabletOrComputerFontSize(50),
                                    decoration: BoxDecoration(
                                        border:
                                            Border.all(color: Colors.purple),
                                        borderRadius: BorderRadius.all(
                                            new Radius.circular(20.0))),
                                    child: Center(
                                      child: Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: TextField(
                                          onSubmitted: (value) {
                                            if (!_loading)
                                              checkEmailAndContinue();
                                          },
                                          textAlign: TextAlign.center,
                                          decoration: new InputDecoration(
                                            hintText:
                                                AppLocalizations.of(context)!
                                                    .orderNumber,
                                            hintStyle: TextStyle(
                                                color: Color(0xFF787676)),
                                            fillColor: Colors.transparent,
                                          ),
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.white),
                                          autofocus: true,
                                          controller:
                                              _passwordEditingController,
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
                                        padding: const EdgeInsets.fromLTRB(
                                            8.0, 4, 8.0, 4),
                                        child: TextButton(
                                            onPressed: checkEmailAndContinue,
                                            child: Directionality(
                                              textDirection: TextDirection.ltr,
                                              child: Text(
                                                AppLocalizations.of(context)!
                                                    .enter,
                                                style: TextStyle(
                                                    fontSize:
                                                        tabletOrComputerFontSize(
                                                            20),
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
                              if (errorMessage != "")
                                Center(
                                    child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    errorMessage,
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
                                  Center(
                                      child: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      AppLocalizations.of(context)!.personalUse,
                                      // data,
                                      style: TextStyle(
                                        //   fontFamily: 'SignInFont',
                                        color: Colors.white,
                                        //wordSpacing: 5,
                                        fontSize: tabletOrComputerFontSize(20),
                                        //height: 1.4,
                                        //letterSpacing: 1.6
                                      ),
                                    ),
                                  )),
                                  Center(
                                      child: Text(
                                    AppLocalizations.of(context)!.publicUse,
                                    style: TextStyle(
                                      //fontFamily: 'SignInFont',
                                      color: Colors.white,
                                      // wordSpacing: 5,
                                      fontSize: tabletOrComputerFontSize(20),
                                      //height: 1.4,
                                      // letterSpacing: 1.6
                                    ),
                                  )),
                                  Center(
                                      child: Text(
                                    'ashira.jewishkaraoke@gmail.com',
                                    style: TextStyle(
                                      //fontFamily: 'SignInFont',
                                      color: Colors.white,
                                      //wordSpacing: 5,
                                      fontSize: tabletOrComputerFontSize(20),
                                      // height: 1.4,
                                      //letterSpacing: 1.6
                                    ),
                                  )),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ])),
              )),
            ],
          )),
    );
  }

  checkEmailAndContinue() async {
    setState(() {
      _loading = true;
    });
    id = _passwordEditingController.text.toLowerCase();
    email = _userNameEditingController.text.toLowerCase();
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await checkFirebaseId(id);
      if (doc.exists) {
        if (!timeIsStillAllocated(doc)) {
          setState(() {
            errorMessage = AppLocalizations.of(context)!.outOfTimeError;
            _loading = false;
          });
          id = "";
          return;
        } else {
          startAllSongs();
          _loading = false;
          return;
        }
      } else {
        try {
          final wp.WPResponse res =
              await api.fetch('orders/' + id, namespace: "wc/v2");
          if (res.data['billing']['email'].toString().toLowerCase() == email) {
            await addTimeToFirebase(res);
          } else {
            setState(() {
              errorMessage = AppLocalizations.of(context)!.pendingError;
              _loading = false;
            });
            id = "";
          }
          if (res.data["status"] == "pending") {
            setState(() {
              errorMessage = AppLocalizations.of(context)!.pendingError;
              _loading = false;
            });
            id = "";
          }
          return;
        } catch (e) {
          try {
            Map<String, dynamic> args = new Map();
            args["billing-email"] = email;
            final wp.WPResponse res =
                await api.fetch('orders', namespace: "wc/v2", args: args);
            print(res.meta!.total);
            setState(() {
              errorMessage = AppLocalizations.of(context)!.noOrderNumberError;
              _loading = false;
            });
            id = "";
          } catch (e) {
            printConnectionError();
          }
        }
      }
    } catch (e) {
      printConnectionError();
    }
  }

  void incrementByOne(QueryDocumentSnapshot doc) async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    await deviceInfo.webBrowserInfo.then((value) => doc.reference.update({
          'signIns': value.vendor! +
              value.userAgent! +
              value.hardwareConcurrency.toString()
        }));
  }

  bool isSmartphone() {
    final userAgent = html.window.navigator.userAgent.toString().toLowerCase();
    // smartphone
    return (userAgent.contains("iphone") ||
        userAgent.contains("android") ||
        userAgent.contains("ipad") ||
        (html.window.navigator.platform!.toLowerCase().contains("macintel") &&
            html.window.navigator.maxTouchPoints! > 0));
  }

  tabletOrComputerFontSize(int size) {
    return isSmartphone() ? size : size;
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

  addTimeToFirebase(wp.WPResponse res) {
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
    email = res.data['billing']['email'];
    firestoreDoc['endTime'] = endTime;
    firestoreDoc['email'] = email;

    CollectionReference users =
        FirebaseFirestore.instance.collection('internetUsers');

    Future<void> addUser() {
      return users
          .doc(id)
          .set(firestoreDoc)
          .then((value) => startAllSongs())
          .catchError((error) => () {
                setState(() {
                  errorMessage = error.toString();
                });
              });
    }

    addUser();
  }

  printConnectionError() {
    setState(() {
      errorMessage = AppLocalizations.of(context)!.communicationError;
      _loading = false;
    });
    id = "";
  }

  startAllSongs() {
    // add email to send and add the timestamp
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => AllSongs()));
  }

  void startDemo() async {
    setState(() {
      _loading = true;
    });
    try {
      FirebaseAuth firebaseAuth = FirebaseAuth.instance;
      await firebaseAuth.signInAnonymously();
      DocumentSnapshot<Map<String, dynamic>> doc = await getDemoSong();
      List<Song> songsPassed = [];
      songsPassed.add(new Song(
          artist: doc.get('artist'),
          title: doc.get("title"),
          imageResourceFile: doc.get("imageResourceFile"),
          genre: doc.get("genre"),
          songResourceFile: doc.get("songResourceFile"),
          textResourceFile: doc.get("textResourceFile"),
          womanToneResourceFile: doc.get("womanToneResourceFile"),
          kidToneResourceFile: doc.get("kidToneResourceFile"),
          length: doc.get("length")));
      setState(() {
        _loading = false;
      });
      // Navigator.push(
      //     context,
      //     MaterialPageRoute(
      //         builder: (_) => Sing(songsPassed)));
    } catch (e) {
      printConnectionError();
    }
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDemoSong() async {
    try {
      var demoCollection =
          FirebaseFirestore.instance.collection('randomFields');

      var demoName = await demoCollection.doc("demo").get();

      var collection = FirebaseFirestore.instance.collection('songs');

      var doc = await collection.doc(demoName.get("songName")).get();

      return doc;
    } catch (e) {
      rethrow;
    }
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
