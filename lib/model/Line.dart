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

  void addSyllables() {
    future = getFutureFromSyllable();
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

  bool needToUpdateLyrics(double position) {
    return !(lastLetterInPosition.isIn(position) ||
        lastLetterInPosition.isFuture(position));
  }

  void updateLyrics(double position) {
    past = "";
    future = "";
    for (Syllable syllable in syllables)
      if (syllable.isIn(position)) {
        for (Letter letter in syllable.letters)
          if (letter.isPast(position) || letter.isIn(position)) {
            lastLetterInPosition = letter;
            past += letter.letter;
          } else
            future += letter.letter;
      } else if (syllable.isPast(position))
        past += syllable.text;
      else
        future += syllable.text;
  }

  void resetSplitWord() {
    splitWordPast = "";
    splitWordFuture = "";
  }

  String getFutureFromSyllable() {
    String text = "";
    for (Syllable s in syllables) {
      text += s.text;
      // text += " ";
    }
    return text;
  }

  void removeCurrentWordFromFuture() {
    future = future.substring(lastWordInPosition.letters.length);
    // future.replaceFirst(lastWordInPosition.text, "");
    // future.trim();
  }

  void resetLine(double time) {
    future = past;
    past = "";
    updateLyrics(time);
  }
}
