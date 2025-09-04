import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class StorageService {
  static const String _tasksKey = 'ruby_tasks';

  // Save all tasks to local storage
  static Future<void> saveTasks(Map<String, List<Task>> tasks) async {
    try {
      print('StorageService: Saving tasks - $tasks');
      final prefs = await SharedPreferences.getInstance();

      // Convert tasks to JSON
      final Map<String, dynamic> tasksJson = {};
      tasks.forEach((day, taskList) {
        tasksJson[day] = taskList.map((task) => task.toJson()).toList();
      });

      final jsonString = jsonEncode(tasksJson);
      print('StorageService: JSON string - $jsonString');

      // Save as JSON string
      final success = await prefs.setString(_tasksKey, jsonString);
      print('StorageService: Save success - $success');
    } catch (e) {
      print('Error saving tasks: $e');
    }
  }

  // Load all tasks from local storage
  static Future<Map<String, List<Task>>> loadTasks() async {
    try {
      print('StorageService: Loading tasks...');
      final prefs = await SharedPreferences.getInstance();
      final String? tasksJsonString = prefs.getString(_tasksKey);
      print('StorageService: Raw JSON string - $tasksJsonString');

      if (tasksJsonString == null) {
        print('StorageService: No data found, returning empty map');
        return {};
      }

      // Parse JSON
      final Map<String, dynamic> tasksJson = jsonDecode(tasksJsonString);
      print('StorageService: Parsed JSON - $tasksJson');

      // Convert back to Task objects
      final Map<String, List<Task>> tasks = {};
      tasksJson.forEach((day, taskListJson) {
        final List<dynamic> taskList = taskListJson as List<dynamic>;
        tasks[day] = taskList
            .map((taskJson) => Task.fromJson(taskJson))
            .toList();
      });

      print('StorageService: Final tasks map - $tasks');
      return tasks;
    } catch (e) {
      print('Error loading tasks: $e');
      return {};
    }
  }

  // Clear all tasks (for testing or reset)
  static Future<void> clearTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tasksKey);
    } catch (e) {
      print('Error clearing tasks: $e');
    }
  }

  // Get storage info (for debugging)
  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tasksJsonString = prefs.getString(_tasksKey);

      return {
        'hasData': tasksJsonString != null,
        'dataSize': tasksJsonString?.length ?? 0,
        'keys': prefs.getKeys().toList(),
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
