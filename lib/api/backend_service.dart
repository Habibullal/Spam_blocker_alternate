// lib/api/backend_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:spam_blocker/api/local_storage_service.dart';

// --- Data Models for API Responses ---

class RegisterResponse {
  final int userType;
  final String token;

  RegisterResponse({required this.userType, required this.token});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    // The 'token' is now expected inside the 'message' field for /register
    return RegisterResponse(
      userType: json['userType'],
      token: json['token'] ?? '', // Safely access the token
    );
  }
}

class CheckNumberResponse {
  final bool exists;
  final List<String> departments;

  CheckNumberResponse({required this.exists, this.departments = const []});

  factory CheckNumberResponse.fromJson(Map<String, dynamic> json) {
    return CheckNumberResponse(
      exists: json['exists'] == 1,
      departments: json['departments'] != null
          ? List<String>.from(json['departments'])
          : [],
    );
  }
}

class BlockedNumbersResponse {
  final List<String> numbers;
  final List<String> codes;

  BlockedNumbersResponse({required this.numbers, required this.codes});

  factory BlockedNumbersResponse.fromJson(Map<String, dynamic> json) {
    return BlockedNumbersResponse(
      numbers: List<String>.from(json['data']),
      codes: List<String>.from(json['codes']),
    );
  }
}

/// NEW: Model for a single report from the backend.
class Report {
  final String mobileNumber;
  final int status; // 0: Rejected, 1: Pending, 2: Accepted/Blocked

  Report({required this.mobileNumber, required this.status});

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      mobileNumber: json['MNE'], // Corresponds to the backend field
      status: json['stat'],      // Corresponds to the backend field
    );
  }
}


class BackendService {
  // IMPORTANT: Replace this with your actual backend URL
  final String _baseUrl = 'http://10.251.0.182:3000/api';

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final responseBody = json.decode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody['error'] == true) {
        throw Exception(responseBody['message'] ?? 'Backend returned an error.');
      }
      return responseBody;
    } else {
      throw Exception(responseBody['message'] ?? 'A server error occurred.');
    }
  }

  Future<CheckNumberResponse> checkNumberExists(String mobileNo) async {
    final url = Uri.parse('$_baseUrl/check');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'mobileNo': mobileNo}),
      );
      final data = await _handleResponse(response);
      return CheckNumberResponse.fromJson(data);
    } catch (e) {
      debugPrint('[BackendService] CheckNumberExists Error: $e');
      rethrow;
    }
  }

  Future<RegisterResponse> registerOrCheckUser({
    required String firebaseToken,
    String? username,
    String? department,
  }) async {
    final url = Uri.parse('$_baseUrl/register');
    try {
      final body = {
        'token': firebaseToken,
        'username': username,
        'department': department,
      };
      body.removeWhere((key, value) => value == null);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      final data = await _handleResponse(response);
      // The backend now returns the sid as 'token'
      return RegisterResponse.fromJson(data);
    } catch (e) {
      debugPrint('[BackendService] RegisterUser Error: $e');
      rethrow;
    }
  }

  // --- NEW: Report Endpoints ---

  /// Submits a new number report to the backend.
  /// Corresponds to your PATCH /report endpoint.
  Future<void> submitReport({
    required String firebaseToken,
    required String mobileNo,
  }) async {
    print(firebaseToken);
    Map<String, String> userProfile = await LocalAuthService().getUserProfile();
    final url = Uri.parse('$_baseUrl/report');
    try {
      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'token': firebaseToken,
          'mobileNo': mobileNo,
          'phone_number': userProfile['mobile'],
        }),
      );
      await _handleResponse(response);
    } catch (e) {
      debugPrint('[BackendService] SubmitReport Error: $e');
      rethrow;
    }
  }

  /// Fetches the user's report history from the backend.
  /// Corresponds to your POST /report endpoint.
  Future<List<Report>> getReports({required String firebaseToken}) async {
    final url = Uri.parse('$_baseUrl/report');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'token': firebaseToken}),
      );
      final data = await _handleResponse(response);
      final List<dynamic> reportData = data['data'];
      return reportData.map((json) => Report.fromJson(json)).toList();
    } catch (e) {
      debugPrint('[BackendService] GetReports Error: $e');
      rethrow;
    }
  }
}
