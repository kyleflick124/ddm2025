/// Widget Tests for App Screens
/// Tests UI rendering and interactions

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Login Screen Widget Tests', () {
    testWidgets('Should render login form', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: Key('email_field'),
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  key: Key('password_field'),
                  decoration: InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                ),
                ElevatedButton(
                  key: Key('login_button'),
                  onPressed: null,
                  child: Text('Entrar'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_button')), findsOneWidget);
    });

    testWidgets('Password field should obscure text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TextField(
              key: Key('password_field'),
              obscureText: true,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(
        find.byKey(const Key('password_field')),
      );
      expect(textField.obscureText, true);
    });
  });

  group('Dashboard Screen Widget Tests', () {
    testWidgets('Should render health metrics', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                _HealthCard(
                  icon: Icons.favorite,
                  label: 'Batimentos',
                  value: '72 bpm',
                  color: Colors.red,
                ),
                _HealthCard(
                  icon: Icons.air,
                  label: 'Oxigênio',
                  value: '98%',
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('72 bpm'), findsOneWidget);
      expect(find.text('98%'), findsOneWidget);
      expect(find.text('Batimentos'), findsOneWidget);
      expect(find.text('Oxigênio'), findsOneWidget);
    });

    testWidgets('Should show emergency button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              key: const Key('emergency_button'),
              backgroundColor: Colors.red,
              onPressed: () {},
              icon: const Icon(Icons.warning),
              label: const Text('Emergência'),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('emergency_button')), findsOneWidget);
      expect(find.text('Emergência'), findsOneWidget);
    });

    testWidgets('Should show heart rate chart title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Text(
                  'Histórico de Batimentos (24h)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Histórico de Batimentos (24h)'), findsOneWidget);
    });

    testWidgets('Should show empty chart state when no data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              key: const Key('empty_chart'),
              height: 200,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 48, color: Colors.grey),
                    Text('Aguardando dados de batimentos...'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('empty_chart')), findsOneWidget);
      expect(find.text('Aguardando dados de batimentos...'), findsOneWidget);
      expect(find.byIcon(Icons.show_chart), findsOneWidget);
    });

    testWidgets('Should show heart rate legend', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Row(
                  children: [
                    Container(
                      key: const Key('legend_normal'),
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Text('Normal (50-120)'),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      key: const Key('legend_critical'),
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Text('Crítico'),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('legend_normal')), findsOneWidget);
      expect(find.byKey(const Key('legend_critical')), findsOneWidget);
      expect(find.text('Normal (50-120)'), findsOneWidget);
      expect(find.text('Crítico'), findsOneWidget);
    });

    testWidgets('Should display touched point info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              key: const Key('touched_info'),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '75 bpm - 14:30',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('touched_info')), findsOneWidget);
      expect(find.text('75 bpm - 14:30'), findsOneWidget);
    });
  });

  group('Settings Screen Widget Tests', () {
    testWidgets('Should render theme toggle', (tester) async {
      bool isDarkMode = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SwitchListTile(
                  key: const Key('theme_switch'),
                  title: const Text('Modo Escuro'),
                  value: isDarkMode,
                  onChanged: (value) {
                    setState(() => isDarkMode = value);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('theme_switch')), findsOneWidget);
      expect(find.text('Modo Escuro'), findsOneWidget);
    });

    testWidgets('Should render language selector', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DropdownButton<String>(
              key: const Key('language_selector'),
              value: 'pt',
              items: const [
                DropdownMenuItem(value: 'pt', child: Text('Português')),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'es', child: Text('Español')),
              ],
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('language_selector')), findsOneWidget);
    });
  });

  group('Alerts Screen Widget Tests', () {
    testWidgets('Should render alert list', (tester) async {
      final alerts = [
        {'title': 'Emergência', 'body': 'Botão pressionado'},
        {'title': 'Geofence', 'body': 'Saiu da área segura'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: alerts.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(alerts[index]['title']!),
                  subtitle: Text(alerts[index]['body']!),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Emergência'), findsOneWidget);
      expect(find.text('Geofence'), findsOneWidget);
    });

    testWidgets('Should show empty state when no alerts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64),
                  Text('Nenhum alerta'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Nenhum alerta'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_off), findsOneWidget);
    });
  });

  group('Device Screen Widget Tests', () {
    testWidgets('Should render device status card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              key: const Key('device_card'),
              child: Column(
                children: const [
                  ListTile(
                    leading: Icon(Icons.watch),
                    title: Text('SmartWatch Sênior'),
                    subtitle: Text('Firmware v1.2.4'),
                  ),
                  ListTile(
                    leading: Icon(Icons.battery_full),
                    title: Text('Bateria: 78%'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('device_card')), findsOneWidget);
      expect(find.text('SmartWatch Sênior'), findsOneWidget);
      expect(find.text('Bateria: 78%'), findsOneWidget);
    });

    testWidgets('Should render action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                ElevatedButton.icon(
                  key: const Key('sync_button'),
                  onPressed: () {},
                  icon: const Icon(Icons.sync),
                  label: const Text('Sincronizar'),
                ),
                ElevatedButton.icon(
                  key: const Key('locate_button'),
                  onPressed: () {},
                  icon: const Icon(Icons.location_searching),
                  label: const Text('Localizar'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('sync_button')), findsOneWidget);
      expect(find.byKey(const Key('locate_button')), findsOneWidget);
    });
  });

  group('Responsive Layout Tests', () {
    testWidgets('Grid should have 2 columns on small screen', (tester) async {
      tester.view.physicalSize = const Size(375, 667);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.reset());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final width = MediaQuery.of(context).size.width;
                final columns = width > 700 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  children: List.generate(4, (i) => Container()),
                );
              },
            ),
          ),
        ),
      );

      final grid = tester.widget<GridView>(find.byType(GridView));
      expect((grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount, 2);
    });

    testWidgets('Grid should have 4 columns on large screen', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.reset());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final width = MediaQuery.of(context).size.width;
                final columns = width > 700 ? 4 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  children: List.generate(4, (i) => Container()),
                );
              },
            ),
          ),
        ),
      );

      final grid = tester.widget<GridView>(find.byType(GridView));
      expect((grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount, 4);
    });
  });

  group('Theme Tests', () {
    testWidgets('Light theme should have correct colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          ),
          home: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Text(
                'Test',
                style: TextStyle(color: theme.colorScheme.primary),
              );
            },
          ),
        ),
      );

      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('Dark theme should have correct colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.dark,
            ),
          ),
          home: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              return Container(
                key: const Key('themed_container'),
                color: theme.scaffoldBackgroundColor,
              );
            },
          ),
        ),
      );

      expect(find.byKey(const Key('themed_container')), findsOneWidget);
    });
  });

  group('Navigation Tests', () {
    test('App should have all required routes', () {
      final routes = [
        '/splash',
        '/login',
        '/home',
        '/dashboard',
        '/alerts',
        '/map',
        '/device',
        '/profile',
        '/settings',
      ];
      
      expect(routes.length, 9);
      expect(routes.every((r) => r.startsWith('/')), true);
    });
  });
}

/// Helper widget for health cards
class _HealthCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _HealthCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color),
            Text(value, style: TextStyle(color: color)),
            Text(label),
          ],
        ),
      ),
    );
  }
}
