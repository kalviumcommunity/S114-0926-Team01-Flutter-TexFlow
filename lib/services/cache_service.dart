import 'package:hive_flutter/hive_flutter.dart';

import '../models/production_log.dart';
import '../models/production_stage.dart';
import '../models/offline_log.dart';

class CacheService {
  static const String _stagesBoxName = 'cached_stages';
  static const String _logsBoxName = 'cached_logs';
  static const String _offlineQueueBoxName = 'offline_queue';
  static const String _lastSyncBoxName = 'last_sync';

  Box<ProductionStage>? _stagesBox;
  Box<ProductionLog>? _logsBox;
  Box<OfflineLog>? _offlineQueueBox;
  Box<DateTime>? _lastSyncBox;

  Future<void>? _initFuture;

  bool get isInitialized =>
      _stagesBox != null &&
      _logsBox != null &&
      _offlineQueueBox != null &&
      _lastSyncBox != null;

  Future<void> init() {
    return _initFuture ??= _init();
  }

  Future<void> _init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(ProductionStageAdapter().typeId)) {
      Hive.registerAdapter(ProductionStageAdapter());
    }
    if (!Hive.isAdapterRegistered(ProductionLogAdapter().typeId)) {
      Hive.registerAdapter(ProductionLogAdapter());
    }
    if (!Hive.isAdapterRegistered(OfflineLogAdapter().typeId)) {
      Hive.registerAdapter(OfflineLogAdapter());
    }

    _stagesBox = await Hive.openBox<ProductionStage>(_stagesBoxName);
    _logsBox = await Hive.openBox<ProductionLog>(_logsBoxName);
    _offlineQueueBox = await Hive.openBox<OfflineLog>(_offlineQueueBoxName);
    _lastSyncBox = await Hive.openBox<DateTime>(_lastSyncBoxName);
  }

  Future<void> ensureInitialized() => init();

  // Stages caching
  Future<void> cacheStages(List<ProductionStage> stages) async {
    final box = await _ready(() => _stagesBox);
    if (box == null) return;
    await box.clear();
    await box.putAll({for (final stage in stages) stage.id: stage});
  }

  Future<List<ProductionStage>> getCachedStages() async {
    final box = await _ready(() => _stagesBox);
    if (box == null) return [];
    return box.values.toList();
  }

  // Logs caching
  Future<void> cacheLogs(List<ProductionLog> logs) async {
    final box = await _ready(() => _logsBox);
    if (box == null) return;
    await box.clear();
    await box.putAll({for (final log in logs) log.id: log});
  }

  Future<List<ProductionLog>> getCachedLogs({
    String? shift,
    String? stageId,
    DateTime? date,
  }) async {
    final box = await _ready(() => _logsBox);
    if (box == null) return [];

    var logs = box.values.toList();

    if (shift != null) {
      logs = logs.where((l) => l.shift == shift).toList();
    }
    if (stageId != null) {
      logs = logs.where((l) => l.stageId == stageId).toList();
    }
    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      logs = logs
          .where((l) => !l.logTime.isBefore(start) && l.logTime.isBefore(end))
          .toList();
    }

    logs.sort((a, b) => b.logTime.compareTo(a.logTime));
    return logs;
  }

  // Offline queue management

  /// Returns `true` only when the entry was durably persisted.
  ///
  /// Previously this returned `void` and silently no-op'd when Hive failed to
  /// initialise, so the UI reported a successful offline save while the log was
  /// lost. Callers must surface a `false` result to the user.
  Future<bool> addToOfflineQueue(OfflineLog log) async {
    final box = await _ready(() => _offlineQueueBox);
    if (box == null) return false;
    try {
      await box.put(log.id, log);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<OfflineLog>> getOfflineQueue() async {
    final box = await _ready(() => _offlineQueueBox);
    if (box == null) return [];
    final queue = box.values.toList();
    queue.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return queue;
  }

  Future<void> removeFromOfflineQueue(String id) async {
    final box = await _ready(() => _offlineQueueBox);
    if (box == null) return;
    await box.delete(id);
  }

  Future<void> updateOfflineLog(OfflineLog log) async {
    final box = await _ready(() => _offlineQueueBox);
    if (box == null) return;
    await box.put(log.id, log);
  }

  Future<void> clearOfflineQueue() async {
    final box = await _ready(() => _offlineQueueBox);
    if (box == null) return;
    await box.clear();
  }

  // Last sync tracking
  Future<void> setLastSync(DateTime dateTime) async {
    final box = await _ready(() => _lastSyncBox);
    if (box == null) return;
    await box.put('lastSync', dateTime);
  }

  Future<DateTime?> getLastSync() async {
    final box = await _ready(() => _lastSyncBox);
    if (box == null) return null;
    return box.get('lastSync');
  }

  Future<bool> hasCachedData() async {
    final stages = await _ready(() => _stagesBox);
    final logs = await _ready(() => _logsBox);
    if (stages == null || logs == null) return false;
    return stages.isNotEmpty || logs.isNotEmpty;
  }

  Future<int> getOfflineQueueCount() async {
    final box = await _ready(() => _offlineQueueBox);
    return box?.length ?? 0;
  }

  Future<Box<T>?> _ready<T>(Box<T>? Function() read) async {
    var box = read();
    if (box != null) return box;
    try {
      await init();
    } catch (_) {
      return null;
    }
    return read();
  }
}
