import 'package:cloud_firestore/cloud_firestore.dart';

class UserHandler {
  CollectionReference users = FirebaseFirestore.instance.collection('users');

  String email = "";
  Timestamp endTime = Timestamp(10, 10);

  void setEmail(String email) {
    this.email = email;
  }

  void setEndTime(Timestamp endTime) {
    this.endTime = endTime;
  }

  Future<bool> addTimeToUser() async {
    return true;
  }
}
