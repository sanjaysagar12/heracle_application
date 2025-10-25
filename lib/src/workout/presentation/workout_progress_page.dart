import 'package:flutter/material.dart';
import '../api/workout_progress_api.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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

  Future<void> _showFinishWorkoutDialog() async {
    final notesController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to finish this workout?'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Workout Notes (Optional)',
                border: OutlineInputBorder(),
                hintText: 'How did the workout go?',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Finish'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _finishWorkout(notesController.text.trim());
    }
    
    notesController.dispose();
  }

  Future<void> _finishWorkout(String notes) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final response = await WorkoutProgressApi.completeWorkout(widget.workoutLogId, notes);
      
      Navigator.of(context).pop(); // Close loading dialog

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workout completed! Total time: ${response['totalTimeMin']} min'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh the page to show the completed status and post button
        _refreshProgress();
        
        // Show post workout dialog immediately after finishing
        await Future.delayed(const Duration(milliseconds: 500)); // Small delay for UI update
        _showPostWorkoutDialog();
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to finish workout: $e')),
        );
      }
    }
  }

  Future<void> _showPostWorkoutDialog() async {
    final captionController = TextEditingController();
    bool isPublic = false;
    File? selectedImage;
    XFile? selectedXFile; // For web compatibility
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Post Workout'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image picker section
                const Text('Workout Photo (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if ((kIsWeb ? selectedXFile != null : selectedImage != null)) ...[
                  Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? Image.network(selectedXFile!.path, fit: BoxFit.cover) // For web
                          : Image.file(selectedImage!, fit: BoxFit.cover), // For mobile
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            if (kIsWeb) {
                              selectedXFile = pickedFile;
                              selectedImage = null;
                            } else {
                              selectedImage = File(pickedFile.path);
                              selectedXFile = null;
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                    const SizedBox(width: 8),
                    if (!kIsWeb) // Camera is not available on web
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(source: ImageSource.camera);
                          if (pickedFile != null) {
                            setState(() {
                              selectedImage = File(pickedFile.path);
                              selectedXFile = null;
                            });
                          }
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                  ],
                ),
                if ((kIsWeb ? selectedXFile != null : selectedImage != null)) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        selectedImage = null;
                        selectedXFile = null;
                      });
                    },
                    child: const Text('Remove Image'),
                  ),
                ],
                const SizedBox(height: 16),
                
                // Caption input
                TextField(
                  controller: captionController,
                  decoration: const InputDecoration(
                    labelText: 'Caption *',
                    border: OutlineInputBorder(),
                    hintText: 'Share your workout achievements!',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                
                // Public toggle
                SwitchListTile(
                  title: const Text('Make Public'),
                  subtitle: const Text('Share with the community'),
                  value: isPublic,
                  onChanged: (value) {
                    setState(() {
                      isPublic = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: captionController.text.trim().isEmpty
                  ? null
                  : () => Navigator.of(context).pop({
                      'caption': captionController.text.trim(),
                      'isPublic': isPublic,
                      'image': selectedImage,
                      'xfile': selectedXFile, // For web
                    }),
              child: const Text('Post'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _postWorkout(
        caption: result['caption'] as String,
        isPublic: result['isPublic'] as bool,
        imageFile: result['image'] as File?,
        imageXFile: result['xfile'] as XFile?, // For web
      );
    }
    
    captionController.dispose();
  }

  Future<void> _postWorkout({
    required String caption,
    required bool isPublic,
    File? imageFile,
    XFile? imageXFile, // For web
  }) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final response = await WorkoutProgressApi.postWorkout(
        logId: widget.workoutLogId,
        imageFile: imageFile,
        imageXFile: imageXFile, // Pass XFile for web
        caption: caption,
        isPublic: isPublic,
      );
      
      Navigator.of(context).pop(); // Close loading dialog

      if (mounted) {
        final postId = response['postId'] as String?;
        final success = response['success'] as bool? ?? false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success && postId != null 
                  ? (isPublic ? 'Workout posted publicly! Post ID: ${postId.substring(0, 8)}...' : 'Workout posted! Post ID: ${postId.substring(0, 8)}...')
                  : (isPublic ? 'Workout posted publicly!' : 'Workout posted!')
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Navigate to home after posting
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/', // Home route
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post workout: $e')),
        );
      }
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
          final status = workoutLog['status'] as String? ?? 'UNKNOWN';
          final isInProgress = status.toUpperCase() == 'IN_PROGRESS';
          final isCompleted = status.toUpperCase() == 'COMPLETED';

          return Scaffold(
            // Show appropriate FAB based on workout status
            floatingActionButton: isInProgress 
                ? FloatingActionButton.extended(
                    onPressed: _showFinishWorkoutDialog,
                    icon: const Icon(Icons.check),
                    label: const Text('Finish Workout'),
                    backgroundColor: Colors.green,
                  )
                : isCompleted 
                    ? FloatingActionButton.extended(
                        onPressed: _showPostWorkoutDialog,
                        icon: const Icon(Icons.share),
                        label: const Text('Post Workout'),
                        backgroundColor: Colors.blue,
                      )
                    : null,
            body: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                // Workout Summary Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Workout Summary', style: Theme.of(context).textTheme.titleLarge),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: status.toUpperCase() == 'COMPLETED' ? Colors.green : 
                                       status.toUpperCase() == 'IN_PROGRESS' ? Colors.orange : Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
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
                        if (!isInProgress && workoutLog['endedAt'] != null)
                          Text('Ended: ${workoutLog['endedAt']}'),
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
                                  isReadOnly: !isInProgress, // Make read-only for completed workouts
                                  onUpdate: isInProgress ? (reps, weight, rpe) {
                                    // Update this specific set - only for in-progress workouts
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
                                  } : null,
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
            ),
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
  final bool isReadOnly; // NEW: read-only mode
  final Function(int reps, double? weight, int rpe)? onUpdate;

  const SetProgressItem({
    Key? key,
    required this.setNumber,
    required this.plannedReps,
    this.plannedWeight,
    this.actualReps,
    this.actualWeight,
    required this.completed,
    this.isReadOnly = false, // NEW
    this.onUpdate,
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
    widget.onUpdate?.call(reps, weight, rpe);
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
                    readOnly: widget.isReadOnly, // NEW: make read-only
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
                    readOnly: widget.isReadOnly, // NEW: make read-only
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
                    readOnly: widget.isReadOnly, // NEW: make read-only
                  ),
                ),
                const SizedBox(width: 8),
                // Only show update button for editable sets
                if (!widget.isReadOnly && widget.onUpdate != null)
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
