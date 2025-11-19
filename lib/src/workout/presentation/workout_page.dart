import 'package:flutter/material.dart';
import '../../../widgets/app_bar.dart';
import '../../home/data/profile_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/bar_chart_card.dart';
import '../data/progress_repository.dart'; // new import

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
                  const Center(
                    child: Text(
                      "Workout Page",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}