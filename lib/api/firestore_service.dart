import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:spam_blocker/api/local_storage_service.dart';
import 'package:spam_blocker/models/user_request.dart';
import 'package:spam_blocker/models/report.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirestoreService() {
    _firestore.settings = const Settings(persistenceEnabled: false);
    fetchNumbers();
  }

  Future<bool> isDeviceInDB(String? deviceId) async {
    final doc = await _firestore.collection('requests_authentication').doc(deviceId).get();
    dynamic isRegistered;

    if (doc.exists) {
      isRegistered = doc.data()?['authenticated'] == true;
    } else {
      isRegistered = false;
    }

    return isRegistered;
  }

  void sendLoginRequest(UserRequest request) async {
    final md = await _firestore.collection('requests_authentication').doc('metadata').get();
    if (md.exists) {
      final val = md.data()?['requests'];
      await _firestore.collection('requests_authentication').doc('metadata').update({"requests": val + 1});
      await _firestore.collection('requests_authentication').doc(request.deviceId).set(request.toJson());
    } else {
      print("Could not send request");
    }
  }

  void fetchNumbers() async {
    try {
      final numbers = await _firestore.collection("BlockedNumbers").doc("numbers").get();
      final numList = numbers.data()?['numbers'] as List<dynamic>?;
      if (numList != null) {
        final blockedNumbers = numList.map((e) => e.toString()).toSet();
        print("Fetched blocked numbers: $blockedNumbers");
      }
    } catch (e) {
      print("Error fetching blocked numbers: $e");
    }
  }

  // Modified method to report a number using the new structure
  Future<void> reportNumber(Report report, String reportedNumber) async {
    try {
      final docRef = _firestore.collection('reports').doc(reportedNumber);

      await _firestore.runTransaction((transaction) async {
        // Use toInnerMap() which now includes reporterName and reporterNumber
        final Map<String, dynamic> dataToSet = {
          report.reporterDeviceId: report.toInnerMap(),
        };

        transaction.set(
          docRef,
          dataToSet,
          SetOptions(merge: true),
        );
      });
      debugPrint('Report for $reportedNumber successfully added to Firestore.');
    } catch (e) {
      debugPrint('Error reporting number to Firestore: $e');
      rethrow;
    }
  }
}
