import 'dart:html';
import 'dart:math';
import 'dart:ui';

import 'package:ashira_flutter/model/Song.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';

import 'Sing.dart';

class AllSongs extends StatefulWidget {
  String id;

  AllSongs(this.id);

  @override
  _AllSongsState createState() => _AllSongsState(id);
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

List<Song> songs = [];

List<String> genres = ["All Songs", "hebrew"];

List<List<Song>> searchPath = [];
List<Song> gridSongs = [];

class _AllSongsState extends State<AllSongs> {
  // Locale _locale = Locale.fromSubtags(languageCode: "he");
  final TextEditingController controller = new TextEditingController();
  bool _showGenreBar = false;
  bool menuOpen = false;
  late bool onSearchTextChanged;

  String currentGenre = "All Songs";

  String previousValue = "";

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  List<Song> songsClicked = [];

  String id;

  bool accessDenied = false;

  _AllSongsState(this.id);

  void signInAnon() async {
    await firebaseAuth.signInAnonymously().then((value) => getSongs());
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // setState(() {
    signInAnon();
    // });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // setState(() {
    //   signInAnon();
    // });
    return MaterialApp(
      // locale: _locale,
      // localizationsDelegates: [
      //   AppLocalizations.delegate, // Add this line
      //   GlobalMaterialLocalizations.delegate,
      //   GlobalWidgetsLocalizations.delegate,
      //   GlobalCupertinoLocalizations.delegate,
      // ],
      // supportedLocales: [
      //   const Locale('en', ''), // English, no country code
      //   const Locale('he', ''), // Spanish, no country code
      // ],
      // theme: ThemeData(
      //   primarySwatch: Colors.blue,
      // ),
      home: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: BoxDecoration(
                gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.8,
              colors: [
                const Color(0xFF221A4D), // blue sky
                const Color(0xFF000000),
              ],
            )),
            child: Stack(children: [
              Column(
                children: [
                  SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            openWebsite();
                          },
                          icon: Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                        if (_showGenreBar)
                          Container(
                              height: 150,
                              width: 110,
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                colors: <Color>[Colors.pink, Colors.blue],
                              )),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  buildListView(),
                                  Align(
                                    alignment: Alignment.topCenter,
                                    child: Transform.rotate(
                                      angle: 270 * pi / 180,
                                      child: IconButton(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4.0),
                                        onPressed: () {
                                          setState(() {
                                            _showGenreBar = false;
                                          });
                                        },
                                        icon: const Icon(
                                            Icons.arrow_back_ios_rounded),
                                        color: Colors.pink[300],
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15.0, horizontal: 8.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: 48,
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: Color(0xFF8D3C8E), width: 2),
                          borderRadius: BorderRadius.circular(50),
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 4,
                            colors: [
                              const Color(0xFF221A4D), // blue sky
                              const Color(0xFF000000), // yellow sun
                            ],
                          )),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                                  textDirection:
                                      // _locale ==
                                      //         Locale.fromSubtags(languageCode: "he")
                                      //     ? TextDirection.rtl
                                      //     :
                                      TextDirection.rtl,
                                  child: TextField(
                                    style: TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                    controller: controller,
                                    decoration: new InputDecoration(
                                      hintText:
                                          // _locale ==
                                          //         Locale.fromSubtags(
                                          //             languageCode: "he")
                                          //     ?
                                          "חפש"
                                      // : "Search"
                                      ,
                                      hintStyle: TextStyle(color: Colors.white),
                                      fillColor: Colors.transparent,
                                    ),
                                    onChanged: (String value) {
                                      if (value != previousValue)
                                        setState(() {
                                          // searchPath.add(new List.from(gridSongs));
                                          gridSongs = value.length >
                                                  previousValue.length
                                              ? getNextSong(value)
                                              : getLastSong();
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
                                  gridSongs = List.from(searchPath.first);
                                  searchPath.clear();
                                });
                              },
                            ),
                          ]),
                    ),
                  ),
                  Expanded(
                    child: Container(
                        decoration: BoxDecoration(
                            gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.8,
                          colors: [
                            const Color(0xFF221A4D), // blue sky
                            const Color(0xFF000000), // yellow sun
                          ],
                        )),
                        margin: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
                        child: accessDenied
                            ? renewWording()
                            : buildGridView(gridSongs)),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: FloatingActionButton(
                    onPressed: () => checkEmailAndContinue(),
                    autofocus: true,
                    child: Icon(Icons.play_arrow),
                    backgroundColor: songsClicked.length > 0
                        ? Color(0xFF8D3C8E)
                        : Colors.black,
                  ),
                ),
              )
            ]),
          )),
    );
  }

  // void setLocale(Locale choice) {
  //   // var localeSubject = BehaviorSubject<Locale>();
  //   //
  //   // choice == 0
  //   //     ? localeSubject.sink.add(Locale('he ', ''))
  //   //     : localeSubject.sink.add(Locale('en', ''));
  //   //
  //   // return localeSubject.stream.distinct();
  //   setState(() {
  //     _locale = choice;
  //   });
  // }

  getSongs() {
    incrementFirebaseByOne();
    FirebaseFirestore.instance
        .collection('songs')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        // Map<String, dynamic> data = doc.data();
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
        if (songs.length > 0) gridSongs = new List.from(songs);
      });
    });
  }

  void incrementFirebaseByOne() async {
    int j = 0;
    // FirebaseFirestore.instance
    //     .collection('websiteEntrances')
    //     .get()
    //     .then((QuerySnapshot querySnapshot) {
    //       querySnapshot.docs.forEach((element) {j = element.data()['entries'] + 1;
    // });});
    FirebaseFirestore.instance
        .collection('websiteEntrances')
        .doc('entries')
        .update({'entries': FieldValue.increment(1)});

    // .update({'entries': FieldValue.increment(1)});
  }

  buildGridView(List<Song> songs) {
    return  GridView.builder(
            shrinkWrap: true,
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: isSmartphone() ? 0.75 : 0.6,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20),
            itemCount: songs.length,
            itemBuilder: (BuildContext ctx, index) {
              return Container(
                  alignment: Alignment.center,
                  child: buildSongLayout(songs[index])
                  // SongLayout(
                  //   song: songs[index],
                  //   index: index,

                  );
            });
  }

  getLastSong() {
    return searchPath.removeLast().toList();
  }

  getNextSong(String value) {
    List<Song> searchedSongs = gridSongs
        .where((element) =>
            element.title.contains(value) || element.artist.contains(value))
        .toList();
    // ignore: unnecessary_statements
    searchPath.add(List.from(gridSongs));
    return searchedSongs;
  }

  buildListView() {
    return Expanded(
      child: Column(children: [
        Expanded(
          child: ListView.builder(
              itemCount: genres.length,
              itemBuilder: (BuildContext ctx, index) {
                return Container(
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: createElevateButton(genre: genres[index]),
                );
              }),
        )
      ]),
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
          setState(() {
            if (genre == "All Songs")
              gridSongs = new List.from(songs);
            else if (currentGenre != genre) {
              gridSongs = new List.from(
                  songs.where((element) => element.genre == genre).toList());
            }
            currentGenre = genre;
            _showGenreBar = false;
          });
        },
        child: Text(
          genre,
          style: TextStyle(color: Colors.white),
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
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => Sing(songsPassed, id)));
      setState(() {
        songsClicked.clear();
      });
    }
  }

  buildSongLayout(Song song) {
    return ElevatedButton(
      style: ButtonStyle(backgroundColor:
          MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        return Colors.transparent;
      })),
      onPressed: () {
        setState(() {
          songInSongsClicked(song)
              ? songsClicked.removeWhere((element) =>
                  element.songResourceFile == song.songResourceFile)
              : songsClicked.add(song);
        });
      },
      child: Container(
        decoration: songInSongsClicked(song)
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                color: Color(0xFF8D3C8E),
                backgroundBlendMode: BlendMode.plus)
            : BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                color: Color(0xFF0A999A),
                backgroundBlendMode: BlendMode.colorDodge),
        child: Column(
          children: [
            Expanded(
              flex: 4,
              child: Container(
                  margin: EdgeInsets.all(5.0),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(15.0),
                      child: Image(
                          fit: BoxFit.fill,
                          image: NetworkImage(song.imageResourceFile)))),
            ),
            Expanded(
              flex: isSmartphone() ? 1 : 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      song.title,
                      style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Normal',
                          fontSize: 15),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Center(
                      child: Text(
                        song.artist,
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Normal',
                            fontSize: 15),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  songInSongsClicked(song)
                      ? (songsClicked.indexWhere((element) =>
                                  element.songResourceFile ==
                                  song.songResourceFile) +
                              1)
                          .toString()
                      : "",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  bool isSmartphone() {
    final userAgent = html.window.navigator.userAgent.toString().toLowerCase();
    return (userAgent.contains("iphone") ||
        userAgent.contains("android") ||
        userAgent.contains("ipad") ||
        (html.window.navigator.platform!.toLowerCase().contains("macintel") &&
            html.window.navigator.maxTouchPoints! > 0));
  }

  songInSongsClicked(Song song) {
    if (songsClicked.length > 0)
      for (int i = 0; i < songsClicked.length; i++) {
        if (song.songResourceFile == songsClicked[i].songResourceFile)
          return true;
      }
    return false;
  }

  renewWording() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
            child: Text(
          'זמן הרשמתך נגמר',
          style: TextStyle(
              fontFamily: 'SignInFont',
              color: Colors.yellow,
              wordSpacing: 5,
              fontSize: 30,
              height: 1.4,
              letterSpacing: 1.6),
        )),
        Center(
            child: Text(
          'לפרטים צרו איתנו קשר',
          style: TextStyle(
              fontFamily: 'SignInFont',
              color: Colors.white,
              wordSpacing: 5,
              fontSize: 20,
              height: 1.4,
              letterSpacing: 1.6),
        )),
        Center(
            child: Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            'אימייל: ashirajewishkaraoke@gmail.com',
            style: TextStyle(
                fontFamily: 'SignInFont',
                color: Colors.white,
                wordSpacing: 5,
                fontSize: 20,
                height: 1.4,
                letterSpacing: 1.6),
          ),
        )),
        Center(
            child: Text(
          'אשר - 053-3381427  יוסי - 058-7978079',
          style: TextStyle(
              fontFamily: 'SignInFont',
              color: Colors.white,
              wordSpacing: 5,
              fontSize: 20,
              height: 1.4,
              letterSpacing: 1.6),
        )),
      ],
    );
  }

  checkEmailAndContinue() async {
    bool valid = false;
    // CollectionReference collectionRef =
    //     FirebaseFirestore.instance.collection('collectionName');
    final databaseReference = FirebaseFirestore.instance;
    try {
      var doc =
          await databaseReference.collection('internetUsers').doc(id).get();
      if (doc.exists) {
        valid = true;
        playSongs();
        return;
      } else {
        setState(() {
          accessDenied = true;
        });
      }
    } catch (e) {
      setState(() {
        accessDenied = true;
      });
    }
    // collectionRef.document()
    // FirebaseFirestore.instance
    //     .collection('internetUsers')
    //     .get()
    //     .then((QuerySnapshot querySnapshot) {
    //   querySnapshot.docs.forEach((doc) {
    //     Map<String, dynamic> data = doc.data();
    //     if (email == data['email']) {
    //       valid = true;
    //       playSongs();
    //       return;
    //     }
    //   });
    //   if (!valid)
    //     setState(() {
    //       accessDenied = true;
    //     });
    // });
  }
}
