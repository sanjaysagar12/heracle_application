import 'package:flutter/material.dart';
import '../api/workout_progress_api.dart';

class WorkoutProgressPage extends StatefulWidget {
  final String workoutLogId;
  final String sessionName;

  const WorkoutProgressPage({
    Key? key,
    required this.workoutLogId,
    required this.sessionName,
  }) : super(key: key);

  @override
  State<WorkoutProgressPage> createState() => _WorkoutProgressPageState();
}

class _WorkoutProgressPageState extends State<WorkoutProgressPage> {
  late Future<Map<String, dynamic>> _progressFuture;

  @override
  void initState() {
    super.initState();
    _refreshProgress();
  }

  void _refreshProgress() {
    setState(() {
      _progressFuture = WorkoutProgressApi.getWorkoutProgress(widget.workoutLogId);
    });
  }

  Future<void> _updateExerciseProgress(String exerciseId, List<Map<String, dynamic>> completedSets) async {
    try {
      final updateData = {
        'completedSets': completedSets,
        'exerciseNotes': '',
        'exerciseCompleted': true,
      };

      await WorkoutProgressApi.updateExerciseProgress(widget.workoutLogId, exerciseId, updateData);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise updated successfully')),
      );
      _refreshProgress();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update exercise: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.sessionName} - Progress'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProgress,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _progressFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          final workoutLog = data['workoutLog'] as Map<String, dynamic>;
          final exerciseProgress = (data['exerciseProgress'] as List<dynamic>?) ?? [];
          final completion = data['completion'] as Map<String, dynamic>?;

          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              // Workout Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Workout Summary', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text('Status: ${workoutLog['status'] ?? 'Unknown'}'),
                      Text('Total Time: ${(workoutLog['totalTimeMin'] as num?)?.toInt() ?? 0} min'),
                      Text('Total Volume: ${(workoutLog['totalVolume'] as num?)?.toInt() ?? 0}'),
                      Text('Total Sets: ${(workoutLog['totalSets'] as num?)?.toInt() ?? 0}'),
                      Text('Total Reps: ${(workoutLog['totalReps'] as num?)?.toInt() ?? 0}'),
                      if (completion != null) ...[
                        const SizedBox(height: 8),
                        Text('Sets: ${(completion['setsPercentage'] as num?)?.toInt() ?? 0}%'),
                        Text('Reps: ${(completion['repsPercentage'] as num?)?.toInt() ?? 0}%'),
                        Text('Volume: ${(completion['volumePercentage'] as num?)?.toInt() ?? 0}%'),
                      ],
                    ],
                  ),
                ),
              ),

              // Exercise Progress Cards
              ...exerciseProgress.map<Widget>((ep) {
                final exercise = ep['exercise'] as Map<String, dynamic>;
                final planned = ep['planned'] as Map<String, dynamic>;
                final actual = ep['actual'] as Map<String, dynamic>?;
                final setDetails = (ep['setDetails'] as List<dynamic>?) ?? [];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ExpansionTile(
                    title: Text(exercise['name'] as String? ?? 'Unknown Exercise'),
                    subtitle: Text('Planned: ${(planned['sets'] as num?)?.toInt() ?? 0} sets × ${(planned['reps'] as num?)?.toInt() ?? 0} reps @ ${(planned['weight'] as num?)?.toDouble() ?? 0}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (actual != null) ...[
                              Text('Actual: ${(actual['sets'] as num?)?.toInt() ?? 0} sets, ${(actual['reps'] as num?)?.toInt() ?? 0} reps'),
                              Text('Volume: ${(actual['volume'] as num?)?.toInt() ?? 0}, Avg Weight: ${(actual['averageWeight'] as num?)?.toDouble() ?? 0}'),
                              const SizedBox(height: 8),
                            ],
                            const Text('Sets:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...setDetails.asMap().entries.map((entry) {
                              final index = entry.key;
                              final setDetail = entry.value as Map<String, dynamic>;
                              final plannedSet = setDetail['planned'] as Map<String, dynamic>? ?? {};
                              final actualSet = setDetail['actual'] as Map<String, dynamic>?;

                              return SetProgressItem(
                                setNumber: (plannedSet['setNumber'] as num?)?.toInt() ?? (index + 1),
                                plannedReps: (plannedSet['reps'] as num?)?.toInt() ?? 0,
                                plannedWeight: (plannedSet['weight'] as num?)?.toDouble(),
                                actualReps: (actualSet?['reps'] as num?)?.toInt(),
                                actualWeight: (actualSet?['weight'] as num?)?.toDouble(),
                                completed: setDetail['completed'] as bool? ?? false,
                                onUpdate: (reps, weight, rpe) {
                                  // Update this specific set
                                  final updatedSets = setDetails.asMap().entries.map((e) {
                                    if (e.key == index) {
                                      return {
                                        'setNumber': (plannedSet['setNumber'] as num?)?.toInt() ?? (index + 1),
                                        'reps': reps,
                                        'weight': weight,
                                        'rpe': rpe,
                                        'completed': true,
                                      };
                                    }
                                    final otherSet = e.value as Map<String, dynamic>;
                                    final otherActual = otherSet['actual'] as Map<String, dynamic>?;
                                    final otherPlanned = otherSet['planned'] as Map<String, dynamic>? ?? {};
                                    return {
                                      'setNumber': (otherPlanned['setNumber'] as num?)?.toInt() ?? (e.key + 1),
                                      'reps': (otherActual?['reps'] as num?)?.toInt() ?? (otherPlanned['reps'] as num?)?.toInt() ?? 0,
                                      'weight': (otherActual?['weight'] as num?)?.toDouble() ?? (otherPlanned['weight'] as num?)?.toDouble(),
                                      'rpe': (otherActual?['rpe'] as num?)?.toInt() ?? 7,
                                      'completed': otherSet['completed'] as bool? ?? false,
                                    };
                                  }).toList();

                                  _updateExerciseProgress(
                                    exercise['id'] as String,
                                    updatedSets.cast<Map<String, dynamic>>(),
                                  );
                                },
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }
}

class SetProgressItem extends StatefulWidget {
  final int setNumber;
  final int plannedReps;
  final double? plannedWeight;
  final int? actualReps;
  final double? actualWeight;
  final bool completed;
  final Function(int reps, double? weight, int rpe) onUpdate;

  const SetProgressItem({
    Key? key,
    required this.setNumber,
    required this.plannedReps,
    this.plannedWeight,
    this.actualReps,
    this.actualWeight,
    required this.completed,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<SetProgressItem> createState() => _SetProgressItemState();
}

class _SetProgressItemState extends State<SetProgressItem> {
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _rpeController;

  @override
  void initState() {
    super.initState();
    _repsController = TextEditingController(
      text: (widget.actualReps ?? widget.plannedReps).toString(),
    );
    _weightController = TextEditingController(
      text: (widget.actualWeight ?? widget.plannedWeight)?.toString() ?? '',
    );
    _rpeController = TextEditingController(text: '7');
  }

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    _rpeController.dispose();
    super.dispose();
  }

  void _updateSet() {
    final reps = int.tryParse(_repsController.text) ?? widget.plannedReps;
    final weight = double.tryParse(_weightController.text);
    final rpe = int.tryParse(_rpeController.text) ?? 7;
    widget.onUpdate(reps, weight, rpe);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.completed ? Colors.green[50] : null,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set ${widget.setNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _repsController,
                    decoration: const InputDecoration(
                      labelText: 'Reps',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight',
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _rpeController,
                    decoration: const InputDecoration(
                      labelText: 'RPE',
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _updateSet,
                  child: const Text('Update'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
