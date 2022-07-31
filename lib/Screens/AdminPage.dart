import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  void initState() {
    super.initState();
    EasyLoading.dismiss();
    load();

    //EasyLoading.showSuccess('Use in initState');
    // EasyLoading.removeCallbacks();
  }

  late String name;

  Future<void> load() async {
    var db = FirebaseFirestore.instance;
    //print("usrid:" + widget.usrid);
    await db.collection("users").doc("1003").get().then((user) {
      setState(() {
        name = user.get("name");
      });
    });
  }

  final Stream<QuerySnapshot> _boothStream =
      FirebaseFirestore.instance.collection('booths').snapshots();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Page")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _boothStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Loading");
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data()! as Map<String, dynamic>;
              return ListTile(
                title: Text("Booth Name:" + data['name']),
                subtitle: Text("Male Count:" +
                    data['m_count'].toString() +
                    "   Female Count:" +
                    data['f_count'].toString()),
              );
            }).toList(),
          );
        },
      ),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(name),
            ),
            ListTile(
              title: const Text('Admin Page'),
              onTap: () {
                // Update the state of the app
                // ...
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
