import 'package:flutter/foundation.dart';

/// Represents a single upload task
class UploadTask {
  final String id;
  final String title;
  final String type; // 'workout' or 'diet'
  double progress;
  UploadStatus status;
  String? errorMessage;
  final DateTime createdAt;

  UploadTask({
    required this.id,
    required this.title,
    required this.type,
    this.progress = 0.0,
    this.status = UploadStatus.uploading,
    this.errorMessage,
  }) : createdAt = DateTime.now();
}

enum UploadStatus { uploading, success, failed }

/// Global upload manager to track upload progress across the app
class UploadManager extends ChangeNotifier {
  static final UploadManager _instance = UploadManager._internal();

  factory UploadManager() {
    return _instance;
  }

  UploadManager._internal();

  final List<UploadTask> _tasks = [];

  /// Get all current tasks
  List<UploadTask> get tasks => List.unmodifiable(_tasks);

  /// Get active (uploading) tasks
  List<UploadTask> get activeTasks =>
      _tasks.where((t) => t.status == UploadStatus.uploading).toList();

  /// Check if there are any active uploads
  bool get hasActiveUploads => activeTasks.isNotEmpty;

  /// Get the current upload task (most recent active)
  UploadTask? get currentTask =>
      activeTasks.isNotEmpty ? activeTasks.last : null;

  /// Start a new upload task
  String startUpload({required String title, required String type}) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final task = UploadTask(id: id, title: title, type: type);
    _tasks.add(task);
    notifyListeners();
    return id;
  }

  /// Update the progress of an upload task
  void updateProgress(String taskId, double progress) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex].progress = progress.clamp(0.0, 1.0);
      notifyListeners();
    }
  }

  /// Mark an upload as successful
  void completeUpload(String taskId) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex].progress = 1.0;
      _tasks[taskIndex].status = UploadStatus.success;
      notifyListeners();

      // Auto-remove after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        removeTask(taskId);
      });
    }
  }

  /// Mark an upload as failed
  void failUpload(String taskId, {String? errorMessage}) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex].status = UploadStatus.failed;
      _tasks[taskIndex].errorMessage = errorMessage;
      notifyListeners();

      // Auto-remove after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        removeTask(taskId);
      });
    }
  }

  /// Remove a task from the list
  void removeTask(String taskId) {
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  /// Clear all completed/failed tasks
  void clearInactiveTasks() {
    _tasks.removeWhere((t) => t.status != UploadStatus.uploading);
    notifyListeners();
  }
}
