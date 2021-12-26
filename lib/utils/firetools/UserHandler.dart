import 'package:cloud_firestore/cloud_firestore.dart';

import '../GenerateRandomString.dart';

class UserHandler {
  Future<dynamic> sendUserInfoToFirestore(String email, String? fullName,
      [String? photoURL = ""]) async {
    CollectionReference users = FirebaseFirestore.instance.collection('users');
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

    // users
    //     .add(firestoreDoc)
    //     .then((value) => print("user added"))
    //     .catchError((error) => print("Failed to add user: $error"));
  }
}
