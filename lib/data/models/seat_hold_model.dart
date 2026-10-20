import 'package:equatable/equatable.dart';

/// Model representing a temporary seat reservation per rule-api.md and endpoint-api.md
class SeatHoldModel extends Equatable {
  final String holdToken;
  final int tripId;
  final List<int> seatIds;
  final List<String> seatCodes;
  final DateTime expiresAt;
  final DateTime? createdAt;

  const SeatHoldModel({
    required this.holdToken,
    required this.tripId,
    required this.seatIds,
    this.seatCodes = const [],
    required this.expiresAt,
    this.createdAt,
  });

  SeatHoldModel copyWith({
    String? holdToken,
    int? tripId,
    List<int>? seatIds,
    List<String>? seatCodes,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return SeatHoldModel(
      holdToken: holdToken ?? this.holdToken,
      tripId: tripId ?? this.tripId,
      seatIds: seatIds ?? this.seatIds,
      seatCodes: seatCodes ?? this.seatCodes,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory SeatHoldModel.fromJson(Map<String, dynamic> json) {
    // 1. Strict holdToken
    final rawHoldToken = json['holdToken'];
    if (rawHoldToken == null ||
        rawHoldToken is! String ||
        rawHoldToken.trim().isEmpty) {
      throw const FormatException(
        'SeatHoldModel contract violation: holdToken is required and cannot be empty',
      );
    }
    final holdToken = rawHoldToken.trim();

    // 2. Strict tripId
    final rawTripId = json['tripId'];
    final tripId = (rawTripId is num)
        ? rawTripId.toInt()
        : (rawTripId is String ? int.tryParse(rawTripId) : null);
    if (tripId == null || tripId <= 0) {
      throw const FormatException(
        'SeatHoldModel contract violation: tripId must be a positive integer',
      );
    }

    // 3. Strict seatIds
    final rawSeatIds = json['seatIds'];
    if (rawSeatIds is! List || rawSeatIds.isEmpty) {
      throw const FormatException(
        'SeatHoldModel contract violation: seatIds must be a non-empty list',
      );
    }
    final parsedSeatIds = rawSeatIds
        .map((e) => (e is num) ? e.toInt() : int.tryParse(e.toString()))
        .whereType<int>()
        .toList();
    if (parsedSeatIds.length != rawSeatIds.length ||
        parsedSeatIds.any((id) => id <= 0)) {
      throw const FormatException(
        'SeatHoldModel contract violation: seatIds must contain valid positive integers',
      );
    }

    // 4. Strict expiresAt
    final rawExpiresAt = json['expiresAt'];
    if (rawExpiresAt is! String) {
      throw const FormatException(
        'SeatHoldModel contract violation: expiresAt is required as ISO-8601 string',
      );
    }
    final parsedExpiresAt = DateTime.tryParse(rawExpiresAt);
    if (parsedExpiresAt == null) {
      throw FormatException(
        'SeatHoldModel contract violation: expiresAt has invalid datetime format ($rawExpiresAt)',
      );
    }

    // Optional fields
    List<String> parsedSeatCodes = [];
    if (json['seatCodes'] is List) {
      parsedSeatCodes = (json['seatCodes'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (json['seats'] is List) {
      parsedSeatCodes = (json['seats'] as List)
          .map((e) => e.toString())
          .toList();
    }

    DateTime? parsedCreatedAt;
    if (json['createdAt'] is String) {
      parsedCreatedAt = DateTime.tryParse(json['createdAt'] as String);
    }

    return SeatHoldModel(
      holdToken: holdToken,
      tripId: tripId,
      seatIds: parsedSeatIds,
      seatCodes: parsedSeatCodes,
      expiresAt: parsedExpiresAt,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'holdToken': holdToken,
    'tripId': tripId,
    'seatIds': seatIds,
    if (seatCodes.isNotEmpty) 'seatCodes': seatCodes,
    'expiresAt': expiresAt.toIso8601String(),
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  /// Countdown helpers
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get remainingTime => expiresAt.difference(DateTime.now());
  int get remainingSeconds =>
      remainingTime.isNegative ? 0 : remainingTime.inSeconds;

  /// Returns remaining time formatted as mm:ss
  String get formattedRemainingTime {
    final secs = remainingSeconds;
    final minutes = secs ~/ 60;
    final remainingSecs = secs % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSecs.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [holdToken, tripId, seatIds, expiresAt];
}
