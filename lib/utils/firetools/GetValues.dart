import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class GetValues {
  List<String> hebrewGenres = [];
  List<String> englishGenres = [];
  List<String> couponCodes = [];

  Future<List<String>> getDemoSongs() async {
    try {
      var demoCollection =
          FirebaseFirestore.instance.collection('randomFields');

      if (kIsWeb) {
        var demoName = await demoCollection.doc("allDemoSongs").get();
        return List.from(demoName.get("songs"));
      } else {
        var demoName = await demoCollection.doc("phoneDemoSongs").get();
        return List.from(demoName.get("songs"));
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> getGenres() async {
    try {
      var genresCollection = FirebaseFirestore.instance.collection('genres');

      var genreLists = await genresCollection.doc("genre").get();

      hebrewGenres = List.from(genreLists.get("hebrew"));
      englishGenres = List.from(genreLists.get("english"));
      return true;
    } catch (e) {
      hebrewGenres = [""];
      englishGenres = [""];
      return false;
    }
  }

  Future<List<String>> getCouponCode() async {
    if (couponCodes.length > 0) return couponCodes;
    var collection = FirebaseFirestore.instance.collection('randomFields');

    var doc = await collection.doc("coupon").get();

    couponCodes = List.from(doc.get("code"));
    return couponCodes;
  }

  get getHebrewGenres {
    return hebrewGenres;
  }

  get getEnglishGenres {
    return englishGenres;
  }
}
