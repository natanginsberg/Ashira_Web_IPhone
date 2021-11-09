import 'dart:core';
import 'dart:math';

import 'package:ashira_flutter/model/Letter.dart';
import 'package:ashira_flutter/model/Line.dart';
import 'package:ashira_flutter/model/Syllable.dart';

class Parser {
  List<Line> parse(List<String> data, bool personalMoishie) {
    List<Line> lines = [];
    for (int i = 0; i < data.length - 1; i++) {
      String line = data[i];
      // if (i > 15 && !line.contains('[')) break;
      if (line.startsWith("#MP3")) {
        continue;
      } else if (line.startsWith("#COVER")) {
        continue;
      } else {
//        for (String line : data) {
        if (line.length == 0) {
          continue;
        }

        // tags

        if (line.startsWith("[ti")) {
          continue;
        } else if (line.startsWith("[ar")) {
          continue;
        } else if (line.startsWith("[al")) {
          continue;
        } else if (line.startsWith("[") && line.endsWith("]")) {
        } else {
          if (line.startsWith("[")) {
            int nextLineIndex = i + 1;
            bool isLastLine = false;
            String nextLine = "";
            while (nextLine == ("")) {
              if (nextLineIndex == data.length) {
                isLastLine = true;
                break;
              }
              nextLine = data[nextLineIndex];
              nextLineIndex++;
            }
            List<String> lineWordsAndTimes = line.split("<");

            if ((lineContainsDollar(lineWordsAndTimes) &&
                    lineWordsAndTimes.length > 5) ||
                (!lineContainsDollar(lineWordsAndTimes) &&
                    lineWordsAndTimes.length > 4) ||
                (lineContainsDollar(lineWordsAndTimes) &&
                    lengthOfLineIsGreaterThan(lineWordsAndTimes, 65)) ||
                (!lineContainsDollar(lineWordsAndTimes) &&
                        lengthOfLineIsGreaterThan(lineWordsAndTimes, 55)) &&
                    lineWordsAndTimes.length > 2) {
              List<List<String>> textLines =
                  breakLineIntoManyLines(lineWordsAndTimes);
              for (int k = 0; k < textLines.length; k++) {
                try {
                  List<String> l = textLines[k];
                  Line nextLineInSong = parseLine(
                      l,
                      getLineTimeStamp(k != textLines.length - 1
                          ? getNextLine(k, textLines)
                          : nextLine),
                      isLastLine,
                      personalMoishie);
                  lines.add(nextLineInSong);
                  if (lastWordIsUnproportionatelyLong(
                      getLineTimeStamp(k != textLines.length - 1
                          ? getNextLine(k, textLines)
                          : nextLine),
                      nextLineInSong.to)) {
                    lines.add(addIntroIndication(
                        getLineTimeStamp(k != textLines.length - 1
                            ? getNextLine(k, textLines)
                            : nextLine),
                        false,
                        personalMoishie));
                  }
                } catch (error) {
                }
              }
            } else {
              Line nextLineInSong = parseLine(lineWordsAndTimes,
                  getLineTimeStamp(nextLine), isLastLine, personalMoishie);
              lines.add(nextLineInSong);
              if (lastWordIsUnproportionatelyLong(
                  getLineTimeStamp(nextLine), nextLineInSong.to)) {
                lines.add(addIntroIndication(
                    getLineTimeStamp(nextLine), false, personalMoishie));
              }
            }
            // } else {
            //   if (i < data.length - 1) {
            //     lines.add(
            //         parseHebrewLine(line.split(">"), data[i + 1], false));
            //   } else {
            //     lines.add(
            //         parseHebrewLine(line.split(">"), data[i + 1], true));
            //   }
          }
        }
      }
    }

    // fix starts

    for (Line line in lines) {
      // try {
      if (line.from == 0 && line.syllables.length > 0) {
        line.from = line.syllables[0].from;
      }
    }
    lines.insert(0, addIntroIndication(lines[0].from, true, personalMoishie));
    if (lines[lines.length - 1]
        .syllables[0]
        .text
        .contains(String.fromCharCode(0x2022))) {
      lines.removeLast();
    }
    return lines;
  }

  bool lengthOfLineIsGreaterThan(List<String> lineWordsAndTimes, int i) {
    int counter = 0;
    for (String word in lineWordsAndTimes) counter += word.length;
    return counter > i;
  }

  bool lineContainsDollar(List<String> lineWordsAndTimes) {
    return lineWordsAndTimes[lineWordsAndTimes.length - 1].contains("\$");
  }

  List<List<String>> breakLineIntoManyLines(List<String> lineWordsAndTimes) {
    List<List<String>> allLines = [];
    int lengthOfNewSentence = 3;
    bool lineContainsADollar = lineContainsDollar(lineWordsAndTimes);
    for (int k = 0; k * lengthOfNewSentence < lineWordsAndTimes.length; k++) {
      if (lineContainsDollar(lineWordsAndTimes) &&
          k * lengthOfNewSentence == lineWordsAndTimes.length - 1) break;
      allLines.add(parsePartOfLine(
          lineWordsAndTimes,
          lengthOfNewSentence,
          k * lengthOfNewSentence,
          lineContainsADollar
              ? (k + 1) * lengthOfNewSentence > lineWordsAndTimes.length - 1
              : (k + 1) * lengthOfNewSentence > lineWordsAndTimes.length));
    }
    return allLines;
  }

  List<String> parsePartOfLine(List<String> lineWordsAndTimes,
      int lengthOfNewSentence, int i, bool lastOne) {
    int lengthOfSentence = !lastOne
        ? lengthOfNewSentence + 1
        : lineWordsAndTimes.length - lengthOfNewSentence;
    List<String> nextLine = List<String>.filled(lengthOfSentence, "");
    int counter = 0;
    for (int j = 0; j < lengthOfSentence; j++) {
      if (i + j > lineWordsAndTimes.length - 1) break;
      counter = j;
      if (j == 0) {
        if (lineWordsAndTimes[i].contains("]")) {
          nextLine[0] = lineWordsAndTimes[0];
        } else {
          nextLine[0] = addFrontBracketToSentence(lineWordsAndTimes[i]);
        }
      } else
        nextLine[j] = lineWordsAndTimes[i + j];
    }
    // i = min(i + lengthOfSentence - 1, lineWordsAndTimes.length - 1);
    i = i + counter;
    if (lineContainsDollar(lineWordsAndTimes)) if (lineWordsAndTimes[i]
        .contains("\$"))
      nextLine[lengthOfSentence - 1] = lineWordsAndTimes[i];
    else
      nextLine[lengthOfSentence - 1] = swapWordForDollar(lineWordsAndTimes[i]);
    else {
      if (i == lineWordsAndTimes.length - 1 &&
          !(lengthOfSentence == lineWordsAndTimes.length) &&
          lastOne) if (lengthOfSentence ==
              1 &&
          !lineWordsAndTimes[i].contains("]"))
        nextLine[lengthOfSentence - 1] =
            addFrontBracketToSentence(lineWordsAndTimes[i]);
      else {
        return removeBlanks(nextLine);
        nextLine[lengthOfSentence - 1] = lineWordsAndTimes[i];
      }
      else
        nextLine[lengthOfSentence - 1] =
            swapWordForDollar(lineWordsAndTimes[i]);
    }
    return removeBlanks(nextLine);
  }

  String addFrontBracketToSentence(String lineWordsAndTime) {
    String newString = lineWordsAndTime.replaceAll('>', ']');
    return "[" + newString;
    // stringBuffer.insert(0, "[");
    // return String.valueOf(stringBuffer);
  }

  String swapWordForDollar(String lineWordsAndTime) {
    String tempWord = lineWordsAndTime;
    List<String> wordAndTime = tempWord.split(">");
    return tempWord.replaceAll(wordAndTime[1], "\$");
  }

  bool lastWordIsUnproportionatelyLong(double parseTimeStamp, double to) {
    return parseTimeStamp != to;
  }

  Line addIntroIndication(double from, bool beginning, bool personalMoishie) {
    double nextSyllableStartsAt = from;
    Line indicatorLine = new Line();
    indicatorLine.from = max(0, from - 3);
    indicatorLine.to = from;
    Syllable syllable;
    int introSeconds = 3;
    for (int i = 0; i < introSeconds; i++) {
      syllable = new Syllable();
      syllable.text = getIndexIndicators(i + 1) + " ";
      syllable.to = nextSyllableStartsAt;
      syllable.from = syllable.to - 1;
      nextSyllableStartsAt = syllable.from;
      syllable.letters = addLettersToSyllable(syllable);
      indicatorLine.syllables.insert(0, syllable);
    }
    indicatorLine.addSyllables(personalMoishie);
    return indicatorLine;
  }

  String getIndexIndicators(int i) {
    return String.fromCharCode(0x2022) * i;
  }

  Line parseLine(List<String> line, double nextLineTimeStamp, bool lastLine,
      bool personalMoishie) {
    Line currentLine = new Line();
    Syllable syllable;
    double startTime = 0;
    double endTime = 0;
    for (int i = 0; i < line.length; i++) {
      syllable = new Syllable();
      String word = line[i];
      if (word.startsWith("[")) {
        startTime = getLineTimeStamp(word);
        currentLine.from = startTime;
        for (int j = 0; j < word.length; j++) {
          String n = word[j];
          if (n == ']') {
            syllable.text = word.substring(j + 1).replaceAll(",", "");
            break;
          }
        }
      } else {
        List<String> wordAndTime = word.split(">");
        // if (i > 0) {
        startTime = parseTimeStamp(wordAndTime[0]);
        // }
        if (wordAndTime[1].contains("\$")) {
          endTime = nextLineTimeStamp;
          if (endTime - startTime > 8) {
            endTime = startTime + 1;
          }
          break;
        }
        syllable.text = wordAndTime[1].replaceAll(",", "");
      }
      if (i < line.length - 1) {
        endTime = parseTimeStamp(line[i + 1].split(">")[0]);
      } else {
        if (lastLine) {
          endTime = startTime + 100000;
        } else {
          endTime = nextLineTimeStamp;
        }
        if (endTime - startTime > 8) {
          endTime = startTime + 1;
        }
      }

      if (endTime == startTime) {
        endTime = startTime + 1;
      }
      syllable.from = startTime;
      syllable.to = endTime;

      syllable.letters = addLettersToSyllable(syllable);
      currentLine.syllables.add(syllable);
      startTime = endTime;
    }
    currentLine.to = endTime;
    currentLine.addSyllables(personalMoishie);
    return currentLine;
  }

  List<Letter> addLettersToSyllable(Syllable syllable) {
    double totalTimeAllotted = syllable.to - syllable.from;
    double lengthPerLetter = totalTimeAllotted / syllable.text.length;
    double currentPosition = syllable.from;
    List<Letter> letters = [];
    for (String letter in syllable.text.split("")) {
      Letter l = new Letter();
      l.from = currentPosition;
      l.to = currentPosition + lengthPerLetter;
      currentPosition = l.to;
      l.letter = letter;
      letters.add(l);
    }
    return letters;
  }

  double getLineTimeStamp(String line) {
    if (line.contains("[")) {
      return parseTimeStamp(
          line.substring(line.indexOf("[") + 1, line.indexOf("]")));
    } else
      return parseTimeStamp(
          line.substring(line.indexOf("<") + 1, line.indexOf("]")));
  }

  double parseTimeStamp(String timeStamp) {
    List<String> minutesSecondsHundredthSeconds = timeStamp.split(":");
    int seconds = int.parse(timeStamp.substring(0, 2)) * 60 +
        int.parse(timeStamp.substring(3, 5));
    int hundredthOfSeconds = int.parse(timeStamp.substring(6, 8));
    return seconds + hundredthOfSeconds / 100;
  }

  String getStringValueOfLine(String line) {
    return line.substring(1, line.length - 1).split(":")[1];
  }

  String getStringValue(String line, String tag) {
    return line.substring(tag.length + 1);
  }

  List<String> removeBlanks(List<String> nextLine) {
    return [
      for (var e in nextLine)
        if (e != "") e
    ];
  }

  getNextLine(int k, List<List<String>> textLines) {
    if (textLines[k + 1].length > 1) {
      return textLines[k + 1][0];
    } else {
      String line =
          textLines[k + 1][0].replaceFirst("<", "[").replaceFirst(">", "]");
      if (line[0] != "[") line = "[" + line;
      return line;
    }
  }
}
