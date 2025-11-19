import 'package:flutter/material.dart';
import '../../../widgets/app_bar.dart';
import '../../home/data/profile_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/bar_chart_card.dart';

class WorkoutPage extends StatefulWidget {
  const WorkoutPage({super.key});

  @override
  State<WorkoutPage> createState() => _WorkoutPageState();
}

class _WorkoutPageState extends State<WorkoutPage> {
  final ProfileRepository _profileRepository = ProfileRepository();
  Profile? _profile;
  bool _isLoading = true;
  // sample bar data for the chart
  final List<BarData> _weeklyBarData = const [
    BarData(label: 'Mon', value: 40),
    BarData(label: 'Tue', value: 60),
    BarData(label: 'Wed', value: 30),
    BarData(label: 'Thu', value: 80),
    BarData(label: 'Fri', value: 55),
    BarData(label: 'Sat', value: 70),
    BarData(label: 'Sun', value: 50),
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileRepository.getProfile();
      setState(() {
        _profile = profile;
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
                  // bar chart card showing weekly data
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