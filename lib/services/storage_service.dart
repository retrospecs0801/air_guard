// lib/services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _homeLatKey = 'home_lat';
  static const _homeLngKey = 'home_lng';

  static Future<void> saveHome(double lat, double lng) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_homeLatKey, lat);
    await sp.setDouble(_homeLngKey, lng);
  }

  /// Returns null if home not set
  static Future<Map<String, double>?> loadHome() async {
    final sp = await SharedPreferences.getInstance();
    if (!sp.containsKey(_homeLatKey) || !sp.containsKey(_homeLngKey)) return null;
    final lat = sp.getDouble(_homeLatKey);
    final lng = sp.getDouble(_homeLngKey);
    if (lat == null || lng == null) return null;
    return {'lat': lat, 'lng': lng};
  }

  // --- ADD THIS METHOD ---
  /// Saves the cumulative pollution dose for the current day.
  static Future<void> saveDose(double dose) async {
    final prefs = await SharedPreferences.getInstance();
    // We should also save the date to know when to reset it.
    final today = DateTime.now();
    await prefs.setDouble('pollution_dose', dose);
    await prefs.setString('dose_saved_date', "${today.year}-${today.month}-${today.day}");
  }


  /// Loads the pollution dose. If the saved date is not today, it returns 0.
  static Future<double> loadDose() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDateStr = prefs.getString('dose_saved_date');

    if (savedDateStr == null) {
      return 0.0; // No date saved, start fresh
    }

    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month}-${today.day}";

    if (savedDateStr == todayStr) {
      // It's still the same day, load the saved dose.
      return prefs.getDouble('pollution_dose') ?? 0.0;
    } else {
      // It's a new day, reset the dose.
      return 0.0;
    }
  }
  static Future<void> clearHome() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_homeLatKey);
    await sp.remove(_homeLngKey);
  }
}
