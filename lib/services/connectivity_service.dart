import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamController<bool>? _controller;
  bool _isOnline = true;

  Stream<bool> get connectionStream {
    _controller ??= StreamController<bool>.broadcast();
    _connectivity.onConnectivityChanged.listen((result) {
      final isOnline = result.contains(ConnectivityResult.none) == false;
      if (isOnline != _isOnline) {
        _isOnline = isOnline;
        _controller?.add(isOnline);
      }
    });
    return _controller!.stream;
  }

  Future<bool> checkConnection() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result.contains(ConnectivityResult.none) == false;
    return _isOnline;
  }

  bool get isOnline => _isOnline;

  void dispose() {
    _controller?.close();
    _controller = null;
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectionStream;
});