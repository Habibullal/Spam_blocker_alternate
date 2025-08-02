// lib/api/backend_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

// New data model for the registration request
class RegisterRequest {
  final String token;
  final String? username;
  final String? department;
  
  RegisterRequest({
    required this.token,
    this.username,
    this.department,
  });

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'username': username,
      'department': department,
    };
  }
}

class BackendService {
  final String _baseUrl = 'http://10.251.0.182:3000/api'; 

  /// Registers a new user on the custom backend server.
  /// Throws an [Exception] if the registration fails.
  Future<bool> registerUser(RegisterRequest request) async {
    final url = Uri.parse('$_baseUrl/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      print('Registration Response: $responseData');
      if (responseData['error'] == false) {
        return true;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to register.');
      }
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'An unknown server error occurred.');
    }
  }
}