import 'dart:html';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:wordpress_api/wordpress_api.dart' as wp;

import 'AllSongs.dart';

class SignIn extends StatefulWidget {
  @override
  _SignIn createState() => _SignIn();
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

const appleType = "apple";
const androidType = "android";
const desktopType = "desktop";

class _SignIn extends State<SignIn> {
  bool _needPermission = false;
  bool hebrew = true;

  late DocumentReference dr;
  wp.WooCredentials credentials = new wp.WooCredentials(
      "f05eb5fc740b05eca1c9ad164566c545956bc2ef",
      "7da22cebd8183c9ff96456b8a58dea8093c363f2");
  wp.WordPressAPI api = wp.WordPressAPI('https://ashira-music.com',
      wooCredentials: wp.WooCredentials(
          ));

  String errorMessage = "";

  String id = "";
  String email = "";

  bool amIHovering = false;

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

  bool _isEditingText = false;

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
        key: _scaffoldKey,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                child: Center(
              child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                      gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      //const Color(0xFF9812E0),
                      const Color(0xFF2C2554), // yellow sun
                      const Color(0xFF17131F), // blue sky
                    ],
                  )),
                  child: Stack(children: [
                    SvgPicture.asset(
                      'Sun_loading_background.svg',
                      width: MediaQuery.of(context).size.width,
                    ),
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
                                const Color(0x5C221A4D), // blue sky
                                const Color(0x54000000), // yellow sun
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
                              padding: const EdgeInsets.fromLTRB(0, 40.0, 0, 0),
                              child: Column(
                                children: [
                                  Center(
                                    child: Text(
                                      'ברוכים הבאים',
                                      style: TextStyle(
                                          fontFamily: 'SignInFont',
                                          fontSize:
                                              tabletOrComputerFontSize(25),
                                          color: Colors.white),
                                    ),
                                  ),
                                  Center(
                                      child: Text(
                                    'למערכות אשירה',
                                    style: TextStyle(
                                        fontFamily: 'SignInFont',
                                        fontSize: tabletOrComputerFontSize(25),
                                        color: Colors.white),
                                  )),
                                  Center(
                                      child: Text(
                                    'אפליקציית הקריוקי היהודי',
                                    style: TextStyle(
                                        fontFamily: 'SignInFont',
                                        fontSize: tabletOrComputerFontSize(25),
                                        color: Colors.white),
                                  ))
                                ],
                              ),
                            ),
                            Center(
                                child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                'Enter Email and Order # - לכניסה הזינו אימייל ומספר הזמנה',
                                style: TextStyle(
                                    fontSize: 15, color: Colors.white),
                              ),
                            )),
                            Center(
                              child: Directionality(
                                textDirection: TextDirection.ltr,
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
                                          text:
                                              'To place an Order # click here - לקניית מספר הזמנה הקליקו כאן',
                                          style: TextStyle(
                                            fontSize: 15,
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
                            ),
                            Center(
                              child: Container(
                                  width: isSmartphone()
                                      ? MediaQuery.of(context).size.width / 2
                                      : MediaQuery.of(context).size.width / 4,
                                  height: tabletOrComputerFontSize(50),
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.purple),
                                      borderRadius: BorderRadius.all(
                                          new Radius.circular(20.0))),
                                  child: Center(
                                    child: Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: TextField(
                                        onSubmitted: (value) {
                                          checkEmailAndContinue();
                                        },
                                        textAlign: TextAlign.center,
                                        decoration: new InputDecoration(
                                          hintText: 'Email - אימייל',
                                          hintStyle: TextStyle(
                                              color: Color(0xFF787676)),
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
                                  height: tabletOrComputerFontSize(50),
                                  decoration: BoxDecoration(
                                      border: Border.all(color: Colors.purple),
                                      borderRadius: BorderRadius.all(
                                          new Radius.circular(20.0))),
                                  child: Center(
                                    child: Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: TextField(
                                        onSubmitted: (value) {
                                          checkEmailAndContinue();
                                        },
                                        textAlign: TextAlign.center,
                                        decoration: new InputDecoration(
                                          hintText: 'Order # - מספר הזמנה',
                                          hintStyle: TextStyle(
                                              color: Color(0xFF787676)),
                                          fillColor: Colors.transparent,
                                        ),
                                        style: TextStyle(
                                            fontSize: 15, color: Colors.white),
                                        autofocus: true,
                                        controller: _passwordEditingController,
                                      ),
                                    ),
                                  )),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.all(
                                      new Radius.circular(10))),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(8.0, 4, 8.0, 4),
                                child: TextButton(
                                    onPressed: checkEmailAndContinue,
                                    child: Text(
                                      'כניסה',
                                      style: TextStyle(
                                          fontSize:
                                              tabletOrComputerFontSize(20),
                                          color: Colors.white),
                                    )),
                              ),
                            ),
                            if (errorMessage != "")
                              Center(
                                  child: Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  errorMessage,
                                  style: TextStyle(
                                    color: Colors.red,
                                    //wordSpacing: 5,
                                    fontSize: 20,
                                    //height: 1.4,
                                    //letterSpacing: 1.6
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
                                    'המערכת מיועדת להפעלת קריוקי',
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
                                  'לקבלת הצעת מחיר צרו איתנו קשר',
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
                                Center(
                                    child: Text(
                                  'אשר - 053-3381427  יוסי - 058-7978079',
                                  style: TextStyle(
                                    // fontFamily: 'SignInFont',
                                    color: Colors.white,
                                    //wordSpacing: 5,
                                    fontSize: tabletOrComputerFontSize(20),
                                    //height: 1.4,
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
        ),
      ),
    );
  }

  checkEmailAndContinue() async {
    id = _passwordEditingController.text.toLowerCase();
    email = _userNameEditingController.text.toLowerCase();
    try {
      DocumentSnapshot<Map<String, dynamic>> doc = await checkFirebaseId(id);
      if (doc.exists) {
        if (!timeIsStillAllocated(doc)) {
          setState(() {
            _needPermission = true;
            errorMessage = "Your time is up - אזל לך הזמן";
          });
          return;
        } else {
          startAllSongs();
          return;
        }
      }
      try {
        final wp.WPResponse res =
            await api.fetch('orders/' + id, namespace: "wc/v2");
        if (res.data['billing']['email'].toString().toLowerCase() == email) {
          await addTimeToFirebase(res);
        } else {
          setState(() {
            errorMessage = "Email and Order # do not match - אין התאמה בנתונים";
          });
        }
        return;
      } catch (e) {
        try {
          final wp.WPResponse res =
              await api.fetch('orders', namespace: "wc/v2");
          setState(() {
            // errorMessage = "Invalid Order Number - מספר הזמנה שגוי";
            errorMessage = e.toString();
          });
        } catch (e) {
          printConnectionError();
        }
      }
    } catch (e) {
      printConnectionError();
    }
  }

  void incrementByOne(QueryDocumentSnapshot doc) async {
    String deviceIdentifier = "unknown";
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    await deviceInfo.webBrowserInfo.then((value) => doc.reference.update({
          'signIns': value.vendor! +
              value.userAgent! +
              value.hardwareConcurrency.toString()
        }));
    // deviceIdentifier = webInfo.vendor! +
    //     webInfo.userAgent! +
    //     webInfo.hardwareConcurrency.toString();
    // return deviceIdentifier;
  }

  bool isSmartphone() {
    final userAgent = html.window.navigator.userAgent.toString().toLowerCase();
    // smartphone
    return (userAgent.contains("iphone") ||
        userAgent.contains("android")

        // tablet
        ||
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
    Timestamp endTime = doc.get("endTime");
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
    firestoreDoc['endTime'] =
        Timestamp.fromDate(DateTime.now().add(Duration(hours: quantity)));
    firestoreDoc['email'] = res.data['billing']['email'];
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
      errorMessage = "Connection error - בעיית תקשרות";
    });
  }

  startAllSongs() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => AllSongs(id)));
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
