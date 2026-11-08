// Contract: Backend ec75064. Session tokens must never be logged or shared.
Map<String, dynamic> aiMap(Object? value) {
  if (value is! Map) throw const FormatException('Invalid AI response');
  return Map<String, dynamic>.from(value);
}

String aiText(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Missing AI text');
  }
  return value;
}

int aiInteger(Object? value, {int minimum = 0}) {
  if (value is! num ||
      !value.isFinite ||
      value != value.roundToDouble() ||
      value < minimum) {
    throw const FormatException('Invalid AI integer');
  }
  return value.toInt();
}

bool aiBoolean(Object? value) {
  if (value is! bool) throw const FormatException('Invalid AI flag');
  return value;
}

List<T> aiList<T>(
  Object? value,
  T Function(Object?) parse, {
  bool optional = false,
}) {
  if (value == null && optional) return List<T>.unmodifiable([]);
  if (value is! List) throw const FormatException('Invalid AI list');
  return List<T>.unmodifiable(value.map(parse));
}

String aiSessionToken(Object? value) {
  final token = aiText(value);
  if (!RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(token)) {
    throw const FormatException('Invalid AI session');
  }
  return token;
}

class AiCitation {
  final String documentCode, title, hierarchyPath;
  final double relevanceScore;
  const AiCitation(
    this.documentCode,
    this.title,
    this.hierarchyPath,
    this.relevanceScore,
  );
  factory AiCitation.fromJson(Object? value) {
    final m = aiMap(value);
    final score = m['relevanceScore'];
    if (score is! num || !score.isFinite) {
      throw const FormatException('Invalid AI score');
    }
    return AiCitation(
      aiText(m['documentCode']),
      aiText(m['title']),
      aiText(m['hierarchyPath']),
      score.toDouble(),
    );
  }
}

class AiSuggestedTrip {
  final int tripId, availableSeats;
  final String code,
      operator,
      origin,
      destination,
      departureDate,
      departureTime,
      vehicleType;
  final String? arrivalTime;
  final int? price;
  const AiSuggestedTrip({
    required this.tripId,
    required this.availableSeats,
    required this.code,
    required this.operator,
    required this.origin,
    required this.destination,
    required this.departureDate,
    required this.departureTime,
    required this.vehicleType,
    this.arrivalTime,
    this.price,
  });
  factory AiSuggestedTrip.fromJson(Object? value) {
    final m = aiMap(value);
    final date = aiText(m['departureDate']);
    final parsed = DateTime.tryParse(date);
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) ||
        parsed == null ||
        parsed.toIso8601String().substring(0, 10) != date) {
      throw const FormatException('Invalid AI trip date');
    }
    String clock(Object? v) {
      final s = aiText(v);
      if (!RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(s)) {
        throw const FormatException('Invalid AI clock');
      }
      return s;
    }

    // Deliberately ignore bookingUrl: only an API-verified tripId can navigate.
    return AiSuggestedTrip(
      tripId: aiInteger(m['tripId'], minimum: 1),
      availableSeats: aiInteger(m['availableSeats']),
      code: aiText(m['code']),
      operator: aiText(m['operator']),
      origin: aiText(m['origin']),
      destination: aiText(m['destination']),
      departureDate: date,
      departureTime: clock(m['departureTime']),
      vehicleType: aiText(m['vehicleType']),
      arrivalTime: m['arrivalTime'] == null ? null : clock(m['arrivalTime']),
      price: m['price'] == null ? null : aiInteger(m['price']),
    );
  }
}

class AiSuggestion {
  final String id, category, question, description;
  const AiSuggestion(this.id, this.category, this.question, this.description);
  factory AiSuggestion.fromJson(Object? value) {
    final m = aiMap(value);
    return AiSuggestion(
      aiText(m['id']),
      aiText(m['category']),
      aiText(m['question']),
      aiText(m['description']),
    );
  }
}

class AiChatReply {
  final String sessionToken, reply, intent;
  final List<AiCitation> citations;
  final List<AiSuggestedTrip> suggestedTrips;
  final List<String> suggestedQuestions;
  final bool requiresHumanHandoff;
  final String? handoffReason;
  final int latencyMs;
  const AiChatReply({
    required this.sessionToken,
    required this.reply,
    required this.intent,
    required this.citations,
    required this.suggestedTrips,
    required this.suggestedQuestions,
    required this.requiresHumanHandoff,
    required this.latencyMs,
    this.handoffReason,
  });
  factory AiChatReply.fromJson(Object? value) {
    final m = aiMap(value);
    return AiChatReply(
      sessionToken: aiSessionToken(m['sessionToken']),
      reply: aiText(m['reply']),
      intent: aiText(m['intent']),
      citations: aiList(m['citations'], AiCitation.fromJson),
      suggestedTrips: aiList(
        m['suggestedTrips'],
        AiSuggestedTrip.fromJson,
        optional: true,
      ),
      suggestedQuestions: aiList(
        m['suggestedQuestions'],
        aiText,
        optional: true,
      ),
      requiresHumanHandoff: aiBoolean(m['requiresHumanHandoff']),
      latencyMs: aiInteger(m['latencyMs']),
      handoffReason: m['handoffReason'] == null
          ? null
          : aiText(m['handoffReason']),
    );
  }
}

class AiHistoryMessage {
  final int id;
  final String role, content;
  final DateTime createdAt;
  final bool requiresHumanHandoff;
  final List<AiCitation> citations;
  final List<AiSuggestedTrip> suggestedTrips;
  const AiHistoryMessage(
    this.id,
    this.role,
    this.content,
    this.createdAt,
    this.requiresHumanHandoff,
    this.citations,
    this.suggestedTrips,
  );
  factory AiHistoryMessage.fromJson(Object? value) {
    final m = aiMap(value);
    final role = aiText(m['role']);
    final time = DateTime.tryParse(aiText(m['createdAt']));
    if (!{'USER', 'ASSISTANT', 'SYSTEM'}.contains(role) || time == null) {
      throw const FormatException('Invalid AI history');
    }
    return AiHistoryMessage(
      aiInteger(m['id'], minimum: 1),
      role,
      aiText(m['content']),
      time,
      aiBoolean(m['requiresHumanHandoff']),
      aiList(m['citations'], AiCitation.fromJson, optional: true),
      aiList(m['toolCalls'], AiSuggestedTrip.fromJson, optional: true),
    );
  }
}

class AiChatHistory {
  final String sessionToken, status;
  final List<AiHistoryMessage> messages;
  const AiChatHistory(this.sessionToken, this.status, this.messages);
  factory AiChatHistory.fromJson(Object? value) {
    final m = aiMap(value);
    return AiChatHistory(
      aiSessionToken(m['sessionToken']),
      aiText(m['status']),
      aiList(m['messages'], AiHistoryMessage.fromJson),
    );
  }
}
