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

