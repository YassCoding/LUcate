import 'dart:math';

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_app/home.dart';
import 'package:mobile_app/main.dart';
import 'package:image_picker/image_picker.dart';



class Groups extends StatelessWidget {
  const Groups({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: MyHomePage(title: 'Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController cmntController = TextEditingController();
  TextEditingController descController = TextEditingController();
  
  var _groupEntry = [];
  var _isPub = [];
  var _groupList = [];

  var dropdownValString = "Public";
  var tempMap = Map<String, dynamic>();

  //calls each time the app is opened
  @override
  void initState() {
    super.initState();
    _getGroupData();
  }

  Future<void> _getGroupData() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot querySnapshot = await firestore.collection('groups').get();
    var groupList = [];
    var name = "";
    QueryDocumentSnapshot doc;
    _groupEntry.clear();
    _isPub.clear();
    _groupList.clear();

    for (var doc in querySnapshot.docs) {
      groupList.add([
        doc['name'],
        doc['visibility'],
        doc['creator'],
        doc['description']
      ]);
    }
    
    var db = FirebaseFirestore.instance;
    var userEmail = FirebaseAuth.instance.currentUser?.email;

    List<Future<bool>> membershipChecks = groupList.map((group) async { // 
      var groupName = group[0];
      final groupQ = await db.collection('groups').where("name", isEqualTo: groupName).limit(1).get();
      if (groupQ.docs.isNotEmpty) {
        final groupDocRef = groupQ.docs.first.reference;
        final userDoc = await groupDocRef.collection('users').doc(userEmail).get();
        return userDoc.exists;
      }
      return false;
    }).toList();

    List<bool> groupEntry = await Future.wait(membershipChecks);
    List<bool> pubpriv = groupList.map((group)  { // 
      return group[1] == "Public";
    }).toList();

    setState(() {
      _groupList = groupList;
      _groupEntry = groupEntry;
      _isPub = pubpriv;
    });
  }

  Future<void> addCurrUserToGroup(String name) async{
    var fs = FirebaseFirestore.instance;

    var qs = await fs.collection('groups').where("name", isEqualTo: name).limit(1).get();

    if(qs.docs.isNotEmpty){
      var gdoc = qs.docs.first.reference;

      await gdoc.collection('users').doc(FirebaseAuth.instance.currentUser!.email).set({
      'email': FirebaseAuth.instance.currentUser!.email
    });
    }
  }
  

  Widget _buildPopupDialog(BuildContext context) {
    return StatefulBuilder(builder: (context, setDialogueState){
      return AlertDialog(
        title: const Text('Group Creation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: cmntController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Group Name',
              ),
            ),
            SizedBox(height: 5),
            TextField(
              maxLines: null,
              controller: descController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Description',
              ),
            ),
            DropdownButton(
              value: dropdownValString,
              hint: Text("Select a visibility"),
              items: ["Public", "Private"]
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? value) {
                setDialogueState(() {
                  dropdownValString = value!;
                });
              },
            ),
            SizedBox(height: 5),
          ],
        ),
        actions: <Widget>[
          ElevatedButton(
            onPressed: ()  {
            // add the newly created group to the group list dropdown option (public private) auth!.email
            // your codes begin here
            // create firebase (groupname, public/private, creator email, description, collection of users)
            // use set state? to update page?
            // close popup?
            tempMap['name'] = cmntController.text;
            tempMap['description'] = descController.text;
            tempMap['creator'] = FirebaseAuth.instance.currentUser?.email;
            tempMap['visibility'] = dropdownValString;
            FirebaseFirestore.instance.collection('groups').add(tempMap).then((doc) async {
              await doc.collection('users').doc(FirebaseAuth.instance.currentUser!.email).set({
                'email': FirebaseAuth.instance.currentUser!.email
              });
            });

            setState(() {
              _groupList.add([
                tempMap['name'],
                tempMap['visibility'],
                tempMap['creator'],
                tempMap['description'],
              ]);
              _isPub.add(tempMap['visibility'] == "Public");
              _groupEntry.add(true);
            });

            cmntController.clear();
            descController.clear();
            Navigator.of(context).pop();
            // end
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade300),
            child: const Text('Create'),
          ),
          ElevatedButton(
            onPressed: () {
              cmntController.clear();
              descController.clear();
              Navigator.of(context).pop();
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade300),
            child: const Text('Close'),
          ),
        ],
      );
    });
    
  }

  Widget _buildGroupDialog(BuildContext context, index) {
    return AlertDialog(
      title: const Text('Group Description'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(_groupList[index][3],
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12))
        ],
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            // show corresponding group description after click
            // your codes begin here
            // Join group by adding to collection of users in group
            // update state to update page?
            // close?
            addCurrUserToGroup(_groupList[index][0]);
            setState(() {
              _groupEntry[index] = true;
            });
            Navigator.of(context).pop();
            // end
          },
          style:
              ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade300),
          child: const Text('Join'),
        ),
        ElevatedButton(
          onPressed: () {
            // your codes begin here
            Navigator.of(context).pop();
            // end
          },
          style:
              ElevatedButton.styleFrom(backgroundColor: Colors.indigo.shade300),
          child: const Text('Close'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "Location",
        home: Scaffold(
            backgroundColor: Colors.lightGreen[100],
            body: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage("lib/assets/mountain.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Center(
                    child: Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightGreen.shade300,
                              minimumSize: Size(64, 64),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50.0),
                                  side: BorderSide(
                                      color: Colors.lightGreen.shade300)),
                            ),
                            child: Icon(
                              Icons.home,
                              size: 30.0,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Home()),
                              );
                            },
                          ),
                          SizedBox(width: 60),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade300),
                            child: const Text('Create a Group'),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    _buildPopupDialog(context),
                              );
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Existing Groups",
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Colors.indigo.shade300),
                      ),
                      SizedBox(height: 20),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Container(
                                height: 30,
                                width: 380,
                                alignment: Alignment.center,
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Container(
                                          width: 95,
                                          child: Text(
                                            "Name",
                                            style: TextStyle(
                                                color: Colors.indigo.shade500),
                                          )),
                                      Container(
                                          width: 75,
                                          child: Text(
                                            "Visibility",
                                            style: TextStyle(
                                                color: Colors.indigo.shade500),
                                          )),
                                      Container(
                                          width: 110,
                                          child: Text(
                                            "Creator",
                                            style: TextStyle(
                                                color: Colors.indigo.shade500),
                                          )),
                                      Container(width: 95, child: Text("")),
                                    ])),
                          ]),
                      Divider(color: Colors.black),
                      Expanded(
                          child: SizedBox(
                        height: 200.0,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _groupList.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Container(
                                      height: 70,
                                      width: 380,
                                      alignment: Alignment.center,
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Container(
                                                width: 95,
                                                child: Text(
                                                  _groupList[index][0],
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      color: Colors
                                                          .indigo.shade500),
                                                )),
                                            Container(
                                                width: 50,
                                                child: Text(
                                                  _groupList[index][1],
                                                  style: TextStyle(
                                                      color: Colors
                                                          .indigo.shade500),
                                                )),
                                            Container(
                                                width: 110,
                                                child: Text(
                                                  _groupList[index][2],
                                                  style: TextStyle(
                                                      color: Colors
                                                          .indigo.shade500),
                                                )),
                                            Container(
                                              width: 95,
                                              child: _groupEntry[index] == false
                                                  ? _groupList[index][1] ==
                                                          "Public"
                                                      ? ElevatedButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .indigo
                                                                          .shade300),
                                                          child: Text(
                                                              'Join Group',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontSize:
                                                                      12)),
                                                          onPressed: () {
                                                            showDialog(
                                                              context: context,
                                                              builder: (BuildContext
                                                                      context) =>
                                                                  _buildGroupDialog(
                                                                      context,
                                                                      index),
                                                            );
                                                          },
                                                        )
                                                      : ElevatedButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .indigo
                                                                          .shade300),
                                                          child:
                                                              Icon(Icons.check),
                                                          onPressed: () => {},
                                                        )
                                                  : ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                              backgroundColor:
                                                                  Colors.indigo
                                                                      .shade300),
                                                      child: Icon(Icons.check),
                                                      onPressed: () => {},
                                                    ),
                                            )
                                          ])),
                                ]);
                          },
                        ),
                      ))
                    ],
                  ),
                )))));
  }
}
