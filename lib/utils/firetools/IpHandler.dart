import 'package:cloud_firestore/cloud_firestore.dart';

class IpHandler {
  void checkIfDeviceRegistered(DocumentSnapshot<Map<String, dynamic>> doc,
      bool saveIp, String ipAddress) {
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
        addIpAddressToDocument(doc, ips);
      } catch (error) {
        Map<String, dynamic> newIpAddress = new Map<String, dynamic>();
        newIpAddress['ip'] = ipAddress;
        newIpAddress['entrance'] = DateTime.now();
        addIpAddressToDocument(doc, [newIpAddress]);
      }
  }

  void addIpAddressToDocument(DocumentSnapshot<Map<String, dynamic>> doc,
      List<Map<String, dynamic>> ips) {
    Map<String, dynamic> firestoreDoc = new Map<String, dynamic>();
    firestoreDoc['endTime'] = doc.get("endTime");
    firestoreDoc['email'] = doc.get("email");
    firestoreDoc['ips'] = ips;

    CollectionReference users =
        FirebaseFirestore.instance.collection('internetUsers');

    Future<void> addUser() {
      return users
          .doc(doc.get("email"))
          .set(firestoreDoc)
          .catchError((error) => {});
    }

    addUser();
  }
}
