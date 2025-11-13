import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlertItem {
  final String id;
  final String title;
  final String body;
  final DateTime when;
  final Map<String, dynamic>? meta;
  AlertItem({required this.id, required this.title, required this.body, required this.when, this.meta});
}

final alertsProvider = StateNotifierProvider<AlertsNotifier, List<AlertItem>>((ref) {
  return AlertsNotifier();
});

class AlertsNotifier extends StateNotifier<List<AlertItem>> {
  AlertsNotifier() : super([]);

  void add(AlertItem a) {
    state = [a, ...state];
  }

  void clear() {
    state = [];
  }

  void remove(String id) {
    state = state.where((a) => a.id != id).toList();
  }
}
