import 'dart:async';

import 'package:ashira_flutter/screens/AllSongs.dart';
import 'package:ashira_flutter/utils/firetools/GetValues.dart';
import 'package:ashira_flutter/utils/firetools/WebUserHandler.dart';
import 'package:ashira_flutter/utils/webPurchases/CheckForPurchase.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_ipify/dart_ipify.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'firetools/IpHandler.dart';

class WebFlow {
  final BuildContext buildContext;
  final GetValues getValues;
  final WebUserHandler userHandler;

  final VoidCallback close;
  final VoidCallback signInSuccessful;

  late StateSetter setState;

  bool _isObscure = true;
  bool amIWatsAppHovering = false;
  bool _loading = false;
  String _errorMessage = "";

  Timer? startTimer;

  TextEditingController _userNameEditingController = TextEditingController();
  TextEditingController _passwordEditingController = TextEditingController();

  bool mounted = false;

  int quantity = 0;

  bool amIHovering = false;

  WebFlow(
      {required this.buildContext,
      required this.getValues,
      required this.userHandler,
      required this.signInSuccessful,
      required this.close});

  buildWebSignInPopup(bool isSmartphone) {
    mounted = true;
    return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
      this.setState = setState;
      return Directionality(
        textDirection: Directionality.of(buildContext),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                child: Center(
              child: Stack(children: [
                Center(
                  child: Container(
                    height: MediaQuery.of(buildContext).size.height - 40,
                    width: isSmartphone
                        ? MediaQuery.of(buildContext).size.width
                        : MediaQuery.of(buildContext).size.width / 3,
                    decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Colors.purple),
                        borderRadius:
                            BorderRadius.all(new Radius.circular(20.0))),
                    child: Stack(children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            height:
                                MediaQuery.of(buildContext).size.height / 3.5,
                            width:
                                MediaQuery.of(buildContext).size.height / 3.5,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/ashira.png'),
                                fit: BoxFit.fill,
                              ),
                              shape: BoxShape.rectangle,
                            ),
                          ),
                          // Directionality(
                          //   textDirection: Directionality.of(buildContext),
                          //   child: Row(
                          //     mainAxisAlignment: MainAxisAlignment.center,
                          //     children: [
                          //       Row(
                          //         children: [
                          //           // Text(
                          //           //     AppLocalizations.of(buildContext)!
                          //           //         .notACustomer,
                          //           //     style: TextStyle(
                          //           //         fontSize: 16, color: Colors.white)),
                          //           // SizedBox(
                          //           //   width: 15,
                          //           // ),
                          //           IconButton(
                          //             icon: Icon(
                          //               Icons.remove,
                          //               color: Colors.white,
                          //             ),
                          //             onPressed: () {
                          //               if (quantity > 0)
                          //                 setState(() {
                          //                   quantity -= 1;
                          //                 });
                          //             },
                          //           ),
                          //           Text(
                          //               quantity.toString() +
                          //                   " " +
                          //                   AppLocalizations.of(buildContext)!
                          //                       .hours,
                          //               style: TextStyle(color: Colors.white)),
                          //           IconButton(
                          //             icon: Icon(
                          //               Icons.add,
                          //               color: Colors.white,
                          //             ),
                          //             onPressed: () {
                          //               setState(() {
                          //                 quantity += 1;
                          //               });
                          //             },
                          //           ),
                          //         ],
                          //       ),
                          //       SizedBox(
                          //         width: 20,
                          //       ),
                          //       Center(
                          //         child: MouseRegion(
                          //           cursor: SystemMouseCursors.click,
                          //           onEnter: (PointerEvent details) =>
                          //               setState(() => amIHovering = true),
                          //           onExit: (PointerEvent details) =>
                          //               setState(() {
                          //             amIHovering = false;
                          //           }),
                          //           child: RichText(
                          //               text: TextSpan(
                          //                   text: AppLocalizations.of(
                          //                           buildContext)!
                          //                       .placeOrder,
                          //                   style: TextStyle(
                          //                     fontSize: 18,
                          //                     color: amIHovering
                          //                         ? Colors.blue[300]
                          //                         : Colors.blue,
                          //                     decoration:
                          //                         TextDecoration.underline,
                          //                   ),
                          //                   recognizer: TapGestureRecognizer()
                          //                     ..onTap = () {
                          //                       launch(
                          //                           "https://ashira- music.com/checkout/?add-to-cart=1102&quantity=$quantity");
                          //                     })),
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          Center(
                            child: Container(
                                width: isSmartphone
                                    ? MediaQuery.of(buildContext).size.width / 2
                                    : MediaQuery.of(buildContext).size.width /
                                        4,
                                height: 50,
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.purple),
                                    borderRadius: BorderRadius.all(
                                        new Radius.circular(20.0))),
                                child: Center(
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: TextField(
                                      onSubmitted: (value) {
                                        if (!_loading)
                                          checkEmailAndContinue(setState);
                                      },
                                      textAlign: TextAlign.center,
                                      decoration: new InputDecoration(
                                        hintText:
                                            AppLocalizations.of(buildContext)!
                                                .email,
                                        hintStyle:
                                            TextStyle(color: Color(0xFF787676)),
                                        fillColor: Colors.transparent,
                                      ),
                                      style: TextStyle(
                                          fontSize: 15, color: Colors.white),
                                      autofocus: true,
                                      controller: _userNameEditingController,
                                    ),
                                  ),
                                )),
                          ),
                          Center(
                            child: Container(
                                width: isSmartphone
                                    ? MediaQuery.of(buildContext).size.width / 2
                                    : MediaQuery.of(buildContext).size.width /
                                        4,
                                height: 50,
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.purple),
                                    borderRadius: BorderRadius.all(
                                        new Radius.circular(20.0))),
                                child: Center(
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: TextField(
                                      obscureText: _isObscure,
                                      onSubmitted: (value) {
                                        if (!_loading)
                                          checkEmailAndContinue(setState);
                                      },
                                      textAlign: TextAlign.center,
                                      decoration: new InputDecoration(
                                        prefixIcon: Icon(
                                          _isObscure
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: Colors.transparent,
                                        ),
                                        hintText:
                                            AppLocalizations.of(buildContext)!
                                                .coupon,
                                        hintStyle:
                                            TextStyle(color: Color(0xFF787676)),
                                        fillColor: Colors.transparent,
                                        suffixIcon: IconButton(
                                            icon: Icon(
                                              _isObscure
                                                  ? Icons.visibility
                                                  : Icons.visibility_off,
                                            ),
                                            onPressed: () => setState(() {
                                                  _isObscure = !_isObscure;
                                                })),
                                      ),
                                      style: TextStyle(
                                          fontSize: 15, color: Colors.white),
                                      autofocus: true,
                                      controller: _passwordEditingController,
                                    ),
                                  ),
                                )),
                          ),
                          !_loading
                              ? Container(
                                  decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.all(
                                          new Radius.circular(10))),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        8.0, 4, 8.0, 4),
                                    child: TextButton(
                                        onPressed: () =>
                                            checkEmailAndContinue(setState),
                                        child: Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: Text(
                                            AppLocalizations.of(buildContext)!
                                                .enter,
                                            style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.white),
                                          ),
                                        )),
                                  ),
                                )
                              : new Align(
                                  child: new Container(
                                    color: Colors.transparent,
                                    width: 70.0,
                                    height: 70.0,
                                    child: new Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: new Center(
                                            child:
                                                new CircularProgressIndicator())),
                                  ),
                                  alignment: FractionalOffset.center,
                                ),
                          if (_errorMessage != "")
                            Center(
                                child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 20,
                                ),
                              ),
                            )),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Center(
                              //     child: Directionality(
                              //   textDirection: TextDirection.rtl,
                              //   child: Text(
                              //     AppLocalizations.of(buildContext)!.personalUse,
                              //     // data,
                              //     style: TextStyle(
                              //       //   fontFamily: 'SignInFont',
                              //       color: Colors.white,
                              //       //wordSpacing: 5,
                              //       fontSize: 20,
                              //       //height: 1.4,
                              //       //letterSpacing: 1.6
                              //     ),
                              //   ),
                              // )),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                    child: Text(
                                  AppLocalizations.of(buildContext)!.publicUse,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    //fontFamily: 'SignInFont',
                                    color: Colors.white,
                                    // wordSpacing: 5,
                                    fontSize: 20,
                                    height: 1.5,

                                    //height: 1.4,
                                    // letterSpacing: 1.6
                                  ),
                                )),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                    child: Text(
                                  AppLocalizations.of(buildContext)!
                                      .questionsAndInquiries,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    //fontFamily: 'SignInFont',
                                    color: Colors.white,
                                    // wordSpacing: 5,
                                    fontSize: 20,
                                    height: 1.5,

                                    //height: 1.4,
                                    // letterSpacing: 1.6
                                  ),
                                )),
                              ),
                              // Padding(
                              //   padding: const EdgeInsets.all(5.0),
                              //   child: Center(
                              //     child: MouseRegion(
                              //       cursor: SystemMouseCursors.click,
                              //       onEnter: (PointerEvent details) => setState(
                              //           () => amIWatsAppHovering = true),
                              //       onExit: (PointerEvent details) =>
                              //           setState(() {
                              //         amIWatsAppHovering = false;
                              //       }),
                              //       child: RichText(
                              //           text: TextSpan(
                              //               text: AppLocalizations.of(
                              //                       buildContext)!
                              //                   .watsappNumber,
                              //               style: TextStyle(
                              //                 fontSize: 18,
                              //                 color: amIWatsAppHovering
                              //                     ? Colors.green[300]
                              //                     : Colors.blue,
                              //                 decoration:
                              //                     TextDecoration.underline,
                              //               ),
                              //               recognizer: TapGestureRecognizer()
                              //                 ..onTap = () {
                              //                   launch(
                              //                       "https://wa.me/message/6CROFFTK7A5BE1");
                              //                 })),
                              //     ),
                              //   ),
                              // ),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Center(
                                    child: Text(
                                  AppLocalizations.of(buildContext)!.emailUsAt,
                                  style: TextStyle(
                                    //fontFamily: 'SignInFont',
                                    color: Colors.white,
                                    //wordSpacing: 5,
                                    fontSize: 20,
                                    // height: 1.4,
                                    //letterSpacing: 1.6
                                  ),
                                )),
                              ),
                            ],
                          )
                        ],
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: Icon(Icons.close),
                          color: Colors.white,
                          onPressed: () {
                            if (mounted)
                              setState(() {
                                _errorMessage = "";
                                _loading = false;
                              });
                            mounted = false;
                            close();
                          },
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            )),
          ],
        ),
      );
    });
  }

  Future<void> checkEmailAndContinue(StateSetter setState) async {
    if (startTimer != null && startTimer!.isActive) {
      startTimer!.cancel();
      startTimer = null;
    }
    if (mounted)
      setState(() {
        _loading = true;
      });
    String password = _passwordEditingController.text.toLowerCase();
    email = _userNameEditingController.text.toLowerCase();
    if (email == "") {
      if (mounted)
        setState(() {
          _errorMessage = AppLocalizations.of(buildContext)!.emailEmptyError;
          _loading = false;
        });
      return;
    }
    if (password == "") {
      if (mounted)
        setState(() {
          _errorMessage = AppLocalizations.of(buildContext)!.passwordEmptyError;
          _loading = false;
        });
      return;
    }
    userHandler.setEmail(email);
    userHandler.setPassword(password);
    bool saveIp = !(password != "" && password == "בלי");
    print(password);
    print(email);
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
          await userHandler.checkUser();
      if (doc.exists) {
        if ((doc.data()!.containsKey("password"))) {
          print(doc.get("password"));
          if (password != doc.get("password")) {
            if (mounted)
              setState(() {
                _errorMessage = AppLocalizations.of(buildContext)!
                    .passwordAndUserNameDoNotMatch;
                _loading = false;
              });
            return;
          }
        } else {
          if (mounted)
            setState(() {
              _errorMessage = AppLocalizations.of(buildContext)!
                  .passwordAndUserNameDoNotMatch;
              _loading = false;
            });
          return;
        }
        if ((doc.data()!.containsKey("endTime"))) // time was already allocated
        {
          if (!timeIsStillAllocated(doc)) {
            if (mounted)
              setState(() {
                AppLocalizations.of(buildContext)!.outOfTimeError;
                _loading = false;
              });
          } else {
            validateDocument(doc, saveIp);
          }
        } else {
          if (doc.data()!.containsKey("hours")) {
            await addTimeToFirebase(int.parse(doc.get("hours").toString()));
          }
        }
      } else {
        if (mounted)
          setState(() {
            _errorMessage =
                AppLocalizations.of(buildContext)!.noOrderNumberError;
            _loading = false;
          });
      }
    } catch (error) {
      printConnectionError(setState);
    }
  }

  bool timeIsStillAllocated(DocumentSnapshot<Map<String, dynamic>> doc) {
    DateTime currentTime = DateTime.now().toUtc();
    Timestamp currentEndTime = doc.get("endTime");
    DateTime myDateTime = currentEndTime.toDate();
    return currentTime.compareTo(myDateTime) < 0;
  }

  printConnectionError(StateSetter setState) {
    if (mounted)
      setState(() {
        _errorMessage = AppLocalizations.of(buildContext)!.communicationError;
        _loading = false;
      });
  }

  validateDocument(DocumentSnapshot<Map<String, dynamic>> doc,
      [bool saveIp = false]) {
    if (doc.id == email) if (!timeStarted(doc)) {
      printTimeDidNotStart(doc);
    } else {
      endTime = doc.get("endTime");
      checkIfDeviceRegistered(doc, saveIp);
      if (mounted)
        setState(() {
          _loading = false;
        });
      mounted = false;
      if (startTimer != null && startTimer!.isActive) {
        startTimer!.cancel();
        startTimer = null;
      }
      signInSuccessful();
      return;
    }
  }

  bool timeStarted(DocumentSnapshot<Map<String, dynamic>> doc) {
    Map document = doc.data() as Map;
    if (document.containsKey("startTime")) {
      DateTime currentTime = DateTime.now().toUtc();
      Timestamp startTime = document["startTime"];
      DateTime myStartTime = startTime.toDate();
      return currentTime.compareTo(myStartTime) > 0;
    } else
      return true;
  }

  void checkIfDeviceRegistered(
      DocumentSnapshot<Map<String, dynamic>> doc, bool saveIp) async {
    String ipAddress = "";
    ipAddress = await Ipify.ipv64(format: Format.TEXT).catchError((error) {});
    IpHandler().checkIfDeviceRegistered(email, doc, saveIp, ipAddress);
  }

  printTimeDidNotStart(DocumentSnapshot<Map<String, dynamic>> doc) {
    Duration timeLeft =
        doc.get("startTime").toDate().difference(DateTime.now().toUtc());
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(timeLeft.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(timeLeft.inSeconds.remainder(60));
    String twoDigitHours = "${twoDigits(timeLeft.inHours)}:";
    String timeUntilStart = twoDigitHours + "$twoDigitMinutes:$twoDigitSeconds";
    if (mounted) {
      setState(() {
        _errorMessage =
            AppLocalizations.of(buildContext)!.timeNotStarted + timeUntilStart;
        _loading = false;
      });
    }
    startTimer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      if (timeLeft.inMilliseconds < 1400) {
        if (startTimer != null && startTimer!.isActive) startTimer!.cancel();
        validateDocument(doc);
      } else
        validateDocument(doc);
    });
  }

  void getPurchaseFromStore(bool newUser, bool timesUp) async {
    try {
      try {
        var res = await CheckForPurchase().getWooCommerceId(email);
        await addTimeToFirebase((res)["quantity"]!);
        CheckForPurchase().assignOrderAsCompleted((res)["id"]!);
        if (mounted)
          setState(() {
            _loading = true;
          });
      } catch (error) {
        if (error.toString() == "No document") {
          if (mounted)
            setState(() {
              _errorMessage = timesUp
                  ? AppLocalizations.of(buildContext)!.outOfTimeError
                  : AppLocalizations.of(buildContext)!.noOrderNumberError;
              _loading = false;
            });
          if (newUser) email = "";
        } else {
          printConnectionError(setState);
        }
      }
    } catch (e) {
      printConnectionError(setState);
    }
  }

  addTimeToFirebase(int quantity) async {
    endTime = Timestamp.fromDate(DateTime.now().add(Duration(hours: quantity)));
    userHandler.setEndTime(endTime);
    bool timeAdded = await userHandler.addTimeToUser(quantity);
    if (timeAdded) {
      if (mounted)
        setState(() {
          _errorMessage = "";
          _loading = false;
        });
      mounted = false;
      if (startTimer != null && startTimer!.isActive) {
        startTimer!.cancel();
        startTimer = null;
      }
      signInSuccessful();
    } else {
      if (mounted)
        setState(() {
          _loading = false;
        });
      printConnectionError(setState);
    }
  }
}
