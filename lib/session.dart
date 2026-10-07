import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps track of the currently logged-in user on this device,
/// so they don't have to log in again every time they open the app.
class Session {
  static Future<void> save({
    required int id,
    required String name,
    required String email,
    required String phone,
    required String token,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', id);
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('user_phone', phone);
    await prefs.setString('user_token', token);
  }

  static Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('user_id');
    if (id == null) return null;
    return {
      'id': id,
      'name': prefs.getString('user_name') ?? '',
      'email': prefs.getString('user_email') ?? '',
      'phone': prefs.getString('user_phone') ?? '',
      'token': prefs.getString('user_token') ?? '',
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_phone');
    await prefs.remove('user_token');
  }
}

/// Keeps the shopping cart saved on the device, so items survive the
/// app being closed, killed in the background, or the phone restarting —
/// not just kept in memory, which disappears if Android kills the app
/// after a period of inactivity.
class CartStorage {
  static Future<void> save(List<Map<String, dynamic>> cart) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_cart', json.encode(cart));
  }

  static Future<List<Map<String, dynamic>>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('saved_cart');
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = json.decode(raw) as List;
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_cart');
  }
}

/// Keeps the in-progress checkout address (and captured GPS point) saved,
/// so navigating back to Cart and returning to Checkout doesn't wipe out
/// what the user already filled in or the location they already captured.
class CheckoutDraft {
  static Future<void> save({
    required String house,
    required String area,
    double? latitude,
    double? longitude,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('draft_house', house);
    await prefs.setString('draft_area', area);
    if (latitude != null) await prefs.setDouble('draft_lat', latitude);
    if (longitude != null) await prefs.setDouble('draft_lng', longitude);
  }

  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'house': prefs.getString('draft_house') ?? '',
      'area': prefs.getString('draft_area') ?? '',
      'latitude': prefs.getDouble('draft_lat'),
      'longitude': prefs.getDouble('draft_lng'),
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('draft_house');
    await prefs.remove('draft_area');
    await prefs.remove('draft_lat');
    await prefs.remove('draft_lng');
  }
}
