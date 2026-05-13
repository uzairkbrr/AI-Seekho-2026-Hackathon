class CrisisEvent {
  final int id;
  final String title;
  final String eventType;
  final String severity;
  final double confidenceScore;
  final double lat;
  final double lng;
  final int? affectedPopulation;
  final double? expectedDurationHours;
  final String? likelyEvolution;
  final String contradictionLevel;
  final double? affectedRadiusKm;
  final String? peakImpactTime;
  final String? spreadRisk;
  final String? uncertaintyRange;
  final String status;
  final String createdAt;
  final List<Signal> signals;

  CrisisEvent({
    required this.id,
    required this.title,
    required this.eventType,
    required this.severity,
    required this.confidenceScore,
    required this.lat,
    required this.lng,
    this.affectedPopulation,
    this.expectedDurationHours,
    this.likelyEvolution,
    required this.contradictionLevel,
    this.affectedRadiusKm,
    this.peakImpactTime,
    this.spreadRisk,
    this.uncertaintyRange,
    required this.status,
    required this.createdAt,
    required this.signals,
  });

  factory CrisisEvent.fromJson(Map<String, dynamic> j) => CrisisEvent(
        id: j['id'],
        title: j['title'] ?? '',
        eventType: j['event_type'] ?? '',
        severity: j['severity'] ?? 'Low',
        confidenceScore: (j['confidence_score'] ?? 0.0).toDouble(),
        lat: (j['lat'] ?? 0.0).toDouble(),
        lng: (j['lng'] ?? 0.0).toDouble(),
        affectedPopulation: j['affected_population'],
        expectedDurationHours: j['expected_duration_hours']?.toDouble(),
        likelyEvolution: j['likely_evolution'],
        contradictionLevel: j['contradiction_level'] ?? 'None',
        affectedRadiusKm: j['affected_radius_km']?.toDouble(),
        peakImpactTime: j['peak_impact_time'],
        spreadRisk: j['spread_risk'],
        uncertaintyRange: j['uncertainty_range'],
        status: j['status'] ?? 'active',
        createdAt: j['created_at'] ?? '',
        signals: (j['signals'] as List? ?? [])
            .map((s) => Signal.fromJson(s))
            .toList(),
      );
}

class Signal {
  final int id;
  final String source;
  final String content;
  final double credibilityScore;
  final double urgencyScore;
  final bool isSuspicious;

  Signal({
    required this.id,
    required this.source,
    required this.content,
    required this.credibilityScore,
    required this.urgencyScore,
    required this.isSuspicious,
  });

  factory Signal.fromJson(Map<String, dynamic> j) => Signal(
        id: j['id'],
        source: j['source'] ?? '',
        content: j['content'] ?? '',
        credibilityScore: (j['credibility_score'] ?? 0.5).toDouble(),
        urgencyScore: (j['urgency_score'] ?? 0.0).toDouble(),
        isSuspicious: j['is_suspicious'] ?? false,
      );
}

class Resource {
  final int id;
  final String name;
  final String resourceType;
  final int totalUnits;
  final int availableUnits;
  final String status;

  Resource({
    required this.id,
    required this.name,
    required this.resourceType,
    required this.totalUnits,
    required this.availableUnits,
    required this.status,
  });

  factory Resource.fromJson(Map<String, dynamic> j) => Resource(
        id: j['id'],
        name: j['name'] ?? '',
        resourceType: j['resource_type'] ?? '',
        totalUnits: j['total_units'] ?? 0,
        availableUnits: j['available_units'] ?? 0,
        status: j['status'] ?? 'available',
      );
}

class Notification {
  final int id;
  final int eventId;
  final String recipient;
  final String subject;
  final String message;
  final String urgency;
  final String channel;
  final String createdAt;

  Notification({
    required this.id,
    required this.eventId,
    required this.recipient,
    required this.subject,
    required this.message,
    required this.urgency,
    required this.channel,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> j) => Notification(
        id: j['id'],
        eventId: j['event_id'],
        recipient: j['recipient'] ?? '',
        subject: j['subject'] ?? '',
        message: j['message'] ?? '',
        urgency: j['urgency'] ?? 'Routine',
        channel: j['channel'] ?? 'Dashboard',
        createdAt: j['created_at'] ?? '',
      );
}

