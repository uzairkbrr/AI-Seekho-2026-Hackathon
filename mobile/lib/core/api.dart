import 'dart:convert';
import 'package:http/http.dart' as http;

const String _base = 'http://10.0.2.2:8000/api';

Future<dynamic> get(String path) async {
  final res = await http.get(Uri.parse('$_base$path'));
  if (res.statusCode == 200) return jsonDecode(res.body);
  throw Exception('GET $path failed: ${res.statusCode}');
}

Future<dynamic> post(String path) async {
  final res = await http.post(Uri.parse('$_base$path'));
  if (res.statusCode == 200) return jsonDecode(res.body);
  throw Exception('POST $path failed: ${res.statusCode}');
}
