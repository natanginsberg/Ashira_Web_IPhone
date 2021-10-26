import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../main.dart';

class Promo extends StatefulWidget {
  @override
  _PromoState createState() => _PromoState();
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

class _PromoState extends State<Promo> {
  late Timer timer;

  @override
  void dispose() {
    // TODO: implement dispose
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // App.setLocale(context, Localizations.localeOf(context));
    timer = Timer(Duration(seconds: 1), () => moveToNextScreen(true));
    return MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', ''), // English, no country code
        const Locale('iw', ''), // Hebrew, no country code
      ],
      home: Scaffold(
        key: _scaffoldKey,
        body: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: kIsWeb
                    ? [const Color(0xFF221A4D), const Color(0xFF000000)]
                    : [
                        Colors.black,
                        Colors.black87,
                      ],
              ),
            ),
            // color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image(
                  image: AssetImage('assets/ashira.png'),
                  fit: BoxFit.fill,
                ),
                Text(
                  AppLocalizations.of(context)!.appName,
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
                  AppLocalizations.of(context)!.slogan,
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
                  AppLocalizations.of(context)!.acum,
                  // 'שומרים על זכויות יוצרים עם אקו"ם',
                  style: TextStyle(color: Color(0x80FFFFFF), fontSize: 18),
                ),
                if (!kIsWeb)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        height: 120.0,
                        width: 350.0,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('toker.jpg'),
                            fit: BoxFit.fill,
                          ),
                          shape: BoxShape.rectangle,
                        ),
                      ),
                      Container(
                        height: 120.0,
                        width: 350.0,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('adi.jpg'),
                            fit: BoxFit.fill,
                          ),
                          shape: BoxShape.rectangle,
                        ),
                        // child: FlatButton(
                        //   onPressed: () {},
                        //   child: Text(""),
                        // ),
                      ),
                    ],
                  ),
              ],
            )),
      ),
    );
  }

  moveToNextScreen(bool approved) {
    // if (approved == true)
    Navigator.pushReplacementNamed(context, '/allSongs');
    // else
    //   Navigator.pushReplacementNamed(context, '/contracts');
  }
}
