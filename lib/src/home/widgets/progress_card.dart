import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'target_settings_bottom_sheet.dart';

class TodayProgressCard extends StatelessWidget {
  final String workoutsLeft;
  final String steps;
  final String calsBurned;
  final String calsTaken;
  final String proteinTaken;
  final double stepsProgress;
  final double calsBurnedProgress;
  final double calsTakenProgress;
  final double proteinTakenProgress;
  final Function(String, int)? onTargetUpdate;
  // Add these new properties
  final int actualSteps;
  final int actualCalsBurned;
  final int actualCalsTaken;
  final int actualProteinTaken;
  final Map<String, int> targets;

  const TodayProgressCard({
    super.key,
    required this.workoutsLeft,
    this.steps = '0',
    this.calsBurned = '0',
    this.calsTaken = '0',
    this.proteinTaken = '0',
    this.stepsProgress = 0.0,
    this.calsBurnedProgress = 0.0,
    this.calsTakenProgress = 0.0,
    this.proteinTakenProgress = 0.0,
    this.onTargetUpdate,
    this.actualSteps = 0,
    this.actualCalsBurned = 0,
    this.actualCalsTaken = 0,
    this.actualProteinTaken = 0,
    this.targets = const {},
  });

  void _showTargetSettings(BuildContext context, String targetType, String currentValue,
      int currentTarget, String unit, IconData icon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TargetSettingsBottomSheet(
        targetType: targetType,
        currentValue: currentValue,
        currentTarget: currentTarget,
        unit: unit,
        icon: icon,
        onSave: (newTarget) async {
          if (onTargetUpdate != null) {
            await onTargetUpdate!(targetType.toLowerCase().replaceAll(' ', '_'), newTarget);
          }
        },
      ),
    );
  }

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
              Expanded(child: _buildStatCard(context, 'Steps', steps, Icons.directions_walk, steps != '0', stepsProgress, actualSteps, targets['steps'] ?? 10000)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, 'Cals Burned', calsBurned, Icons.local_fire_department, calsBurned != '0', calsBurnedProgress, actualCalsBurned, targets['cals_burned'] ?? 500)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, 'Cals Taken', calsTaken, Icons.restaurant, calsTaken != '0', calsTakenProgress, actualCalsTaken, targets['cals_taken'] ?? 2000)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard(context, 'Protein Taken', proteinTaken, Icons.egg, proteinTaken != '0', proteinTakenProgress, actualProteinTaken, targets['protein_taken'] ?? 150, unit: 'g')),
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

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, bool isHighlighted, double progress, int actualValue, int targetValue, {String unit = ''}) {
    final displayValue = unit.isNotEmpty ? '$value$unit' : value;

    return GestureDetector(
      onTap: () => _showTargetSettings(
        context,
        label,
        displayValue,
        targetValue, // Use the actual target value from database
        unit,
        icon,
      ),
      child: Container(
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
                fontSize: 16,
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
                      value: progress,
                      strokeWidth: 2.5,
                      backgroundColor: AppColors.greyLight,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isHighlighted ? AppColors.primary : AppColors.white40,
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
      ),
    );
  }
}
