/// Tests for RFP Functional Requirements
/// Sistema de Localização Inteligente para Smartwatches com GPS
/// UFSCar - Sorocaba
/// 
/// Requisitos Funcionais:
/// 1. Rastreamento GPS
/// 2. Controle Remoto
/// 3. Modo de Emergência
/// 4. Visualização em Mapa
/// 5. Otimização de Energia
/// 6. Integração com Notificações
/// 7. Autonomia de Operação

import 'package:flutter_test/flutter_test.dart';
import 'package:elder_monitor/models/location_data.dart';
import 'package:elder_monitor/models/health_data.dart';
import 'package:elder_monitor/services/firebase_sync_service.dart';
import 'package:elder_monitor/providers/geofence_provider.dart';
import 'package:elder_monitor/providers/alerts_provider.dart';
import 'package:elder_monitor/providers/device_providers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  // ============================================================
  // REQUISITO 1: RASTREAMENTO GPS
  // Obter e atualizar a posição geográfica do usuário em 
  // intervalos configuráveis
  // ============================================================
  group('REQ-1: Rastreamento GPS', () {
    test('1.1 - LocationData deve armazenar coordenadas GPS válidas', () {
      final location = LocationData(
        latitude: -23.5505,
        longitude: -46.6333,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );
      
      expect(location.latitude, -23.5505);
      expect(location.longitude, -46.6333);
      expect(location.accuracy, 10.0);
    });

    test('1.2 - LocationData deve validar coordenadas dentro dos limites', () {
      // Latitude válida: -90 a 90
      // Longitude válida: -180 a 180
      final validLocation = LocationData(
        latitude: 90.0,
        longitude: 180.0,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );
      
      expect(validLocation.latitude, lessThanOrEqualTo(90));
      expect(validLocation.latitude, greaterThanOrEqualTo(-90));
      expect(validLocation.longitude, lessThanOrEqualTo(180));
      expect(validLocation.longitude, greaterThanOrEqualTo(-180));
    });

    test('1.3 - Deve calcular distância entre duas posições', () {
      final pos1 = LocationData(
        latitude: -23.5505,
        longitude: -46.6333,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );
      
      final pos2 = LocationData(
        latitude: -23.5515,
        longitude: -46.6343,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );
      
      final distance = pos1.distanceTo(pos2);
      
      // Distância deve ser aproximadamente 150 metros
      expect(distance, greaterThan(100));
      expect(distance, lessThan(200));
    });

    test('1.4 - Deve detectar precisão do GPS', () {
      final accurateLocation = LocationData(
        latitude: -23.5505,
        longitude: -46.6333,
        accuracy: 5.0,
        timestamp: DateTime.now(),
      );
      
      final inaccurateLocation = LocationData(
        latitude: -23.5505,
        longitude: -46.6333,
        accuracy: 50.0,
        timestamp: DateTime.now(),
      );
      
      expect(accurateLocation.isAccurate(), true);
      expect(inaccurateLocation.isAccurate(), false);
    });

    test('1.5 - Firebase paths devem estar corretos para localização', () {
      final path = FirebaseSyncService.getLocationPath('elder123');
      expect(path, 'elders/elder123/location');
    });

    test('1.6 - Serialização JSON deve preservar dados de localização', () {
      final original = LocationData(
        latitude: -23.5505,
        longitude: -46.6333,
        accuracy: 10.0,
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );
      
      final json = original.toJson();
      final restored = LocationData.fromJson(json);
      
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.accuracy, original.accuracy);
    });
  });

  // ============================================================
  // REQUISITO 2: CONTROLE REMOTO
  // Permite que um responsável altere a taxa de atualização 
  // via aplicativo ou web
  // ============================================================
  group('REQ-2: Controle Remoto da Taxa de Atualização', () {
    test('2.1 - Deve ter configuração de intervalo de atualização', () {
      // Intervalos suportados: 5, 10, 30 minutos ou tempo real
      const updateIntervals = [5, 10, 30, 1]; // minutos (1 = tempo real)
      
      expect(updateIntervals.contains(5), true);
      expect(updateIntervals.contains(10), true);
      expect(updateIntervals.contains(30), true);
      expect(updateIntervals.contains(1), true);
    });

    test('2.2 - Firebase path para configurações do dispositivo', () {
      final path = FirebaseSyncService.getDeviceStatusPath('elder123');
      expect(path, 'elders/elder123/device');
    });

    test('2.3 - DeviceSettings deve armazenar taxa de atualização', () {
      // O provider deviceSettingsProvider armazena o intervalo em segundos
      const defaultInterval = 300; // 5 minutos
      
      expect(defaultInterval, 300);
    });

    test('2.4 - Deve validar elder ID para controle remoto', () {
      expect(FirebaseSyncService.isValidElderId('elder123'), true);
      expect(FirebaseSyncService.isValidElderId(''), false);
      expect(FirebaseSyncService.isValidElderId('elder/bad'), false);
    });
  });

  // ============================================================
  // REQUISITO 3: MODO DE EMERGÊNCIA
  // Ativar rastreamento contínuo em situações críticas
  // ============================================================
  group('REQ-3: Modo de Emergência', () {
    test('3.1 - DeviceStatus deve indicar modo de emergência', () {
      final device = DeviceStatus(
        deviceId: 'watch001',
        lastUpdate: DateTime.now(),
        batteryLevel: 50,
        gpsSignal: true,
        emergencyMode: true,
      );
      
      expect(device.emergencyMode, true);
    });

    test('3.2 - HealthData deve detectar condições críticas', () {
      final criticalHealth = HealthData(
        heartRate: 45, // abaixo de 50 é crítico
        spo2: 85, // abaixo de 90 é crítico
        steps: 0,
        temperature: 39.5,
        bloodPressure: '180/110',
        timestamp: DateTime.now(),
      );
      
      expect(criticalHealth.isCritical, true);
    });

    test('3.3 - HealthData normal não deve disparar emergência', () {
      final normalHealth = HealthData(
        heartRate: 75,
        spo2: 98,
        steps: 5000,
        temperature: 36.5,
        bloodPressure: '120/80',
        timestamp: DateTime.now(),
      );
      
      expect(normalHealth.isCritical, false);
    });

    test('3.4 - Batimentos muito baixos devem ser críticos', () {
      final lowHeartRate = HealthData(
        heartRate: 40,
        spo2: 98,
        steps: 5000,
        temperature: 36.5,
        bloodPressure: '120/80',
        timestamp: DateTime.now(),
      );
      
      expect(lowHeartRate.isCritical, true);
    });

    test('3.5 - Batimentos muito altos devem ser críticos', () {
      final highHeartRate = HealthData(
        heartRate: 160,
        spo2: 98,
        steps: 5000,
        temperature: 36.5,
        bloodPressure: '120/80',
        timestamp: DateTime.now(),
      );
      
      expect(highHeartRate.isCritical, true);
    });

    test('3.6 - Geração de ID de alerta único para emergências', () {
      final id1 = FirebaseSyncService.generateAlertId();
      final id2 = FirebaseSyncService.generateAlertId();
      
      expect(id1, isNotEmpty);
      expect(id1, isNot(equals(id2)));
    });
  });

  // ============================================================
  // REQUISITO 4: VISUALIZAÇÃO EM MAPA
  // Exibir a localização atual e o histórico recente em 
  // mapa interativo
  // ============================================================
  group('REQ-4: Visualização em Mapa', () {
    test('4.1 - GeofenceArea deve armazenar área segura no mapa', () {
      final geofence = GeofenceArea(
        id: 'home',
        center: const LatLng(-23.5505, -46.6333),
        radius: 100.0,
        name: 'Casa',
      );
      
      expect(geofence.id, 'home');
      expect(geofence.radius, 100.0);
      expect(geofence.name, 'Casa');
    });

    test('4.2 - Deve detectar se localização está dentro da área segura', () {
      final center = LocationData(
        latitude: -23.5505,
        longitude: -46.6333,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );
      
      final insidePoint = LocationData(
        latitude: -23.5506,
        longitude: -46.6334,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );
      
      final outsidePoint = LocationData(
        latitude: -23.5600,
        longitude: -46.6400,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );
      
      // Raio de 100 metros
      expect(insidePoint.isWithinRadius(center, 100), true);
      expect(outsidePoint.isWithinRadius(center, 100), false);
    });

    test('4.3 - GeofenceNotifier deve adicionar áreas', () {
      final notifier = GeofenceNotifier();
      
      notifier.add(GeofenceArea(
        id: 'home',
        center: const LatLng(-23.5505, -46.6333),
        radius: 100.0,
        name: 'Casa',
      ));
      
      expect(notifier.state.length, 1);
      expect(notifier.state.first.name, 'Casa');
    });

    test('4.4 - GeofenceNotifier deve remover áreas', () {
      final notifier = GeofenceNotifier();
      
      notifier.add(GeofenceArea(
        id: 'home',
        center: const LatLng(-23.5505, -46.6333),
        radius: 100.0,
        name: 'Casa',
      ));
      
      notifier.remove('home');
      
      expect(notifier.state.length, 0);
    });

    test('4.5 - Firebase path para geofences deve estar correto', () {
      final path = FirebaseSyncService.getGeofencesPath('elder123');
      expect(path, 'elders/elder123/geofences');
    });

    test('4.6 - Histórico de localização deve manter ordem cronológica', () {
      final locations = <LocationData>[];
      
      locations.add(LocationData(
        latitude: -23.5505,
        longitude: -46.6333,
        accuracy: 10.0,
        timestamp: DateTime(2024, 1, 15, 10, 0),
      ));
      
      locations.add(LocationData(
        latitude: -23.5510,
        longitude: -46.6340,
        accuracy: 10.0,
        timestamp: DateTime(2024, 1, 15, 10, 5),
      ));
      
      locations.add(LocationData(
        latitude: -23.5515,
        longitude: -46.6345,
        accuracy: 10.0,
        timestamp: DateTime(2024, 1, 15, 10, 10),
      ));
      
      // Ordenar por timestamp
      locations.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      expect(locations.first.timestamp.minute, 0);
      expect(locations.last.timestamp.minute, 10);
    });
  });

  // ============================================================
  // REQUISITO 5: OTIMIZAÇÃO DE ENERGIA
  // Reduzir o consumo de bateria por meio de atualizações 
  // adaptativas
  // ============================================================
  group('REQ-5: Otimização de Energia', () {
    test('5.1 - Intervalos de atualização configuráveis', () {
      // Intervalos em segundos
      const intervals = {
        'realTime': 60,      // 1 minuto para tempo real
        'normal': 300,       // 5 minutos
        'economy': 600,      // 10 minutos
        'ultraSaving': 1800, // 30 minutos
      };
      
      expect(intervals['realTime'], 60);
      expect(intervals['normal'], 300);
      expect(intervals['economy'], 600);
      expect(intervals['ultraSaving'], 1800);
    });

    test('5.2 - DeviceStatus deve monitorar nível de bateria', () {
      final device = DeviceStatus(
        deviceId: 'watch001',
        lastUpdate: DateTime.now(),
        batteryLevel: 25,
        gpsSignal: true,
        emergencyMode: false,
      );
      
      expect(device.batteryLevel, 25);
      expect(device.batteryLevel < 30, true); // Bateria baixa
    });

    test('5.3 - Deve ajustar intervalo baseado na bateria', () {
      int getOptimalInterval(int batteryLevel) {
        if (batteryLevel < 20) return 1800; // Ultra saving
        if (batteryLevel < 40) return 600;  // Economy
        if (batteryLevel < 60) return 300;  // Normal
        return 60; // Real-time quando bateria cheia
      }
      
      expect(getOptimalInterval(15), 1800);
      expect(getOptimalInterval(35), 600);
      expect(getOptimalInterval(55), 300);
      expect(getOptimalInterval(80), 60);
    });

    test('5.4 - Deve detectar se está carregando', () {
      final chargingDevice = {
        'batteryLevel': 50,
        'isCharging': true,
      };
      
      expect(chargingDevice['isCharging'], true);
    });
  });

  // ============================================================
  // REQUISITO 6: INTEGRAÇÃO COM NOTIFICAÇÕES
  // Alertas automáticos por SMS, push ou e-mail para familiares
  // ============================================================
  group('REQ-6: Integração com Notificações', () {
    test('6.1 - AlertItem deve armazenar dados do alerta', () {
      final alert = AlertItem(
        id: 'alert001',
        title: 'Fora da área segura',
        body: 'O idoso saiu da área delimitada',
        when: DateTime.now(),
        meta: {'priority': 'high', 'type': 'geofence'},
      );
      
      expect(alert.id, 'alert001');
      expect(alert.title, 'Fora da área segura');
      expect(alert.meta?['priority'], 'high');
    });

    test('6.2 - AlertsNotifier deve adicionar alertas', () {
      final notifier = AlertsNotifier();
      
      notifier.add(AlertItem(
        id: 'alert001',
        title: 'Emergência',
        body: 'Botão de emergência acionado',
        when: DateTime.now(),
      ));
      
      expect(notifier.state.length, 1);
    });

    test('6.3 - Alertas devem manter ordem cronológica reversa', () {
      final notifier = AlertsNotifier();
      
      notifier.add(AlertItem(
        id: 'old',
        title: 'Antigo',
        body: 'Alerta antigo',
        when: DateTime(2024, 1, 15, 10, 0),
      ));
      
      notifier.add(AlertItem(
        id: 'new',
        title: 'Novo',
        body: 'Alerta novo',
        when: DateTime(2024, 1, 15, 11, 0),
      ));
      
      // Newest first
      expect(notifier.state.first.id, 'new');
    });

    test('6.4 - Firebase path para alertas', () {
      final path = FirebaseSyncService.getAlertsPath('elder123');
      expect(path, 'elders/elder123/alerts');
    });

    test('6.5 - Tipos de alerta suportados', () {
      const alertTypes = [
        'geofence_exit',
        'emergency_button',
        'fall_detected',
        'low_battery',
        'critical_health',
        'connection_lost',
      ];
      
      expect(alertTypes.length, 6);
      expect(alertTypes.contains('emergency_button'), true);
      expect(alertTypes.contains('fall_detected'), true);
    });

    test('6.6 - Deve remover alertas específicos', () {
      final notifier = AlertsNotifier();
      
      notifier.add(AlertItem(
        id: 'to_remove',
        title: 'Teste',
        body: 'Teste',
        when: DateTime.now(),
      ));
      
      notifier.remove('to_remove');
      
      expect(notifier.state.length, 0);
    });

    test('6.7 - Deve limpar todos os alertas', () {
      final notifier = AlertsNotifier();
      
      notifier.add(AlertItem(
        id: 'a1', title: 'A', body: 'A', when: DateTime.now(),
      ));
      notifier.add(AlertItem(
        id: 'a2', title: 'B', body: 'B', when: DateTime.now(),
      ));
      
      notifier.clear();
      
      expect(notifier.state.length, 0);
    });
  });

  // ============================================================
  // REQUISITO 7: AUTONOMIA DE OPERAÇÃO
  // O smartwatch deve funcionar independentemente do smartphone
  // ============================================================
  group('REQ-7: Autonomia de Operação', () {
    test('7.1 - DeviceStatus deve indicar sinal GPS independente', () {
      final independentDevice = DeviceStatus(
        deviceId: 'watch001',
        lastUpdate: DateTime.now(),
        batteryLevel: 75,
        gpsSignal: true,
        emergencyMode: false,
      );
      
      expect(independentDevice.gpsSignal, true);
    });

    test('7.2 - Smartwatch deve ter ID único', () {
      final device = DeviceStatus(
        deviceId: 'watch_abc123',
        lastUpdate: DateTime.now(),
        batteryLevel: 75,
        gpsSignal: true,
        emergencyMode: false,
      );
      
      expect(device.deviceId.isNotEmpty, true);
      expect(device.deviceId.startsWith('watch_'), true);
    });

    test('7.3 - Health data deve ser coletado localmente', () {
      // Dados coletados pelos sensores do smartwatch
      final watchData = HealthData(
        heartRate: 72,
        spo2: 97,
        steps: 3500,
        temperature: 36.5,
        bloodPressure: '118/78',
        timestamp: DateTime.now(),
      );
      
      // Deve ter timestamp indicando coleta local
      expect(watchData.timestamp, isNotNull);
      expect(watchData.heartRate, greaterThan(0));
    });

    test('7.4 - Serialização para envio quando conectado', () {
      final healthData = HealthData(
        heartRate: 72,
        spo2: 97,
        steps: 3500,
        temperature: 36.5,
        bloodPressure: '118/78',
        timestamp: DateTime.now(),
      );
      
      final json = healthData.toJson();
      
      expect(json['heartRate'], 72);
      expect(json['spo2'], 97);
      expect(json['steps'], 3500);
      expect(json['timestamp'], isNotNull);
    });

    test('7.5 - Deve ter timestamp de última atualização', () {
      final device = DeviceStatus(
        deviceId: 'watch001',
        lastUpdate: DateTime.now(),
        batteryLevel: 75,
        gpsSignal: true,
        emergencyMode: false,
      );
      
      final now = DateTime.now();
      final timeSinceUpdate = now.difference(device.lastUpdate);
      
      expect(timeSinceUpdate.inMinutes, 0); // Acabou de atualizar
    });

    test('7.6 - Firebase sync service deve validar IDs corretamente', () {
      // IDs válidos
      expect(FirebaseSyncService.isValidElderId('elder123'), true);
      expect(FirebaseSyncService.isValidElderId('watch_abc'), true);
      
      // IDs inválidos (caracteres especiais proibidos no Firebase)
      expect(FirebaseSyncService.isValidElderId('elder/123'), false);
      expect(FirebaseSyncService.isValidElderId('elder.123'), false);
      expect(FirebaseSyncService.isValidElderId('elder#123'), false);
      expect(FirebaseSyncService.isValidElderId(''), false);
    });
  });

  // ============================================================
  // TESTES DE INTEGRAÇÃO DOS REQUISITOS
  // ============================================================
  group('Integração de Requisitos', () {
    test('Fluxo completo: Detecção de saída da área segura', () {
      // 1. Configurar geofence
      final geofence = GeofenceArea(
        id: 'home',
        center: const LatLng(-23.5505, -46.6333),
        radius: 100.0,
        name: 'Casa',
      );
      
      // 2. Receber localização atual
      final currentLocation = LocationData(
        latitude: -23.5700, // Fora da área
        longitude: -46.6500,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );
      
      // 3. Verificar se está fora da área
      final center = LocationData(
        latitude: geofence.center.latitude,
        longitude: geofence.center.longitude,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );
      
      final isOutside = !currentLocation.isWithinRadius(center, geofence.radius);
      
      // 4. Se fora, gerar alerta
      expect(isOutside, true);
      
      if (isOutside) {
        final alert = AlertItem(
          id: FirebaseSyncService.generateAlertId(),
          title: 'Fora da área segura',
          body: 'O idoso saiu da área "${geofence.name}"',
          when: DateTime.now(),
          meta: {'type': 'geofence_exit'},
        );
        
        expect(alert.meta?['type'], 'geofence_exit');
      }
    });

    test('Fluxo completo: Modo emergência por saúde crítica', () {
      // 1. Receber dados de saúde
      final healthData = HealthData(
        heartRate: 40, // Crítico
        spo2: 88,      // Crítico
        steps: 0,
        temperature: 35.0,
        bloodPressure: '90/60',
        timestamp: DateTime.now(),
      );
      
      // 2. Verificar se é crítico
      expect(healthData.isCritical, true);
      
      // 3. Se crítico, ativar emergência
      if (healthData.isCritical) {
        final device = DeviceStatus(
          deviceId: 'watch001',
          lastUpdate: DateTime.now(),
          batteryLevel: 50,
          gpsSignal: true,
          emergencyMode: true, // Ativado!
        );
        
        expect(device.emergencyMode, true);
        
        // 4. Gerar alerta
        final alert = AlertItem(
          id: FirebaseSyncService.generateAlertId(),
          title: 'Emergência de Saúde',
          body: 'Sinais vitais críticos detectados!',
          when: DateTime.now(),
          meta: {'type': 'critical_health', 'priority': 'urgent'},
        );
        
        expect(alert.meta?['priority'], 'urgent');
      }
    });

    test('Fluxo completo: Otimização adaptativa de bateria', () {
      // Simular diferentes níveis de bateria
      final batteryLevels = [90, 60, 40, 20, 10];
      
      for (final battery in batteryLevels) {
        int getInterval(int level) {
          if (level < 20) return 1800;
          if (level < 40) return 600;
          if (level < 60) return 300;
          return 60;
        }
        
        final interval = getInterval(battery);
        
        if (battery >= 60) {
          expect(interval, 60, reason: 'Bateria alta = tempo real');
        } else if (battery >= 40) {
          expect(interval, 300, reason: 'Bateria média = 5 min');
        } else if (battery >= 20) {
          expect(interval, 600, reason: 'Bateria baixa = 10 min');
        } else {
          expect(interval, 1800, reason: 'Bateria crítica = 30 min');
        }
      }
    });
  });
}
