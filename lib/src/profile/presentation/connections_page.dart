import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../profile/data/profile_repository.dart';
import '../../../route.dart';

class ConnectionsPage extends StatefulWidget {
  final int initialIndex;
  final String username;

  const ConnectionsPage({
    super.key,
    this.initialIndex = 0,
    required this.username,
  });

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProfileRepository _repository = ProfileRepository();
  
  List<ConnectionUser> _followers = [];
  List<ConnectionUser> _following = [];
  bool _isLoadingFollowers = true;
  bool _isLoadingFollowing = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
    _loadData();
  }

  Future<void> _loadData() async {
    // Load both lists
    _loadFollowers();
    _loadFollowing();
  }

  Future<void> _loadFollowers() async {
    try {
      final data = await _repository.getFollowers();
      if (mounted) {
        setState(() {
          _followers = data;
          _isLoadingFollowers = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingFollowers = false);
    }
  }

  Future<void> _loadFollowing() async {
    try {
      final data = await _repository.getFollowing();
      if (mounted) {
        setState(() {
          _following = data;
          _isLoadingFollowing = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingFollowing = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back.svg',
            color: AppColors.pureWhite,
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.username,
          style: const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold),
        ),
        // Actually, typically Title is username, but let's stick to Tabs handling content
        // We'll hide title change logic or just put "Sanjay Sagar" as title
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserList(_followers, _isLoadingFollowers, 'No followers yet'),
          _buildUserList(_following, _isLoadingFollowing, 'Not following anyone'),
        ],
      ),
    );
  }

  Widget _buildUserList(List<ConnectionUser> users, bool isLoading, String emptyMessage) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (users.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: AppColors.white60, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.profile,
              arguments: user.username,
            );
          },
          leading: CircleAvatar(
            backgroundImage: NetworkImage(user.profileImageUrl),
            radius: 24,
          ),
          title: Text(
            user.username, // Using username as main display or name? usually name then username
            style: const TextStyle(color: AppColors.pureWhite, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            user.name,
            style: const TextStyle(color: AppColors.white60),
          ),
          trailing: _buildActionButton(user),
        );
      },
    );
  }

  Widget _buildActionButton(ConnectionUser user) {
    final isFollowing = user.isFollowing;

    return SizedBox(
      height: 32,
      child: ElevatedButton(
        onPressed: () => _toggleConnectionFollow(user),
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing ? AppColors.greyLight : AppColors.primary,
          foregroundColor: isFollowing ? AppColors.pureWhite : AppColors.black,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: Text(
          isFollowing ? 'Following' : 'Follow',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _toggleConnectionFollow(ConnectionUser user) {
    setState(() {
      // Update in followers list if present
      final followerIndex = _followers.indexWhere((u) => u.id == user.id);
      if (followerIndex != -1) {
        _followers[followerIndex] = _followers[followerIndex].copyWith(
          isFollowing: !user.isFollowing,
        );
      }

      // Update in following list if present
      final followingIndex = _following.indexWhere((u) => u.id == user.id);
      if (followingIndex != -1) {
        _following[followingIndex] = _following[followingIndex].copyWith(
          isFollowing: !user.isFollowing,
        );
      }
    });

    // Ideally, call API here to persist changes
    // _repository.followUser(user.id);
  }
}
