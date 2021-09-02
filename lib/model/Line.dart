import 'Letter.dart';
import 'Syllable.dart';

class Line {
  late double from;
  late double to;
  String past = "";
  String splitWordPast = "";
  String splitWordFuture = "";
  List<Syllable> syllables = [];
  late String future;
  late Letter lastLetterInPosition;
  late Syllable lastWordInPosition;

  void addSyllables(bool personalMoishie) {
    future = getFutureFromSyllable(personalMoishie);
    lastLetterInPosition = syllables.first.letters.first;
    lastWordInPosition = syllables.first;
  }

  void setStart() {
    splitWordFuture = lastWordInPosition.text;
    removeCurrentWordFromFuture();
  }

  bool isIn(double position) {
    return from <= position && position <= to;
  }

  bool isAfter(double position) {
    return from > position;
  }

  bool needToUpdateLyrics(double position) {
    return !(lastLetterInPosition.isIn(position) ||
        lastLetterInPosition.isFuture(position));
  }

  void updateLyrics(double position, bool personalMoishie) {
    past = "";
    future = "";
    for (Syllable syllable in syllables)
      if (syllable.isIn(position)) {
        if (personalMoishie && syllable.text.contains(String.fromCharCode(0x2022))) {
          assignNumber(syllable);
          return;
        }
        for (Letter letter in syllable.letters)
          if (letter.isPast(position) || letter.isIn(position)) {
            lastLetterInPosition = letter;
            past += letter.letter;
          } else
            future += letter.letter;
      }
    //else if (syllable.text.contains(String.fromCharCode(0x2022))) {
      //  return;
      //}
      else if (syllable.isPast(position))
        past += syllable.text;
      else
        future += syllable.text;
  }

  void resetSplitWord() {
    splitWordPast = "";
    splitWordFuture = "";
  }

  String getFutureFromSyllable(bool personalMoishie) {
    String text = "";
    if (personalMoishie && syllables[0].text.contains(String.fromCharCode(0x2022))) {
      return String.fromCharCode(0x2022) * 6;
    }
    for (Syllable s in syllables) {
      text += s.text;
      // text += " ";
    }
    return text;
  }

  void removeCurrentWordFromFuture() {
    future = future.substring(lastWordInPosition.letters.length);
  }

  void resetLine(double time, bool personalMoishie) {
    future = getFutureFromSyllable(personalMoishie);
    past = "";
    updateLyrics(time, personalMoishie);
  }

  void assignNumber(Syllable syllable) {
    future = "";
    if (syllable.text == String.fromCharCode(0x2022) + " ") {
      past = 1.toString();
    } else if (syllable.text == String.fromCharCode(0x2022) * 2 + " ") {
      past = 2.toString();
    } else if (syllable.text == String.fromCharCode(0x2022) * 3 + " ") {
      past = 3.toString();
    }
  }
}
