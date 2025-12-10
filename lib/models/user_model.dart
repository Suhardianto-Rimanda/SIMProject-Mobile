class User {
  final int id;
  final String fullName;
  final String username;
  final String role;
  final String? accessToken; // Token hanya ada saat Login response

  User({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
    this.accessToken,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle struktur JSON yang mungkin berbeda antara Login vs List User
    // Login: { "user": { "id": 1, ... }, "access_token": "..." }
    // List: { "id": 1, "username": "...", ... }

    // Cek jika ini response Login (ada 'user' di dalamnya)
    if (json.containsKey('user')) {
      final userData = json['user'];
      return User(
        id: userData['id'] ?? 0, // Default 0 jika tidak ada
        fullName: userData['full_name'] ?? 'No Name',
        username: userData['username'],
        role: userData['role'],
        accessToken: json['access_token'],
      );
    }

    // Response List User biasa
    return User(
      id: json['id'] ?? 0,
      fullName: json['full_name'] ?? 'Staff',
      username: json['username'],
      role: json['role'],
      accessToken: null,
    );
  }
}