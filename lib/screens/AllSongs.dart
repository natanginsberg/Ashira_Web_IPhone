import 'dart:math';
import 'dart:ui';

import 'package:ashira_flutter/model/Song.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Sing.dart';

class AllSongs extends StatefulWidget {
  @override
  _AllSongsState createState() => _AllSongsState();
}

final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

List<Song> songs = [];

List<String> genres = ["All Songs", "hebrew"];

List<List<Song>> searchPath = [];
List<Song> gridSongs = [];

class _AllSongsState extends State<AllSongs> {
  final TextEditingController controller = new TextEditingController();
  bool _showGenreBar = false;
  bool menuOpen = false;
  late bool onSearchTextChanged;

  String currentGenre = "All Songs";

  String previousValue = "";

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  List<Song> songsClicked = [];

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
  Widget build(BuildContext context) {
    // setState(() {
    //   signInAnon();
    // });
    return MaterialApp(
      home: Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.transparent,
          body:
              // Stack(
              //   alignment: Alignment.center,
              //   children: [
              //     Positioned(
              //       top: 70,
              //       child: Padding(
              //         padding:
              //             const EdgeInsets.symmetric(vertical: 15.0, horizontal: 8.0),
              //         child: Container(
              //           width: MediaQuery.of(context).size.width * 0.8,
              //           height: 48,
              //           decoration: BoxDecoration(
              //               border: Border.all(color: Color(0xFF8D3C8E), width: 2),
              //               borderRadius: BorderRadius.circular(50),
              //               gradient: RadialGradient(
              //                 center: Alignment.center,
              //                 radius: 0.8,
              //                 colors: [
              //                   const Color(0xFF221A4D), // blue sky
              //                   const Color(0xFF000000), // yellow sun
              //                 ],
              //               )),
              //           child: Row(
              //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //               children: [
              //                 Padding(
              //                   padding: const EdgeInsets.all(8.0),
              //                   child: Icon(
              //                     Icons.search,
              //                     color: Colors.white,
              //                   ),
              //                 ),
              //                 SizedBox(
              //                   width: MediaQuery.of(context).size.width * 0.5,
              //                   height: 48,
              //                   child: Center(
              //                     child: TextField(
              //                       style: TextStyle(color: Colors.white),
              //                       textAlign: TextAlign.center,
              //                       controller: controller,
              //                       decoration: new InputDecoration(
              //                         hintText: 'Search',
              //                         hintStyle: TextStyle(color: Colors.white),
              //                         fillColor: Colors.transparent,
              //                       ),
              //                       onChanged: (String value) {
              //                         setState(() {
              //                           // searchPath.add(new List.from(gridSongs));
              //                           gridSongs = value.length > previousValue.length
              //                               ? getNextSong(value)
              //                               : getLastSong();
              //                           previousValue = value;
              //                         });
              //                       },
              //                     ),
              //                   ),
              //                 ),
              //                 IconButton(
              //                   icon: new Icon(
              //                     Icons.cancel,
              //                     color: Colors.white,
              //                   ),
              //                   onPressed: () {
              //                     controller.clear();
              //                     previousValue = "";
              //                     setState(() {
              //                       gridSongs = List.from(searchPath.first);
              //                       searchPath.clear();
              //                     });
              //                   },
              //                 ),
              //               ]),
              //         ),
              //       ),
              //     ),
              //     Positioned.fill(
              //       top: 150,
              //       child: Container(
              //           height: MediaQuery.of(context).size.height - 400,
              //           decoration: BoxDecoration(
              //               gradient: RadialGradient(
              //             center: Alignment.center,
              //             radius: 0.8,
              //             colors: [
              //               const Color(0xFF221A4D), // blue sky
              //               const Color(0xFF000000), // yellow sun
              //             ],
              //           )),
              //           margin: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 0.0),
              //           child: buildGridView(gridSongs)),
              //     ),
              //     Align(
              //       alignment: Alignment.topCenter,
              //       child: SafeArea(
              //         child: Row(
              //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //           children: [
              //             IconButton(
              //               onPressed: () {},
              //               icon: Icon(
              //                 Icons.menu,
              //                 color: Colors.white,
              //               ),
              //             ),
              //             if (_showGenreBar)
              //               Container(
              //                   height: 150,
              //                   width: 110,
              //                   decoration: BoxDecoration(
              //                       gradient: LinearGradient(
              //                     colors: <Color>[Colors.pink, Colors.blue],
              //                   )),
              //                   child: Row(
              //                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //                     children: [
              //                       buildListView(),
              //                       Align(
              //                         alignment: Alignment.topCenter,
              //                         child: Transform.rotate(
              //                           angle: 270 * pi / 180,
              //                           child: IconButton(
              //                             padding: const EdgeInsets.symmetric(
              //                                 horizontal: 4.0),
              //                             onPressed: () {
              //                               setState(() {
              //                                 _showGenreBar = false;
              //                               });
              //                             },
              //                             icon:
              //                                 const Icon(Icons.arrow_back_ios_rounded),
              //                             color: Colors.pink[300],
              //                           ),
              //                         ),
              //                       )
              //                     ],
              //                   ))
              //             else
              //               GenreButton(
              //                   height: 40,
              //                   width: 110,
              //                   child: Row(
              //                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //                     children: [
              //                       Text(
              //                         currentGenre,
              //                         style: TextStyle(color: Colors.white),
              //                       ),
              //                       Icon(
              //                         Icons.arrow_back_ios_rounded,
              //                         color: Colors.pink[300],
              //                       ),
              //                     ],
              //                   ),
              //                   gradient: LinearGradient(
              //                     colors: <Color>[Colors.pink, Colors.blue],
              //                   ),
              //                   onPressed: () {
              //                     setState(() {
              //                       _showGenreBar = true;
              //                     });
              //                   }),
              //             IconButton(
              //               onPressed: () {},
              //               icon: Icon(
              //                 Icons.mic,
              //                 color: Colors.white,
              //               ),
              //             ),
              //           ],
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
              Container(
            decoration: BoxDecoration(
                gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.8,
              colors: [
                const Color(0xFF221A4D), // blue sky
                const Color(0xFF000000), // yellow sun
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
                                  )
                                ],
                              ))
                        else
                          // GenreButton(
                          //     height: 40,
                          //     width: 110,
                          //     child: Row(
                          //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          //       children: [
                          //         Text(
                          //           currentGenre,
                          //           style: TextStyle(color: Colors.white),
                          //         ),
                          //         Icon(
                          //           Icons.arrow_back_ios_rounded,
                          //           color: Colors.pink[300],
                          //         ),
                          //       ],
                          //     ),
                          //     gradient: LinearGradient(
                          //       colors: <Color>[Colors.pink, Colors.blue],
                          //     ),
                          //     onPressed: () {
                          //       setState(() {
                          //         _showGenreBar = true;
                          //       });
                          //     }),
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                              Icons.mic,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15.0, horizontal: 8.0),
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: 48,
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: Color(0xFF8D3C8E), width: 2),
                          borderRadius: BorderRadius.circular(50),
                          gradient: RadialGradient(
                            center: Alignment.center,
                            radius: 0.8,
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
                                  textDirection: TextDirection.rtl,
                                  child: TextField(
                                    style: TextStyle(color: Colors.white),
                                    textAlign: TextAlign.center,
                                    controller: controller,
                                    decoration: new InputDecoration(
                                      hintText: 'חפש',
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
                        child: buildGridView(gridSongs)),
                  ),
                ],
              ),
              // if (menuOpen)
              //   Container(
              //     width: MediaQuery.of(context).size.width,
              //     height: MediaQuery.of(context).size.height * 0.7,
              //     decoration: BoxDecoration(
              //         gradient: LinearGradient(
              //       begin: Alignment.topCenter,
              //       end: Alignment.bottomCenter,
              //       colors: <Color>[Colors.pink, Colors.blue],
              //     )),
              //     child: Column(
              //       children: [
              //         Align(
              //           alignment: Alignment.topLeft,
              //           child: SafeArea(
              //             child: IconButton(
              //               onPressed: () {
              //                 // setState(() {
              //                 //   menuOpen = false;
              //                 // });
              //                 openWebsite();
              //               },
              //               icon: Icon(
              //                 Icons.keyboard_arrow_left_rounded,
              //                 color: Colors.white,
              //               ),
              //             ),
              //           ),
              //         ),
              //         Expanded(
              //           child: Center(
              //             child: RichText(
              //               textAlign: TextAlign.center,
              //               text: TextSpan(children: [
              //                 TextSpan(
              //                     text: "Visit our website at \n",
              //                     style: TextStyle(color: Colors.white)),
              //                 TextSpan(
              //                     text: "https://ashira-music.com/",
              //                     style: TextStyle(
              //                       color: Colors.white,
              //                       decoration: TextDecoration.underline,
              //                     ),
              //                     recognizer: new TapGestureRecognizer()
              //                       ..onTap = () async {
              //                         final url = "https://ashira-music.com/";
              //                         if (await canLaunch(url)) {
              //                           await launch(
              //                             url,
              //                           );
              //                         }
              //                       })
              //               ]),
              //             ),
              //           ),
              //         )
              //       ],
              //     ),
              //   ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: FloatingActionButton(
                    onPressed: () => playSongs(),
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

  getSongs() {
    incrementFirebaseByOne();
    FirebaseFirestore.instance
        .collection('songs')
        .get()
        .then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        Map<String, dynamic> data = doc.data();
        songs.add(new Song(
            artist: data['artist'],
            title: data['title'],
            imageResourceFile: data['imageResourceFile'],
            genre: data['genre'],
            songResourceFile: data['songResourceFile'],
            textResourceFile: data['textResourceFile'],
            womanToneResourceFile: data['womanToneResourceFile'],
            kidToneResourceFile: data['kidToneResourceFile'],
            length: data['length']));
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
    return GridView.builder(
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            childAspectRatio: 0.6,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20),
        itemCount: songs.length,
        itemBuilder: (BuildContext ctx, index) {
          return Container(
              alignment: Alignment.center, child: buildSongLayout(songs[index])
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
          context, MaterialPageRoute(builder: (_) => Sing(songsPassed, "22")));
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

        // Navigator.pushNamed(context, '/sing', arguments: {'song':this.song});
        // Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //         builder: (_) => Sing(
        //             this.song, index.toString() + " " + counter.toString())));
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
              flex: 2,
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
          ],
        ),
      ),
    );
  }

  songInSongsClicked(Song song) {
    if (songsClicked.length > 0)
      for (int i = 0; i < songsClicked.length; i++) {
        if (song.songResourceFile == songsClicked[i].songResourceFile)
          return true;
      }
    return false;
  }
}
