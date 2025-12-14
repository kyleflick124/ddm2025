# 🧓 Elder Monitor - Sistema de Localização Inteligente para Smartwatches

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Realtime-orange.svg)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**Sistema inteligente de monitoramento de idosos** desenvolvido para a disciplina DDM2025 - UFSCar Sorocaba.

> Solução completa com app para cuidadores e app Wear OS para smartwatch, oferecendo rastreamento GPS em tempo real, alertas de emergência e monitoramento de saúde.

---

## 📱 Visão Geral

O Elder Monitor é composto por **duas aplicações**:

| App | Descrição | Plataforma |
|-----|-----------|------------|
| **Elder Monitor** | App para cuidadores/familiares | Android, iOS, Web |
| **Elder Watch** | App para smartwatch do idoso | Wear OS |

---

## ✨ Funcionalidades

### 📍 Rastreamento GPS
- Localização em tempo real
- Histórico de trajeto no mapa
- Intervalos configuráveis (1, 5, 10, 30 min)
- Otimização automática baseada na bateria

### 🗺️ Geofencing (Áreas Seguras)
- Definição de zonas seguras
- Alertas quando sai da área
- Raio ajustável
- Múltiplas zonas por idoso

### 🚨 Modo de Emergência
- Botão SOS no smartwatch
- Detecção automática de quedas
- Alertas de saúde crítica
- Rastreamento contínuo em emergências

### ❤️ Monitoramento de Saúde
- Frequência cardíaca (bpm)
- Saturação de oxigênio (SpO2)
- Contagem de passos
- Temperatura corporal
- Detecção de condições críticas

### 🌍 Multi-idioma
- 🇧🇷 Português
- 🇺🇸 English
- 🇪🇸 Español
- 🇫🇷 Français
- 🇨🇳 中文

---

## 🚀 Como Usar

### Pré-requisitos

```bash
# Flutter SDK 3.x+
flutter --version

# Verificar ambiente
flutter doctor
```

### Instalação

```bash
# 1. Clone o repositório
git clone https://github.com/kyleflick124/ddm2025.git
cd ddm2025

# 2. Instale dependências
flutter pub get

# 3. Execute o app (modo debug)
flutter run
```

### Executar no Emulador

```bash
# Android
flutter run -d android

# iOS (apenas macOS)
flutter run -d ios

# Web
flutter run -d chrome
```

---

## ⌚ App Wear OS (Smartwatch)

```bash
# Navegue para o módulo do smartwatch
cd elder_watch

# Instale dependências
flutter pub get

# Execute no emulador Wear OS
flutter run -d <wear_emulator_id>

# Listar dispositivos disponíveis
flutter devices
```

### Funcionalidades do Watch
- Exibição de batimentos cardíacos
- Contador de passos
- Botão SOS (pressão longa)
- Sincronização automática a cada 30s

---

## 🔥 Configuração do Firebase

O projeto já está configurado com Firebase. Para usar seu próprio projeto:

### 1. Criar projeto no Firebase Console

1. Acesse [Firebase Console](https://console.firebase.google.com)
2. Crie um novo projeto
3. Ative **Realtime Database** e **Authentication**

### 2. Configurar FlutterFire

```bash
# Instalar FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurar seu projeto
flutterfire configure
```

### 3. Estrutura do Realtime Database

```json
{
  "elders": {
    "elder_id": {
      "health": {
        "heartRate": 72,
        "spo2": 98,
        "steps": 5000,
        "temperature": 36.5,
        "bloodPressure": "120/80",
        "timestamp": "2024-01-15T10:30:00Z"
      },
      "location": {
        "latitude": -23.5505,
        "longitude": -46.6333,
        "accuracy": 10.0,
        "timestamp": "2024-01-15T10:30:00Z"
      },
      "device": {
        "batteryLevel": 78,
        "isCharging": false,
        "lastSync": "2024-01-15T10:30:00Z"
      },
      "alerts": {},
      "geofences": {}
    }
  }
}
```

### 4. Regras de Segurança

```json
{
  "rules": {
    "elders": {
      "$elderId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    }
  }
}
```

---

## 🗺️ Google Maps API

### Android

A chave já está configurada em `android/app/src/main/AndroidManifest.xml`.

Para usar sua própria chave:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="SUA_CHAVE_AQUI"/>
```

### Obter Chave API

1. Acesse [Google Cloud Console](https://console.cloud.google.com)
2. Crie um projeto ou selecione existente
3. Ative "Maps SDK for Android" e "Maps SDK for iOS"
4. Crie credenciais → Chave de API
5. (Opcional) Restrinja a chave ao seu app

---

## 🧪 Testes

### Executar Todos os Testes

```bash
flutter test
```

### Testes Específicos

```bash
# Requisitos RFP
flutter test test/rfp_requirements_test.dart

# Features completas
flutter test test/comprehensive_features_test.dart

# Firebase
flutter test test/firebase_integration_test.dart

# Sensores do smartwatch
flutter test test/smartwatch_sensors_test.dart

# Widgets/UI
flutter test test/widgets/
```

### Cobertura de Testes

| Categoria | Testes |
|-----------|--------|
| Requisitos RFP | 39 |
| Features Completas | 61 |
| Firebase | 15 |
| Sensores Smartwatch | 27 |
| Widgets UI | 17 |
| Modelos | 18 |
| Providers | 49 |
| **Total** | **242** |

---

## 📁 Estrutura do Projeto

```
ddm2025/
├── lib/
│   ├── main.dart              # Entrada principal
│   ├── models/                # Modelos de dados
│   │   ├── health_data.dart
│   │   └── location_data.dart
│   ├── providers/             # Estado (Riverpod)
│   │   ├── locale_provider.dart
│   │   ├── theme_provider.dart
│   │   ├── alerts_provider.dart
│   │   ├── geofence_provider.dart
│   │   └── device_providers.dart
│   ├── screens/               # Telas do app
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── map_screen.dart
│   │   ├── alerts_screen.dart
│   │   ├── device_screen.dart
│   │   ├── profile_screen.dart
│   │   └── settings_screen.dart
│   └── services/              # Serviços
│       ├── firebase_sync_service.dart
│       └── translation_service.dart
├── elder_watch/               # App Wear OS
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   └── services/
│   └── pubspec.yaml
├── test/                      # Testes
└── pubspec.yaml
```

---

## 🛣️ Rotas da Aplicação

| Rota | Tela | Descrição |
|------|------|-----------|
| `/splash` | SplashScreen | Tela inicial |
| `/login` | LoginScreen | Autenticação |
| `/home` | HomeScreen | Menu principal |
| `/dashboard` | DashboardScreen | Indicadores de saúde |
| `/map` | MapScreen | Mapa com localização |
| `/alerts` | AlertsScreen | Lista de alertas |
| `/device` | DeviceScreen | Status do smartwatch |
| `/profile` | ProfileScreen | Perfil do idoso |
| `/settings` | SettingsScreen | Configurações |

---

## 👥 Equipe

- Felipe Rodrigues Bastos - RA: 815406
- Fernando Favareto Abromovick - RA: 792178
- Maurício Marques da Silva Junior - RA: 771053

**Professor**: José Guimarães  
**Disciplina**: DDM2025  
**Instituição**: UFSCar - Campus Sorocaba

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja [LICENSE](LICENSE) para mais detalhes.

---

## 🤝 Contribuindo

1. Fork o projeto
2. Crie sua branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Add: nova feature'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

---

<p align="center">
  <b>Elder Monitor</b> - Cuidando de quem você ama 💙
</p>
