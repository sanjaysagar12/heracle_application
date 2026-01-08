import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../app.dart';
import '../data/session_repository.dart';

import '../storage/streak_storage.dart';

class ViewSessionPage extends StatefulWidget {
  final Session session;

  const ViewSessionPage({super.key, required this.session});

  @override
  State<ViewSessionPage> createState() => _ViewSessionPageState();
}

class _ViewSessionPageState extends State<ViewSessionPage> {
  final SessionRepository _sessionRepository = SessionRepository();
  final StreakStorage _streakStorage = StreakStorage();
  bool _isCopying = false;

  Future<void> _handleFinishWorkout() async {
    try {
      await _streakStorage.incrementStreak();

      // Calculate simple stats for the log
      int totalSets = 0;
      int totalVolume = 0;
      
      for (var exercise in widget.session.exercises) {
        final sets = (exercise['sets'] as List<dynamic>?) ?? [];
        totalSets += sets.length;
        for (var s in sets) {
           final weight = int.tryParse(s['kg']?.toString() ?? '0') ?? 0;
           final reps = int.tryParse(s['reps']?.toString() ?? '0') ?? 0;
           totalVolume += (weight * reps);
        }
      }

      final log = WorkoutLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sessionId: widget.session.id,
        title: widget.session.title,
        completedAt: DateTime.now(),
        duration: 45 * 60, // Dummy duration ~45 mins
        totalVolume: totalVolume,
        totalSets: totalSets,
        exercisesCount: widget.session.exercisesCount,
        exercises: widget.session.exercises,
      );

      await _sessionRepository.saveWorkoutLogToDb(log);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Workout Finished! Streak updated.'),
            backgroundColor: AppColors.primary,
             behavior: SnackBarBehavior.floating,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, true); // Return to refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error finishing workout: $e')));
      }
    }
  }

  Future<void> _handleCopySession() async {
    setState(() {
      _isCopying = true;
    });

    try {
      // Create a new session object with a new ID
      final newSession = Session(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: widget.session.title,
        content: widget.session.content,
        categories: widget.session.categories,
        exercisesCount: widget.session.exercisesCount,
        position: 0, // Should be handled by repository or added to end
        exercises: widget.session.exercises,
      );

      // Save to local database
      await _sessionRepository.saveSessionToDb(newSession);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session copied: ${newSession.title}'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );

        // Navigate to Workout Page (Tab index 3) and remove all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const AppPage(initialIndex: 3),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCopying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to copy session: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.session.title,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: widget.session.exercises.length,
                itemBuilder: (context, index) {
                  final exercise = widget.session.exercises[index];
                  return _buildExerciseCard(exercise);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Copy Session Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isCopying ? null : _handleCopySession,
                  icon: _isCopying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.copy, color: Colors.black),
                  label: Text(
                    _isCopying ? 'Copying...' : 'Copy Session',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white60,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Finish Workout Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _handleFinishWorkout,
                  icon: const Icon(Icons.check_circle, color: Colors.black),
                  label: const Text(
                    'Finish Workout',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    final sets = (exercise['sets'] as List<dynamic>?) ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.white70,
                  image: exercise['image'] != null && exercise['image'].toString().isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(exercise['image']),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: exercise['image'] == null || exercise['image'].toString().isEmpty
                    ? const Icon(Icons.fitness_center, color: Colors.black54)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise['name'] ?? 'Unknown Exercise',
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (exercise['desc'] != null && exercise['desc'].toString().isNotEmpty)
                      Text(
                        exercise['desc'],
                        style: const TextStyle(
                          color: AppColors.white60,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.more_horiz, color: AppColors.white60),
            ],
          ),
          const SizedBox(height: 20),
          ...sets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value as Map<String, dynamic>;
            // Handle different key naming if necessary, assuming kg/reps from previous context
            final weight = set['kg'] ?? set['weight'] ?? 0;
            final reps = set['reps'] ?? 0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      'Set ${index + 1}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildSetParam('Weight', weight.toString()),
                  const SizedBox(width: 32),
                  _buildSetParam('Reps', reps.toString()),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSetParam(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.white60,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.greyDark,
            borderRadius: BorderRadius.circular(6),
          ),
          constraints: const BoxConstraints(minWidth: 40),
          alignment: Alignment.center,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
