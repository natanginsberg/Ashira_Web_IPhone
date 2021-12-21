import 'dart:io';
import 'dart:math';

class GenerateRandomString {
  int STRING_LENGTH = 15;
  String alphaNumericString =
      "ABCDEFGHIJKLMNOPQRSTUVWXYZ" + "0123456789" + "abcdefghijklmnopqrstuvxyz";

  String generateRandomString() {
    Random random = new Random();

    String randomString = Platform.isIOS ? "app" : "";

    while (randomString.length < STRING_LENGTH) {
      int index = random.nextInt(alphaNumericString.length);
      randomString += alphaNumericString[index];
    }
    return randomString;
  }
}
