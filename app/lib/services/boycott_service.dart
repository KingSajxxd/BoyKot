import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

class BoycottService {
  // REPLACE THIS LINK WITH YOUR RAW GITHUB LINK
  static const String _remoteUrl = 
      'https://raw.githubusercontent.com/KingSajxxd/BoyKot/refs/heads/main/app/assets/boycott_data.json';

  Future<Map<String, dynamic>?> loadData() async {
    // 1. Try to fetch the latest data from the internet
    try {
      final response = await http.get(Uri.parse(_remoteUrl)).timeout(
        const Duration(seconds: 5), // Don't make the user wait too long
      );

      if (response.statusCode == 200) {
        // If successful, parse and return the fresh data
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      // If no internet or error, silently fail and fall back to local
      print("⚠️ Offline or GitHub down. Using local data.");
    }

    // 2. Fallback: Load the local file shipped with the app
    try {
      final jsonString = await rootBundle.loadString('assets/boycott_data.json');
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchLiveToll() async {
    try {
      final url = Uri.parse(
        'https://data.techforpalestine.org/api/v2/casualties_daily.json',
      );
      final response = await http.get(url);
      if (response.statusCode != 200) return null;

      final List<dynamic> history = json.decode(response.body);
      if (history.isEmpty) return null;

      int getLast(String key) {
        for (var i = history.length - 1; i >= 0; i--) {
          final val = history[i][key];
          if (val != null && val is int && val > 0) return val;
        }
        return 0;
      }

      final latest = history.last;
      final int aidKilled = getLast('aid_seeker_killed_cum');
      final int aidInjured = getLast('aid_seeker_injured_cum');

      return {
        'killed': latest['killed_cum'] ?? 0,
        'children': getLast('ext_killed_children_cum'),
        'women': getLast('ext_killed_women_cum'),
        'starved': getLast('famine_cum'),
        'medical': getLast('ext_med_killed_cum'),
        'press': getLast('ext_press_killed_cum'),
        'civil_defense': getLast('ext_civdef_killed_cum'),
        'aid_attacked': aidKilled + aidInjured,
        'injured': latest['injured_cum'] ?? 0,
        'last_update': latest['report_date'] ?? 'Today',
      };
    } catch (_) {
      return null;
    }
  }
}
