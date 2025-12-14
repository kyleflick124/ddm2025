import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_sync_service.dart';

/// State class for managing caregiver and elder data
class ElderState {
  final String? caregiverId;
  final String? activeElderId;
  final List<Map<String, dynamic>> elders;
  final bool isLoading;

  const ElderState({
    this.caregiverId,
    this.activeElderId,
    this.elders = const [],
    this.isLoading = false,
  });

  ElderState copyWith({
    String? caregiverId,
    String? activeElderId,
    List<Map<String, dynamic>>? elders,
    bool? isLoading,
  }) {
    return ElderState(
      caregiverId: caregiverId ?? this.caregiverId,
      activeElderId: activeElderId ?? this.activeElderId,
      elders: elders ?? this.elders,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Get the active elder's data
  Map<String, dynamic>? get activeElder {
    if (activeElderId == null) return null;
    try {
      return elders.firstWhere((e) => e['id'] == activeElderId);
    } catch (_) {
      return null;
    }
  }
}

/// Notifier for managing elder state
class ElderNotifier extends StateNotifier<ElderState> {
  final FirebaseSyncService _syncService;
  StreamSubscription? _eldersSubscription;
  StreamSubscription? _activeElderSubscription;

  ElderNotifier(this._syncService) : super(const ElderState()) {
    _loadCaregiverId();
  }

  Future<void> _loadCaregiverId() async {
    final prefs = await SharedPreferences.getInstance();
    final caregiverId = prefs.getString('caregiver_id');
    
    if (caregiverId != null) {
      state = state.copyWith(caregiverId: caregiverId);
      await loadElders();
    }
  }

  /// Set the caregiver ID and load their elders
  Future<void> setCaregiverId(String caregiverId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('caregiver_id', caregiverId);
    
    state = state.copyWith(caregiverId: caregiverId, isLoading: true);
    await loadElders();
  }

  /// Load elders for the current caregiver
  Future<void> loadElders() async {
    if (state.caregiverId == null) return;

    state = state.copyWith(isLoading: true);

    try {
      // Get elders list
      final elders = await _syncService.getCaregiverElders(state.caregiverId!);
      
      // Get active elder
      final activeElderId = await _syncService.getActiveElder(state.caregiverId!);

      state = state.copyWith(
        elders: elders,
        activeElderId: activeElderId,
        isLoading: false,
      );

      // Start listening for changes
      _startListening();
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void _startListening() {
    if (state.caregiverId == null) return;

    // Listen to elders list changes
    _eldersSubscription?.cancel();
    _eldersSubscription = _syncService
        .listenToCaregiverElders(state.caregiverId!)
        .listen((elders) {
      state = state.copyWith(elders: elders);
    });

    // Listen to active elder changes
    _activeElderSubscription?.cancel();
    _activeElderSubscription = _syncService
        .listenToActiveElder(state.caregiverId!)
        .listen((activeElderId) {
      state = state.copyWith(activeElderId: activeElderId);
    });
  }

  /// Register a new elder
  Future<String?> registerElder({
    required String name,
    required String age,
    String? phone,
    String? email,
    String? medicalCondition,
  }) async {
    if (state.caregiverId == null) return null;

    try {
      final elderId = await _syncService.registerElder(
        caregiverId: state.caregiverId!,
        name: name,
        age: age,
        phone: phone,
        email: email,
        medicalCondition: medicalCondition,
      );

      await loadElders();
      return elderId;
    } catch (e) {
      return null;
    }
  }

  /// Set active elder
  Future<void> setActiveElder(String elderId) async {
    if (state.caregiverId == null) return;

    await _syncService.setActiveElder(state.caregiverId!, elderId);
    state = state.copyWith(activeElderId: elderId);

    // Save to local storage for quick access
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_elder_id', elderId);
  }

  /// Remove elder from caregiver's list
  Future<void> removeElder(String elderId) async {
    if (state.caregiverId == null) return;

    await _syncService.unlinkElderFromCaregiver(state.caregiverId!, elderId);
    await loadElders();

    // If removed elder was active, set first available as active
    if (state.activeElderId == elderId && state.elders.isNotEmpty) {
      await setActiveElder(state.elders.first['id']);
    }
  }

  @override
  void dispose() {
    _eldersSubscription?.cancel();
    _activeElderSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for elder state
final elderProvider = StateNotifierProvider<ElderNotifier, ElderState>((ref) {
  return ElderNotifier(FirebaseSyncService());
});

/// Convenience provider for active elder ID
final activeElderIdProvider = Provider<String?>((ref) {
  return ref.watch(elderProvider).activeElderId;
});

/// Convenience provider for active elder data
final activeElderProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(elderProvider).activeElder;
});
