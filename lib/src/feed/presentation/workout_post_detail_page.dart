import 'package:flutter/material.dart';
import '../api/workout_posts_api.dart';
import '../domain/models/workout_post_detail_model.dart';
import '../../config/api_endpoints.dart';

class WorkoutPostDetailPage extends StatefulWidget {
  final String postId;

  const WorkoutPostDetailPage({Key? key, required this.postId}) : super(key: key);

  @override
  State<WorkoutPostDetailPage> createState() => _WorkoutPostDetailPageState();
}

class _WorkoutPostDetailPageState extends State<WorkoutPostDetailPage> {
  late Future<WorkoutPostDetail> _postDetailFuture;

  @override
  void initState() {
    super.initState();
    _postDetailFuture = WorkoutPostsApi.fetchWorkoutPostDetail(widget.postId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Post')),
      body: FutureBuilder<WorkoutPostDetail>(
        future: _postDetailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final post = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User header
                ListTile(
                  contentPadding: EdgeInsets.zero,
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
                if (post.caption.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(post.caption, style: const TextStyle(fontSize: 16)),
                ],

                // Workout image
                if (post.imageS3Key != null) ...[
                  const SizedBox(height: 16),
                  FutureBuilder<Map<String, String>>(
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
                          ),
                        );
                      }
                      return Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 16),

                // Workout Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${post.workoutDetails.sessionInfo.name}', 
                             style: Theme.of(context).textTheme.headlineSmall),
                        if (post.workoutDetails.sessionInfo.description != null)
                          Text(post.workoutDetails.sessionInfo.description!),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat('Duration', '${post.workoutDetails.completion.duration}min'),
                            _buildStat('Exercises', '${post.workoutDetails.performance.totalExercises}'),
                            _buildStat('Sets', '${post.workoutDetails.performance.totalSets}'),
                            _buildStat('Volume', '${post.workoutDetails.performance.totalVolume}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Muscle Groups
                if (post.workoutDetails.muscleGroupBreakdown.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Muscle Groups', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          ...post.workoutDetails.muscleGroupBreakdown.map((mg) => 
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(mg.muscleGroup.toUpperCase()),
                                  Text('${mg.sets} sets (${mg.percentage}%)'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Exercises
                const SizedBox(height: 16),
                const Text('Exercises', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                ...post.workoutDetails.exercises.map((exercise) => 
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ExpansionTile(
                      title: Text(exercise.exercise.name),
                      subtitle: Text('${exercise.performance.totalSets} sets • ${exercise.performance.totalReps} reps • ${exercise.performance.totalVolume} volume'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: exercise.sets.map((set) => 
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Set ${set.setNumber}'),
                                    Text('${set.reps} × ${set.weight ?? 0}kg'),
                                    if (set.rpe != null) Text('RPE: ${set.rpe}'),
                                  ],
                                ),
                              ),
                            ).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement like
                      },
                      icon: Icon(post.isLikedByUser ? Icons.favorite : Icons.favorite_border),
                      label: Text('${post.stats.likesCount}'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement comments
                      },
                      icon: const Icon(Icons.comment),
                      label: Text('${post.stats.commentsCount}'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement share
                      },
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
