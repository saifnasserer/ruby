import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ruby/core/models/task.dart';
import 'package:ruby/core/services/backend_service.dart';
import 'package:ruby/core/services/auth_service.dart';
import 'package:ruby/core/services/storage_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  static SyncService get instance => _instance;

  static const String _lastSyncKey = 'last_sync_time';
  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  SyncService._internal() {
    _initConnectivityListener();
    _loadLastSyncTime();
  }

  Future<void> _loadLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastSyncKey);
    if (timestamp != null) {
      _lastSyncTime = DateTime.tryParse(timestamp);
    }
  }

  Future<void> _updateLastSyncTime() async {
    _lastSyncTime = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, _lastSyncTime!.toIso8601String());
  }

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      // Check if we just became online
      final hasConnection = results.any(
        (result) => result != ConnectivityResult.none,
      );
      if (hasConnection && AuthService.instance.isAuthenticated) {
        debugPrint('SyncService: Network recovered, triggering auto-sync.');
        sync();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  PocketBase get _pb => BackendService.instance.pb;

  // Collection name
  static const String _collectionName = 'tasks';
  static const String _offlineQueueKey = 'sync_offline_queue';

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  // Track tasks currently being uploaded to prevent duplicate uploads
  final Set<String> _inFlightTasks = {};

  /// Public wrapper for creating a task
  Future<void> createTask(Task task) async {
    await _uploadTask(task);
  }

  /// Public wrapper for updating a task
  Future<void> updateTask(Task task) async {
    try {
      if (!AuthService.instance.isAuthenticated) {
        await _addToOfflineQueue(task.id, 'upsert');
        return;
      }
      final records = await _pb
          .collection(_collectionName)
          .getList(filter: 'local_id = "${task.id}"');
      await _uploadTask(
        task,
        remoteId: records.items.isNotEmpty ? records.items.first.id : null,
      );
    } catch (e) {
      await _addToOfflineQueue(task.id, 'upsert');
    }
  }

  /// Public wrapper for deleting a task
  Future<void> deleteTask(String taskId) async {
    try {
      if (!AuthService.instance.isAuthenticated) {
        await _addToOfflineQueue(taskId, 'delete');
        return;
      }
      await _deleteTaskRemotely(taskId);
    } catch (e) {
      await _addToOfflineQueue(taskId, 'delete');
    }
  }

  /// Main entry point for syncing everything
  Future<void> sync() async {
    final userId = AuthService.instance.currentUserId;
    if (!AuthService.instance.isAuthenticated || _isSyncing || userId == null) {
      if (AuthService.instance.isAuthenticated && userId == null) {
        debugPrint(
          'SyncService: Skipping sync - Authenticated but userId is null.',
        );
      }
      return;
    }

    // Double check session validity before starting
    final isSessionValid = await AuthService.instance.validateSession();
    if (!isSessionValid) {
      debugPrint('SyncService: Skipping sync - Session is invalid.');
      return;
    }

    _isSyncing = true;
    try {
      debugPrint('SyncService: Starting full sync...');

      // 1. Process offline queue first
      await _processOfflineQueue();

      // 2. Fetch remote tasks
      final userId = AuthService.instance.currentUserId;
      final remoteRecords = await _pb
          .collection(_collectionName)
          .getFullList(sort: '-updated', filter: 'user = "$userId"');
      debugPrint(
        'SyncService: Fetched ${remoteRecords.length} remote tasks for user $userId',
      );

      // 3. Get local tasks
      final localTasksMap = await StorageService.loadTasks();
      final List<Task> allLocalTasks = [];
      for (var list in localTasksMap.values) {
        allLocalTasks.addAll(list);
      }

      // 4. Reconcile
      await _reconcile(allLocalTasks, remoteRecords, localTasksMap);
      await _updateLastSyncTime();

      debugPrint('SyncService: Sync completed successfully.');
    } catch (e) {
      debugPrint('SyncService: Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Reconcile local and remote states
  Future<void> _reconcile(
    List<Task> localTasks,
    List<RecordModel> remoteRecords,
    Map<String, List<Task>> localTasksMap,
  ) async {
    bool hasLocalChanges = false;

    // Map remote records by local_id for fast lookup
    final remoteMap = {
      for (var r in remoteRecords) r.data['local_id'] as String: r,
    };

    // 1. Check local tasks against remote
    for (final task in localTasks) {
      final remote = remoteMap[task.id];
      if (remote == null) {
        // Task exists locally but not on server -> Upload
        await _uploadTask(task);
      } else {
        // Task exists in both -> Compare updatedAt
        final remoteUpdatedAt = DateTime.parse(remote.updated);
        final localUpdatedAt = task.updatedAt ?? task.createdAt;

        if (localUpdatedAt.isAfter(
          remoteUpdatedAt.add(const Duration(seconds: 1)),
        )) {
          // Local is newer -> Update remote
          await _uploadTask(task, remoteId: remote.id);
        } else if (remoteUpdatedAt.isAfter(
          localUpdatedAt.add(const Duration(seconds: 1)),
        )) {
          // Remote is newer -> Update local
          final remoteTask = _recordToTask(remote);
          if (task.dayOfWeek != remoteTask.dayOfWeek) {
            debugPrint(
              'SyncService: Task ${task.id} moving from ${task.dayOfWeek} to ${remoteTask.dayOfWeek}',
            );
          }
          _updateLocalTaskInMap(localTasksMap, remoteTask);
          hasLocalChanges = true;
        }
      }
      // Remove from remote map to see what's left (exclusive remotes)
      remoteMap.remove(task.id);
    }

    // 2. Any records left in remoteMap don't exist locally -> Download
    for (final remote in remoteMap.values) {
      final remoteTask = _recordToTask(remote);
      // Download remote tasks, even those marked as deleted (to keep local state in sync)
      debugPrint('SyncService: Downloading remote task ${remoteTask.id}');
      _updateLocalTaskInMap(localTasksMap, remoteTask);
      hasLocalChanges = true;
    }

    if (hasLocalChanges) {
      // Reload from storage to avoid overwriting changes that happened while syncing
      final finalTasksMap = await StorageService.loadTasks();
      for (final list in localTasksMap.values) {
        for (final task in list) {
          _updateLocalTaskInMap(finalTasksMap, task);
        }
      }
      await StorageService.saveTasks(finalTasksMap);
    }
  }

  void _updateLocalTaskInMap(Map<String, List<Task>> map, Task task) {
    // 1. Remove the task if it exists anywhere else (prevents duplicates across days)
    for (final day in map.keys.toList()) {
      map[day]?.removeWhere((t) => t.id == task.id);
    }

    // 2. Add to its current correct day
    final list = map[task.dayOfWeek] ?? [];
    list.add(task);
    map[task.dayOfWeek] = list;
  }

  /// Upload or Update a task to Cloud
  Future<void> _uploadTask(Task task, {String? remoteId}) async {
    // Prevent duplicate concurrent uploads for the same task
    if (_inFlightTasks.contains(task.id)) {
      debugPrint('SyncService: Task ${task.id} is already being uploaded. Skipping.');
      return;
    }

    _inFlightTasks.add(task.id);

    try {
      if (!AuthService.instance.isAuthenticated) {
        await _addToOfflineQueue(task.id, 'upsert');
        return;
      }

      final body = _taskToRecordMap(task);
      final userId = AuthService.instance.currentUserId;
      if (userId == null) {
        debugPrint(
          'SyncService: Skipping upload for task ${task.id}. User ID is null.',
        );
        return;
      }
      debugPrint('SyncService: Uploading task ${task.id} for user $userId');

      body['user'] = userId;

      if (remoteId != null) {
        await _pb.collection(_collectionName).update(remoteId, body: body);
      } else {
        try {
          // Double check if already exists by local_id before creating, 
          // as a final safety measure against race conditions
          final records = await _pb.collection(_collectionName).getList(
                filter: 'local_id = "${task.id}" && user = "$userId"',
              );
          
          if (records.items.isNotEmpty) {
            debugPrint('SyncService: Task ${task.id} already exists on server. Updating instead.');
            await _pb.collection(_collectionName).update(records.items.first.id, body: body);
          } else {
            await _pb.collection(_collectionName).create(body: body);
          }
        } catch (e) {
          // If it fails with a relation error, it might be a multi-relation field
          if (e.toString().contains('validation_missing_rel_records')) {
            debugPrint(
              'SyncService: Probable multi-relation mismatch. Retrying as array...',
            );
            body['user'] = [userId];
            await _pb.collection(_collectionName).create(body: body);
          } else {
            rethrow;
          }
        }
      }
    } catch (e) {
      debugPrint('SyncService: Error uploading task ${task.id}: $e');
      if (e is ClientException &&
          (e.statusCode == 401 || e.statusCode == 403)) {
        AuthService.instance.setReAuthRequired(true);
      } else {
        await _addToOfflineQueue(task.id, 'upsert');
      }
    } finally {
      _inFlightTasks.remove(task.id);
    }
  }

  /// Queue a change for later sync
  Future<void> _addToOfflineQueue(String taskId, String action) async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_offlineQueueKey) ?? '[]';
    final List<dynamic> queue = jsonDecode(queueJson);

    final itemToRemove = queue.indexWhere((item) => item['taskId'] == taskId);
    if (itemToRemove != -1) {
      final existingAction = queue[itemToRemove]['action'];
      // If we are deleting something that was only just created offline,
      // we can just remove it from the queue entirely.
      if (action == 'delete' && existingAction == 'upsert') {
        queue.removeAt(itemToRemove);
        await prefs.setString(_offlineQueueKey, jsonEncode(queue));
        return;
      }
      queue.removeAt(itemToRemove);
    }

    queue.add({
      'taskId': taskId,
      'action': action,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await prefs.setString(_offlineQueueKey, jsonEncode(queue));
  }

  Future<void> _processOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = prefs.getString(_offlineQueueKey);
    if (queueJson == null || queueJson == '[]') return;

    debugPrint('SyncService: Processing offline queue...');
    final List<dynamic> queue = jsonDecode(queueJson);
    final localTasksMap = await StorageService.loadTasks();

    for (final item in List.from(queue)) {
      final taskId = item['taskId'];
      final action = item['action'];

      try {
        if (action == 'delete') {
          await _deleteTaskRemotely(taskId);
        } else {
          Task? task;
          for (var list in localTasksMap.values) {
            final found = list.where((t) => t.id == taskId);
            if (found.isNotEmpty) {
              task = found.first;
              break;
            }
          }
          if (task != null) {
            final userId = AuthService.instance.currentUserId;
            final records = await _pb
                .collection(_collectionName)
                .getList(filter: 'local_id = "$taskId" && user = "$userId"');
            await _uploadTask(
              task,
              remoteId: records.items.isNotEmpty
                  ? records.items.first.id
                  : null,
            );
          }
        }
        queue.remove(item);
      } catch (e) {
        debugPrint('SyncService: Failed to process queue item $taskId: $e');
        // Continue to next item instead of breaking
      }
    }
    await prefs.setString(_offlineQueueKey, jsonEncode(queue));
  }

  Future<void> _deleteTaskRemotely(String taskId) async {
    final userId = AuthService.instance.currentUserId;
    final records = await _pb
        .collection(_collectionName)
        .getList(filter: 'local_id = "$taskId" && user = "$userId"');
    if (records.items.isNotEmpty) {
      // Soft deletion: update is_deleted to true
      await _pb
          .collection(_collectionName)
          .update(records.items.first.id, body: {'is_deleted': true});
    }
  }

  // --- Mappers ---

  Map<String, dynamic> _taskToRecordMap(Task task) {
    return {
      'local_id': task.id,
      'text': task.text,
      'is_completed': task.isCompleted,
      'day_of_week': task.dayOfWeek,
      'is_deleted': task.isDeleted,
      'data': jsonEncode(task.toJson()),
    };
  }

  Task _recordToTask(RecordModel record) {
    final data = record.data['data'];
    Map<String, dynamic>? json;

    if (data != null) {
      if (data is String) {
        try {
          json = jsonDecode(data) as Map<String, dynamic>;
        } catch (e) {
          debugPrint(
            'SyncService: Error decoding data string for task ${record.data['local_id']}: $e',
          );
        }
      } else if (data is Map<String, dynamic>) {
        json = data;
      } else {
        debugPrint(
          'SyncService: Unknown data type for task ${record.data['local_id']}: ${data.runtimeType}',
        );
      }
    }

    if (json != null) {
      try {
        return Task.fromJson(
          json,
        ).copyWith(updatedAt: DateTime.parse(record.updated));
      } catch (e) {
        debugPrint(
          'SyncService: Error parsing task from JSON for task ${record.data['local_id']}: $e',
        );
      }
    }

    // Fallback: Create from top-level record fields if possible
    debugPrint(
      'SyncService: Falling back to basic task for ${record.data['local_id']}',
    );
    return Task(
      id: record.data['local_id'] ?? record.id,
      text: record.data['text'] ?? '',
      createdAt: DateTime.parse(record.created),
      updatedAt: DateTime.parse(record.updated),
      dayOfWeek: record.data['day_of_week'] ?? '',
      isCompleted: record.data['is_completed'] ?? false,
      isDeleted: record.data['is_deleted'] ?? false,
    );
  }
}
