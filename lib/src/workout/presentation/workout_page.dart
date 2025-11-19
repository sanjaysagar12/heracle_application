import 'package:flutter/material.dart';
import '../../../widgets/app_bar.dart';
import '../../home/data/profile_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/bar_chart_card.dart';
import '../data/progress_repository.dart'; // new import
import './tab/select_workouts_tab.dart'; // navigation target
import '../widgets/sessions_section.dart'; // added

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final ProgressRepository _progressRepository = ProgressRepository(); // new repo
  Profile? _profile;
  bool _isLoading = true;
  List<BarData> _weeklyBarData = []; // will be filled from repository

  @override
  void initState() {
    super.initState();
    _loadData(); // fetch profile + weekly data
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _profileRepository.getProfile(),
        _progressRepository.getWeeklyActivity(),
      ]);

      final profile = results[0] as Profile;
      final weeklyValues = results[1] as List<double>;

      // Map weekly values to BarData with labels Mon..Sun
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final barData = List<BarData>.generate(
        weeklyValues.length,
        (i) => BarData(label: labels.length > i ? labels[i] : 'Day${i+1}', value: weeklyValues[i]),
      );

      setState(() {
        _profile = profile;
        _weeklyBarData = barData;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
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
                    ),
                  // bar chart card showing weekly data (uses fetched data)
                  BarChartCard(
                    title: 'Weekly Activity',
                    data: _weeklyBarData,
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to select workouts tab/page (start empty session)
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => SelectWorkoutsTab(mode: 'start')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              minimumSize: const Size.fromHeight(48), // reduced height
                              padding: const EdgeInsets.symmetric(vertical: 12), // reduced vertical padding
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add, color: Colors.black, size: 20), // smaller icon
                                SizedBox(width: 8),
                                Text(
                                  'Start Empty Session',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16, // smaller text
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10), // reduced gap
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              // Navigate to select workouts tab/page (create workout)
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => SelectWorkoutsTab(mode: 'create')),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary, width: 1.6),
                              minimumSize: const Size.fromHeight(48), // reduced height
                              padding: const EdgeInsets.symmetric(vertical: 12), // reduced vertical padding
                              shape: const StadiumBorder(),
                            ),
                            child: const Text(
                              'Create Workout Session',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 16, // smaller text
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
                  const SessionsSection(),
                ],
              ),
            ),
    );
  }
}