import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'dart:async';
import '../../core/utils/sync_manager.dart';
import '../../core/utils/connectivity_service.dart';

enum SyncStatus { idle, syncing, noInternet }

class SyncState {
  final SyncStatus status;
  const SyncState(this.status);
}

@injectable
class SyncCubit extends Cubit<SyncState> {
  final SyncManager _syncManager;
  final ConnectivityService _connectivityService;
  StreamSubscription<bool>? _syncSubscription;
  StreamSubscription<bool>? _connectivitySubscription;

  SyncCubit(this._syncManager, this._connectivityService)
      : super(const SyncState(SyncStatus.idle)) {
    _initListeners();
  }

  void _initListeners() {
    // 1. Listen to connectivity state changes
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((isConnected) {
      if (!isConnected) {
        emit(const SyncState(SyncStatus.noInternet));
      } else {
        emit(const SyncState(SyncStatus.idle));
        _syncManager.processSyncQueue();
      }
    });

    // 2. Listen to SyncManager sync active state
    _syncSubscription = _syncManager.syncStatusStream.listen((isSyncing) {
      if (isSyncing) {
        emit(const SyncState(SyncStatus.syncing));
      } else {
        _connectivityService.isConnected.then((connected) {
          if (connected) {
            emit(const SyncState(SyncStatus.idle));
          } else {
            emit(const SyncState(SyncStatus.noInternet));
          }
        });
      }
    });

    // Run initial check
    _connectivityService.isConnected.then((connected) {
      if (!connected) {
        emit(const SyncState(SyncStatus.noInternet));
      } else {
        _syncManager.processSyncQueue();
      }
    });
  }

  Future<void> forceSync() async {
    final connected = await _connectivityService.isConnected;
    if (connected) {
      await _syncManager.processSyncQueue();
    } else {
      emit(const SyncState(SyncStatus.noInternet));
    }
  }

  @override
  Future<void> close() {
    _syncSubscription?.cancel();
    _connectivitySubscription?.cancel();
    return super.close();
  }
}
