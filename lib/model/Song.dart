import 'package:ashira_flutter/utils/Parser.dart';
import 'package:http/http.dart' as http;

import 'Line.dart';

class Song {
  String artist;
  String imageResourceFile;
  String songResourceFile;

  String textResourceFile;

  String womanToneResourceFile;
  String kidToneResourceFile;

  // int timesDownloaded;
  // int timesPlayed;
  String title;

  // List<String> lines;
  String genre;
  late List<Line> lines;

  // String songReference;
  // String date = "";

  // Song({
  //   this.artist,
  //   this.imageResourceFile,
  //   this.songResourceFile,
  //   this.textResourceFile,
  //   this.timesDownloaded,
  //   this.timesPlayed,
  //   this.title,
  //   this.genre,
  //   this.songReference,
  //   this.womanToneResourceFile,
  //   this.kidToneResourceFile,
  // });

  Song(
      {required this.artist,
      required this.imageResourceFile,
      required this.title,
      required this.genre,
      required this.songResourceFile,
      required this.textResourceFile,
      required this.kidToneResourceFile,
      required this.womanToneResourceFile});

  Future<List<Line>> parseLines() async {
    final response = await http.read(Uri.parse(textResourceFile));
    lines = (new Parser()).parse(response.split("\r\n"));
    return lines;
  }
}
