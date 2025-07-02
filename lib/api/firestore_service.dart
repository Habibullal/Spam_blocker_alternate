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

  // Check if a device is registered in the database
  Future<bool> isDeviceInDB(String? deviceId) async {
    // If deviceId is null, it cannot be in the DB
    if (deviceId == null) return false;
    try {
      final doc = await _firestore.collection('requests_authentication').doc(deviceId).get();
      // A device is considered registered if its document exists and 'authenticated' field is true
      dynamic isRegistered = doc.exists && doc.data()?['authenticated'] == true;
      return isRegistered;
    } catch (e) {
      debugPrint("Error `checking device in DB: $e");
      return false; // Return false on error
    }
  }

  // Send a login request for a new device
  void sendLoginRequest(UserRequest request) async {
    try {
      // Get the metadata document to increment the request count
      final md = await _firestore.collection('requests_authentication').doc('metadata').get();
      if (md.exists) {
        final val = md.data()?['requests'];
        // Update the request count
        await _firestore.collection('requests_authentication').doc('metadata').update({"requests": (val ?? 0) + 1});
      } else {
        // If metadata doesn't exist, create it
        await _firestore.collection('requests_authentication').doc('metadata').set({"requests": 1});
      }
      // Set the user request data, merging if it already exists
      await _firestore.collection('requests_authentication').doc(request.deviceId).set(request.toJson(), SetOptions(merge: true));
      debugPrint("Login request sent successfully for device: ${request.deviceId}");
    } catch (e) {
      debugPrint("Error sending login request: $e");
    }
  }

  // Fetch blocked numbers from Firestore
  void fetchNumbers() async {
    try {
      final numbers = await _firestore.collection("BlockedNumbers").doc("numbers").get();
      final numList = numbers.data()?['numbers'] as List<dynamic>?;
      if (numList != null) {
        final blockedNumbers = numList.map((e) => e.toString()).toSet();
        debugPrint("Fetched blocked numbers: $blockedNumbers");
        // You might want to update a local cache here if it's not already handled
        // LocalBlockedNumbersStorage.instance.updateNumbers(blockedNumbers);
      }
    } catch (e) {
      debugPrint("Error fetching blocked numbers: $e");
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

  // NEW: Fetch user profile by device ID from 'requests_authentication' collection
  Future<Map<String, String>> getUserProfileByDeviceId(String deviceId) async {
    try {
      final docSnapshot = await _firestore.collection('requests_authentication').doc(deviceId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          return {
            'name': data['name'] as String? ?? 'Unknown User',
            'email': data['email'] as String? ?? 'No Email',
            'mobile': data['mobile'] as String? ?? 'No Phone',
            'location': data['location'] as String? ?? 'Unknown Location', // Assuming 'location' might be added
            // Add other fields if they are part of UserRequest and need to be displayed
          };
        }
      }
    } catch (e) {
      debugPrint("Error fetching user profile from Firestore: $e");
    }
    return {}; // Return an empty map if no data is found or an error occurs
  }

  // NEW: Update user profile in 'requests_authentication' collection
  Future<void> updateUserProfile(String deviceId, Map<String, dynamic> newData) async {
    try {
      await _firestore.collection('requests_authentication').doc(deviceId).update(newData);
      debugPrint("User profile updated in Firestore for device: $deviceId");
    } catch (e) {
      debugPrint("Error updating user profile in Firestore: $e");
      rethrow; // Rethrow to handle in UI if necessary
    }
  }
}
