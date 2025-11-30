import 'participation.dart';

class Game {
  final String gameId;
  final String placeName;
  final DateTime gameDateTime;
  final String address;
  final String prefecture;
  final double latitude;
  final double longitude;
  final int acceptableRadius;
  final String status;
  final int fee;
  final int capacity;
  final int participantCount;

  final bool? isParticipating;
  final bool? hasCheckedIn;
  final List<Participation>? participants;

  Game({
    required this.gameId,
    required this.placeName,
    required this.gameDateTime,
    required this.address,
    required this.prefecture,
    required this.latitude,
    required this.longitude,
    required this.acceptableRadius,
    required this.status,
    required this.fee,
    required this.capacity,
    required this.participantCount,

    this.isParticipating,
    this.hasCheckedIn,
    this.participants,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      gameId: json['game_id'] as String,
      placeName: json['place_name'] as String,
      gameDateTime: DateTime.parse(json['game_date_time'] as String).toLocal(),
      address: json['address'] as String,
      prefecture: json['prefecture'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      acceptableRadius: (json['acceptable_radius'] as num).toInt(),
      status: json['status'] as String,
      fee: (json['fee'] as num?)?.toInt() ?? 0,
      capacity: (json['capacity'] as num).toInt(),
      participantCount: (json['participant_count'] as num?)?.toInt() ??
          (json['participants'] as List?)?.length ??
          0,
      isParticipating: json['is_participating'] as bool?,
      hasCheckedIn: json['has_checked_in'] as bool?,
      participants: (json['participants'] as List?)
          ?.map((p) => Participation.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'game_id': gameId,
      'place_name': placeName,
      'game_date_time': gameDateTime.toUtc().toIso8601String(), // Store in UTC ISO format
      'address': address,
      'prefecture': prefecture,
      'latitude': latitude,
      'longitude': longitude,
      'acceptable_radius': acceptableRadius,
      'status': status,
      'fee': fee,
      'capacity': capacity,
      'participant_count': participantCount,
      'is_participating': isParticipating,
      'has_checked_in': hasCheckedIn,
      'participants': participants?.map((p) => p.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'Game(gameId: $gameId, placeName: $placeName, dateTime: $gameDateTime, status: $status)';
  }
}