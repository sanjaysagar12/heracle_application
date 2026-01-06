import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../nutrition/presentation/track_calories_page.dart';
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
        _buildWorkoutHeader(context),
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

  Widget _buildWorkoutHeader(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TrackCaloriesPage()),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.black100,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(0),
              child: SvgPicture.asset(
                'assets/icons/trackcal.svg',
                width: 40,
                height: 40,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track Your Food',
                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Check cals, protein, fat, carbs...',
                    style: TextStyle(
                      color: AppColors.white60,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const Row(
              children: [
                Text(
                  'Track now',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_outward,
                  color: AppColors.primary,
                  size: 16,
                ),
              ],
            ),
          ],
        ),
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
