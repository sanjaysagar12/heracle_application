import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import '../../feed/api/workout_posts_api.dart';
import '../../feed/domain/models/workout_post_model.dart';
import '../../config/api_endpoints.dart'; // <--- added import

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<WorkoutPost>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _refreshPosts();
  }

  void _refreshPosts() {
    setState(() {
      _postsFuture = WorkoutPostsApi.fetchWorkoutPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      extendBody: true,
      bottomNavigationBar: const FloatingNavBar(),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Positioned.fill(
                  child: SvgPicture.asset(
                    'assets/images/home_hero.svg',
                    fit: BoxFit.cover,
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildProfileHeader(),
                        const SizedBox(height: 20),
                        _buildWorkoutProgressCard(),
                        const SizedBox(height: 20),
                        _buildStatsCards(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Posts section
          SliverToBoxAdapter(
            child: Container(
              color: const Color.fromARGB(255, 0, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Track Mutuals',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTrackingOptions(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // Use FutureBuilder to show backend posts
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: FutureBuilder<List<WorkoutPost>>(
                      future: _postsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              children: [
                                Text('Error loading posts: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                                const SizedBox(height: 8),
                                ElevatedButton(onPressed: _refreshPosts, child: const Text('Retry')),
                              ],
                            ),
                          );
                        }
                        final posts = snapshot.data ?? <WorkoutPost>[];
                        if (posts.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: Text('No workout posts found.', style: TextStyle(color: Colors.white70)),
                            ),
                          );
                        }
                        return Column(
                          children: posts.map((p) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: WorkoutPostCard(post: p),
                          )).toList(),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: const AssetImage('assets/images/home/profile.jpg'),
              backgroundColor: Colors.grey[800],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Sanjay Mogger N',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ],
                ),
                const Text(
                  '20 years old',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _buildIconButton(Icons.notifications_outlined, isActive: false),
            const SizedBox(width: 12),
            _buildIconButton(Icons.local_fire_department, isActive: true),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.orange.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: isActive ? Colors.orange : Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildWorkoutProgressCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(
                height: 60,
                width: 60,
                child: Stack(
                  children: [
                    SizedBox(
                      height: 60,
                      width: 60,
                      child: CustomPaint(
                        painter: CircleProgressPainter(
                          progress: 0.7,
                          progressColor: const Color(0xFFF84959),
                          backgroundColor: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                    ),
                    Center(
                      child: Icon(
                        Icons.fitness_center,
                        color: const Color(0xFFF84959),
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workout Progress',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '10 Workouts left',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Biceps',
                style: TextStyle(
                  color: Color(0xFFF84959),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.arrow_outward,
                color: const Color(0xFFF84959),
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard('0', 'Steps', Icons.directions_walk, 0.0),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard('0', 'Cals Burned', Icons.local_fire_department, 0.0),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard('1200', 'Cals Taken', Icons.restaurant, 0.8, isActive: true),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard('76g', 'Protein Taken', Icons.fitness_center, 0.6, isActive: true),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, double progress, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            width: 60,
            child: Stack(
              children: [
                SizedBox(
                  height: 60,
                  width: 60,
                  child: CustomPaint(
                    painter: CircleProgressPainter(
                      progress: progress,
                      progressColor: isActive ? const Color(0xFFF84959) : Colors.grey.withOpacity(0.3),
                      backgroundColor: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    icon,
                    color: isActive ? const Color(0xFFF84959) : Colors.grey,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingOptions() {
    return Row(
      children: [
        _buildTrackingButton('All', isActive: true),
        const SizedBox(width: 8),
        _buildTrackingButton('Friends'),
        const SizedBox(width: 8),
        _buildTrackingButton('PRs'),
        const SizedBox(width: 8),
        _buildTrackingButton('Challenges'),
      ],
    );
  }

  Widget _buildTrackingButton(String text, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFF84959) : const Color(0xFF252525),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

// Renamed widget to avoid name collision with domain model
class WorkoutPostCard extends StatelessWidget {
  final WorkoutPost post;

  const WorkoutPostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF181818),
        borderRadius: BorderRadius.all(Radius.circular(16.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info and timestamp
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[800],
                backgroundImage: post.user.avatarUrl != null ? NetworkImage(post.user.avatarUrl!) as ImageProvider : const AssetImage('assets/images/home/profile.jpg'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          post.user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatDate(post.createdAt),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '@${post.user.username}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Caption
          if (post.caption.isNotEmpty)
            Text(
              post.caption,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
          if (post.caption.isNotEmpty) const SizedBox(height: 12),

          // NEW: Workout image (uses signed headers if available)
          if (post.imageS3Key != null) ...[
            AspectRatio(
              aspectRatio: 16/9,
              child: FutureBuilder<Map<String, String>>(
                future: WorkoutPostsApi.getImageHeaders(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final imageUrl = workoutPostImageUrl(post.id);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        headers: snapshot.data,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[900],
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[900],
                            child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 48)),
                          );
                        },
                      ),
                    );
                  }
                  return Container(
                    color: Colors.grey[900],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Workout stats
          Row(
            children: [
              _buildStatItem('Duration', '${post.workoutSummary.totalTimeMin.toInt()}min'),
              _buildStatItem('Volume', '${post.workoutSummary.totalVolume}'),
              _buildStatItem('Sets', '${post.workoutSummary.totalSets}'),
              _buildStatItem('Reps', '${post.workoutSummary.totalReps}'),
            ],
          ),
          const SizedBox(height: 12),

          // Exercises list (show names)
          if (post.workoutSummary.exercises.isNotEmpty)
            ...post.workoutSummary.exercises.take(4).map((e) => _buildExerciseItem(e.actualSets, e.exercise.name)),

          if (post.workoutSummary.exercises.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
              child: Text(
                'See ${post.workoutSummary.exercises.length - 4} more exercises',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
              ),
            ),

          // Bottom interaction row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Likes section
              Row(
                children: [
                  Icon(post.isLikedByUser ? Icons.favorite : Icons.favorite_border, color: post.isLikedByUser ? const Color(0xFFF84959) : Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    post.likesCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              // Comment and share
              Row(
                children: [
                  Icon(Icons.comment_outlined, color: Colors.white.withOpacity(0.7), size: 22),
                  const SizedBox(width: 16),
                  Icon(Icons.share_outlined, color: Colors.white.withOpacity(0.7), size: 22),
                ],
              ),
            ],
          ),

          // Liked by / placeholder
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/home/profile.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Liked by ${post.likesCount > 0 ? 'someone' : 'no one yet'}',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(int sets, String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                sets.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$sets sets $name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  CircleProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width / 2, size.height / 2) - 4;
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0;

    canvas.drawCircle(center, radius, backgroundPaint);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      width: 332,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(40.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(icon: Icons.home_filled, isSelected: true),
          _buildNavItem(icon: Icons.photo_camera_outlined, isSelected: false),
          _buildNavItem(icon: Icons.chat_bubble_outline_rounded, isSelected: false),
          _buildNavItem(icon: Icons.person_outline_rounded, isSelected: false),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required bool isSelected}) {
    return Container(
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? const Color(0xFFF84959) : Colors.transparent,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey,
            size: 28,
          ),
        ],
      ),
    );
  }
}
