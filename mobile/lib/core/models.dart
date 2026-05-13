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

class RoadClosure {
  final int id;
  final int eventId;
  final String label;
  final String reason;
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final String status;

  RoadClosure({
    required this.id,
    required this.eventId,
    required this.label,
    required this.reason,
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    required this.status,
  });

  factory RoadClosure.fromJson(Map<String, dynamic> j) => RoadClosure(
        id: j['id'],
        eventId: j['event_id'],
        label: j['label'] ?? '',
        reason: j['reason'] ?? '',
        fromLat: (j['from_lat'] ?? 0.0).toDouble(),
        fromLng: (j['from_lng'] ?? 0.0).toDouble(),
        toLat: (j['to_lat'] ?? 0.0).toDouble(),
        toLng: (j['to_lng'] ?? 0.0).toDouble(),
        status: j['status'] ?? 'active',
      );
}

class DispatchTrack {
  final int id;
  final int eventId;
  final int resourceId;
  final int? allocationId;
  final int units;
  final double fromLat;
  final double fromLng;
  final double toLat;
  final double toLng;
  final double currentLat;
  final double currentLng;
  final double etaMinutes;
  final double progress;
  final String status;

  DispatchTrack({
    required this.id,
    required this.eventId,
    required this.resourceId,
    required this.allocationId,
    required this.units,
    required this.fromLat,
    required this.fromLng,
    required this.toLat,
    required this.toLng,
    required this.currentLat,
    required this.currentLng,
    required this.etaMinutes,
    required this.progress,
    required this.status,
  });

  factory DispatchTrack.fromJson(Map<String, dynamic> j) => DispatchTrack(
        id: j['id'],
        eventId: j['event_id'],
        resourceId: j['resource_id'],
        allocationId: j['allocation_id'],
        units: j['units'] ?? 1,
        fromLat: (j['from_lat'] ?? 0.0).toDouble(),
        fromLng: (j['from_lng'] ?? 0.0).toDouble(),
        toLat: (j['to_lat'] ?? 0.0).toDouble(),
        toLng: (j['to_lng'] ?? 0.0).toDouble(),
        currentLat: (j['current_lat'] ?? 0.0).toDouble(),
        currentLng: (j['current_lng'] ?? 0.0).toDouble(),
        etaMinutes: (j['eta_minutes'] ?? 0.0).toDouble(),
        progress: (j['progress'] ?? 0.0).toDouble(),
        status: j['status'] ?? 'enroute',
      );
}

class AlertZone {
  final int id;
  final int eventId;
  final double centerLat;
  final double centerLng;
  final double radiusKm;
  final String severity;
  final String message;
  final int broadcastCount;
  final String status;

  AlertZone({
    required this.id,
    required this.eventId,
    required this.centerLat,
    required this.centerLng,
    required this.radiusKm,
    required this.severity,
    required this.message,
    required this.broadcastCount,
    required this.status,
  });

  factory AlertZone.fromJson(Map<String, dynamic> j) => AlertZone(
        id: j['id'],
        eventId: j['event_id'],
        centerLat: (j['center_lat'] ?? 0.0).toDouble(),
        centerLng: (j['center_lng'] ?? 0.0).toDouble(),
        radiusKm: (j['radius_km'] ?? 0.0).toDouble(),
        severity: j['severity'] ?? 'Medium',
        message: j['message'] ?? '',
        broadcastCount: j['broadcast_count'] ?? 0,
        status: j['status'] ?? 'active',
      );
}

class EmergencyTicket {
  final int id;
  final int eventId;
  final String ticketCode;
  final String category;
  final String priority;
  final String title;
  final String description;
  final String assignee;
  final String status;
  final double? etaMinutes;
  final int? resourceId;
  final int? dispatchId;
  final int? closureId;
  final int? zoneId;
  final String createdAt;
  final String? resolvedAt;

  EmergencyTicket({
    required this.id,
    required this.eventId,
    required this.ticketCode,
    required this.category,
    required this.priority,
    required this.title,
    required this.description,
    required this.assignee,
    required this.status,
    required this.etaMinutes,
    required this.resourceId,
    required this.dispatchId,
    required this.closureId,
    required this.zoneId,
    required this.createdAt,
    required this.resolvedAt,
  });

  factory EmergencyTicket.fromJson(Map<String, dynamic> j) => EmergencyTicket(
        id: j['id'],
        eventId: j['event_id'],
        ticketCode: j['ticket_code'] ?? '',
        category: j['category'] ?? '',
        priority: j['priority'] ?? 'P3',
        title: j['title'] ?? '',
        description: j['description'] ?? '',
        assignee: j['assignee'] ?? '',
        status: j['status'] ?? 'open',
        etaMinutes: j['eta_minutes']?.toDouble(),
        resourceId: j['resource_id'],
        dispatchId: j['dispatch_id'],
        closureId: j['closure_id'],
        zoneId: j['zone_id'],
        createdAt: j['created_at'] ?? '',
        resolvedAt: j['resolved_at'],
      );
}

class AlertLogEntry {
  final int id;
  final int? eventId;
  final String channel;
  final String level;
  final String title;
  final String message;
  final int? ticketId;
  final String createdAt;

  AlertLogEntry({
    required this.id,
    required this.eventId,
    required this.channel,
    required this.level,
    required this.title,
    required this.message,
    required this.ticketId,
    required this.createdAt,
  });

  factory AlertLogEntry.fromJson(Map<String, dynamic> j) => AlertLogEntry(
        id: j['id'],
        eventId: j['event_id'],
        channel: j['channel'] ?? '',
        level: j['level'] ?? 'info',
        title: j['title'] ?? '',
        message: j['message'] ?? '',
        ticketId: j['ticket_id'],
        createdAt: j['created_at'] ?? '',
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

class AgentTrace {
  final int id;
  final String agent;
  final String stage;
  final int? eventId;
  final String summary;
  final String reasoning;
  final String? prompt;
  final String? decision;
  final String status;
  final String createdAt;

  AgentTrace({
    required this.id,
    required this.agent,
    required this.stage,
    required this.eventId,
    required this.summary,
    required this.reasoning,
    required this.prompt,
    required this.decision,
    required this.status,
    required this.createdAt,
  });

  factory AgentTrace.fromJson(Map<String, dynamic> j) => AgentTrace(
        id: (j['id'] as num?)?.toInt() ?? 0,
        agent: (j['agent'] ?? '').toString(),
        stage: (j['stage'] ?? '').toString(),
        eventId: (j['event_id'] as num?)?.toInt(),
        summary: (j['summary'] ?? '').toString(),
        reasoning: (j['reasoning'] ?? '').toString(),
        prompt: j['prompt'] as String?,
        decision: j['decision'] as String?,
        status: (j['status'] ?? 'ok').toString(),
        createdAt: (j['created_at'] ?? '').toString(),
      );
}

