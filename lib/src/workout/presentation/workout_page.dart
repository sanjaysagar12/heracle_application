import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/app_bar.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/bar_chart_widget.dart';
import '../../home/data/progress_repository.dart';
import './tab/select_workouts_tab.dart';
import '../widgets/sessions_section.dart';
import '../data/session_repository.dart';
import 'package:heracle/route.dart';
import '../../feed/data/stories_repository.dart';
import '../../feed/presentation/tab/my_story_viewer.dart';
import '../../home/providers/user_profile_provider.dart';
import '../data/draft_repository.dart';
import 'dart:convert';
import './tab/log_workout_tab.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => WorkoutPageState();
}

class WorkoutPageState extends State<WorkoutPage> {
  final ProgressRepository _progressRepository = ProgressRepository();
  final StoriesRepository _storiesRepository = StoriesRepository();

  bool _isLoading = true;
  List<ChartData> _chartData = [];
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Public method to refresh data (called from App scaffold)
  Future<void> refresh() async {
    await _loadData();
  }

  Future<void> _loadData() async {
    // Load profile via provider
    final profileProvider = context.read<UserProfileProvider>();
    if (!profileProvider.hasProfile) {
      await profileProvider.loadProfile();
    }

    // Load Stats
    try {
      final results = await Future.wait([
        _progressRepository.getWeeklyActivity(),
        _progressRepository.getTodayNutrition(),
        _progressRepository.getMonthlyProgress(),
      ]);

      final weeklyValues = results[0] as List<double>;
      final nutritionValues = results[1] as Map<String, double>;
      final monthlyValues = results[2] as List<double>;

      const weeklyLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const monthlyLabels = ['W1', 'W2', 'W3', 'W4'];

      final weeklyData = ChartData(
        title: 'Weekly Activity',
        data: List.generate(
          weeklyValues.length,
          (i) => BarData(label: weeklyLabels[i], value: weeklyValues[i]),
        ),
        type: ChartType.bar,
      );

      final nutritionData = ChartData(
        title: "Today's Nutrition",
        data: [
          BarData(label: 'Calories', value: nutritionValues['calories'] ?? 0),
          BarData(label: 'Protein', value: nutritionValues['protein'] ?? 0),
          BarData(label: 'Carbs', value: nutritionValues['carbs'] ?? 0),
          BarData(label: 'Fats', value: nutritionValues['fat'] ?? 0),
        ],
        type: ChartType.pie,
      );

      final monthlyData = ChartData(
        title: 'Monthly Progress',
        data: List.generate(
          monthlyValues.length,
          (i) => BarData(label: monthlyLabels[i], value: monthlyValues[i]),
        ),
        type: ChartType.area,
      );

      if (mounted) {
        setState(() {
          _chartData = [weeklyData, nutritionData, monthlyData];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('WorkoutPage: Failed to load stats: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleStoryTap() async {
    try {
      final myStory = await _storiesRepository.getMyStories();
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyStoryViewer(myStory: myStory),
        ),
      );
    } catch (e) {
      debugPrint('Failed to open story: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, profileProvider, child) {
        final profile = profileProvider.profile;

        return Scaffold(
          backgroundColor: AppColors.black,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      if (profile != null)
                        CustomAppBar(
                          name: profile.name,
                          age: profile.age,
                          profileImageUrl: profile.profileImageUrl,
                          hasStory: profile.hasStory,
                          onProfileTap: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.profile,
                              arguments: profile.username,
                            );
                          },
                          onStoryTap: _handleStoryTap,
                        ),
                      // bar chart carousel showing multiple progress charts
                      BarChartCard(charts: _chartData),
                      const SizedBox(height: 16),
                      // Action buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final draftRepo = DraftRepository();
                                  final hasDraft = await draftRepo.hasDraft();

                                  if (hasDraft && context.mounted) {
                                     final shouldResume = await showDialog<String>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                           backgroundColor: AppColors.black100,
                                           title: const Text('Unfinished Workout', style: TextStyle(color: AppColors.pureWhite)),
                                           content: const Text('You have an unfinished workout session. Do you want to resume it or start a new empty one?', style: TextStyle(color: AppColors.white60)),
                                           actions: [
                                              TextButton(
                                                 onPressed: () => Navigator.pop(ctx, 'new'),
                                                 child: const Text('Start New', style: TextStyle(color: AppColors.white60)),
                                              ),
                                              TextButton(
                                                 onPressed: () => Navigator.pop(ctx, 'resume'),
                                                 child: const Text('Resume', style: TextStyle(color: AppColors.primary)),
                                              ),
                                           ],
                                        ),
                                     );

                                     if (shouldResume == 'resume') {
                                         final draft = await draftRepo.getDraft();
                                         if (draft != null && context.mounted) {
                                            final exercises = List<Map<String, dynamic>>.from(jsonDecode(draft.data));
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => LogWorkoutTab(
                                                  mode: 'resume',
                                                  exercises: exercises,
                                                  sessionId: draft.sessionId,
                                                  sessionName: draft.sessionName,
                                                ),
                                              ),
                                            );
                                            await _loadData();
                                            return;
                                         }
                                     } else if (shouldResume == 'new') {
                                         await draftRepo.deleteDraft();
                                     } else {
                                         return;
                                     }
                                  }

                                  if (context.mounted) {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            SelectWorkoutsTab(mode: 'start'),
                                      ),
                                    );
                                    await _loadData();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  minimumSize: const Size.fromHeight(48),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: const StadiumBorder(),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.add,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Start Empty Session',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          SelectWorkoutsTab(mode: 'create'),
                                    ),
                                  );
                                  if (result == true) {
                                    setState(() {
                                      _refreshKey++;
                                    });
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.6,
                                  ),
                                  minimumSize: const Size.fromHeight(48),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: const Text(
                                  'Create Workout Session',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SessionsSection(
                        key: ValueKey(_refreshKey),
                        repository: SessionRepository(),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
