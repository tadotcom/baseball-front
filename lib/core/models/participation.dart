import 'user.dart';

class Participation {
  final String participationId;
  final String userId;
  final String gameId;
  final String teamDivision;
  final String position;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;

  Participation({
    required this.participationId,
    required this.userId,
    required this.gameId,
    required this.teamDivision,
    required this.position,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory Participation.fromJson(Map<String, dynamic> json) {
    if (json['participation_id'] == null ||
        json['user_id'] == null ||
        json['game_id'] == null ||
        json['team_division'] == null ||
        json['position'] == null ||
        json['status'] == null
    ) {
      throw FormatException(
          "Invalid Participation JSON received from API: $json");
    }

    DateTime? createdAt, updatedAt;
    try {
      if (json['created_at'] != null) {
        createdAt = DateTime.parse(json['created_at'] as String).toLocal();
      }
      if (json['updated_at'] != null) {
        updatedAt = DateTime.parse(json['updated_at'] as String).toLocal();
      }
    } catch (e) {
      print("Error parsing participation dates: $e");
      throw FormatException("Invalid date format in Participation JSON: $json");
    }

    return Participation(
      participationId: json['participation_id'] as String,
      userId: json['user_id'] as String,
      gameId: json['game_id'] as String,
      teamDivision: json['team_division'] as String,
      position: json['position'] as String,
      status: json['status'] as String,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
      user: json['user'] != null ? User.fromJson(json['user'] as Map<String, dynamic>) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'participation_id': participationId,
      'user_id': userId,
      'game_id': gameId,
      'team_division': teamDivision,
      'position': position,
      'status': status,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'user': user?.toJson(),
    };
  }

  @override
  String toString() {
    return 'Participation(participationId: $participationId, userId: $userId, gameId: $gameId, status: $status)';
  }

  Participation copyWith({
    String? participationId,
    String? userId,
    String? gameId,
    String? teamDivision,
    String? position,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? user,
  }) {
    return Participation(
      participationId: participationId ?? this.participationId,
      userId: userId ?? this.userId,
      gameId: gameId ?? this.gameId,
      teamDivision: teamDivision ?? this.teamDivision,
      position: position ?? this.position,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
    );
  }
}