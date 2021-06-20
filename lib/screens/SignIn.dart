import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:path_provider/path_provider.dart';

class SignIn extends StatefulWidget {
  @override
  _SignIn createState() => _SignIn();
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class _SignIn extends State<SignIn> {
  bool _needPermission = false;

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

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/contractApproved.txt');
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
                        width: MediaQuery.of(context).size.width / 3,
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
                                          fontSize: 25,
                                          color: Colors.white),
                                    ),
                                  ),
                                  Center(
                                      child: Text(
                                    'למערכות אשירה',
                                    style: TextStyle(
                                        fontSize: 25, color: Colors.white),
                                  )),
                                  Center(
                                      child: Text(
                                    'אפליקציית הקריוקי היהודי ',
                                    style: TextStyle(
                                        fontSize: 25, color: Colors.white),
                                  ))
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 20,
                            ),
                            Center(
                                child: Text(
                              'לכניסה הזינו כתובת מייל',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.white),
                            )),
                            Center(
                              child: Container(
                                  width: MediaQuery.of(context).size.width / 4,
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
                                          checkEmailAndContinue();
                                        },
                                        textAlign: TextAlign.center,
                                        decoration: new InputDecoration(
                                          hintText:
                                              'your_email@your_domain.com',
                                          hintStyle: TextStyle(
                                              color: Color(0xFFB8B6B6)),
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
                                          fontSize: 20, color: Colors.white),
                                    )),
                              ),
                            ),
                            Center(
                                child: Text(
                              _needPermission
                                  ? 'אימייל לא תקין'
                                  : "",
                              style: TextStyle(
                                  color: Colors.red,
                                  wordSpacing: 5,
                                  fontSize: 20,
                                  height: 1.4,
                                  letterSpacing: 1.6),
                            )),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Center(
                                    child: Text(
                                  'לקבלת גישה למערכת אנא צרו עימנו קשר',
                                  style: TextStyle(
                                      color: Colors.white,
                                      wordSpacing: 5,
                                      fontSize: 20,
                                      height: 1.4,
                                      letterSpacing: 1.6),
                                )),
                                Center(
                                    child: Text(
                                  'אימייל: ashirajewishkaraoke@gmail.com',
                                  style: TextStyle(
                                      color: Colors.white,
                                      wordSpacing: 5,
                                      fontSize: 20,
                                      height: 1.4,
                                      letterSpacing: 1.6),
                                )),
                                Center(
                                    child: Text(
                                  'אשר - 053-3381427  יוסי - 058-7978079',
                                  style: TextStyle(
                                      color: Colors.white,
                                      wordSpacing: 5,
                                      fontSize: 20,
                                      height: 1.4,
                                      letterSpacing: 1.6),
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
    FirebaseFirestore.instance
        .collection('internetUsers')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        Map<String, dynamic> data = doc.data();
        if (_editingController.text == data['email'])
          Navigator.pushReplacementNamed(context, '/allSongs');
        else
          setState(() {
            _needPermission = true;
          });
      });
    });
  }
}
