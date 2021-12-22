import 'package:cloud_firestore/cloud_firestore.dart';

import '../GenerateRandomString.dart';

class UserHandler {
  Future<void> sendUserInfoToFirestore(
      String email, String fullName, String token) async {
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    Map<String, dynamic> firestoreDoc = new Map<String, dynamic>();
    firestoreDoc['id'] = GenerateRandomString().generateRandomString();
    firestoreDoc['userEmail'] = email;
    firestoreDoc['userName'] = fullName;
    firestoreDoc['expirationDate'] = "";

    return users.doc(email).set(firestoreDoc);
  }
}
