import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../data/profile_repository.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_tab_bar.dart';
import '../widgets/highlight_grid.dart';
import '../widgets/profile_skeleton.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileRepository _repository = ProfileRepository();
  
  UserProfile? _profile;
  List<HighlightVideo> _highlights = [];
  
  bool _isLoading = true;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _repository.getUserProfile(),
        _repository.getAllHighlights(),
      ]);

      setState(() {
        _profile = results[0] as UserProfile;
        _highlights = results[1] as List<HighlightVideo>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  void _onFollowTap() {
    if (_profile != null) {
      setState(() {
        _profile = _repository.toggleFollow(_profile!);
      });
    }
  }

  void _onHighlightTap(HighlightVideo highlight) {
    // TODO: Navigate to video player or detail view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing: ${highlight.formattedViews}'),
        backgroundColor: AppColors.greyDark,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.pureWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.pureWhite),
            onPressed: () {
              // TODO: Show options menu
            },
          ),
        ],
      ),
      body: _isLoading
          ? const ProfileSkeleton()
          : RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              backgroundColor: AppColors.greyDark,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Profile Header
                    if (_profile != null)
                      ProfileHeader(
                        profile: _profile!,
                        onFollowTap: _onFollowTap,
                      ),
                    // Tab Bar
                    ProfileTabBar(
                      selectedIndex: _selectedTabIndex,
                      onTabSelected: _onTabSelected,
                    ),
                    // Content based on selected tab
                    _buildTabContent(),
                    // Bottom padding for nav bar
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _buildHighlightsTab();
      case 1:
        return _buildSessionsTab();
      case 2:
        return _buildPostsTab();
      default:
        return _buildHighlightsTab();
    }
  }

  Widget _buildHighlightsTab() {
    return Column(
      children: [
        // Highlights grid
        HighlightGrid(
          highlights: _highlights,
          onHighlightTap: _onHighlightTap,
        ),
      ],
    );
  }

  Widget _buildSessionsTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Text(
          'Sessions coming soon',
          style: TextStyle(
            color: AppColors.white60,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Text(
          'Posts coming soon',
          style: TextStyle(
            color: AppColors.white60,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
