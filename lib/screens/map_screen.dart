import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Offset _position = const Offset(150, 150);
  final List<Offset> _path = [];
  Timer? _timer;
  Timer? _progressTimer;
  int _interval = 5;
  double _progress = 0.0;
  final Random _random = Random();

  static const double _iconSize = 36;
  static const double _safeRadius = 30.0;
  late Offset _safeCenter;
  bool _isOutOfBounds = false;
  bool _alertTriggered = false; // evita alertas repetidos

  // 🔔 Cria um novo alerta na lista de alertas
  Future<void> _createAlert(String title) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('alerts');
    List<Map<String, dynamic>> alerts = [];

    if (stored != null) {
      alerts = List<Map<String, dynamic>>.from(jsonDecode(stored));
    }

    alerts.insert(0, {
      'title': title,
      'time': 'Agora',
      'read': false,
    });

    await prefs.setString('alerts', jsonEncode(alerts));
  }

  void _updatePosition() async {
    final dx = (_random.nextDouble() * 20 - 10);
    final dy = (_random.nextDouble() * 20 - 10);
    final newPos = Offset(
      (_position.dx + dx).clamp(20, 280),
      (_position.dy + dy).clamp(20, 280),
    );

    final newPoint = newPos + const Offset(_iconSize / 2, _iconSize);
    final distance = (newPoint - _safeCenter).distance;

    setState(() {
      _position = newPos;
      _path.add(newPoint);
      if (_path.length > 20) _path.removeAt(0);

      final isOut = distance > _safeRadius;

      // Só dispara alerta se acabou de sair da área segura
      if (isOut && !_isOutOfBounds && !_alertTriggered) {
        _alertTriggered = true;
        _createAlert('Fora da área segura');
      }

      _isOutOfBounds = isOut;

      // Reseta o estado de alerta quando volta à área segura
      if (!isOut) _alertTriggered = false;
    });

    // Save position to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('map_position_x', newPos.dx);
    await prefs.setDouble('map_position_y', newPos.dy);
  }

  void _startSimulation() {
    _timer?.cancel();
    _progressTimer?.cancel();
    _progress = 0.0;

    _timer = Timer.periodic(Duration(seconds: _interval), (_) {
      _updatePosition();
      _progress = 0.0;
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _progress += 0.1 / _interval;
        if (_progress > 1.0) _progress = 1.0;
      });
    });
  }

  void _clearTrail() {
    setState(() {
      _path.clear();
      _path.add(_position + const Offset(_iconSize / 2, _iconSize));
    });
  }

  @override
  void initState() {
    super.initState();
    _loadMapState();
  }

  Future<void> _loadMapState() async {
    final prefs = await SharedPreferences.getInstance();

    final savedX = prefs.getDouble('map_position_x');
    final savedY = prefs.getDouble('map_position_y');
    final savedInterval = prefs.getInt('map_interval');

    setState(() {
      if (savedX != null && savedY != null) {
        _position = Offset(savedX, savedY);
      }
      if (savedInterval != null) {
        _interval = savedInterval;
      }
      _safeCenter = _position + const Offset(_iconSize / 2, _iconSize);
      _path.add(_safeCenter);
    });

    _startSimulation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Localização em Tempo Real'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // mapa
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 320,
                      height: 320,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        border:
                            Border.all(color: Colors.grey.shade600, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomPaint(
                        painter: _MapPainter(
                          path: _path,
                          safeCenter: _safeCenter,
                          safeRadius: _safeRadius,
                          isOutOfBounds: _isOutOfBounds,
                        ),
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 500),
                              left: _position.dx,
                              top: _position.dy,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.redAccent,
                                size: _iconSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // botão limpar trilha
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: ElevatedButton.icon(
                        onPressed: _clearTrail,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Limpar trilha'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),

                    // aviso visual
                    if (_isOutOfBounds)
                      Positioned(
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Fora da área segura!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // progresso
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Próxima atualização em ${(_interval * (1 - _progress)).toStringAsFixed(1)} s',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey.shade300,
                  color: Colors.lightBlueAccent,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // selecionador de tempo
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Atualizar a cada: ',
                        style: TextStyle(fontSize: 16)),
                    DropdownButton<int>(
                      value: _interval,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 s')),
                        DropdownMenuItem(value: 3, child: Text('3 s')),
                        DropdownMenuItem(value: 5, child: Text('5 s')),
                        DropdownMenuItem(value: 10, child: Text('10 s')),
                      ],
                      onChanged: (val) async {
                        if (val != null) {
                          setState(() => _interval = val);
                          _startSimulation();

                          // Save interval to SharedPreferences
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setInt('map_interval', val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final List<Offset> path;
  final Offset safeCenter;
  final double safeRadius;
  final bool isOutOfBounds;

  _MapPainter({
    required this.path,
    required this.safeCenter,
    required this.safeRadius,
    required this.isOutOfBounds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // área segura
    final safePaint = Paint()
      ..color = (isOutOfBounds
          ? Colors.redAccent.withOpacity(0.15)
          : Colors.greenAccent.withOpacity(0.15))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(safeCenter, safeRadius, safePaint);

    final safeBorder = Paint()
      ..color = isOutOfBounds ? Colors.redAccent : Colors.green
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(safeCenter, safeRadius, safeBorder);

    // trilha
    if (path.length < 2) return;
    final trail = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final trailPath = Path()..moveTo(path.first.dx, path.first.dy);
    for (var i = 1; i < path.length; i++) {
      trailPath.lineTo(path[i].dx, path[i].dy);
    }
    canvas.drawPath(trailPath, trail);
  }

  @override
  bool shouldRepaint(_MapPainter oldDelegate) => true;
}
