import 'package:flutter/material.dart';
import '../../../widgets/app_bar.dart';
import '../../home/data/profile_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/bar_chart_widget.dart';
import '../data/progress_repository.dart'; // new import
import './tab/select_workouts_tab.dart'; // navigation target
import '../widgets/sessions_section.dart'; // added
import '../data/session_repository.dart'; // add import
import 'tab/workout_logs_tab.dart';
import 'package:heracle/route.dart';
import '../../feed/data/stories_repository.dart';
import '../../feed/presentation/tab/my_story_viewer.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final ProgressRepository _progressRepository = ProgressRepository();
  final StoriesRepository _storiesRepository = StoriesRepository();
  Profile? _profile;
  bool _isLoading = true;
  List<ChartData> _chartData = [];
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _profileRepository.getProfile(),
        _progressRepository.getWeeklyActivity(),
        _progressRepository.getTodayNutrition(),
        _progressRepository.getMonthlyProgress(),
      ]);

      final profile = results[0] as Profile;
      final weeklyValues = results[1] as List<double>;
      final nutritionValues = results[2] as Map<String, double>;
      final monthlyValues = results[3] as List<double>;

      const weeklyLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const monthlyLabels = ['W1', 'W2', 'W3', 'W4'];

      final weeklyData = ChartData(
        title: 'Weekly Activity',
        data: List.generate(weeklyValues.length, (i) => BarData(label: weeklyLabels[i], value: weeklyValues[i])),
        type: ChartType.bar,
      );

      final nutritionData = ChartData(
        title: "Today's Nutrition",
        data: [
          BarData(label: 'Calories', value: nutritionValues['calories']!),
          BarData(label: 'Protein', value: nutritionValues['protein']!),
          BarData(label: 'Carbs', value: nutritionValues['carbs']!),
          BarData(label: 'Fats', value: nutritionValues['fats']!),
        ],
        type: ChartType.pie,
      );

      final monthlyData = ChartData(
        title: 'Monthly Progress',
        data: List.generate(monthlyValues.length, (i) => BarData(label: monthlyLabels[i], value: monthlyValues[i])),
        type: ChartType.area,
      );

      setState(() {
        _profile = profile;
        _chartData = [weeklyData, nutritionData, monthlyData];
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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
      print('Failed to open story: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (_profile != null)
                    CustomAppBar(
                      name: _profile!.name,
                      age: _profile!.age,
                      profileImageUrl: _profile!.profileImageUrl,
                      hasStory: _profile!.hasStory,
                      onProfileTap: () {
                        Navigator.pushNamed(
                          context, 
                          AppRoutes.profile,
                          arguments: _profile!.username,
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
                              // Navigate to select workouts tab/page (start empty session)
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => SelectWorkoutsTab(mode: 'start')),
                              );
                              // refresh sessions section after returning
                              setState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size.fromHeight(48),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add, color: Colors.black, size: 20),
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
                              // Navigate to select workouts tab/page (create workout)
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => SelectWorkoutsTab(mode: 'create')),
                              );
                              // refresh sessions section if session was created
                              if (result == true) {
                                setState(() {
                                  _refreshKey++;
                                });
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary, width: 1.6),
                              minimumSize: const Size.fromHeight(48),
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
                  // Sessions section (moved to its own widget & data layer)
                  SessionsSection(
                    key: ValueKey(_refreshKey),
                    repository: SessionRepository(),
                  ),
                ],
              ),
            ),
    );
  }
}