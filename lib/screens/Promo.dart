import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Promo extends StatefulWidget {
  @override
  _PromoState createState() => _PromoState();
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class _PromoState extends State<Promo> {
  late Timer timer;

  // Future<String> get _localPath async {
  //   final directory = await getApplicationDocumentsDirectory();
  //
  //   return directory.path;
  // }

  // Future<File> get _localFile async {
  //   final path = await _localPath;
  //   return File('$path/contractApproved.txt');
  // }

  @override
  void dispose() {
    // TODO: implement dispose
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    timer = Timer(Duration(seconds: 1), () => moveToNextScreen(true));
    // contractApproved().then((value) async => moveToNextScreen(value)));
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        body: Container(
            decoration: BoxDecoration(
                gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.8,
              colors: [
                const Color(0xFF221A4D), // blue sky
                const Color(0xFF000000), // yellow sun
              ],
            )),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image(
                  image: AssetImage('assets/ashira.png'),
                  fit: BoxFit.fill,
                ),
                Text(
                  'Ashira',
                  style: TextStyle(
                      fontSize: 50,
                      color: Colors.white,
                      // fontFamily: 'Logo',
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w500),
                ),
                SizedBox(
                  height: 10.0,
                ),
                Text(
                  // "Jewish Karaoke App",
                  'אפליקציה השירה היהודית',
                  style: TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 25,
                      // fontFamily: 'Normal',
                      letterSpacing: 1.5),
                ),
                Row(children: []),
                SizedBox(
                  height: 10.0,
                ),
                Container(
                  height: 40.0,
                  width: 40.0,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/acum-logo.jpg'),
                      fit: BoxFit.fill,
                    ),
                    shape: BoxShape.rectangle,
                  ),
                  // child: FlatButton(
                  //   onPressed: () {},
                  //   child: Text(""),
                  // ),
                ),
                SizedBox(
                  height: 10.0,
                ),
                Text(
                  // 'Copyright with ACUM',
                  'שומרים על זכויות יוצרים עם אקו"ם',
                  style: TextStyle(color: Color(0x80FFFFFF), fontSize: 18),
                )
              ],
            )),
      ),
    );
  }

  moveToNextScreen(bool approved) {
    // if (approved == true)
    Navigator.pushReplacementNamed(context, '/signIn');
    // else
    //   Navigator.pushReplacementNamed(context, '/contracts');
  }

// Future<bool> contractApproved() async {
//   try {
//     final file = await _localFile;
//
//     Read the file.
// String contents = await file.readAsString();
//
// return contents == "32";
// } catch (e) {
//   If encountering an error, return 0.
// return false;
// }
// }
}
