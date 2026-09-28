import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';
import '../core/api/production_api.dart';
import '../core/api/api_exceptions.dart';
import '../models/offline_log.dart';
import '../providers/production_provider.dart';

class SyncService {
  final CacheService _cache;
  final ProductionApiService _productionApi;
  final ConnectivityService _connectivity;
  bool _isSyncing = false;

  SyncService(this._cache, this._productionApi, this._connectivity);

  bool get isSyncing => _isSyncing;

  Future<void> syncOfflineQueue() async {
    if (_isSyncing) return;
    
    final isOnline = await _connectivity.checkConnection();
    if (!isOnline) return;

    _isSyncing = true;
    
    try {
      final queue = _cache.getOfflineQueue();
      if (queue.isEmpty) return;

      for (final log in queue) {
        if (!_isSyncing) break;
        
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
        } on ValidationException catch (e) {
          // Don't retry validation errors - remove from queue
          await _cache.removeFromOfflineQueue(log.id);
        } on ApiException catch (e) {
          // Increment retry count
          log.retryCount++;
          log.lastAttemptAt = DateTime.now();
          log.lastError = e.message;
          await _cache.updateOfflineLog(log);
          
          // If max retries reached, could move to dead letter queue
          if (log.retryCount >= 5) {
            // Optionally log for manual review
          }
        }
      }
      
      await _cache.setLastSync(DateTime.now());
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> startPeriodicSync({Duration interval = const Duration(minutes: 5)}) async {
    Timer.periodic(interval, (_) async {
      if (!_isSyncing) {
        await syncOfflineQueue();
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

  Future<void> syncLogs({String? shift, String? stageId, DateTime? date}) async {
    final isOnline = await _connectivity.checkConnection();
    if (!isOnline) return;

    try {
      final logs = await _productionApi.getLogs(shift: shift, stageId: stageId, date: date);
      await _cache.cacheLogs(logs);
    } catch (_) {
      // Silently fail for background sync
    }
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  final api = ref.watch(productionApiProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  return SyncService(cache, api, connectivity);
});