import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api.dart';
import '../../core/models.dart';

final eventsProvider = FutureProvider<List<CrisisEvent>>((ref) async {
  final data = await get('/events') as List;
  return data.map((e) => CrisisEvent.fromJson(e)).toList();
});

final criticalCountProvider = FutureProvider<int>((ref) async {
  final events = await ref.watch(eventsProvider.future);
  return events.where((e) => e.severity.toLowerCase() == 'critical').length;
});

class EventResponseState {
  final List<RoadClosure> closures;
  final List<DispatchTrack> dispatches;
  final List<AlertZone> zones;
  final List<EmergencyTicket> tickets;
  final List<AlertLogEntry> log;

  const EventResponseState({
    required this.closures,
    required this.dispatches,
    required this.zones,
    required this.tickets,
    required this.log,
  });

  bool get isEmpty =>
      closures.isEmpty &&
      dispatches.isEmpty &&
      zones.isEmpty &&
      tickets.isEmpty &&
      log.isEmpty;
}

final eventResponseProvider =
    FutureProvider.family<EventResponseState, int>((ref, eventId) async {
  final results = await Future.wait([
    get('/closures?event_id=$eventId'),
    get('/dispatches?event_id=$eventId'),
    get('/alert-zones?event_id=$eventId'),
    get('/tickets?event_id=$eventId'),
    get('/alert-log?event_id=$eventId&limit=80'),
  ]);
  return EventResponseState(
    closures: (results[0] as List).map((e) => RoadClosure.fromJson(e)).toList(),
    dispatches:
        (results[1] as List).map((e) => DispatchTrack.fromJson(e)).toList(),
    zones: (results[2] as List).map((e) => AlertZone.fromJson(e)).toList(),
    tickets:
        (results[3] as List).map((e) => EmergencyTicket.fromJson(e)).toList(),
    log: (results[4] as List).map((e) => AlertLogEntry.fromJson(e)).toList(),
  );
});
