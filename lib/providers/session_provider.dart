import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionState {
  final String? lastRoute;
  final String? lastLanguage;
  final Map<String, dynamic> pageData;

  SessionState({
    this.lastRoute,
    this.lastLanguage,
    this.pageData = const {},
  });

  SessionState copyWith({
    String? lastRoute,
    String? lastLanguage,
    Map<String, dynamic>? pageData,
  }) {
    return SessionState(
      lastRoute: lastRoute ?? this.lastRoute,
      lastLanguage: lastLanguage ?? this.lastLanguage,
      pageData: pageData ?? this.pageData,
    );
  }
}

class SessionNotifier extends StateNotifier<SessionState> {
  SessionNotifier() : super(SessionState()) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final route = prefs.getString('last_route');
    final language = prefs.getString('last_language');

    // Load page-specific data
    final Map<String, dynamic> pageData = {};

    // Profile screen data
    pageData['elder_name'] = prefs.getString('elder_name');
    pageData['elder_age'] = prefs.getString('elder_age');
    pageData['elder_phone'] = prefs.getString('elder_phone');
    pageData['elder_email'] = prefs.getString('elder_email');
    pageData['caregivers'] = prefs.getString('caregivers');

    // Home screen data
    pageData['heart_rate'] = prefs.getInt('heart_rate');
    pageData['spo2'] = prefs.getInt('spo2');
    pageData['inside_geofence'] = prefs.getBool('inside_geofence');
    pageData['last_update'] = prefs.getString('last_update');

    // Settings data
    pageData['notifications'] = prefs.getBool('notifications');
    pageData['darkTheme'] = prefs.getBool('darkTheme');

    state = SessionState(
      lastRoute: route,
      lastLanguage: language,
      pageData: pageData,
    );
  }

  Future<void> saveLastRoute(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_route', route);
    state = state.copyWith(lastRoute: route);
  }

  Future<void> saveLastLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_language', language);
    state = state.copyWith(lastLanguage: language);
  }

  Future<void> savePageData(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    }

    final newPageData = Map<String, dynamic>.from(state.pageData);
    newPageData[key] = value;
    state = state.copyWith(pageData: newPageData);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_route');
    await prefs.remove('last_language');
    state = SessionState();
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier();
});
