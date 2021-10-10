import 'package:ashira_flutter/screens/AllSongs.dart';
import 'package:ashira_flutter/screens/Contracts.dart';
import 'package:ashira_flutter/screens/Promo.dart';

// import 'package:ashira_flutter/screens/SignIn.dart';
import 'package:ashira_flutter/screens/Sing.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
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
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: [
              const Locale('en', ''), // English, no country code
              const Locale('he', ''), // Hebrew, no country code
            ],
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
            },
          );
        }

        // Otherwise, show something whilst waiting for initialization to complete
        return Scaffold(
          body: Icon(Icons.cloud),
        );
      },
    );
  }
}
