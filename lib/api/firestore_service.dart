// firestore_service.dart
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
      debugPrint("Error checking device in DB: $e");
      return false; // Return false on error
    }
  }

  // Send a login request for a new device
  Future<bool> sendLoginRequest(UserRequest request) async {
    try {
      // Get the metadata document to increment the request count
      final md = await _firestore.collection('requests_authentication').doc('metadata').get();
      int currentRequests = (md.data()?['requests'] as int?) ?? 0;

      await _firestore.runTransaction((transaction) async {
        // Increment the 'requests' counter in the metadata document
        final metadataRef = _firestore.collection('requests_authentication').doc('metadata');
        transaction.set(metadataRef, {'requests': FieldValue.increment(1)}, SetOptions(merge: true));

        // Set the new device's request document
        final deviceRequestRef = _firestore.collection('requests_authentication').doc(request.deviceId);
        transaction.set(deviceRequestRef, request.toJson());
      });
      return true;
    } catch (e) {
      debugPrint("Error sending access request: $e");
      return false;
    }
  }

  // NEW: Function to delete device document and decrement authenticated counter
  Future<void> deleteDeviceAndDecrementAuthenticatedCounter(String deviceId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        // Delete the device's document
        final deviceDocRef = _firestore.collection('requests_authentication').doc(deviceId);
        transaction.delete(deviceDocRef);

        // Atomically decrement the 'authenticated' counter in the metadata document
        final metadataRef = _firestore.collection('requests_authentication').doc('metadata');
        transaction.set(metadataRef, {'authenticated': FieldValue.increment(-1)}, SetOptions(merge: true));
      });
      debugPrint("Device $deviceId removed and authenticated counter decremented.");
    } catch (e) {
      debugPrint("Error deleting device document or decrementing counter: $e");
      rethrow;
    }
  }

  // Placeholder for fetchNumbers - implement real logic if needed
  void fetchNumbers() async {
    // This function needs to fetch blocked numbers from Firestore and store them locally
    // For now, it's a placeholder.
    debugPrint("Fetching numbers (placeholder)...");
  }

  // Handle reporting a number
  Future<void> submitReport(Report report) async {
    try {
      final reportDocRef = _firestore.collection('reports').doc(report.number);

      // Using a transaction to ensure atomicity for both report submission and metadata update
      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(reportDocRef);

        if (!docSnapshot.exists) {
          // If the document doesn't exist, it's a new report for this number
          // Increment the reports counter in the metadata document
          final metadataRef = _firestore.collection('reports').doc('metadata');
          transaction.set(metadataRef, {'reports': FieldValue.increment(1)}, SetOptions(merge: true));
        }

        // Add or update the report details, setting lastReported timestamp
        // The reported phone number is the document ID.
        // We use SetOptions(merge: true) to either create a new document or update an existing one.
        // The structure will be:
        // reports/{reportedNumber}: {
        //   'lastReported': Timestamp,
        //   'reporterDeviceId1': { reason, timestamp, reporterName, reporterNumber, status },
        //   'reporterDeviceId2': { reason, timestamp, reporterName, reporterNumber, status },
        // }
        transaction.set(
          reportDocRef,
          {
            'lastReported': report.timestamp, // Update lastReported timestamp
            report.reporterDeviceId: report.toInnerMap(), // Direct nesting using reporterDeviceId
          },
          SetOptions(merge: true),
        );
      });
      debugPrint("Report for ${report.number} submitted successfully.");
    } catch (e) {
      debugPrint("Error submitting report: $e");
      rethrow;
    }
  }


  // NEW: Function to get report status for a given number
  Future<String> getReportStatus(String phoneNumber) async {
    try {
      // Check if the number exists in the 'reports' collection
      final reportDoc = await _firestore.collection('reports').doc(phoneNumber).get();
      if (reportDoc.exists) {
        // If the document exists, we need to check if there's at least one report by a device.
        // Since we're flattening, just checking for existence means it has been reported.
        // The presence of any fields other than 'lastReported' would indicate a specific report.
        // For simplicity, if the document exists, we assume it's pending.
        // You might want a more sophisticated check here if you have an "admin" status field for the number itself.
        final data = reportDoc.data();
        if (data != null && data.keys.length > 1) { // Check if there's more than just 'lastReported'
          return 'Pending';
        }
      }

      // Check if the number is in the 'blocked/numbers' document
      final blockedNumbersDoc = await _firestore.collection('blocked').doc('numbers').get();
      if (blockedNumbersDoc.exists) {
        final data = blockedNumbersDoc.data();
        if (data != null && data.containsKey(phoneNumber)) {
          return 'Blocked';
        }
      }

      // If not in reports or blocked, it's rejected
      return 'Rejected';
    } catch (e) {
      debugPrint("Error getting report status for $phoneNumber: $e");
      return 'Unknown'; // Return unknown status on error
    }
  }

  // Fetch user profile by device ID from 'requests_authentication' collection
  Future<Map<String, String>> getUserProfileByDeviceId(String deviceId) async {
    try {
      final docSnapshot = await _firestore.collection('requests_authentication').doc(deviceId).get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          return {
            'name': data['name'] as String? ?? '',
            'mobile': data['mobile'] as String? ?? '',
            // Remove location since it's not in your UserRequest model
          };
        }
      }
      debugPrint("No profile found for device: $deviceId");
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
      rethrow; // Rethrow to allow UI to handle the error
    }
  }
}