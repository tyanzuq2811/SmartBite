import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:injectable/injectable.dart';
import '../di/injection.dart';
import 'connectivity_service.dart';
import '../../data/datasources/sqlite_helper.dart';

@lazySingleton
class SyncManager {
  final ConnectivityService _connectivityService;
  final SqliteHelper _sqliteHelper;
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isSyncing = false;

  // Stream to notify UI of sync status changes
  final _syncStatusController = StreamController<bool>.broadcast();
  Stream<bool> get syncStatusStream => _syncStatusController.stream;

  SyncManager(this._connectivityService, this._sqliteHelper) {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen((isConnected) {
      if (isConnected) {
        processSyncQueue();
      }
    });
  }

  bool get _isFirebaseInitialized {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> processSyncQueue() async {
    if (_isSyncing) return;
    if (!_isFirebaseInitialized) return;

    final user = getIt<FirebaseAuth>().currentUser;
    if (user == null) return;

    final tasks = await _sqliteHelper.queryPendingSyncTasks();
    if (tasks.isEmpty) return;

    _isSyncing = true;
    _syncStatusController.add(true);

    try {
      final firestore = getIt<FirebaseFirestore>();
      for (var task in tasks) {
        final id = task['id'] as int;
        final action = task['action'] as String;
        final recordId = task['record_id'] as String;
        final dataJson = task['data_json'] as String;
        final Map<String, dynamic> data = jsonDecode(dataJson);

        if (action == 'SAVE') {
          await firestore
              .collection('users')
              .doc(user.uid)
              .collection('saved_recipes')
              .doc(recordId)
              .set(data);
        }

        // Successfully synced, remove from queue
        await _sqliteHelper.deleteSyncTask(id);
      }
    } catch (_) {
      // Sync failed, will retry next time connection is active
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false);
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }
}
