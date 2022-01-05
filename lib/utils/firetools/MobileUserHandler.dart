import 'package:ashira_flutter/utils/firetools/UserHandler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../GenerateRandomString.dart';

class MobileUserHandler extends UserHandler {
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  Future<bool> addTimeToUser() async {
    print("we tried");
    var dt = DateTime.fromMillisecondsSinceEpoch(endTime.millisecondsSinceEpoch);

    var d24 = DateFormat('yyyyMMdd_HHmmss').format(dt); // 12/31/2000, 10:00 PM

    var userFound = false;

    var timeAdded = false;
    DocumentSnapshot? documentSnapshot;
    await users
        .where("userEmail", isEqualTo: email)
        .get()
        .then(
            (QuerySnapshot querySnapshot) => querySnapshot.docs.forEach((doc) {
          userFound = true;
          documentSnapshot = doc;
        }))
        .catchError((error) => {});
    if (userFound) {
      await users
          .doc(documentSnapshot!.id)
          .update({"expirationDate": d24})
          .then((value) => timeAdded = true)
          .catchError((error) => timeAdded = false);
      return timeAdded;
    } else {
      Map<String, dynamic> firestoreDoc = new Map<String, dynamic>();
      firestoreDoc['id'] = GenerateRandomString().generateRandomString();
      firestoreDoc['userEmail'] = email;
      firestoreDoc['userName'] = "";
      firestoreDoc['expirationDate'] = d24;
      firestoreDoc["picUrl"] = "";

      Future<void> addUser() {
        // Call the user's CollectionReference to add a new user
        return users
            .add(firestoreDoc)
            .then((value) => timeAdded = true)
            .catchError((error) => timeAdded = false);
      }

      await addUser();
      return timeAdded;
    }
  }

  Future<dynamic> sendUserInfoToFirestore(String email, String? fullName,
      [String? photoURL = ""]) async {
    if (fullName == null) fullName = "";
    if (photoURL == null) fullName = "";

    Map<String, dynamic> firestoreDoc = new Map<String, dynamic>();
    firestoreDoc['id'] = GenerateRandomString().generateRandomString();
    firestoreDoc['userEmail'] = email;
    firestoreDoc['userName'] = fullName;
    firestoreDoc['expirationDate'] = "";
    firestoreDoc["picUrl"] = photoURL;

    // users.where("userEmail", isEqualTo: email).get().then(
    //     (QuerySnapshot querySnapshot) => querySnapshot.docs.forEach((doc) {
    //           return;
    //         }));
    bool userAdded = false;

    Future<void> addUser() {
      // Call the user's CollectionReference to add a new user
      return users
          .add(firestoreDoc)
          .then((value) => userAdded = true)
          .catchError((error) => userAdded = false);
    }

    bool userFound = false;
    await users
        .where("userEmail", isEqualTo: email)
        .get()
        .then(
            (QuerySnapshot querySnapshot) => querySnapshot.docs.forEach((doc) {
          userFound = true;
        }))
        .catchError((error) => {});
    if (userFound) return true;
    await addUser();
    return userAdded;
  }

  Future<Timestamp> getUserEndTime() async {
    DocumentSnapshot? documentSnapshot;
    var userFound = false;
    await users
        .where("userEmail", isEqualTo: email)
        .get()
        .then(
            (QuerySnapshot querySnapshot) => querySnapshot.docs.forEach((doc) {
          userFound = true;
          documentSnapshot = doc;
        }))
        .catchError((error) => {});
    if (userFound) {
      String expirationDate = documentSnapshot!.get('expirationDate');
      if (expirationDate.length > 13) {
        String year = expirationDate.substring(0, 4);
        String month = expirationDate.substring(4, 6);
        String day = expirationDate.substring(6, 8);
        String hour = expirationDate.substring(9, 11);
        String minute = expirationDate.substring(11, 13);
        return Timestamp.fromDate(DateTime(int.parse(year), int.parse(month),
            int.parse(day), int.parse(hour), int.parse(minute)));
      } else
        return Timestamp(10, 10);
    } else {
      return Timestamp(10, 10);
    }
  }
}
