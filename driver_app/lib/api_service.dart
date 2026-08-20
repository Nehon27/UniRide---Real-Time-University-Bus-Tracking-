import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class ApiService {
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('${AppConfig.apiBase}/driver_login.php'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': username, 'password': password},
    ).timeout(const Duration(seconds: 10));

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<bool> sendLocation(int driverId, double lat, double lng) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiBase}/update_location.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'driver_id': driverId.toString(),
          'lat': lat.toString(),
          'lng': lng.toString(),
        },
      ).timeout(const Duration(seconds: 10));

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  static Future<void> stopTracking(int driverId) async {
    try {
      await http.post(
        Uri.parse('${AppConfig.apiBase}/stop_tracking.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'driver_id': driverId.toString()},
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // best-effort; nothing to do if this fails
    }
  }
}
