import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api.dart';
import '../../core/models.dart';

final resourcesProvider = FutureProvider<List<Resource>>((ref) async {
  final data = await get('/resources') as List;
  return data.map((r) => Resource.fromJson(r)).toList();
});

