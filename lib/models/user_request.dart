class UserRequest {
  final String name;
  final String email;
  final String mobile;
  final String deviceId;
  final DateTime timestamp;

  UserRequest({
    required this.name,
    required this.email,
    required this.mobile,
    required this.deviceId,
    required this.timestamp,
  });

  // Convert object to a JSON format for Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      //'email': email,
      'mobile': mobile,
      'UUID': deviceId,
      'createdAt': timestamp,
      'authenticated': false
    };
  }
}