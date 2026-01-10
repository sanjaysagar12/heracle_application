import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../nutrition/presentation/track_calories_page.dart';
import '../../nutrition/presentation/diet_history_page.dart';
import '../presentation/steps_history_page.dart';
import 'target_settings_bottom_sheet.dart';

import '../../workout/storage/streak_storage.dart'; // Added

class TodayProgressCard extends StatelessWidget {
  final String workoutsLeft;
  final String steps;
  final String calsBurned;
  final String calsTaken;
  // removed proteinTaken string, but keeping it in constructor if needed for compatibility or just ignoring it
  final double stepsProgress;
  final double calsBurnedProgress;
  final double calsTakenProgress;
  // removed proteinTakenProgress
  final Function(String, int)? onTargetUpdate;
  final VoidCallback? onRefresh;
  final int actualSteps;
  final int actualCalsBurned;
  final int actualCalsTaken;
  // params for streak
  final int streak;
  final int breakDaysUsed;
  final int maxBreakDays;
  final Map<String, int> targets;

  const TodayProgressCard({
    super.key,
    required this.workoutsLeft,
    this.steps = '0',
    this.calsBurned = '0',
    this.calsTaken = '0',
    String proteinTaken = '0', // Keep for compatibility but don't use
    this.stepsProgress = 0.0,
    this.calsBurnedProgress = 0.0,
    this.calsTakenProgress = 0.0,
    double proteinTakenProgress = 0.0, // Keep for compatibility
    this.onTargetUpdate,
    this.onRefresh,
    this.actualSteps = 0,
    this.actualCalsBurned = 0,
    this.actualCalsTaken = 0,
    int actualProteinTaken = 0, // Keep
    this.streak = 0, // Added
    this.breakDaysUsed = 0, // Added
    this.maxBreakDays = 3, // Added
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
        onHistoryTap: () {
            // Determine which history page to show
            if (targetType == 'Steps' || targetType == 'Cals Burned') {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StepsHistoryPage()),
              );
            } else if (targetType == 'Cals Taken') {
               Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DietHistoryPage()),
              );
            }
        },
      ),
    );
  }
  
  Future<void> _handleStreakTap(BuildContext context) async {
    // Show dialog to set break day
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.black100,
          title: const Text('Streak & Break Days', style: TextStyle(color: AppColors.pureWhite)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Streak: $streak days',
                style: const TextStyle(color: AppColors.primary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Break Days Used:',
                style: TextStyle(color: AppColors.white60),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(maxBreakDays, (index) {
                  final isUsed = index < breakDaysUsed;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: isUsed ? Colors.redAccent : AppColors.greyDark,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUsed ? Icons.close : Icons.check,
                      color: AppColors.pureWhite,
                      size: 16,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                '$breakDaysUsed / $maxBreakDays break days used this week.',
                style: const TextStyle(color: AppColors.white60, fontSize: 12),
              ),
              const SizedBox(height: 24),
              const Text(
                'Need a break today? You can take up to 3 break days a week to maintain your streak.',
                style: TextStyle(color: AppColors.white60),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.white60)),
            ),
            TextButton(
              onPressed: () async {
                if (breakDaysUsed >= maxBreakDays) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No break days remaining for this week!')),
                  );
                  Navigator.pop(context);
                  return;
                }
                
                final success = await StreakStorage().setBreakDay();
                if (success) {
                   if (context.mounted) Navigator.pop(context, true);
                } else {
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cannot set break day (Already worked out or limit reached)')),
                     );
                     Navigator.pop(context);
                   }
                }
              },
              child: const Text('Take Break Day', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        );
      },
    );
    
    if (result == true) {
      onRefresh?.call();
    }
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
              // Replaced Protein with Streak
              Expanded(
                child: GestureDetector(
                  onTap: () => _handleStreakTap(context),
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
                          '$streak',
                          style: const TextStyle(
                            color: AppColors.pureWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Streak',
                          style: TextStyle(
                            color: AppColors.white60,
                            fontSize: 10,
                          ),
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
                                  value: 1.0, // Always full circle or use break days?
                                  // Maybe show break days remaining progress?
                                  // Or just show fire icon?
                                  // Let's show break days *usage* as inverse progress? 
                                  // Or just show 1.0 for "active".
                                  strokeWidth: 2.5,
                                  backgroundColor: AppColors.greyLight,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                ),
                              ),
                              const Icon(
                                Icons.local_fire_department_outlined, // Streak icon
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutHeader(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TrackCaloriesPage()),
        );
        if (result == true) {
          onRefresh?.call(); // Call refresh callback
        }
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced padding
        decoration: BoxDecoration(
          color: AppColors.black100,
          borderRadius: BorderRadius.circular(20), // Slightly reduced radius
          border: Border.all(color: AppColors.white10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(0),
              child: SvgPicture.asset(
                'assets/icons/trackcal.svg',
                width: 32, // Reduced size
                height: 32,
              ),
            ),
            const SizedBox(width: 12), // Reduced gap
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Track Your Food',
                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 16, // Reduced font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2), // Reduced height
                  Text(
                    'Check cals, protein, fat, carbs...',
                    style: TextStyle(
                      color: AppColors.white60,
                      fontSize: 12, // Reduced font size
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
