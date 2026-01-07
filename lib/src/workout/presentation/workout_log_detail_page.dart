import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/session_repository.dart';

class WorkoutLogDetailPage extends StatelessWidget {
  final WorkoutLog log;

  const WorkoutLogDetailPage({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        title: Text(log.title, style: const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.pureWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: log.exercises.length,
        itemBuilder: (context, index) {
          final exercise = log.exercises[index];
          return _buildExerciseCard(exercise);
        },
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise) {
    final sets = exercise['sets'] as List<dynamic>? ?? [];
    final name = exercise['name']?.toString() ?? 'Exercise';
    final image = exercise['image']?.toString() ?? '';
    final desc = exercise['desc']?.toString() ?? ''; // Assuming desc holds muscle group or generic desc

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
          // Header: Image + Name + Desc
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.pureWhite,
                  image: image.isNotEmpty
                      ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover)
                      : null,
                ),
                child: image.isEmpty
                    ? const Icon(Icons.fitness_center, color: AppColors.black)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (desc.isNotEmpty)
                      Text(
                        desc,
                        style: const TextStyle(
                          color: AppColors.white60,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Sets List
          ...sets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value as Map<String, dynamic>;
            final weight = set['kg']?.toString() ?? '0';
            final reps = set['reps']?.toString() ?? '0';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                   // Set Label
                   SizedBox(
                     width: 60,
                     child: Text(
                       'Set ${index + 1}',
                       style: const TextStyle(
                         color: Color(0xFFD0FD3E), // Neon yellow/green
                         fontSize: 14,
                         fontWeight: FontWeight.w600,
                       ),
                     ),
                   ),
                   const Spacer(),
                   
                   // Weight
                   const Text('Weight', style: TextStyle(color: AppColors.pureWhite, fontSize: 14)),
                   const SizedBox(width: 12),
                   _buildValueBox(weight),
                   
                   const SizedBox(width: 24),

                   // Reps
                   const Text('Reps', style: TextStyle(color: AppColors.pureWhite, fontSize: 14)),
                   const SizedBox(width: 12),
                   _buildValueBox(reps),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildValueBox(String value) {
    return Container(
      width: 50,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E), // Darker grey for inputs
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(
        value,
        style: const TextStyle(
          color: AppColors.pureWhite,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
