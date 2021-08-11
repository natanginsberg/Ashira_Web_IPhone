import 'dart:html';

import 'package:ashira_flutter/screens/AllSongs.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;

class SignIn extends StatefulWidget {
  @override
  _SignIn createState() => _SignIn();
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

String id = "";

const appleType = "apple";
const androidType = "android";
const desktopType = "desktop";

class _SignIn extends State<SignIn> {
  bool _needPermission = false;
  bool hebrew = true;

  late DocumentReference dr;

  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController(text: "");
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }
  bool _isEditingText = false;

  late TextEditingController _editingController;

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
                            if (!isSmartphone())
                              SizedBox(
                                height: 20,
                              ),
                            Center(
                                child: Text(
                              'לכניסה הזינו סיסמא',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.white),
                            )),
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
                                          hintText:
                                              '******',
                                          hintStyle: TextStyle(
                                              color: Color(0xFF787676)),
                                          fillColor: Colors.transparent,
                                        ),
                                        style: TextStyle(
                                            fontSize: 15, color: Colors.white),
                                        autofocus: true,
                                        controller: _editingController,
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
                            Center(
                                child: Text(
                              _needPermission ? 'אימייל לא תקין' : "",
                              style: TextStyle(
                                color: Colors.red,
                                //wordSpacing: 5,
                                fontSize: 20,
                                //height: 1.4,
                                //letterSpacing: 1.6
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
                                  'asher307901520@gmail.com',
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

  checkEmailAndContinue() {
    bool valid = false;
    FirebaseFirestore.instance
        .collection('internetUsers')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        if (_editingController.text.toLowerCase() == doc.get("email")) {
          id = doc.id;
          valid = true;
          incrementByOne(doc);
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => AllSongs(doc.id)));
          return;
        }
      });
      if (!valid)
        setState(() {
          _needPermission = true;
        });
    });
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
}

