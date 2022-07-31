import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class HomeScreen extends StatefulWidget {
  final String usrid;
  const HomeScreen({Key? key, required this.usrid}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String boothNo = "", boothName = "", usrName = "";
  late String aaddaarNo, address, vName, voterId, gender;
  late int matchedFId, mCount = 0, fCount = 0;
  late bool vote;
  @override
  void initState() {
    super.initState();
    getBoothData();
    EasyLoading.dismiss();
    //EasyLoading.showSuccess('Use in initState');
    // EasyLoading.removeCallbacks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Image.asset(
                "assets/images/vote_marker_logo.jpeg",
                width: 250,
                height: 250,
              ),
            ),
          ),
          // Text(
          //   "Booth no:" + boothNo,
          //   style: const TextStyle(
          //     fontSize: 28,
          //   ),
          // ),
          Text(
            "Booth Name:" + boothName + " - " + boothNo,
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
          Text(
            "Officer Incharge:" + usrName,
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
          Container(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: () async {
                  await EasyLoading.show(
                    status: 'Scanning...',
                    maskType: EasyLoadingMaskType.black,
                  );
                  scanVoter();
                },
                child: const Text(
                  "Scan",
                  style: TextStyle(
                    fontSize: 60,
                  ),
                ),
                style: const ButtonStyle(),
              ),
            ),
          ),
          Text(
            mCount.toString(),
            style: const TextStyle(
              fontSize: 40,
            ),
          ),
          const Text(
            "Male Count",
            style: TextStyle(
              fontSize: 24,
            ),
          ),
          Text(
            fCount.toString(),
            style: const TextStyle(
              fontSize: 40,
            ),
          ),
          const Text(
            "Female Count",
            style: TextStyle(
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> getBoothData() async {
    var db = FirebaseFirestore.instance;
    //print("usrid:" + widget.usrid);
    await db.collection("users").doc(widget.usrid).get().then((user) async {
      boothNo = user.get("booth_id").toString();
      await db.collection("booths").doc(boothNo).get().then((booth) {
        setState(() {
          usrName = user.get("name");
          boothName = booth.get("name");
          boothNo = user.get("booth_id").toString();
          mCount = booth.get("m_count");
          fCount = booth.get("f_count");
        });
      });
    });
  }

  Future<void> scanVoter() async {
    bool flg = false;

    var db = FirebaseFirestore.instance;

    await db
        .collection("booths")
        .doc(boothNo)
        .update({"scanner": true}).whenComplete(() async {
      await Future.delayed(const Duration(seconds: 10), () {
        print('One second has passed.'); // Prints after 1 second.
      });
      final docRef = db.collection("booths").doc(boothNo);
      docRef.snapshots(includeMetadataChanges: true).listen((booth) async {
        var scanResult = booth.get("finger_result");

        if (scanResult > 0) {
          await db
              .collection("voters")
              .doc(boothNo)
              .collection("booth-voters")
              .get()
              .then((voters) async {
            for (var voter in voters.docs) {
              var finger = voter.get("fingerprint");
              print(finger);
              for (var f in finger) {
                matchedFId = scanResult;
                print(f.runtimeType);
                if (f == matchedFId) {
                  voterId = voter.id;

                  aaddaarNo = voter.get("aaddhaar_no").toString();
                  address = voter.get("address");
                  vName = voter.get("name").toString();
                  vote = voter.get("vote");
                  gender = voter.get("gender");
                  print("vname" + vName);

                  EasyLoading.dismiss();
                  await EasyLoading.showSuccess('Match Found!');
                  await db
                      .collection("booths")
                      .doc(boothNo)
                      .update({"finger_result": -1}).whenComplete(() {
                    print("result updated -1");
                  });
                  voterDetails();
                }
              }
            }
          });
          flg = true;
        }
      });
    });
    if (flg = false) {
      EasyLoading.dismiss();
      await EasyLoading.showError('Match Not Found!');
    }
  }

  Future<void> voterDetails() async {
    var db = FirebaseFirestore.instance;
    db
        .collection("voters")
        .doc(boothNo)
        .collection("booth-voters")
        .doc(voterId)
        .get()
        .then((voter) async {
      vote = voter.get("vote");
    }).catchError((e) => print(e));

    var sts = vote == false ? "Not Voted" : "Already Voted";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            "Voter Details",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Container(
            height: 300,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Name            :" + vName,
                  style: const TextStyle(
                    fontSize: 24,
                  ),
                ),
                Text(
                  "Gender         :" + gender,
                  style: const TextStyle(
                    fontSize: 24,
                  ),
                ),
                Text(
                  "Aadhaar No :" + aaddaarNo,
                  style: const TextStyle(
                    fontSize: 24,
                  ),
                ),
                Text(
                  "Address       :" + address,
                  style: const TextStyle(
                    fontSize: 24,
                  ),
                ),
                Text(
                  "Vote Status :" + sts,
                  style: const TextStyle(
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: vote
                  ? null
                  : () async {
                      var db = FirebaseFirestore.instance;
                      if (gender == "male") {
                        setState(() {
                          mCount++;
                        });
                        await db
                            .collection("booths")
                            .doc(boothNo)
                            .update({"m_count": mCount}).whenComplete(
                                () => print("male +1"));
                      } else {
                        setState(() {
                          fCount++;
                        });
                        await db
                            .collection("booths")
                            .doc(boothNo)
                            .update({"f_count": fCount}).whenComplete(
                                () => print("female +1"));
                      }

                      await db
                          .collection("voters")
                          .doc(boothNo)
                          .collection("booth-voters")
                          .doc(voterId)
                          .update({
                        "vote": true,
                      }).whenComplete(() {
                        print("Completed");
                      }).catchError((e) => print(e));
                      Navigator.pop(context);
                    },
              child: const Text('Mark as Verified'),
            ),
          ],
        );
      },
    );
  }
}
