import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api.dart';
import '../../core/models.dart' as ciro;

final notificationsProvider = FutureProvider<List<ciro.Notification>>((ref) async {
  final data = await get('/notifications') as List;
  return data.map((n) => ciro.Notification.fromJson(n)).toList();
});

