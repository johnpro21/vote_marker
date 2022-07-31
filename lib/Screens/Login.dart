import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:vote_marker/Screens/AdminPage.dart';
import 'package:vote_marker/Screens/HomePage.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController phoneController = TextEditingController();
  double screenHeight = 0;
  double screenWidth = 0;
  double bottom = 0;
  String usrtype = "";
  String otpPin = " ";
  String countryDial = "+91";
  String verID = " ";
  Timer? _timer;
  int screenState = 0;

  Color blue = const Color(0xff8cccff);

  get smsCode => null;
  var j = "";
  get verificationId => null;

  @override
  void initState() {
    super.initState();
    EasyLoading.addStatusCallback((status) {
      print('EasyLoading Status $status');
      if (status == EasyLoadingStatus.dismiss) {
        _timer?.cancel();
      }
    });
    //EasyLoading.showSuccess('Use in initState');
    // EasyLoading.removeCallbacks();
  }

  Future<void> verifyPhone(String number) async {
    print(number);
    String usrPno;
    bool usrfound = false;
    await EasyLoading.show(
      status: 'loading...',
      maskType: EasyLoadingMaskType.black,
    );
    var db = FirebaseFirestore.instance;
    await db.collection("users").get().then((users) async {
      for (var usr in users.docs) {
        j = usr.id;
        print(j);
        usrPno = usr.get("phno");
        print(usrPno);
        if (usrPno == number) {
          await FirebaseAuth.instance.verifyPhoneNumber(
            phoneNumber: number,
            timeout: const Duration(seconds: 40),
            verificationCompleted: (PhoneAuthCredential credential) {
              showSnackBarText("Auth Completed!");
            },
            verificationFailed: (FirebaseAuthException e) {
              EasyLoading.dismiss();
              showSnackBarText("Auth Failed!");
            },
            codeSent: (String verificationId, int? resendToken) {
              showSnackBarText("OTP Sent!");
              verID = verificationId;
              setState(() {
                EasyLoading.dismiss();
                screenState = 1;
              });
            },
            codeAutoRetrievalTimeout: (String verificationId) {
              showSnackBarText("Timeout!");
            },
          );
          usrfound = true;
          break;
        }
      }
      if (usrfound == false) {
        EasyLoading.dismiss();
        showSnackBarText("User not Found");
      }
    });
  }

  Future<void> verifyOTP() async {
    var userid;
    // await EasyLoading.show(
    //   status: 'logging...',
    //   maskType: EasyLoadingMaskType.black,
    // );
    var db = FirebaseFirestore.instance;
    print("j:" + j);
    await db.collection("users").doc(j).get().then((user) async {
      usrtype = user.get("user_typ").toString();
      userid = user.id;

      print(usrtype);
    });
    await FirebaseAuth.instance
        .signInWithCredential(
      PhoneAuthProvider.credential(
        verificationId: verID,
        smsCode: otpPin,
      ),
    )
        .whenComplete(() {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              usrtype == "b_o" ? HomeScreen(usrid: j) : const AdminPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    bottom = MediaQuery.of(context).viewInsets.bottom;
    return WillPopScope(
      onWillPop: () {
        setState(() {
          screenState = 0;
        });
        return Future.value(false);
      },
      child: Scaffold(
        backgroundColor: blue,
        body: SizedBox(
          height: screenHeight,
          width: screenWidth,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: screenHeight / 8),
                  child: Column(
                    children: [
                      Text(
                        "Login",
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: screenWidth / 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: circle(5),
              ),
              Transform.translate(
                offset: const Offset(30, -30),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: circle(4.5),
                ),
              ),
              Center(
                child: circle(3),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedContainer(
                  height: bottom > 0 ? screenHeight : screenHeight / 2,
                  width: screenWidth,
                  color: Colors.white,
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.fastLinearToSlowEaseIn,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: screenWidth / 12,
                      right: screenWidth / 12,
                      top: bottom > 0 ? screenHeight / 12 : 0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        screenState == 0 ? stateRegister() : stateOTP(),
                        GestureDetector(
                          onTap: () {
                            if (screenState == 0) {
                              if (phoneController.text.isEmpty) {
                                showSnackBarText(
                                    "Phone number is still empty!");
                              } else {
                                verifyPhone(countryDial + phoneController.text);
                              }
                            } else {
                              if (otpPin.length >= 6) {
                                verifyOTP();
                              } else {
                                showSnackBarText("Enter OTP correctly!");
                              }
                            }
                          },
                          child: Container(
                            height: 50,
                            width: screenWidth,
                            margin: EdgeInsets.only(bottom: screenHeight / 12),
                            decoration: BoxDecoration(
                              color: blue,
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: Center(
                              child: Text(
                                "Verify",
                                style: GoogleFonts.montserrat(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void showSnackBarText(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
      ),
    );
  }

  Widget stateRegister() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 16,
        ),
        Text(
          "Phone number",
          style: GoogleFonts.montserrat(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        IntlPhoneField(
          controller: phoneController,
          showCountryFlag: false,
          showDropdownIcon: false,
          initialValue: countryDial,
          onCountryChanged: (country) {
            setState(() {
              countryDial = "+" + country.dialCode;
            });
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget stateOTP() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: "We just sent a code to ",
                style: GoogleFonts.montserrat(
                  color: Colors.black87,
                  fontSize: 18,
                ),
              ),
              TextSpan(
                text: countryDial + phoneController.text,
                style: GoogleFonts.montserrat(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              TextSpan(
                text: "\nEnter the code here and we can continue!",
                style: GoogleFonts.montserrat(
                  color: Colors.black87,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        PinCodeTextField(
          appContext: context,
          length: 6,
          onChanged: (value) {
            setState(() {
              otpPin = value;
            });
          },
          pinTheme: PinTheme(
            activeColor: blue,
            selectedColor: blue,
            inactiveColor: Colors.black26,
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "Didn't receive the code? ",
                style: GoogleFonts.montserrat(
                  color: Colors.black87,
                  fontSize: 12,
                ),
              ),
              WidgetSpan(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      screenState = 0;
                    });
                  },
                  child: Text(
                    "Resend",
                    style: GoogleFonts.montserrat(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget circle(double size) {
    return Container(
      height: screenHeight / size,
      width: screenHeight / size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
    );
  }
}
