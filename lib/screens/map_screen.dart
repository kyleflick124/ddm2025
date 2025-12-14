import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_data.dart';
import '../services/firebase_sync_service.dart';
import '../providers/geofence_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/elder_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(-23.5505, -46.6333); // São Paulo default
  final List<LatLng> _locationHistory = [];
  bool _isLoading = true;
  bool _isOutOfBounds = false;
  Timer? _updateTimer;
  StreamSubscription? _locationSubscription;
  
  // Elder ID from provider (dynamic based on selection)
  String get _elderId => ref.read(activeElderIdProvider) ?? 'elder_demo';
  
  // Firebase sync service
  final FirebaseSyncService _syncService = FirebaseSyncService();
  
  // Safe zone settings
  double _safeRadius = 100.0; // meters
  LatLng? _safeCenter;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _subscribeToLocationUpdates();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      // Get current position (for initial map center)
      if (permission == LocationPermission.whileInUse || 
          permission == LocationPermission.always) {
        try {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
            _safeCenter = _currentPosition;
            _locationHistory.add(_currentPosition);
            _isLoading = false;
          });
        } catch (e) {
          // Location service might be disabled
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _subscribeToLocationUpdates() {
    // Listen to location updates from Firebase (from smartwatch)
    _locationSubscription = _syncService
        .listenToLocation(_elderId)
        .listen((locationData) {
      if (locationData != null) {
        final newPosition = LatLng(locationData.latitude, locationData.longitude);
        _updatePosition(newPosition);
      }
    });
  }

  void _updatePosition(LatLng newPosition) {
    setState(() {
      _currentPosition = newPosition;
      _locationHistory.add(newPosition);
      if (_locationHistory.length > 50) {
        _locationHistory.removeAt(0);
      }
      
      // Check if outside safe zone
      if (_safeCenter != null) {
        final distance = _calculateDistance(_currentPosition, _safeCenter!);
        _isOutOfBounds = distance > _safeRadius;
      }
    });

    // Move camera to new position
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(newPosition),
    );
  }

  double _calculateDistance(LatLng p1, LatLng p2) {
    return Geolocator.distanceBetween(
      p1.latitude, p1.longitude,
      p2.latitude, p2.longitude,
    );
  }

  Set<Circle> _buildCircles() {
    final circles = <Circle>{};
    
    // Safe zone circle
    if (_safeCenter != null) {
      circles.add(Circle(
        circleId: const CircleId('safe_zone'),
        center: _safeCenter!,
        radius: _safeRadius,
        fillColor: _isOutOfBounds 
            ? Colors.red.withOpacity(0.15)
            : Colors.green.withOpacity(0.15),
        strokeColor: _isOutOfBounds ? Colors.red : Colors.green,
        strokeWidth: 2,
      ));
    }
    
    // Add geofences from provider
    final geofences = ref.read(geofenceProvider);
    for (final geofence in geofences) {
      circles.add(Circle(
        circleId: CircleId(geofence.id),
        center: geofence.center,
        radius: geofence.radius,
        fillColor: Colors.blue.withOpacity(0.1),
        strokeColor: Colors.blue,
        strokeWidth: 1,
      ));
    }
    
    return circles;
  }

  Set<Polyline> _buildPolylines() {
    if (_locationHistory.length < 2) return {};
    
    return {
      Polyline(
        polylineId: const PolylineId('trail'),
        points: _locationHistory,
        color: Colors.blueAccent,
        width: 3,
      ),
    };
  }

  Set<Marker> _buildMarkers() {
    return {
      Marker(
        markerId: const MarkerId('elder_position'),
        position: _currentPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(title: 'Localização do Idoso'),
      ),
    };
  }

  void _clearTrail() {
    setState(() {
      _locationHistory.clear();
      _locationHistory.add(_currentPosition);
    });
  }

  void _setSafeZone() {
    setState(() {
      _safeCenter = _currentPosition;
      _isOutOfBounds = false;
    });
    
    // Save to Firebase
    _syncService.saveGeofence(
      _elderId,
      'safe_zone',
      _currentPosition.latitude,
      _currentPosition.longitude,
      _safeRadius,
      'Área Segura',
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: TranslatedText('Área segura definida na posição atual!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const TranslatedText('Localização em Tempo Real'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Definir área segura aqui',
            onPressed: _setSafeZone,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Limpar trilha',
            onPressed: _clearTrail,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 16,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  circles: _buildCircles(),
                  polylines: _buildPolylines(),
                  markers: _buildMarkers(),
                ),

          // Warning banner when outside safe zone
          if (_isOutOfBounds)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: TranslatedText(
                        'Fora da área segura!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Safe zone radius slider
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const TranslatedText(
                          'Raio da área segura:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        TranslatedText(
                          '${_safeRadius.toInt()} m',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _safeRadius,
                      min: 20,
                      max: 500,
                      divisions: 48,
                      label: '${_safeRadius.toInt()} m',
                      onChanged: (val) {
                        setState(() {
                          _safeRadius = val;
                          if (_safeCenter != null) {
                            final distance =
                                _calculateDistance(_currentPosition, _safeCenter!);
                            _isOutOfBounds = distance > _safeRadius;
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
