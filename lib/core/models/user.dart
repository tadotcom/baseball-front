
class User {
  final String userId;
  final String email;
  final String nickname;

  User({
    required this.userId,
    required this.email,
    required this.nickname,
  });

  factory User.fromJson(Map<String, dynamic> json) {
  if (json['user_id'] == null || json['email'] == null || json['nickname'] == null) {
    throw FormatException("Invalid User JSON received from API: $json");
  }
  return User(
      userId: json['user_id'] as String,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
  );
  }

  Map<String, dynamic> toJson() {
  return {
    'user_id': userId,
    'email': email,
    'nickname': nickname,
  };
  }

  @override
  String toString() {
    return 'User(userId: $userId, email: $email, nickname: $nickname)';
  }
}