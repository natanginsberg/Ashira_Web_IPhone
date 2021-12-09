// import 'package:ashira_flutter/screens/AllSongs.dart';
import 'package:ashira_flutter/screens/AllSongs.dart';

// import 'package:ashira_flutter/screens/AllSongsTablet.dart';
import 'package:ashira_flutter/screens/Contracts.dart';
import 'package:ashira_flutter/screens/MobileSing.dart';
import 'package:ashira_flutter/screens/Promo.dart';

// import 'package:ashira_flutter/screens/SignIn.dart';
import 'package:ashira_flutter/screens/Sing.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatefulWidget {
  static void setLocale(BuildContext context, Locale newLocale) async {
    _AppState state = context.findAncestorStateOfType<_AppState>()!;
    state.changeLanguage(newLocale);
  }

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  Locale _locale = Locale('ps');

  String originalLanguageCode = "ps";
  String originalCountryCode = "ar";

  changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void _initializeLocale(BuildContext context) {
    Locale myLocale = Localizations.localeOf(context);
    App.setLocale(context, myLocale);
    // return myLocale;
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: new MediaQueryData(),
      child: FutureBuilder(
        // Initialize FlutterFire:
        future: _initialization,
        builder: (context, snapshot) {
          // Check for errors
          // if (snapshot.hasError) {
          //   return SomethingWentWrong();
          // }

          // Once complete, show your application
          if (snapshot.connectionState == ConnectionState.done) {
            return MaterialApp(
              // locale: _locale,
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: [
                const Locale('en', 'US'), // English, no country code
                const Locale('he', 'IL'), // Hebrew, no country code
              ],
              localeResolutionCallback: (locale, supportedLocales) {
                print(locale!.languageCode);
                for (var supportedLocaleLanguage in supportedLocales) {
                  if (supportedLocaleLanguage.languageCode ==
                      locale.languageCode) {
                    // if (originalCode == "") {
                    originalLanguageCode = locale.languageCode;
                    // }
                    _locale = Locale(locale.languageCode);
                    return supportedLocaleLanguage;
                  }
                }
                return _locale == Locale('ps')
                    ? supportedLocales.last
                    : _locale;
              },
              locale: _locale,
              // locale: Locale(""),
              theme: ThemeData(
                primarySwatch: Colors.blue,
              ),
              initialRoute: '/',
              routes: {
                '/': (context) => Promo(),
                '/contracts': (context) => Contracts(),
                // '/signIn': (context) => SignIn(),
                '/allSongs': (context) => AllSongs(),
                '/sing': (context) => Sing(songs, ""),
                '/mobileSing': (context) => MobileSing(songs, ""),
              },
            );
          }

          // Otherwise, show something whilst waiting for initialization to complete
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(
              body: Icon(Icons.cloud),
            ),
          );
        },
      ),
    );
  }
}
