import 'dart:async';
import 'package:pedometer/pedometer.dart' as ped;
import 'package:permission_handler/permission_handler.dart' as perm;
import '../storage/steps_storage.dart';

class StepsCounter {
  static final StepsCounter _instance = StepsCounter._internal();
  factory StepsCounter() => _instance;
  StepsCounter._internal();

  StreamSubscription<ped.StepCount>? _stepCountSubscription;
  final StepsStorage _storage = StepsStorage();
  
  int _currentSteps = 0;
  bool _isListening = false;

  // Stream controllers for broadcasting step updates
  final StreamController<int> _stepsController = StreamController<int>.broadcast();

  Stream<int> get stepsStream => _stepsController.stream;
  int get currentSteps => _currentSteps;
  bool get isListening => _isListening;

  Future<bool> requestPermissions() async {
    try {
      final status = await perm.Permission.activityRecognition.request();
      
      if (status.isDenied) {
        print('StepsCounter: Activity recognition permission denied');
        return false;
      }
      
      if (status.isPermanentlyDenied) {
        print('StepsCounter: Activity recognition permission permanently denied');
        await perm.openAppSettings();
        return false;
      }
      
      return status.isGranted;
    } catch (e) {
      print('StepsCounter: Error requesting permissions: $e');
      return false;
    }
  }

  Future<void> startListening() async {
    if (_isListening) {
      print('StepsCounter: Already listening');
      return;
    }

    try {
      // Request permissions first
      final hasPermission = await requestPermissions();
      if (!hasPermission) {
        print('StepsCounter: No permission to track steps');
        return;
      }

      // Load stored steps for today (this will auto-reset if new day)
      await _loadTodaySteps();

      // Start listening to step count
      _stepCountSubscription = ped.Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );

      _isListening = true;
      print('StepsCounter: Started listening to step count');
    } catch (e) {
      print('StepsCounter: Error starting step counter: $e');
    }
  }

  Future<void> stopListening() async {
    await _stepCountSubscription?.cancel();
    _stepCountSubscription = null;
    _isListening = false;
    print('StepsCounter: Stopped listening to step count');
  }

  void _onStepCount(ped.StepCount event) async {
    try {
      final todaySteps = await _calculateTodaySteps(event.steps);
      _currentSteps = todaySteps;
      
      // Save to storage
      await _storage.saveTodaySteps(todaySteps);
      
      // Broadcast update
      _stepsController.add(todaySteps);
      
      print('StepsCounter: Steps updated: $todaySteps');
    } catch (e) {
      print('StepsCounter: Error processing step count: $e');
    }
  }

  void _onStepCountError(error) {
    print('StepsCounter: Step count error: $error');
  }

  Future<void> _loadTodaySteps() async {
    try {
      _currentSteps = await _storage.getTodaySteps();
      _stepsController.add(_currentSteps);
    } catch (e) {
      print('StepsCounter: Error loading today steps: $e');
    }
  }

  Future<int> _calculateTodaySteps(int totalSteps) async {
    try {
      // Get stored base steps for today (steps at start of day)
      final baseSteps = await _storage.getBaseStepsForToday();
      
      if (baseSteps == -1) {
        // First time today, set base steps
        await _storage.setBaseStepsForToday(totalSteps);
        return 0;
      }
      
      // Calculate steps taken today
      final todaySteps = totalSteps - baseSteps;
      return todaySteps > 0 ? todaySteps : 0;
    } catch (e) {
      print('StepsCounter: Error calculating today steps: $e');
      return 0;
    }
  }

  Future<void> resetDailySteps() async {
    try {
      await _storage.resetDailySteps();
      _currentSteps = 0;
      _stepsController.add(0);
      print('StepsCounter: Daily steps reset');
    } catch (e) {
      print('StepsCounter: Error resetting daily steps: $e');
    }
  }

  void dispose() {
    stopListening();
    _stepsController.close();
  }
}
