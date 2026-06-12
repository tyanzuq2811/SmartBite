import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class ConnectivityService {
  final Connectivity _connectivity;
  
  ConnectivityService(this._connectivity);

  // Stream of network status (true = connected, false = disconnected)
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return _hasActiveConnection(results);
    });
  }

  // Check current connectivity state
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _hasActiveConnection(results);
  }

  bool _hasActiveConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    // If any of the connection types is not 'none', we have a connection
    return results.any((result) => result != ConnectivityResult.none);
  }
}
