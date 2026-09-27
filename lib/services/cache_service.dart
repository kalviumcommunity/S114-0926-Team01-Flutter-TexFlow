import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/production_log.dart';
import '../models/production_stage.dart';
import '../models/offline_log.dart';
import '../models/production_log.g.dart';
import '../models/production_stage.g.dart';
import '../models/offline_log.g.dart';

class CacheService {
  static const String _stagesBox = 'cached_stages';
  static const String _logsBox = 'cached_logs';
  static const String _offlineQueueBox = 'offline_queue';
  static const String _lastSyncBox = 'last_sync';

  late Box<ProductionStage> _stagesBoxInstance;
  late Box<ProductionLog> _logsBoxInstance;
  late Box<OfflineLog> _offlineQueueInstance;
  late Box<DateTime> _lastSyncInstance;

  Future<void> init() async {
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

    _stagesBoxInstance = await Hive.openBox<ProductionStage>(_stagesBox);
    _logsBoxInstance = await Hive.openBox<ProductionLog>(_logsBox);
    _offlineQueueInstance = await Hive.openBox<OfflineLog>(_offlineQueueBox);
    _lastSyncInstance = await Hive.openBox<DateTime>(_lastSyncBox);
  }

  // Stages caching
  Future<void> cacheStages(List<ProductionStage> stages) async {
    await _stagesBoxInstance.clear();
    for (final stage in stages) {
      await _stagesBoxInstance.put(stage.id, stage);
    }
  }

  List<ProductionStage> getCachedStages() {
    return _stagesBoxInstance.values.toList();
  }

  // Logs caching
  Future<void> cacheLogs(List<ProductionLog> logs) async {
    await _logsBoxInstance.clear();
    for (final log in logs) {
      await _logsBoxInstance.put(log.id, log);
    }
  }

  List<ProductionLog> getCachedLogs({String? shift, String? stageId, DateTime? date}) {
    var logs = _logsBoxInstance.values.toList();
    
    if (shift != null) {
      logs = logs.where((l) => l.shift == shift).toList();
    }
    if (stageId != null) {
      logs = logs.where((l) => l.stageId == stageId).toList();
    }
    if (date != null) {
      final start = DateTime(date.year, date.month, date.day);
      final end = start.add(const Duration(days: 1));
      logs = logs.where((l) => l.logTime.isAfter(start) && l.logTime.isBefore(end)).toList();
    }
    
    logs.sort((a, b) => b.logTime.compareTo(a.logTime));
    return logs;
  }

  // Offline queue management
  Future<void> addToOfflineQueue(OfflineLog log) async {
    await _offlineQueueInstance.put(log.id, log);
  }

  List<OfflineLog> getOfflineQueue() {
    final queue = _offlineQueueInstance.values.toList();
    queue.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return queue;
  }

  Future<void> removeFromOfflineQueue(String id) async {
    await _offlineQueueInstance.delete(id);
  }

  Future<void> updateOfflineLog(OfflineLog log) async {
    await _offlineQueueInstance.put(log.id, log);
  }

  Future<void> clearOfflineQueue() async {
    await _offlineQueueInstance.clear();
  }

  // Last sync tracking
  Future<void> setLastSync(DateTime dateTime) async {
    await _lastSyncInstance.put('lastSync', dateTime);
  }

  DateTime? getLastSync() {
    return _lastSyncInstance.get('lastSync');
  }

  bool hasCachedData() {
    return _stagesBoxInstance.isNotEmpty || _logsBoxInstance.isNotEmpty;
  }

  int getOfflineQueueCount() {
    return _offlineQueueInstance.length;
  }
}