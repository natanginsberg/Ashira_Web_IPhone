import 'package:cloud_firestore/cloud_firestore.dart';

class IpHandler {
  void checkIfDeviceRegistered(
      String email,
      DocumentSnapshot<Map<String, dynamic>> doc,
      bool saveIp,
      String ipAddress) {
    if (saveIp)
      try {
        List<Map<String, dynamic>> ips
            // List<String> ips
            = List.from(doc.get("ips"));
        int valueToChange = -1;
        for (int i = 0; i < ips.length; i++) {
          var map = ips[i];
          if (map['ip'] == ipAddress) {
            valueToChange = i;
          }
        }
        Map<String, dynamic> newIpAddress = new Map<String, dynamic>();
        newIpAddress['ip'] = ipAddress;
        newIpAddress['entrance'] = DateTime.now();
        if (valueToChange == -1) {
          ips.add(newIpAddress);
        } else {
          ips[valueToChange] = newIpAddress;
        }
        addIpAddressToDocument(doc, ips, email);
      } catch (error) {
        Map<String, dynamic> newIpAddress = new Map<String, dynamic>();
        newIpAddress['ip'] = ipAddress;
        newIpAddress['entrance'] = DateTime.now();
        addIpAddressToDocument(doc, [newIpAddress], email);
      }
  }

  void addIpAddressToDocument(DocumentSnapshot<Map<String, dynamic>> doc,
      List<Map<String, dynamic>> ips, String email) {
    Map<String, dynamic> firestoreDoc = new Map<String, dynamic>();
    // firestoreDoc['endTime'] = doc.get("endTime");
    // firestoreDoc['email'] = email;
    firestoreDoc['ips'] = ips;

    CollectionReference users =
        FirebaseFirestore.instance.collection('internetUsers');

    Future<void> addUser() {
      return users.doc(email).update(firestoreDoc).catchError((error) => {});
    }

    addUser();
  }

  Future<DocumentSnapshot> checkCurrentIpAddress(String ipAddress) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('internetUsers')
        .where("endTime", isGreaterThan: DateTime.now())
        .get();
    for (DocumentSnapshot doc in querySnapshot.docs)
    // querySnapshot.docs.forEach((doc)
    {
      if (doc.exists) {
        Map document = doc.data() as Map;
        if (document.containsKey("ips")) {
          List<Map<String, dynamic>> ips = List.from(document["ips"]);
          for (int i = 0; i < ips.length; i++) {
            var map = ips[i];
            if (map['ip'] == ipAddress) {
              Duration signInTime = new Duration(hours: 3);
              DateTime entrance = map['entrance'].toDate();
              DateTime currentTime = DateTime.now().toUtc();
              var endTime = doc.get("endTime");
              DateTime myDateTime = endTime.toDate();
              DateTime earliestTime =
                  getEarliestTime(entrance.add(signInTime), myDateTime);
              if (currentTime.compareTo(earliestTime) < 0) return doc;
            }
          }
        }
      }
    }
    throw "no ip exists";
  }

  DateTime getEarliestTime(DateTime signInTime, DateTime endTime) {
    if (signInTime.compareTo(endTime) < 0) return signInTime;
    return endTime;
  }
}
