import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:spam_blocker/api/local_storage_service.dart';
import 'package:spam_blocker/models/user_request.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreService(){
    _firestore.settings = const Settings(persistenceEnabled: false);
     fetchNumbers();

  //   StreamSubscription<DocumentSnapshot> numberSub = _firestore.collection("BlockedNumbers").doc("numbers").snapshots().listen((DocumentSnapshot snapshot){
  //     if(!snapshot.exists) return;
  //     fetchNumbers();
  //     print("boo");
  //   });
  // }
  }

  Future<bool> isDeviceInDB(String? deviceId) async {
    final doc = await _firestore.collection('requests_authentication').doc(deviceId).get();
      dynamic isRegistered;

      if(doc.exists) {
        isRegistered = doc.data()?['status'] == 'true';
      } else {
        isRegistered = false; // Device not found in Firestore
      }

      return isRegistered;
  }

  void sendLoginRequest(UserRequest request) async {
     await _firestore.collection('requests_authentication').doc(request.deviceId).set(request.toJson());
  }

  void fetchNumbers() async{
    try{
      final numbers = await _firestore.collection("BlockedNumbers").doc("numbers").get();
      final numList = numbers.data()!.keys;
      LocalBlockedNumbersStorage.instance.createNumberSet(numList.toSet());
    } catch(e){
      debugPrint("$e");
    }
  }
}
