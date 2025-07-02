// lib/models/report.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String number;
  final String reason;
  final Timestamp timestamp; // Stored as Timestamp for Firestore
  final String reporterDeviceId;
  final String reporterName; // New: Reporter's name
  final String reporterNumber; // New: Reporter's number
  final String status;

  Report({
    required this.number,
    required this.reason,
    required this.timestamp,
    required this.reporterDeviceId,
    required this.reporterName, // Updated constructor
    required this.reporterNumber, // Updated constructor
    required this.status,
  });
  // For Firestore storage - this is the map that goes into the document
  // e.g., 'reports/{reportedNumber}': {
  //   'reporterDeviceId1': { /* toInnerMap() content */ },
  //   'reporterDeviceId2': { /* toInnerMap() content */ },
  // }
  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'reason': reason,
      'timestamp': timestamp, // Firestore handles Timestamp directly
      'reporterDeviceId': reporterDeviceId,
      'reporterName': reporterName,
      'reporterNumber': reporterNumber,
      'status': status,
    };
  }

  // This method creates the inner map for Firestore's 'set with merge'
  // It contains the details specific to THIS report instance by a device.
  Map<String, dynamic> toInnerMap() {
    return {
      'reason': reason,
      'timestamp': timestamp,
      'reporterName': reporterName,
      'reporterNumber': reporterNumber,
      'status': status,
    };
  }

  // For Local Storage (SharedPreferences) - converts Timestamp to String
  Map<String, dynamic> toLocalJson() {
    return {
      'number': number,
      'reason': reason,
      'timestamp': timestamp.toDate().toIso8601String(), // Convert to String for local storage
      'reporterDeviceId': reporterDeviceId,
      'reporterName': reporterName,
      'reporterNumber': reporterNumber,
      'status': status,
    };
  }

  // Factory constructor to create a Report object from a JSON map
  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      number: json['number'] as String,
      reason: json['reason'] as String,
      timestamp: json['timestamp'] is Timestamp
          ? json['timestamp'] as Timestamp
          : Timestamp.fromDate(DateTime.parse(json['timestamp'] as String)),
      reporterDeviceId: json['reporterDeviceId'] as String,
      reporterName: json['reporterName'] as String, // Updated factory
      reporterNumber: json['reporterNumber'] as String, // Updated factory
      status: json['status'] as String,
    );
  }
}