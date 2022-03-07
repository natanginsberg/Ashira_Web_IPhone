import 'package:ashira_flutter/model/Song.dart';
import 'package:ashira_flutter/utils/firetools/UserHandler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WebUserHandler extends UserHandler{
  CollectionReference users =
  FirebaseFirestore.instance.collection('internetUsers');

  Future<bool> addTimeToUser([int quantity = 0]) async {
    Map<String, dynamic> firestoreDoc = new Map<String, dynamic>();
    bool timeAdded = false;
    firestoreDoc["endTime"] = endTime;
    // firestoreDoc['email'] = email;
    // firestoreDoc['hours'] = quantity;
    // firestoreDoc['password'] = password;

    CollectionReference users =
    FirebaseFirestore.instance.collection('internetUsers');

    Future<void> addUser() {
      return users
          .doc(email).update(firestoreDoc)
          // .(firestoreDoc)
          .then((value) => timeAdded = true)
          .catchError((error) {});
    }

    await addUser();
    return timeAdded;
  }

  void addSongsPlayedAndLength(
      String email, List<Song> songs, Duration songLength) async {
    Map<String, dynamic> firestoreDoc = new Map<String, dynamic>();
    try {
      var collection = FirebaseFirestore.instance.collection('internetUsers');

      var doc = await collection.doc(email).get();

      if (doc.exists) {
        Map document = doc.data() as Map;
        if (document.containsKey("songsPlayed")) {
          List<String> songsPlayed = List.from(document["songsPlayed"]);
          for (Song song in songs)
            if (!songsPlayed.contains(song.title)) songsPlayed.add(song.title);
          firestoreDoc["songsPlayed"] = songsPlayed;
        } else {
          List<String> songsPlayed = [];
          for (Song song in songs) songsPlayed.add(song.title);
          firestoreDoc["songsPlayed"] = songsPlayed;
        }
        if (document.containsKey("timePlayed")) {
          double milliseconds = document["timePlayed"];
          firestoreDoc["timePlayed"] = milliseconds + songLength.inMilliseconds;
        } else {
          firestoreDoc["timePlayed"] = songLength.inMilliseconds;
        }
        if (document.containsKey("allSongsPlayed")) {
          List<String> allSongsPlayed = List.from(document["allSongsPlayed"]);
          for (Song song in songs) allSongsPlayed.add(song.title);
          firestoreDoc["allSongsPlayed"] = allSongsPlayed;
        } else {
          List<String> allSongsPlayed = [];
          for (Song song in songs) allSongsPlayed.add(song.title);
          firestoreDoc["allSongsPlayed"] = allSongsPlayed;
        }
      }
      collection.doc(email).update(firestoreDoc);
    } catch (e) {}
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> checkUser() async {
    try {
      var collection = FirebaseFirestore.instance.collection('internetUsers');

      var doc = await collection.doc(email).get();
      return doc;
    } catch (e) {
      throw e;
    }
  }
}