import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import '../models/task.dart';
import 'backend_service.dart';
import 'auth_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  static SyncService get instance => _instance;

  SyncService._internal();

  PocketBase get _pb => BackendService.instance.pb;

  // Collection name
  static const String _collectionName = 'tasks';

  /// Sync a newly created task to Cloud
  Future<void> createTask(Task task) async {
    if (!AuthService.instance.isAuthenticated) return;

    try {
      final body = _taskToRecordMap(task);
      body['user'] = AuthService.instance.currentUser?.id;

      List<http.MultipartFile> files = [];
      if (task.audioPath != null) {
        final file = File(task.audioPath!);
        if (await file.exists()) {
          files.add(await http.MultipartFile.fromPath('audio', file.path));
        }
      }

      await _pb.collection(_collectionName).create(body: body, files: files);
      debugPrint('SyncService: Task created ${task.id}');
    } catch (e) {
      debugPrint('SyncService: Error creating task: $e');
      // TODO: Queue for offline sync
    }
  }

  /// Sync task updates to Cloud
  Future<void> updateTask(Task task) async {
    if (!AuthService.instance.isAuthenticated) return;

    try {
      // Find record by some ID mapping.
      // Ideally, Task.id should match Record.id.
      // If Task.id is a timestamp (legacy), we need to search or map it.
      // For now, assume we find via filter or store PB ID in local Task.
      // Since we don't have PB ID in Task yet, we'll try to find by 'taskId' field if we add one,
      // or filter by the legacy ID stored in a custom field.

      // Strategy: Use a filter to find the record where `data.localId` == task.id
      final records = await _pb
          .collection(_collectionName)
          .getList(filter: 'local_id = "${task.id}"');

      if (records.items.isNotEmpty) {
        final recordId = records.items.first.id;
        final body = _taskToRecordMap(task);

        // Handle audio update if changed? (Complex, skip for MVP unless needed)

        await _pb.collection(_collectionName).update(recordId, body: body);
        debugPrint('SyncService: Task updated ${task.id}');
      } else {
        // If not found, create it (healing)
        await createTask(task);
      }
    } catch (e) {
      debugPrint('SyncService: Error updating task: $e');
    }
  }

  /// Sync task deletion
  Future<void> deleteTask(String taskId) async {
    if (!AuthService.instance.isAuthenticated) return;

    try {
      final records = await _pb
          .collection(_collectionName)
          .getList(filter: 'local_id = "$taskId"');

      if (records.items.isNotEmpty) {
        await _pb.collection(_collectionName).delete(records.items.first.id);
        debugPrint('SyncService: Task deleted $taskId');
      }
    } catch (e) {
      debugPrint('SyncService: Error deleting task: $e');
    }
  }

  /// Fetch all tasks from Cloud
  Future<List<Task>> fetchAllTasks() async {
    if (!AuthService.instance.isAuthenticated) return [];

    try {
      final records = await _pb.collection(_collectionName).getFullList();
      return records.map((r) => _recordToTask(r)).toList();
    } catch (e) {
      debugPrint('SyncService: Error fetching tasks: $e');
      return [];
    }
  }

  // --- Mappers ---

  Map<String, dynamic> _taskToRecordMap(Task task) {
    // We store the main fields and a big 'data' JSON for the rest
    return {
      'local_id': task.id, // Important for mapping
      'text': task.text,
      'is_completed': task.isCompleted,
      'day_of_week': task.dayOfWeek,
      'data': jsonEncode(task.toJson()), // Backup/Full data
    };
  }

  Task _recordToTask(RecordModel record) {
    // Prefer the 'data' JSON if available as it has everything
    final data = record.data['data'];
    if (data != null && data is String) {
      try {
        final json = jsonDecode(data);
        // Verify ID mapping?
        return Task.fromJson(json);
      } catch (_) {}
    }
    // Fallback or if data field missing
    // Construct minimal task
    return Task(
      id: record.data['local_id'] ?? record.id,
      text: record.data['text'] ?? '',
      createdAt: DateTime.parse(record.created),
      dayOfWeek: record.data['day_of_week'] ?? '',
      isCompleted: record.data['is_completed'] ?? false,
    );
  }
}
