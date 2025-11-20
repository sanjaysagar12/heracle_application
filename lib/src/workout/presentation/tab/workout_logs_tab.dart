import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/session_repository.dart';

class WorkoutLogsTab extends StatefulWidget {
  const WorkoutLogsTab({super.key});

  @override
  State<WorkoutLogsTab> createState() => _WorkoutLogsTabState();
}

class _WorkoutLogsTabState extends State<WorkoutLogsTab> {
  final SessionRepository _sessionRepository = SessionRepository();
  late Future<List<WorkoutLog>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    _logsFuture = _sessionRepository.getWorkoutLogsFromDb();
  }

  Future<void> _onRefresh() async {
    _loadLogs();
    await _logsFuture;
    setState(() {});
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/back.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Workout History', style: TextStyle(color: AppColors.pureWhite)),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppColors.primary,
        child: FutureBuilder<List<WorkoutLog>>(
          future: _logsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading logs: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.white60),
                ),
              );
            }

            final logs = snapshot.data ?? [];

            if (logs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fitness_center, size: 64, color: AppColors.white60),
                    const SizedBox(height: 16),
                    const Text(
                      'No workout logs yet',
                      style: TextStyle(color: AppColors.white60, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Complete a workout to see your history',
                      style: TextStyle(color: AppColors.white60, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final log = logs[index];
                return _buildLogCard(log);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogCard(WorkoutLog log) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.black100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.title,
                      style: const TextStyle(
                        color: AppColors.pureWhite,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(log.completedAt),
                      style: const TextStyle(color: AppColors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatDuration(log.duration),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(Icons.fitness_center, '${log.exercisesCount}', 'Exercises'),
              _buildStatItem(Icons.repeat, '${log.totalSets}', 'Sets'),
              _buildStatItem(Icons.monitor_weight, '${log.totalVolume}', 'Volume (kg)'),
            ],
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text(
              'View Exercises',
              style: TextStyle(color: AppColors.primary, fontSize: 14),
            ),
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.white60,
            children: [
              ...log.exercises.map((exercise) {
                final sets = exercise['sets'] as List<dynamic>;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['name']?.toString() ?? 'Exercise',
                        style: const TextStyle(
                          color: AppColors.pureWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...sets.asMap().entries.map((entry) {
                        final index = entry.key;
                        final set = entry.value as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            'Set ${index + 1}: ${set['kg']}kg × ${set['reps']} reps',
                            style: const TextStyle(color: AppColors.white60, fontSize: 13),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.pureWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: AppColors.white60, fontSize: 12),
        ),
      ],
    );
  }
}
