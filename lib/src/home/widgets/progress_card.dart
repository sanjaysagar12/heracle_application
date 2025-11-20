import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class TodayProgressCard extends StatelessWidget {
  final int workoutsLeft;
  final int steps;
  final int calsBurned;
  final int calsTaken;
  final int proteinTaken;

  const TodayProgressCard({
    super.key,
    required this.workoutsLeft,
    this.steps = 0,
    this.calsBurned = 0,
    this.calsTaken = 0,
    this.proteinTaken = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildWorkoutHeader(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(child: _buildStatCard('Steps', steps, Icons.directions_walk, false)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Cals Burned', calsBurned, Icons.local_fire_department, false)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Cals Taken', calsTaken, Icons.restaurant, true)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Protein Taken', proteinTaken, Icons.egg, true, unit: 'g')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: 0.7,
                  strokeWidth: 3,
                  backgroundColor: AppColors.greyDark,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const Icon(
                Icons.fitness_center,
                color: AppColors.primary,
                size: 24,
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workout Progress',
                  style: TextStyle(
                    color: AppColors.pureWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$workoutsLeft Workouts left',
                  style: const TextStyle(
                    color: AppColors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Navigate to Biceps workout
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Biceps',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                Transform.rotate(
                  angle: -0.785398, // -45 degrees in radians
                  child: const Icon(
                    Icons.arrow_forward,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, bool isHighlighted, {String unit = ''}) {
    final displayValue = unit.isNotEmpty ? '$value$unit' : value.toString();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayValue,
            style: const TextStyle(
              color: AppColors.pureWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white60,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    value: isHighlighted ? 0.65 : 0,
                    strokeWidth: 2.5,
                    backgroundColor: AppColors.greyLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isHighlighted ? AppColors.primary : AppColors.greyLight,
                    ),
                  ),
                ),
                Icon(
                  icon,
                  color: isHighlighted ? AppColors.primary : AppColors.white40,
                  size: 20,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
