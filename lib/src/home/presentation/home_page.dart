import 'package:flutter/material.dart';
import '../../../widgets/app_bar.dart';
import '../data/profile_repository.dart';
import '../data/progress_repository.dart';
import '../data/mutual_feed_repository.dart';
import 'widgets/progress_card.dart';
import 'widgets/track_mutuals_section.dart';
import '../../../core/theme/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final ProgressRepository _progressRepository = ProgressRepository();
  final MutualFeedRepository _mutualFeedRepository = MutualFeedRepository();
  Profile? _profile;
  ProgressCard? _progress;
  List<FeedPost> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _profileRepository.getProfile(),
        _progressRepository.getTodayProgress(),
        _mutualFeedRepository.getMutualFeed(),
      ]);

      setState(() {
        _profile = results[0] as Profile;
        _progress = results[1] as ProgressCard;
        _posts = results[2] as List<FeedPost>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
      print('Error loading data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: _isLoading || _profile == null
          ? null
          : CustomAppBar(
              name: _profile!.name,
              age: _profile!.age,
              profileImageUrl: _profile!.profileImageUrl,
            ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (_progress != null)
                    TodayProgressCard(
                      workoutsLeft: _progress!.workoutsLeft,
                      steps: _progress!.steps,
                      calsBurned: _progress!.calsBurned,
                      calsTaken: _progress!.calsTaken,
                      proteinTaken: _progress!.proteinTaken,
                    ),
                  TrackMutualsSection(posts: _posts),
                ],
              ),
            ),
    );
  }
}