import '../../../core/helper/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class FitnessTarget {
  final int id;
  final String targetType;
  final int targetValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  FitnessTarget({
    required this.id,
    required this.targetType,
    required this.targetValue,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FitnessTarget.fromMap(Map<String, dynamic> map) {
    return FitnessTarget(
      id: map['id'] as int,
      targetType: map['target_type'] as String,
      targetValue: map['target_value'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'target_type': targetType,
      'target_value': targetValue,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }
}

class TargetsRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<Map<String, int>> getAllTargets() async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('targets');
      
      final Map<String, int> targets = {};
      for (final map in maps) {
        final target = FitnessTarget.fromMap(map);
        targets[target.targetType] = target.targetValue;
      }
      
      return targets;
    } catch (e) {
      print('TargetsRepository: Error getting targets: $e');
      // Return default targets if database fails
      return {
        'steps': 10000,
        'cals_burned': 500,
        'cals_taken': 2000,
        'protein_taken': 150,
      };
    }
  }

  Future<int> getTarget(String targetType) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'targets',
        where: 'target_type = ?',
        whereArgs: [targetType],
        limit: 1,
      );
      
      if (maps.isNotEmpty) {
        return maps.first['target_value'] as int;
      }
      
      // Return default values if not found
      switch (targetType) {
        case 'steps': return 10000;
        case 'cals_burned': return 500;
        case 'cals_taken': return 2000;
        case 'protein_taken': return 150;
        default: return 0;
      }
    } catch (e) {
      print('TargetsRepository: Error getting target for $targetType: $e');
      return 0;
    }
  }

  Future<bool> updateTarget(String targetType, int targetValue) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final result = await db.update(
        'targets',
        {
          'target_value': targetValue,
          'updated_at': now,
        },
        where: 'target_type = ?',
        whereArgs: [targetType],
      );
      
      return result > 0;
    } catch (e) {
      print('TargetsRepository: Error updating target: $e');
      return false;
    }
  }

  Future<bool> setTarget(String targetType, int targetValue) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // First try to update existing record
      final updateResult = await db.update(
        'targets',
        {
          'target_value': targetValue,
          'updated_at': now,
        },
        where: 'target_type = ?',
        whereArgs: [targetType],
      );
      
      // If no rows were updated, insert new record
      if (updateResult == 0) {
        await db.insert(
          'targets',
          {
            'target_type': targetType,
            'target_value': targetValue,
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      
      return true;
    } catch (e) {
      print('TargetsRepository: Error setting target: $e');
      return false;
    }
  }
}
