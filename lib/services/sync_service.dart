import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_exceptions.dart';
import '../core/api/production_api.dart';
import '../models/production_log.dart';
import '../providers/production_provider.dart';
import 'cache_service.dart';
import 'connectivity_service.dart';

class SyncService {
  final CacheService _cache;
  final ProductionApiService _productionApi;
  final ConnectivityService _connectivity;
  bool _isSyncing = false;
  Timer? _periodicTimer;

  SyncService(this._cache, this._productionApi, this._connectivity);

  bool get isSyncing => _isSyncing;

  /// Flushes queued offline logs to the backend.
  ///
  /// Retry policy:
  ///  * 400/422 (bad payload) - the entry can never succeed, drop it.
  ///  * 401 - the session is the problem, not the entry: keep it queued and
  ///    stop hammering until the user signs in again.
  ///  * anything else (5xx, network) - keep it and retry later.
  Future<void> syncOfflineQueue() async {
    if (_isSyncing) return;

    final isOnline = await _connectivity.checkConnection();
    if (!isOnline) return;

    _isSyncing = true;

    try {
      final queue = await _cache.getOfflineQueue();
      if (queue.isEmpty) return;

      for (final log in queue) {
        try {
          await _productionApi.createLog(
            CreateLogRequest(
              stageId: log.stageId,
              quantity: log.quantity,
              unit: log.unit,
              shift: log.shift,
              notes: log.notes,
            ),
          );
          await _cache.removeFromOfflineQueue(log.id);
        } on BadRequestException {
          // Permanently invalid payload - keeping it would block the queue.
          await _cache.removeFromOfflineQueue(log.id);
        } on ValidationException {
          await _cache.removeFromOfflineQueue(log.id);
        } on UnauthorizedException {
          // Session expired mid-sync; leave the entry intact for after login.
          break;
        } on ApiException catch (e) {
          log.retryCount++;
          log.lastAttemptAt = DateTime.now();
          log.lastError = e.message;
          await _cache.updateOfflineLog(log);
        }
      }

      await _cache.setLastSync(DateTime.now());
    } finally {
      _isSyncing = false;
    }
  }

  /// Starts the periodic background flush.
  ///
  /// Calling this more than once cancels the previous timer instead of stacking
  /// another `Timer.periodic` (which would multiply network traffic).
  void startPeriodicSync({Duration interval = const Duration(minutes: 5)}) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) {
      if (!_isSyncing) {
        unawaited(syncOfflineQueue());
      }
    });
  }

  Future<void> syncStages() async {
    final isOnline = await _connectivity.checkConnection();
    if (!isOnline) return;

    try {
      final stages = await _productionApi.getStages();
      await _cache.cacheStages(stages);
    } catch (_) {
      // Silently fail for background sync
    }
  }

  Future<void> syncLogs({
    String? shift,
    String? stageId,
    DateTime? date,
  }) async {
    final isOnline = await _connectivity.checkConnection();
    if (!isOnline) return;

    try {
      final logs = await _productionApi.getLogs(
        shift: shift,
        stageId: stageId,
        date: date,
      );
      await _cache.cacheLogs(logs);
    } catch (_) {
      // Silently fail for background sync
    }
  }

  void dispose() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  unawaited(cache.ensureInitialized());
  final api = ref.watch(productionApiProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final service = SyncService(cache, api, connectivity);
  ref.onDispose(service.dispose);
  return service;
});
