import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elder_monitor/providers/alerts_provider.dart';

void main() {
  group('AlertItem Tests', () {
    test('should create AlertItem with required fields', () {
      final now = DateTime.now();
      final alert = AlertItem(
        id: 'alert-1',
        title: 'Queda detectada',
        body: 'O idoso pode ter caído.',
        when: now,
      );
      
      expect(alert.id, 'alert-1');
      expect(alert.title, 'Queda detectada');
      expect(alert.body, 'O idoso pode ter caído.');
      expect(alert.when, now);
      expect(alert.meta, isNull);
    });

    test('should create AlertItem with meta data', () {
      final alert = AlertItem(
        id: 'alert-2',
        title: 'Bateria baixa',
        body: 'A bateria do relógio está em 15%.',
        when: DateTime.now(),
        meta: {'batteryLevel': 15, 'critical': true},
      );
      
      expect(alert.meta, isNotNull);
      expect(alert.meta!['batteryLevel'], 15);
      expect(alert.meta!['critical'], true);
    });

    test('should handle different alert types', () {
      final alertTypes = [
        'Queda detectada',
        'Bateria baixa',
        'Fora da área segura',
        'Inatividade prolongada',
        'Frequência cardíaca elevada',
      ];
      
      for (int i = 0; i < alertTypes.length; i++) {
        final alert = AlertItem(
          id: 'alert-$i',
          title: alertTypes[i],
          body: 'Descrição do alerta',
          when: DateTime.now(),
        );
        expect(alert.title, alertTypes[i]);
      }
    });
  });

  group('AlertsNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('should have initial empty state', () {
      final alerts = container.read(alertsProvider);
      expect(alerts, isEmpty);
    });

    test('should add an alert', () {
      final alert = AlertItem(
        id: 'alert-1',
        title: 'Queda detectada',
        body: 'O idoso pode ter caído.',
        when: DateTime.now(),
      );
      
      container.read(alertsProvider.notifier).add(alert);
      
      final alerts = container.read(alertsProvider);
      expect(alerts.length, 1);
      expect(alerts.first.title, 'Queda detectada');
    });

    test('should add alerts in reverse chronological order (newest first)', () {
      final notifier = container.read(alertsProvider.notifier);
      
      notifier.add(AlertItem(
        id: '1', title: 'First', body: 'First alert', when: DateTime.now()));
      notifier.add(AlertItem(
        id: '2', title: 'Second', body: 'Second alert', when: DateTime.now()));
      notifier.add(AlertItem(
        id: '3', title: 'Third', body: 'Third alert', when: DateTime.now()));
      
      final alerts = container.read(alertsProvider);
      expect(alerts.length, 3);
      // Newest should be first
      expect(alerts[0].title, 'Third');
      expect(alerts[1].title, 'Second');
      expect(alerts[2].title, 'First');
    });

    test('should remove an alert by id', () {
      final notifier = container.read(alertsProvider.notifier);
      
      notifier.add(AlertItem(
        id: '1', title: 'First', body: 'Body', when: DateTime.now()));
      notifier.add(AlertItem(
        id: '2', title: 'Second', body: 'Body', when: DateTime.now()));
      
      notifier.remove('2');
      
      final alerts = container.read(alertsProvider);
      expect(alerts.length, 1);
      expect(alerts.first.id, '1');
    });

    test('should clear all alerts', () {
      final notifier = container.read(alertsProvider.notifier);
      
      notifier.add(AlertItem(
        id: '1', title: 'First', body: 'Body', when: DateTime.now()));
      notifier.add(AlertItem(
        id: '2', title: 'Second', body: 'Body', when: DateTime.now()));
      notifier.add(AlertItem(
        id: '3', title: 'Third', body: 'Body', when: DateTime.now()));
      
      expect(container.read(alertsProvider).length, 3);
      
      notifier.clear();
      
      expect(container.read(alertsProvider), isEmpty);
    });

    test('should handle removing non-existent alert gracefully', () {
      final notifier = container.read(alertsProvider.notifier);
      
      notifier.add(AlertItem(
        id: '1', title: 'First', body: 'Body', when: DateTime.now()));
      
      // Remove non-existent id
      notifier.remove('non-existent');
      
      final alerts = container.read(alertsProvider);
      expect(alerts.length, 1); // Original still there
    });

    test('should handle multiple add and remove operations', () {
      final notifier = container.read(alertsProvider.notifier);
      
      notifier.add(AlertItem(id: '1', title: 'A', body: 'B', when: DateTime.now()));
      notifier.add(AlertItem(id: '2', title: 'C', body: 'D', when: DateTime.now()));
      notifier.remove('1');
      notifier.add(AlertItem(id: '3', title: 'E', body: 'F', when: DateTime.now()));
      notifier.remove('2');
      
      final alerts = container.read(alertsProvider);
      expect(alerts.length, 1);
      expect(alerts.first.id, '3');
    });

    test('should preserve alert data after operations', () {
      final now = DateTime(2024, 1, 15, 10, 30);
      final notifier = container.read(alertsProvider.notifier);
      
      notifier.add(AlertItem(
        id: 'important',
        title: 'Emergência',
        body: 'Situação crítica',
        when: now,
        meta: {'priority': 'high', 'acknowledged': false},
      ));
      
      // Add more alerts
      notifier.add(AlertItem(id: '2', title: 'Other', body: 'B', when: DateTime.now()));
      notifier.add(AlertItem(id: '3', title: 'Another', body: 'C', when: DateTime.now()));
      
      // Find our important alert
      final alerts = container.read(alertsProvider);
      final important = alerts.firstWhere((a) => a.id == 'important');
      
      expect(important.title, 'Emergência');
      expect(important.body, 'Situação crítica');
      expect(important.when, now);
      expect(important.meta!['priority'], 'high');
    });
  });
}
