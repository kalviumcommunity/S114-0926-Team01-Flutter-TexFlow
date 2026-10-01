import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _controller;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isOnline = true;

  /// Broadcast stream of connectivity changes.
  ///
  /// The underlying plugin subscription is created at most once; previously
  /// every access to this getter added a new listener that was never cancelled,
  /// leaking subscriptions on each rebuild.
  Stream<bool> get connectionStream {
    _controller ??= StreamController<bool>.broadcast();
    _subscription ??= _connectivity.onConnectivityChanged.listen((result) {
      final isOnline = !result.contains(ConnectivityResult.none);
      if (isOnline != _isOnline) {
        _isOnline = isOnline;
        _controller?.add(isOnline);
      }
    });
    return _controller!.stream;
  }

  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);
    return _isOnline;
  }

  bool get isOnline => _isOnline;

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _controller?.close();
    _controller = null;
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectionStream;
});
