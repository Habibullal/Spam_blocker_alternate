// user_request.dart
class UserRequest {
  final String name;
  final String mobile; // Removed email
  final String deviceId;
  final DateTime timestamp;
  final String department;

  UserRequest({
    required this.name,
    required this.mobile, // Removed email
    required this.deviceId,
    required this.timestamp,
    required this.department,
  });

  // Convert object to a JSON format for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'mobile': mobile,
      'deviceId': deviceId, // Use 'deviceId' directly, removed 'UUID'
      'createdAt': timestamp,
      'authenticated': false,
      'department': department
    };
  }
}