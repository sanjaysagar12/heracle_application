import 'package:flutter/material.dart';
import 'package:heracle/route.dart';
import '../../config/api_endpoints.dart';
import '../../feed/api/workout_posts_api.dart';
import '../../feed/domain/models/workout_post_model.dart';
import '../../feed/presentation/workout_post_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<WorkoutPost>> _workoutPostsFuture;

  @override
  void initState() {
    super.initState();
    _refreshFeed();
  }

  void _refreshFeed() {
    setState(() {
      _workoutPostsFuture = WorkoutPostsApi.fetchWorkoutPosts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Feed'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.fitness_center),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.session),
            tooltip: 'Sessions',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.workoutLogs),
            tooltip: 'Workout Logs',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFeed,
          ),
        ],
      ),
      body: FutureBuilder<List<WorkoutPost>>(
        future: _workoutPostsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshFeed,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          final posts = snapshot.data ?? <WorkoutPost>[];
          if (posts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No workout posts found.'),
                  Text('Complete a workout and share it to see posts here!'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              return WorkoutPostCard(post: posts[index]);
            },
          );
        },
      ),
    );
  }
}

class WorkoutPostCard extends StatelessWidget {
  final WorkoutPost post;

  const WorkoutPostCard({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkoutPostDetailPage(postId: post.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header
            ListTile(
              leading: CircleAvatar(
                backgroundImage: post.user.avatarUrl != null
                    ? NetworkImage(post.user.avatarUrl!)
                    : null,
                child: post.user.avatarUrl == null
                    ? Text(post.user.name.isNotEmpty ? post.user.name[0].toUpperCase() : 'U')
                    : null,
              ),
              title: Text(post.user.name),
              subtitle: Text('@${post.user.username}'),
              trailing: Text(_formatDate(post.createdAt)),
            ),

            // Caption
            if (post.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(post.caption),
              ),

            // Workout image
            if (post.imageS3Key != null)
              AspectRatio(
                aspectRatio: 16 / 9,
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
                              color: Colors.grey[200],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, size: 64, color: Colors.grey),
                            );
                          },
                        ),
                      );
                    }
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),

            // Workout summary
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        post.workoutSummary.sessionName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          post.workoutSummary.status,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStat('Time', '${post.workoutSummary.totalTimeMin.toInt()}min'),
                      const SizedBox(width: 16),
                      _buildStat('Volume', '${post.workoutSummary.totalVolume}'),
                      const SizedBox(width: 16),
                      _buildStat('Sets', '${post.workoutSummary.totalSets}'),
                      const SizedBox(width: 16),
                      _buildStat('Reps', '${post.workoutSummary.totalReps}'),
                    ],
                  ),
                  if (post.workoutSummary.exercises.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Exercises: ${post.workoutSummary.exercises.map((e) => e.exercise.name).join(', ')}'),
                  ],
                ],
              ),
            ),

            // Actions
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement like functionality
                  },
                  icon: Icon(
                    post.isLikedByUser ? Icons.favorite : Icons.favorite_border,
                    color: post.isLikedByUser ? Colors.red : null,
                  ),
                  label: Text('${post.likesCount}'),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement comments functionality
                  },
                  icon: const Icon(Icons.comment),
                  label: Text('${post.commentsCount}'),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement share functionality
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
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
